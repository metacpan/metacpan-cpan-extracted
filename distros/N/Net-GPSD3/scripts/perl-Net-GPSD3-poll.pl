#!/usr/bin/perl
use strict;
use warnings;
use Net::GPSD3;
use Data::Dumper qw{Dumper};

=head1 NAME

perl-Net-GPSD3-poll.pl - Net::GPSD3 Poll Example

=cut

my $host=shift || undef;
my $port=shift || undef;
my $debug=shift || 0;

my $gpsd=Net::GPSD3->new(host=>$host, port=>$port); #default host port as undef

my $poll=$gpsd->poll;

printf "Net::GPSD3:    %s\n", $poll->parent->VERSION;
printf "GPSD Release:  %s\n", $poll->parent->cache->VERSION->release;
printf "Protocol:      %s\n", $poll->parent->cache->VERSION->protocol;
printf "Sats Reported: %s\n", $poll->sky->reported;
printf "Sats Used:     %s\n", $poll->sky->used;
printf "Timestamp:     %s\n", $poll->tpv->timestamp;
printf "Latitude:      %s\n", $poll->tpv->lat;
printf "Longitude:     %s\n", $poll->tpv->lon;
printf "Altitude:      %s\n", $poll->tpv->alt;

print Dumper($gpsd->poll) if $debug;

=head1 Example Output

  Net::GPSD3:    0.15
  GPSD Release:  2.96
  Protocol:      3.4
  Sats Reported: 13
  Sats Used:     9
  Timestamp:     2011-04-05T05:35:08.00Z
  Latitude:      37.371420138
  Longitude:     -122.01518436
  Altitude:      28.974

=cut
