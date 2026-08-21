#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Punk ();

# The session id: the whole authentication of a server-side session.
#
# With a cookie session, forging one means forging an HMAC. With a stored one
# it means GUESSING AN ID, so what is proven here is that guessing is hopeless,
# that two workers never hand out the same id, and that an id which was not
# minted by this server is refused before it could become a store lookup.

{
    package IdApp;
    use Punk;
    session secret => 's3kr3t', expires => '7d';
    get '/' => sub { $_[0]->text('ok') };
    package main;
}
my $app_obj = IdApp->punk_app;

# ---- the shape ---------------------------------------------------------------
{
    my $id = Punk::Session::_new_id();
    is(length $id, 32, 'an id is 32 hex characters');
    like($id, qr/\A[0-9a-f]{32}\z/, '128 bits, lowercase hex, and nothing else');

    my %seen;
    $seen{ Punk::Session::_new_id() }++ for 1 .. 20_000;
    is(scalar keys %seen, 20_000,
        '20,000 draws, no repeat - a counter or a truncated clock would not '
      . 'survive this');
}

# ---- across a real worker pool -----------------------------------------------
# The assertion a single process cannot make. An entropy buffer filled once and
# inherited through fork hands every worker the same bytes - measured at 767
# duplicates in 8000 while building RequestId, and it looks perfectly random
# the entire time. A duplicate request id is a nuisance; a duplicate SESSION
# id is one user handed another user's session.
SKIP: {
    skip 'fork is POSIX-only here', 2 if $^O eq 'MSWin32';

    my $workers = 4;
    my $per     = 500;
    pipe my $rd, my $wr or die "pipe: $!";

    # Draw one in the PARENT first, so the buffer is warm and inherited, which
    # is exactly the condition that makes a naive generator collide. A test
    # that forked before touching it would pass against the bug.
    Punk::Session::_new_id();

    my @pids;
    for (1 .. $workers) {
        my $pid = fork // die "fork: $!";
        if (!$pid) {
            close $rd;
            # syswrite, not print: a buffered handle shared across forked
            # children is its own source of lost and interleaved output.
            syswrite $wr, join('', map { Punk::Session::_new_id() . "\n" }
                                       1 .. $per);
            close $wr;
            POSIX::_exit(0) if eval { require POSIX; 1 };
            exit 0;
        }
        push @pids, $pid;
    }
    close $wr;

    my %seen;
    my $lines = 0;
    while (my $line = <$rd>) {
        chomp $line;
        next unless length $line;
        $seen{$line}++;
        $lines++;
    }
    close $rd;
    waitpid $_, 0 for @pids;

    is($lines, $workers * $per, "all $workers workers reported their ids");
    is(scalar keys %seen, $lines,
        'EVERY id is unique across the pool - the entropy buffer is filled '
      . 'per process, not inherited from the parent that warmed it')
        or diag sprintf 'got %d distinct ids from %d', scalar keys %seen, $lines;
}

# ---- the cookie it rides in --------------------------------------------------
# Still signed, and still the same signer. Not to protect a secret - an id is
# not one - but because an unsigned id turns the store into an oracle: anyone
# could send a guess and make the server do a lookup for it.
{
    my $id = Punk::Session::_new_id();
    my ($name, $value) = Punk::Session::_seal_id($app_obj, $id);

    is($name, 'punk.sid', 'the id rides in the configured cookie');
    like($value, qr/\A[\w-]+\.[\w-]+\z/,
        'as payload.signature, the format the cookie session already uses');
    is(Punk::Session::_unseal_id($app_obj, $value), $id,
        'and it round-trips back out');

    # Signed is not sealed, here as everywhere else: the client can decode the
    # payload and read its own id. That is not a leak - it is the client's own
    # session id, which it has to send back anyway. What the signature buys is
    # that it cannot send back a DIFFERENT one.
    unlike($value, qr/\A\Q$id\E/,
        'the cookie value is not the bare id, so an id cannot be swapped for '
      . 'a guess and still arrive as a session');
}

# What travels is the id and nothing else. The moment something useful is in
# there, an application reads it instead of the session, and the cookie is the
# source of truth again with none of the signing that made that safe.
{
    my $id = Punk::Session::_new_id();
    my ($name, $value) = Punk::Session::_seal_id($app_obj, $id);
    my ($payload) = split /\./, $value;
    $payload =~ tr{-_}{+/};
    $payload .= '=' x ((4 - length($payload) % 4) % 4);

    SKIP: {
        eval { require MIME::Base64; 1 } or skip 'MIME::Base64', 2;
        my $json = MIME::Base64::decode_base64($payload);
        like($json, qr/\Q$id\E/, 'the payload carries the id');
        my @keys = $json =~ /"([^"]+)":/g;
        is_deeply([sort @keys], [sort 'punk.exp', 'punk.id'],
            'and the stamped expiry, and NOTHING else - no user id, no role, '
          . 'nothing an application could be tempted to read from the client');
    }
}

