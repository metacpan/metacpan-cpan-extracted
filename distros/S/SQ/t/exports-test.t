#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use SQ;

{
    # TEST
    is( $S, q#'#, "dollar-s contains a single quote." );
}

