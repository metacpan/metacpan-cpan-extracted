# see also https://github.com/openskynetwork/opensky-api

package OpenSky::API;

# ABSTRACT: Perl interface to the OpenSky Network API

our $VERSION = '0.005';
use Moose;
use OpenSky::API::Types qw(
  ArrayRef
  Bool
  Dict
  HashRef
  InstanceOf
  Int
  Latitude
  Longitude
  NonEmptyStr
  Num
  Optional
);
use OpenSky::API::States;
use OpenSky::API::Flights;
use PerlX::Maybe;
use Config::INI::Reader;
use Carp qw( croak );

use Mojo::UserAgent;
use Mojo::URL;
use Mojo::JSON qw( decode_json );
use Type::Params -sigs;
use experimental qw( signatures );

warnings::warnif( 'deprecated', 'OpenSky::API is deprecated and should no longer be used. Please use WebService::OpenSky instead.' );

has config => (
    is      => 'ro',
    isa     => NonEmptyStr,
    default => sub ($self) { $ENV{HOME} . '/.openskyrc' },
);

has [qw/debug raw testing/] => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has _config_data => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => undef,
    lazy     => 1,
    default  => sub ($self) {
        Config::INI::Reader->read_file( $self->config );
    },
);

has _ua => (
    is       => 'ro',
    isa      => InstanceOf ['Mojo::UserAgent'],
    init_arg => undef,
    default  => sub { Mojo::UserAgent->new },
);

