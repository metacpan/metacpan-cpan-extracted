#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings qw(all);

use Test::More;
use Test::Mojibake;

all_files_encoding_ok();
