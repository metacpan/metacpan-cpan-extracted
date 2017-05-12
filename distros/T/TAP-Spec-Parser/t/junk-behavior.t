#!/usr/bin/perl
use strict;
use warnings;

use TAP::Spec::Parser;
use Test::More;

my $result = eval {
  TAP::Spec::Parser->parse_from_string(
    <<EOTAP
1..3
ok 1
ok 2
1..1
ok 3
EOTAP
  );
};

my $error = $@;
ok !$result, "No parse for invalid TAP";
like $error, qr/expecting/, "Parse error for invalid TAP";

$result = eval {
  TAP::Spec::Parser->parse_from_string(
    <<EOTAP
1..3
ok 1
ok 2
this is junk
ok 3
EOTAP
  );
};

$error = $@;
ok $result, "Got parse for valid TAP with junk";
ok !$error, "No parse error for valid TAP with junk";
ok $result->passed, "Valid TAP passed tests";
is $result->plan->number_of_tests, 3, "Planned 3 tests";
my @tests = $result->tests;
is scalar @tests, 3, "Found 3 tests";

done_testing;
