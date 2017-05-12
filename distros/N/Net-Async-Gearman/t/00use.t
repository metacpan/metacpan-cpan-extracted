#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "Net::Async::Gearman" );
use_ok( "Net::Async::Gearman::Client" );
use_ok( "Net::Async::Gearman::Worker" );

done_testing;
