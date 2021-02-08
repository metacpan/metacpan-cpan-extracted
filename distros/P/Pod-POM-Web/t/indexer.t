#!perl

use strict;
use warnings;

use Test::More tests => 1;


SKIP: {
  eval {require Search::Indexer};
  skip "Search::Indexer does not seem to be installed", 1
    if $@;
  use_ok( 'Pod::POM::Web::Indexer' );
}


# TODO ... more than just a compile test
