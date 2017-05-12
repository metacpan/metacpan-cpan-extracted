#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}) {
  plan(skip_all => 'AUTHOR_TESTING or RELEASE_TESTING is not set; skipping');
}

eval {
  require Test::Kwalitee;
  Test::Kwalitee->import();
};

plan(skip_all => 'Test::Kwalitee not installed; skipping') if $@;
