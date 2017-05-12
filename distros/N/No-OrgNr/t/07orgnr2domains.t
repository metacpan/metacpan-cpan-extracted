#!/usr/bin/env perl

use utf8;
use 5.014;
use warnings;
use open qw/:encoding(UTF-8) :std/;

use Test::More;

BEGIN {
    use_ok( 'No::OrgNr', qw/orgnr2domains/ );
}

my @empty;
is( orgnr2domains('abc'), @empty, 'Testing invalid organization number' );
is( orgnr2domains(undef), @empty, 'Testing undefined organization number' );
is( orgnr2domains(''),    @empty, 'Testing empty organization number' );
is( orgnr2domains(' '),   @empty, 'Testing organization number equal to a space' );

done_testing;
