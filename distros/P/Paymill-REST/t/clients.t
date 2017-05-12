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

my $found_client = $client_api->find($created_client->id);

is(
    $found_client->id,
    $created_client->id,
    "Found client via find(), IDs match"
);
is(
    $found_client->email,
    $created_client->email,
    "Found client via find(), email matches"
);
is(
    $found_client->description,
    $created_client->description,
    "Found client via find(), description matches"
);

my @all_clients = $client_api->list({ order => 'created_at_desc' });
cmp_ok(scalar @all_clients, ">=", 1, "Found at least 1 client via list()");

my $found_previous_client = 0;
foreach my $client (@all_clients) {
    $found_previous_client++ if $client->id eq $found_client->id;
}
is($found_previous_client, 1, "Previous created client found via list()");

$created_client->delete;
eval { $client_api->find($created_client->id) };
ok($@ =~ /^Request error: 404/, "Previous created client successfully deleted");

done_testing;
