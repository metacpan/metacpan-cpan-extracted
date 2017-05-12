#!/usr/bin/perl -w

=head1 NAME

example-information.pl - Net::GPSD example to get gpsd server and perl module information

=cut

use strict;
use lib qw{./lib ../lib};
use Net::GPSD;

my ($host,$port)=split(q{:}, shift()||'');
$host||=q{localhost};
$port||=q{2947};

my $gps=Net::GPSD->new(host=>$host, port=>$port) || die("Error: Cannot connect to the gpsd server");

print "Net::GPSD Version:\t", $gps->VERSION ||"N/A", "\n";
print "gpsd Version:     \t", $gps->daemon  ||"N/A", "\n";
print "gpsd Commands:    \t", $gps->commands||"N/A", "\n";
print "Host:             \t", $gps->host    ||"N/A", "\n";
print "Port:             \t", $gps->port    ||"N/A", "\n";
print "Baud:             \t", $gps->baud    ||"N/A", "\n";
print "Rate:             \t", $gps->rate    ||"N/A", "\n";
print "Device:           \t", $gps->device  ||"N/A", "\n";
print "ID:               \t", $gps->id      ||"N/A", "\n";
print "Protocol:         \t", $gps->protocol||"N/A", "\n";

__END__

=head1 SAMPLE OUTPUT

  Net::GPSD Version:      0.34
  gpsd Version:           2.34
  gpsd Commands:          abcdefgijklmnopqrstuvwxyz
  Host:                   gpsd.mainframe.cx
  Port:                   2947
  Baud:                   N/A
  Rate:                   1.00
  Device:                 /dev/cuaU0
  ID:                     SiRF
  Protocol:               3

=cut
