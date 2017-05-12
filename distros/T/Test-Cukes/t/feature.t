#!/usr/bin/env perl -w
use strict;
use Test::More qw(no_plan);

use Test::Cukes::Feature;

my $feature = Test::Cukes::Feature->new(<<TEXT);
Feature: Hendrerit iriure et dolore autem tincidunt enim autem
  In order to Quis facilisis facilisis minim esse
  As a dolor te duis.
  I want to vel feugait vulputate molestie.

  Scenario: Some random scenario text
    Given the pre-conditions is there
    When it branches into the second level
    Then the final shall be reached
TEXT

is($feature->name, "Hendrerit iriure et dolore autem tincidunt enim autem");
like($feature->body, qr/In order to.+As.+I want/s);
is(scalar @{ $feature->scenarios }, 1);

my $scenario = $feature->scenarios->[0];
is($scenario->name, "Some random scenario text");
is_deeply($scenario->steps, ["Given the pre-conditions is there",
                             "When it branches into the second level",
                             "Then the final shall be reached"]);
