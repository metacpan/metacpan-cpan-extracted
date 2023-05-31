#!/usr/bin/env perl

use lib 'lib', 't/lib';
use Test::Most;
use OpenSky::API::Test qw( set_response );

my $raw     = OpenSky::API->new( raw     => 1, testing => 1 );
my $objects = OpenSky::API->new( testing => 1 );

my $now     = time;
my $then    = $now - 3600;
my $airport = 'EBNM';

subtest 'Flight data is available' => sub {
    set_response( one_flight() );
    my $flights_raw = $raw->get_arrivals_by_airport( $airport, $then, $now );
    set_response( one_flight() );
    my $flights = $objects->get_arrivals_by_airport( $airport, $then, $now );

    is scalar @$flights_raw, 1, 'We should have one flight';
    is $flights->count,      1, 'We should have one flight';

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
    my $flights_raw = $raw->get_arrivals_by_airport( $airport, $then, $now );
    set_response($not_found);
    my $flights = $objects->get_arrivals_by_airport( $airport, $then, $now );
    ok !@$flights_raw,   'We should have no flights for raw data';
    ok !$flights->count, 'We should have no flights for objects';
};

subtest 'Bad time intervals' => sub {
    my $then = $now + 3600;
    set_response( one_flight() );
    throws_ok { $raw->get_arrivals_by_airport( $airport, $then, $now ) }
    qr/The end time must be greater than or equal to the start time/, 'The earlier time must be earlier than the later time';

    $then = $now - 604900;
    set_response( one_flight() );
    throws_ok { $raw->get_arrivals_by_airport( $airport, $then, $now ) }
    qr/The time interval must be smaller than 7 days/, 'The time interval must be smaller than 7 days';
};

done_testing;

sub one_flight {
    return <<'END';
HTTP/1.1 200 OK
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Connection: keep-alive
Content-Length: 366
Content-Type: application/json;charset=UTF-8
Date: Sun, 28 May 2023 09:45:46 GMT
Expires: 0
Pragma: no-cache
Server: nginx/1.17.6
Set-Cookie: XSRF-TOKEN=889fcd99-7008-47c0-82e6-e68355609d3e; Path=/
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-XSS-Protection: 1; mode=block

[{"icao24":"391cd9","firstSeen":1685264616,"estDepartureAirport":"EBNM","lastSeen":1685265426,"estArrivalAirport":"EBNM","callsign":null,"estDepartureAirportHorizDistance":7934,"estDepartureAirportVertDistance":1007,"estArrivalAirportHorizDistance":5256,"estArrivalAirportVertDistance":1739,"departureAirportCandidatesCount":107,"arrivalAirportCandidatesCount":107}]
END
}
