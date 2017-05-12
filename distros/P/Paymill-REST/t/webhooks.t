use strict;
use Test::More;

use Data::Compare;
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

my $webhook_api     = Paymill::REST::Webhooks->new(%base_args);
my $created_webhook = $webhook_api->create(
    {
        url             => 'https://example.net/hook',
        'event_types[]' => ['transaction.succeeded', 'transaction.failed'],
    }
);

my $found_webhook = $webhook_api->find($created_webhook->id);

is(
    $found_webhook->id,
    $created_webhook->id,
    "Found webhook via find(), IDs match"
);
is(
    $found_webhook->url,
    $created_webhook->url,
    "Found webhook via find(), url matches"
);
ok(
    Compare($created_webhook->event_types, $found_webhook->event_types),
    "Found webhook via find(), event_types matches"
);

my @all_webhooks = $webhook_api->list({ order => 'created_at_desc' });
cmp_ok(scalar @all_webhooks, ">=", 1, "Found at least 1 webhook via list()");

my $found_previous_webhook = 0;
foreach my $webhook (@all_webhooks) {
    $found_previous_webhook++ if $webhook->id eq $found_webhook->id;
}
is($found_previous_webhook, 1, "Previous created webhook found via list()");

$created_webhook->delete;
eval { $webhook_api->find($created_webhook->id) };
ok($@ =~ /^Request error: 404/, "Previous created webhook successfully deleted");

done_testing;
