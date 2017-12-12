use strict;
use warnings;
use Test::More;
use HTTP::Response;
use JSON;

my $api_user = '-- API USER --';
my $api_key = ' -- API KEY --';

if ($api_user =~ /-- API/ ) {
	plan skip_all => 'Add your own api user and key to run this test';
} else {
	plan tests => 21
};

use_ok( 'P5kkelabels' );

ok (my $lbl = P5kkelabels->new(user => $api_user, passwd => $api_key), "New P5kkelabel");

# Get methods
my @gethods = qw/
    products
    account_balance
    account_payment_requests
    return_portals
    shipments
    print_queue_entries
    imported_shipments
/;

for my $method (@gethods) {
    ok(my $result = $lbl->$method, "$method");
    is($result->code, 200, "$method call ok");
}

# Get methods w/ parameters
my %p1ethods = (
    products => {
        country_code => 'DK',
        carrier_code => 'dao',
    },
    pickup_points => {
        country_code => 'DK',
        carrier_code => 'dao',
        zipcode => 2000,
    }
);
my %cache;
for my $method (keys %p1ethods) {
    ok(my $result = $lbl->$method($p1ethods{$method}), "$method");
    is($result->code, 200, "$method call ok");
    $cache{$method} = $result->data;
}

# Create shipment
my $ship_data = {
    test_mode => JSON::true,
    order_id => 123456,
    own_agreement => JSON::false,
    product_code => 'DAO_P',
    service_codes => 'EMAIL_NT',
    parcels => [
        { weight => 1000 },
    ],
    receiver => {
        name  => 'Receiver',
        attention  => '',
        address1 => 'Testvej 36B 1 th',
        zipcode => '2000',
        city => 'Frederiksberg',
        email => 'kaare@jasonic.dk',
        country_code => 'DK',
      },
    sender => {
       name => 'Sender ApS',
       email => 'info@example.com',
       city => 'Frederiksberg',
       address1 => 'Testvej 12',
       zipcode => '2000',
       country_code => 'DK'
     },
    service_point => $cache{pickup_points}[0],
};

ok(my $shipment = $lbl->create_shipment($ship_data), 'Create shipment');

exit;

# Get methods w/ parameters - needs shipment
my %p2ethods = (
    shipment_monitor => {
        ids => $shipment->data->{id},
    },
    return_portals => {
        id => $shipment->data->{id},
    },
    return_portal_shipments => {
        id => $shipment->data->{id},
    },
    shipments => {
        id => $shipment->data->{id},
    },
    shipment_labels => {
        id => $shipment->data->{id},
    },
    labels => {
        ids => [ $shipment->data->{id} ],
    },
);

for my $method (keys %p2ethods) {
    ok(my $result = $lbl->$method($p2ethods{$method}), "$method");
    is($result->code, 200, "$method call ok");
    $cache{$method} = $result->data;
}
