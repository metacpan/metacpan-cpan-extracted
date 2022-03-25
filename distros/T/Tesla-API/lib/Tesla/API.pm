package Tesla::API;

use warnings;
use strict;

use Carp qw(croak confess);
use Data::Dumper;
use Digest::SHA qw(sha256_hex);
use FindBin qw($RealBin);
use File::Copy;
use File::HomeDir;
use File::Share qw(:all);
use HTTP::Request;
use JSON;
use MIME::Base64 qw(encode_base64url);
use WWW::Mechanize;
use URI;

our $VERSION = '0.09';

$| = 1;

my $home_dir;

# The %api_cache hash is a cache for Tesla API call data across all objects.
# The $api_cache_alive_time is a timestamp of last cache write for a particular
# endpoint/ID pair, and is relative to API_CACHE_TIMEOUT_SECONDS

my %api_cache;
my $api_cache_alive_time = time;

BEGIN {
    $home_dir = File::HomeDir->my_home;
}

use constant {
    DEBUG_CACHE                 => $ENV{DEBUG_TESLA_API_CACHE},
    API_CACHE_PERSIST           => 0,
    API_CACHE_TIMEOUT_SECONDS   => 2,
    CACHE_FILE                  => "$home_dir/tesla_api_cache.json",
    ENDPOINTS_FILE              => dist_file('Tesla-API', 'endpoints.json'),
    OPTION_CODES_FILE           => dist_file('Tesla-API', 'option_codes.json'),
    URL_API                     => 'https://owner-api.teslamotors.com/',
    URL_ENDPOINTS               => 'https://raw.githubusercontent.com/tdorssers/TeslaPy/master/teslapy/endpoints.json',
    URL_OPTION_CODES            => 'https://raw.githubusercontent.com/tdorssers/TeslaPy/master/teslapy/option_codes.json',
    URL_AUTH                    => 'https://auth.tesla.com/oauth2/v3/authorize',
    URL_TOKEN                   => 'https://auth.tesla.com/oauth2/v3/token',
};

