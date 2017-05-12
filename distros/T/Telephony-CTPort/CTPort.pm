package Telephony::CTPort;

# CTPort - part of ctserver client/server library for Computer Telephony 
# programming in Perl
#
# Copyright (C) 2001-2003 David Rowe
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require 5.005_62;
#use strict;
use warnings;
use Carp;
use IO::Socket;
use IO::Handle;
use Cwd qw(cwd);
use POSIX;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Telephony::CTPort ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );
our $VERSION = '1.01';

# Preloaded methods go here.

# constructor - opens TCP/IP connection to server and makes sure we are
# on hook to start with
sub new($) {
	my $proto = shift;
	our $port = shift;
	my $class = ref($proto) || $proto;
	my $self = {};

	$self->{SERVER} = IO::Socket::INET->new(
		Proto => "tcp",
		PeerAddr => "localhost",
		PeerPort => $port,
	)
	or croak "cannot connect to server tcp port $port";

	$self->{EVENT}  = undef;
	$self->{DEF_EXT} = ".au";     # default audio file extension
	$self->{PATHS} = [];          # user supplied audio file paths
	$self->{INTER_DIGIT} = undef;
	$self->{DEFEVENTS} = undef;		# Used to hold default event handlers
	$self->{CONFIG} = undef;		# Used to hold Config values
	$self->{DAEMON} = undef;		# Used to hold daemon state

	bless($self, $class);
	return $self;
}

sub set_def_ext($) {
	my $self = shift;
	my $defext = shift;
	$self->{DEF_EXT} = $defext;
}

sub set_paths($) {
	my $self = shift;
	my $paths = shift;
	$self->{PATHS} = $paths;
}

sub set_event_handler(){
	my $self = shift;
	my $event = shift;
	my $handle = shift;
	$self->{DEFEVENT}{$event}=$handle;
}

sub unset_event_handler(){
	my $self = shift;
	my $event = shift;
	$self->{DEFEVENT}{$event}=undef;
}

sub event($) {
	my $self = shift;
	return $self->{EVENT};
}

sub off_hook() {
	my $self = shift;
	my $buf;
	my $server = $self->{SERVER};
	print $server "ctanswer\n";
	$buf = <$server>;
}

sub on_hook() {
	my $self = shift;
	my $buf;
	my $server = $self->{SERVER};
	print $server "cthangup\n";
	$buf = <$server>;
}

sub wait_for_ring() {
	my $self = shift;
	my $server = $self->{SERVER};
	my $caller_id;
	print $server "ctwaitforring\n";
	$caller_id = <$server>;
	return $caller_id;
}

sub wait_for_dial_tone() {
	my $self = shift;
	my $server = $self->{SERVER};
	my $buf;
	print $server "ctwaitfordial\n";
	$buf = <$server>;
}

sub play_busy_tone_async(){
	my $self = shift;
	my $server = $self->{SERVER};
	print $server "ctplaytoneasync\nbusy\n";
	my $tmp=<$server>;
	return($tmp);
}

sub play_dialx_tone_async(){
	my $self = shift;
	my $server = $self->{SERVER};
	print $server "ctplaytoneasync\ndialx\n";
}

sub play_dial_tone_async(){
	my $self = shift;
	my $server = $self->{SERVER};
	print $server "ctplaytoneasync\ndial\n";
}

sub play_ringback_async(){
	my $self = shift;
	my $server = $self->{SERVER};
	print $server "ctplaytoneasync\nringback\n";
	my $tmp=<$server>;
	return($tmp);
}

sub play_terminate(){
	my $self = shift;
	my $server = $self->{SERVER};
	print $server "ctstoptone\n";
	my $tmp=<$server>;
	return($tmp);
}

sub play_stop(){
	my $self = shift;
	my $server = $self->{SERVER};
	print $server "ctplay_stop\n";
	my $tmp=<$server>;
	return($tmp);
}

sub play_async($) {
	my $self = shift;
	my $files_str = shift;
	my $file;

	unless (length($files_str)) {return;}

	foreach $file (split(/ /,$files_str)){
		$self->_ctplayonefile_async($file);
	}
}

