#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  example.pl
#
#        USAGE:  ./example.pl
#
#  DESCRIPTION:
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Gavin Henry (GH), <ghenry@suretecsystems.com>
#      COMPANY:  Suretec Systems Ltd.
#      VERSION:  1.0
#      CREATED:  25/11/09 17:37:41 GMT
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Net::Magrathea;

my $ntsapi = Net::Magrathea->new(
    username => 'user',
    password => 'pass',
    debug    => 1,
);

my $index = 1;
my $dest  = 'S:01224279484@sip.surevoip.co.uk';

my $number = $ntsapi->allocate('01224______');

$ntsapi->activate($number) if $ntsapi->success;

$ntsapi->set( $number, $index, $dest ) if $ntsapi->success;

$ntsapi->status($number) if $ntsapi->success;

$ntsapi->user_info(
    $number, 'Suretec Systems Ltd., 24 Cormack Park,
Rothienorman, Inverurie, AB51 8GL.'
) if $ntsapi->success;

$ntsapi->deactivate($number) if $ntsapi->success;
$ntsapi->quit;

