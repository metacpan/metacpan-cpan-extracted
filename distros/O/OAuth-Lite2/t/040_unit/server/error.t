use strict;
use warnings;

use Test::More;
use OAuth::Lite2::Server::Error;

sub assert_server_error {
    my $params = shift;
    my $CLASS_NAME = "OAuth::Lite2::Server::Error::$params->{name}";
    my $error = $CLASS_NAME->new;
    ok($error);
    is($error->code, $params->{code}, "code for $CLASS_NAME");
};

my @defined_errors = (
    {
        q{name} => q{InvalidRequest},
        q{code} => 400,
        q{type} => q{invalid_request},
    },
    {
        q{name} => q{InvalidClient},
        q{code} => 401,
        q{type} => q{invalid_client},
    },
    {
        q{name} => q{UnauthorizedClient},
        q{code} => 401,
        q{type} => q{unauthorized_client},
    },
    {
        q{name} => q{RedirectURIMismatch},
        q{code} => 401,
        q{type} => q{redirect_uri_mismatch},
    },
    {
        q{name} => q{AccessDenied},
        q{code} => 401,
        q{type} => q{access_denied},
    },
    {
        q{name} => q{UnsupportedResponseType},
        q{code} => 400,
        q{type} => q{unsupported_response_type},
    },
    {
        q{name} => q{UnsupportedResourceType},
        q{code} => 400,
        q{type} => q{unsupported_resource_type},
    },
    {
        q{name} => q{InvalidGrant},
        q{code} => 401,
        q{type} => q{invalid_grant},
    },
    {
        q{name} => q{UnsupportedGrantType},
        q{code} => 400,
        q{type} => q{unsupported_grant_type},
    },
    {
        q{name} => q{InvalidScope},
        q{code} => 401,
        q{type} => q{invalid_scope},
    },
    {
        q{name} => q{InvalidToken},
        q{code} => 401,
        q{type} => q{invalid_token},
    },
    {
        q{name} => q{ExpiredTokenLegacy},
        q{code} => 401,
        q{type} => q{expired_token},
    },
    {
        q{name} => q{ExpiredToken},
        q{code} => 401,
        q{type} => q{invalid_token},
    },
    {
        q{name} => q{InsufficientScope},
        q{code} => 401,
        q{type} => q{insufficient_scope},
    },
    {
        q{name} => q{InvalidServerState},
        q{code} => 401,
        q{type} => q{invalid_server_state},
    },
    {
        q{name} => q{TemporarilyUnavailable},
        q{code} => 503,
        q{type} => q{temporarily_unavailable},
    },
    {
        q{name} => q{ServerError},
        q{code} => 500,
        q{type} => q{server_error},
    },
);

foreach my $defined_error (@defined_errors) {
    assert_server_error($defined_error);
}

done_testing();
