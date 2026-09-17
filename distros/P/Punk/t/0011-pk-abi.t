#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Scalar::Util ();
use Punk ();

# pk_abi.h - Punk's own C ABI. Everything here goes through the TABLE, not the
# static functions behind it: t/lib is not involved, the observers are C
# functions registered through PK_ABI.on_request / on_response, and the values
# they record were read back through PK_ABI's accessors. A mis-ordered
# initialiser or a signature that drifted from the header shows up here as a
# wrong value rather than as nothing at all.

# ---- before anything registers ----------------------------------------------
# Registration is process-global and there is no deregistration, so the
# "nobody is listening" assertions have to come first, in this order.
{
    package QuietApp;
    use Punk;
    get '/q' => sub { $_[0]->text('quiet') };
    package main;
}
{
    my $app = QuietApp->to_app;
    my $r = $app->({ REQUEST_METHOD => 'GET', PATH_INFO => '/q' });
    is($r->[0], 200, 'with no observer registered the app answers normally');
    is($r->[2][0], 'quiet', 'and the body is untouched');
    my $ev = Punk::_abi_selftest_events();
    is(scalar @$ev, 0, 'nothing was recorded, because nothing was registered');
}

# ---- the table ---------------------------------------------------------------
{
    ok(Punk::_abi_ptr() > 0, '_abi_ptr hands back a non-zero address');
    is(Punk::_abi_selftest_install(), 1,
        'a C consumer resolves the table, matches PK_ABI_VERSION and registers');
    is(Punk::_abi_selftest_install(), 1, 'registering again is idempotent');
}

# ---- the application ---------------------------------------------------------
sub petstore {
    return {
        openapi => '3.1.0',
        info    => { title => 'Petstore', version => '1' },
        paths   => {
            '/pets' => {
                get => { operationId => 'listPets',
                         responses => { 200 => { description => 'ok' } } },
            },
        },
    };
}

{
    package AbiApp;
    use Punk;

    api main::petstore() => { handlers => {
        listPets => sub { $_[0]->json({ pets => [] }) },
    } };

    mount '/mounted' => sub {
        return [ 201, [ 'Content-Type' => 'text/plain' ], ['from the mount'] ];
    };

    get  '/users/:id' => sub { $_[0]->text('user ' . $_[0]->param('id')) };
    post '/users'     => sub { $_[0]->text('made') };
    get  '/boom'      => sub { die "went wrong\n" };
    get  '/slow'      => sub {
        my ($c) = @_;
        $c->timer(0)->then(sub { $c->text('late') });
    };
    get  '/big' => { cb => sub { $_[0]->text('big') }, max_body => 4 };

    # v5 current_of. Each returns what it observed so the test reads a body
    # rather than a global, which keeps the assertions about one request.
    get '/cur' => sub {
        my ($c) = @_;
        my $cur = Punk::_abi_current();
        $c->text(defined $cur
            ? (Scalar::Util::refaddr($cur) == Scalar::Util::refaddr($c)
                ? 'same' : 'other')
            : 'undef');
    };
    # A future the TEST settles, after punk_serve has returned. A timer(0)
    # would not do: with no loop running it settles inline, still inside the
    # dispatch frame, where the current context is legitimately still set.
    # The case that matters is the continuation that runs once the frame has
    # gone.
    our $LATE;
    get '/cur-async' => sub {
        my ($c) = @_;
        $LATE = Punk::Future->new;
        return $LATE->then(sub {
            # THE ASSERTION THE DESIGN TURNS ON. A value here is the leak the
            # ABI note warns about, and would attribute one request's
            # statements to another.
            $main::CUR_IN_CONTINUATION =
                defined Punk::_abi_current() ? 'leaked' : 'undef';
            $c->text('late');
        });
    };
    get '/cur-croak' => sub { die "went wrong\n" };

    package main;
}

my $app = AbiApp->to_app;

sub hit {
    my ($method, $path, %env) = @_;
    Punk::_abi_selftest_events();            # drain
    my $res = $app->({ REQUEST_METHOD => $method, PATH_INFO => $path, %env });
    return ($res, Punk::_abi_selftest_events());
}

sub only {                                   # the one event of a kind
    my ($ev, $kind) = @_;
    my @m = grep { $_->{kind} eq $kind } @$ev;
    return @m == 1 ? $m[0] : undef;
}

# ---- one event of each kind, on every path ----------------------------------
my @paths = (
    [ 'a matched route',  GET  => '/users/7',    200 ],
    [ 'a 404',            GET  => '/nope',       404 ],
    [ 'a 405',            GET  => '/users',      405 ],
    [ 'a PSGI mount',     GET  => '/mounted/x',  201 ],
    [ 'an API operation', GET  => '/pets',   200 ],
    [ 'a handler that died', GET => '/boom',     500 ],
    [ 'an async handler', GET  => '/slow',       200 ],
);