# Public object methods
sub new {
    my ($class, %params) = @_;
    my $self = bless {}, $class;

    $self->endpoints;

    # Return early if the user specifies that they are
    # not authenticated. Use this param for unit tests

    if ($params{unauthenticated}) {
        return $self;
    }

    $self->api_cache_persist($params{api_cache_persist});
    $self->api_cache_time($params{api_cache_time});

    $self->mech;
    $self->_access_token;

    return $self;
}
sub api {
    my ($self, %params) = @_;

    my $endpoint_name   = $params{endpoint};
    my $id              = $params{id};
    my $api_params      = $params{api_params};

    if (! defined $endpoint_name) {
        croak "Tesla::API::api() requires an endpoint name sent in";
    }

    my $endpoint = $self->endpoints($endpoint_name);

    my $type = $endpoint->{TYPE};
    my $auth = $endpoint->{AUTH};
    my $uri = $endpoint->{URI};

    if ($uri =~ /\{/) {
        if (! defined $id || $id !~ /^\d+$/) {
            croak "Endpoint $endpoint_name requires an \$id as an integer";
        }
        $uri =~ s/\{.*?\}/$id/;
    }

    # Return early if all cache mechanisms check out

    if ($self->api_cache_persist || $self->api_cache_time) {
        if (DEBUG_CACHE) {
            printf(
                "Cache - Alive: $api_cache_alive_time, Timeout: %.2f, Persist: %d\n",
                $self->api_cache_time,
                $self->api_cache_persist
            );
        }
        if ($self->api_cache_persist || time - $api_cache_alive_time <= $self->api_cache_time) {
            if ($self->_cache(endpoint => $endpoint_name, id => $id)) {
                print "Returning cache for $endpoint_name/$id pair...\n" if DEBUG_CACHE;
                return $self->_cache(endpoint => $endpoint_name, id => $id);
            }
        }
        print "No cache present for $endpoint_name/$id pair...\n" if DEBUG_CACHE;
    }

    my $url = URI->new(URL_API . $uri);

    my $header = ['Content-Type' => 'application/json; charset=UTF-8'];

    if ($auth) {
        my $token_string = "Bearer " . $self->_access_token;
        push @$header, 'Authorization' => $token_string;
    }

    my $request = HTTP::Request->new($type, $url, $header, encode_json($api_params));

    my $response = $self->mech->request($request);

    if ($response->is_success) {
        my $response_data = _decode($response->decoded_content)->{response};

        $self->_cache(
            endpoint => $endpoint_name,
            id       => $id,
            data     => $response_data
        );

        return $response_data;
    }
    else {
        warn $response->status_line;
    }
}
sub api_cache_clear {
    my ($self) = @_;
    %api_cache = ();
}
sub api_cache_persist {
    my ($self, $persist) = @_;
    if (defined $persist) {
        $self->{api_cache_persist} = $persist;
    }
    return $self->{api_cache_persist} // API_CACHE_PERSIST;
}
sub api_cache_time {
    my ($self, $cache_seconds) = @_;
    if (defined $cache_seconds) {
        $self->{api_cache_time} = $cache_seconds;
    }
    return $self->{api_cache_time} // API_CACHE_TIMEOUT_SECONDS;
}
sub endpoints {
    my ($self, $endpoint) = @_;

    if (! $self->{endpoints} || $self->{reset_data}) {
        $self->{reset_data} = 0;

        my $json_endpoints;
        {
            local $/;
            open my $fh, '<', ENDPOINTS_FILE
                or die "Can't open ${\ENDPOINTS_FILE}: $!";
            $json_endpoints = <$fh>;
        }

        my $perl_endpoints = decode_json($json_endpoints);
        $self->{endpoints} = $perl_endpoints;
    }

    if ($endpoint) {
        if (! exists $self->{endpoints}{$endpoint}) {
            croak "Tesla API endpoint $endpoint does not exist";
        }
        return $self->{endpoints}{$endpoint};
    }

    return $self->{endpoints};
}
sub mech {
    my ($self) = @_;

    return $self->{mech} if $self->{mech};

    my $www_mech = WWW::Mechanize->new(
        agent       => $self->_useragent_string,
        autocheck   => 0,
        timeout     => 3,
        cookie_jar  => {}
    );

    $self->{mech} = $www_mech;
}
sub object_data {
    my ($self) = @_;
    return $self->{data};
}
sub option_codes {
    my ($self, $code) = @_;

    if (! $self->{option_codes}) {
        my $json_option_codes;
        {
            local $/;
            open my $fh, '<', OPTION_CODES_FILE
                or die "Can't open ${\OPTION_CODES_FILE}: $!";
            $json_option_codes = <$fh>;
        }

        my $perl_option_codes = decode_json($json_option_codes);

        $self->{option_codes} = $perl_option_codes;
    }

    if ($code) {
        if (! exists $self->{option_codes}{$code}) {
            croak "Tesla API option code $code does not exist";
        }
        return $self->{option_codes}{$code};
    }

    return $self->{option_codes};
}
sub update_data_files {
    my ($self) = @_;

    for my $data_url (URL_ENDPOINTS, URL_OPTION_CODES) {
        my $filename;

        if ($data_url =~ /.*\/(\w+\.json)$/) {
            $filename = $1;
        }

        if (! defined $filename) {
            croak "Couldn't extract the filename from '$data_url'";
        }

        (my $data_method = $filename) =~ s/\.json//;

        my $url = URI->new($data_url);
        my $response = $self->mech->get($url);

        if ($response->is_success) {
            my $new_data = decode_json($response->decoded_content);
            my $existing_data = $self->$data_method;

            my $data_differs;

            if (scalar keys %$new_data != scalar keys %$existing_data) {
                $data_differs = 1;
            }

            if (! $data_differs) {
                for my $key (keys %$new_data) {
                    if (! exists $existing_data->{$key}) {
                        $data_differs = 1;
                        last;
                    }
                }
                for my $key (keys %$existing_data) {
                    if (! exists $new_data->{$key}) {
                        $data_differs = 1;
                        last;
                    }
                }
            }

            if ($data_differs) {
                $self->{reset_data} = 1;
                my $file = dist_file('Tesla-API', $filename);

                # Make a backup copy

                my $backup = "$file." . time;
                copy($file, $backup) or die "Can't create $file backup file!: $!";

                chmod 0644, $file;

                open my $fh, '>', "$file"
                    or die "Can't open '$file' for writing: $!";

                print $fh JSON->new->pretty->encode($new_data);
            }
        }
        else {
            croak $response->status_line;
        }
    }
}

# Private methods

sub _access_token {
    # Returns the access token from the cache file or generates
    # that cache file (with token) if it isn't available

    my ($self) = @_;

    if (! -e CACHE_FILE) {
        my $auth_code = $self->_authentication_code;
        $self->_access_token_generate($auth_code);
    }

    my $valid_token = $self->_access_token_validate;

    if (! $valid_token) {
        $self->_access_token_refresh;
    }

    $self->{access_token} = $self->_access_token_data->{access_token};

    return $self->{access_token};
}
sub _access_token_data {
    # Fetches and stores the cache data file dat

    my ($self, $data) = @_;

    $self->{cache_data} = $data if defined $data;

    return $self->{cache_data} if $self->{cache_data};

    {
        open my $fh, '<', CACHE_FILE or die "Can't open Tesla cache file " . CACHE_FILE . ": $!";
        my $json = <$fh>;
        $self->{cache_data} = decode_json($json);
    }

    return $self->{cache_data};
}
sub _access_token_generate {
    # Generates an access token and stores it in the cache file

    my ($self, $auth_code) = @_;

    if (! defined $auth_code) {
        croak "_access_token_generate() requires an \$auth_code parameter";
    }

    my $url = URI->new(URL_TOKEN);
    my $header = ['Content-Type' => 'application/json; charset=UTF-8'];

    my $request_data = {
        grant_type    => "authorization_code",
        client_id     => "ownerapi",
        code          => $auth_code,
        code_verifier => $self->_authentication_code_verifier,
        redirect_uri  => "https://auth.tesla.com/void/callback",
    };

    my $request = HTTP::Request->new('POST', $url, $header, encode_json($request_data));

    my $response = $self->mech->request($request);

    if ($response->is_success) {
        my $token_data = decode_json($response->decoded_content);

        $token_data = $self->_access_token_set_expiry($token_data);
        $self->_access_token_update($token_data);

        return $token_data;
    }
    else {
        croak $self->mech->response->status_line;
    }
}
sub _access_token_validate {
    # Checks the validity of an existing token

    my ($self) = @_;

    my $token_expires_at = $self->_access_token_data->{expires_at};
    my $token_expires_in = $self->_access_token_data->{expires_in};

    my $valid = 0;

    if (time + $token_expires_in < $token_expires_at) {
        $valid = 1;
    }

    return $valid;
}
sub _access_token_set_expiry {
    # Sets the access token expiry date/time after generation and
    # renewal

    my ($self, $token_data) = @_;

    if (! defined $token_data || ref($token_data) ne 'HASH') {
        croak "_access_token_set_expiry() needs a hash reference of token data";
    }

    my $expiry = time + $token_data->{expires_in};

    $token_data->{expires_at} = $expiry;

    return $token_data;
}
sub _access_token_refresh {
    # Renews an expired/invalid access token

    my ($self) = @_;

    my $url = URI->new(URL_TOKEN);
    my $header = ['Content-Type' => 'application/json; charset=UTF-8'];

    my $refresh_token = $self->_access_token_data->{refresh_token};

    my $request_data = {
        grant_type    => 'refresh_token',
        refresh_token => $refresh_token,
        client_id     => 'ownerapi',
    };

    my $request = HTTP::Request->new('POST', $url, $header, encode_json($request_data));

    my $response = $self->mech->request($request);

    if ($response->is_success) {
        my $token_data = decode_json($response->decoded_content);

        # Re-add the existing refresh token; its still valid
        $token_data->{refresh_token} = $refresh_token;

        # Set the expiry time
        $token_data = $self->_access_token_set_expiry($token_data);

        # Update the cached token
        $self->_access_token_update($token_data);
    }
    else {
        croak $self->mech->response->status_line;
    }
}
sub _access_token_update {
    # Writes the new or updated token to the cache file

    my ($self, $token_data) = @_;

    if (! defined $token_data || ref($token_data) ne 'HASH') {
        croak "_access_token_update() needs a hash reference of token data";
    }

    $self->_access_token_data($token_data);

    open my $fh, '>', CACHE_FILE or die $!;
    print $fh encode_json($token_data);
}
sub _authentication_code {
    # If an access token is unavailable, prompt the user with a URL to
    # authenticate to Tesla, and have them paste in the resulting URL
    # We then extract and return the access code to generate the access
    # token

    my ($self) = @_;
    my $auth_url = URI->new(URL_AUTH);

    my %params = (
        client_id             => 'ownerapi',
        code_challenge        => $self->_authentication_code_verifier,
        code_challenge_method => 'S256',
        redirect_uri          => 'https://auth.tesla.com/void/callback',
        response_type         => 'code',
        scope                 => 'openid email offline_access',
        state                 => '123',
        login_hint            => $ENV{TESLA_EMAIL},
    );

    $auth_url->query_form(%params);

    print
        "Please follow the URL displayed below in your browser and log into Tesla, " .
        "then paste the URL from the resulting 'Page Not Found' page's address bar, " .
        "then hit ENTER:\n";

    print "\n$auth_url\n";

    print "\nPaste URL here: ";

    my $code_url = <STDIN>;
    chomp $code_url;

    my $code;

    if ($code_url =~ /code=(.*?)\&/) {
        $code = $1;
    }
    else {
        croak "Could not extract the authorization code from the URL";
    }

    return $code;
}
sub _authentication_code_verifier {
    # When generating an access token, generate and store a code
    # validation key

    my ($self) = @_;

    if (defined $self->{authentication_code_verifier}) {
        return $self->{authentication_code_verifier}
    }

    my $code_verifier = _random_string();
    $code_verifier = sha256_hex($code_verifier);
    $code_verifier = encode_base64url($code_verifier);

    return $self->{authentication_code_verifier} = $code_verifier;
}
sub _cache {
    # Stores the Tesla API fetched data
    my ($self, %params) = @_;

    my $endpoint = $params{endpoint};
    my $id = $params{id} // 0;
    my $data = $params{data};

    if (! $endpoint) {
        croak "_cache() requires an endpoint name sent in";
    }

    if ($data) {
        $api_cache{$endpoint}{$id} = $data;
        $api_cache_alive_time = time;
    }

    return $api_cache{$endpoint}{$id};
}
sub _decode {
    # Decode JSON to Perl
    my ($json) = @_;
    my $perl = decode_json($json);
    return $perl;
}
sub _random_string {
    # Returns a proper length alpha-num string for token code
    # verification key

    my @chars = ('A' .. 'Z', 'a' .. 'z', 0 .. 9);
    my $rand_string;
    $rand_string .= $chars[rand @chars] for 1 .. 85;
    return $rand_string;
}
sub _useragent_string {
    # Returns the user agent string
    my ($self) = @_;
    my $ua = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:98.0) Gecko/20100101 Firefox/98.0';
    return $ua;
}

