#!/usr/bin/perl

#------------------------------------------------------------------------------
#
# Standard pragmas
#
#------------------------------------------------------------------------------

use strict;
require v5.6.0;

use Getopt::Long;
use lib 'blib/lib';
use Net::SMS::Mtnsms;

my @options = qw(
    username=s
    password=s
    recipient=s
    message=s
    subject=s
    verbose
);

my %args;
die <<USAGE unless GetOptions( \%args, @options );
$0 
    -username <username> 
    -password <password>
    -recipient <mobile no.>
    -message <message>
    [ -subject <subject> ]
    [ -verbose ]

USAGE

my $sms = Net::SMS::Mtnsms->new( %args );
$sms->send_sms();
