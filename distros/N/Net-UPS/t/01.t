
# $Id: 01.t,v 1.1 2005/11/11 00:04:17 sherzodr Exp $

use strict;
use diagnostics;
use Test::More;
use File::Spec;
use Net::UPS;

my $upsrc = File::Spec->catfile($ENV{HOME}, '.upsrc');
my $ups = undef;
unless ( defined($ups   = Net::UPS->new($upsrc)) ) {
    plan(skip_all=>Net::UPS->errstr);
    exit(0);
}
plan(tests=>29);

use_ok("Net::UPS::Rate");
use_ok("Net::UPS::Package");
use_ok("Net::UPS::Address");
use_ok("Net::UPS::Service");

ok($ups, "Net::UPS instance created");
can_ok($ups,    "live",         "instance",         "userid", 
                "password",     "access_key",       "rate", 
                "service",      "shop_for_rates",   "validate_address",
                "init",         "cache_life",       "cache_root");

ok($Net::UPS::LIVE == 0);
$ups->live(1);
ok($Net::UPS::LIVE == 1);
$ups->live(0);
ok($Net::UPS::LIVE == 0);

# Creating a package to be rated
my $package = Net::UPS::Package->new(length=>34, width=>24, height=>1.5, weight=>1);
ok($package);

my $rate = $ups->rate(15241, 48823, $package);
ok($rate && ref($rate) && $rate->isa("Net::UPS::Rate"));

# check if we get the same result if we replaced zip codes with Net::UPS::Address:
my $address_from = Net::UPS::Address->new(postal_code=>15241);
my $address_to   = Net::UPS::Address->new(postal_code=>48823);
my $rate1 = $ups->rate($address_from, $address_to, $package);

ok($rate->total_charges == $rate1->total_charges);
ok($rate->total_charges == $rate->service->total_charges);

my @packages = ($package);
push @packages, Net::UPS::Package->new(length=>34, width=>24, height=>1.5, weight=>1);

$rate = $ups->rate($address_from, $address_to, \@packages);
ok($rate && ref($rate) && (ref $rate eq 'ARRAY') && ($rate->[0]->isa("Net::UPS::Rate")) && ($rate->[1]->isa("Net::UPS::Rate")) );

can_ok($rate->[0], "total_charges", "billing_weight", "rated_package", "service", "from", "to");
ok(     ($rate->[0]->rated_package->length == 34) 
    &&  ($rate->[0]->rated_package->width  == 24)
    &&  ($rate->[0]->rated_package->height == 1.5)
    &&  ($rate->[0]->rated_package->weight == 1)
);

ok(     ($rate->[1]->service->label eq "GROUND")
    &&  ($rate->[1]->service->code  == 03 )
    &&  ($rate->[1]->service->total_charges == $rate->[1]->total_charges+$rate->[0]->total_charges)
    &&  ($rate->[1]->service->rated_packages->[0]->length == 34)
    &&  ($rate->[1]->service->rated_packages->[0]->width  == 24)
    &&  ($rate->[1]->service->rated_packages->[0]->height == 1.5)
    &&  ($rate->[1]->service->rated_packages->[0]->weight == 1)
);

ok(     ($rate->[0]->from->postal_code  ==  15241)
    &&  ($rate->[0]->to->postal_code    ==  48823)
);


my $services = $ups->shop_for_rates($address_from, $address_to, $package);
ok(     $services 
    &&  ref($services)
    &&  (ref$services eq 'ARRAY')
    &&  $services->[0]->isa("Net::UPS::Service")
);

for my $service ( @$services ) {
    printf("#%s [%02d]=> \$%.2f\n", $service->label, $service->code, $service->total_charges);
}

ok(     ($services->[0]->label  eq 'GROUND')
    &&  ($services->[0]->code   ==  03 )
);

ok(     ($services->[0]->total_charges < $services->[1]->total_charges)
    &&  ($services->[1]->total_charges < $services->[2]->total_charges)
);


# what happens if we rate multiple packages?
$services = $ups->shop_for_rates($address_from, $address_to, \@packages);
ok(     $services 
    &&  ref($services)
    &&  (ref$services eq 'ARRAY')
    &&  $services->[0]->isa("Net::UPS::Service")
);

for my $service ( @$services ) {
    printf("#%s [%02d]=> \$%.2f\n", $service->label, $service->code, $service->total_charges);
}

ok(     ($services->[0]->label  eq 'GROUND')
    &&  ($services->[0]->code   ==  03 )
);

ok(     ($services->[0]->total_charges < $services->[1]->total_charges)
    &&  ($services->[1]->total_charges < $services->[2]->total_charges)
);

# since we had two packages, we should have two seperate rates associated with the service rate
my $rates = $services->[0]->rates();
ok(     $rates
    &&  ref($rates)
    &&  (ref $rates eq 'ARRAY')
    &&  (@$rates == 2)
);

# if we add the two rates for the first service, we should get the total
# charges amount for the first service
ok( $services->[0]->total_charges == ($rates->[0]->total_charges + $rates->[1]->total_charges));


# testing address verification service
my $address = Net::UPS::Address->new(
        city        => "East Lansing",
        state       => "MI",
        postal_code => "48823",
        country_code=> "US",
        is_residential=>1
);

ok($address);

my $addresses = $ups->validate_address($address, {tolerance=>0});
ok(     $addresses
    &&  ref($addresses)
    &&  (ref $addresses eq 'ARRAY')
);

ok(     ($addresses->[0]->quality == 1)
    &&  (lc($addresses->[0]->city)  eq "east lansing")
    &&  ($addresses->[0]->state eq "MI")
    &&  ($addresses->[0]->postal_code eq "48823")
    &&  ($addresses->[0]->country_code eq "US")
);