1;

=head1 NAME

Tesla::API - Interface to Tesla's API

=for html
<a href="https://github.com/stevieb9/tesla-api/actions"><img src="https://github.com/stevieb9/tesla-api/workflows/CI/badge.svg"/></a>
<a href='https://coveralls.io/github/stevieb9/tesla-api?branch=master'><img src='https://coveralls.io/repos/stevieb9/tesla-api/badge.svg?branch=master&service=github' alt='Coverage Status' /></a>

=head1 SYNOPSIS

    use Tesla::API;

    my $tesla = Tesla::API->new;

    my @endpoint_names = keys %{ $tesla->endpoints };

    # See Tesla::Vehicle for direct access to vehicle-related methods

    my $endpoint_name   = 'VEHICLE_DATA';
    my $vehicle_id      = 3234234242124;

    # Get the entire list of car data

    my $car_data = $tesla->api(
        endpoint    => $endpoint_name,
        id          => $vehicle_id
    );

    # Send the open trunk command

    $tesla->api(
        endpoint    => 'ACTUATE_TRUNK',
        id          => $vehicle_id,
        api_params  => {which_trunk => 'rear'}
    );

    if ($tesla->trunk_rear) {
        # Trunk is open
        put_stuff_in_trunk();
    }

=head1 DESCRIPTION

This distribution provides access to the Tesla API.

B<WARNING>: This is an initial, beta release. The interface may change.

This class is designed to be subclassed. For example, I have already begun a
new L<Tesla::Vehicle> distribution which will have access and update methods
that deal specifically with Tesla autos, then a C<Tesla::Powerwall>
distribution for their battery storage etc.

=head1 METHODS - CORE

=head2 new(%params)

Instantiates and returns a new L<Tesla::API> object.

B<NOTE>: When instantiating an object and you haven't previously authenticated,
a URL will be displayed on the console for you to navigate to. You will then
be redirected to Tesla's login page where you will authenticate. You will
be redirected again to a "Page Not Found" page, in which you must copy the URL
from the address bar and paste it back into the console.

We then internally generate an access token for you, store it in a
C<tesla_cache.json> file in your home directory, and use it on all subsequent
accesses.

B<NOTE>: If you do not have a Tesla account, you can still instantiate a
L<Tesla::API> object by supplying the C<< unauthenticated => 1 >> parameter
to C<new()>.

B<Parameters>:

All parameters are to be sent in the form of a hash.

    unauthenticated

I<Optional, Bool>: Set to true to bypass the access token generation.

I<Default>: C<undef>

    api_cache_persist

I<Optional, Bool>: Set this to true if you want to make multiple calls against
the same data set, where having the cache time out and re-populated between
these calls would be non-beneficial.

