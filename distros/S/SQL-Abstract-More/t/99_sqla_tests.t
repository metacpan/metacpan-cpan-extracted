use strict;
use warnings;

use Test::More;
use FindBin;
use TAP::Harness;

plan tests => 1;

SKIP: {
  $ENV{SQLA_SRC_DIR} or do {
    my $msg = 'define $ENV{SQLA_SRC_DIR} to run these tests';
    diag $msg;
    skip $msg, 1;
  };

  open my $fh, ">", \my $tap_output;

  # all regular SQL::Abstract tests will be run, but through the source filter
  # "UsurpSQLA" which is located in this t/lib directory. That filter replaces
  # SQL::Abstract by SQL::Abstract::More in the source code.
  my $harness = TAP::Harness->new({
    lib       => ["$ENV{SQLA_SRC_DIR}/lib", "$FindBin::Bin/lib", @INC],
    switches  => ["-MUsurpSQLA"],
    stdout => $fh,
  });

  my @tests = glob "$ENV{SQLA_SRC_DIR}/t/*.t $ENV{SQLA_SRC_DIR}/t/*/*.t";

  diag "Running the whole SQLA test suite through SQLAM..";
  my $aggr = $harness->runtests(@tests);
  diag $tap_output;
  ok $aggr->all_passed, "SQLA tests against SQLAM";
}



