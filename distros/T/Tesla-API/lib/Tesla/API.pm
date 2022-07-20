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
use UUID;

our $VERSION = '1.02';

$| = 1;

my $home_dir;

# The %api_cache hash is a cache for Tesla API call data across all objects.
# It is managed by the _api_cache() private method. Each cache slot contains the
# time() that it was stored, and will time out after
# API_CACHE_TIMEOUT_SECONDS/api_cache_time()

my %api_cache;

BEGIN {
    $home_dir = File::HomeDir->my_home;
}

use constant {
    DEBUG_CACHE                 => $ENV{DEBUG_TESLA_API_CACHE},
    API_CACHE_PERSIST           => 0,
    API_CACHE_TIMEOUT_SECONDS   => 2,
    API_TIMEOUT_RETRIES         => 3,
    AUTH_CACHE_FILE             => "$home_dir/tesla_auth_cache.json",
    ENDPOINTS_FILE              => $ENV{TESLA_API_ENDPOINTS_FILE} // dist_file('Tesla-API', 'endpoints.json'),
    OPTION_CODES_FILE           => $ENV{TESLA_API_OPTIONCODES_FILE} // dist_file('Tesla-API', 'option_codes.json'),
    TOKEN_EXPIRY_WINDOW         => 5,
    URL_API                     => 'https://owner-api.teslamotors.com/',
    URL_ENDPOINTS               => 'https://raw.githubusercontent.com/tdorssers/TeslaPy/master/teslapy/endpoints.json',
    URL_OPTION_CODES            => 'https://raw.githubusercontent.com/tdorssers/TeslaPy/master/teslapy/option_codes.json',
    URL_AUTH                    => 'https://auth.tesla.com/oauth2/v3/authorize',
    URL_TOKEN                   => 'https://auth.tesla.com/oauth2/v3/token',
    USERAGENT_STRING            => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:98.0) Gecko/20100101 Firefox/98.0',
    USERAGENT_TIMEOUT           => 180,
};

# Public object methods

