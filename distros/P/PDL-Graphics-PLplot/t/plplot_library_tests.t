# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use PDL;
use PDL::Config;
use PDL::Graphics::PLplot;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

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

if (!$plversion->{'c_plwidth'}) {
  plan skip_all => 'plwidth not found--plplot version needs to be 5.9.10 or greater to run library tests';
}

my $tmpdir = tempdir( CLEANUP => 1 );

foreach my $plplot_test_script (@scripts) {
  my ($num) = ($plplot_test_script =~ /x(\d\d)\.pl/);
  (my $c_code = $plplot_test_script) =~ s/\.pl/c\.c/;

  # Compile C version
  my $cmd_line = "$plversion->{'C_COMPILE'} $c_code -o $tmpdir/a.out -lm $plversion->{'C_COMPILE_SUFFIX'}";
  $cmd_line = "LD_RUN_PATH=\"$plversion->{'PLPLOT_LIB'}\" $cmd_line" if $^O !~ /MSWin32/i;
  system $cmd_line;
  ok ((($? == 0) && -s "$tmpdir/a.out"), "$c_code compiled successfully");

  # Run C version
  my $devnull = File::Spec->devnull();
  my $c_output = "$tmpdir/x${num}c.svg";
  $cmd_line = "$tmpdir/a.out -dev svg -o $c_output -fam";
  $cmd_line = "echo $tmpdir/foo.svg | " . $cmd_line if $num == 14;
  system $cmd_line;
  ok ($? == 0, "C code $c_code ran successfully");

  # Run perl version
  my $perlrun = qq{"$^X" -Mblib};
  my $p_output = "$tmpdir/x${num}p.svg";
  $cmd_line = "$perlrun $plplot_test_script -dev svg -o $p_output -fam";
  $cmd_line = "echo $tmpdir/foo.svg | " . $cmd_line if $num == 14;
  system $cmd_line;
  ok ($? == 0, "Script $plplot_test_script ran successfully");
  my @output = glob ("$tmpdir/x${num}p.svg*");
  foreach my $perlfile (@output) {
    (my $reffile = $perlfile) =~ s/x(\d\d)p/x${1}c/;
    cmp_files($perlfile, $reffile);
  }
}

done_testing;

sub cmp_files {
  my ($perlfile, $reffile) = @_;
  my $perldata = do { local( @ARGV, $/ ) = $perlfile; <> } ; # slurp!
  my $refdata  = do { local( @ARGV, $/ ) = $reffile; <> } ; # slurp!
  ok $perldata eq $refdata, "Output file $perlfile matches C output"
    or diag "$perlfile: " . length($perldata) . ", $reffile: " . length($refdata);
}

# Local Variables:
# mode: cperl
# End:
