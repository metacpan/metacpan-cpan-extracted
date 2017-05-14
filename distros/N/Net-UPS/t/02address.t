#!perl
use strict;
use Test::More;
use File::Spec;
use Net::UPS;

my $upsrc = File::Spec->catfile($ENV{HOME}, ".upsrc");
my $ups = undef;
unless (defined($ups = Net::UPS->new($upsrc)) ) {
    plan(skip_all=>Net::UPS->errstr);
    exit(0);
}

ok($ups);

use_ok("Net::UPS");
use_ok("Net::UPS::Address");

subtest 'signature' => sub {
    my $address = Net::UPS::Address->new();
    ok( $address->can("name")
        && $address->can("building_name")
        && $address->can("address")
        && $address->can("address2")
        && $address->can("address3")
        && $address->can("city")
        && $address->can("postal_code")
        && $address->can("postal_code_extended")
        && $address->can("state")
        && $address->can("country_code")
        && $address->can("is_residential")
        && $address->can("is_commercial")
        && $address->can("quality"),
    );
};

subtest 'simple validation' => sub {
    my $address = Net::UPS::Address->new();

    $address->city("East Lansing");
    $address->postal_code("48823");
    $address->state("MI");
    $address->country_code("US");
    $address->is_residential(1);

    ok($address->city           eq "East Lansing"   );
    ok($address->postal_code    eq "48823"          );
    ok($address->state          eq "MI"             );
    ok($address->country_code   eq "US"             );
    ok($address->is_residential eq "1"              );
    ok($address->quality        eq undef            );

    my $addresses = $address->validate();
    ok( $addresses && ref($addresses) && (ref $addresses eq "ARRAY"));
    ok( $addresses->[0]->quality == 1 );
    ok( $addresses->[0]->is_residential eq undef);
    ok( $addresses->[0]->is_exact_match     );
    ok(!$addresses->[0]->is_poor_match      );
    ok( $addresses->[0]->is_close_match     );
    ok( $addresses->[0]->is_very_close_match);
    ok( $addresses->[0]->is_match           );
};

subtest 'street-level validation' => sub {
    my $address = Net::UPS::Address->new();

    $address->name("John Doe");
    $address->building_name("Pearl Hotel");
    $address->address("233 W 49th St");
    $address->city("New York");
    $address->postal_code("10019");
    $address->postal_code_extended("");
    $address->state("NY");
    $address->country_code("US");

    ok($address->city eq "New York" );
    ok($address->postal_code eq "10019" );
    ok($address->state eq "NY" );
    ok($address->country_code eq "US" );

    my $response_address = $address->validate_street_level();
    ok( $response_address && ref($response_address) && (ref $response_address eq "Net::UPS::Address") );
    ok( $response_address->is_match );
};

done_testing;
