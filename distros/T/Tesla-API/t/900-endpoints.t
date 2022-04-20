use warnings;
use strict;

use JSON;
use Tesla::API;
use Test::More;

my $tesla = Tesla::API->new(unauthenticated => 1);

my $known_endpoints;
{
    local $/;
    open my $fh, '<', 't/test_data/endpoints.json' or die $!;
    my $json = <$fh>;
    $known_endpoints = decode_json($json);
}

my $api_endpoints = $tesla->endpoints;

is
    keys %$api_endpoints,
    keys %$known_endpoints,
    "endpoints() returns the proper number of endpoints ok";

for my $endpoint (keys %$known_endpoints) {
    for (keys %{ $known_endpoints->{$endpoint} }) {
        is
            $api_endpoints->{$endpoint}{$_},
            $known_endpoints->{$endpoint}{$_},
            "Attribute $_ for endpoint $endpoint is $known_endpoints->{$endpoint}{$_} ok";
    }
}

my $missing_ok = eval { $tesla->endpoint('NON_EXIST'); 1; };
is $missing_ok, undef, "If an endpoint doesn't exist, we croak";

done_testing();