#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use Test::Fatal;
use Number::Phone::BR;

my $class = 'Number::Phone::BR';

for my $number (
    '+55 11 2345-6789', '+55 (011) 2345-6789', '+55 011 2345-6789',
        '11 2345-6789',     '(011) 2345-6789',     '011 2345-6789',
          '1123456789',         '01123456789'
) {
    subtest "Testing valid number $number" => sub {
        ok(my $obj = $class->new($number), 'valid number builds ok');

        is($obj->is_valid, 1, q{it's valid});
        is($obj->is_fixed_line, 1, q{it's a fixed line});
        is($obj->is_mobile, 0, q{it's not a mobile phone});
        is($obj->country_code, 55, q{country_code is 55});
        is($obj->country, 'BR', q{country is BR});
        is($obj->areacode, '11', q{areacode is 11});
        is($obj->areaname, 'SP - Região Metropolitana de São Paulo', q{areaname is São Paulo});
        is($obj->subscriber, '23456789', 'subscriber is ok');
    };
}

like(exception { $class->new('+1 (714) 781-3463') }, qr/Not a valid/, 'valid US phone number is not valid BR phone number');
like(exception { $class->new('(112) 345-6789')    }, qr/Not a valid/, 'valid phone number with misplaced () is not valid');
like(exception { $class->new('0xx11 2345-6789')   }, qr/Not a valid/, 'letters are not valid');

done_testing;
