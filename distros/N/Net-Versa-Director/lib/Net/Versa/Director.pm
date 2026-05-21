package Net::Versa::Director;
$Net::Versa::Director::VERSION = '0.005000';
# ABSTRACT: Versa Director REST API client library

use v5.38;
use Moo;
use feature qw( class signatures );
no warnings 'experimental::class';
use Types::Standard qw( Str );
use Net::Versa::Director::Serializer;


has 'user' => (
    isa => Str,
    is  => 'rw',
);

has 'passwd' => (
    isa => Str,
    is  => 'rw',
);

has '_refresh_token' => (
    isa     => Str,
    is      => 'rw',
    clearer => 1,
);

with 'Role::REST::Client';

has '+serializer_class' => (
    default => sub { 'Net::Versa::Director::Serializer' },
);

with 'Role::REST::Client::Auth::Basic';

sub _is_oauth ($self) {
    return $self->server =~ /:9183/;
}

# has to be after "with 'Role::REST::Client::Auth::Basic';" to be called before
# its method modifier
before '_call' => sub ($self, $method, $endpoint, $data, $args) {
    # disable http basic auth if talking to the OAuth port
    $args->{authentication} = 'none'
        if $self->_is_oauth;
};

has '+persistent_headers' => (
    default => sub {
        return { Accept => 'application/json' };
    },
);

# around 'do_request' => sub($orig, $self, $method, $uri, $opts) {
#     use DDP;
#     warn 'request: ' . np($method) . np($uri) . np($opts);
#     my $response = $orig->($self, $method, $uri, $opts);
#     warn 'response: ' .  np $response;
#     return $response;
# };


class Net::Versa::Director::Exception {
    use overload q{""} => 'as_string', fallback => 1;
}
class Net::Versa::Director::Exception::OAuth :isa(Net::Versa::Director::Exception) {
    field $error                :param :reader;
    field $error_description    :param :reader;

    method as_string {
        return $error_description;
    }
}
class Net::Versa::Director::Exception::Basic :isa(Net::Versa::Director::Exception) {
    field $code                 :param :reader;
    field $description          :param :reader;
    field $http_status_code     :param :reader;
    field $message              :param :reader;
    field $more_info            :param :reader;

    method as_string {
        return $description;
    }
}
class Net::Versa::Director::Exception::VNMS :isa(Net::Versa::Director::Exception) {
    field $error                :param :reader;
    field $exception            :param :reader;
    field $timestamp            :param :reader;
    field $http_status_code     :param :reader;
    field $message              :param :reader;
    field $path                 :param :reader;

    method as_string {
        return $message;
    }
}
class Net::Versa::Director::Exception::Other :isa(Net::Versa::Director::Exception) {
    field $http_status_code     :param :reader;
    field $message              :param :reader;

    method as_string {
        return $message;
    }
}

sub _error_handler ($self, $res) {
    if (ref $res->data eq 'HASH') {
        if (exists $res->data->{error} && ref $res->data->{error} eq 'HASH') {
            if (exists $res->data->{error}->{code}) {
                die Net::Versa::Director::Exception::Basic->new(
                    $res->data->{error}->%*,
                );
            }
            die Net::Versa::Director::Exception::VNMS->new(
                $res->data->{error}->%*,
            );
        }
        elsif ($self->_is_oauth && exists $res->data->{error_description}) {
            die Net::Versa::Director::Exception::OAuth->new(
                $res->data->%*,
            );
        }

        die Net::Versa::Director::Exception::VNMS->new(
            $res->data->%*
        );
    }
    # handle undocumented API error responses
    else {
        die Net::Versa::Director::Exception::Other->new(
            http_status_code    => $res->code,
            message             => $res->response->status_line,
        );
    }
}

sub _create ($self, $url, $object_data, $query_params = {}, $expected_code = 201, $args = {}) {
    my $params = $self->user_agent->www_form_urlencode( $query_params );
    my $res = $self->post("$url?$params", $object_data, $args);
    $self->_error_handler($res)
        unless $res->code == $expected_code;

    return $res->data;
}

