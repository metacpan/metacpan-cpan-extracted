#!/usr/bin/env perl
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Time::HiRes qw(time);
use FakeSSHD;
use Net::LibSSH;

# Devices such as Cisco Small Business switches let the SSH layer in without
# authentication and then run their own "User Name:" / "Password:" dialog on
# an interactive shell. That needs auth "none", a pty, a shell, and reads that
# give up after a while instead of blocking for good.
#
# The server is t/lib/fake-sshd.c -- libssh's own server API, compiled against
# the same Alien::libssh -- because OpenSSH's sshd offers auth "none" only to
# an account with an empty password. Every assertion below that needs a
# working login runs inside eval so that, against a build without these
# methods, the file fails with named assertions rather than dying on the
# first call.

my $probe = FakeSSHD->start;
plan skip_all => 'no C compiler: cannot build t/lib/fake-sshd.c' unless $probe;
undef $probe;

# Everything below drives these; without them the rest cannot say anything
# useful, so stop here with one clear failure instead of a cascade.
ok( Net::LibSSH->can('auth_none')
    && Net::LibSSH::Channel->can('request_pty')
    && Net::LibSSH::Channel->can('request_shell')
    && Net::LibSSH::Channel->can('read_timeout'),
    'auth_none, request_pty, request_shell and read_timeout exist'
) or do { done_testing; exit 1 };

