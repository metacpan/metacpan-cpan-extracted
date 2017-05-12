use strict;
use Test::More tests => 108;
use Test::Requires qw( Number::Phone );

my %test_number = (
    '+810112345678'     => '+81 01 12345678',
    '+810912012345678'  => '+81 09120 12345678',
    '+816033001234'     => '+81 60 33001234',
    '+81120000123'      => '+81 120 000123',
    '+81112001234'      => '+81 11 2001234',
    '+815010001234'     => '+81 50 10001234',
    '+818010012345'     => '+81 80 10012345',
    '+812046012345'     => '+81 20 46012345',
    '+817050112345'     => '+81 70 50112345',
    '+81990504123'      => '+81 990 504123',
    '+81570000123'      => '+81 570 000123',
);

for my $number (keys %test_number) {
    my $phone = Number::Phone->new($number);
    ok($phone->is_valid, "$number is_valid");
    ok(defined $phone->is_mobile, "$number is_mobile");
    ok(defined $phone->is_pager, "$number is_pager");
    ok(defined $phone->is_ipphone, "$number is_ipphone");
    ok(defined $phone->is_tollfree, "$number is_tollfree");
    ok(defined $phone->is_specialrate, "$number is_specialrate");
    is($phone->country_code, 81, "$number country_code");
    is($phone->format, $test_number{$number}, "$number format")
}

my @unsupported_methods = qw(
    is_allocated
    is_in_use
    is_geographic
    is_fixed_line
    is_isdn
    is_adult
    is_personal
    is_corporate
    is_government
    is_international
    is_network_service
    regulator
    areacode
    areaname
    location
    subscriber
    operator
    type
    country
    translates_to
);

my $phone = Number::Phone->new('+810112345678');
for my $method (@unsupported_methods) {
    is($phone->$method(), undef, "$method is unsupported");
}
