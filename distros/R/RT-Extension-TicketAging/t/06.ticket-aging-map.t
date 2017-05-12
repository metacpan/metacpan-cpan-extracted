#!/usr/bin/perl

# Test user specified $TicketAgingMap

use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { require 't/utils.pl' }
RT::Init();

use RT::Extension::TicketAging;
my $CLASS = 'RT::Extension::TicketAging';

RT->Config->Set('TicketAgingMap' => undef);
my $Default_Map = $CLASS->PrepareMap;

verbose("Empty TicketAgingMap");
{
    RT->Config->Set('TicketAgingMap' => {});
    is_deeply( $CLASS->PrepareMap, $Default_Map );
}


verbose("New age");
{
    ok( !grep { $_ eq 'NewAgeHippies' } $CLASS->Ages );

    my %new_map = (
        NewAgeHippies => {
            Condition => {
                SQL => sub { return "Something" }
            }
        }
    );

    RT->Config->Set('TicketAgingMap' => \%new_map );
    is_deeply( $CLASS->PrepareMap, { %$Default_Map, %new_map } );
}
