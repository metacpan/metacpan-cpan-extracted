#!/usr/bin/env perl

use lib 'lib', 't/lib';
use Test::Most;
use OpenSky::API::Test qw( set_response );

my $raw     = OpenSky::API->new( raw     => 1, testing => 1 );
my $objects = OpenSky::API->new( testing => 1 );

my $now    = time;
my $then   = $now - 3600;
my $icao24 = '3c4a9c';

use Test2::Plugin::BailOnFail;

subtest 'Flight data is available' => sub {
    set_response( two_flights() );
    my $flights_raw = $raw->get_flights_by_aircraft( $icao24, $then, $now );
    set_response( two_flights() );
    my $flights = $objects->get_flights_by_aircraft( $icao24, $then, $now );

    is scalar @$flights_raw, 3, 'We should have three flights';
    is $flights->count,      3, 'We should have three flights';

    while ( my $flight = $flights->next ) {
        my $raw_flight = shift @$flights_raw;
        foreach my $key ( sort keys %$raw_flight ) {
            my $value = $raw_flight->{$key};
            no warnings 'uninitialized';
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
    my $flights_raw = $raw->get_flights_by_aircraft( $icao24, $then, $now );
    set_response($not_found);
    my $flights = $objects->get_flights_by_aircraft( $icao24, $then, $now );
    ok !@$flights_raw,   'We should have no flights for raw data';
    ok !$flights->count, 'We should have no flights for objects';
};

subtest 'Bad time intervals' => sub {
    my $then = $now + 3600;
    set_response( two_flights() );
    throws_ok { $raw->get_flights_by_aircraft( $icao24, $then, $now ) }
    qr/The end time must be greater than or equal to the start time/, 'The earlier time must be earlier than the later time';

    $then = $now - 2_593_000;
    set_response( two_flights() );
    throws_ok { $raw->get_flights_by_aircraft( $icao24, $then, $now ) }
    qr/The time interval must be smaller than 30 days/, 'The time interval must be smaller than 30 days';
};

done_testing;

sub two_flights {
    return <<'END';
HTTP/1.1 200 OK
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Connection: keep-alive
Content-Length: 1092
Content-Type: application/json;charset=UTF-8
Date: Sun, 28 May 2023 09:30:23 GMT
Expires: 0
Pragma: no-cache
Server: nginx/1.17.6
Set-Cookie: XSRF-TOKEN=e0dc3f64-ddc0-4205-8136-a46a712e4f5d; Path=/
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block

[{"icao24":"391cd9","firstSeen":1685266104,"estDepartureAirport":"EBNM","lastSeen":1685266217,"estArrivalAirport":null,"callsign":null,"estDepartureAirportHorizDistance":4118,"estDepartureAirportVertDistance":1190,"estArrivalAirportHorizDistance":null,"estArrivalAirportVertDistance":null,"departureAirportCandidatesCount":107,"arrivalAirportCandidatesCount":0},{"icao24":"391cd9","firstSeen":1685264616,"estDepartureAirport":"EBNM","lastSeen":1685265426,"estArrivalAirport":"EBNM","callsign":null,"estDepartureAirportHorizDistance":7934,"estDepartureAirportVertDistance":1007,"estArrivalAirportHorizDistance":5256,"estArrivalAirportVertDistance":1739,"departureAirportCandidatesCount":107,"arrivalAirportCandidatesCount":107},{"icao24":"391cd9","firstSeen":1685261521,"estDepartureAirport":"EBML","lastSeen":1685262279,"estArrivalAirport":"EBNM","callsign":null,"estDepartureAirportHorizDistance":8639,"estDepartureAirportVertDistance":1345,"estArrivalAirportHorizDistance":6227,"estArrivalAirportVertDistance":1586,"departureAirportCandidatesCount":109,"arrivalAirportCandidatesCount":108}]
END
}
