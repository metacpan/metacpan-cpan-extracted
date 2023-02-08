#!/usr/bin/perl
use strict; use warnings; use feature qw(say state);

# Run all "subtests" twice:
#
#  1. In silent mode, verifying that nothing was printed
#
#  2. In verbose+debug mode, verifying that there are no
#     full tracebacks or other mention of internal packages
#     (this checks that "caller_level" is handled correctly).
#
# "Subtests" are all the scripts called t/*.pl 

use Test::More;

use FindBin qw($Bin);
use lib $Bin;

# N.B. t_Setup parses and removes -d/--debug etc. from @ARGV
# and sets $debug, etc. but this wrapper ignores them.
use t_Setup;

use t_Utils;

use Getopt::Long qw(GetOptions);
use Capture::Tiny qw/capture_merged tee_merged/;
use File::Basename qw(dirname basename);

sub run_subtest($@) {
  my ($subtest, @args) = @_;
  my @cmd = ($^X, $Carp::Verbose ? ("-MCarp=verbose"):(), $subtest, @args);
  my $wstat = system @cmd;
  say "ERROR: Command  @cmd\n",
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
  my ($soutput, $swstat) = tee_merged { run_subtest($st, '--silent') };
  if ($swstat != 0) {
    # Diagnostic has already been displayed
    die "Non-zero exit status"; 
  }
  ok ($soutput eq "", basename($st)." --silent is really silent") or die;
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