sub _get ($self, $url, $query_params = {}, $args = {}) {
    my $res = $self->get($url, $query_params, $args);
    $self->_error_handler($res)
        unless $res->code == 200;

    return $res->data;
}

sub _update ($self, $url, $object, $object_data, $query_params = {}, $args = {}) {
    my $updated_data = clone($object);
    $updated_data = { %$updated_data, %$object_data };
    my $params = $self->user_agent->www_form_urlencode( $query_params );
    my $res = $self->put("$url?$params", $updated_data, $args);
    $self->_error_handler($res)
        unless $res->code == 200;

    return $res->data;
}

sub _delete ($self, $url, $args = {}) {
    my $res = $self->delete($url, undef, $args);
    $self->_error_handler($res)
        unless $res->code == 200;

    return 1;
}


sub login ($self, $client_id, $client_secret) {
    my $login_response = $self->_create('/auth/token', {
        client_id       => $client_id,
        client_secret   => $client_secret,
        username        => $self->user,
        password        => $self->passwd,
        grant_type      => "password",
    }, {}, 200);
    my $access_token = $login_response->{access_token};
    $self->set_persistent_header('Authorization', "Bearer $access_token");
    $self->_refresh_token($login_response->{refresh_token});
    return $login_response;
}


sub logout ($self) {
    my $res = $self->_create('/auth/revoke', undef, {}, 200);

    $self->_clear_refresh_token;
    $self->clear_persistent_headers;

    return $res;
}


sub get_director_info ($self) {
    return $self->_get('/api/operational/system/package-info')
        ->{'package-info'}->[0];
}


sub get_version ($self) {
    return $self->get_director_info->{branch};
}


sub list_appliances ($self) {
    return $self->_get('/vnms/appliance/appliance', { offset => 0, limit => 2048 })
        ->{'versanms.ApplianceStatusResult'}->{appliances};
}


sub list_device_workflows ($self) {
    return $self->_get('/vnms/sdwan/workflow/devices', { offset => 0, limit => 2048 })
        ->{'versanms.sdwan-device-list'};
}


sub get_device_workflow ($self, $device_workflow_name ) {
    return $self->_get("/vnms/sdwan/workflow/devices/device/$device_workflow_name")
        ->{'versanms.sdwan-device-workflow'};
}


sub list_assets ($self) {
    return $self->_get('/vnms/assets/asset', { offset => 0, limit => 2048 })
        ->{'versanms.AssetsResult'}->{assets};
}


sub list_device_interfaces ($self, $devicename) {
    return $self->_get("/api/config/devices/device/$devicename/config/interfaces?deep")
        ->{interfaces};
}


sub list_device_networks ($self, $devicename) {
    return $self->_get("/api/config/devices/device/$devicename/config/networks/network")
        ->{network};
}


