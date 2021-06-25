#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use_ok( "Protocol::IRC" );
use_ok( "Protocol::IRC::Client" );
use_ok( "Protocol::IRC::Message" );

done_testing;