for my $case (@paths) {
    my ($what, $method, $path, $status) = @$case;
    my ($res, $ev) = hit($method, $path);
    is($res->[0], $status, "$what answers $status");
    is(scalar(grep { $_->{kind} eq 'request' } @$ev), 1,
        "$what fires exactly one request event");
    is(scalar(grep { $_->{kind} eq 'response' } @$ev), 1,
        "$what fires exactly one response event");
    is(only($ev, 'response')->{status}, $status,
        "$what reports the final status through status_of");
}

# ---- ordering and identity ---------------------------------------------------
{
    my ($res, $ev) = hit(GET => '/users/7');
    is($ev->[0]{kind}, 'request',  'the request event comes first');
    is($ev->[1]{kind}, 'response', 'and the response event second');

    ok($ev->[0]{mark} > 0, 'the request observer could write to the stash');
    is($ev->[1]{mark}, $ev->[0]{mark},
        'the response observer reads its own mark back: ONE context per request');

    is($_->{has_env},   1, 'env_of works in the ' . $_->{kind} . ' observer')
        for @$ev;
    is($_->{has_app},   1, 'app_of works in the ' . $_->{kind} . ' observer')
        for @$ev;
    is($_->{has_match}, 1, 'match_of works in the ' . $_->{kind} . ' observer')
        for @$ev;
    is($_->{has_stash}, 1, 'stash_of works in the ' . $_->{kind} . ' observer')
        for @$ev;
}

# ---- route_pattern_of: the pattern, never the path --------------------------
{
    my ($res, $ev) = hit(GET => '/users/7');
    is(only($ev, 'response')->{route}, '/users/:id',
        'route_pattern_of gives the DECLARED path, not /users/7');
    is(only($ev, 'request')->{route}, undef,
        'and undef before routing has happened');
}

{
    my ($res, $ev) = hit(GET => '/nope');
    is(only($ev, 'response')->{route}, undef, '404: no route to name');
}
{
    my ($res, $ev) = hit(GET => '/mounted/x');
    is(only($ev, 'response')->{route}, undef, 'mount: no route to name');
}

# ---- operation_of ------------------------------------------------------------
{
    my ($res, $ev) = hit(GET => '/pets');
    is(only($ev, 'response')->{operation}, 'listPets',
        'operation_of names the API operation');
    is(only($ev, 'response')->{route}, undef,
        'an API operation has no route pattern, it has an operation id');
}

# ---- the paths that never reach punk_deliver --------------------------------
{
    my ($res, $ev) = hit(POST => '/users',
        CONTENT_LENGTH => 99, CONTENT_TYPE => 'text/plain');
    is($res->[0], 200, 'a POST under the ceiling is served');

    ($res, $ev) = hit(GET => '/big',
        CONTENT_LENGTH => 4_000, CONTENT_TYPE => 'text/plain');
    is($res->[0], 413, 'max_body refuses before the hook chain');
    is(scalar(grep { $_->{kind} eq 'response' } @$ev), 1,
        'and the 413 still fires exactly one response event');
    is(only($ev, 'response')->{status}, 413, 'with the right status');
}

# ---- the error path reports what was actually sent --------------------------
{
    my ($res, $ev) = hit(GET => '/boom');
    is(only($ev, 'response')->{status}, 500,
        'a died handler reports the 500 that went out, not the handler');
}

# ---- $c->match->{route}: the POD claim, now true -----------------------------
{
    package MatchApp;
    use Punk;
    our $seen;
    get '/m/:id' => sub {
        my ($c) = @_;
        $seen = $c->match->{route};
        $c->text('ok');
    };
    package main;

    my $m = MatchApp->to_app;
    $m->({ REQUEST_METHOD => 'GET', PATH_INFO => '/m/3' });
    ok(ref $MatchApp::seen eq 'HASH', '$c->match carries the route record');
    is($MatchApp::seen->{path}, '/m/:id', 'whose path is the declared pattern');
    is($MatchApp::seen->{method}, 'GET', 'and which names the method');
}

