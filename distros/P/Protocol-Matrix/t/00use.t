#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "Protocol::Matrix" );

use_ok( "Protocol::Matrix::HTTP::Federation" );

done_testing;
