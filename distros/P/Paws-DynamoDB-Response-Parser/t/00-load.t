#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    use_ok('Paws::DynamoDB::Response::Parser') || print "Bail out!\n";
}

diag( "Testing Paws::DynamoDB::Response::Parser $Paws::DynamoDB::Response::Parser::VERSION, Perl $], $^X" );;
