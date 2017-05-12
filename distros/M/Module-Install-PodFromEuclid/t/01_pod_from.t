use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Copy;
use File::Temp qw[tempdir];
use Config;


{
   # Prepare test
   my $ori_dir = File::Spec->rel2abs(File::Spec->curdir);
   my $tmpdir = tempdir(DIR => $ori_dir, CLEANUP => 1);
   chdir $tmpdir or die "Chdir failed: $!";
   mkdir 'script';
   my $ori  = File::Spec->catfile($ori_dir, 't', 'data', 'my_script.pl');
   my $dest = File::Spec->catfile('script', 'my_script.pl');
   copy($ori, $dest) or die "Copy failed: $!";
   open MFPL, '>Makefile.PL' or die "$!\n";
   print MFPL <<EOF;
use strict;
use inc::Module::Install;
name 'my_script';
version '0.01';
author 'John Doe';
abstract 'Check out my cool script';
license 'perl';
pod_from 'script/my_script.pl';
WriteAll;
EOF
   close MFPL;

   # Run Makefile.PL
   system "$^X Makefile.PL";
   #my $merged = Capture::Tiny->capture_merged {system "$^X Makefile.PL"}; diag("$merged");
   ok -f File::Spec->catfile('inc','Module','Install','PodFromEuclid.pm'), 'PodFromEuclid.pm exists in inc/';
   my $pod = File::Spec->catfile('script', 'my_script.pod');
   ok -f( $pod ), "POD file created: $pod";

   # Run make disclean
   SKIP: {
      skip 'because no "make" is available', 1 unless -e 'have_make';
      my $make = $Config{make};
      system "$make distclean";
      #my $distclean = Capture::Tiny->capture_merged {system "$make distclean"}; diag("$distclean");
      ok -f $pod, 'POD file remains';
   }

   chdir $ori_dir or die "Chdir failed: $!";
}

done_testing;
