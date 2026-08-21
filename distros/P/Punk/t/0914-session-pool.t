#!perl
use 5.010;
use strict;
use warnings;
use File::Temp ();
use POSIX ();
use Test::More;
use lib 't/lib';
use PunkTest;

# The gate: a stored session belongs to the POOL, not to the worker that made
# it. A login on one worker is visible on every other worker's next request,
# and a logout on one is refused by every other.
#
# It is asserted across real forked processes because a single-process test
# cannot see the failure at all - a per-worker copy answers itself perfectly
# and only diverges from its siblings, which is exactly how this class of bug
# reaches production.

my $root = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
sub dir { "$root/s" . $n++ }

sub set_cookie {
    my ($r) = @_;
    for (my $i = 0; $i < @{ $r->[1] }; $i += 2) {
        return $r->[1][$i + 1] if $r->[1][$i] eq 'Set-Cookie';
    }
    return undef;
}
sub cookie_val { my ($sc) = @_; $sc // return; my ($v) = $sc =~ /punk\.sid=([^;]+)/; $v }

# One request, served by a forked child. The application is compiled in the
# PARENT, so a child inherits it exactly as a prefork worker inherits it from
# the master - which is the arrangement under test.
#
# The child reports down a pipe and leaves through POSIX::_exit: a child that
# returned into the harness would inherit the TAP stream and report the
# parent's plan a second time.
sub in_worker {
    my ($app, %o) = @_;
    pipe my $rd, my $wr or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        close $rd;
        my $r    = eval { hit($app, %o) };
        my $err  = $@;
        my $body = ref $r eq 'ARRAY' ? join('', grep { defined } @{ $r->[2] })
                                     : "DIED:$err";
        my $sc   = ref $r eq 'ARRAY' ? (set_cookie($r) // '') : '';
        syswrite $wr, join("\t", $$, $sc, $body);
        close $wr;
        POSIX::_exit(0);
    }
    close $wr;
    my $out = do { local $/; <$rd> };
    close $rd;
    waitpid $pid, 0;
    my $status = $?;

    # A worker that died reported nothing, and splitting nothing gives an odd
    # list and a hash full of undef - which is how Punk 0.26's segfault reached
    # the smokers looking like "Use of uninitialized value" four times over,
    # with the signal that caused it nowhere in the output. Say what happened.
    my @f = split /\t/, ($out // ''), 3;
    if (@f < 3) {
        diag sprintf 'worker %d died before reporting: %s',
            $pid, $status & 127 ? "signal @{[ $status & 127 ]}"
                                : 'exit ' . ($status >> 8);
        return { pid => $pid, cookie => undef, body => undef, died => $status };
    }
    return { pid => $f[0], cookie => cookie_val($f[1]), body => $f[2] };
}

SKIP: {
    skip 'fork is POSIX-only here', 7 if $^O eq 'MSWin32';

    my $d = dir();
    eval qq{
        package PoolApp;
        use Punk;
        cache 'file', dir => '$d';
        session secret => 'k', expires => '1h', store => 'cache';

        get '/login'  => sub { my \$c = shift; \$c->session_rotate;
                               \$c->session->{user_id} = 42; \$c->text("in:\$\$") };
        get '/me'     => sub { my \$c = shift;
                               \$c->text((\$c->session->{user_id} // 'none') . ":\$\$") };
        get '/logout' => sub { my \$c = shift; \$c->session_expire;
                               \$c->text("out:\$\$") };
        1;
    } or die $@;

    # Compile in the parent, before any fork - the master's work, inherited.
    my $app = PoolApp->to_app;

    my $login = in_worker($app, path => '/login');
    my $cv    = $login->{cookie};
    ok(defined $cv, 'worker A logged somebody in');

    my $b = in_worker($app, path => '/me',
                      env => { HTTP_COOKIE => "punk.sid=$cv" });
    my ($who, $bpid) = split /:/, $b->{body};
    is($who, '42',
        'worker B sees the login on its NEXT request - the session belongs to '
      . 'the pool, not to the process that created it');
    isnt($bpid, $login->{pid}, 'and it really was a different process');

    my $c = in_worker($app, path => '/me',
                      env => { HTTP_COOKIE => "punk.sid=$cv" });
    is((split /:/, $c->{body})[0], '42', 'so does worker C');

    # Revocation crosses the pool the same way, and this is the half that
    # matters: a logout that only reached one worker would leave the session
    # alive on the other seven.
    my $out = in_worker($app, path => '/logout',
                        env => { HTTP_COOKIE => "punk.sid=$cv" });
    like($out->{body}, qr/^out:/, 'worker D logged them out');

    my $after = in_worker($app, path => '/me',
                          env => { HTTP_COOKIE => "punk.sid=$cv" });
    is((split /:/, $after->{body})[0], 'none',
        'and worker E refuses the same cookie on its next request - the '
      . 'logout was not a local event');

    # A rotation is a delete too, so it has to cross the pool as well.
    my $l2 = in_worker($app, path => '/login');
    my $r2 = in_worker($app, path => '/me',
                       env => { HTTP_COOKIE => 'punk.sid=' . $l2->{cookie} });
    is((split /:/, $r2->{body})[0], '42',
        'a rotated session is readable on another worker under its new id');
}

# ---- the memory tier ---------------------------------------------------------
# A tier is a copy per worker. A tier MISS falls through to the backend, so it
# can never manufacture a missing session - the hazard runs one way only, and
# it is that a worker which missed an invalidation answers with the session as
# it was BEFORE the logout.

{
    package T::Counting;
    our $GETS = 0;
    sub new       { my ($c, %o) = @_; bless { h => {}, %o }, $c }
    sub is_shared { 1 }
    sub get       { $GETS++; $_[0]{h}{ $_[1] } }
    sub set       { $_[0]{h}{ $_[1] } = $_[2]; 1 }
    sub delete    { defined delete $_[0]{h}{ $_[1] } ? 1 : 0 }
    sub clear     { %{ $_[0]{h} } = (); 1 }
    sub stats     { (entries => scalar keys %{ $_[0]{h} }) }
    package main;
}

# By default a session read goes STRAIGHT to the backend, whatever the
# application configured for everything else.
{
    package TBypass;
    use Punk;
    session secret => 'k',
            store  => { backend => 'T::Counting', memory => '1M',
                        memory_ttl => 30 };
    get '/login' => sub { $_[0]->session->{user_id} = 1; $_[0]->text('in') };
    get '/me'    => sub { $_[0]->text($_[0]->session->{user_id} // 'none') };
    package main;

    my $app = TBypass->to_app;
    my $cv  = cookie_val(set_cookie(hit($app, path => '/login')));

    $T::Counting::GETS = 0;
    hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$cv" });
    hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($T::Counting::GETS, 2,
        'every session read reaches the backend even though the store has a '
      . 'tier - the tier is where a revoked session would keep working, and '
      . 'sessions do not opt into that by accident');
}

# Opted in, it reads through the tier - which is the whole point of asking.
{
    package TOptIn;
    use Punk;
    session secret => 'k',
            tier   => 5,
            store  => { backend => 'T::Counting', memory => '1M',
                        memory_ttl => 5 };
    get '/login' => sub { $_[0]->session->{user_id} = 1; $_[0]->text('in') };
    get '/me'    => sub { $_[0]->text($_[0]->session->{user_id} // 'none') };
    package main;

    my $app = TOptIn->to_app;
    my $cv  = cookie_val(set_cookie(hit($app, path => '/login')));

    $T::Counting::GETS = 0;
    my $first = hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$cv" });
    my $second = hit($app, path => '/me', env => { HTTP_COOKIE => "punk.sid=$cv" });
    is($first->[2][0],  '1', 'the session reads');
    is($second->[2][0], '1', 'twice');
    is($T::Counting::GETS, 1,
        'and the second read never reached the backend - which is what the '
      . 'tier buys, and what a 100us network store makes worth buying');
}

# A write has to drop the tier copy, not just change the backend. This is the
# in-process half of "set invalidates as well as delete": the worker that made
# the change must not be the one serving the old value.
#
# It is also why session writes are NOT routed around the tier the way reads
# are - the front's own set and delete drop the local copy and publish, and
# reaching past them would leave this worker stale.
{
    package TWrite;
    use Punk;
    session secret => 'k',
            tier   => 5,
            store  => { backend => 'T::Counting', memory => '1M',
                        memory_ttl => 5 };
    get '/login'  => sub { $_[0]->session->{user_id} = 1; $_[0]->text('in') };
    get '/me'     => sub { $_[0]->text($_[0]->session->{user_id} // 'none') };
    get '/change' => sub { $_[0]->session->{user_id} = 2; $_[0]->text('ch') };
    get '/logout' => sub { $_[0]->session_expire; $_[0]->text('out') };
    package main;

    my $app = TWrite->to_app;
    my $cv  = cookie_val(set_cookie(hit($app, path => '/login')));
    my %env = (HTTP_COOKIE => "punk.sid=$cv");

    hit($app, path => '/me', env => \%env);            # populates the tier
    hit($app, path => '/change', env => \%env);
    my $after = hit($app, path => '/me', env => \%env);
    is($after->[2][0], '2',
        'a change is visible to the worker that made it - the write dropped '
      . 'the tier copy rather than leaving it to answer for memory_ttl');

    hit($app, path => '/logout', env => \%env);
    my $out = hit($app, path => '/me', env => \%env);
    is($out->[2][0], 'none',
        'and so is a logout, which is the same rule wearing its dangerous hat');
}

# ---- what the tier option refuses at boot ------------------------------------
{
    my $err = do {
        local $@;
        eval q{
            package TTooLong;
            use Punk;
            session secret => 'k', tier => 60,
                    store  => { backend => 'T::Counting', memory => '1M',
                                memory_ttl => 60 };
            TTooLong->to_app;
            1;
        };
        $@;
    };
    like($err, qr/is the most this will accept|not a logout/,
        'a minute of stale authentication is refused at boot - a logout that '
      . 'lags that long is not a logout');
}

{
    my $err = do {
        local $@;
        eval q{
            package TNoTier;
            use Punk;
            session secret => 'k', tier => 2,
                    store  => { backend => 'T::Counting' };
            TNoTier->to_app;
            1;
        };
        $@;
    };
    like($err, qr/this store has none/,
        'asking to read through a tier that does not exist is a boot error, '
      . 'not a silently slower application');
}

{
    my $err = do {
        local $@;
        eval q{
            package TMismatch;
            use Punk;
            session secret => 'k', tier => 1,
                    store  => { backend => 'T::Counting', memory => '1M',
                                memory_ttl => 4 };
            TMismatch->to_app;
            1;
        };
        $@;
    };
    like($err, qr/memory_ttl is 4 seconds/,
        'and a store that lags longer than the application said it accepts '
      . 'names both numbers rather than quietly using the larger one');
}

# A tier makes a SHARED store unshared as far as Punk::Cache is concerned, and
# the phase-0 check had to know the difference. This is that check, from the
# other side: a tiered store is still a legitimate session store.
{
    package TStillOk;
    use Punk;
    session secret => 'k',
            store  => { backend => 'T::Counting', memory => '1M' };
    package main;
    ok(TStillOk->to_app,
        'a tiered store boots - the shared check asks the BACKEND, not the '
      . 'front, which reports itself unshared the moment a tier exists');
}

done_testing;
