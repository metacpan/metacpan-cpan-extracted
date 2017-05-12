#!/usr/bin/perl
use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Request;
use HTTP::Request::Common;

my $Country_db;
for my $file ('GeoLite2-Country.mmdb', '/usr/share/GeoIP/GeoLite2-Country.mmdb', '/var/lib/GeoIP/GeoLite2-Country.mmdb', '/usr/local/share/GeoIP/GeoLite2-Country.mmdb') {
    $Country_db = $file, last if -f $file;
}

unless ($Country_db) {
    plan skip_all => 'No GeoLite2-Country.mmdb found';
}

sub run {
    my ($remote_addr, $expected_country) = @_;

    my $app = builder {
        enable sub {
            my $app = shift;
            sub { $_[0]->{REMOTE_ADDR} = $remote_addr; $app->($_[0]) };
        };
        enable 'Plack::Middleware::GeoIP2',
            GeoIP2DBFile => $Country_db;
        sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ $_[0]->{GEOIP_COUNTRY_CODE} ] ] };
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

    run($ip_addr, $expected_country);
}

# GeoIP2::Database::Reader returns exceptions when encountering local/bad IPs
{
    my $app = builder {
        enable sub {
            my $app = shift;
            sub { $_[0]->{REMOTE_ADDR} = '10.164.153.148'; $app->($_[0])};
        };
        enable 'Plack::Middleware::GeoIP2',
            GeoIP2DBFile => $Country_db;
        sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ $_[0]->{GEOIP_COUNTRY_CODE} ] ] };
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET '/');
        is $res->content, 'ZZ';
    };
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
