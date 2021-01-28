use strict;
use warnings;

use Test::More;
use FindBin;
use TAP::Harness;

SKIP: {
  eval "use SQL::Abstract::Classic; 1"
    or skip "SQL::Abstract::Classic is not installed on this system";

  open my $fh, ">", \my $tap_output;
  my $harness = TAP::Harness->new({ stdout => $fh});

  $ENV{SQL_ABSTRACT_MORE_EXTENDS} = 'Classic';
  undef $ENV{SQLA_SRC_DIR};

  diag "Running the test suite with option -extends => 'Classic'";
  my @tests = glob "$FindBin::Bin/../*.t";
  my $aggr = $harness->runtests(@tests);

  diag $tap_output;
  ok $aggr->all_passed, "tests against -extends => 'Classic'";
}


done_testing;
