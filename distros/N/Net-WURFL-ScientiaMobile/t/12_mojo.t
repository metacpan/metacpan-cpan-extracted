#!/usr/bin/env perl
 
use strict;
use warnings FATAL => 'all';
use Test::More;
use Net::WURFL::ScientiaMobile;

if (!$ENV{WURFL_CLOUD_APIKEY}) {
    plan skip_all => 'No API key provided (use the WURFL_CLOUD_APIKEY environment variable).';
}

if (!eval "use Mojo::Headers; 1") {
    plan skip_all => 'Mojo::Headers is not installed.';
}

my $client = Net::WURFL::ScientiaMobile->new(
    api_key => $ENV{WURFL_CLOUD_APIKEY},
);

isa_ok $client, 'Net::WURFL::ScientiaMobile',
    'client successfully initialized';

my $headers = Mojo::Headers->new;
$headers->parse("User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/534.57.2 (KHTML, like Gecko) Version/5.1.7 Safari/534.57.2\r\n");

$client->detectDevice($headers);

ok scalar keys %{$client->capabilities} > 0,
    'device capabilities successfully retrieved';

done_testing;

__END__