# ---- what is refused ---------------------------------------------------------
{
    my $id = Punk::Session::_new_id();
    my ($name, $value) = Punk::Session::_seal_id($app_obj, $id);

    my $tampered = $value;
    substr($tampered, 0, 1) = (substr($tampered, 0, 1) eq 'a' ? 'b' : 'a');
    is(Punk::Session::_unseal_id($app_obj, $tampered), undef,
        'a tampered cookie yields no id, so it never becomes a store lookup');

    my ($p, $s) = split /\./, $value;
    is(Punk::Session::_unseal_id($app_obj, "$p.$p"), undef,
        'nor does one with the signature replaced');
    is(Punk::Session::_unseal_id($app_obj, $p), undef,
        'nor does a truncated one with no signature at all');
    is(Punk::Session::_unseal_id($app_obj, ''), undef, 'nor an empty cookie');
    is(Punk::Session::_unseal_id($app_obj, 'punk.sid=' . $id), undef,
        'nor a bare id somebody guessed, which is the whole reason the '
      . 'signature is still here');
}

# A different secret is a different server. The id was minted here; the cookie
# was not sealed with this key, so it is not a session.
{
    package IdApp2;
    use Punk;
    session secret => 'other-key', expires => '7d';
    package main;

    my $id = Punk::Session::_new_id();
    my (undef, $value) = Punk::Session::_seal_id($app_obj, $id);
    is(Punk::Session::_unseal_id(IdApp2->punk_app, $value), undef,
        'a cookie sealed with another key is not a session here');
}

# The 0.19 expiry stamp still applies. Belt and braces once the store has its
# own TTL - but a cookie past its lifetime must be refused rather than looked
# up, and the two expiries must not be able to disagree in the direction where
# the cookie outlives the entry.
#
# The stamp is absolute seconds, so an expired one is built directly through
# the raw sealer rather than slept through.
{
    my $id = Punk::Session::_new_id();

    my (undef, $live) = Punk::Session::_seal(
        $app_obj, { 'punk.id' => $id, 'punk.exp' => time + 60 });
    is(Punk::Session::_unseal_id($app_obj, $live), $id,
        'a stamp in the future unseals');

    my (undef, $dead) = Punk::Session::_seal(
        $app_obj, { 'punk.id' => $id, 'punk.exp' => time - 1 });
    is(Punk::Session::_unseal_id($app_obj, $dead), undef,
        'a stamp one second in the past does not - the signature is perfectly '
      . 'good, and the cookie is still not a session');
}

# The upgrade path: cookies minted BEFORE a store was configured verify
# perfectly and carry a session instead of an id. They are not sessions here.
#
# What that costs is one logout for everybody holding one at the moment the
# store is switched on, which is a thing to say out loud in the documentation
# rather than a thing to discover.
{
    my (undef, $old) = Punk::Session::_seal(
        $app_obj, { user_id => 42, 'punk.exp' => time + 3600 });
    is(Punk::Session::_unseal_id($app_obj, $old), undef,
        'a cookie-session cookie carries no id, so it is no session to a '
      . 'store-backed application');
}

# An id of the wrong shape never reaches a store. The signature has already
# refused anything this server did not mint, so this is what keeps a session
# written by hand - or by a later bug - from arriving at a backend as a key of
# some other shape.
{
    my $err = do { local $@; eval { Punk::Session::_seal_id($app_obj, 'short') }; $@ };
    like($err, qr/hex id/, 'sealing refuses an id that is not one');

    $err = do { local $@; eval { Punk::Session::_seal_id($app_obj, 'g' x 32) }; $@ };
    like($err, qr/hex id/, 'including 32 characters that are not hex');

    $err = do {
        local $@;
        eval { Punk::Session::_seal_id($app_obj, '../../etc/passwd' . '0' x 16) };
        $@;
    };
    like($err, qr/hex id/,
        'and one shaped like a path, which is what a file store would have '
      . 'had to defend against');
}

# ---- the keyword's own contract ----------------------------------------------
{
    my $err = do {
        local $@;
        eval { Punk::Session::_seal_id({}, Punk::Session::_new_id()) };
        $@;
    };
    like($err, qr/needs an app with a session keyword/,
        'sealing needs a session config, not just any hashref');
}

done_testing;
