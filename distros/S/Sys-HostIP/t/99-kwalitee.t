#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => 'these tests are for release candidate testing'
      unless $ENV{RELEASE_TESTING};
}

use Test::Kwalitee::Extra qw(:experimental);

done_testing;
