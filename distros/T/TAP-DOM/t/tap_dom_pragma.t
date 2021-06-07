#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
  local $/;
  open (TAP, "< t/some_tap8_pragma.txt") or die "Cannot read t/some_tap8_pragma.txt";
  $tap = <TAP>;
  close TAP;
}

diag "\n=== complete TAP-DOM:";
my $tapdata = TAP::DOM->new( tap => $tap); # needs Test::Harness 3.22: , version => 13 );

my $l = 5;

#diag Dumper($tapdata);
is($tapdata->{version},             13,      "version");
is($tapdata->{tests_planned},        3,      "tests_planned");
is($tapdata->{plan},             '1..3',     "missing plan");
is($tapdata->{tests_run},            3,      "tests_run");
is($tapdata->{lines}[$l]{is_pragma}, 1,      "[$l] is_test");
is($tapdata->{lines}[$l]{kv_data}{'tapdom-error-type'}, "unittest", "[$l] kv_data.tapdom-error-type");
is($tapdata->{lines}[$l]{kv_data}{'tapdom-unittest-code'}, 42,      "[$l] kv_data.tapdom-unittest-code");

is($tapdata->{lines}[0]{severity}, 0,      "severity::version");
is($tapdata->{lines}[1]{severity}, 0,      "severity::plan");
is($tapdata->{lines}[2]{severity}, 1,      "severity::test 1");
is($tapdata->{lines}[3]{severity}, 4,      "severity::test 2");
is($tapdata->{lines}[4]{severity}, 1,      "severity::test 3");
is($tapdata->{lines}[5]{severity}, 5,      "severity::pragma +tapdom_error");

done_testing();
