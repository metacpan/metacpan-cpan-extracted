#!perl

use Test2::V1 '-import';
plan(1);

use ok 'Monit::HTTP';

diag( "Testing Monit::HTTP $Monit::HTTP::VERSION, Perl $], $^X" );
