#!/usr/bin/perl -w

=head1 NAME

example-subscribe.pl - Net::GPSD subscribe method example

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD;

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

my $gps=Net::GPSD->new(host=>$host, port=>$port) || die("Error: Cannot connect to the gpsd server");

$gps->subscribe();

print "Note: Nothing after the subscribe will be executed.\n";
