package Stancer::Core::Types::ApiKeys::Stub;

use 5.020;
use strict;
use warnings;

use Moo;
use namespace::clean;

use Stancer::Core::Types::ApiKeys qw(:all);

has an_api_key => (
    is => 'ro',
    isa => ApiKey,
);

has a_public_live_api_key => (
    is => 'ro',
    isa => PublicLiveApiKey,
);

has a_public_test_api_key => (
    is => 'ro',
    isa => PublicTestApiKey,
);

has a_secret_live_api_key => (
    is => 'ro',
    isa => SecretLiveApiKey,
);

has a_secret_test_api_key => (
    is => 'ro',
    isa => SecretTestApiKey,
);

1;
