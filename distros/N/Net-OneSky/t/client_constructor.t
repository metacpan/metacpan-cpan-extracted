#!/usr/bin/env perl -Tw

use strict;
use warnings;

use Test::More tests => 6;
use Test::Trap;

use Net::OneSky;

my $client;

BEGIN {
  $client = Net::OneSky->new(api_key => 'key', api_secret => 'secret');
}

# Valid arguments
ok( defined $client,                                          'new() returned something');
ok( $client->isa('Net::OneSky'),                              '  And it is a Net::OneSky');

trap {
  Net::OneSky->new(api_secret => 'secret');
};

is($trap->leaveby, 'die',                                     'invalid api_key forces die');
ok($trap->die->{trace}->{message} =~ /api_key.*required/,     'api_key is required');

trap {
  Net::OneSky->new(api_key => 'key');
};

is($trap->leaveby, 'die',                                     'invalid api_secret forces die');
ok($trap->die->{trace}->{message} =~ /api_secret.*required/,  'api_secret is required');
