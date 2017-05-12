#!/usr/bin/perl

use strict;
use warnings;

use RT::Condition::Complex::Test tests => 9;

my $scrip;
{
    my $code = "Type = 'Create'";
    $scrip = RT::Scrip->new( $RT::SystemUser );
    my ($sid, $msg) = $scrip->Create(
        Queue                  => 'General',
        ScripAction            => 'User Defined',
        ScripCondition         => 'Complex',
        Template               => 'Blank',
        Stage                  => 'TransactionCreate',

        CustomIsApplicableCode => $code,
        CustomPrepareCode      => 'return 1',
        CustomCommitCode       => 'return $self->TicketObj->SetPriority( $self->TicketObj->Priority + 1 )',
    );
    ok($sid, "created scrip") or diag "error: $msg";
}

{
    my $ticket = RT::Ticket->new($RT::SystemUser);
    my ($tid, $msg) = $ticket->Create( Queue => 'General', Subject => 'test' );
    ok( $tid, "created ticket" );
    is( $ticket->Priority, 1, "fired scrip" );
}

