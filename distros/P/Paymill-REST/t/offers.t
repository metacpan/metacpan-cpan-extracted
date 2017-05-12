use strict;
use Test::More;

use Paymill::REST;

unless ($ENV{PAYMILL_PRIVATE_KEY}) {
    plan skip_all => 'PAYMILL_PRIVATE_KEY not set';
    done_testing;
    exit;
}

$Paymill::REST::PRIVATE_KEY = $ENV{PAYMILL_PRIVATE_KEY};

my %base_args;

if ($ENV{TEST_LOCAL}) {
    %base_args = (
        base_url        => 'https://api.chipmunk.dev/v2/',
        auth_netloc     => 'api.chipmunk.dev:443',
        verify_hostname => 0,
    );

    if ($ENV{DEBUG}) {
        $base_args{debug} = 1;
    }
}

my $offer_api     = Paymill::REST::Offers->new(%base_args);
my $created_offer = $offer_api->create(
    {
        name     => 'Test offer through Paymill::REST: ' . time,
        amount   => 2300,
        interval => '1 MONTH',
        currency => 'EUR',
    }
);

my $found_offer = $offer_api->find($created_offer->id);

is(
    $found_offer->id,
    $created_offer->id,
    "Found offer via find(), IDs match"
);
is(
    $found_offer->name,
    $created_offer->name,
    "Found offer via find(), name matches"
);
is(
    $found_offer->interval,
    $created_offer->interval,
    "Found offer via find(), interval matches"
);

my @all_offers = $offer_api->list({ order => 'created_at_desc' });
cmp_ok(scalar @all_offers, ">=", 1, "Found at least 1 offer via list()");

my $found_previous_offer = 0;
foreach my $offer (@all_offers) {
    $found_previous_offer++ if $offer->id eq $found_offer->id;
}
is($found_previous_offer, 1, "Previous created offer found via list()");

$created_offer->delete;
eval { $offer_api->find($created_offer->id) };
ok($@ =~ /^Request error: 404/, "Previous created offer successfully deleted");

done_testing;
