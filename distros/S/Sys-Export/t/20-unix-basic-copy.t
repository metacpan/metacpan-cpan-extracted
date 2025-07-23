use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Test2AndUtils;
use experimental qw( signatures );
use Sys::Export::Unix;
use File::stat;
use Fcntl qw( S_IFDIR S_IFREG S_IFLNK );
use autodie;

# Set up some symlinks
my $tmp= File::Temp->newdir;
umask 022;
mkdir "$tmp/usr";
mkdir "$tmp/usr/local";
chmod 0700, "$tmp/usr";
mkfile "$tmp/usr/local/datafile", "Just some data\n";
symlink "./datafile", "$tmp/usr/local/datafile2";

my $exporter= Sys::Export::Unix->new(src => $tmp, dst => File::Temp->newdir);
note "exporter src: '".$exporter->src."' dst: '".$exporter->dst."'";

$exporter->add('usr/local/datafile2');

my @tests= (
  [ 'usr',                 (S_IFDIR|0700) ],
  [ 'usr/local',           (S_IFDIR|0755) ],
  [ 'usr/local/datafile',  (S_IFREG|0644) ],
  [ 'usr/local/datafile2', (S_IFLNK|0777) ],
);

for (@tests) {
   ok( my $stat= lstat($exporter->dst_abs . $_->[0]), "$_->[0] exists" );
   is( $stat->mode, $_->[1], "$_->[0] mode" );
}

done_testing;