sub connect_fake {
    my ($srv) = @_;
    my $ssh = Net::LibSSH->new;
    $ssh->option(host       => $srv->host);
    $ssh->option(port       => $srv->port);
    $ssh->option(user       => 'switch');
    $ssh->option(knownhosts => $srv->known_hosts);
    $ssh->option(timeout    => 10);
    $ssh->connect or die 'connect failed: ' . ($ssh->error // '');
    return $ssh;
}

# Read until $re matches the accumulated output or $secs pass; returns it.
sub read_until {
    my ($ch, $re, $secs) = @_;
    my $got = '';
    my $end = time + ($secs // 5);
    while (time < $end && $got !~ $re) {
        my $r = $ch->read_timeout(0.5);
        last unless defined $r;
        $got .= $r;
    }
    return $got;
}

# --- auth_none, pty, shell, and the whole dialog ---

{
    my $srv = FakeSSHD->start;
    my $ssh = connect_fake($srv);

    ok eval { $ssh->auth_none }, 'auth_none() succeeds against a server that allows none'
        or diag $@;

    my $ch = $ssh->channel;
    ok $ch, 'channel() opens after auth_none';

    ok eval { $ch->request_pty(132, 50, 'vt100') }, 'request_pty(132, 50, "vt100") succeeds'
        or diag $@;
    ok eval { $ch->request_shell }, 'request_shell() succeeds' or diag $@;

    is eval { read_until($ch, qr/User Name:\z/) }, "\r\nUser Name:",
        'the login prompt arrives through timed reads' or diag $@;

    my $t0 = time;
    is eval { $ch->read_timeout(0.3) }, '',
        'read_timeout() returns the empty string when nothing arrives in time' or diag $@;
    my $took = time - $t0;
    cmp_ok $took, '>=', 0.25, 'and it really waited for the timeout';
    cmp_ok $took, '<',  2,    'but not much longer';

    is $ch->write("cisco\r"), 6, 'write() sends the user name to the shell';
    is eval { read_until($ch, qr/Password:\z/) }, "\r\nPassword:",
        'the password prompt follows' or diag $@;
    $ch->write("wrong\r");
    is eval { read_until($ch, qr/User Name:\z/) }, "\r\nUser Name:",
        'a wrong login brings the first prompt back' or diag $@;

    $ch->write("cisco\r");
    read_until($ch, qr/Password:\z/);
    $ch->write("secret\r");
    is eval { read_until($ch, qr/switch#\z/) }, "\r\nswitch#",
        'the right login reaches the device prompt' or diag $@;

    $ch->write("echo hello\r");
    is eval { read_until($ch, qr/switch#\z/) }, "\r\nhello\r\nswitch#",
        'a command round-trips through write() and read_timeout()' or diag $@;

    $ch->write("pty\r");
    is eval { read_until($ch, qr/switch#\z/) }, "\r\nvt100 132x50\r\nswitch#",
        'the server saw the terminal type and window size that were requested' or diag $@;

    # A slow device: nothing for a while, then the answer.
    $ch->write("slow\r");
    is eval { $ch->read_timeout(0.3) }, '', 'a slow command: first a timeout' or diag $@;
    is eval { $ch->read_timeout(0) }, '',  'read_timeout(0) polls without waiting' or diag $@;
    is eval { read_until($ch, qr/switch#\z/, 6) }, "\r\ndone\r\nswitch#",
        'and the answer arrives on a later read' or diag $@;

    # read_timeout(0) is a poll, not a read of nothing: it picks data up.
    $ch->write("echo polled\r");
    my $got = '';
    my $end = time + 5;
    while (time < $end && $got !~ /switch#\z/) {
        my $r = eval { $ch->read_timeout(0) };
        $got .= $r if defined $r;
        select undef, undef, undef, 0.05;
    }
    is $got, "\r\npolled\r\nswitch#", 'read_timeout(0) returns data that has arrived';

    # End of file is undef, which a timeout is not.
    $ch->write("logout\r");
    is eval { $ch->read_timeout(5) }, "\r\nbye\r\n", 'the farewell is still delivered' or diag $@;
    ok !defined eval { $ch->read_timeout(5) } && !$@,
        'read_timeout() returns undef at end of file' or diag $@;
    ok !defined eval { $ch->read_timeout(0) } && !$@,
        'and keeps returning undef afterwards, even for a poll' or diag $@;
    is $ch->eof, 1, 'eof() agrees';
    $ch->close;
}

# --- an error is a croak, not an empty string and not undef ---

{
    my $srv = FakeSSHD->start;
    my $ssh = connect_fake($srv);
    eval { $ssh->auth_none; 1 } or diag $@;
    my $ch = $ssh->channel;
    eval { $ch->request_pty; $ch->request_shell; 1 } or diag $@;
    read_until($ch, qr/User Name:\z/);

    kill 'KILL', $srv->{pid};
    waitpid $srv->{pid}, 0;
    $srv->{pid} = 0;

    my $r = eval { $ch->read_timeout(2) };
    like $@, qr/\ANet::LibSSH::Channel::read_timeout: /,
        'a dropped connection croaks, telling it apart from end of file and from a timeout';
    ok !defined $r, 'and returns nothing';
}

# --- request_pty() without a size uses libssh's default ---

{
    my $srv = FakeSSHD->start;
    my $ssh = connect_fake($srv);
    eval { $ssh->auth_none; 1 } or diag $@;
    my $ch = $ssh->channel;
    ok eval { $ch->request_pty }, 'request_pty() with no arguments succeeds' or diag $@;
    ok eval { $ch->request_shell }, 'request_shell() succeeds' or diag $@;
    read_until($ch, qr/User Name:\z/);
    $ch->write("cisco\rsecret\r");
    read_until($ch, qr/switch#\z/);
    $ch->write("pty\r");
    is eval { read_until($ch, qr/switch#\z/) }, "\r\nxterm 80x24\r\nswitch#",
        'the default is xterm, 80x24' or diag $@;
    $ch->close;
}

# --- argument checks: these are croaks, not libssh's silent zeroes ---

{
    my $srv = FakeSSHD->start;
    my $ssh = connect_fake($srv);
    eval { $ssh->auth_none; 1 } or diag $@;
    my $ch = $ssh->channel;

    for my $bad (
        [ 'a lone column count',  [ 100 ] ],
        [ 'zero columns',         [ 0, 24 ] ],
        [ 'a negative row count', [ 80, -1 ] ],
        [ 'a non-numeric size',   [ 'wide', 24 ] ],
        [ 'a huge size',          [ 80, 70000 ] ],
        [ 'an empty term',        [ 80, 24, '' ] ],
        [ 'too many arguments',   [ 80, 24, 'vt100', 'x' ] ],
    ) {
        my ($what, $args) = @$bad;
        eval { $ch->request_pty(@$args) };
        like $@, qr/request_pty/, 'request_pty() croaks on ' . $what;
    }

    for my $bad (
        [ 'a negative timeout',       [ -1 ] ],
        [ 'a non-numeric timeout',    [ 'soon' ] ],
        [ 'an undefined timeout',     [ undef ] ],
        [ 'a zero length',            [ 1, 0 ] ],
    ) {
        my ($what, $args) = @$bad;
        no warnings 'uninitialized';
        eval { $ch->read_timeout(@$args) };
        like $@, qr/read_timeout/, 'read_timeout() croaks on ' . $what;
    }
    eval { $ch->read_timeout };
    like $@, qr/Usage|seconds/, 'read_timeout() needs a timeout';

    ok eval { $ch->request_pty; $ch->request_shell },
        'the channel is still usable after the refused arguments';
    $ch->close;

    for my $call (
        [ request_pty   => sub { $ch->request_pty } ],
        [ request_shell => sub { $ch->request_shell } ],
        [ read_timeout  => sub { $ch->read_timeout(0) } ],
    ) {
        my ($name, $code) = @$call;
        eval { $code->() };
        like $@, qr/\ANet::LibSSH::Channel::\Q$name\E: channel is closed/,
            $name . '() croaks on a closed channel';
    }
}

{
    my $srv = FakeSSHD->start;
    my $ssh = connect_fake($srv);
    eval { $ssh->auth_none; 1 } or diag $@;
    my $ch = $ssh->channel;
    $ssh->disconnect;
    for my $call (
        [ request_pty   => sub { $ch->request_pty } ],
        [ request_shell => sub { $ch->request_shell } ],
        [ read_timeout  => sub { $ch->read_timeout(0) } ],
    ) {
        my ($name, $code) = @$call;
        eval { $code->() };
        like $@, qr/\ANet::LibSSH::Channel::\Q$name\E: session was disconnected/,
            $name . '() croaks after disconnect()';
    }
}

# --- length and stderr selector ---

# The fake server has no exec, so the stderr selector is only checked for
# plumbing: with a pty there is no separate stderr, so it is silent.
{
    my $srv = FakeSSHD->start;
    my $ssh = connect_fake($srv);
    eval { $ssh->auth_none; 1 } or diag $@;
    my $ch = $ssh->channel;
    eval { $ch->request_pty; $ch->request_shell; 1 } or diag $@;
    is eval { $ch->read_timeout(0.2, 100, 1) }, '',
        'read_timeout($s, $len, $is_stderr) reads stderr, which a pty shell leaves empty'
        or diag $@;
    is eval { $ch->read_timeout(2, 4) }, "\r\nUs", 'the length argument caps one read'
        or diag $@;
    is eval { read_until($ch, qr/Name:\z/) }, 'er Name:', 'and the rest is still there'
        or diag $@;
}

# --- auth_none against a real sshd: refused, and the shell still works ---

require TestSSHD;
my $real = TestSSHD->start;
if ($real) {
    my $ssh = Net::LibSSH->new;
    $ssh->option(host       => $real->host);
    $ssh->option(port       => $real->port);
    $ssh->option(user       => scalar getpwuid($<));
    $ssh->option(knownhosts => $real->known_hosts);
    $ssh->connect or die 'connect failed: ' . ($ssh->error // '');

    my $r = eval { $ssh->auth_none };
    is $r, 0, 'auth_none() returns 0, not a croak, when the server wants real credentials'
        or diag $@;
    ok $ssh->auth_publickey($real->client_key), 'a real login still works afterwards';

    my $ch = $ssh->channel;
    ok eval { $ch->request_pty(100, 30) }, 'request_pty() on an OpenSSH server' or diag $@;
    ok eval { $ch->request_shell },        'request_shell() on an OpenSSH server' or diag $@;
    $ch->write("echo MARK\$((6*7))END\n");
    like eval { read_until($ch, qr/MARK42END/, 10) } // '', qr/MARK42END/,
        'a command typed into the shell is answered' or diag $@;
    $ch->write("exit\n");
    my $end = time + 10;
    my $r2 = '';
    while (time < $end && defined $r2) {
        $r2 = eval { $ch->read_timeout(0.5) };
    }
    ok !defined $r2 && !$@, 'and "exit" ends the stream with undef, not an error' or diag $@;
    $ch->close;
}
else {
    diag 'no sshd or ssh-keygen: the OpenSSH part of this file did not run';
}

done_testing;
