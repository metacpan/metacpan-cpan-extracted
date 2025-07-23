use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use File::Temp;
use Sys::Export::Unix;
use File::stat;
use Fcntl qw( S_IFDIR S_IFREG S_IFLNK );
use autodie;

# Set up some symlinks
my $tmp= File::Temp->newdir;
umask 022;
mkdir "$tmp/bin";
mkfile "$tmp/bin/sh", "not actually testing ELF rewrite yet", 0755;
mkdir "$tmp/usr";
mkdir "$tmp/usr/local";
mkdir "$tmp/usr/local/bin";
mkfile "$tmp/usr/local/bin/script", "#! /bin/sh\n", 0755;
symlink "./script", "$tmp/usr/local/bin/script2";

my $exporter= Sys::Export::Unix->new(src => $tmp, dst => File::Temp->newdir);
note "exporter src: '".$exporter->src."' dst: '".$exporter->dst."'";

# Pretend that we're assembling a standalone environment in /opt/foo
$exporter->rewrite_path('/usr/local', '/opt/foo');
$exporter->rewrite_path('/bin', '/opt/foo/bin');

$exporter->add('usr/local/bin/script2');

my @tests= (
  [ 'opt',                    (S_IFDIR|0755) ],
  [ 'opt/foo',                (S_IFDIR|0755) ],
  [ 'opt/foo/bin',            (S_IFDIR|0755) ],
  [ 'opt/foo/bin/sh',         (S_IFREG|0755) ],
  [ 'opt/foo/bin/script',     (S_IFREG|0755) ],
  [ 'opt/foo/bin/script2',    (S_IFLNK|0777) ],
);

for (@tests) {
   ok( my $stat= lstat($exporter->dst_abs . $_->[0]), "$_->[0] exists" );
   is( $stat->mode, $_->[1], "$_->[0] mode" );
}

done_testing;
