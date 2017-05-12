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

my $preauthorization_api = Paymill::REST::Preauthorizations->new(%base_args);
my $created_transaction  = $preauthorization_api->create(
    {
        token    => '098f6bcd4621d373cade4e832627b4f6',
        amount   => 4200,
        currency => 'EUR',
    }
);
my $created_preauthorization = $created_transaction->preauthorization;

my $found_preauthorization = $preauthorization_api->find($created_preauthorization->id);

is(
    $found_preauthorization->id,
    $created_preauthorization->id,
    "Found preauthorization via find(), IDs match"
);
is(
    $found_preauthorization->amount,
    $created_preauthorization->amount,
    "Found preauthorization via find(), amount matches"
);
is(
    $found_preauthorization->currency,
    $created_preauthorization->currency,
    "Found preauthorization via find(), currency matches"
);

my @all_preauthorizations = $preauthorization_api->list({ order => 'created_at_desc' });
cmp_ok(scalar @all_preauthorizations, ">=", 1, "Found at least 1 preauthorization via list()");

my $found_previous_preauthorization = 0;
foreach my $preauthorization (@all_preauthorizations) {
    $found_previous_preauthorization++ if $preauthorization->id eq $found_preauthorization->id;
}
is($found_previous_preauthorization, 1, "Previous created preauthorization found via list()");

$created_preauthorization->delete;
eval { $preauthorization_api->find($created_preauthorization->id) };
ok($@ =~ /^Request error: 404/, "Previous created preauthorization successfully deleted");

done_testing;
