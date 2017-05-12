#!perl

use strict;
use Test::More;

BEGIN {
    plan skip_all => 'these tests are for release candidate testing'
      unless $ENV{RELEASE_TESTING};
}

use Test::Kwalitee::Extra;
done_testing;

