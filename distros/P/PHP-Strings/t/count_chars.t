#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More tests => 12;
BEGIN { use_ok 'PHP::Strings', ':count_chars' };

# Good inputs
{
    my %have_expected = qw( 97 1 98 2 99 3 );
    my %freq = count_chars( "abcbcc", 1 );
    ok( eq_hash( \%freq, \%have_expected ), "Mode 1" );

    my %dont_expected = map { ($_,0) } (0..96, 100..255);
    %freq = count_chars( "abcbcc", 2 );
    ok( eq_hash( \%freq, \%dont_expected ), "Mode 2" );

    my %expected = ( %have_expected, %dont_expected );
    %freq = count_chars( "abcbcc", 0 );
    ok( eq_hash( \%freq, \%expected ), "Mode 0" );

    my $freq = count_chars( "abcbcc", 3 );
    is( $freq => 'abc' => 'Mode 3' );

    my $dont = join '', map chr, sort keys %dont_expected;
    $freq = count_chars( "abcbcc", 4 );
    is( $freq => $dont => 'Mode 4' );
}

# Bad inputs
{
    eval { count_chars( ) };
    like( $@, qr/^0 param/, "No arguments" );
    eval { count_chars( undef ) };
    like( $@, qr/^Parameter #1.*undef.*scalar/, "Bad type for string" );
    eval { count_chars( "Foo", undef ) };
    like( $@, qr/^Parameter #2.*undef.*scalar/, "Bad type for mode" );
    eval { count_chars( "Foo", "Not a number" ) };
    like( $@, qr/^Parameter #2.*Number between.*callback/, "Mode not a number" );
    eval { count_chars( "Foo", 5 ) };
    like( $@, qr/^Parameter #2.*Number between.*callback/, "Mode too high" );
    eval { count_chars( "Foo", 3, 6 ) };
    like( $@, qr/^3 parameters were passed.*but .* were expected/, "Too many arguments" );
}
