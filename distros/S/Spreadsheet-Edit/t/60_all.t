#!/usr/bin/perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp
use t_TestCommon # Test::More etc.
  qw/$silent $verbose $debug run_perlscript verif_no_internals_mentioned/;

# Run all "subtests" twice:
#
#  1. In silent mode, verifying that nothing was printed
#
#  2. In verbose+debug mode, verifying that there are no
#     full tracebacks or other mention of internal packages
#     (this checks that "caller_level" is handled correctly).
#
# "Subtests" are all the scripts called t/*.pl 

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


#--------------------------------------------------------------------------
for my $st (@subtests) {
  # The --silent argument is parsed in t_TestCommon.pm and sets the global $silent
  my ($soutput, $swstat) = tee_merged { run_subtest($st, '--silent') };
  if ($swstat != 0) {
    # Diagnostic has already been displayed
    die "$soutput\nNon-zero exit status from subtest '$st' --silent"; 
  }
  ok ($soutput eq "", basename($st)." --silent is really silent") 
    or die; # stop immediately
}
#--------------------------------------------------------------------------
for my $st (@subtests) {
  my ($doutput, $dwstat) = capture_merged { 
                             run_subtest($st,'--verbose', '--debug') };
  if ($dwstat != 0) {
    say $doutput;
    die "Non-zero exit status";
  }
  if (! eval { verif_no_internals_mentioned($doutput) }) {
    say $@;
    die "internals inappropriately mentioned in output";
  }
  note basename($st)." produced ".length($doutput)." characters\n";
  ok (1, basename($st)." --verbose --debug : no inappropriate output detected");
}

exit 0;