I<Default>: False

    api_cache_time

I<Optional, Integer>: By default, we cache the fetched data from the Tesla API
for two seconds. If you make calls that have already been called within that
time, we will return the cached data.

Send in the number of seconds you'd like to cache the data for. A value of zero
(C<0>) will disable caching and all calls through this library will go directly
to Tesla every time.

I<Return>: Integer, the number of seconds we're caching Tesla API data for.

=head2 api(%params)

Responsible for disseminating the endpoints and retrieving data through the
Tesla API.

All parameters are to be sent in as a hash.

B<Parameters>:

    endpoint

I<Mandatory, String>: A valid Tesla API endpoint name. The entire list can be
found in the C<t/test_data/endpoints.json> file for the time being.

    id

I<Optional, Integer>: Some endpoints require an ID sent in (eg. vehicle ID,
Powerwall ID etc).

    api_params

I<Optional, Hash Reference>: Some API calls require additional parameters. Send
in a hash reference where the keys are the API parameter name, and the value is,
well, the value.

I<Return>: Hash or array reference, depending on the endpoint.

=head2 endpoints

Returns a hash reference of hash references. Each key is the name of the
endpoint, and its value contains data on how we process the call to Tesla.

Example (snipped for brevity):

    {
        MEDIA_VOLUME_DOWN => {
            TYPE => 'POST',
            URI => 'api/1/vehicles/{vehicle_id}/command/media_volume_down'
            AUTH => $VAR1->{'UPGRADES_CREATE_OFFLINE_ORDER'}{'AUTH'},
        },
        VEHICLE_DATA => {
            TYPE => 'GET',
            URI => 'api/1/vehicles/{vehicle_id}/vehicle_data',
            AUTH => $VAR1->{'UPGRADES_CREATE_OFFLINE_ORDER'}{'AUTH'}
        },
    }

Bracketed names in the URI (eg: C<{vehicle_id}>) are variable placeholders.
It will be replaced with the ID sent in to the various method or C<api()>
call.

To get a list of endpoint names:

    my @endpoint_names = keys %{ $tesla->endpoints };

=head2 mech

Returns the L<WWW::Mechanize> object we've instantiated internally.

=head2 object_data

Returns a hash reference of the data we've collected for you and stashed
within the object. This does not reflect the entire object, just the data
returned from Tesla's API.

=head2 option_codes

B<NOTE>: I'm unsure if the option codes are vehicle specific, or general for
all Tesla products, so I'm leaving this method here for now.

Returns a hash reference of 'option code' => 'description' pairs.

=head2 update_data_files

Checks to see if there are any updates to the C<endpoints.json> or
C<option_codes.json> files online, and updates them locally.

Takes no parameters, there is no return. C<croak()>s on failure.

=head1 METHODS - API CACHE

=head2 api_cache_clear

Some methods chain method calls. For example, calling
C<< $vehicle->doors_lock >> will poll the API, then cache the state data.

if another call is made to C<< $vehicle->locked >> immediately thereafter to
check whether the door is actually closed or not, the old cached data would
normally be returned.

If we don't clear the cache out between these two calls, we will be returned
stale data.

Takes no parameters, has no return. Only use this call in API calls that
somehow manipulate the state of the object you're working with.

=head2 api_cache_persist($bool)

    $bool

I<Optional, Bool>: Set this to true if you want to make multiple calls against
the same data set, where having the cache time out and re-populated between
these calls would be non-beneficial.

You can ensure fresh data for the set by making a call to C<api_cache_clear()>
before the first call that fetches data.

I<Default>: False

=head2 api_cache_time($cache_seconds)

The number of seconds we will cache retrieved endpoint data from the Tesla API
for, to reduce the number of successive calls to retrieve the same data.

