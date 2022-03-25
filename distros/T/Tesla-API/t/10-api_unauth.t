use warnings;
use strict;

use Tesla::API;
use Test::More;

my $tesla = Tesla::API->new(unauthenticated => 1);

my $no_endpoint_ok = eval {
    $tesla->api;
    1;
};

is $no_endpoint_ok, undef, "api() croaks if no endpoint sent in";
like $@, qr/requires an endpoint/, "...and error is sane";

my $no_id_ok = eval {
    $tesla->api(endpoint => 'VEHICLE_SUMMARY');
    1;
};

is $no_id_ok, undef, "if no \$id to api(), we croak on endpoints that require one";
like $@, qr/Endpoint VEHICLE_SUMMARY requires/, "...and error is sane";

done_testing();