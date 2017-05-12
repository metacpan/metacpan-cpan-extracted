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

my $client_api     = Paymill::REST::Clients->new(%base_args);
my $created_client = $client_api->create(
    {
        email       => 'foo@example.com',
        description => 'Test client through Paymill::REST on ' . time,
    }
);

my $payment_api     = Paymill::REST::Payments->new(%base_args);
my $created_payment = $payment_api->create(
    {
        token  => '098f6bcd4621d373cade4e832627b4f6',
        client => $created_client->id,
    }
);

my $offer_api     = Paymill::REST::Offers->new(%base_args);
my $created_offer = $offer_api->create(
    {
        name     => 'Test offer through Paymill::REST on ' . time,
        amount   => 2300,
        interval => '1 MONTH',
        currency => 'EUR',
    }
);

my $subscription_api     = Paymill::REST::Subscriptions->new(%base_args);
my $created_subscription = $subscription_api->create(
    {
        client  => $created_client->id,
        offer   => $created_offer->id,
        payment => $created_payment->id,
    }
);

my $found_subscription = $subscription_api->find($created_subscription->id);

is(
    $found_subscription->id,
    $created_subscription->id,
    "Found subscription via find(), IDs match"
);
is(
    $found_subscription->client->id,
    $created_subscription->client->id,
    "Found subscription via find(), client->id matches"
);
is(
    $found_subscription->payment->id,
    $created_subscription->payment->id,
    "Found subscription via find(), payment->id matches"
);
# API value of next_capture_at upon creation is wrong!
# is(
#     $found_subscription->next_capture_at->epoch,
#     $created_subscription->next_capture_at->epoch,
#     "Found subscription via find(), next_capture_at matches"
# );
is(
    $found_subscription->created_at->epoch,
    $created_subscription->created_at->epoch,
    "Found subscription via find(), created_at matches"
);

my @all_subscriptions = $subscription_api->list({ order => 'created_at_desc' });
cmp_ok(scalar @all_subscriptions, ">=", 1, "Found at least 1 subscription via list()");

my $found_previous_subscription = 0;
foreach my $subscription (@all_subscriptions) {
    $found_previous_subscription++ if $subscription->id eq $found_subscription->id;
}
is($found_previous_subscription, 1, "Previous created subscription found via list()");

$created_subscription->delete;
my $deleted_subscription = $subscription_api->find($created_subscription->id);
ok($deleted_subscription->canceled_at->epoch <= time, "Previous created subscription successfully deleted");

$created_offer->delete;
$created_payment->delete;
$created_client->delete;

done_testing;
