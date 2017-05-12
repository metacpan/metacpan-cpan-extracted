#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;

use SWISH::3;
my $swish3 = SWISH::3->new();
ok( !$swish3->parse('no/such/file.xml'),
    "failed to parse non-existent file" );
is( $swish3->error, 'No such file or directory', "got correct error" );
ok( $swish3->parse('t/test.html'), "parse t/test.html" );
is( $swish3->error, undef, "error() returns undef no error" );
