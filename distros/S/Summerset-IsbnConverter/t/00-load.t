#!/usr/bin/env perl
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 15;


BEGIN {
    use_ok( 'Summerset::IsbnConverter' ) || print "Bail out!\n";
}

diag( "Testing Summerset::IsbnConverter $Summerset::IsbnConverter::VERSION, Perl $], $^X" );

# validate our _stripNonDigit chars method works
is(Summerset::IsbnConverter::_replaceNonDigitCharacters(undef), '');
cmp_ok(Summerset::IsbnConverter::_replaceNonDigitCharacters( '1 2 3 4 --- 5 6 -7 8xx 9 0'), 'eq', '1234567890');
cmp_ok(Summerset::IsbnConverter::_replaceNonDigitCharacters( '1 2 3 4 --- 5 6 -7 8xx 9 0X'), 'eq', '1234567890X');


# validateIsbn10
cmp_ok(validateIsbn10('0-395-04089-2'), '==', 1); 
cmp_ok(validateIsbn10('0-937383-18-X'), '==', 1); 
cmp_ok(validateIsbn10('0-937383-18-0'), '==', 0); # invalid isbn
cmp_ok(validateIsbn10(undef), '==', 0);

# validateIsbn13
cmp_ok(validateIsbn13('978-0-937383-18-6'), '==', 1);
cmp_ok(validateIsbn13('978-0-937383-18-7'), '==', 0); # invalid isbn
cmp_ok(validateIsbn13(undef), '==', 0);

# convertToIsbn10
cmp_ok(convertToIsbn10('9780395040898'), 'eq', '0395040892');
is(convertToIsbn10('234234'), undef); # invalid length

# convertToIsbn13
cmp_ok(convertToIsbn13('0395040892'), 'eq', '9780395040898');
is(convertToIsbn13('234234'), undef); # invalid length
