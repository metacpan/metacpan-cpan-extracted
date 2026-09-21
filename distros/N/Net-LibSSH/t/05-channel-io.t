use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;
use Net::LibSSH;

# Channel read()/write() contract points that t/02-integration.t never
# exercises: explicit-length reads, reading from stderr, the documented
# read(undef) trap, write()+send_eof() into a command that blocks on
# stdin, eof() after the remote side closes, and binary data (NUL and
# high bytes) surviving the round trip unmangled.

my $srv = TestSSHD->start;
plan skip_all => 'sshd or ssh-keygen not available' unless $srv;

my $ssh = Net::LibSSH->new;
$ssh->option(host       => $srv->host);
$ssh->option(port       => $srv->port);
$ssh->option(user       => scalar getpwuid($<));
$ssh->option(knownhosts => $srv->known_hosts);

$ssh->connect
    or plan skip_all => 'connect failed: ' . ($ssh->error // '');
$ssh->auth_publickey($srv->client_key)
    or plan skip_all => 'auth failed: ' . ($ssh->error // '');

# --- read($length) ---

{
    my $ch = $ssh->channel;
    ok $ch->exec('printf 0123456789'), 'exec() succeeds';
    is $ch->read(4), '0123', 'read($length) returns exactly the requested number of bytes';
    is $ch->read(4), '4567', 'a second read($length) continues where the first left off';
    is $ch->read,    '89',   'read() with no argument slurps the remainder';
    is $ch->exit_status, 0, 'exit_status() after the output was fully drained';
    $ch->close;
}

# --- read($length, $is_stderr) ---

{
    my $ch = $ssh->channel;
    ok $ch->exec('sh -c "printf STDERRDATA >&2"'), 'exec() succeeds';
    is $ch->read,        '',      'nothing arrives on stdout';
    is $ch->read(5, 1),  'STDER', 'read($length, $is_stderr) reads from stderr, not stdout';
    is $ch->read(-1, 1), 'RDATA', 'read(-1, $is_stderr) slurps the remaining stderr';
    $ch->close;
}

# --- read(undef) is a documented trap ---
#
# SvIV(undef) is 0, so read(undef) is NOT "no length limit" -- it is
# interpreted as an explicit zero-length read and returns "". Verified
# directly against LibSSH.xs: `if (items >= 2) len = SvIV(ST(1));` runs
# for a literal undef argument same as for any other scalar, then
# `len < 0` is false for len == 0, so this takes the explicit-length
# branch with length 0 rather than the slurp-until-EOF branch. The POD's
# warning matches what the code actually does.

{
    my $ch = $ssh->channel;
    ok $ch->exec('echo trap_test_' . $$), 'exec() succeeds';
    my $r;
    {
        no warnings 'uninitialized';
        $r = $ch->read(undef);
    }
    is $r, '', 'read(undef) returns empty string, not the command output';
    is $ch->read, "trap_test_$$\n",
        'the output was not lost -- a later read() still returns it in full';
    $ch->close;
}

# --- write() + send_eof() into a command that reads stdin ---

{
    my $ch = $ssh->channel;
    ok $ch->exec('cat'), 'exec(cat) succeeds';
    my $payload = 'roundtrip test data ' . ('X' x 50) . ' ' . $$ . "\n";
    my $n = $ch->write($payload);
    is $n, length($payload), 'write() returns the number of bytes written';
    $ch->send_eof;
    is $ch->read, $payload,
        'send_eof() lets cat observe EOF on stdin and echo the input back unchanged';
    is $ch->exit_status, 0, 'cat exits 0';
    $ch->close;
}

{
    my $ch = $ssh->channel;
    ok $ch->exec('wc -c'), 'exec(wc -c) succeeds';
    my $payload = 'y' x 12345;
    $ch->write($payload);
    $ch->send_eof;
    my $out = $ch->read;
    $out =~ s/^\s+|\s+\z//g;
    is $out, '12345',
        'wc -c only reports a count (and terminates) once send_eof signals end of input';
    $ch->close;
}

# --- eof() after the remote side closes ---

{
    my $ch = $ssh->channel;
    is $ch->eof, 0, 'eof() is false on a freshly opened channel';
    ok $ch->exec('echo eof_test_' . $$), 'exec() succeeds';
    is $ch->read, "eof_test_$$\n", 'read() drains the output';
    is $ch->eof, 1, 'eof() is true once the remote side has closed its stdout';
    $ch->close;
}

# --- binary data through write()/read() ---

{
    my $ch = $ssh->channel;
    ok $ch->exec('cat'), 'exec(cat) succeeds';
    my $bin = join('', map { chr($_) } 0 .. 255) x 4;   # includes NUL and high bytes
    my $n = $ch->write($bin);
    is $n, length($bin), 'write() reports the full binary length written';
    $ch->send_eof;
    my $out = '';
    while (1) {
        my $chunk = $ch->read(8192);
        last if length($chunk) == 0;
        $out .= $chunk;
    }
    is length($out), length($bin),
        'binary round trip preserves length (no truncation at a NUL byte)';
    is $out, $bin,
        'binary round trip preserves every byte through write()/read(), including NUL and high bytes';
    $ch->close;
}

done_testing;