sub _ctplayonefile_async() {
	my $self = shift;
	my $file = shift;
	my $server = $self->{SERVER};
	my $event;
	my $path;

	# append default extension if no extension on file name
	if ($self->{DEF_EXT}) {
		if ($file !~ /\./) {
			$file = $file . $self->{DEF_EXT};
		}
	}

	# check user supplied paths
	if (defined($self->{PATHS})) {
		my @paths = $self->{PATHS};
		foreach $path (@paths) {
			# find first path that contains the file
			if (-e "$path/$file") {
				print $server "ctplay_async\n$path/$file\n";
				$event = <$server>;
				$event =~ s/[^0-9ABCD#*]//g;
				$self->{EVENT} = $event;
				return;			      
			}
		}
	}

	# check default paths
	if (-e "$ENV{PWD}/$file") {
		# full path supplied by caller
		print $server "ctplay_async\n$ENV{PWD}/$file\n";
		$event = <$server>;
		$event =~ s/[^0-9ABCD#*]//g;
		$self->{EVENT} = $event;
		return;			      
	}

	if (-e "$ENV{PWD}/prompts/$file") {
		# prompts sub-dir of current dir
		print $server "ctplay_async\n$ENV{PWD}/prompts/$file\n";
		$event = <$server>;
		$event =~ s/[^0-9ABCD#*]//g;
		$self->{EVENT} = $event;
		return;			      
	}

	if (-e "/var/ctserver/USEngM/$file") {
		# USEngM prompts dir
		print $server "ctplay_async\n/var/ctserver/USEngM/$file\n";
		$event = <$server>;
		$event =~ s/[^0-9ABCD#*]//g;
		$self->{EVENT} = $event;
		return;			      
	}

	return -1;
} 

sub play($) {
	my $self = shift;
	my $files_str = shift;
	my $file;

	unless (length($files_str)) {return;}
	my @files_array = split(/ /,$files_str);

	foreach $file (@files_array) {
		if (!$self->{EVENT}) {
			$self->_ctplayonefile($file);
		}
	}
}

sub _ctplayonefile() {
	my $self = shift;
	my $file = shift;
	my $server = $self->{SERVER};
	my $event;
	my $path;

	# append default extension if no extension on file name
	if ($self->{DEF_EXT}) {
		if ($file !~ /\./) {
			$file = $file . $self->{DEF_EXT};
		}
	}

	# check user supplied paths
	if (defined($self->{PATHS})) {
		my @paths = $self->{PATHS};
		foreach $path (@paths) {
			# find first path that contains the file
			if (-e "$path/$file") {
				print $server "ctplay\n$path/$file\n";
				$event = <$server>;
				$event =~ s/[^0-9ABCD#*]//g;
				$self->{EVENT} = $event;
				return;			      
			}
		}
	}

	# check default paths
	if (-e "$ENV{PWD}/$file") {
		# full path supplied by caller
		print $server "ctplay\n$ENV{PWD}/$file\n";
		$event = <$server>;
		$event =~ s/[^0-9ABCD#*]//g;
		$self->{EVENT} = $event;
		return;			      
	}

	if (-e "$ENV{PWD}/prompts/$file") {
		# prompts sub-dir of current dir
		print $server "ctplay\n$ENV{PWD}/prompts/$file\n";
		$event = <$server>;
		$event =~ s/[^0-9ABCD#*]//g;
		$self->{EVENT} = $event;
		return;			      
	}

	if (-e "/var/ctserver/USEngM/$file") {
		# USEngM prompts dir
		print $server "ctplay\n/var/ctserver/USEngM/$file\n";
		$event = <$server>;
		$event =~ s/[^0-9ABCD#*]//g;
		$self->{EVENT} = $event;
		return;			      
	}

	print "play: File $file not found!\n";
} 

sub record($$$) {
	my $self = shift;
	my $file = shift;
	my $timeout = shift;
	my $term_digits = shift;
	my $server = $self->{SERVER};
	my $event;
	my @unpacked_file = split(//, $file);

	unless ($unpacked_file[0] eq "/") {
		# if not full path, record in current dir
		$file = "$ENV{PWD}/$file";
	}
	print $server "ctrecord\n$file\n$timeout\n$term_digits\n";
	$event = <$server>;
	$event =~ s/[^0-9ABCD#*]//g;
	$self->{EVENT} = $event;
} 

sub ctsleep($) {
	my $self = shift;
	my $secs = shift;
	my $server = $self->{SERVER};
	my $event;
	if (!$self->{EVENT}) {
		print $server "ctsleep\n$secs\n";
		$event = <$server>;
		$event =~ s/[^0-9ABCD#*]//g;
		$self->{EVENT} = $event;
	}
}

sub clear() {
	my $self = shift;
	my $server = $self->{SERVER};
	my $tmp;
	print $server "ctclear\n";
	$tmp = <$server>;
	undef $self->{EVENT};
}

sub collect($$) {
	my $self = shift;
	my $maxdigits = shift;
	my $maxseconds = shift;
	my $maxinter;
	my $server = $self->{SERVER};
	my $digits ="OK";

	$maxinter = $self->{INTER_DIGIT} || $maxseconds;
	undef $self->{EVENT};

	print $server "ctcollect\n$maxdigits\n$maxseconds\n$maxinter\n";
	while ($digits =~ /OK/){
		$digits = <$server>; 
	}
	$digits =~ s/[^0-9ABCD#*]//g;
	return $digits;		  
}

sub dial($) {
	my $self = shift;
	my($dial_str) = shift;
	my $server = $self->{SERVER};
	my($tmp);
	print $server "ctdial\n$dial_str\n";
	$tmp = <$server>; 
	return($tmp);
}

sub number($) {
	my $self = shift;
	my $num = shift;
	my $server = $self->{SERVER};
	my $tens;
	my $hundreds;
	my @files;
	my $all;
	unless ($num) {return undef};
	if ($num == 0) { push(@files, $num); }

	$hundreds = int($num/100) * 100;
	$num = $num - $hundreds;
	if ($hundreds != 0) { push(@files, $hundreds); }
	$tens = int($num/10) * 10;
	if ($num > 20) { 
		$num = $num - $tens;
		if ($tens != 0) { push(@files, $tens); }
	}
	if ($num != 0) { push(@files, $num); }
	$all = "@files";
	return $all;
}

sub get_inter_digit_time_out() {
	my $self = shift;
	return $self->{INTER_DIGIT};
}

sub set_inter_digit_time_out($) {
	my $self = shift;
	my $inter = shift;
	$self->{INTER_DIGIT} = $inter;
}

sub wait_for_event() {
	my $self = shift;
	my $server = $self->{SERVER};
	my $handle = "";

WEWL:
	print $server "ctwaitforevent\n";
	while($handle eq ""){
		$handle = <$server>;
		if (!defined($handle)) {
			exit;
		}
		$handle =~ s/[^0-9a-z ]//g;
	}
	my $event = <$server>;
	$event =~ s/[^0-9a-z ]//g;
	if (defined $self->{DEFEVENT}{$event}){
		my $foo="main::".$self->{DEFEVENT}{$event};
		&{$foo}($handle);
		$self->{EVENT} = $event;
		undef $event;
		$handle="";
		goto WEWL;
	}
	$self->{EVENT} = $event;
	return ($handle,$event);
}

sub send_event($$) {
	my $self = shift;
	my $port = shift;
	my $event = shift;
	my $server = $self->{SERVER};
	my $tmp;

	print $server "ctsendevent\n$port\n$event\n";
	$tmp = <$server>; 
}

sub start_timer_async($) {
	my $self = shift;
	my $duration = shift;
	my $server = $self->{SERVER};
	my $tmp;

	print $server "ctstarttimerasync\n$duration\n";
	$tmp = <$server>; 
	return($tmp);
}

sub stop_timer() {
	my $self = shift;
	my $server = $self->{SERVER};
	my $tmp;

	print $server "ctstoptimer\n";
	$tmp = <$server>; 
	return($tmp);
}

sub play_tone_async($) {
	my $self = shift;
	my $tone = shift;
	my $server = $self->{SERVER};
	my $tmp;

	print $server "ctplaytoneasync\n$tone\n";
	$tmp = <$server>; 
	return($tmp);
}

sub stop_tone() {
	my $self = shift;
	my $server = $self->{SERVER};
	my $tmp;

	print $server "ctstoptone\n";
	$tmp = <$server>; 
	return($tmp);
}

sub join($$) {
	my $self = shift;
	my $port = shift;
	my $port2 = shift;
	my $server = $self->{SERVER};
	my $tmp;

	print $server "ctjoin\n $port \n $port2 \n";
	$tmp = <$server>; 
	return($tmp);
}

sub bridge($) {
	my $self = shift;
	my $port = shift;
	my $server = $self->{SERVER};
	my $tmp;

	print $server "ctbridge\n$port\n";
	$tmp = <$server>; 
	return($tmp);
}

sub unbridge($) {
	my $self = shift;
	my $port = shift;
	my $server = $self->{SERVER};
	my $tmp;
	if ($port <0){
		return("NOK");
	}

	print $server "ctunbridge\n$port\n";
	$tmp = <$server>; 
	return($tmp);
}

sub start_ring_async($) {
	my $self = shift;
	my $server = $self->{SERVER};
	my $tmp;

	print $server "ctstartringasync\n";
	$tmp = <$server>; 
	return($tmp);
}

sub stop_ring($) {
	my $self = shift;
	my $server = $self->{SERVER};
	my $tmp;

	print $server "ctstopring\n";
	$tmp = <$server>; 
	return($tmp);
}

sub start_ring_once_async() {
	my $self = shift;
	my $server = $self->{SERVER};
	my $tmp;

	print $server "ctstartringonceasync\n";
	$tmp = <$server>; 
	return($tmp);
}

sub getconf($){
	my $self = shift;
	my $file = shift;
	my ($line,$section,$tag,$value);
	if (!defined $conffile){
		our $conffile = cwd();
		$conffile=$conffile."/".$file;
	}
	open(FILE,"< $conffile") || die "Can't open $conffile : $!\n";
	foreach $line (<FILE>){
		chomp $line;
		if ($line =~ /^\s*#/){
			next;
		}
		elsif($line =~ /^\s*\[\w+\]/){
			$section=$line;
			$section =~ s/[\[\]]//g;
		}
		elsif($line =~ /(\w+)=(\w+)/){
			($tag, $value)= split /=/,$line;
			$self->{CONFIG}->{$section}{$tag} = $value;
		}
	}
	close FILE;
	return(1);
}

sub daemonize($){
	my $self = shift;
	my $bool = shift;
	if ($bool == 1){
		# make a daemon
		defined(my $pid = fork) or die "Can't fork: $!";
		exit if $pid;
		setsid or die "Can't start a new session: $!";
		chdir '/' or die "Can't chdir to /: $!";
		umask 0;
		open STDIN, '/dev/null' or die "Can't read /dev/null: $!";
		open STDOUT, '/dev/null' or die "Can't write to /dev/null: $!";
		open STDERR, '/dev/null' or die "Can't write to /dev/null: $!";
	}
	$self->{DAEMON}=1;
	return(1);
}

sub openlogger($){
	my $self = shift;
	my $logfile = shift;
	open (our $LOGFILE,">$logfile");
	autoflush $LOGFILE 1;
}

sub logger($){
	my $self = shift;
	my $text = shift;
	my $foo = strftime("%Y/%m/%d-%H:%M:%S",localtime(time));
	if ($self->{DAEMON}){
		print $LOGFILE "$foo [".$port."] $text\n";
	}
	else {
		print STDERR "$foo [".$port."] $text\n";
	}
}

1;

__END__

# Documentation for module

=head1 NAME

Telephony::CTPort - Computer Telephony programming in Perl

=head1 SYNOPSIS

use Telephony::CTPort;

$ctport = new Telephony::CTPort(1200); # first port of CT card
$ctport->off_hook;
$ctport->play("beep");                 
$ctport->record("prompt.wav",5,"");    # record for 5 seconds
$ctport->play("prompt.wav");           # play back
$ctport->on_hook;

=head1 DESCRIPTION

This module implements an Object-Oriented interface to control Computer 
Telephony (CT) card ports using Perl.  It is part of a client/server
library for rapid CT application development using Perl.

=head1 AUTHOR

David Rowe, support@voicetronix.com.au

=head1 CONSTRUCTOR

new Telephony::CTPort(SERVER_PORT);

Connects Perl client to the "ctserver" server via TCP/IP port SERVER_PORT,
where SERVER_PORT=1200, 1201,..... etc for the first, second,..... etc
CT ports.

=head1 METHODS

event() - returns the most recent event, or undef if no events pending.

off_hook() - takes port off hook, just like picking up the phone.

on_hook() - places the port on hook, just like hanging up.

wait_for_ring() - blocks until port detects a ring, then returns.  The caller
ID (if present) will be returned.

wait_for_dial_tone() - blocks until dial tone detected on port, then returns.

play($files) - plays audio files, playing stops immediately if a DTMF key is 
pressed.  The DTMF key pressed can be read using the event() member function.
If $ctport->event() is already defined it returns immediately.  Any digits
pressed while playing will be added to the digit buffer.

Filename extensions:

=over 4

=item *

default is .au, can be redefined by calling set_def_ext()

=item *

override default by providing extension, e.g. $ctport->play("hello.wav");

=back

Searches for file in:

=over 4

=item *

paths defined by set_path() method

=item *

current dir

=item *

"prompts" sub dir (relative to current dir)

=item *

full path supplied by caller

=item *

/var/ctserver/UsMEng

=back

You can play multiple files, e.g. 

$ctport->play("Hello World"); 

(assumes you have Hello.au and World.au files available)

You can "speak" a limited vocab, e.g. 

$ctport->play("1 2 3"); 

(see /var/ctserver/UsMEng directory for the list of included files that define
the vocab)

record($file_name, $time_out, $term_keys) - records $file_name for 
$time_out seconds or until any of the digits in $term_keys are pressed.
The path of $file_name is considered absolute if there is a leading /, 
otherwise it is relative to the current directory.

ctsleep($seconds) - blocks for $seconds, unless a DTMF key is pressed in which
case it returns immediately.  If $ctport->event() is already defined it 
returns immediately without sleeping.

clear() - clears any pending events, and clears the DTMF digit buffer.

collect($max_digits, $max_seconds) - returns up to $max_digits by waiting up 
to $max_seconds.  Will return as soon as either $max_digits have been collected
or $max_seconds have elapsed.  On return, the event() method will return
undefined.  

DTMF digits pressed at any time are collected in the digit buffer.  The digit
buffer is cleared by the clear() method.  Thus it is possible for this function
to return immediately if there are already $max_digits in the digit buffer.

dial($number) - Dials a DTMF string.  Valid characters are 1234567890#*,&

=over 4

=item *

, gives a 1 second pause, e.g. $ctport->dial(",,1234) will wait 2 seconds, 
then dial extension 1234.

=item *

& generates a hook flash (used for transfers on many PBXs) e.g. :

$ctport->dial("&,1234) will send a flash, wait one second, then dial 1234. 

=back

number() - returns a string of audio files that enable numbers to be "spoken"

e.g. number() will convert 121 into "one hundred twenty one" 

e.g. ctplay("youhave " . $ctnumber($num_mails) . " mails");

(assumes files youhave.au, mails.au, and variable $num_mails exist)

set_path() - used to set the search path for audio files supplied to play()

get_inter_digit_time_out() - returns the optional inter-digit time out used
with collect().

set_inter_digit_time_out($time_out) - sets the optional inter-digit time out 
used with collect().
