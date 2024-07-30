#!/usr/bin/perl

use v5.14;
use warnings;

use lib 't/lib';

use Test2::V0;

use TestFCGI;

is( fcgi_trans( type => 1, id => 1, data => "ABCDEFGH" ),
    "\1\1\0\1\0\x08\0\0ABCDEFGH",
    'Testing fcgi_trans() internal function' );

done_testing;
