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
mkdir "$tmp/usr/local/bin";
mkfile "$tmp/usr/bin/script", "#! /bin/true\n", 0755;
symlink "bin", "$tmp/usr/local/sbin";
mkfile "$tmp/usr/local/bin/script", "#! /bin/true\n", 0755;

my $exporter= Sys::Export::Unix->new(src => $tmp, dst => File::Temp->newdir);
note "exporter src: '".$exporter->src."'";

is( $exporter->src_exe_PATH, '/usr/local/bin:/usr/bin', 'src_exe_PATH' );
is( $exporter->src_which('script'), 'usr/local/bin/script', 'which "script"' );

done_testing;
