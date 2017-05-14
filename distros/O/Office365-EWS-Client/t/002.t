#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use DateTime;
use Data::Dumper;

my $ews;
my $user = 'skip';
my $pass = 'skip';

if ( $ENV{EWS_USER} and $ENV{EWS_PASS} ) {
    $user = $ENV{EWS_USER};
    $pass = $ENV{EWS_PASS};
    plan tests => 8;
}
else {
    print "set EWS_USER and EWS_PASS in your ENV for more thorough tests\n";
    plan tests => 1;
    ok(1);
    done_testing;
    exit 0;
}

use Office365::EWS::Client;

# test simple auth and fetch
$ews = Office365::EWS::Client->new({
    server         => 'outlook.office365.com',
    username       => $user,
    password       => $pass,
    server_version => 'Exchange2013_SP1',
});

# calendar
my $calendar;
ok( $calendar = $ews->calendar->retrieve({
    start => DateTime->now(),
    end   => DateTime->now(),
}), 'got calendar' );  
is( ref $calendar, 'EWS::Calendar::ResultSet', 'calendar ref' );
ok( $calendar->count() >= 0, 'haz some calendar' );

# gal
my $gal;
ok( $gal = $ews->gal->retrieve( { querystring => $user } ), 'got gal' );  
is( ref $gal, 'Office365::EWS::GAL::ResultSet', 'gal ref' );
ok( $gal->count() > 0, 'haz self in gal' );
while ($gal->has_next) {
    my $entry = $gal->next;
    ok($entry->DisplayName, "displayname");
    is($entry->EmailAddress->{EmailAddress}, $user, "emailaddress");
}
