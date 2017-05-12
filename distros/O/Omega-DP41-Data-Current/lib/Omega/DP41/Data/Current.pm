package Omega::DP41::Data::Current;
use warnings;
use strict;
use base 'Exporter';
our $VERSION = '0.3.4';
our @EXPORT = qw(serial_data);
####################
### OS Dependant ###
####################
BEGIN {
   require autouse;
   autouse->import(
     $^O =~ /^win32/i ? "Win32::SerialPort" : "Device::SerialPort"
   );
}
########################
### End OS Dependant ###
########################

=head1 NAME

DP41::Data::Current - Module for retrieving data from an Omega brand Thermacouple. 

=head1 SYNOPSIS

use DP41::Data::Current;
$temp = serial_data();

=head1 REQUIRES

Requires Device::SerialPort or Win32::SerialPort depending on platform.

=head1 DESCRIPTION

Module for retrieving the current reading on a Omega DP41 Thermocouple. Module has been tested on Omega DP41-RTD only, unknown if it will work with other models. Requires Device::SerialPort or Win32::SerialPort depending on platform.

=head1 AUTHOR/LICENSE

Perl Module DP41::Data::Current, retrieves current reading from Omega DP41-RTD Thermocouple.
Copyright (C) 2008-2009 Stanford University, Authored by Sam Kerr kerr@cpan.org

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA


=head2 Functions

One function is exported by default (serial_data).

=head3 serial_data

$temp = serial_data();

Returns the current reading from a DP41 Thermacouple.

=head2 Changelog

04-06-09 - v0.3.4 Added  PREREQ_PM  => Device::SerialPort to makefile
04-02-09 - v0.3.2 Modified to run on Win32 (experimental!)


=cut

sub serial_data{
my $current;
my $device = "/dev/ttyS0"; 
my $serial = Device::SerialPort-> new($device, 1);
die "Can't open serial port $serial: $^E\n" unless ($serial);
	
	$serial->user_msg(0);
	$serial->databits(7);
	$serial->baudrate(9600);
	$serial->parity("odd");
	$serial->stopbits(1);
	$serial->handshake("none");
	$serial->datatype('raw');
	$serial->dtr_active('T');
	$serial->stty_icrnl(0);
	$serial->write_settings;

print $serial->write("*X01\r"); 
my $STALL_DEFAULT=5; 
my $timeout=$STALL_DEFAULT;
$serial->read_char_time(0); 
$serial->read_const_time(1000); 
my $chars=0;
my $buffer="";
my ($count,$saw)=$serial->read(255); 

if ($count > 0) {
 $chars+=$count;
 $buffer.=$saw;
 $current = $buffer;
 }

$current =~ s/^X......//g;
$current =~ s/\.{1}//g;
return $current;
$serial->close();
}
