#!/usr/bin/env perl -w
use strict;
use Test::Cukes;
my @passed;

Given qr/blah1/ => sub {
    push @passed, 1;

    assert @passed == 1;
};

When qr/blah2/ => sub {
    push @passed, 2;
    assert @passed == 2;
};

Then qr/blah3/ => sub {
    push @passed, 3;
    assert @passed == 3;

    # We can't use is_deeply because Test::More doesn't play nice with
    # Cukes's plan.
    assert 1 == $passed[0];
    assert 2 == $passed[1];
    assert 3 == $passed[2];
};

runtests(<<FEATURE_TEXT);
Feature: foo
  In order to bleh
  I want to bleh

  Scenario: blehbleh
    Given blah1
    When blah2
    Then blah3
FEATURE_TEXT
