#!/usr/bin/env perl

use lib 'lib', 't/lib';
use Test::Most;
use OpenSky::API::Test qw( set_response );

my $fetch_raw_data = OpenSky::API->new( raw     => 1, testing => 1 );
my $open_sky       = OpenSky::API->new( testing => 1 );

my %params = (
    extended => 1,
    bbox     => {
        lomin => -11.141510,
        lamin => 52.257137,
        lomax => 19.607100,
        lamax => 62.890717,
    }
);

subtest 'Flight data is available' => sub {
    set_response( three_vectors() );
    my $vectors_raw = $fetch_raw_data->get_states(%params);
    set_response( three_vectors() );
    my $states = $open_sky->get_states(%params);
    explain $vectors_raw;

    my $state_vectors = $vectors_raw->{states};
    is scalar @$state_vectors, 3, 'We should have three vectors';
    my $vectors = $states->vectors;
    is $vectors->count, 3, 'We should have three vectors';

    my @params = $vectors->first->_get_params;
    while ( my $flight = $states->next ) {
        my $raw_flight = shift @$state_vectors;
        foreach my $param (@params) {
            my $value = shift @$raw_flight;
            no warnings 'uninitialized';
            is $flight->$param, $value, "The $param should be the same: '$value'";
        }
    }
};

subtest 'No vectors available' => sub {
    my $not_found = <<'END';
HTTP/1.1 404 Not Found
Content-Length: 0
Date: Sun, 28 May 2023 08:02:21 GMT
END
    set_response($not_found);
    my $vectors_raw = $fetch_raw_data->get_states(%params);
    set_response($not_found);
    my $states = $open_sky->get_states(%params);
    ok !@{ $vectors_raw->{states} }, 'We should have no state vectors for raw data';
    ok !$states->count,              'We should have no state vectors for objects';
};

done_testing;

sub three_vectors {
    return <<'END';
HTTP/1.1 200 OK
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Connection: keep-alive
Content-Length: 52570
Content-Type: application/json;charset=UTF-8
Date: Sun, 28 May 2023 08:28:18 GMT
Expires: 0
Pragma: no-cache
Server: nginx/1.17.6
Set-Cookie: XSRF-TOKEN=a103094f-5df1-47e5-9760-31e42c80b7c2; Path=/
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
X-Rate-Limit-Remaining: 3974
X-XSS-Protection: 1; mode=block

{
	"time":1685262494,
	"states":[
		["511156","SAS67W  ","Estonia",1685262494,1685262494,14.8963,56.5511,11582.4,false,226.44,205.28,0,null,11727.18,"3726",false,0,0],
		["3c6668","DLH9YE  ","Germany",1685262494,1685262494,10.7016,59.3888,7040.88,false,208.9,195.13,9.75,null,7033.26,null,false,0,1],
        ["44028c","EJU42KR ","Austria",1685262494,1685262494,10.9374,52.545,8793.48,false,216.11,88.91,-11.38,null,9044.94,"1000",false,0,4]
    ]
}
END
}
