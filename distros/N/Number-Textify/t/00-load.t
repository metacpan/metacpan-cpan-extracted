#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
  use_ok( 'Number::Textify' );
}

diag( "Testing Number::Textify $Number::Textify::VERSION, Perl $], $^X" );
