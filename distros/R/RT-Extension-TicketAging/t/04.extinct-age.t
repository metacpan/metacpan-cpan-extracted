#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN { require 't/utils.pl' }
RT::Init();
use_ok('RT::Extension::TicketAging');

verbose("simle test of the script");
{
    my ($res, $err) = run_exec();
    ok(!$err, 'no error') or diag("error: $err");
}

verbose("extinct age");
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id) = $ticket->Create( Queue => 'General', Status => 'resolved' );
    ok($id, "created ticket");

    my $date = $ticket->LastUpdatedObj;
    $date->AddDays( -31 * 13 );
    $ticket->__Set( Field => 'LastUpdated', Value => $date->ISO );
    is($ticket->LastUpdated, $date->ISO, 'set date');

    my ($res, $err) = run_exec( debug => 1 );
    my $ferr = filter_log( $err );
    ok(!$ferr, 'no error') or diag $err;

    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    is($ticket->id, $id, 'loaded ticket');
    is($ticket->FirstCustomFieldValue('Age'), 'Extinct', 'correct age');
    is($ticket->Status, 'deleted', 'correct status');

    verbose("extinct age: search");
    {
        my $tickets = RT::Tickets->new( $RT::SystemUser );
        $tickets->FromSQL("id = $id AND CF.{Age} = 'Extinct'");
        ok($tickets->Count, "we found ticket even if it's deleted");
    }
}


