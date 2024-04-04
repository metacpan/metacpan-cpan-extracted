package Stancer::Role::Country::Test;

use 5.020;
use strict;
use warnings;
use base qw(Test::Class);

use Stancer::Role::Country::Stub;
use TestCase;

## no critic (RequireExtendedFormatting, RequireFinalReturn)

sub city : Tests(3) {
    my $object = Stancer::Role::Country::Stub->new();
    my $city = random_string(10);

    is($object->city, undef, 'Undefined by default');

    $object->hydrate(city => $city);

    is($object->city, $city, 'Should have a value');

    throws_ok { $object->city($city) } qr/city is a read-only accessor/sm, 'Not writable';
}

sub country : Tests(3) {
    my $object = Stancer::Role::Country::Stub->new();
    my $country = random_string(2);

    is($object->country, undef, 'Undefined by default');

    $object->hydrate(country => $country);

    is($object->country, $country, 'Should have a value');

    throws_ok { $object->country($country) } qr/country is a read-only accessor/sm, 'Not writable';
}

sub zip_code : Tests(3) {
    my $object = Stancer::Role::Country::Stub->new();
    my $zip_code = random_string(8);

    is($object->zip_code, undef, 'Undefined by default');

    $object->zip_code($zip_code);

    is($object->zip_code, $zip_code, 'Should be updated');
    cmp_deeply_json($object, { zip_code => $zip_code }, 'Should be exported');
}

1;
