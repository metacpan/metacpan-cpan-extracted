package Sunpower::Cryocooler;
use warnings;
use strict;
use base 'Exporter';
our $VERSION = '0.1.5';
our @EXPORT = qw(devwrite endscon gct gcm scm gtt stt gcs scs gcl);
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

Sunpower::Cryocooler - a module for interfacing with Sunpower Cryocoolers 

=head1 SYNOPSIS

use Sunpower::Cryocooler;

=head1 REQUIRES

Requires Device::SerialPort or Win32::SerialPort depending on platform.

=head1 DESCRIPTION

Function library for interfacing with Sunpower Cryogenic Pumps

=head1 AUTHOR/LICENSE

Perl Module Sunpower::Cryocooler - Library of functions for Sunpower cryogenic pumps.
Copyright (C) 2009 Stanford University, Authored by Sam Kerr kerr@cpan.org

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

10 Functions exported by default:

gct()
gcm()
scm()
gtt()
stt()
gcs()
scs()
gcl()
endscon()
devwrite()

=head3 gct() - Get Current Temperature

$temp = gct();

=head3 gcm() - Get Controller Mode

$mode = gcm();

=head3 scm() - Set Controller Mode

scm($mode);

=head3 gtt() - Get Target Temperature

$tartemp = gtt();

=head3 stt() - Set Target Temperature

stt($tartemp);

=head3 gcs() - Get Command Stroke

$stroke = gcs();

=head3 scs() - Set Command Stroke

scs($stroke);

=head3 gcl() - Get Command Stroke & Limits

$limits = gcl();

=head3 endscon() - End Connection

&endscon;

=head3 devwrite() - User Inputted Command Issuer

devwrite(@commands);

-or-

devwrite
<accept input from STDIN>

=head2 Changelog

04-02-09 - Modified to run on Win32 (experimental!)

=cut



####################
## INITIALIZATION ##
####################

my $device = "/dev/ttyS0"; 
my $serial = Device::SerialPort-> new($device, 1);
die "Can't open serial port $serial: $^E\n" unless ($serial);

	$serial->user_msg(0);
	$serial->databits(8);
	$serial->baudrate(4800);
	$serial->parity("none");
	$serial->stopbits(1);
	$serial->handshake("none");
	$serial->datatype('raw');
	$serial->dtr_active('T');
	$serial->stty_icrnl(0);
	$serial->write_settings;
	$serial->read_char_time(0); 
	$serial->read_const_time(1000); 
	
	my $STALL_DEFAULT=5; 
	my $timeout=$STALL_DEFAULT;
##############
## END INIT ##
##############

sub endscon{
$serial->close();
}


##################################
## Developer Raw Command Issuer ##
##################################
sub devwrite{
my $inarg = shift(@_);
if(!defined $inarg){
print "Input Command: ";
$inarg = <>;
print $serial -> write("$inarg\r");
my $devin;
my $chars=0;
my $buffer="";
my ($count,$saw)=$serial->read(255); 

if ($count > 0) {
 $chars+=$count;
 $buffer.=$saw;
 $devin = $buffer;
 }
return $devin;
}

elsif(defined $inarg){
print $serial -> write("$inarg\r");
my $devin;
my $chars=0;
my $buffer="";
my ($count,$saw)=$serial->read(255); 

if ($count > 0) {
 $chars+=$count;
 $buffer.=$saw;
 $devin = $buffer;
 }
return $devin;
}
}

#############################
## BEGIN CRYO FUNCTION LIB ##
#############################

sub gct{
#Get Current Temperature
my $gct_in;
print $serial->write("TC\r");
my $chars=0;
my $buffer="";
my ($count,$saw)=$serial->read(255); 
if ($count > 0) {
 $chars+=$count;
 $buffer.=$saw;
 $gct_in = $buffer;
 }
$gct_in =~ m/(\w+)(\D+)(\d+\.\d)/;
return $3;
}

sub gcm{
#Get Controller Mode
my $gcm_in;
print $serial -> write("SET PID\r");
my $chars=0;
my $buffer="";
my ($count,$saw)=$serial->read(255); 

if ($count > 0) {
 $chars+=$count;
 $buffer.=$saw;
 $gcm_in = $buffer;
 }
$gcm_in =~ m/(\w+)(\D+)(\d+\.\d)/;
return $3;
}

sub scm{
#Set Controller Mode
my $input = shift(@_);
if($input =~ m/[0,2]/)
 {
 my $scm_in;
 print $serial -> write("SET PID=$input\r");
 my $chars=0;
 my $buffer="";
 my ($count,$saw)=$serial->read(255); 

 if ($count > 0) {
  $chars+=$count;
  $buffer.=$saw;
  $scm_in = $buffer;
  }
$scm_in =~ m/(\w+)(\D+)(\d+\.\d)/;
return $3;
#return $scm_in;
 }
else{warn "Set Controller Mode can only be 0 or 2";
	 die "Controller Mode not 0 or 2\n";
	}
}

sub gtt{
#Get Target Temperature
my $gtt_in;
print $serial -> write("SET TTARGET\r");
my $chars=0;
my $buffer="";
my ($count,$saw)=$serial->read(255); 

if ($count > 0) {
 $chars+=$count;
 $buffer.=$saw;
 $gtt_in = $buffer;
 }
$gtt_in =~ m/(\w+)(\D+)(\d+\.\d)/;
return $3;
}

sub stt{
#Set Target Temperature (Mode 2)
my $ttemp = shift(@_);
if($ttemp > 10 && $ttemp < 300){

 my $stt_in;
 print $serial -> write("SET TTARGET=$ttemp\r");
 my $chars=0;
 my $buffer="";
 my ($count,$saw)=$serial->read(255); 

 if ($count > 0) {
  $chars+=$count;
  $buffer.=$saw;
  $stt_in = $buffer;
  }
 $stt_in =~ m/(\w+)(\D+)(\d+\.\d)/;
 return $3;
 }
else{die "Target Temp must be between 60K and 100K\n 
	Set Target Temp to between 60K and 100K\n";}

}

sub gcs{
#Get Command Stroke (Mode 0)
my $gcs_in;
print $serial -> write("SET PWOUT\r");
my $chars=0;
my $buffer="";
my ($count,$saw)=$serial->read(255); 

if ($count > 0) {
 $chars+=$count;
 $buffer.=$saw;
 $gcs_in = $buffer;
 }
$gcs_in =~ m/(\w+)(\D+)(\d+\.\d)/;
return $3;
}

sub scs{
#Set Command Stroke (Mode 0)
my $scs_in;
my $strokin = shift(@_);
if(defined $strokin){
## Code stroke limits ##
print $serial -> write("SET PWOUT=$strokin\r");
my $chars=0;
my $buffer="";
my ($count,$saw)=$serial->read(255); 

if ($count > 0) {
 $chars+=$count;
 $buffer.=$saw;
 $scs_in = $buffer;
 }
$scs_in =~ m/(\w+)(\D+)(\d+\.\d)/;
return $3;
}
else{print "No set value given\n"; die;}
}

sub gcl{
#Get Command Stroke and Limits
my $gcl_in;
print $serial -> write("E\r");
my $chars=0;
my $buffer="";
my ($count,$saw)=$serial->read(255); 

if ($count > 0) {
 $chars+=$count;
 $buffer.=$saw;
 $gcl_in = $buffer;
 }
$gcl_in =~ s/^\w//g;
return $gcl_in;
}

###########################
## END CRYO FUNCTION LIB ##
###########################


__END__

