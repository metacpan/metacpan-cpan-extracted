#!/usr/bin/env perl -w
use strict;

package Foo;
use Test::Cukes;

Given qr/^the pre-conditions is there$/, sub {
    assert 1;
};

When qr/^it branches into the second level$/, sub {
    assert 1;
};

Then qr/^the final shall be reached$/, sub {
    assert 1;
};

package main;

use Test::Cukes;

feature(q{
Feature: Hendrerit iriure et dolore autem tincidunt enim autem
  In order to Quis facilisis facilisis minim esse
  As a dolor te duis.
  I want to vel feugait vulputate molestie.

  Scenario: Some random scenario text
    Given the pre-conditions is there
    When it branches into the second level
    Then the final shall be reached
});

runtests;
