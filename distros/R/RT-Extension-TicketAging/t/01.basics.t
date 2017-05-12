#!/usr/bin/perl

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN { require 't/utils.pl' }
RT::Init();

verbose("simle test of the script");
{
    my ($res, $err) = run_exec();
    ok(!$err, 'no error') or diag $err;
}

verbose("check custom field");
{
    my $cf = RT::CustomField->new( $RT::SystemUser );
    $cf->LoadByNameAndQueue( Name => 'Age', Queue => 0 );
    unless ( ok($cf->id, 'custom field exists') ) {
        diag "Custom Field 'Age' doesn't exist. Most probably you forget to ran `make initdb`\n";
        exit 1;
    }
}

verbose("active age");
{
    my $ticket = RT::Ticket->new( $RT::SystemUser );
    my ($id) = $ticket->Create( Queue => 'General' );
    ok($id, "created ticket");

    my ($res, $err) = run_exec( debug => 1 );
    my $ferr = filter_log( $err );
    ok(!$ferr, 'no error') or diag $err;

    $ticket = RT::Ticket->new( $RT::SystemUser );
    $ticket->Load( $id );
    is($ticket->id, $id, 'loaded ticket');
    is($ticket->FirstCustomFieldValue('Age'), 'Active', 'correct age');
}

