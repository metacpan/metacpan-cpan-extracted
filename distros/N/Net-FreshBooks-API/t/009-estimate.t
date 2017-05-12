#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dump qw( dump );
use DateTime;
use Test::More;

plan -r 't/config.pl'
    && require( 't/config.pl' )
    && $ENV{FB_LIVE_TESTS}
    ? ( tests => 34 )
    : (
    skip_all => 'Set FB_LIVE_TESTS to true in your %ENV to run live tests' );

use_ok 'Net::FreshBooks::API';

# create the FB object
my $fb = Net::FreshBooks::API->new(
    {   auth_token   => FBTest->get( 'auth_token' ),
        account_name => FBTest->get( 'account_name' ),
        verbose      => $ENV{'FB_VERBOSE'} || 0,
    }
);

ok $fb, "created the FB object";

my $estimate = $fb->estimate;

foreach my $method ( sort keys %{ $fb->estimate->_fields() } ) {
    can_ok( $estimate, $method );
}

isa_ok( $estimate, 'Net::FreshBooks::API::Estimate', );

my $client = $fb->client->list->next;
ok( $client->client_id, "got a client id" );

$estimate->client_id( $client->client_id );
ok $estimate->add_line(
    {   name      => "Estimate Test line 1",
        unit_cost => 1,
        quantity  => 1,
    }
    ),
    "Add first line to the estimate";

ok $estimate->add_line(
    {   name      => "Estimate Test line 2",
        unit_cost => 2,
        quantity  => 2,
    }
    ),
    "Add second line to the estimate";

ok $estimate->create, "create the estimate";
is( $estimate->status, "draft", 'flagged as draft' );

#$estimate->status('sent');
$estimate->update( { status => 'sent' } );

is( $estimate->status, "sent", 'flagged as sent' );

#ok ( $estimate->send_by_email, "sent by email" );
