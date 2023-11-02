#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon # Test2::V0 etc.
  qw/$silent $verbose $debug
     run_perlscript verif_no_internals_mentioned my_capture_merged my_tee_merged/;

use Test2::Tools::Subtest qw/subtest_buffered subtest_streamed/;

# Run all "subtests" twice:
#
#  1. In silent mode, verifying that nothing was printed
#
#  2. In verbose+debug mode, verifying that there are no
#     full tracebacks or other mention of internal packages
#     (this checks that "caller_level" is handled correctly).
#
# "Subtests" are all the scripts called t/*.pl which do NOT use
#  the test harness infrastructure at all (otherwise we get trouble
#  with event mis-odering -- something I don't understand).
#

sub run_subtest(@) {
  my (@perlargs) = @_;
  my $wstat = run_perlscript(@perlargs);
  printf("ERROR: @perlargs\n  exited with WAIT STATUS %d = 0x%04X\n", $wstat, $wstat)
    if $wstat != 0;
  $wstat;
}

my @subtests = @ARGV;
if (@subtests == 0) {
  @subtests = (sort <$Bin/*.pl>);
  foreach my $subtest (@subtests) {
    say "> Found subtest $subtest";
  }
  die unless @subtests >= 4;  # update this as we add more of them
}

my $silent_skip_msg;
$silent_skip_msg = "Skipping --silent tests because \$debug or \$verbose is true" if $debug || $verbose;

my $debug_skip_msg;
$debug_skip_msg = "Skipping verbose logging checks (AUTHOR_TESTING only)"
  if !$ENV{AUTHOR_TESTING} && !$debug && !$verbose;

plan tests => ($silent_skip_msg ? 1 : scalar(@subtests)) +
              ($debug_skip_msg  ? 1 : scalar(@subtests));

# Note: --silent --verbose etc. arguments are parsed in t_TestCommon.pm

##### Run with --silent #####
SKIP: {
  skip $silent_skip_msg if $silent_skip_msg;
  for my $st (@subtests) {
    subtest_buffered with_silent => sub {
      my ($soutput, $swstat) = my_tee_merged { run_subtest($st, '--silent') };
      is($swstat, 0, "zero exit status from $st",
         "OUTPUT:$soutput<end OUTPUT>\nNon-zero exit status from subtest '$st' --silent"
        ) || return;
      like($soutput,
           # If a subtest uses Test2 it will output the usual messages. Otherwise
           # it should output nothing at all when invoked with --silent.
           qr/\A(?:(?:\#\ Seeded.*\n)? # The test system sometimes(?) puts this out first
                 (?:ok\ \d+.*\n)+    # successful test outputs
                 1\.\.\d+\n          # The final line
              )?\z/x
      ,
      "checking '$st' for silence violations",
      "<<$soutput>>\nSILENCE VIOLATED by subtest '$st' --silent"
      );
      done_testing();
    };
  }
}

SKIP: {
  skip $debug_skip_msg if $debug_skip_msg;

  # Run with --verbose (*not* --debug) and check that no internals are mentioned
  my @vdopts = ('--verbose'); # without --debug
  for my $st (@subtests) {
    subtest_buffered with_debug => sub {
      my @cmd = ($st, @vdopts);
      my ($doutput, $dwstat) = my_capture_merged { run_subtest(@cmd) };
      is($dwstat, 0, "zero subtest exit stat","output:\n$doutput");
      if (! eval { verif_no_internals_mentioned($doutput) }) {
        die "\n==================\n$doutput\n",
            $@,"\nInternals inappropriately mentioned in output from @cmd\n ";
      }
      print basename($st)." @vdopts produced ".length($doutput)." characters\n";
      print basename($st)." @vdopts : no inappropriate output detected\n";
      done_testing();
    };
  }
}

done_testing();

exit 0;
