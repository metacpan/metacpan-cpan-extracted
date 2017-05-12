#!/usr/bin/perl

use strict;
use warnings;

use Test::MockTime qw( :all );
use RT::Extension::SLA::Test tests => 11;
my $test = 'RT::Extension::SLA::Test';

my $ru_queue = $test->load_or_create_queue( Name => 'RU' );
ok $ru_queue && $ru_queue->id, 'created RU queue';

my $us_queue = $test->load_or_create_queue( Name => 'US' );
ok $us_queue && $ru_queue->id, 'created US queue';

no warnings 'once';
%RT::ServiceAgreements = (
    Default => 2,
    QueueDefault => {
        RU => { Timezone => 'Europe/Moscow' },
        US => { Timezone => 'America/New_York' },
    },
    Levels  => {
        '2' => { Resolve => { BusinessMinutes => 60 * 2 } },
    },
);

set_absolute_time('2007-01-01T22:00:00Z');

note 'check dates in US queue';
{
    my $ticket = RT::Ticket->new($RT::SystemUser);
    my ($id) = $ticket->Create( Queue => 'US', Subject => 'xxx' );
    ok( $id, "created ticket #$id" );

    my $start = $ticket->StartsObj->ISO( Timezone => 'utc' );
    is( $start, '2007-01-01 22:00:00', 'Start date is right' );
    my $due = $ticket->DueObj->ISO( Timezone => 'utc' );
    is( $due, '2007-01-02 15:00:00', 'Due date is right' );
}

note 'check dates in RU queue';
{
    my $ticket = RT::Ticket->new($RT::SystemUser);
    my ($id) = $ticket->Create( Queue => 'RU', Subject => 'xxx' );
    ok( $id, "created ticket #$id" );

    my $start = $ticket->StartsObj->ISO( Timezone => 'utc' );
    is( $start, '2007-01-02 06:00:00', 'Start date is right' );
    my $due = $ticket->DueObj->ISO( Timezone => 'utc' );
    is( $due, '2007-01-02 08:00:00', 'Due date is right' );
}

