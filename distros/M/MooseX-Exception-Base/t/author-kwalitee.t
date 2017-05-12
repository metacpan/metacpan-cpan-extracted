#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}


use strict;
use warnings;

eval { require Test::Kwalitee; Test::Kwalitee->import() };

if ($@) {
    require Test::More;
    Test::More->import;
    plan( skip_all => 'Test::Kwalitee not installed; skipping' );
}
