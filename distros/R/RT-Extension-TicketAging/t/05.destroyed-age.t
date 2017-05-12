#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN { require 't/utils.pl' }
RT::Init();

verbose("destroyed age");
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id) = $ticket->Create( Queue => 'General', Status => 'resolved' );
    ok($id, "created ticket");

    my $date = $ticket->LastUpdatedObj;
    $date->AddDays( -31*24 );
    $ticket->__Set( Field => 'LastUpdated', Value => $date->ISO );
    is($ticket->LastUpdated, $date->ISO, 'set date' );

    my ($res, $err) = run_exec( debug => 1 );
    my $ferr = filter_log( $err );
    ok(!$ferr, 'no error') or diag $err;

    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    is($ticket->id, undef, "couldn't load destroyed ticket");
}

