#!/usr/bin/env perl

use utf8;
use 5.014;
use warnings;
use open qw/:encoding(UTF-8) :std/;

use Test::More;

BEGIN {
    use_ok( 'No::OrgNr', qw/num_domains/ );
}

is( num_domains('abc'), 0, 'Testing invalid organization number' );
is( num_domains(undef), 0, 'Testing undefined organization number' );
is( num_domains(''),    0, 'Testing empty organization number' );
is( num_domains(' '),   0, 'Testing organization number equal to a space' );

done_testing;
