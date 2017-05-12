# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use PDL;
use PDL::Config;
use PDL::Graphics::PLplot;
use Test::More;
use File::Spec;

# These tests are taken from the plplot distribution.  The reference results
# are also from the plplot distribution--they are the results of running
# the C language test suite.  D. Hunt May 6, 2011

# Determine if we are running these tests from the build directory
# or the 't' directory.
my $cwd = '.';
my @scripts = glob ("./x??.pl");
unless (@scripts) {
  @scripts = glob ("./t/x??.pl");
  $cwd = 't';
}

my $maindir = '..' if (-s "../OPTIONS!");
   $maindir = '.'  if (-s "./OPTIONS!");
my $plversion = do "$maindir/OPTIONS!";

if ($plversion->{'c_plwidth'}) {
  plan qw(no_plan);
} else {
  plan skip_all => 'plwidth not found--plplot version needs to be 5.9.10 or greater to run library tests';
}

foreach my $plplot_test_script (@scripts) {
  my ($num) = ($plplot_test_script =~ /x(\d\d)\.pl/);
  (my $c_code = $plplot_test_script) =~ s/\.pl/c\.c/;

  # Compile C version
  unlink ("a.out");
  if($^O =~ /MSWin32/i) { # A Windows system
    my $cmd = $plversion->{'C_COMPILE'};
    my $cc = $Config::Config{'cc'};
    $cmd =~ s/\\/\//g; # Convert all backslashes to forward slashes
    $cmd =~ s/\Q$cc\E/\Q$cc $c_code\E/; # Insert source file into the command
    $cmd =~ s/\\//g;   # Remove all backskashes
    system("$cmd -o a.out");
  } else { # A UNIX system
    system "LD_RUN_PATH=\"$plversion->{'PLPLOT_LIB'}\" $plversion->{'C_COMPILE'} $c_code -lm -o a.out";
  }
  ok ((($? == 0) && -s "a.out"), "$c_code compiled successfully");

  # Run C version
  my $devnull = File::Spec->devnull();
  my $dot_slash = $^O =~ /MSWin32/i ? '' : './';
  if ($num == 14) {
    system "echo foo.svg | ${dot_slash}a.out -dev svg -o x${num}c.svg -fam > $devnull 2>&1";
  } else {
    system "${dot_slash}a.out -dev svg -o x${num}c.svg -fam > $devnull 2>&1";
  }
  ok ($? == 0, "C code $c_code ran successfully");

  # Run perl version
  my $perlrun = 'perl -Mblib';
  if ($num == 14) {
    system "echo foo.svg | $perlrun $plplot_test_script -dev svg -o x${num}p.svg -fam > $devnull 2>&1";
  } else {
    system "$perlrun $plplot_test_script -dev svg -o x${num}p.svg -fam > $devnull 2>&1";
  }
  ok ($? == 0, "Script $plplot_test_script ran successfully");
  my @output = glob ("x${num}p.svg*");
  foreach my $outfile (@output) {
    (my $reffile = $outfile) =~ s/x(\d\d)p/x${1}c/;
    my $perldata = do { local( @ARGV, $/ ) = $outfile; <> } ; # slurp!
    my $refdata  = do { local( @ARGV, $/ ) = $reffile; <> } ; # slurp!
    ok ($perldata eq $refdata, "Output file $outfile matches C output");
  }
}


# comment this out for testing!!!
unlink glob ("$cwd/x???.svg.*");
unlink glob ("$cwd/foo.svg.*");
unlink "$cwd/a.out";

# Local Variables:
# mode: cperl
# End:
