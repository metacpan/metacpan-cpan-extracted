#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

BEGIN { require 't/utils.pl' }
RT::Init();

verbose("Reopening a finished ticket should reactivate it");
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    ok my ($id) = $ticket->Create( Queue => 'General', Status => 'resolved' );

    run_exec_ok;

    $ticket->Load( $id );
    is $ticket->FirstCustomFieldValue("Age"), 'Finished';

    # reopen
    $ticket->_Set( Field => 'Status', Value => 'open' );

    is $ticket->FirstCustomFieldValue("Age"), 'Active';

    run_exec_ok;

    $ticket->Load( $id );
    is $ticket->FirstCustomFieldValue("Age"), 'Active';
}
