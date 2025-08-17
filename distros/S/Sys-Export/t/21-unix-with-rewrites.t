use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use File::Temp;
use Sys::Export::Unix;
use File::stat;
use Fcntl qw( S_IFDIR S_IFREG S_IFLNK S_ISLNK );
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
skip_all "symlinks not supported on this host"
   unless eval { symlink "./script", "$tmp/usr/local/bin/script2" };

my $exporter= Sys::Export::Unix->new(src => $tmp, dst => File::Temp->newdir);
note "exporter src: '".$exporter->src."' dst: '".$exporter->dst."'";

# Pretend that we're assembling a standalone environment in /opt/foo
$exporter->rewrite_path('/usr/local', '/opt/foo');
$exporter->rewrite_path('/bin', '/opt/foo/bin');

$exporter->add('usr/local/bin/script2');
$exporter->add([ file => 'usr/share/mydata', <<DATA]);
ID\tNAME
1\tfoo
2\tbar
DATA
$exporter->add([ file755 => 'usr/libexec/script3', <<SH]);
#! /bin/sh
exit 1;
SH

# verify that interpreter of script got rewritten, and that interpreter of script3 did not
# because it was supplied literally rather than read from the source tree.
like( slurp($exporter->dst_abs . 'opt/foo/bin/script'), qr{^#! /opt/foo/bin/sh\n}, 'rewrite script interpreter' );
like( slurp($exporter->dst_abs . 'usr/libexec/script3'), qr{^#! /bin/sh\n}, 'no rewrite of script3 interpreter' );

my @tests= (
  [ 'opt',                    (S_IFDIR|0755) ],
  [ 'opt/foo',                (S_IFDIR|0755) ],
  [ 'opt/foo/bin',            (S_IFDIR|0755) ],
  [ 'opt/foo/bin/sh',         (S_IFREG|0755) ],
  [ 'opt/foo/bin/script',     (S_IFREG|0755) ],
  [ 'opt/foo/bin/script2',    (S_IFLNK|0777) ],
  [ 'usr/libexec/script3',    (S_IFREG|0755) ],
  [ 'usr/share/mydata',       (S_IFREG|0644) ],
);

for (@tests) {
   ok( my $stat= lstat($exporter->dst_abs . $_->[0]), "$_->[0] exists" );
   my $mode= $stat->mode;
   $mode |= 0777 if S_ISLNK($mode);
   is( $mode, $_->[1], "$_->[0] mode" );
}

done_testing;