B<Parameters>:

    $cache_seconds

I<Optional, Integer>: By default, we cache the fetched data from the Tesla API
for two seconds. If you make calls that have already been called within that
time, we will return the cached data.

Send in the number of seconds you'd like to cache the data for. A value of zero
(C<0>) will disable caching and all calls through this library will go directly
to Tesla every time.

I<Return>: Integer, the number of seconds we're caching Tesla API data for.

=head1 API CACHING

We've employed a complex caching mechanism for data received from Tesla's API.

By default, we cache retrieved data for every endpoint/ID pair in the cache for
two seconds (modifiable by C<api_cache_timeout()>, or C<api_cache_timeout> in
C<new()>).

This means that if you call three methods in a row that all extract information
from the data returned via a single endpoint/ID pair, you may get back the
cached result, or if the cache has timed out, you'll get data from another call
to the Tesla API. In some cases, having the data updated may be desirable,
sometimes you want data from the same set.

Here are some examples on how to deal with the caching mechanism. We will use
a L<Tesla::Vehicle> object for this example:

=head2 Store API cache for 10 seconds

Again, by default, we cache and return data from the Tesla API for two seconds.
Change it to 10:

    my $api = Tesla::API->new(api_cache_timeout => 10);

...or:

    my $car = Tesla::Vehicle->new(api_cache_timeout => 10);

...or:

    $car->api_cache_timeout(10);

=head2 Disable API caching

    my $api = Tesla::API->new(api_cache_timeout => 0);

...or:

    my $car = Tesla::Vehicle->new(api_cache_timeout => 0);

...or:

    $car->api_cache_timeout(0);

=head2 Flush the API cache

    $api->api_cache_clear;

...or:

    $car->api_cache_clear;

=head2 Permanently use the cached data until manually flushed

    my $api = Tesla::API->new(api_cache_persist => 1);

...or:

    my $car = Tesla::Vehicle->new(api_cache_persist => 1);

...or:

    $car->api_cache_persist(1);

=head2 Use the cache for a period of time

If making multiple calls to methods that use the same data set and want to be
sure the data doesn't change until you're done, do this:

    my $car = Tesla::Vehicle->new; # Default caching of 2 seconds

    sub work {

        # Clear the cache so it gets updated, but set it to persistent so once
        # the cache data is updated, it remains

        $car->api_cache_clear;
        $car->api_cache_persist(1);

        say $car->online;
        say $car->lat;
        say $car->lon;
        say $car->battery_level;

        # Now unset the persist flag so other parts of your program won't be
        # affected by it

        $car->api_cache_persist(0);
    }

If you are sure no other parts of your program will be affected by having a
persistent cache, you can set it globally:

    my $car = Tesla::Vehicle->new(api_cache_persist => 1);

    while (1) {

        # Clear the cache at the beginning of the loop so it gets updated,
        # unless you never want new data after the first saving of data

        $car->api_cache_clear;

        say $car->online;
        say $car->lat;
        say $car->lon;
        say $car->battery_level;
    }

=head1 EXAMPLE USAGE

See L<Tesla::Vehicle> for vehicle specific methods.

    use Data::Dumper;
    use Tesla::API;
    use feature 'say';

    my $tesla = Tesla::API->new;
    my $vehicle_id = 1234238782349137;

    print Dumper $tesla->api(endpoint => 'VEHICLE_DATA', id => $vehicle_id);

