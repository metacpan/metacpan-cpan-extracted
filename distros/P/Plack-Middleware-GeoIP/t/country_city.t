#!/usr/bin/perl
use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Request;
use HTTP::Request::Common;

my ($Country_db, $City_db);
foreach my $dir ('.', '/usr/share/GeoIP', '/var/lib/GeoIP', '/usr/local/share/GeoIP') {
    my $country_file = "$dir/GeoIP.dat";
    my $city_file    = "$dir/GeoIPCity.dat";

    $Country_db = $country_file if -f $country_file;
    $City_db    = $city_file    if -f $city_file;

    last if $Country_db and $City_db;
}

unless ($Country_db and $City_db) {
    plan skip_all => 'No GeoIP.dat or GeoIPCity.dat found';
}

sub run_noflag {
    my ($remote_addr, $expected_country) = @_;

    my $app = builder {
        enable sub {
            my $app = shift;
            sub { $_[0]->{REMOTE_ADDR} = $remote_addr; $app->($_[0]) }; # fake remote address
        };
        enable 'Plack::Middleware::GeoIP',
            GeoIPDBFile => [
                               $Country_db, $City_db
                           ];
        sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ defined $_[0]->{GEOIP_LATITUDE} ? $_[0]->{GEOIP_COUNTRY_CODE} : '' ] ] };
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        is $res->content, $expected_country;
    };
}

sub run_oneflag {
    my ($remote_addr, $expected_country) = @_;

    my $app = builder {
        enable sub {
            my $app = shift;
            sub { $_[0]->{REMOTE_ADDR} = $remote_addr; $app->($_[0]) }; # fake remote address
        };
        enable 'Plack::Middleware::GeoIP',
            GeoIPDBFile => [
                               $Country_db, [ $City_db, 'MemoryCache' ],
                           ];
        sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ defined $_[0]->{GEOIP_LATITUDE} ? $_[0]->{GEOIP_COUNTRY_CODE} : '' ] ] };
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        is $res->content, $expected_country;
    };
}

sub run_multiflag {
    my ($remote_addr, $expected_country) = @_;

    my $app = builder {
        enable sub {
            my $app = shift;
            sub { $_[0]->{REMOTE_ADDR} = $remote_addr; $app->($_[0]) }; # fake remote address
        };
        enable 'Plack::Middleware::GeoIP',
            GeoIPDBFile => [
                               $Country_db, [ $City_db, [ qw(MemoryCache CheckCache) ] ],
                           ],
            GeoIPEnableUTF8 => 1;
        sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ defined $_[0]->{GEOIP_LATITUDE} ? $_[0]->{GEOIP_COUNTRY_CODE} : '' ] ] };
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        is $res->content, $expected_country;
    };
}

while (<DATA>) {
    chomp;
    my ($ip_addr, $expected_country) = split /\s+/;

    run_noflag($ip_addr, $expected_country);
    run_oneflag($ip_addr, $expected_country);
    run_multiflag($ip_addr, $expected_country);
}

done_testing;

__DATA__
203.174.65.12	JP
212.208.74.140	FR
200.219.192.106	BR
134.102.101.18	DE
193.75.148.28	BE
134.102.101.18	DE
147.251.48.1	CZ
194.244.83.2	IT
203.15.106.23	AU
196.31.1.1	ZA
210.54.22.1	NZ
210.25.5.5	CN
210.54.122.1	NZ
210.25.15.5	CN
192.37.51.100	CH
192.37.150.150	CH
192.106.51.100	IT
192.106.150.150	IT