sub get_device_configuration ($self, $devicename) {
    $self->set_header(Accept => 'text/plain');
    return $self->_get("/vnms/appliance/export",
        {
            applianceName           => $devicename,
        }, {
            deserializer => undef,
        });
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Versa::Director - Versa Director REST API client library

=head1 VERSION

version 0.005000

=head1 SYNOPSIS

    use v5.38;
    use Net::Versa::Director;

    # to use the username/password basic authentication

    my $director = Net::Versa::Director->new(
        server      => 'https://director.example.com:9182',
        user        => 'username',
        passwd      => '$password',
        clientattrs => {
            timeout     => 10,
        },
    );

    # OR to use the OAuth token based authentication

    $director = Net::Versa::Director->new(
        server      => 'https://director.example.com:9183',
        user        => 'username',
        passwd      => '$password',
        clientattrs => {
            timeout     => 10,
        },
    );

    # this is required to fetch the OAuth access and refresh tokens
    # using the client id and secret passed to user and passwd.
    $director->login;

    # at the end of your code, possible in an END block to always execute it
    # after a successful login to not exceed the maximum number of access
    # tokens.
    $director->logout;

=head1 DESCRIPTION

This module is a client library for the Versa Director REST API.

Currently it is developed and tested against version 22.1.4.

For more information see
L<https://docs.versa-networks.com/Management_and_Orchestration/Versa_Director/Director_REST_APIs/Versa_Director_REST_API_Overview>.

=head1 METHODS

=head2 login

Takes a client id and secret.

Logs into the Versa Director when using the OAuth token based port 9183.

Sets the Authorization header to the Bearer access token.

Returns a hashref containing the OAuth access- and refresh-tokens.

=head2 logout

Revokes the access token if OAuth authentication is used so the maximum number
of access tokens of the client isn't exceeded.

Returns the response.

=head2 get_director_info

Returns the Versa Director information as hashref.

From /api/operational/system/package-info.

=head2 get_version

Returns the Versa Director version.

From L</get_director_info>->{branch}.

=head2 list_appliances

Returns an arrayref of Versa appliances.

From /vnms/appliance/appliance.

=head2 list_device_workflows

Returns an arrayref of device workflows.

From /vnms/sdwan/workflow/devices.

=head2 get_device_workflow

Takes a workflow name.

Returns a hashref of device workflow data.

From /vnms/sdwan/workflow/devices/device/$device_workflow_name.

=head2 list_assets

Returns an arrayref of Versa appliances.

From /vnms/assets/asset.

=head2 list_device_interfaces

Takes a device name.

Returns a hashref of interface types each containing an arrayref of interface
hashrefs.

From /api/config/devices/device/$devicename/config/interfaces?deep.

=head2 list_device_networks

Takes a device name.

Returns an arrayref of network hashrefs.

From /api/config/devices/device/$devicename/config/networks/network?deep=true.

=head2 get_device_configuration

Takes a device name.

Returns the current device configuration as string.

From /vnms/appliance/export?applianceName=$devicename.

=head1 ERROR handling

All methods throw an exception on error returning the unmodified data from the API
as a Net::Versa::Director::Exception subclass object which stringifies to an error message.

Currently the Versa Director has multiple different API error formats depending on
the type of request.

See L<https://docs.versa-networks.com/Management_and_Orchestration/Versa_Director/Director_REST_APIs/Versa_Director_REST_API_Overview#Status_and_Error_Responses>
for a detailed documentation about the possible error responses.

=head2 OAuth errors

Are thrown as Net::Versa::Director::Exception::OAuth objects and have the following attributes:

    error               => 'invalid_client',
    error_description   =>'Client authentication failed (e.g., unknown client, no client authentication included, or unsupported authentication method).',

=head2 YANG data model errors

All API endpoints starting with /api/config or /api/operational return this type of error.
They are thrown as Net::Versa::Director::Exception::Basic objects and have the following attributes:

    code                => 401,
    description         => "Invalid user name or password.",
    http_status_code    => 401,
    message             => "Unauthenticated",
    more_info           => "http://nms.versa.com/errors/401",

=head2 YANG and relational data model errors

All API endpoints starting with /vnms are thrown as Net::Versa::Director::Exception::VNMS objects:

    error               => "Not Found",
    exception           => "com.versa.vnms.common.exception.VOAEException",
    http_status_code    => 404,
    message             => " device work flow non-existing does not exist ",
    path                => "/vnms/sdwan/workflow/devices/device/non-existing",
    timestamp           => 1696574964569,

=head2 other errors

If an error response doesn't conform to any of the above documented types, the exception is thrown
as Net::Versa::Director::Exception::Other object:

    http_status_code    => 500,
    message             => "500 Internal Server Error",

=head1 TESTS

To run the live API tests the following environment variables need to be set:

=over

=item NET_VERSA_DIRECTOR_HOSTNAME

=item NET_VERSA_DIRECTOR_USERNAME

=item NET_VERSA_DIRECTOR_PASSWORD

=item NET_VERSA_DIRECTOR_CLIENT_ID

=item NET_VERSA_DIRECTOR_CLIENT_SECRET

=back

If basic authentication tests should be also run set this additional variable to true.

=over

=item NET_VERSA_DIRECTOR_BASIC_AUTH

=back

Only read calls are tested so far.

=head1 AUTHOR

Alexander Hartmaier <alex@hartmaier.priv.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Alexander Hartmaier.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
