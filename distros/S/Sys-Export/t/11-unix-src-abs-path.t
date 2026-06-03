use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Cwd 'abs_path';
use Test2AndUtils;
use experimental qw( signatures );
use File::Temp;
use Sys::Export::Unix;
use autodie;

# Set up some symlinks
my $tmp= File::Temp->newdir;
my $tmp_abs= abs_path($tmp);
mkdir "$tmp/usr";
skip_all "Can't symlink on this host"
   unless eval { symlink "/usr/bin", "$tmp/bin" };
mkdir "$tmp/usr/bin";
mkdir "$tmp/usr/local";
open my $out, '>', "$tmp/usr/local/datafile";
$out->print("Just some data");
$out->close;
symlink "/bin", "$tmp/usr/local/bin";
symlink "bin", "$tmp/usr/local/sbin";
symlink "$tmp_abs", "$tmp/self";

my $exporter= Sys::Export::Unix->new(src => $tmp, dst => File::Temp->newdir);
note "exporter src: '".$exporter->src."'";

for (
   [ 'usr/local/bin'      => 'usr/bin' ],
   [ 'usr/local/./bin'    => 'usr/bin' ],
   [ 'usr/local/sbin'     => 'usr/bin' ],
   [ 'usr/local/../../bin'=> 'usr/bin' ],
   [ 'usr/local/datafile' => 'usr/local/datafile' ],
) {
   is( $exporter->_src_abs_path( $_->[0] ), $_->[1], $_->[0] );
}

$exporter= Sys::Export::Unix->new(src => '/', dst => File::Temp->newdir);
note "exporter src: '".$exporter->src."'";
for (
   [ "$tmp_abs/self"               => substr($tmp_abs,1) ],
   # hide these from systems where /bin is a symlink or doesn't exist
   (-d '/bin' && !-l '/bin'? (
      [ "$tmp_abs/usr/local/bin"      => 'bin' ],
      [ "$tmp_abs/usr/local/sbin"     => 'bin' ]
   ) : ()),
) {
   is( $exporter->_src_abs_path( $_->[0] ), $_->[1], $_->[0] );
}

done_testing;
