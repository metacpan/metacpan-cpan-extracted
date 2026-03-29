use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;
use Net::LibSSH;

my $srv = TestSSHD->start;
unless ($srv) {
    plan skip_all => 'sshd or ssh-keygen not available';
}

# --- connect + auth ---

my $ssh = Net::LibSSH->new;
$ssh->option(host    => $srv->host);
$ssh->option(port    => $srv->port);
$ssh->option(user    => scalar getpwuid($<));
$ssh->option(knownhosts => '/dev/null');

ok $ssh->connect, 'connect() succeeds'
    or diag 'connect error: ' . ($ssh->error // '');

ok $ssh->auth_publickey($srv->client_key), 'auth_publickey() succeeds'
    or diag 'auth error: ' . ($ssh->error // '');

# --- channel + exec ---

my $ch = $ssh->channel;
ok defined $ch, 'channel() returns object';

ok $ch->exec('echo hello'), 'exec() succeeds';
my $out = $ch->read;
chomp $out;
is $out, 'hello', 'read() returns command output';

is $ch->exit_status, 0, 'exit_status() is 0 for successful command';
$ch->close;

# exec a failing command
my $ch2 = $ssh->channel;
$ch2->exec('exit 42');
$ch2->read;   # drain
is $ch2->exit_status, 42, 'exit_status() reflects non-zero exit code';
$ch2->close;

# --- sftp ---

SKIP: {
    skip 'sftp-server not available', 3 unless $srv->has_sftp;

    my $sftp = $ssh->sftp;
    ok defined $sftp, 'sftp() returns object when subsystem available';

    my $attr = $sftp->stat('/etc/hostname');
    ok defined $attr, 'stat() returns hashref for existing path';
    ok $attr->{size} > 0, 'stat() size is positive';
}

# --- sftp on server without subsystem ---
# This is implicitly tested by TestSSHD: if has_sftp is false,
# sftp() must return undef without dying.
unless ($srv->has_sftp) {
    my $sftp = eval { $ssh->sftp };
    is $@, '', 'sftp() does not die when subsystem unavailable';
    ok !defined $sftp, 'sftp() returns undef when subsystem unavailable';
}

done_testing;
