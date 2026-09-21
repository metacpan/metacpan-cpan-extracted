use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestSSHD;
use Net::LibSSH;

# The product claim of this distribution is that exec-channel operation
# works on a host with NO sftp subsystem at all, and that sftp() degrades
# to undef instead of dying. TestSSHD normally advertises "Subsystem sftp"
# whenever an sftp-server binary is found on the box running the tests, so
# on a dev machine with one installed the "no sftp" path never actually
# runs. Force it off here, regardless of what's installed.
my $srv = TestSSHD->start(sftp => 0);
unless ($srv) {
    plan skip_all => 'sshd or ssh-keygen not available';
}

ok !$srv->has_sftp, 'harness variant really has no sftp subsystem'
    or plan skip_all => 'TestSSHD unexpectedly advertised sftp; aborting';

my $ssh = Net::LibSSH->new;
$ssh->option(host       => $srv->host);
$ssh->option(port       => $srv->port);
$ssh->option(user       => scalar getpwuid($<));
$ssh->option(knownhosts => $srv->known_hosts);

ok $ssh->connect, 'connect() succeeds against sftp-free sshd'
    or diag 'connect error: ' . ($ssh->error // '');

ok $ssh->auth_publickey($srv->client_key), 'auth_publickey() succeeds'
    or diag 'auth error: ' . ($ssh->error // '');

# --- exec-channel path works fully, with no SFTP subsystem present ---

my $ch = $ssh->channel;
ok defined $ch, 'channel() returns object on sftp-free session';

ok $ch->exec('echo sftp-free-' . $$), 'exec() succeeds';
my $out = $ch->read;
chomp $out;
is $out, 'sftp-free-' . $$, 'read() returns command output over exec channel';

is $ch->exit_status, 0, 'exit_status() is 0 for successful command';
$ch->close;

# a second channel, non-zero exit, to prove exit_status is not a fluke of 0
my $ch2 = $ssh->channel;
ok $ch2->exec('exit 7'), 'exec() succeeds for failing command';
$ch2->read;   # drain before reading exit_status, per contract
is $ch2->exit_status, 7, 'exit_status() reflects non-zero exit code';
$ch2->close;

# --- sftp() must return undef, never die, when the subsystem is absent ---

my $sftp = eval { $ssh->sftp };
is $@, '', 'sftp() does not die when subsystem unavailable';
ok !defined $sftp, 'sftp() returns undef when subsystem unavailable';

$ssh->disconnect;

done_testing;
