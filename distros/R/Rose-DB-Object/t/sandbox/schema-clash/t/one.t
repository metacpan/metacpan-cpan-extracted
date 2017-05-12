#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;

use Alpha;
use Beta;

ok( Alpha::Member->can( 'friends' ), 'Alpha::Member has friends method' );

