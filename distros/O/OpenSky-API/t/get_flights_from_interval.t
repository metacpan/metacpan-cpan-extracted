#!/usr/bin/env perl

use lib 'lib', 't/lib';
use Test::Most;
use OpenSky::API::Test qw( set_response );

my $raw     = OpenSky::API->new( raw     => 1, testing => 1 );
my $objects = OpenSky::API->new( testing => 1 );

my $now  = time;
my $then = $now - 3600;

subtest 'Flight data is available' => sub {
    set_response( two_flights() );
    my $flights_raw = $raw->get_flights_from_interval( $then, $now );
    set_response( two_flights() );
    my $flights = $objects->get_flights_from_interval( $then, $now );

    is scalar @$flights_raw, 2, 'We should have two flights';
    is $flights->count, 2, 'We should have two flights';

    while ( my $flight = $flights->next ) {
        my $raw_flight = shift @$flights_raw;
        foreach my $key ( sort keys %$raw_flight ) {
            my $value = $raw_flight->{$key};
            is $flight->$key, $value, "The $key should be the same: '$value'";
        }
    }
};

subtest 'No flights available' => sub {
    my $not_found = <<'END';
HTTP/1.1 404 Not Found
Content-Length: 0
Date: Sun, 28 May 2023 08:02:21 GMT
END
    set_response($not_found);
    my $flights_raw = $raw->get_flights_from_interval( $then, $now );
    set_response($not_found);
    my $flights = $objects->get_flights_from_interval( $then, $now );
    ok !@$flights_raw,                    'We should have no flights for raw data';
    ok !$flights->count, 'We should have no flights for objects';
};

subtest 'Bad time intervals' => sub {
    my $then = $now + 3600;
    set_response( two_flights() );
    throws_ok { $raw->get_flights_from_interval( $then, $now ) }
    qr/The end time must be greater than or equal to the start time/, 'The earlier time must be earlier than the later time';

    $then = $now - 10_000;
    set_response( two_flights() );
    throws_ok { $raw->get_flights_from_interval( $then, $now ) }
    qr/The time interval must be smaller than two hours/, 'The time interval must be smaller than two hours';
};

done_testing;

sub two_flights {
    return <<'END';
HTTP/1.1 200 OK
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Connection: keep-alive
Content-Length: 4362
Content-Type: application/json;charset=UTF-8
Date: Sun, 28 May 2023 06:40:02 GMT
Expires: 0
Pragma: no-cache
Server: nginx/1.17.6
Set-Cookie: XSRF-TOKEN=7e66aaf5-4338-412f-a71b-3c603d95352e; Path=/
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block

[
    {"icao24":"394813","firstSeen":1685254624,"estDepartureAirport":"LIPN","lastSeen":1685255252,"estArrivalAirport":"LIPN","callsign":"FGSAT   ","estDepartureAirportHorizDistance":4311,"estDepartureAirportVertDistance":1292,"estArrivalAirportHorizDistance":1358,"estArrivalAirportVertDistance":2663,"departureAirportCandidatesCount":48,"arrivalAirportCandidatesCount":9},
    {"icao24":"471fac","firstSeen":1685250275,"estDepartureAirport":"LHBP","lastSeen":1685252459,"estArrivalAirport":"LRCT","callsign":"WZZ78YZ ","estDepartureAirportHorizDistance":940,"estDepartureAirportVertDistance":44,"estArrivalAirportHorizDistance":9159,"estArrivalAirportVertDistance":2207,"departureAirportCandidatesCount":63,"arrivalAirportCandidatesCount":7}
]
END
}
