use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use TestSSHDNoSFTP;

my $srv = TestSSHDNoSFTP->start;
unless ($srv) {
    plan skip_all => 'sshd or ssh-keygen not available';
}

# Loud sanity check — if this harness ever ends up with has_sftp=1, the test
# would silently prove nothing (an SFTP subsystem would mask any fallback
# that crept into the exec-only paths). Fail loudly instead.
ok !$srv->has_sftp, 'harness built without sftp subsystem';

use Rex -feature => ['1.4'];
use Rex::Group::Entry::Server;
use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::File;
use Rex::Config;

set connection => 'LibSSH';

Rex::Config->set_user( scalar getpwuid($<) );
Rex::Config->set_private_key( $srv->client_key );
Rex::Config->set_public_key( $srv->client_key . '.pub' );

Rex::connect(
    server      => $srv->host,
    port        => $srv->port,
    user        => scalar( getpwuid($<) ),
    private_key => $srv->client_key,
    public_key  => $srv->client_key . '.pub',
    auth_type   => 'key',
    knownhosts  => $srv->known_hosts,
);

# Every Fs/File operation must work via SSH exec channels alone. On a host
# without an SFTP subsystem, the OpenSSH/SSH backends crash with
# "Can't call method \"stat\" on an undefined value". LibSSH should sail
# through, and that is the contract this test pins down.

ok is_file('/etc/passwd'), 'is_file works without SFTP';
ok is_dir('/tmp'),         'is_dir works without SFTP';

my %st = stat('/etc/passwd');
ok $st{size} > 0,     'stat works without SFTP';
ok defined $st{uid},  'stat returns uid without SFTP';
ok defined $st{mode}, 'stat returns mode without SFTP';

my @entries = ls('/etc');
ok scalar(@entries) > 0,                            'ls returns entries without SFTP';
ok( (grep { $_ eq 'passwd' } @entries),             'ls /etc contains passwd' );

my $tmpdir = "/tmp/rex-libssh-nosftp-$$";
mkdir $tmpdir;
ok is_dir($tmpdir), 'mkdir works without SFTP';
run "rm -rf '$tmpdir'";

my $tmpfile = "/tmp/rex-libssh-nosftp-file-$$";
file $tmpfile, content => "hello no-sftp\n";
my $got = run "cat '$tmpfile'";
chomp $got;
is $got, 'hello no-sftp', 'file write works without SFTP';
run "rm -f '$tmpfile'";

my $dir = tempdir(CLEANUP => 1);
my $src = "$dir/src";
CORE::open( my $fh, '>', $src ) or die $!;
print $fh "no-sftp upload content\n";
CORE::close $fh;

upload $src, "/tmp/rex-libssh-nosftp-upload-$$";
my $upl = run "cat '/tmp/rex-libssh-nosftp-upload-$$'";
chomp $upl;
is $upl, 'no-sftp upload content', 'upload works without SFTP';

download "/tmp/rex-libssh-nosftp-upload-$$", "$dir/dl";
my $dl = do { local $/; CORE::open( my $f, '<', "$dir/dl" ) or die $!; <$f> };
chomp $dl;
is $dl, 'no-sftp upload content', 'download works without SFTP';

run "rm -f '/tmp/rex-libssh-nosftp-upload-$$'";

Rex::pop_connection();

done_testing;
