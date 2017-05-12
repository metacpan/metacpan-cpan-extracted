#!/usr/bin/env perl
use strict;
use warnings;

use lib 't/lib';
use Test::More tests => 2;
use Net::Journyx;

# This is the workflow we need from Update.html
# and for sending updates if the live update fails
my $jx = Net::Journyx->new(
    site => 'https://services.journyx.com/jxadmin23/jtcgi/jxapi.pyc',
    wsdl => 'file:../jxapi.wsdl',
    username => $ENV{'JOURNYX_USER'},
    password => $ENV{'JOURNYX_PASSWORD'},
);
isa_ok($jx, 'Net::Journyx');

use Net::Journyx::Time;

my $time_record = Net::Journyx::Time->new( jx => $jx );
ok $time_record;


#my $user = $time_record->getUser(pattern => 'bestpractical');
#
#$time_record->user($user->id);
#$time_record->date();#unknown format, Transaction->Created
#$time_record->hours(); # Transaction->TimeWorked converted from minutes to floating point hours
#$time_record->project(); #Ticket->FirstCustomFieldValue('Journyx Project ID');
#$time_record->comment(); #Ticket->FirstCustomFieldValue('Journyx Comment') (transaction custom field)
#
#$j->addTimeRecord( rec => $time_record );
