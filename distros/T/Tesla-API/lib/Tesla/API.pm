package Tesla::API;

use warnings;
use strict;

use Carp qw(croak confess);
use Data::Dumper;
use Digest::SHA qw(sha256_hex);
use File::HomeDir;
use HTTP::Request;
use JSON;
use MIME::Base64 qw(encode_base64url);
use WWW::Mechanize;
use URI;

our $VERSION = '0.01';

my $home_dir;

BEGIN {
    $home_dir = File::HomeDir->my_home;
}

use constant {
    CACHE_FILE  => "$home_dir/tesla_api_cache.json",
    AUTH_URL    => 'https://auth.tesla.com/oauth2/v3/authorize',
    TOKEN_URL   => 'https://auth.tesla.com/oauth2/v3/token',
    API_URL     => 'https://owner-api.teslamotors.com/',
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

    $self->mech;
    $self->_access_token;

    $self->my_vehicle_id($params{vehicle_id});

    return $self;
}
sub api {
    my ($self, $endpoint_name, $id) = @_;

    if (! defined $endpoint_name) {
        croak "Tesla::API::api() requires an endpoint name sent in";
    }

    my $endpoint = $self->endpoints($endpoint_name);

    my $type = $endpoint->{TYPE};
    my $auth = $endpoint->{AUTH};
    my $uri = $endpoint->{URI};

    if ($uri =~ /\{/) {
        if (! defined $id) {
            croak "Endpoint $endpoint_name requires an \$id, but none sent in";
        }
        $uri =~ s/\{.*?\}/$id/;
    }

    my $url = URI->new(API_URL . $uri);

    my $request;

    if ($auth) {
        my $token_string = "Bearer " . $self->_access_token;
        my $header = ['Authorization' => $token_string];
        $request = HTTP::Request->new($type, $url, $header);
    }
    else {
        $request = HTTP::Request->new($type, $url);
    }

    my $response = $self->mech->request($request);

    if ($response->is_success) {
        return _decode($response->decoded_content)->{response};
    }
    else {
        warn $response->status_line;
    }
}
sub data {
    my ($self) = @_;
    return $self->{data};
}
sub endpoints {
    my ($self, $endpoint) = @_;

    if (! $self->{endpoints}) {
        my $json_endpoints;
        {
            local $/;
            $json_endpoints = <DATA>;
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
sub my_vehicle_id {
    my ($self, $id) = @_;

    if (defined $id) {
        $self->{data}{vehicle_id} = $id;
    }
    else {
        my @vehicle_ids = keys %{$self->my_vehicles};

        if (scalar @vehicle_ids == 1) {
            $self->{data}{vehicle_id} = $vehicle_ids[0];
        }
    }

    return $self->{data}{vehicle_id} || -1;
}
sub my_vehicle_name {
    my ($self) = @_;

    if (! $self->my_vehicle_id) {
        warn "You haven't set a vehicle ID yet";
    }

    return $self->my_vehicles->{$self->my_vehicle_id};
}
sub my_vehicles {
    my ($self) = @_;

    return $self->{vehicles} if $self->{vehicles};

    my $vehicles = $self->api('VEHICLE_LIST');

    for (@$vehicles) {
        $self->{data}{vehicles}{$_->{id}} = $_->{display_name};
    }

    return $self->{data}{vehicles};
}

# Public Tesla API methods

sub vehicle_data {
    my ($self, $id) = @_;
    return $self->api('VEHICLE_DATA', $self->_id($id));
}
sub wake {
    my ($self, $id) = @_;
    return $self->api('VEHICLE_DATA', $self->_id($id));
}

# Private methods

sub _access_token {
    # Returns the access token from the cache file or generates
    # that cache file (with token) if it isn't available

    my ($self) = @_;

    return $self->{access_token} if $self->{access_token};

    if (! -e CACHE_FILE) {
        my $auth_code = $self->_authentication_code;
        $self->_access_token_generate($auth_code);
    }
    else {
        $self->{access_token} = $self->_access_token_fetch;
    }
}
sub _access_token_fetch {
    # Fetches the access token from the cache file

    my ($self) = @_;

    my $cache_data;
    {
        open my $fh, '<', CACHE_FILE or croak "Can't open Tesla cache file " . CACHE_FILE . ": $!";
        my $json = <$fh>;
        $cache_data = decode_json($json);
    }

    my $access_token = $cache_data->{access_token};

    return $access_token;
}
sub _access_token_generate {
    # Generates an access token and stores it in the cache file

    my ($self, $auth_code) = @_;

    if (! defined $auth_code) {
        croak "_access_token_generate() requires an \$auth_code parameter";
    }

    my $url = URI->new(TOKEN_URL);
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
        open my $fh, '>', CACHE_FILE or die $!;
        print $response->decoded_content;
        print $fh $response->decoded_content;

        my $response_data = decode_json($response->decoded_content);

        return $response_data;
    }
    else {
        croak $self->mech->response->status_line;
    }
}
sub _authentication_code {
    # If an access token is unavailable, prompt the user with a URL to
    # authenticate to Tesla, and have them paste in the resulting URL
    # We then extract and return the access code to generate the access
    # token

    my ($self) = @_;
    my $auth_url = URI->new(AUTH_URL);

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
        qq~
            Please follow the URL displayed below in your browser and log into Tesla,
            then paste the URL from the resulting "Page Not Found" page's address bar,
            then hit ENTER:\n";
        ~;

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

    print "$code\n";
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
sub _id {
    # Tries to figure out the ID to use in API calls

    my ($self, $id) = @_;

    if (! defined $id) {
        $id = $self->my_vehicle_id;
    }

    if (! $id) {
        croak "vehicle_data() requires an \$id sent in";
    }

    return $id;
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

    my $vehicles = $tesla->my_vehicles;

    my $vehicle_name = $tesla->vehicle_name;

    my @endpoint_names = keys %{ $tesla->endpoints };

    # Using the internal api() until the complete interface
    # of this distribution is done

    my $endpoint_name = 'VEHICLE_DATA';

    my $car_data = $tesla->api($endpoint_name, $tesla->vehicle_id);

=head1 DESCRIPTION

This distribution provides access to the Tesla API.

B<WARNING>: This is an initial, beta release. Barely any functionality has
been implemented, and the authentication mechanism needs a lot of polishing.

It's currently in its infancy, so the interface may^H^H^Hwill change. Although
there are very few public access methods available yet, all current and future
ones behave the exact same way, by using the object's C<api()> method with an
endpoint name.

Some endpoints require an ID sent in, so it must be provided for those calls as
well.

B<< NOTE >>: The 'wake' function has not yet been fully impemented, so if a
Tesla API call times out, its likely you'll have to use the official Tesla
App to wake the car up.

=head1 METHODS

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

Parameters:

All parameters are to be sent in the form of a hash.

    unauthenticated

Optional, Bool: Set to true to bypass the access token generation.

Default: False.

    vehicle_id

Optional, Integer: If sent in, we'll use this ID for all calls to endpoints
that require one.

If not sent in, we'll check how many vehicles you own under your account, and
if there's only one, we'll use that ID instead.

If you have more than one Tesla vehicle registered and you don't supply this
parameter, you will have to supply the ID to each method call that requires it,
or set it in C<vehicle_id($id)> after instantiation.

Default: C<undef>

=head2 api($endpoint, $id)

Responsible for disseminating the endpoints and retrieving data through the
Tesla API.

Parameters:

    $endpoint

Mandatory, String: A valid Tesla API endpoint name. The entire list can be
found in the C<t/test_data/endpoints.json> file for the time being.

    $id

Optional, Integer: Some endpoints require an ID sent in (eg. vehicle ID,
powerwall ID etc).

Return: Hash or array reference, depending on the endpoint.

=head2 data

Returns a hash reference of the data we've collected for you and stashed
within the object. This does not reflect the entire object.

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

Returns the L<WWW::Mechanze> object we've instantiated internally.

=head2 my_vehicle_id($id)

Sets/gets your primary vehicle ID. If set, we will use this in all API calls
that require it.

Parameters:

    $id

Optional, Integer: The vehicle ID you want to use in all API calls that require
one, as opposed to sending it into every separate call.

If you only have a single Tesla vehicle registered under your account, we will
set C<my_vehicle_id()> to that ID when you instantiate the object.

You can also have this auto-populated in C<new()> by sending it in with the
C<< vehicle_id => $id >> parameter.

=head2 my_vehicle_name

Returns the name you associated with your vehicle under your Tesla account.

L</my_vehicle_id($id)> must have already been set.

=head2 my_vehicles

Returns a hash reference of your listed vehicles. The key is the vehicle ID,
and the value is the name you've assigned to that vehicle.

Example:

    {
        1234567891011 => 'Dream Machine',
        1234567891012 => 'Model S',
    }

=head2 vehicle_data($id)

Returns a hash reference containing state data of a vehicle.

C<croak()>s if an ID isn't sent in and we can't sort one out automatically.

=head2 wake($id)

NOT YET IMPLEMENTED FULLY.

=head2 EXAMPLE USAGE

    use Data::Dumper;
    use Tesla::API;
    use feature 'say';

    my $tesla = Tesla::API->new;

    say $tesla->my_vehicle_name;

    print Dumper $tesla->vehicle_data;

Output (massively and significantly snipped for brevity):

    Dream machine

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

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

__DATA__
{
  "STATUS": {
    "TYPE": "GET",
    "URI": "status",
    "AUTH": false
  },
  "PRODUCT_LIST": {
    "TYPE": "GET",
    "URI": "api/1/products",
    "AUTH": true
  },
  "VEHICLE_LIST": {
    "TYPE": "GET",
    "URI": "api/1/vehicles",
    "AUTH": true
  },
  "VEHICLE_ORDER_LIST": {
    "TYPE": "GET",
    "URI": "api/1/users/orders",
    "AUTH": true
  },
  "VEHICLE_SUMMARY": {
    "TYPE": "GET",
    "URI": "api/1/vehicles/{vehicle_id}",
    "AUTH": true
  },
  "VEHICLE_DATA_LEGACY": {
    "TYPE": "GET",
    "URI": "api/1/vehicles/{vehicle_id}/data",
    "AUTH": true
  },
  "VEHICLE_DATA": {
    "TYPE": "GET",
    "URI": "api/1/vehicles/{vehicle_id}/vehicle_data",
    "AUTH": true
  },
  "VEHICLE_SERVICE_DATA": {
    "TYPE": "GET",
    "URI": "api/1/vehicles/{vehicle_id}/service_data",
    "AUTH": true
  },
  "NEARBY_CHARGING_SITES": {
    "TYPE": "GET",
    "URI": "api/1/vehicles/{vehicle_id}/nearby_charging_sites",
    "AUTH": true
  },
  "WAKE_UP": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/wake_up",
    "AUTH": true
  },
  "UNLOCK": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/door_unlock",
    "AUTH": true
  },
  "LOCK": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/door_lock",
    "AUTH": true
  },
  "HONK_HORN": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/honk_horn",
    "AUTH": true
  },
  "FLASH_LIGHTS": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/flash_lights",
    "AUTH": true
  },
  "CLIMATE_ON": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/auto_conditioning_start",
    "AUTH": true
  },
  "CLIMATE_OFF": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/auto_conditioning_stop",
    "AUTH": true
  },
  "MAX_DEFROST": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_preconditioning_max",
    "AUTH": true
  },
  "CHANGE_CLIMATE_TEMPERATURE_SETTING": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_temps",
    "AUTH": true
  },
  "SET_CLIMATE_KEEPER_MODE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_climate_keeper_mode",
    "AUTH": true
  },
  "HVAC_BIOWEAPON_MODE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_bioweapon_mode",
    "AUTH": true
  },
  "SCHEDULED_DEPARTURE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_scheduled_departure",
    "AUTH": true
  },
  "SCHEDULED_CHARGING": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_scheduled_charging",
    "AUTH": true
  },
  "CHARGING_AMPS": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_charging_amps",
    "AUTH": true
  },
  "SET_CABIN_OVERHEAT_PROTECTION": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_cabin_overheat_protection",
    "AUTH": true
  },
  "CHANGE_CHARGE_LIMIT": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_charge_limit",
    "AUTH": true
  },
  "SET_VEHICLE_NAME": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_vehicle_name",
    "AUTH": true
  },
  "CHANGE_CHARGE_MAX": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/charge_max_range",
    "AUTH": true
  },
  "CHANGE_CHARGE_STANDARD": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/charge_standard",
    "AUTH": true
  },
  "CHANGE_SUNROOF_STATE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/sun_roof_control",
    "AUTH": true
  },
  "WINDOW_CONTROL": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/window_control",
    "AUTH": true
  },
  "ACTUATE_TRUNK": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/actuate_trunk",
    "AUTH": true
  },
  "REMOTE_START": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/remote_start_drive",
    "AUTH": true
  },
  "TRIGGER_HOMELINK": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/trigger_homelink",
    "AUTH": true
  },
  "CHARGE_PORT_DOOR_OPEN": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/charge_port_door_open",
    "AUTH": true
  },
  "CHARGE_PORT_DOOR_CLOSE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/charge_port_door_close",
    "AUTH": true
  },
  "START_CHARGE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/charge_start",
    "AUTH": true
  },
  "STOP_CHARGE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/charge_stop",
    "AUTH": true
  },
  "MEDIA_TOGGLE_PLAYBACK": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/media_toggle_playback",
    "AUTH": true
  },
  "MEDIA_NEXT_TRACK": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/media_next_track",
    "AUTH": true
  },
  "MEDIA_PREVIOUS_TRACK": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/media_prev_track",
    "AUTH": true
  },
  "MEDIA_NEXT_FAVORITE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/media_next_fav",
    "AUTH": true
  },
  "MEDIA_PREVIOUS_FAVORITE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/media_prev_fav",
    "AUTH": true
  },
  "MEDIA_VOLUME_UP": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/media_volume_up",
    "AUTH": true
  },
  "MEDIA_VOLUME_DOWN": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/media_volume_down",
    "AUTH": true
  },
  "SPLUNK_TELEMETRY": {
    "TYPE": "POST",
    "URI": "api/1/logs",
    "AUTH": true
  },
  "APP_FEEDBACK_ENTITLEMENTS": {
    "TYPE": "GET",
    "URI": "api/1/diagnostics",
    "AUTH": true
  },
  "APP_FEEDBACK_LOGS": {
    "TYPE": "POST",
    "URI": "api/1/reports",
    "AUTH": true
  },
  "APP_FEEDBACK_METADATA": {
    "TYPE": "POST",
    "URI": "api/1/diagnostics",
    "AUTH": true
  },
  "RETRIEVE_NOTIFICATION_PREFERENCES": {
    "TYPE": "GET",
    "URI": "api/1/notification_preferences",
    "AUTH": true
  },
  "SEND_NOTIFICATION_PREFERENCES": {
    "TYPE": "POST",
    "URI": "api/1/notification_preferences",
    "AUTH": true
  },
  "RETRIEVE_NOTIFICATION_SUBSCRIPTIONS": {
    "TYPE": "GET",
    "URI": "api/1/subscriptions",
    "AUTH": true
  },
  "SEND_NOTIFICATION_SUBSCRIPTIONS": {
    "TYPE": "POST",
    "URI": "api/1/subscriptions",
    "AUTH": true
  },
  "DEACTIVATE_DEVICE_TOKEN": {
    "TYPE": "POST",
    "URI": "api/1/device/{device_token}/deactivate",
    "AUTH": true
  },
  "CALENDAR_SYNC": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/upcoming_calendar_entries",
    "AUTH": true
  },
  "SET_VALET_MODE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_valet_mode",
    "AUTH": true
  },
  "RESET_VALET_PIN": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/reset_valet_pin",
    "AUTH": true
  },
  "SPEED_LIMIT_ACTIVATE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/speed_limit_activate",
    "AUTH": true
  },
  "SPEED_LIMIT_DEACTIVATE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/speed_limit_deactivate",
    "AUTH": true
  },
  "SPEED_LIMIT_SET_LIMIT": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/speed_limit_set_limit",
    "AUTH": true
  },
  "SPEED_LIMIT_CLEAR_PIN": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/speed_limit_clear_pin",
    "AUTH": true
  },
  "SCHEDULE_SOFTWARE_UPDATE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/schedule_software_update",
    "AUTH": true
  },
  "CANCEL_SOFTWARE_UPDATE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/cancel_software_update",
    "AUTH": true
  },
  "SET_SENTRY_MODE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/set_sentry_mode",
    "AUTH": true
  },
  "POWERWALL_ORDER_SESSION_DATA": {
    "TYPE": "GET",
    "URI": "api/1/users/powerwall_order_entry_data",
    "AUTH": true
  },
  "POWERWALL_ORDER_PAGE": {
    "TYPE": "GET",
    "URI": "powerwall_order_page",
    "AUTH": true,
    "CONTENT": "HTML"
  },
  "ONBOARDING_EXPERIENCE": {
    "TYPE": "GET",
    "URI": "api/1/users/onboarding_data",
    "AUTH": true
  },
  "ONBOARDING_EXPERIENCE_PAGE": {
    "TYPE": "GET",
    "URI": "onboarding_page",
    "AUTH": true,
    "CONTENT": "HTML"
  },
  "GET_UPCOMING_SERVICE_VISIT_DATA": {
    "TYPE": "GET",
    "URI": "api/1/users/service_scheduling_data",
    "AUTH": true
  },
  "GET_OWNERSHIP_XP_CONFIG": {
    "TYPE": "GET",
    "URI": "api/1/users/app_config",
    "AUTH": true
  },
  "REFERRAL_DATA": {
    "TYPE": "GET",
    "URI": "api/1/users/referral_data",
    "AUTH": true
  },
  "REFERRAL_PAGE": {
    "TYPE": "GET",
    "URI": "referral_page",
    "AUTH": true,
    "CONTENT": "HTML"
  },
  "ROADSIDE_ASSISTANCE_DATA": {
    "TYPE": "GET",
    "URI": "api/1/users/roadside_assistance_data",
    "AUTH": true
  },
  "ROADSIDE_ASSISTANCE_PAGE": {
    "TYPE": "GET",
    "URI": "roadside_assistance_page",
    "AUTH": true,
    "CONTENT": "HTML"
  },
  "UPGRADE_ELIGIBILITY": {
    "TYPE": "GET",
    "URI": "api/1/vehicles/{vehicle_id}/eligible_upgrades",
    "AUTH": true
  },
  "UPGRADES_PAGE": {
    "TYPE": "GET",
    "URI": "upgrades_page",
    "AUTH": true,
    "CONTENT": "HTML"
  },
  "MESSAGE_CENTER_MESSAGE_COUNT": {
    "TYPE": "GET",
    "URI": "api/1/messages/count",
    "AUTH": true
  },
  "MESSAGE_CENTER_MESSAGE_LIST": {
    "TYPE": "GET",
    "URI": "api/1/messages",
    "AUTH": true
  },
  "MESSAGE_CENTER_MESSAGE": {
    "TYPE": "GET",
    "URI": "api/1/messages/{message_id}",
    "AUTH": true
  },
  "MESSAGE_CENTER_COUNTS": {
    "TYPE": "GET",
    "URI": "api/1/messages/count",
    "AUTH": true
  },
  "MESSAGE_CENTER_MESSAGE_ACTION_UPDATE": {
    "TYPE": "POST",
    "URI": "api/1/messages/{message_id}/actions",
    "AUTH": true
  },
  "MESSAGE_CENTER_CTA_PAGE": {
    "TYPE": "GET",
    "URI": "messages_cta_page",
    "AUTH": true,
    "CONTENT": "HTML"
  },
  "SEND_DEVICE_KEY": {
    "TYPE": "POST",
    "URI": "api/1/users/keys",
    "AUTH": true
  },
  "BATTERY_SUMMARY": {
    "TYPE": "GET",
    "URI": "api/1/powerwalls/{battery_id}/status",
    "AUTH": true
  },
  "BATTERY_DATA": {
    "TYPE": "GET",
    "URI": "api/1/powerwalls/{battery_id}",
    "AUTH": true
  },
  "BATTERY_POWER_TIMESERIES_DATA": {
    "TYPE": "GET",
    "URI": "api/1/powerwalls/{battery_id}/powerhistory",
    "AUTH": true
  },
  "BATTERY_ENERGY_TIMESERIES_DATA": {
    "TYPE": "GET",
    "URI": "api/1/powerwalls/{battery_id}/energyhistory",
    "AUTH": true
  },
  "BATTERY_BACKUP_RESERVE": {
    "TYPE": "POST",
    "URI": "api/1/powerwalls/{battery_id}/backup",
    "AUTH": true
  },
  "BATTERY_SITE_NAME": {
    "TYPE": "POST",
    "URI": "api/1/powerwalls/{battery_id}/site_name",
    "AUTH": true
  },
  "BATTERY_OPERATION_MODE": {
    "TYPE": "POST",
    "URI": "api/1/powerwalls/{battery_id}/operation",
    "AUTH": true
  },
  "SITE_SUMMARY": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/site_status",
    "AUTH": true
  },
  "SITE_DATA": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/live_status",
    "AUTH": true
  },
  "SITE_CONFIG": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/site_info",
    "AUTH": true
  },
  "RATE_TARIFFS": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/rate_tariffs",
    "AUTH": true
  },
  "SITE_TARIFFS": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/tariff_rates",
    "AUTH": true
  },
  "SITE_TARIFF": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/tariff_rate",
    "AUTH": true
  },
  "HISTORY_DATA": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/history",
    "AUTH": true
  },
  "CALENDAR_HISTORY_DATA": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/calendar_history",
    "AUTH": true
  },
  "SOLAR_SAVINGS_FORECAST": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/savings_forecast",
    "AUTH": true
  },
  "ENERGY_SITE_BACKUP_TIME_REMAINING": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/backup_time_remaining",
    "AUTH": true
  },
  "ENERGY_SITE_PROGRAMS": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/programs",
    "AUTH": true
  },
  "ENERGY_SITE_TELEMETRY_HISTORY": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/{site_id}/telemetry_history",
    "AUTH": true
  },
  "BACKUP_RESERVE": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/{site_id}/backup",
    "AUTH": true
  },
  "OFF_GRID_VEHICLE_CHARGING_RESERVE": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/{site_id}/off_grid_vehicle_charging_reserve",
    "AUTH": true
  },
  "SITE_NAME": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/{site_id}/site_name",
    "AUTH": true
  },
  "OPERATION_MODE": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/{site_id}/operation",
    "AUTH": true
  },
  "TIME_OF_USE_SETTINGS": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/{site_id}/time_of_use_settings",
    "AUTH": true
  },
  "STORM_MODE_SETTINGS": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/{site_id}/storm_mode",
    "AUTH": true
  },
  "ENERGY_SITE_COMMAND": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/{site_id}/command",
    "AUTH": true
  },
  "ENERGY_SITE_ENROLL_PROGRAM": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/{site_id}/program",
    "AUTH": true
  },
  "ENERGY_SITE_OPT_EVENT": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/{site_id}/event",
    "AUTH": true
  },
  "ENERGY_SITE_PREFERENCE": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/{site_id}/preference",
    "AUTH": true
  },
  "CHECK_ENERGY_PRODUCT_REGISTRATION": {
    "TYPE": "GET",
    "URI": "api/1/energy_sites/registered",
    "AUTH": true
  },
  "ENERGY_EVENT": {
    "TYPE": "POST",
    "URI": "api/1/energy_sites/energy_event",
    "AUTH": true
  },
  "VEHICLE_CHARGE_HISTORY": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/charge_history",
    "AUTH": true
  },
  "SEND_NOTIFICATION_CONFIRMATION": {
    "TYPE": "POST",
    "URI": "api/1/notification_confirmations",
    "AUTH": true
  },
  "SEND_TO_VEHICLE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/share",
    "AUTH": true
  },
  "SEND_SC_TO_VEHICLE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/navigation_sc_request",
    "AUTH": true
  },
  "SEND_GPS_TO_VEHICLE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/navigation_gps_request",
    "AUTH": true
  },
  "REMOTE_SEAT_HEATER_REQUEST": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/remote_seat_heater_request",
    "AUTH": true
  },
  "REMOTE_STEERING_WHEEL_HEATER_REQUEST": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/remote_steering_wheel_heater_request",
    "AUTH": true
  },
  "TRIGGER_VEHICLE_SCREENSHOT": {
    "TYPE": "GET",
    "URI": "api/1/vehicles/{vehicle_id}/screenshot",
    "AUTH": true
  },
  "HERMES_AUTHORIZATION": {
    "TYPE": "POST",
    "URI": "api/1/users/jwt/hermes",
    "AUTH": true
  },
  "HERMES_VEHICLE_AUTHORIZATION": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{id}/jwt/hermes",
    "AUTH": true
  },
  "STATIC_SUPERCHARGER_FILE": {
    "TYPE": "GET",
    "URI": "static/superchargers/{file_path}",
    "AUTH": true
  },
  "STATIC_CHARGER_FILE": {
    "TYPE": "GET",
    "URI": "static/chargers/{file_path}",
    "AUTH": true
  },
  "PLAN_TRIP": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/plan_trip",
    "AUTH": true
  },
  "PLACE_SUGGESTIONS": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/place_suggestions",
    "AUTH": true
  },
  "DRIVING_PLAN": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/driving_plan",
    "AUTH": true
  },
  "REVERSE_GEOCODING": {
    "TYPE": "GET",
    "URI": "maps/reverse_geocoding/v3/",
    "AUTH": true
  },
  "USER": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/user",
    "AUTH": true
  },
  "OWNERSHIP_TRANSLATIONS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/static/protected/translations/{path}",
    "AUTH": true
  },
  "ROADSIDE_INCIDENTS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/roadside/incidents",
    "AUTH": true
  },
  "ROADSIDE_CREATE_INCIDENT": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/roadside/incidents",
    "AUTH": true
  },
  "ROADSIDE_CANCEL_INCIDENT": {
    "TYPE": "PUT",
    "URI": "bff/v2/mobile-app/roadside/incidents/{incidentsId}",
    "AUTH": true
  },
  "ROADSIDE_WARRANTY": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/roadside/warranty",
    "AUTH": true
  },
  "ROADSIDE_LOCATIONS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/roadside/locations",
    "AUTH": true
  },
  "ROADSIDE_COUNTRIES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/roadside/countries",
    "AUTH": true
  },
  "SERVICE_GET_SERVICE_VISITS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/appointments",
    "AUTH": true
  },
  "SERVICE_UPDATE_APPOINTMENT": {
    "TYPE": "PUT",
    "URI": "bff/v2/mobile-app/service/appointments/{serviceVisitId}",
    "AUTH": true
  },
  "SERVICE_CANCEL_APPOINTMENT": {
    "TYPE": "PATCH",
    "URI": "mobile-app/service/appointments/{serviceVisitId}",
    "AUTH": true
  },
  "SERVICE_CREATE_ACTIVITIES": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/activities/{serviceVisitId}",
    "AUTH": true
  },
  "SERVICE_UPDATE_ACTIVITIES": {
    "TYPE": "PUT",
    "URI": "bff/v2/mobile-app/service/activities/{serviceVisitId}",
    "AUTH": true
  },
  "SERVICE_DELETE_ACTIVITIES": {
    "TYPE": "PATCH",
    "URI": "bff/v2/mobile-app/service/activities/{serviceVisitId}",
    "AUTH": true
  },
  "SERVICE_GET_SERVICE_APPOINTMENTS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/service-appointments",
    "AUTH": true
  },
  "SERVICE_CREATE_SERVICE_VISIT": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/appointments",
    "AUTH": true
  },
  "SERVICE_TRACKER_DETAILS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/tracker/{serviceVisitID}",
    "AUTH": true
  },
  "SERVICE_MOBILE_NEAREST_LOCATIONS": {
    "TYPE": "GET",
    "URI": "mobile-app/service/locations/mobile/nearest",
    "AUTH": true
  },
  "SERVICE_MOBILE_OPEN_SLOTS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/locations/mobile/slots",
    "AUTH": true
  },
  "SERVICE_CENTER_OPEN_SLOTS": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/locations/center/slots",
    "AUTH": true
  },
  "SERVICE_CENTER_IS_BODY_SHOP": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/locations/body-shop",
    "AUTH": true
  },
  "SERVICE_SAVE_CENTER_APPOINTMENT": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/center",
    "AUTH": true
  },
  "SERVICE_CREATE_MOBILE_APPOINTMENT": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/mobile",
    "AUTH": true
  },
  "SERVICE_UPDATE_MOBILE_APPOINTMENT": {
    "TYPE": "PATCH",
    "URI": "bff/v2/mobile-app/service/mobile/{appointmentId}",
    "AUTH": true
  },
  "SERVICE_SWITCH_TO_CENTER_APPOINTMENT": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/mobile/{appointmentId}/convert-to-center",
    "AUTH": true
  },
  "SERVICE_SWITCH_TO_MOBILE_APPOINTMENT": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/center/{appointmentId}/convert-to-mobile",
    "AUTH": true
  },
  "SERVICE_MOBILE_APPOINTMENT_DETAILS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/mobile/{appointmentId}",
    "AUTH": true
  },
  "SERVICE_CENTER_APPOINTMENT_DETAILS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/center/{appointmentId}",
    "AUTH": true
  },
  "SERVICE_HISTORY": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/history",
    "AUTH": true
  },
  "SERVICE_SURVEY_ELIGIBILITY": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/surveys",
    "AUTH": true
  },
  "SERVICE_SURVEY_QUESTIONS": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/surveys",
    "AUTH": true
  },
  "SERVICE_SURVEY_ANSWER_QUESTIONS": {
    "TYPE": "PUT",
    "URI": "bff/v2/mobile-app/service/surveys",
    "AUTH": true
  },
  "SERVICE_LOCATIONS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/center/locations",
    "AUTH": true
  },
  "SERVICE_LOCATIONS_BY_TRT_ID": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/center/locations-by-trtid",
    "AUTH": true
  },
  "SERVICE_MOBILE_ISSUES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/feature-flag/mobile-service-issues",
    "AUTH": true
  },
  "SERVICE_FEATURE_FLAG_SERVICE_TRACKER": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/feature-flag/mobile-app-service-tracker",
    "AUTH": true
  },
  "SERVICE_FEATURE_FLAG_ALLOW_FILE_UPLOAD": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/feature-flag/service-scheduling-allow-file-upload",
    "AUTH": true
  },
  "SERVICE_FEATURE_FLAG_MOBILE_SERVICE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/feature-flag/show-mobile-service",
    "AUTH": true
  },
  "SERVICE_FEATURE_FLAG_MACGYVER": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/feature-flag/tao-4109-use-macgyver-mobile-app",
    "AUTH": true
  },
  "SERVICE_FEATURE_FLAG_SCHEDULING_FALLBACK": {
    "TYPE": "GET",
    "URI": "mobile-app/feature-flag/TAO-13782-no-estimate-schedule-fallback",
    "AUTH": true
  },
  "SERVICE_UPLOAD_FILE": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/files",
    "AUTH": true
  },
  "SERVICE_DELETE_UPLOADED_FILE": {
    "TYPE": "PUT",
    "URI": "bff/v2/mobile-app/files/{uuid}",
    "AUTH": true
  },
  "SERVICE_UPDATE_FILE_METADATA": {
    "TYPE": "PATCH",
    "URI": "bff/v2/mobile-app/files/{uuid}/metadata",
    "AUTH": true
  },
  "SERVICE_GET_FILE_LIST": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/files/metadata",
    "AUTH": true
  },
  "SERVICE_GET_FILE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/files/{uuid}",
    "AUTH": true
  },
  "SERVICE_GET_APPOINTMENT_INVOICES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/tracker/{serviceVisitID}/invoices",
    "AUTH": true
  },
  "SERVICE_GET_ESTIMATE_APPROVAL_STATUS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/tracker/{serviceVisitID}/estimate-status",
    "AUTH": true
  },
  "SERVICE_GET_ESTIMATE_COST_DETAILS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/tracker/invoices/{invoiceId}",
    "AUTH": true
  },
  "SERVICE_APPROVE_ESTIMATE": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/tracker/{serviceVisitID}/estimate-status",
    "AUTH": true
  },
  "SERVICE_GET_FINAL_INVOICE_AMOUNT_DUE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/tracker/{serviceVisitID}/amount-due",
    "AUTH": true
  },
  "SERVICE_MACGYVER_ALERTS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/macgyver/alerts",
    "AUTH": true
  },
  "SERVICE_MACGYVER_OUTSTANDING_WORK": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/macgyver/categories",
    "AUTH": true
  },
  "SERVICE_ACTIVITY_INFO": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/macgyver/activity-info/{serviceVisitID}",
    "AUTH": true
  },
  "SERVICE_MACGYVER_POST_CUSTOMER_ANSWERS": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/macgyver/customer-answers",
    "AUTH": true
  },
  "SERVICE_MACGYVER_DISMISS_CUSTOMER_ANSWERS": {
    "TYPE": "PUT",
    "URI": "bff/v2/mobile-app/macgyver/customer-answers",
    "AUTH": true
  },
  "SERVICE_MACGYVER_SERVICE_TYPE": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/macgyver/service-type",
    "AUTH": true
  },
  "SERVICE_MACGYVER_DIAGNOSTIC_RESULT": {
    "TYPE": "GET",
    "URI": "mobile-app/macgyver/urgent-autodiag-result",
    "AUTH": true
  },
  "SERVICE_ACCEPT_LOANER_AGREEMENT": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/loaner/{serviceVisitId}",
    "AUTH": true
  },
  "SERVICE_CREATE_OFFLINE_ORDER": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/payment/create-offline-order",
    "AUTH": true
  },
  "SERVICE_COMPLETE_OFFLINE_ORDER": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/payment/complete-offline-order",
    "AUTH": true
  },
  "ENERGY_OWNERSHIP_GET_TOGGLES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/energy/feature-flags",
    "AUTH": true
  },
  "ENERGY_SERVICE_GET_SITE_INFORMATION": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/energy-service/site-information",
    "AUTH": true
  },
  "ENERGY_SERVICE_GET_SERVICE_CASES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/energy-service/appointments",
    "AUTH": true
  },
  "ENERGY_SERVICE_POST_SERVICE_CASE": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/energy-service/appointments",
    "AUTH": true
  },
  "ENERGY_SERVICE_GET_APPOINTMENT_SUGGESTIONS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/energy-service/appointment-suggestions",
    "AUTH": true
  },
  "ENERGY_SERVICE_CANCEL_SERVICE_CASE": {
    "TYPE": "PUT",
    "URI": "bff/v2/mobile-app/energy-service/service-case",
    "AUTH": true
  },
  "ENERGY_SERVICE_CANCEL_APPOINTMENT": {
    "TYPE": "PUT",
    "URI": "bff/v2/mobile-app/energy-service/appointments",
    "AUTH": true
  },
  "ENERGY_DOCUMENTS_GET_DOCUMENTS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/energy-documents/documents",
    "AUTH": true
  },
  "ENERGY_DOCUMENTS_DOWNLOAD_DOCUMENT": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/energy-documents/documents/{documentId}",
    "AUTH": true
  },
  "ENERGY_GET_TROUBLESHOOTING_GUIDE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/energy-service/troubleshooting/{troubleshootingFlow}?version=2",
    "AUTH": true
  },
  "ENERGY_SERVICE_GET_POWERWALL_WARRANTY_DETAILS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/energy-service/warranty-details",
    "AUTH": true
  },
  "LOOTBOX_USER_INFO": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/referrals",
    "AUTH": true
  },
  "LOOTBOX_GET_ONBOARDING_COPY": {
    "TYPE": "GET",
    "URI": "mobile-app/referrals/getOnboardingCopy",
    "AUTH": true
  },
  "LOOTBOX_PAST_REFERRAL_DATA": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/referrals/past-referrals",
    "AUTH": true
  },
  "REFERRAL_GET_USER_INFO": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/referrals/user-info",
    "AUTH": true
  },
  "REFERRAL_GET_PRODUCT_INFO": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/referrals/product-info",
    "AUTH": true
  },
  "REFERRAL_GET_CONTACT_LIST": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/referrals/contact-list",
    "AUTH": true
  },
  "REFERRAL_POST_CONTACT_LIST": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/referrals/contact-list",
    "AUTH": true
  },
  "REFERRAL_GET_CREDIT_HISTORY": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/referrals/credit-history",
    "AUTH": true
  },
  "REFERRAL_GET_PAST_HISTORY": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/referrals/past-referral-history",
    "AUTH": true
  },
  "REFERRAL_GET_PAST_HISTORY_COUNT": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/referrals/past-referral-history/count",
    "AUTH": true
  },
  "REFERRAL_GET_FEATURE_FLAG": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/feature-flag/tao-69420-treasure",
    "AUTH": true
  },
  "REFERRAL_GET_TERMS_AND_CONDITIONS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/referrals/terms-conditions",
    "AUTH": true
  },
  "UPGRADES_GET_ELIGIBLE_UPGRADES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/upgrades/eligible",
    "AUTH": true
  },
  "UPGRADES_GET_PURCHASED_UPGRADES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/upgrades/purchased",
    "AUTH": true
  },
  "UPGRADES_SUBMIT_REFUND": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/upgrades/refunds",
    "AUTH": true
  },
  "UPGRADES_POST_PAYMENT": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/upgrades/payment",
    "AUTH": true
  },
  "USER_ACCOUNT_GET_DETAILS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/account/details",
    "AUTH": true
  },
  "USER_ACCOUNT_PUT_DETAILS": {
    "TYPE": "PUT",
    "URI": "bff/v2/mobile-app/account/details",
    "AUTH": true
  },
  "USER_ACCOUNT_UPLOAD_PROFILE_PICTURE": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/account/profile-pic",
    "AUTH": true
  },
  "USER_ACCOUNT_DOWNLOAD_PROFILE_PICTURE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/account/profile-pic",
    "AUTH": true
  },
  "UPGRADES_CREATE_OFFLINE_ORDER": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/upgrades/payment/offline-order",
    "AUTH": true
  },
  "UPGRADES_COMPLETE_OFFLINE_ORDER": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/upgrades/payment/offline-purchase-complete",
    "AUTH": true
  },
  "SUBSCRIPTIONS_GET_ELIGIBLE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/subscriptions",
    "AUTH": true
  },
  "SUBSCRIPTIONS_GET_PURCHASED_SUBSCRIPTIONS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/subscriptions/purchased",
    "AUTH": true
  },
  "SUBSCRIPTIONS_CREATE_OFFLINE_ORDER": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/subscriptions/offline-order",
    "AUTH": true
  },
  "SUBSCRIPTIONS_POST_CREATE_OFFLINE_ORDER": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/subscriptions/offline-order",
    "AUTH": true
  },
  "GET_WALLET_FEATURE_FLAG": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/feature-flag/enable-subscriptions-wallet-channel",
    "AUTH": true
  },
  "SUBSCRIPTIONS_PURCHASE": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/subscriptions",
    "AUTH": true
  },
  "MANAGE_GET_SUBSCRIPTION_INVOICES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/subscriptions/invoices",
    "AUTH": true
  },
  "MANAGE_PATCH_AUTO_RENEW_SUBSCRIPTIONS": {
    "TYPE": "PATCH",
    "URI": "bff/v2/mobile-app/subscriptions",
    "AUTH": true
  },
  "MANAGE_GET_BILL_ME_LATER_LIST": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/bill-me-later/pending-orders",
    "AUTH": true
  },
  "MANAGE_COMPLETE_BILL_ME_LATER_ORDER": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/bill-me-later/purchase-complete",
    "AUTH": true
  },
  "MANAGE_CANCEL_BILL_ME_LATER_ORDER": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/bill-me-later/cancel",
    "AUTH": true
  },
  "MANAGE_UPGRADE_BILL_ME_LATER_GET_OFFLINE_TOKEN": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/bill-me-later/token",
    "AUTH": true
  },
  "MANAGE_GET_BILL_ME_LATER_TOGGLE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/bill-me-later/security-toggle",
    "AUTH": true
  },
  "MANAGE_POST_BILL_ME_LATER_TOGGLE": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/bill-me-later/security-toggle",
    "AUTH": true
  },
  "UPGRADES_SUBSCRIPTIONS_SHARED_BILLING_ADDRESS_FEATURE_FLAG": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/billing-address/feature-flag/TAO-8065-in-app-BillingBlock-Enable",
    "AUTH": true
  },
  "BILLING_ADDRESS_FORM_FEATURE_FLAG": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/billing-address/feature-flag/tao-8202-ownership-mobile-app-billing-address",
    "AUTH": true
  },
  "VIDEO_GUIDES_GET_VIDEO_LIST": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/video-guides",
    "AUTH": true
  },
  "PAYMENTS_GET_SIGNED_USER_TOKEN": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/payments/signed-user-token",
    "AUTH": true
  },
  "PAYMENTS_GET_SIGNED_USER_TOKEN_V4": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/payments/v4/signed-user-token",
    "AUTH": true
  },
  "PAYMENTS_POST_SIGNED_USER_TOKEN": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/payments/signed-user-token",
    "AUTH": true
  },
  "PAYMENTS_GET_INSTRUMENT": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/payments/instrument",
    "AUTH": true
  },
  "PAYMENTS_GET_BILLING_ADDRESS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/billing-address",
    "AUTH": true
  },
  "PAYMENTS_UPDATE_BILLING_ADDRESS": {
    "TYPE": "PUT",
    "URI": "bff/v2/mobile-app/billing-address",
    "AUTH": true
  },
  "PAYMENTS_FETCH_CN_ENTITY": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/payments/entity",
    "AUTH": true
  },
  "DOCUMENTS_DOWNLOAD_INVOICE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/documents/invoices/{invoiceId}",
    "AUTH": true
  },
  "SERVICE_MESSAGES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/service/messages/{serviceVisitID}",
    "AUTH": true
  },
  "SERVICE_SEND_MESSAGE": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/service/messages/{serviceVisitID}",
    "AUTH": true
  },
  "SERVICE_MESSAGES_MARK_READ": {
    "TYPE": "PATCH",
    "URI": "bff/v2/mobile-app/service/messages/{serviceVisitID}",
    "AUTH": true
  },
  "COMMERCE_CATEGORIES": {
    "TYPE": "GET",
    "URI": "commerce-api/categories/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_RECOMMENDATIONS_CATEGORIES": {
    "TYPE": "POST",
    "URI": "commerce-api/recommendations/categories/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_GET_ADDRESS": {
    "TYPE": "GET",
    "URI": "commerce-api/addresses/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_ADDRESS": {
    "TYPE": "POST",
    "URI": "commerce-api/addresses/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_CAPTURE": {
    "TYPE": "POST",
    "URI": "commerce-api/purchases/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_PROCESSPAYMENT": {
    "TYPE": "POST",
    "URI": "commerce-api/purchases/{purchaseNumber}/processpayment/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_CART_UPDATE": {
    "TYPE": "PUT",
    "URI": "commerce-api/carts/{cartId}/items/{lineItemId}/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_CART_DELETE": {
    "TYPE": "DELETE",
    "URI": "commerce-api/carts/{cartId}/items/{lineItemId}/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_ADD_CART": {
    "TYPE": "POST",
    "URI": "commerce-api/carts/items/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_CLEAR_CART": {
    "TYPE": "DELETE",
    "URI": "commerce-api/carts/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_GET_CART": {
    "TYPE": "GET",
    "URI": "commerce-api/carts/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_INVENTORY": {
    "TYPE": "POST",
    "URI": "commerce-api/inventory/v2{locale}",
    "AUTH": true
  },
  "COMMERCE_ITEM": {
    "TYPE": "POST",
    "URI": "commerce-api/items/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_TOKEN": {
    "TYPE": "POST",
    "URI": "commerce-api/tokens/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_ADDRESS_VALIDATION": {
    "TYPE": "POST",
    "URI": "commerce-api/addresses/validations/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_GEOGRAPHIES": {
    "TYPE": "GET",
    "URI": "commerce-api/geographies/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_GET_STORE_INFO": {
    "TYPE": "GET",
    "URI": "commerce-api/storeconfigurations/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_PURCHASE_HISTORY": {
    "TYPE": "GET",
    "URI": "commerce-api/purchases/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_PURCHASE_BY_ORDERNUMBER": {
    "TYPE": "GET",
    "URI": "commerce-api/purchases/{orderNumber}/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_GET_VEHICLES": {
    "TYPE": "GET",
    "URI": "commerce-api/vehicles/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_POST_VEHICLES": {
    "TYPE": "POST",
    "URI": "commerce-api/vehicles/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_GET_SERVICECENTERS": {
    "TYPE": "GET",
    "URI": "commerce-api/servicecenters/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_POST_SERVICECENTERS": {
    "TYPE": "POST",
    "URI": "commerce-api/servicecenters/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_POST_CANCELORDER": {
    "TYPE": "POST",
    "URI": "commerce-api/cancellation/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_POST_RETURNORDER": {
    "TYPE": "POST",
    "URI": "commerce-api/returns/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_GET_INSTALLERS": {
    "TYPE": "GET",
    "URI": "commerce-api/installers/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_POST_INSTALLER_VENDOR": {
    "TYPE": "POST",
    "URI": "commerce-api/checkout/auditrecords/v1/{locale}",
    "AUTH": true
  },
  "COMMERCE_CONTENT": {
    "TYPE": "GET",
    "URI": "commerce-api/content/v2?file={fileName}",
    "AUTH": true
  },
  "MATTERMOST": {
    "TYPE": "POST",
    "URI": "Just a placeholder",
    "AUTH": true
  },
  "SAFETY_RATING_GET_ELIGIBLE_FOR_TELEMATICS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/insurance/eligible-for-telematics",
    "AUTH": true
  },
  "SAFETY_RATING_GET_DAILY_BREAKDOWN": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/insurance/daily-breakdown",
    "AUTH": true
  },
  "SAFETY_RATING_GET_TRIPS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/insurance/trips",
    "AUTH": true
  },
  "SAFETY_RATING_GET_ESTIMATED_SAFETY_SCORE": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/insurance/calculate-safety-rating",
    "AUTH": true
  },
  "COMMERCE_POST_INVOICE": {
    "TYPE": "POST",
    "URI": "commerce-api/purchases/invoices/v1{locale}",
    "AUTH": true
  },
  "COMMERCE_POST_CHECKOUT_INVOICE": {
    "TYPE": "POST",
    "URI": "commerce-api/checkout/invoices/v1{locale}",
    "AUTH": true
  },
  "CHARGING_BALANCE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/balance",
    "AUTH": true
  },
  "CHARGING_BALANCE_CHARGE_TYPE_FLAG": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/feature-flag/tao-9296-filter-by-charge-type",
    "AUTH": true
  },
  "CHARGING_BALANCE_CREATE_OFFLINE_ORDER": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/charging/payment",
    "AUTH": true
  },
  "CHARGING_BALANCE_PAYMENT": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/charging/payment/complete",
    "AUTH": true
  },
  "CHARGING_BALANCE_ZERO_DOLLAR_TX": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/signed-token",
    "AUTH": true
  },
  "CHARGING_BALANCE_GET_IS_BLOCKED": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging-cn/supercharger-status",
    "AUTH": true
  },
  "CHARGING_HISTORY": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/history",
    "AUTH": true
  },
  "CHARGING_HISTORY_VEHICLES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/vehicles",
    "AUTH": true
  },
  "CHARGING_HISTORY_VEHICLE_IMAGES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/vehicle-images",
    "AUTH": true
  },
  "DOWNLOAD_CHARGING_INVOICE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/invoice/{uuid}",
    "AUTH": true
  },
  "DOWNLOAD_CHARGING_SUBSCRIPTION_INVOICE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/subscription/invoice/{invoiceId}",
    "AUTH": true
  },
  "CHARGING_DOWNLOAD_CSV": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/export",
    "AUTH": true
  },
  "CHARGING_GET_SITES_BOUNDING_BOX": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/charging/sites",
    "AUTH": true
  },
  "CHARGING_GET_SITE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/site/{id}",
    "AUTH": true
  },
  "CHARGING_GET_BILLING_ADDRESS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/billing-address",
    "AUTH": true
  },
  "CHARGING_SET_BILLING_ADDRESS": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/charging/billing-address",
    "AUTH": true
  },
  "CHARGING_STOP_SESSION": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging/session/stop/{id}",
    "AUTH": true
  },
  "FINANCING_IS_ENABLED": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/is-captive",
    "AUTH": true
  },
  "FINANCING_FETCH_DETAILS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/details",
    "AUTH": true
  },
  "FINANCING_FETCH_DOCUMENT_LIST": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/document-list",
    "AUTH": true
  },
  "FINANCING_DOWNLOAD_DOCUMENT": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/document",
    "AUTH": true
  },
  "FINANCING_GET_SIGNED_TOKEN": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/signed-token",
    "AUTH": true
  },
  "FINANCING_GET_BILLING_ADDRESS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/billing-address",
    "AUTH": true
  },
  "FINANCING_UPDATE_BILLING_ADDRESS": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/financing/billing-address",
    "AUTH": true
  },
  "FINANCING_ONE_TIME_PAYMENT_SIGNED_TOKEN": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/financing/one-time-payment-signed-token",
    "AUTH": true
  },
  "FINANCING_UPDATE_ONE_TIME_PAYMENT_STATUS": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/financing/update-one-time-payment-status",
    "AUTH": true
  },
  "FINANCING_UPDATE_ENROLLMENT_SETTINGS": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/financing/update-enrollment-settings",
    "AUTH": true
  },
  "FINANCING_LOOKUP_WALLET": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/lookup-wallet",
    "AUTH": true
  },
  "FINANCING_GET_FEATURE_FLAGS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/feature-flags",
    "AUTH": true
  },
  "FINANCING_GET_E_SIGN_DOCUMENTS_STATUS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/documents-status",
    "AUTH": true
  },
  "FINANCING_SUBMIT_FINANCING_ACTION": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/financing/manage-financing-action",
    "AUTH": true
  },
  "FINANCING_GET_EXTENSION_QUOTE": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/extension-quote",
    "AUTH": true
  },
  "FINANCING_GET_CAR_DETAILS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/car-details",
    "AUTH": true
  },
  "FINANCING_GET_E_SIGN_SUMMARY": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/esign-summary",
    "AUTH": true
  },
  "FINANCING_GET_E_SIGN_DOCUMENT": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/financing/esign-document",
    "AUTH": true
  },
  "FINANCING_VALIDATE_E_SIGN_DETAILS": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/financing/esign-validate-details",
    "AUTH": true
  },
  "DASHCAM_SAVE_CLIP": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/command/dashcam_save_clip",
    "AUTH": true
  },
  "NON_OWNER_SUPPORTED_PRODUCTS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/user/supported-products",
    "AUTH": true
  },
  "FEATURE_CONFIG": {
    "TYPE": "GET",
    "URI": "api/1/users/feature_config",
    "AUTH": true
  },
  "SITE_LOCK_GET_SITES": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging-cn/get-locks",
    "AUTH": true
  },
  "SITE_LOCK_SEND_UNLOCK_REQUEST": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/charging-cn/open-lock",
    "AUTH": true
  },
  "SITE_LOCK_GET_STATUS": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/charging-cn/get-lock-status",
    "AUTH": true
  },
  "FETCH_VEHICLE_SHARED_DRIVERS": {
    "TYPE": "GET",
    "URI": "api/1/vehicles/{vehicle_id}/drivers",
    "AUTH": true
  },
  "CREATE_VEHICLE_SHARE_INVITE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/invitations",
    "AUTH": true
  },
  "FETCH_VEHICLE_SHARE_INVITES": {
    "TYPE": "GET",
    "URI": "api/1/vehicles/{vehicle_id}/invitations",
    "AUTH": true
  },
  "REVOKE_VEHICLE_SHARE_INVITE": {
    "TYPE": "POST",
    "URI": "api/1/vehicles/{vehicle_id}/invitations/{invite_id}/revoke",
    "AUTH": true
  },
  "REMOVE_VEHICLE_SHARE_DRIVER": {
    "TYPE": "DELETE",
    "URI": "api/1/vehicles/{vehicle_id}/drivers/{share_user_id}",
    "AUTH": true
  },
  "REDEEM_VEHICLE_SHARE_INVITE": {
    "TYPE": "POST",
    "URI": "api/1/invitations/redeem",
    "AUTH": true
  },
  "AUTH_GENERATE_INSTANT_LOGIN": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/auth/generate-instant-login",
    "AUTH": true
  },
  "GET_MANAGE_DRIVER_FLAG": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/feature-flag/TAO-14025-add-driver-flow",
    "AUTH": true
  },
  "CONTACT_US_CLASSIFICATION": {
    "TYPE": "POST",
    "URI": "bff/v2/mobile-app/contact-us/classify-narrative",
    "AUTH": true
  },
  "CONTACT_US_CONTENT_CATALOG": {
    "TYPE": "GET",
    "URI": "mobile-app/contact-us/content-catalog",
    "AUTH": true
  },
  "VEHICLE_PSEUDONYM_DIRECTIVES": {
    "TYPE": "POST",
    "URI": "api/1/directives/products",
    "AUTH": true
  },
  "VEHICLE_UPLOAD_PSEUDONYM_DIRECTIVE": {
    "TYPE": "POST",
    "URI": "api/1/directives/discover",
    "AUTH": true
  },
  "VEHICLE_COMPLETE_PSEUDONYM_DIRECTIVE": {
    "TYPE": "POST",
    "URI": "api/1/directives/products/complete",
    "AUTH": true
  },
  "OWNERSHIP_VEHICLE_SPECS_REQUEST": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/ownership/vehicle-details",
    "AUTH": true
  },
  "OWNERSHIP_WARRANTY_DETAILS_REQUEST": {
    "TYPE": "GET",
    "URI": "bff/v2/mobile-app/ownership/warranty-details",
    "AUTH": true
  },
  "COMMERCE_FEATURE_FLAG": {
    "TYPE": "GET",
    "URI": "mobile-app/commerce/feature-flags",
    "AUTH": true
  },
  "COMMERCE_SEARCH_PRODUCTS": {
    "TYPE": "POST",
    "URI": "commerce-api/searches/v1{locale}",
    "AUTH": true
  }
}
