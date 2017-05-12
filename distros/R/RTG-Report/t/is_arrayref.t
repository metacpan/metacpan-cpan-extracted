#!/usr/bin/perl
use strict;
use warnings;

use lib ".";
use lib "lib";

use Test::More 'no_plan';

BEGIN { use_ok('RTG::Report'); };
require_ok('RTG::Report');

my $reporter = RTG::Report->new();

ok( $reporter->is_arrayref( [ 'the', 'fat', 'cat' ] ), 'is_arrayref');

ok( ! $reporter->is_arrayref( 'the', 'fat', 'cat' ), 'is_arrayref');

