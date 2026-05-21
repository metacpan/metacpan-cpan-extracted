#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Test::More tests => 1;

use Alpha;
use Beta;

ok( Alpha::Member->can( 'friends' ), 'Alpha::Member has friends method' );