sub new {
    my ($class, %params) = @_;
    my $self = bless {}, $class;

    $self->endpoints;

    $self->uuid;

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
    my $uri  = $endpoint->{URI};

    if ($uri =~ /\{/) {
        if (! defined $id || $id !~ /^\d+$/) {
            croak "Endpoint $endpoint_name requires an \$id as an integer";
        }
        $uri =~ s/\{.*?\}/$id/;
    }

    $id //= 0;

    # Return early if all cache mechanisms check out

    if ($self->api_cache_persist || $self->api_cache_time) {
        my $cache = $self->_api_cache(endpoint => $endpoint_name, id => $id);
        if ($cache) {
            if ($self->api_cache_persist || time - $cache->{time} <= $self->api_cache_time) {
                warn "Returning cache for $endpoint_name/$id pair...\n" if DEBUG_CACHE;
                return $cache->{data};
            }
        }
    }

    my $url = $self->uri(URL_API . $uri);

    my $header = ['Content-Type' => 'application/json; charset=UTF-8'];

    if ($auth) {
        my $token_string = "Bearer " . $self->_access_token;
        push @$header, 'Authorization' => $token_string;
    }

    my $request = HTTP::Request->new(
        $type,
        $url,
        $header,
        JSON->new->allow_nonref->encode($api_params)
    );

    my ($success, $code, $response_data) = $self->_tesla_api_call($request);
    my $data = $self->_decode($response_data);

    if ($data->{error}) {
        return $data;
    }

    $self->_api_cache(
        endpoint => $endpoint_name,
        id       => $id,
        data     => $data->{response}
    );

    return $data->{response};
}
sub api_cache_clear {
    my ($self) = @_;
    $api_cache{$self->uuid} = {};
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
        if ($cache_seconds !~ /^\d+$/) {
            croak "api_cache_time() requires an int as \$cache_seconds param";
        }
        $self->{api_cache_time} = $cache_seconds;
    }
    return $self->{api_cache_time} // API_CACHE_TIMEOUT_SECONDS;
}
sub endpoints {
    my ($self, $endpoint) = @_;

    if (! $self->{endpoints} || $self->{reset_endpoints_data}) {
        $self->{reset_endpoints_data} = 0;

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

    if ($self->{mech} && ! $self->{mech_reset}) {
        return $self->{mech};
    }

    my $www_mech = WWW::Mechanize->new(
        agent      => $self->useragent_string,
        autocheck  => 0,
        cookie_jar => {},
        timeout    => $self->useragent_timeout
    );

    $self->{mech} = $www_mech;
    $self->{mech_reset} = 0;

    return $self->{mech};
}
sub option_codes {
    my ($self, $code) = @_;

    if (! $self->{option_codes} || $self->{reset_option_codes_data}) {
        print "RESET DATA\n";
        $self->{reset_option_codes_data} = 0;

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
    my ($self, $url_type) = @_;

    my @urls_to_process;

    if (defined $url_type) {
        push @urls_to_process, URL_ENDPOINTS if $url_type eq 'endpoints';
        push @urls_to_process, URL_OPTION_CODES if $url_type eq 'option_codes';
    }
    else {
        @urls_to_process = (ENDPOINTS_FILE, OPTION_CODES_FILE);
    }

    for my $data_url (@urls_to_process) {
        my $filename;

        if ($data_url =~ /.*\/(\w+\.json)$/) {
            $filename = $1;
        }

        if (! defined $filename) {
            croak "Couldn't extract the filename from '$data_url'";
        }

        (my $data_method = $filename) =~ s/\.json//;

        my $url = $self->uri($data_url);

        my $request = HTTP::Request->new('GET', $url,);

        my ($success, $code, $response_data) = $self->_tesla_api_call($request);
        my $new_data = decode_json($response_data);
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
        }

        if ($data_differs) {

            my $file = $filename =~ /endpoints/
                ? ENDPOINTS_FILE
                : OPTION_CODES_FILE ;

            if ($filename =~ /endpoints/) {
                $self->{reset_endpoints_data} = 1;
            }
            else {
                $self->{reset_option_codes_data} = 1;
            }

            # Make a backup copy

            my $backup = "$file." . time;
            copy($file, $backup) or die "Can't create $file backup file!: $!";

            chmod 0644, $file;

            open my $fh, '>', "$file"
                or die "Can't open '$file' for writing: $!";

            print $fh JSON->new->pretty->encode($new_data);
        }
    }
}
sub uri {
    my ($self, $url) = @_;

    if (! defined $url) {
        croak "The uri() method requires a URL string sent in";
    }

    return URI->new($url);
}
sub useragent_string {
    my ($self, $ua_string) = @_;

    if (defined $ua_string) {
        $self->{useragent_string} = $ua_string;
        $self->{mech_reset} = 1;
    }

    return $self->{useragent_string} // USERAGENT_STRING;
}
sub useragent_timeout {
    my ($self, $timeout) = @_;

    if (defined $timeout) {
        if ($timeout !~ /^\d+?(?:\.\d+)?$/) {
            croak "useragent_timeout() requires an integer or float";
        }
        $self->{useragent_timeout} = $timeout;
        $self->{mech_reset} = 1;
    }

    return $self->{useragent_timeout} // USERAGENT_TIMEOUT;
}
sub uuid {
    my ($self) = @_;

    if (! defined $self->{uuid}) {
        $self->{uuid} = UUID::uuid();
    }

    return $self->{uuid};
}
# Private methods

sub _access_token {
    # Returns the access token from the cache file or generates
    # that cache file (with token) if it isn't available

    my ($self) = @_;

    if (! -e $self->_authentication_cache_file) {
        $self->_access_token_generate;
    }

    if (! $self->_access_token_valid) {
        $self->_access_token_refresh;
    }

    $self->{access_token} = $self->_access_token_data->{access_token};

    return $self->{access_token};
}
sub _access_token_data {
    # Fetches and stores the access token data to the AUTH_CACHE_FILE

    my ($self, $data) = @_;

    $self->{cache_data} = $data if defined $data;

    return $self->{cache_data} if $self->{cache_data};

    {
        local $/;
        open my $fh, '<', $self->_authentication_cache_file or die
            "Can't open Tesla cache file " .
            $self->_authentication_cache_file .
            ": $!";

        my $json = <$fh>;
        $self->{cache_data} = decode_json($json);
    }

    return $self->{cache_data};
}
sub _access_token_generate {
    # Generates an access token and stores it in the cache file

    my ($self) = @_;

    my $auth_code = $self->_authentication_code;

    my $url = $self->uri(URL_TOKEN);
    my $header = ['Content-Type' => 'application/json; charset=UTF-8'];

    my $request_data = {
        grant_type    => "authorization_code",
        client_id     => "ownerapi",
        code          => $auth_code,
        code_verifier => $self->_authentication_code_verifier,
        redirect_uri  => "https://auth.tesla.com/void/callback",
    };

    my $request = HTTP::Request->new(
        'POST',
        $url,
        $header,
        JSON->new->allow_nonref->encode($request_data)
    );

    my ($success, $code, $response_data)= $self->_tesla_api_call($request);

    my $token_data = decode_json($response_data);

    $token_data = $self->_access_token_set_expiry($token_data);
    $self->_access_token_update($token_data);

    return $token_data;
}
sub _access_token_valid {
    # Checks the validity of an existing token

    my ($self) = @_;

    my $token_expires_at = $self->_access_token_data->{expires_at};

    my $valid = 0;

    if (time + TOKEN_EXPIRY_WINDOW < $token_expires_at) {
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

    my $url = $self->uri(URL_TOKEN);
    my $header = ['Content-Type' => 'application/json; charset=UTF-8'];

    my $refresh_token = $self->_access_token_data->{refresh_token};

    my $request_data = {
        grant_type    => 'refresh_token',
        refresh_token => $refresh_token,
        client_id     => 'ownerapi',
    };

    my $request = HTTP::Request->new(
        'POST',
        $url,
        $header,
        JSON->new->allow_nonref->encode($request_data)
    );

    my ($success, $code, $response_data) = $self->_tesla_api_call($request);

    # Extract the token data
    my $token_data = decode_json($response_data);

    # Re-add the existing refresh token; its still valid
    $token_data->{refresh_token} = $refresh_token;

    # Set the expiry time
    $token_data = $self->_access_token_set_expiry($token_data);

    # Update the cached token
    $self->_access_token_update($token_data);
}
sub _access_token_update {
    # Writes the new or updated token to the cache file

    my ($self, $token_data) = @_;

    if (! defined $token_data || ref($token_data) ne 'HASH') {
        croak "_access_token_update() needs a hash reference of token data";
    }

    $self->_access_token_data($token_data);

    open my $fh, '>', $self->_authentication_cache_file or die $!;

    print $fh JSON->new->allow_nonref->encode($token_data);
}
sub _api_attempts {
    # Stores and returns the number of attempts of each API call to Tesla

    my ($self, $add) = @_;

    if (defined $add) {
        if ($add) {
            $self->{api_attempts}++;
        }
        else {
            $self->{api_attempts} = 0;
        }
    }

    return $self->{api_attempts} || 0;
}
sub _api_cache {
    # Stores the Tesla API fetched data
    my ($self, %params) = @_;

    my $endpoint = $params{endpoint};
    my $id = $params{id} // 0;
    my $data = $params{data};

    if (! $endpoint) {
        croak "_api_cache() requires an endpoint name sent in";
    }

    if ($data) {
        $api_cache{$self->uuid}->{$endpoint}{$id}{data} = $data;
        $api_cache{$self->uuid}->{$endpoint}{$id}{time} = time;
    }

    return $api_cache{$self->uuid}->{$endpoint}{$id};
}
sub _api_cache_data {
    # Returns the entire API cache (for testing)

    my ($self) = @_;
    return %{ $api_cache{$self->uuid} };
}
sub _authentication_cache_file {
    my ($self, $filename) = @_;

    if (defined $filename) {
        $self->{authentication_cache_file} = $filename;
    }

    return $self->{authentication_cache_file} || AUTH_CACHE_FILE;
}
sub _authentication_code {
    # If an access token is unavailable, prompt the user with a URL to
    # authenticate to Tesla, and have them paste in the resulting URL
    # We then extract and return the access code to generate the access
    # token

    my ($self) = @_;

    return $self->{authentication_code} if $self->{authentication_code};

    my $auth_url = $self->_authentication_code_url;

    # If we're in testing mode, we don't want to be waiting for
    # a read from STDIN

    my $code_url;

    if ($ENV{TESLA_API_TESTING}) {
        $code_url = $ENV{TESLA_API_TESTING_CODE_URL};
    }
    else {
        print "\n$auth_url\n";
        print "\nPaste URL here: ";
        $code_url = <STDIN>;
    }

    chomp $code_url;

    my $code = $self->_authentication_code_extract($code_url);

    $self->{authentication_code} = $code;

    return $code;
}
sub _authentication_code_extract {
    # Pull in the pasted URL with the code, extract the code,
    # and return it

    my ($self, $code_url) = @_;

    my $code;

    if ($code_url =~ /code=(.*?)\&/) {
        $code = $1;
    }
    else {
        croak "Could not extract the authorization code from the URL";
    }

    return $code;
}
sub _authentication_code_url {
    # Generate Tesla's authentication URL

    my ($self) = @_;
    my $auth_url = $self->uri(URL_AUTH);

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
        "\nPlease follow the URL displayed below in your browser and log into Tesla, " .
        "then paste the URL from the resulting 'Page Not Found' page's address bar, " .
        "then hit ENTER:\n";

    return $auth_url;
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
sub _decode {
    # Decode JSON to Perl
    my ($self, $json) = @_;
    my $perl = decode_json($json);
    return $perl;
}
sub _random_string {
    # Returns a proper length alpha-num string for Tesla API token code
    # verification key

    my @chars = ('A' .. 'Z', 'a' .. 'z', 0 .. 9);
    my $rand_string;
    $rand_string .= $chars[rand @chars] for 1 .. 85;
    return $rand_string;
}
sub _tesla_api_call {
    # Responsible for all calls to the Tesla API

    my ($self, $request) = @_;

    $self->_api_attempts(0);

    my $response;

    for (1 .. API_TIMEOUT_RETRIES) {
        $response = $self->mech->request($request);

        $self->_api_attempts(1);

        if ($response->is_success) {
            last;
        }
    }

    my $success = $response->is_success;
    my $code = $response->code;
    my $decoded_content = $response->decoded_content;

    if (! $response->is_success) {
        my $error_msg = $response->status_line;

        my $error_string = "Error - Tesla API said: '$error_msg'";
        warn $error_string;

        $decoded_content = "{\"error\" : \"$error_msg\"}";
    }

    return ($success, $code, $decoded_content);
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

=head1 DESCRIPTION

This distribution provides access to the Tesla API.

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
C<tesla_auth_cache.json> file in your home directory, and use it on all
subsequent accesses.

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
found in the C<share/endpoints.json> file for the time being.

    id

I<Optional, Integer>: Some endpoints require an ID sent in (eg. vehicle ID,
Powerwall ID etc).

    api_params

I<Optional, Hash Reference>: Some API calls require additional parameters. Send
in a hash reference where the keys are the API parameter name, and the value is,
well, the value.

I<Return>: Hash or array reference, depending on the endpoint. If an error
occurs while communicating with the Tesla API, we'll send back a hash reference
containing C<< error => 'Tesla error message' >>.

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

=head2 option_codes

B<NOTE>: I'm unsure if the option codes are vehicle specific, or general for
all Tesla products, so I'm leaving this method here for now.

Returns a hash reference of 'option code' => 'description' pairs.

=head2 update_data_files($type)

Checks to see if there are any updates to the C<endpoints.json> or
C<option_codes.json> files online, and updates them locally.

Parameters:

    $type

I<Optional, String>: One of B<endpoints> or B<option_codes>. If set, we'll
operate on only that file.

I<Return>: None. C<croak()>s on faiure.

=head2 uri($url)

Parameters:

    $url

I<Mandatory, String>: The URL to instantiate the object with.

Instantiates and returns a new L</URI> object ready to be used.

=head2 useragent_string($ua_string)

Sets/gets the useragent string we send to the Tesla API.

I<Optional, String>: The user agent browser string to send to the Tesla API.

I<Return>: String, the currently set value.

=head2 useragent_timeout($timeout)

Sets/gets the timeout we use in the L<WWW::Mechanize|/mech> object that we
communicate to the Tesla API with.

Parameters:

    $timeout

I<Optional, Integer/Float>: The timeout in seconds or fractions of a second.

I<Return>: Integer/Float, the currently set value.

=head2 uuid

Each L</Tesla::API> object is identified internally by a unique identifier
string. This method returns it for you.

Example:

    5A7C01A5-0C47-4815-8B33-9AE3A475FF01

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

Each L<Tesla::API> object you instantiate has its own cache storage.
Modifications to the cache or any cache attributes or parameters will not
affect the caching of other objects whether they be created in the same or a
different process/script. The cache is kept separate by using the stored UUID
of each object.

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

=head1 CONFIGURATION VARIABLES

Most configuration options used in this software are defined as constants in the
library file. Some are defaults that can be overridden via method calls, others
are only modifiable by updating the actual value in the file.

=head2 DEBUG_CACHE

Prints to C<STDOUT> debugging output from the caching mechanism.

I<Override>: C<$ENV{DEBUG_TESLA_API_CACHE}>. Note that this must be configured
within a C<BEGIN> block, prior to the C<use Tesla::API> line for it to have
effect.

=head2 API_CACHE_PERSIST

Always/never use the cache once data has been retrieved through the Tesla API.

I<Default>: False (C<0>).

I<Override>: None

=head2 API_CACHE_TIMEOUT_SECONDS

How many seconds to reuse the cached data retrieved from the Tesla API.

I<Default>: C<2>

I<Override>: L</api_cache_time($cache_seconds)>

=head2 API_CACHE_RETRIES

How many times we'll try a Tesla API call in the event of a failure.

I<Default>: C<3>

I<Override>: None

=head2 AUTH_CACHE_FILE

The path and filename of the file we'll store the Tesla API access token
information.

I<Default>: C<$home_dir/tesla_api_cache.json>

I<Override>: C<_authentication_cache_file()>, used primarily for unit testing.

=head2 ENDPOINTS_FILE

The path and filename of the file we'll store the Tesla API endpoint description
file.

I<Default>: C<dist_file('Tesla-API', 'endpoints.json')>

I<Override>: C<$ENV{TESLA_API_ENDPOINTS_FILE}>. Note that this must be
configured within a C<BEGIN> block, prior to the C<use Tesla::API> line for it
to have effect.

=head2 OPTION_CODES_FILE

The path and filename of the file we'll store the product option code list file
for Tesla products.

I<Default>: C<dist_file('Tesla-API', 'option_codes.json')>

I<Override>: C<$ENV{TESLA_API_OPTIONCODES_FILE}>. Note that this must be
configured within a C<BEGIN> block, prior to the C<use Tesla::API> line for it
to have effect.

=head2 TOKEN_EXPIRY_WINDOW

The number of seconds we'll add to the current time when validating the token
expiry. This is effectively a cusion window so that the token has at least this
many seconds before expiring to ensure the next call won't use an invalidated
token

I<Default>: C<5>

I<Override>: None

=head2 URI_API

The URL we use to communicate with the Tesla API for data retrieval operations.

I<Default>: C<https://owner-api.teslamotors.com/>

I<Override>: None

=head2 URI_ENDPOINTS

The URL we use to retrieve the updated Tesla API endpoints file.

I<Default>: C<https://raw.githubusercontent.com/tdorssers/TeslaPy/master/teslapy/endpoints.json>

I<Override>: None

=head2 URI_OPTION_CODES

The URL we use to retrieve the updated Tesla API product option codes file.

I<Default>: C<https://raw.githubusercontent.com/tdorssers/TeslaPy/master/teslapy/option_codes.json>

I<Override>: None

=head2 URI_AUTH

The URL we use to perform the Tesla API authentication routines.

I<Default>: C<https://auth.tesla.com/oauth2/v3/authorize>

I<Override>: None

=head2 URI_TOKEN

The URL we use to fetch and update the Tesla API access tokens.

I<Default>: C<https://auth.tesla.com/oauth2/v3/token>

I<Override>: None

=head2 USERAGENT_STRING

String used to identify the 'browser' we're using to access the Tesla API.

I<Default>: C<Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:98.0) Gecko/20100101 Firefox/98.0>

I<Override>: L</useragent_string($ua_string)>

=head2 USERAGENT_TIMEOUT

Number of seconds before we classify a call to the Tesla API as timed out.

I<Default>: C<180>

I<Override>: L</useragent_timeout($timeout)>

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
