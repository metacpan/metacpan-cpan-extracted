#!/usr/bin/env perl -Tw

use strict;
use warnings;

use Test::More tests => 6;
use Test::Trap;

use Net::OneSky;

my $client;
my $project;

BEGIN {
  $client = Net::OneSky->new(api_key => 'key', api_secret => 'secret');
  $project = $client->project(123);
}

# Valid params
ok( defined $project,                         'it returns something');
ok( $project->isa('Net::OneSky::Project'),    '   and it is a Net::OneSky::Project');

trap {
  $client->project;
};

is($trap->leaveby, 'die',                     'it dies without a project id');
ok($trap->die->{trace}->{message} =~ /undef/, '   with the correct error message');

trap {
  $client->project('abc');
};

is($trap->leaveby, 'die',                     'it dies when the project id is non-numeric');
ok($trap->die->{trace}->{message} =~ /'Num'/, '   with the correct error message');

