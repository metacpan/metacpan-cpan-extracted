use v5.26;
use warnings;
use lib (__FILE__ =~ s,[^\\/]+$,lib,r);
use Cwd 'abs_path';
use Test2AndUtils;
use experimental qw( signatures );
use Sys::Export::Unix;
use autodie;

# Set up some symlinks
my $tmp= tmpdir;
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

subtest defaults => sub {
   my $exporter= Sys::Export::Unix->new(src => $tmp, dst => tmpdir);
   note "exporter src: '".$exporter->src."'";

   is( $exporter->src_exe_path, '/usr/local/bin:/usr/bin', 'src_exe_path' );
   is( $exporter->src_which('script'), 'usr/local/bin/script', 'which "script"' );
};

# When src is '/', $PATH gets added to src_exe_path
subtest include_PATH => sub {
   skip_all "exporting '/' doesn't make sense on Win32"
      if $^O eq 'MSWin32';

   mkdir "$tmp/opt";
   mkdir "$tmp/opt/bin";
   mkdir "$tmp/opt/bin2";
   
   my $unique_name= "probably-doesnt-exist-on-host-".int(rand(9999));
   mkfile "$tmp/opt/bin2/$unique_name", "#! /bin/true\n", 0755;

   local $ENV{PATH}= "$tmp_abs/opt/bin:$tmp_abs/opt/bin2";
   
   my $exporter= Sys::Export::Unix->new(src => '/', dst => tmpdir);
   note "exporter src: '".$exporter->src."'";

   # No guarantees which host bin directories exist, but make sure our custom ones
   # from $PATH got added
   like( $exporter->src_exe_path, qr{\Q$tmp_abs/opt/bin:$tmp_abs/opt/bin2\E}, 'src_exe_path' );
   is( $exporter->src_which($unique_name), substr("$tmp_abs/opt/bin2/$unique_name",1), qq{which "$unique_name"} );
};

done_testing;
