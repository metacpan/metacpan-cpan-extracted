package TestAPI;
use Net::HTTP::API;

use HTTP::Response;

net_api_declare fake_api => (
    api_base_url => 'http://exemple.com',
    format       => 'json',
);

net_api_method users => (
    method   => 'GET',
    path     => '/users/',
    expected => [qw/200/],
);

net_api_method user => (
    method   => 'GET',
    path     => '/user/:user_name/:last_name',
    params   => [qw/user_name last_name/],
    required => [qw/user_name/],
    expected => [qw/200/],
);

net_api_method add_user => (
    method   => 'POST',
    path     => '/user/',
    params   => [qw/name dob/],
    required => [qw/name/],
    expected => [qw/201/],
);

net_api_method update_user => (
    method   => 'PUT',
    path     => '/user/:name',
    params   => [qw/name dob/],
    required => [qw/name/],
    expected => [qw/201/],
);

net_api_method delete_user => (
    method   => 'DELETE',
    path     => '/user/:name',
    params   => [qw/name/],
    required => [qw/name/],
    expected => [qw/204/],
);

net_api_method unstrict_users => (
    method   => 'GET',
    path     => '/users/unstrict',
    strict   => 0,
    params   => [qw/name/],
    required => [qw/name/],
);

net_api_method params_users => (
    method        => 'POST',
    path          => '/users/',
    params        => [qw/name/],
    params_in_url => [qw/bod/],
    required      => [qw/bod name/],
);

1;
