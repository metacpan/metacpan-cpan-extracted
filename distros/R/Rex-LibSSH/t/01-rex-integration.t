use strict;
use warnings;
use lib 't/lib';
use Test::More;
use File::Temp qw(tempdir);
use TestSSHD;

my $srv = TestSSHD->start;
unless ($srv) {
    plan skip_all => 'sshd or ssh-keygen not available';
}

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
);

# --- run ---
my $out = run 'echo hello';
chomp $out;
is $out, 'hello', 'run echo works';

# --- is_file / is_dir ---
ok  is_file('/etc/hostname'),        'is_file /etc/hostname';
ok  is_dir('/tmp'),                  'is_dir /tmp';
ok !is_file('/nonexistent/path/x'),  'is_file returns false for nonexistent';

# --- mkdir ---
my $tmpdir = "/tmp/rex-libssh-test-$$";
mkdir $tmpdir;
ok is_dir($tmpdir), 'mkdir + is_dir';
run "rm -rf '$tmpdir'";

# --- file content write + verify ---
my $tmpfile = "/tmp/rex-libssh-file-$$";
file $tmpfile, content => "hello libssh\n";
my $got = run "cat '$tmpfile'";
chomp $got;
is $got, 'hello libssh', 'file write + cat';
run "rm -f '$tmpfile'";

# --- stat ---
my %st = stat('/etc/hostname');
ok $st{size} > 0,       'stat: size > 0';
ok defined $st{uid},    'stat: uid defined';
ok defined $st{mode},   'stat: mode defined';

# --- upload + download ---
my $dir = tempdir(CLEANUP => 1);
my $src = "$dir/src";
CORE::open( my $fh, '>', $src ) or die $!;
print $fh "upload content\n";
CORE::close $fh;

upload $src, "/tmp/rex-libssh-upload-$$";
my $upl = run "cat '/tmp/rex-libssh-upload-$$'";
chomp $upl;
is $upl, 'upload content', 'upload';

download "/tmp/rex-libssh-upload-$$", "$dir/dl";
my $dl = do { local $/; CORE::open( my $f, '<', "$dir/dl" ) or die $!; <$f> };
chomp $dl;
is $dl, 'upload content', 'download';

run "rm -f '/tmp/rex-libssh-upload-$$'";

Rex::pop_connection();

done_testing;