# ---- v2 on_query: the OTHER database path -----------------------------------
# Punk::Model::DBI is a second, separate backend from DBIx::Loop's, and an
# application using the default `model` generates no DBIx::Loop traffic at
# all. Instrumenting only that one would leave this whole class of application
# silent.
SKIP: {
    eval { require DBI; require DBD::SQLite; 1 }
        or skip 'DBI + DBD::SQLite required', 6;
    require Punk::Model;

    {
        package T::Abi::Book;
        use Punk::Model;
        table 'books';
        field id     => { type => 'integer', primary => 1 };
        field title  => { type => 'string' };
    }

    my $model = T::Abi::Book->_instantiate({ dsn => 'dbi:SQLite:dbname=:memory:' });
    $model->backend->dbh->do(
        'CREATE TABLE books (id INTEGER PRIMARY KEY, title TEXT)');

    my ($s0, $d0, $ok0) = Punk::_abi_selftest_queries();
    $model->create({ title => 'Neuromancer' });
    my ($s1, $d1, $ok1, $nbind, $sql) = Punk::_abi_selftest_queries();

    ok($s1 > $s0, 'a model write is observed through on_query');
    is($d1 - $d0, $s1 - $s0, 'every statement start settled');
    ok($ok1 > $ok0, 'and is reported as having succeeded');

    my ($s2) = Punk::_abi_selftest_queries();
    is($model->get(id => 1)->{title}, 'Neuromancer', 'the row round-tripped');
    my ($s3, $d3, $ok3, $bind3, $sql3) = Punk::_abi_selftest_queries();
    ok($s3 > $s2, 'a model read is observed too');
    like($sql3, qr/SELECT/i, 'the observer is handed the statement text');
    unlike($sql3, qr/Neuromancer/,
        'and never a bind value: the literal data does not reach an observer');
}

# ---- v5: current_of ----------------------------------------------------------
#
# The member exists so an observer that is handed NO context - on_query - can
# find the request that issued the statement. Everything below is about one
# property: it is the right context, or it is nothing. It is never somebody
# else's, which is what pk_abi.h's own note on on_log_ctx refuses.
{
    is(Punk::_abi_current(), undef,
        'current_of is undef outside any request');

    my ($res) = hit(GET => '/cur');
    is($res->[2][0], 'same',
        'inside a handler it is THAT request, by address and not by shape');

    is(Punk::_abi_current(), undef,
        'and undef again once the request is over');

    # Every observer event carries an identity check of its own, so a
    # current_of that named a different context would fail here even if the
    # handler above happened to look right.
    my (undef, $ev) = hit(GET => '/users/7');
    is(scalar(grep { $_->{current_is_c} } @$ev), scalar @$ev,
        'both observers see current_of naming the context they were handed');

    # A croak leaves ps_serve_one by none of its returns. Without the save
    # stack the pointer would survive the request that died.
    my ($boom) = hit(GET => '/cur-croak');
    is($boom->[0], 500, 'a handler that dies still answers 500');
    is(Punk::_abi_current(), undef,
        'and current_of is undef after it: the restore is not on the happy path');

    # THE ONE THAT DECIDES THE DESIGN. The request is dispatched, punk_serve
    # returns, and only then is the future settled - so the continuation runs
    # with the dispatch frame long gone. Anything but undef is the leak the
    # ABI note warns about, and would attribute one request's statements to
    # another.
    $main::CUR_IN_CONTINUATION = 'never ran';
    hit(GET => '/cur-async');
    is(Punk::_abi_current(), undef,
        'the frame has unwound before the future is settled');
    $AbiApp::LATE->done;
    is($main::CUR_IN_CONTINUATION, 'undef',
        'current_of is undef in a future continuation: no parent, never a wrong one');

    is(Punk::_abi_current(), undef, 'and undef after that too');
}

# ---- v5: a mounted application restores the outer context --------------------
#
# The restore puts back the PREVIOUS value, not undef. An app mounted in an app
# nests two dispatch frames, and the outer one has to find its own context
# where it left it.
{
    {
        package InnerApp;
        use Punk;
        get '/in' => sub {
            my ($c) = @_;
            my $cur = Punk::_abi_current();
            $c->text(defined $cur
                && Scalar::Util::refaddr($cur) == Scalar::Util::refaddr($c)
                    ? 'inner' : 'wrong');
        };
        package main;
    }
    our $INNER = InnerApp->to_app;       # to_app compiles once, per app
    {
        package OuterApp;
        use Punk;
        mount '/deep' => $main::INNER;
        get '/out' => sub {
            my ($c) = @_;
            my $before = Punk::_abi_current();
            # a whole nested dispatch, inside this one
            $main::INNER->({ REQUEST_METHOD => 'GET', PATH_INFO => '/in' });
            my $after = Punk::_abi_current();
            $c->text(
                  (defined $before && defined $after
                   && Scalar::Util::refaddr($before) == Scalar::Util::refaddr($c)
                   && Scalar::Util::refaddr($after)  == Scalar::Util::refaddr($c))
                  ? 'restored' : 'clobbered');
        };
        package main;
    }

    my $outer = OuterApp->to_app;
    my $deep = $outer->({ REQUEST_METHOD => 'GET', PATH_INFO => '/deep/in' });
    is($deep->[2][0], 'inner', 'a mounted app sees its own context');

    my $out = $outer->({ REQUEST_METHOD => 'GET', PATH_INFO => '/out' });
    is($out->[2][0], 'restored',
        'and the outer frame finds its own context again afterwards');

    is(Punk::_abi_current(), undef, 'nothing is left set once both unwind');
}

done_testing;
