#!/usr/bin/env perl -w
use strict;
use Test::More tests => 2;
use Test::Cukes::Scenario;

my $scenario = Test::Cukes::Scenario->new(<<SCENARIO_TEXT);
Scenario: Some random scenario text
  Given the pre-conditions is there
  When it branches into the second level
  Then the final shall be reached
SCENARIO_TEXT

is($scenario->name, "Some random scenario text");
is_deeply($scenario->steps, ["Given the pre-conditions is there",
                             "When it branches into the second level",
                             "Then the final shall be reached"]);
