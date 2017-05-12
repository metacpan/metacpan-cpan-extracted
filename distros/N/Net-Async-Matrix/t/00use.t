#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( 'Net::Async::Matrix' );
use_ok( 'Net::Async::Matrix::Room' );
use_ok( 'Net::Async::Matrix::Room::State' );

done_testing;
