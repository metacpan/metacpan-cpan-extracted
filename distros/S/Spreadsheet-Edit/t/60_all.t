#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon # Test::More etc.
  qw/$silent $verbose $debug run_perlscript verif_no_internals_mentioned/;

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
#  with even mis-odering, or something like that).
#

use Capture::Tiny qw/capture_merged tee_merged/;

sub run_subtest($@) {
  my ($subtest, @args) = @_;
  my $wstat = run_perlscript($subtest, @args);
  say "ERROR: $subtest @args\n",
      sprintf("  exited with WAIT STATUS 0x%04X\n", $wstat)
    if $wstat != 0;
  $wstat;
}

my @subtests = @ARGV;
if (@subtests == 0) {
  @subtests = (<$Bin/*.pl>);
  foreach my $subtest (@subtests) {
    say "> Found subtest $subtest";
  }
  die unless @subtests >= 4;  # update this as we add more of them
}

plan tests => scalar(@subtests) * 2;

# Note: --silent --debug etc. arguments are parsed in t_TestCommon.pm

##### Run with --silent ##### 
for my $st (@subtests) {
  subtest_buffered with_silent => sub {
    my ($soutput, $swstat) = tee_merged { run_subtest($st, '--silent') };
    ok($swstat == 0, "zero subtest exit status",
       "$soutput\nNon-zero exit status from subtest '$st' --silent"
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

##### Run with --verbose --debug #####
for my $st (@subtests) {
  subtest_buffered with_debug => sub {
    my ($doutput, $dwstat) = capture_merged { 
                               run_subtest($st,'--verbose', '--debug') };
    is($dwstat, 0, "zero subtest exit stat");
    if (! eval { verif_no_internals_mentioned($doutput) }) {
      say $@;
      die "internals inappropriately mentioned in output from $st";
    }
    print basename($st)." --verbose --debug produced ".length($doutput)." characters\n";
    print basename($st)." --verbose --debug : no inappropriate output detected\n";
    done_testing();
  };
}

exit 0;