Output (massively and significantly snipped for brevity):

    $VAR1 = {
        'vehicle_config' => {
            'car_type' => 'modelx',
            'rear_seat_type' => 7,
            'rear_drive_unit' => 'Small',
            'wheel_type' => 'Turbine22Dark',
            'timestamp' => '1647461524710',
            'rear_seat_heaters' => 3,
            'trim_badging' => '100d',
            'headlamp_type' => 'Led',
            'driver_assist' => 'TeslaAP3',
        },
        'id_s' => 'XXXXXXXXXXXXXXXXX',
        'vehicle_id' => 'XXXXXXXXXX',
        'charge_state' => {
            'usable_battery_level' => 69,
            'battery_range' => '189.58',
            'charge_limit_soc_std' => 90,
            'charge_amps' => 48,
            'charge_limit_soc' => 90,
            'battery_level' => 69,
        },
        'vin' => 'XXXXXXXX',
        'in_service' => $VAR1->{'vehicle_config'}{'use_range_badging'},
        'user_id' => 'XXXXXX',
        'id' => 'XXXXXXXXXXXXX',
        'drive_state' => {
            'shift_state' => 'P',
            'heading' => 92,
            'longitude' => '-XXX.XXXXXX',
            'latitude' => 'XX.XXXXXX',
            'power' => 0,
            'speed' => undef,
        },
        'api_version' => 34,
        'display_name' => 'Dream machine',
        'state' => 'online',
        'access_type' => 'OWNER',
        'option_codes' => 'AD15,MDL3,PBSB,RENA,BT37,ID3W,RF3G,S3PB,DRLH,DV2W,W39B,APF0,COUS,BC3B,CH07,PC30,FC3P,FG31,GLFR,HL31,HM31,IL31,LTPB,MR31,FM3B,RS3H,SA3P,STCP,SC04,SU3C,T3CA,TW00,TM00,UT3P,WR00,AU3P,APH3,AF00,ZCST,MI00,CDM0',
        'vehicle_state' => {
            'valet_mode' => $VAR1->{'vehicle_config'}{'use_range_badging'},
            'vehicle_name' => 'Dream machine',
            'sentry_mode_available' => $VAR1->{'vehicle_config'}{'plg'},
            'sentry_mode' => $VAR1->{'vehicle_config'}{'use_range_badging'},
            'car_version' => '2022.4.5.4 abcfac6bfcdc',
            'homelink_device_count' => 3,
            'is_user_present' => $VAR1->{'vehicle_config'}{'use_range_badging'},
            'odometer' => 'XXXXXXX.233656',
            'media_state' => {
                'remote_control_enabled' => $VAR1->{'vehicle_config'}{'plg'}
            },
        },
        'autopark_style' => 'dead_man',
        'software_update' => {
            'expected_duration_sec' => 2700,
            'version' => ' ',
            'status' => '',
            'download_perc' => 0,
            'install_perc' => 1
        },
        'speed_limit_mode' => {
            'max_limit_mph' => 90,
            'min_limit_mph' => '50',
            'active' => $VAR1->{'vehicle_config'}{'use_range_badging'},
            'current_limit_mph' => '80.029031',
            'pin_code_set' => $VAR1->{'vehicle_config'}{'plg'}
        },
        'climate_state' => {
               'passenger_temp_setting' => '20.5',
               'driver_temp_setting' => '20.5',
               'side_mirror_heaters' => $VAR1->{'vehicle_config'}{'use_range_badging'},
               'is_climate_on' => $VAR1->{'vehicle_config'}{'use_range_badging'},
               'fan_status' => 0,
               'seat_heater_third_row_right' => 0,
               'seat_heater_right' => 0,
               'is_front_defroster_on' => $VAR1->{'vehicle_config'}{'use_range_badging'},
               'battery_heater' => $VAR1->{'vehicle_config'}{'use_range_badging'},
               'is_rear_defroster_on' => $VAR1->{'vehicle_config'}{'use_range_badging'},
        },
        'gui_settings' => {
              'gui_temperature_units' => 'C',
              'gui_charge_rate_units' => 'km/hr',
              'gui_24_hour_time' => $VAR1->{'vehicle_config'}{'use_range_badging'},
              'gui_range_display' => 'Ideal',
              'show_range_units' => $VAR1->{'vehicle_config'}{'plg'},
              'gui_distance_units' => 'km/hr',
              'timestamp' => '1647461524710'
        }
    };

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

This distribution suite has been a long time in the works. For my other projects
written in Perl previous to writing this code that required data from the Tesla
API, I wrapped L<Tim Dorssers|https://github.com/tdorssers> wonderful
L<TeslaPy|https://github.com/tdorssers/TeslaPy> Python project.

Much of the code in this distribution is heavily influenced by the code his
project, and currently, we're using a direct copy of its
L<Tesla API endpoint file|https://github.com/tdorssers/TeslaPy/blob/master/teslapy/endpoints.json>.

Thanks Tim, and great work!

Also thanks goes out to L<https://teslaapi.io>, as a lot of the actual request
parameter information and response data layout I learned from that site while
implementing the actual REST calls to the Tesla API.

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

The copied endpoint code data borrowed from Tim's B<TeslaPy> project has been
rebranded with the Perl license here, as permitted by the MIT license TeslaPy
is licensed under.

=cut
