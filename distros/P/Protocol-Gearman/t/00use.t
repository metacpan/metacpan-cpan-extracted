#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use_ok( "Protocol::Gearman" );
use_ok( "Protocol::Gearman::Client" );
use_ok( "Protocol::Gearman::Worker" );
use_ok( "Net::Gearman" );
use_ok( "Net::Gearman::Client" );
use_ok( "Net::Gearman::Worker" );

done_testing;
