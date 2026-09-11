#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::OpenStack::MetaAPI qw{:all};
use Test::OpenStack::MetaAPI::Auth qw{:all};

use OpenStack::MetaAPI ();
use OpenStack::MetaAPI::API;

# --- Missing name ---
like(
    dies { OpenStack::MetaAPI::API::get_service(auth => bless({}, 'Fake::Auth')) },
    qr/name required/,
    "get_service dies without name"
);

# --- Missing auth ---
like(
    dies { OpenStack::MetaAPI::API::get_service(name => 'compute') },
    qr/auth required/,
    "get_service dies without auth"
);

# --- Auth must be a reference ---
like(
    dies { OpenStack::MetaAPI::API::get_service(name => 'compute', auth => 'not_a_ref') },
    qr/auth required/,
    "get_service dies when auth is not a reference"
);

# --- Invalid service name ---
like(
    dies {
        OpenStack::MetaAPI::API::get_service(
            name => 'nonexistent_service_xyz',
            auth => bless({}, 'Fake::Auth'),
        )
    },
    qr/Failed to load/,
    "get_service dies for unknown service module"
);

# --- Successful service loading ---
{
    mock_lwp_useragent();

    my $api = get_api_object(use_env => 0);
    ok $api, "got api object for factory test" or die;

    # The service() method on Routes calls API::get_service internally
    my $routes = $api->route;
    my $compute_service = $routes->service('compute');

    ok ref $compute_service, "get_service returns a service object for compute";
    like ref($compute_service), qr/Compute/, "compute service has correct class";
}

done_testing;