has _username => (
    is       => 'ro',
    isa      => NonEmptyStr,
    lazy     => 1,
    init_arg => 'username',
    default  => sub ($self) { $ENV{OPENSKY_USERNAME} // $self->_config_data->{opensky}{username} },
);

has _password => (
    is       => 'ro',
    isa      => NonEmptyStr,
    lazy     => 1,
    init_arg => 'password',
    default  => sub ($self) { $ENV{OPENSKY_PASSWORD} // $self->_config_data->{opensky}{password} },
);

has _base_url => (
    is       => 'ro',
    init_arg => 'base_url',
    isa      => NonEmptyStr,
    default  => sub ($self) {'https://opensky-network.org/api'},
);

has limit_remaining => (
    is      => 'ro',
    isa     => Int,
    lazy    => 1,
    writer  => '_set_limit_remaining',
    default => sub ($self) {
        return 4000 if $self->testing;

        # per their documentation,
        # https://openskynetwork.github.io/opensky-api/rest.html#api-credit-usage,
        # this request should only cost one credit. However, it appears to
        # cost three.
        my %params = (
            lamin => 49.7,
            lomin => 3.2,
            lamax => 50.5,
            lomax => 4.6,
        );
        my $route = '/states/all';
        return $self->_get_response( route => $route, params => \%params, credits => 1 );
    },
);

signature_for get_states => (
    method => 1,
    named  => [
        time   => Optional [Num], { default => 0 },
        icao24 => Optional [ NonEmptyStr | ArrayRef [NonEmptyStr] ],
        bbox   => Optional [
            Dict [
                lamin => Latitude,
                lomin => Longitude,
                lamax => Latitude,
                lomax => Longitude,
            ],
            { default => {} },
        ],
        extended => Optional [Bool],
    ],
    named_to_list => 1,
);

sub get_states ( $self, $seconds, $icao24, $bbox, $extended ) {
    my %params = (
        maybe time     => $seconds,
        maybe icao24   => $icao24,
        maybe extended => $extended,
    );
    if ( keys $bbox->%* ) {
        $params{$_} = $bbox->{$_} for qw( lamin lomin lamax lomax );
    }

    my $route    = '/states/all';
    my $response = $self->_get_response( route => $route, params => \%params, no_auth_required => 1 ) // {
        time   => time - ( $seconds // 0 ),
        states => [],
    };
    if ( $self->raw ) {
        return $response;
    }
    return OpenSky::API::States->new($response);
}

signature_for get_my_states => (
    method => 1,
    named  => [
        time    => Optional [Num], { default => 0 },
        icao24  => Optional [ NonEmptyStr | ArrayRef [NonEmptyStr] ],
        serials => Optional [ NonEmptyStr | ArrayRef [NonEmptyStr] ],
    ],
    named_to_list => 1,
);

sub get_my_states ( $self, $seconds, $icao24, $serials ) {
    my %params = (
        extended      => 1,
        maybe time    => $seconds,
        maybe icao24  => $icao24,
        maybe serials => $serials,
    );

    my $route    = '/states/own';
    my $response = $self->_get_response( route => $route, params => \%params );
    if ( $self->raw ) {
        return $response;
    }
    return OpenSky::API::States->new($response);
}

sub get_flights_from_interval ( $self, $begin, $end ) {
    if ( $begin >= $end ) {
        croak 'The end time must be greater than or equal to the start time.';
    }
    if ( ( $end - $begin ) > 7200 ) {
        croak 'The time interval must be smaller than two hours.';
    }

    my %params   = ( begin => $begin, end => $end );
    my $route    = '/flights/all';
    my $response = $self->_get_response( route => $route, params => \%params ) // [];

    if ( $self->raw ) {
        return $response;
    }
    return OpenSky::API::Flights->new($response);
}

sub get_flights_by_aircraft ( $self, $icao24, $begin, $end ) {
    if ( $begin >= $end ) {
        croak 'The end time must be greater than or equal to the start time.';
    }
    if ( ( $end - $begin ) > 2592 * 1e3 ) {
        croak 'The time interval must be smaller than 30 days.';
    }

    my %params   = ( icao24 => $icao24, begin => $begin, end => $end );
    my $route    = '/flights/aircraft';
    my $response = $self->_get_response( route => $route, params => \%params ) // [];

    if ( $self->raw ) {
        return $response;
    }
    return OpenSky::API::Flights->new($response);
}

sub get_arrivals_by_airport ( $self, $airport, $begin, $end ) {
    if ( $begin >= $end ) {
        croak 'The end time must be greater than or equal to the start time.';
    }
    if ( ( $end - $begin ) > 604800 ) {
        croak 'The time interval must be smaller than 7 days.';
    }

    my %params   = ( airport => $airport, begin => $begin, end => $end );
    my $route    = '/flights/arrival';
    my $response = $self->_get_response( route => $route, params => \%params ) // [];

    if ( $self->raw ) {
        return $response;
    }
    return OpenSky::API::Flights->new($response);
}

sub get_departures_by_airport ( $self, $airport, $begin, $end ) {
    if ( $begin >= $end ) {
        croak 'The end time must be greater than or equal to the start time.';
    }
    if ( ( $end - $begin ) > 604800 ) {
        croak 'The time interval must be smaller than 7 days.';
    }

    my %params   = ( airport => $airport, begin => $begin, end => $end );
    my $route    = '/flights/departure';
    my $response = $self->_get_response( route => $route, params => \%params ) // [];

    if ( $self->raw ) {
        return $response;
    }
    return OpenSky::API::Flights->new($response);
}

signature_for _get_response => (
    method => 1,
    named  => [
        route            => NonEmptyStr,
        params           => Optional [HashRef],
        credits          => Optional [Bool],
        no_auth_required => Optional [Bool],
    ],
    named_to_list => 1,
);

sub _get_response ( $self, $route, $params, $credits, $no_auth_required ) {
    my $url = $self->_url( $route, $params, $no_auth_required );

    my $response  = $self->_GET($url);
    my $remaining = $response->headers->header('X-Rate-Limit-Remaining');

    $self->_debug( $response->headers->to_string . "\n" );

    # not all requests cost credits, so we only want to set the limit if
    # $remaining is defined
    $self->_set_limit_remaining($remaining) if !$credits && defined $remaining;
    if ( !$response->is_success ) {
        if ( $response->code == 404 ) {

            # this is annoying. If the didn't match any criteria, return a 200
            # and and empty element. Instead, we get a 404.
            return;
        }
        croak $response->to_string;
    }
    return $remaining if $credits;
    if ( $self->debug ) {
        $self->_debug( $response->body );
    }
    return decode_json( $response->body );
}

# an easy target to override for testing
sub _GET ( $self, $url ) {
    $self->_debug("GET $url\n");
    return $self->_ua->get($url)->res;
}

sub _debug ( $self, $msg ) {
    return if !$self->debug;
    say STDERR $msg;
}

sub _url ( $self, $url, $params = {}, $no_auth_required = 0 ) {
    my $username = $self->_username;
    my $password = $self->_password;
    if ( ( !$username || !$password ) && $no_auth_required ) {
        return Mojo::URL->new( $self->_base_url . $url )->query($params);
    }
    $url = Mojo::URL->new( $self->_base_url . $url )->userinfo( $self->_username . ':' . $self->_password );
    $url->query($params);
    return $url;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenSky::API - Perl interface to the OpenSky Network API

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    use OpenSky::API;

    my $api = OpenSky::API->new(
        username => 'username',
        password => 'password',
    );

    my $states = $api->get_states;
    while ( my $vector = $states->next ) {
        say $vector->callsign;
    }

=head1 DESCRIPTION

B<WARNING>: This module is deprecated in favor of L<WebService::OpenSky>. This
was an experiment to see how easy it would be to create this module using
Github Copilot. It was a fun experiment, but there were some design flaws.
Those are largely fixed in L<WebService::OpenSky>.

This is a Perl interface to the OpenSky Network API. It provides a simple, object-oriented
interface, but also allows you to fetch raw results for performance.

This is largely based on L<the official Python
implementation|https://github.com/openskynetwork/opensky-api/blob/master/python/opensky_api.py>,
but with some changes to make it more user-friendly for Perl developers.

=head1 CONSTRUCTOR

Basic usage:

    my $open_sky = OpenSky::API->new;

This will create an instance of the API object with no authentication. This only allows you access
to the C<get_states> method.

If you want to use the other methods, you will need to provide a username and password:

    my $open_sky = OpenSky::API->new(
        username => 'username',
        password => 'password',
    );

You can get a username and password by registering for a free account on
L<OpenSky Network|https://opensky-network.org>.

Alternatively, you can set the C<OPENSKY_USERNAME> and C<OPENSKY_PASSWORD>
environment variables, or create a C<.openskyrc> file in your home directory
with the following contents:

    [opensky]
    username = myusername
    password = s3cr3t

If you'd like that file in another directory, just pass the C<config> argument:

    my $open_sky = OpenSky::API->new(
        config => '/path/to/config',
    );

By default, all methods return objects. If you want to get the raw results, you can set the C<raw>
attribute in the constructor:

    my $open_sky = OpenSky::API->new(
        raw => 1,
    );

If you are debugging why something failed, pass the C<debug> attribute to see
a C<STDERR> trace of the requests and responses:

    my $open_sky = OpenSky::API->new(
        debug => 1,
    );

=head1 METHODS

For more insight to all methods, see L<the OpenSky API
documentation|https://openskynetwork.github.io/opensky-api/>.

Note a key difference between the Python implementation and this one: the
Python implementation returns <None> if results are not found. For this
module, you will still receive the iterator, but it won't have any results.
This allows you to keep a consistent interface without having to check for
C<undef> everywhere.

=head2 get_states

    my $states = $api->get_states;

Returns an instance of L<OpenSky::API::States>. if C<< raw => 1 >> was passed
to the constructor, this will be the raw data structure instead.

This API call can be used to retrieve any state vector of the
OpenSky. Please note that rate limits apply for this call. For API calls
without rate limitation, see C<get_my_states>.

By default, the above fetches all current state vectors.

You can (optionally) request state vectors for particular airplanes or times using the following request parameters:

    my $states = $api->get_states(
        icao24 => 'abc9f3',
        time   => 1517258400,
    );

Both parameters are optional.

=over 4

=item * C<icao24>

One or more ICAO24 transponder addresses represented by a hex string (e.g. abc9f3). To filter multiple ICAO24 append the property once for each address. If omitted, the state vectors of all aircraft are returned.

=item * C<time>

A Unix timestamp (seconds since epoch). Only state vectors after this timestamp are returned.

=back

In addition to that, it is possible to query a certain area defined by a
bounding box of WGS84 coordinates. For this purpose, add the following
parameters:

    my $states = $api->get_states(
        bbox => {
            lomin => -0.5,     # lower bound for the longitude in decimal degrees
            lamin => 51.25,    # lower bound for the latitude in decimal degrees
            lomax => 0,        # upper bound for the longitude in decimal degrees
            lamax => 51.75,    # upper bound for the latitude in decimal degrees
        },
    );

You can also request the category of aircraft by adding the following request parameter:

    my $states = $api->get_states(
        extended => 1,
    );

Any and all of the above parameters can be combined.

    my $states = $api->get_states(
        icao24   => 'abc9f3',
        time     => 1517258400,
        bbox     => {
            lomin => -0.5,     # lower bound for the longitude in decimal degrees
            lamin => 51.25,    # lower bound for the latitude in decimal degrees
            lomax => 0,        # upper bound for the longitude in decimal degrees
            lamax => 51.75,    # upper bound for the latitude in decimal degrees
        },
        extended => 1,
    );

=head2 get_my_states

    my $states = $api->get_my_states;

Returns an instance of L<OpenSky::API::States>. if C<< raw => 1 >> was passed,
this will be the raw data structure instead.

This API call can be used to retrieve state vectors for your own
sensors without rate limitations. Note that authentication is required for
this operation, otherwise you will get a 403 - Forbidden.

By default, the above fetches all current state vectors for your states. However, you can also pass
arguments to fine-tune this:

    my $states = $api->get_my_states(
        time    => 1517258400,
        icao24  => 'abc9f3',
        serials => [ 1234, 5678 ],
    );

=over 4

=item * C<time>

The time in seconds since epoch (Unix timestamp to retrieve states for. Current time will be used if omitted.

=item * <icao24>

One or more ICAO24 transponder addresses represented by a hex string (e.g.
abc9f3). To filter multiple ICAO24 append the property once for each address.
If omitted, the state vectors of all aircraft are returned.

=item * C<serials>

Retrieve only states of a subset of your receivers. You can pass this argument
several time to filter state of more than one of your receivers. In this case,
the API returns all states of aircraft that are visible to at least one of the
given receivers.

=back

=head2 C<get_arrivals_by_airport>

    my $arrivals = $api->get_arrivals_by_airport('KJFK', $start, $end);

Returns an instance of L<OpenSky::API::Flights>. if C<< raw => 1 >> was
passed, you will get the raw data structure instead.

Positional arguments:

=over 4

=item * C<airport>

The ICAO code of the airport you want to get arrivals for.

=item * C<start>

The start time in seconds since epoch (Unix timestamp).

=item * C<end>

The end time in seconds since epoch (Unix timestamp).

=back

The interval between start and end time must be smaller than seven days.

=head2 C<get_departures_by_airport>

Identical to C<get_arrivals_by_airport>, but returns departures instead of arrivals.

=head2 C<get_flights_by_aircraft>

    my $flights = $api->get_flights_by_aircraft('abc9f3', $start, $end);

Returns an instance of L<OpenSky::API::Flights>. if C<< raw => 1 >> was passed
to the constructor, you will get the raw data structure instead.

The first argument is the ICAO24 transponder address of the aircraft you want.

=head2 C<get_flights_from_interval>

    my $flights = $api->get_flights_from_interval($start, $end);

Returns an instance of L<OpenSky::API::Flights>. if C<< raw => 1 >> was passed
to the constructor, you will get the raw data structure instead.

=head2 C<limit_remaining>

    my $limit = $api->limit_remaining;

The methods to retrieve state vectors of sensors other than your own are rate
limited. As of this writing, this is only C<get_states>. See
L<limitations|https://openskynetwork.github.io/opensky-api/rest.html#limitations>
for more details.

=head1 EXAMPLES

Perl Wikipedia, L<OpenSky Network|https://en.wikipedia.org/wiki/OpenSky_Network> is ...

    The OpenSky Network is a non-profit association based in Switzerland that
    provides open access of flight tracking control data. It was set up as
    a research project by several universities and government entities with
    the goal to improve the security, reliability and efficiency of the
    airspace. Its main function is to collect, process and store air traffic
    control data and provide open access to this data to the public. Similar
    to many existing flight trackers such as Flightradar24 and FlightAware,
    the OpenSky Network consists of a multitude of sensors (currently around
    1000, mostly concentrated in Europe and the US), which are connected to
    the Internet by volunteers, industrial supporters, academic, and
    governmental organizations. All collected raw data is archived in a
    large historical database, containing over 23 trillion air traffic control
    messages (November 2020). The database is primarily used by researchers
    from different areas to analyze and improve air traffic control
    technologies and processes

=head2 Elon Musk's Jet

However, this data can be used to track the movements of certain aircraft. For
example, Elon Musk's primary private jet (he has three, but this is the one he
mainly uses), has the ICAO24 transponder address C<a835af>. Running the
following code ...

    use OpenSky::API;

    my $musks_jet = 'a835af';
    my $openapi   = OpenSky::API->new;

    my $days = 7;
    my $now  = time;
    my $then = $now - 86400 * 7;    # up to 7 days ago

    my $flight_data = $openapi->get_flights_by_aircraft( $musks_jet, $then, $now );
    say "Jet $musks_jet has " . $flight_data->count . " flights";

As of this writing, that prints out:

    Jet a835af has 6 flights

=head1 ETHICS

There are some ethical considerations to be made when using this module. I was
ambivalent about writing it, but I decided to do so because I think it's
important to be aware of the privacy implications. However, it's also
important to be aware of the L<climate
implications|https://www.euronews.com/green/2023/03/30/wasteful-luxury-private-jet-pollution-more-than-doubles-in-europe>.

Others are using the OpenSky API to model the amount of carbon being released
by the aviation industry, while others have used this public data to predict
corporate mergers and acquisitions. There are a wealth of reasons why this
data is useful, but not all of those reasons are good. Be good.

=head1 TODO

=over 4

=item * Implement rate limits

=item * Add a C<is_rate_limited> method to results

=item * Add Waypoints and Flight Routes

=back

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
