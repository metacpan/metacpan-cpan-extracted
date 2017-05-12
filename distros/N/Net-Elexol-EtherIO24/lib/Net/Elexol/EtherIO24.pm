# Module for manipulating Elexol Ether I/O 24 units
#
# Copyright (c) 2005 Chris Luke <chrisy@flirble.org>.  All rights
# reserved.  This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
# 
# Feel free to use, modify and redistribute it as long as
# you retain the correct attribution.
# 

package Net::Elexol::EtherIO24;

require 5.8.0;

use warnings;
use strict;

use threads;
use threads::shared;

use Socket;
use IO::Socket::INET;
use IO::Select;
use Time::HiRes;


=head1 NAME

Net::Elexol::EtherIO24 - Threaded object interface for manipulating Elexol Ether I/O 24 units with Perl

=cut

our $VERSION = '0.22';

=head1 VERSION

Version 0.22.

Requires Perl 5.8.0.

=cut

# =============================================================================

=head1 SYNOPSIS

  use Net::Elexol::EtherIO24;

  Net::Elexol::EtherIO24->debug(1);
  my $eio = Net::Elexol::EtherIO24->new(target_addr=>$addr, threaded=>1);

  for my $line (0..23) {
    print "line $line dir: ".$eio->get_line_dir($line)."  ".
          "line $line val: ".$eio->get_line($line)."\n";
  }

  $eio->close;

=head1 DESCRIPTION

The Ether I/O 24 manufactured by Elexol is an inexpensive and simple to
use and operate device designed for remote control or remote sensing.
It has 24 digital lines that are each programmable for input or output and a
variety of other things.

The control protocol is relatively simplistic and UDP based. This Perl
module attempts to abstract this protocol and add other features
along the way. In particular, programmers are encouraged to investigate
setting direct_writes => 0 and direct_reads => 0 in the constructor
for network efficiency (since these are not yet the defaults).

It is thread savvy and will use threads unless told not to. It might perform
adequately without threads, but various functionality would be reduced as
a result. In particular, the module functions in a nice asynchronous
way when it can use threads. Threads support requires Perl 5.8.
This module may not function correctly, or even compile, with an older Perl.
Your Perl will require Threads to be enabled at compile-time, even if you
don't use Threads with this module.

It uses C<IO::Socket::INET> for network I/O and C<Time::HiRes> for timing.
It was developed using Perl on a FreeBSD and a Linux system, but has
been known to function using Perl with Cygwin or ActivePerl on Windows.

=cut

# =============================================================================

my $_debug = 0;
my $_error = 0;

share($_debug);
share($_error);

sub _dbg($$) {
	my $self = shift;
	my $line = shift;
	my $debug = shift;
	return if(!$self->{'debug'});
	$debug = 0 if(!$debug);
	return if($self->{'debug'} < $debug);
	my $pfx = $self->{'debug_prefix'};
	$pfx = 'eio' if(!$pfx);
	$pfx .= ':'.threads->self->tid() if($self->{'threaded'});
	print STDERR $pfx.': '.$line."\n";
}


# =============================================================================

=head1 CONSTRUCTOR

=over 4

=item I<new(args, ...)>

Creates a new C<Net::Elexol::EtherIO24> object complete with associated
socket and any necessary threads (if enabled). Returns undef if
this is not possible, whereupon the application can check
C<< Net::Elexol::EtherIO24->error() >> for any relevant error string.

Arguments are given in C<< key => value >> form from these candidates:

=over 4

=item I<target_addr>

Address or hostname of the device to communicate with. B<Mandatory>.

=item I<target_port>

UDP port number to communicate on. Defaults to '2424'.

=item I<prefetch_status>

Indicates that the current status and configuration of ports on
the device should be immediately fetched. Defaults to '1', which
enables this feature.

=item I<presend_status>

Indicates that the initial state should be immediately sent to the
device. This would set all lines to inputs with no pullups and
threshold set to TTL levels. If at some point we add a way to pre-set
this status, then this feature might become useful!

=item I<threaded>

Enables Perl ithreads and creates a thread to listen to replies from the
EtherIO24 unit. This currently requires Perl 5.8 to function. For the
most part, client applications do not need to be thread aware, but some
functionality may change this assumption. Defaults to '1'.

=item I<recv_timeout>, I<service_recv_timeout>, I<service_status_fetch>

These values control various timers and are unlikely to need any
tweaking. However: recv_timeout is the time recv_result will hang around
waiting for an answer. service_recv_timeout is the timer used in the
packet receiver thread, when threading, to wait for packets before 
seeing if there's anything else to do. service_status_fetch is how
often in that same thread we fire off a call to the status_fetch
method, just to keep our status up-to-date, just in case. These
timers are all integer seconds.

I<recv_timeout> defaults to '1.0', I<service_recv_timeout> to '1.0' and
I<service_status_fetch> to '60.0'.

=item I<direct_writes>, I<direct_reads>

These values, which default to '1' (on) control whether the various
line_ methods directly query/update the Elexol device or whether they
cache data and send/fetch the data to/fom the Elexol device periodically.

The latter method (a setting of '0') can cause less network traffic if you
are constantly polling the device at the expense of a marginally longer interval 
before the device is polled.  However, you must call the I<indirect_write_send>
method in order to push out writes quickly, or especially if you are not
using threads.

By default, if the I<close> method is called any pending writes are sent
(See I<flush_writes_at_close> below).

If data is received that would overwrite a pending write then any pending
writes are sent.

=item I<indirect_write_interval>

The interval, in seconds, between background writes to the Elexol device.
When not using I<direct_writes>  this is the interval at which updates are
sent.  Defaults to '0.1' (200ms).

=item I<indirect_read_interval>

The interval, in fractional seconds, after which a cached read value from
the Elexol device is considered invalid and must be refetched if that
line group is queried. Defaults to '0.5' (500ms).

=item I<read_before_write>

Defaults to '0'. Forces any "write" functions to "read" the current status
first.  However, if I<indirect_reads> is '0', it will used the cached value
if it has not yet expired.

It should be noted that this is very risky since collisions will occur if
two such agents attempt to write to the same group of lines at
approximately the same time.

=item I<debug>, I<debug_prefix>

Controls debugging output. Default value of I<$debug> is inherited from the parent
object (if you set it with C<Net::Elexol::EtherIO24::debug(1)> before cloning
it).

I<$debug_prefix> is displayed at the start of all debug output and defaults to
'eio24'. You can set this, for example, if you have more than one EtherIO24 object
so you can differentiate the debugging output of each.

See also the C<debug> method. Also note that when using threads, the thread ID
that produced the debugging output is included after the prefix.

=item I<flush_writes_at_close>

Defaults to '1', on. Determines whether the I<indirect_write_send> method is
called at I<close> to flush any pending writes.

=item I<eeprom_read_retries>

Number of attempts to read an eeprom location, if it times out. Defaults to '2'.

=item I<async_status_sub>

By default this is not defined. The developer can pass in a reference to a
subroutine that will be called after new status information is received from
the Elexol device.

Such new status includes both the response to a status query, or unsolicited
updates from the autoscan feature.

The subroutine is passed four parameters:

	$fn($data, $key, $new_value, $old_value)

I<$data> is the $data hash used to store information by the object, and which
can optionally be passed in at object creation time (see below).

I<$key> is the index into $data that was updated with new status information.
This will be in the form "TYPE GROUP" where TYPE is one of "status", "dir",
"pullup", "thresh" and GROUP is one of "A", "B", or "C".

I<$new_value> is the value just received.

I<$old_value> is the previous value.

=item I<wakeup>

If true then we will attempt to wakeup the module at initialisation. See the
'wakeup' method for details.

=item I<data>

Various state information is contained within a hash. If not given, one
is created and used anonymously. However, the application can pass in
a reference to a hash here, for instance to identify this object to an
async callback subroutine.

Many of the items in this hash are C<threads::shared> when we are threading.

Developers should prefix their own elements in this hash with a '_'
character to ensure uniqueness from those added by this module.

=back

=back

=cut

sub new {
	my $proto = shift;
	my %arg = @_;

	my $class = ref($proto) || $proto;
	my $self = {};

	if(!$arg{'target_addr'}) {
		$_error = "No target_addr specified";
		return undef;
	}

	# It's worth noting that when threading, our backround servicing
	# thread only sees the values of these things as they were at the
	# time the thread started. Anything that changes needs to go into
	# $self->{'data'} and be share()'ed. The best place to initialise
	# such a thing is in init_state() further down.

	$self->{'debug'} = $_debug;
	$self->{'debug_prefix'} = 'eio24';
	$self->{'target_port'} = '2424';
	$self->{'prefetch_status'} = 1;
	$self->{'presend_status'} = 0;
	$self->{'threaded'} = 1;
	$self->{'recv_timeout'} = 1.0;
	$self->{'service_recv_timeout'} = 1.0;
	$self->{'service_status_fetch'} = 60;
	$self->{'direct_writes'} = 1;
	$self->{'direct_reads'} = 1;
	$self->{'indirect_write_interval'} = 0.1;
	$self->{'indirect_read_interval'} = 0.5;
	$self->{'read_before_write'} = 0;
	$self->{'flush_writes_at_close'} = 1;
	$self->{'eeprom_read_retries'} = 2;
	$self->{'async_status_sub'} = undef;

	$self->{'socket'} = undef;
	$self->{'thread_indirect'} = undef;
	$self->{'thread_status'} = undef;
	$self->{'thread_recv'} = undef;

	foreach my $field (('debug', 'debug_prefix',
			'target_addr', 'target_port',
			'prefetch_status', 'presend_status', 'threaded', 'recv_timeout',
			'service_recv_timeout', 'service_status_fetch',
			'direct_writes', 'direct_reads',
			'indirect_write_interval', 'indirect_read_interval',
			'read_before_write', 'flush_writes_at_close', 'eeprom_read_retries',
			'async_status_sub', 'wakeup', )) {
		$self->{$field} = $arg{$field} if(defined($arg{$field}));
	}

	# Bless me...
	bless($self, $class);

	# Things relating to the state of the IO24 module
	$self->{'data'} = {};
	if($arg{'data'}) {
		$self->{'data'} = $arg{'data'};
	}

	_init_state($self);

	$self->wakeup if($arg{'wakeup'});

	$self->{'socket'} = IO::Socket::INET->new(
			PeerAddr =>	$self->{'target_addr'},
			PeerPort =>	$self->{'target_port'},
			Proto =>	'udp',
			ReuseAddr =>	1,
	);
	if(!$self->{'socket'}) {
		$_error = "Net::Elexol::EtherIO24->new can't create socket: $@\n";
		return undef;
	}

	if($self->{'threaded'}) {
		$self->_dbg("we're going to be using threads, starting service threads...", 1);
		$self->{'thread_indirect'} = threads->new(\&_service_indirect, $self);
		$self->{'thread_status'} = threads->new(\&_service_status, $self);
		$self->{'thread_recv'} = threads->new(\&_service_recv, $self);
	}

	if($self->{'prefetch_status'}) {
		if(!$self->status_fetch) {
			$self->close;
			$_error .= ' while prefetching status';
			return undef;
		}
		if(!$self->eeprom_fetch) {
			$self->close;
			$_error .= ' while prefetching eeprom contents';
			return undef;
		}
	}
	$self->status_send() if($self->{'presend_status'});
	$self->{'parent'} = 1;

	return $self;
}

# Until we can reliably detect the one and only useful call to this, 
# we need to comment out DESTROY. It's called too many times when a
# thread ends and runtime values like 'running' don't seem to keep up!
# Net effect: Applications MUST call 'close'.

#DESTROY {
#	my $self = shift;
#	$self->close if($self->{'parent'});
#	$self->SUPER::DESTROY if($self->can("SUPER::DESTROY"));
#}

=head1 METHODS

=over 4

=item I<close>

Closes network resources and waits (briefly) for any running threads to end. Should
be called when the host application is ending or when the object is no longer needed.

The object destructor will attempt to call this function when the world ends, but Perl
might not be patient enough to wait for threads to end by that time.

=cut

sub close {
	my $self = shift;

	return if(!$self->{'parent'});
	return if(!$self->{'data'}->{'running'});

	$self->_dbg("close called, shutting down...", 1);

	$self->indirect_write_send if($self->{'flush_writes_at_close'});  # flush anything pending

	{ lock($self->{'data'}->{'running'}); $self->{'data'}->{'running'} = 0; } # should signal threads to exit

	if($self->{'threaded'}) {
		foreach my $tname (('indirect', 'status', 'recv')) {
			my $t = $self->{'thread_'.$tname};
			if($t) {
				$self->_dbg("waiting for thread '$tname' (id ".$t->tid().") to stop", 1);
				$t->join;
				$self->{'thread_'.$tname} = undef;
			}
		}
	}

	if($self->{'socket'}) {
		$self->{'socket'}->close;
		$self->{'socket'} = undef;
	}
}

=item I<wakeup>

Send a handful of UDP packets to the device to 'wake it up'. The intention
is to trigger MAC address resolution before we send any real packets to it.

This method creates and closes its own socket so it does not interfere with
other threads.

It is called at initialisation if you pass 'wakeup' into the constructor.

=cut

sub wakeup {
	my $self = shift;
	my %arg = @_;

	$self->_dbg("Attempting to wakeup module at ".$self->{'target_addr'}.":".$self->{'target_port'}, 1);

	my $s = IO::Socket::INET->new(
			PeerAddr =>	$self->{'target_addr'},
			PeerPort =>	$self->{'target_port'},
			Proto =>	'udp',
			ReuseAddr =>	1,
	);
	if(!$s) {
		$_error = "Net::Elexol::EtherIO24->wakeup can't create socket for wakeup: $@\n";
		return undef;
	}

	# Send a couple of simple packets to the device.
	$s->send('IO24');
	$s->send('IO24');
	$s->send('IO24');
	$s->send('IO24');

	# Wait briefly - enough time for MAC resolution to occur.
	Time::HiRes::usleep(250000);

	# TODO: Detect if the module was woken up or not. :)

	# Move on.
	$s->close;

	return 1;
}

sub _service_indirect {
	my $self = shift;
	
	$self->_dbg("service_indirect starting up", 1);

	my $indirect_time = Time::HiRes::time() + $self->{'indirect_write_interval'};

	while($self->{'data'}->{'running'}) {
		if($self->{'indirect_write_interval'} && $indirect_time < Time::HiRes::time()) {
			$indirect_time = Time::HiRes::time() + $self->{'indirect_write_interval'};
			$self->indirect_write_send;
		} else {
			Time::HiRes::usleep(1000000);
		}
	}

	$self->_dbg("service_indirect shutting down", 1);
}

sub _service_status {
	my $self = shift;

	$self->_dbg("service_status starting up", 1);

	my $status_time = Time::HiRes::time() + $self->{'service_status_fetch'};

	while($self->{'data'}->{'running'}) {
		if($self->{'service_status_fetch'} && $status_time < Time::HiRes::time()) {
			$status_time = Time::HiRes::time() + $self->{'service_status_fetch'};
			# 0=don't recv_result, which would cause a deadlock
			$self->status_fetch(0);
		} else {
			Time::HiRes::usleep(1000000);
		}

	}

	$self->_dbg("service_status shutting down", 1);
}

sub _service_recv {
	my $self = shift;

	$self->_dbg("service_recv starting up", 1);

	while($self->{'data'}->{'running'}) {
		$self->recv_command;
	}

	$self->_dbg("service_recv shutting down", 1);
}

=item I<debug($level)>

The higher $level is, the more debugging is output. "3" is currently the useful
limit, though "4" will enable hex-dumps of all data sent and received.

Can be called on the parent to set default debugging level, and on each object
to control that objects debug level.

=cut

sub debug {
	my $self = shift;
	if(@_) {
		$_debug = shift;
		$self->{'debug'} = $_debug if(ref($self));
	}
	return $_debug;
}

=item I<error>

Returns a string description of the last error, or 0 if no error recorded.

Note that this value is global - it is shared between all EtherIO24 objects
so that you can return an error should C<new()> fail to construct a new object.

=cut

sub error {
	my $self = shift;
	return $_error;
}

=item I<dump_packet($packet, $offset, $increment)>

Returns a string containing a HEX and ASCII dump of the packet in I<$packet>.

This is used in the send/receive routines if a high enough debug level is set and
is provided here in case someone else finds it useful.

I<$offset> is optional and specifies the offset in the packet to start at, defaults to 0.

I<$increment> is optional and specifies how many items to display per line, defaults to 16.

=cut

sub dump_packet {
	my $self = shift;
	my $packet = shift;
	my $offset = shift;
	my $incr = shift;

	my $string = "";

	$offset = 0 if(!defined($offset));
	$incr = 16 if(!defined($incr));

	while($offset < length($packet)) {
		my $l = substr($packet, $offset, $incr);
		my $hexstr = join(' ', map { sprintf "%02.2x", $_ } unpack("C*", $l));
		my $ascstr = $l;
		$ascstr =~ s/[^A-Za-z0-9,:;\-=_+<>?\/\\{}[\]'"`]/./g;
 
		my $hexlen = ($incr*3)-1;
		$string .= sprintf("%04.4d  %-${hexlen}.${hexlen}s  %s\n", $offset, $hexstr, $ascstr);

		$offset += $incr;
	}
	return $string;
}

sub _dbg_packet {
	my $self = shift;
	my $packet = shift;
	my $debug = shift;
	my $offset = shift;
	my $incr = shift;

	return if($self->{'debug'} < $debug);
	my $string = $self->dump_packet($packet, $offset, $incr);
	foreach my $line (split(/\n/, $string)) {
		$self->_dbg($line, $debug);
	}
}

# =============================================================================

my $status_commands = {
	'status A' => 'a',
	'status B' => 'b',
	'status C' => 'c',
	'dir A' => '!a',
	'dir B' => '!b',
	'dir C' => '!c',
	'pullup A' => '@a',
	'pullup B' => '@b',
	'pullup C' => '@c',
	'thresh A' => '#a',
	'thresh B' => '#b',
	'thresh C' => '#c',
	'schmitt A' => '$a',
	'schmitt B' => '$b',
	'schmitt C' => '$c',
};

# reverse mapping of status commands
my $status_map = {};
foreach my $key (keys %$status_commands) {
	$status_map->{$status_commands->{$key}} = $key;
}

my $set_commands = {
	'status A' => 'A',
	'status B' => 'B',
	'status C' => 'C',
	'dir A' => '!A',
	'dir B' => '!B',
	'dir C' => '!C',
	'pullup A' => '@A',
	'pullup B' => '@B',
	'pullup C' => '@C',
	'thresh A' => '#A',
	'thresh B' => '#B',
	'thresh C' => '#C',
	'schmitt A' => '$A',
	'schmitt B' => '$B',
	'schmitt C' => '$C',
};

# reverse mapping of set command
my $set_map = {};
foreach my $key (keys %$set_commands) {
	$set_map->{$set_commands->{$key}} = $key;
}

# What a status query results in
my $cmd_map = {
	'a' => 'A',
	'!a' => '!A',
	'@a' => '@A',
	'#a' => '#A',
	'$a' => '$A',
	'b' => 'B',
	'!b' => '!B',
	'@b' => '@B',
	'#b' => '#B',
	'$b' => '$B',
	'c' => 'C',
	'!c' => '!C',
	'@c' => '@C',
	'#c' => '#C',
	'$c' => '$C',
	'IO24' => 'IO24',
	'%' => '%',
	'`' => '\'',
	'*' => ' ',
	'\'R' => 'R',
};

my $cmd_rev_map = {};
foreach my $key (keys %$cmd_map) {
	$cmd_rev_map->{$cmd_map->{$key}} = $key;
}

my $send_commands = {
	'IO24' => {
		length => 4,
		'desc' => 'ID units',
		},

	'A' => {
		'length' => 2,
		'desc' => 'Wr Port A',
		'type' => 'hex_byte',
		},
	'B' => {
		'length' => 2,
		'desc' => 'Wr Port C',
		'type' => 'hex_byte',
		},
	'C' => {
		'length' => 2,
		'desc' => 'Wr Port C',
		'type' => 'hex_byte',
		},

	'a' => {
		'length' => 1,
		'desc' => 'Rd Port A',
		},
	'b' => {
		'length' => 1,
		'desc' => 'Rd Port B',
		},
	'c' => {
		'length' => 1,
		'desc' => 'Rd Port C',
		},

	'!A' => {
		'length' => 3,
		'desc' => 'Wr Dir A',
		'type' => 'hex_byte',
		},
	'!B' => {
		'length' => 3,
		'desc' => 'Wr Dir B',
		'type' => 'hex_byte',
		},
	'!C' => {
		'length' => 3,
		'desc' => 'Wr Dir C',
		'type' => 'hex_byte',
		},

	'!a' => {
		'length' => 2,
		'desc' => 'Rd Dir A',
		},
	'!b' => {
		'length' => 2,
		'desc' => 'Rd Dir B',
		},
	'!c' => {
		'length' => 2,
		'desc' => 'Rd Dir C',
		},

	'@A' => {
		'length' => 3,
		'desc' => 'Wr Pullup A',
		'type' => 'hex_byte',
		},
	'@B' => {
		'length' => 3,
		'desc' => 'Wr Pullup B',
		'type' => 'hex_byte',
		},
	'@C' => {
		'length' => 3,
		'desc' => 'Wr Pullup C',
		'type' => 'hex_byte',
		},

	'#A' => {
		'length' => 3,
		'desc' => 'Wr Thresh A',
		'type' => 'hex_byte',
		},
	'#B' => {
		'length' => 3,
		'desc' => 'Wr Thresh B',
		'type' => 'hex_byte',
		},
	'#C' => {
		'length' => 3,
		'desc' => 'Wr Thresh C',
		'type' => 'hex_byte',
		},

	'$A' => {
		'length' => 3,
		'desc' => 'Wr Schmitt A',
		'type' => 'hex_byte',
		},
	'$B' => {
		'length' => 3,
		'desc' => 'Wr Schmitt B',
		'type' => 'hex_byte',
		},
	'$C' => {
		'length' => 3,
		'desc' => 'Wr Schmitt C',
		'type' => 'hex_byte',
		},

	'@a' => {
		'length' => 2,
		'desc' => 'Rd Pullup a',
		},
	'@b' => {
		'length' => 2,
		'desc' => 'Rd Pullup b',
		},
	'@c' => {
		'length' => 2,
		'desc' => 'Rd Pullup c',
		},

	'#a' => {
		'length' => 2,
		'desc' => 'Rd Thresh a',
		},
	'#b' => {
		'length' => 2,
		'desc' => 'Rd Thresh b',
		},
	'#c' => {
		'length' => 2,
		'desc' => 'Rd Thresh c',
		},

	'$a' => {
		'length' => 2,
		'desc' => 'Rd Schmitt a',
		},
	'$b' => {
		'length' => 2,
		'desc' => 'Rd Schmitt b',
		},
	'$c' => {
		'length' => 2,
		'desc' => 'Rd Schmitt c',
		},

	'\'R' => {
		'length' => 5,
		'desc' => 'Rd EEPROM word',
		'type' => 'eeprom',
		'nobundle' => 1,
		},
	'\'W' => {
		'length' => 5,
		'desc' => 'Wr EEPROM word',
		'type' => 'eeprom',
		'nobundle' => 1,
		},
	'\'E' => {
		'length' => 5,
		'desc' => 'Erase EEPROM word',
		'type' => 'eeprom',
		'nobundle' => 1,
		},
	'\'0' => {
		'length' => 5,
		'desc' => 'Write disable EEPROM',
		'type' => 'hex_byte',
		'nobundle' => 1,
		},
	'\'1' => {
		'length' => 5,
		'desc' => 'Write enable EEPROM',
		'type' => 'hex_byte',
		'nobundle' => 1,
		},
	'\'@' => {
		'length' => 5,
		'desc' => 'Reset module',
		'type' => 'eeprom',
		'nobundle' => 1,
		},

	'`' => {
		'length' => 2,
		'desc' => 'Echo byte',
		'type' => 'hex_byte',
		},
	'*' => {
		'length' => 1,
		'desc' => 'Echo a space',
		},
	'%' => {
		'length' => 1,
		'desc' => 'Read host data',
		},
};

my $recv_commands = {
	'IO24' => {
		length => 12,
		'desc' => 'ID units',
		'type' => 'io24',
		},

	'A' => {
		'length' => 2,
		'desc' => 'Wr Port A',
		'type' => 'hex_byte',
		},
	'B' => {
		'length' => 2,
		'desc' => 'Wr Port C',
		'type' => 'hex_byte',
		},
	'C' => {
		'length' => 2,
		'desc' => 'Wr Port C',
		'type' => 'hex_byte',
		},

	'!A' => {
		'length' => 3,
		'desc' => 'Wr Dir A',
		'type' => 'hex_byte',
		},
	'!B' => {
		'length' => 3,
		'desc' => 'Wr Dir B',
		'type' => 'hex_byte',
		},
	'!C' => {
		'length' => 3,
		'desc' => 'Wr Dir C',
		'type' => 'hex_byte',
		},

	'@A' => {
		'length' => 3,
		'desc' => 'Wr Pullup A',
		'type' => 'hex_byte',
		},
	'@B' => {
		'length' => 3,
		'desc' => 'Wr Pullup B',
		'type' => 'hex_byte',
		},
	'@C' => {
		'length' => 3,
		'desc' => 'Wr Pullup C',
		'type' => 'hex_byte',
		},

	'#A' => {
		'length' => 3,
		'desc' => 'Wr Thresh A',
		'type' => 'hex_byte',
		},
	'#B' => {
		'length' => 3,
		'desc' => 'Wr Thresh B',
		'type' => 'hex_byte',
		},
	'#C' => {
		'length' => 3,
		'desc' => 'Wr Thresh C',
		'type' => 'hex_byte',
		},

	'$A' => {
		'length' => 3,
		'desc' => 'Wr Schmitt A',
		'type' => 'hex_byte',
		},
	'$B' => {
		'length' => 3,
		'desc' => 'Wr Schmitt B',
		'type' => 'hex_byte',
		},
	'$C' => {
		'length' => 3,
		'desc' => 'Wr Schmitt C',
		'type' => 'hex_byte',
		},

	'R' => {
		'length' => 4,
		'desc' => 'Rd EEPROM word',
		'type' => 'eeprom_recv',
		},

	'\'' => {
		'length' => 2,
		'desc' => 'Echo byte',
		'type' => 'hex_byte',
		},
	' ' => {
		'length' => 1,
		'desc' => 'Echo a space',
		},
	'%' => {
		'length' => 16,
		'desc' => 'Read host data',
		'type' => 'host_data',
		},
};

# =============================================================================

sub _init_state {
	my $self = shift;
	my $data = $self->{'data'};

	$data->{'running'} = 1;
	share($data->{'running'});
	$data->{'running'} = 1;

	foreach my $key (keys %$status_commands) {
		$data->{$key} = 0;
		share($data->{$key});
		$data->{'changed '.$key} = 0;
		share($data->{'changed '.$key});
		$data->{'ts '.$key} = 0;
		share($data->{'ts '.$key});
	}
	foreach my $addr (0..63) {
		$data->{'rcvd eeprom '.$addr} = 0;
		share($data->{'rcvd eeprom '.$addr});
		$data->{'eeprom '.$addr} = 0;
		share($data->{'eeprom '.$addr});
	}
	foreach my $cmd (keys %$cmd_map) {
		$data->{'rcvd '.$cmd_map->{$cmd}} = 1;
		share($data->{'rcvd '.$cmd_map->{$cmd}});
		$data->{'rcvdcmd '.$cmd_map->{$cmd}} = 0;
		share($data->{'rcvdcmd '.$cmd_map->{$cmd}});
	}

	foreach my $var ((
			'last_status_fetch',
			'last_status_send',
			'last_eeprom_fetch')) {
		$data->{$var} = 0;
		share($data->{$var});
	}
}

=item I<clear_cache>

Resets the timestamps on all cached data forcing the next read
to query the Elexol device.

=cut

sub clear_cache {
	my $self = shift;
	my $data = $self->{'data'};

	foreach my $key (keys %$status_commands) {
		$data->{'ts '.$key} = 0;
	}
}

=item I<eeprom_fetch($recv=1, $fetchall=0)>

Fetch the contents of the eeprom. If recv is 1 then it will wait
for the results to arrive, otherwise it returns immediately.

Additionally gets all the reserved and user space words if $fetchall is 1.

Returns 1 on success, 0 on failure.

=cut

sub eeprom_fetch {
	my $self = shift;
	my $recv = shift || 1;
	my $fetchall = shift || 0;

	my $last = 24;
	$last = 63 if($fetchall);

	foreach my $addr (0..$last) {
		if(!$self->read_eeprom($addr)) {
			return 0;
		}
	}
	$self->{'data'}->{'last_eeprom_fetch'} = time();
	return 1;
}

=item I<status_fetch($recv)>

Query the EtherIO24 for its current status. This will store
the current status of all I/O lines and their programmed
settings. If you don't intend to reset these settings then
this is important in order for the Net::Elexol::EtherIO24 to be
able to manipulate I/O lines on a per-bit basis.

If recv is 1 then it will wait
for the results to arrive, otherwise it returns immediately.

Returns 1 on success, 0 on failure.

=cut

sub status_fetch {
	my $self = shift;
	my $recv = shift;

	# Issue "read" commands and issue a read_command.
	# We can ignore the response since status-responses
	# will get updated in our state automagically.
	my $cmd;
	foreach my $key (sort keys %$status_commands) {
		$cmd .= $status_commands->{$key};
	}
	if(!send_command($self, $cmd)) {
		$self->_dbg("WARNING: Unable to send status request.", 0);
		return 0;
	} else {
		if($recv && !recv_result($self, $cmd)) {
			$self->_dbg("WARNING: Error receiving status reply ($_error)", 0);
			return 0;
		}
	}
	$self->{'data'}->{'last_status_fetch'} = time();
	return 1;
}

=item I<status_send>

Send all current status to the EtherIO24.

Returns 1 on success, 0 on failure.

=cut

sub status_send {
	my $self = shift;

	# Issue a series of write commands.
	my $cmd = '';
	foreach my $key (sort keys %$set_commands) {
		$cmd .= $set_commands->{$key}.pack("C", $self->{$key});
	}
	if(!send_command($self, $cmd)) {
		$self->_dbg("WARNING: Unable to send status.", 0);
		return 0;
	}
	$self->{'data'}->{'last_status_send'} = time();
}


=item I<indirect_write_send()>

This method performs various background tasks such as sending any updates to
the Elexol device that are pending and retrieving status from the device.

It should be called periodically (often) if you are not using threads; otherwise
it is not necessary (but not harmful) to call this.

=cut

sub indirect_write_send {
	my $self = shift;

	my $data = $self->{'data'};

	# Send out any pending writes.

	$self->_dbg("indirect_write_send: checking for pending writes", 5);

	foreach my $key (sort keys %$status_commands) {  # sorting this means "dir" is written before "status" - important
		if($data->{'changed '.$key}) {
			$self->_dbg("indirect_write_send: \"$key\" is pending write...", 4);
			send_command($self, $set_commands->{$key}.pack("C", $data->{$key}));
			$data->{'changed '.$key} = 0;
		}
	}
}

# =============================================================================

sub _decode_cmd {
	my $cmd = shift;
	my $len = shift;
	my $type = shift;

	my $txt = '';
	$type = 0 if(!$type);
	if($type eq 'hex_byte') {
		# dump non-cmd chars as hex bytes
		foreach my $i ($len..length($cmd)-1) {
			$txt .= sprintf("%02.2x ", unpack("x$i C1", $cmd));
		}
	} elsif($type eq 'eeprom') {
		my($addr, $msb, $lsb) = unpack("x2 CCC", $cmd);
		$txt = sprintf("addr: %d (0x%02.2x) val: %02.2x %02.2x",
			$addr, $addr, $msb, $lsb);
	} elsif($type eq 'eeprom_recv') {
		my($addr, $msb, $lsb) = unpack("x CCC", $cmd);
		$txt = sprintf("addr: %d (0x%02.2x) val: %02.2x %02.2x",
			$addr, $addr, $msb, $lsb);
	} elsif($type eq 'host_data') {
		$txt .= sprintf("Serial: %02.2x%02.2x%02.2x ".
				"IP: %d.%d.%d.%d ".
				"MAC: %02.2x:%02.2x:%02.2x:%02.2x:%02.2x:%02.2x",
				unpack("x$len CCCCCCCCCCCCC", $cmd));
	} elsif($type eq 'io24') {
		$txt .= sprintf("MAC: %02.2x:%02.2x:02.2x:02.2x:02.2x:02.2x  ".
				"Fw: %02.2x.$02.2x",
				unpack("x$len CCCCCCCC", $cmd));
	}

	return $txt;
}

sub _find_cmd {
	my $cmd = shift;
	my $cmds = shift;

	foreach my $len (1..length($cmd)) {
		my $c = substr($cmd, 0, $len);
		if($cmds->{$c}) {
			return $c;
		}
	}
	return 0;
}

=item I<verify_send_command($cmd)>

Not normally called directly.

Verify commands to be sent. Returns 1 if the command(s) is(are) valid. Returns
0 if any command is invalid. Will search the entire string given for multiple commands.

Will perform various processing tasks on the command, such as resetting the
"status received" flags for any status fields referenced by the command.

=cut

sub verify_send_command {
	my $self = shift;
	my $cmd = shift;

	my $data = $self->{'data'};
	my $start = 0;
	my $ok = 1;
	while($start < length($cmd) && $ok) {
		my $c = _find_cmd(substr($cmd, $start, 6), $send_commands);
		if($c) {
			# found it!
			my $len = length($c);
			my $chk = substr($cmd, $start, $send_commands->{$c}->{'length'});
			if($self->{'debug'}>1) {
				my $type = $send_commands->{$c}->{'type'};
				my $txt = _decode_cmd($chk, $len, $type);
				$self->_dbg("verify_send_command: cmd \"$c\" -> \"".
					$send_commands->{$c}->{'desc'}."\"".
					($txt ne ''?": $txt":""), 1);
			}
# Hmm, what was this block of code for? It seems to slow things down and occasionaly hang the whole thing!
#			#if($set_map->{$c} && $self->{'threaded'}) {
#			if($cmd_map->{$c} && $self->{'threaded'}) {
#				# block waiting for any outstanding status queries to return
#				# to avoid a race condition
#				#my $f = 'rcvd '.$c;
#				my $f = 'rcvd '.$cmd_map->{$c};
#				my $timeout = time() + $self->{'recv_timeout'};
#				lock($data->{$f});
#				while(!$data->{$f}) {
#					$self->_dbg("verify_send_command: flag snd check data->{$f} = ".$data->{$f}, 2);
#					last if(!cond_timedwait($data->{$f}, $timeout));
#				}
#				$self->_dbg("verify_send_command: flag snd result data->{$f} = ".$data->{$f}, 2);
#				if(!$data->{$f}) {
#					$_error = 'Timeout waiting for outstanding status reply '.
#						'while trying to send new status';
#					$ok = 0;
#					last;
#				}
#
#			}
			if($cmd_map->{$c}) { # reset "received" status for query commands
				my $f = 'rcvd '.$cmd_map->{$c};
				if($cmd_map->{$c} eq 'R') { # save eeprom data
					# eepromness
					my($addr, $msb, $lsb) = unpack("x$len CCC", $chk);
					$f = 'rcvd eeprom '.$addr;
				}
				lock($data->{$f});
				$data->{$f} = 0;
				$self->_dbg("verify_send_command: flag send data->{$f} set to 0", 2);
			}
			$start += $send_commands->{$c}->{'length'};
		} else {
			$self->_dbg("verify_send_command: cmd unknown: \"".substr($cmd, $start, 2)."\"", 1);
			$ok = 0;
			last;
		}
	}

	return $ok;
}

=item I<verify_recv_command($cmd)>

Not normally called directly.

Verify a command is valid and if so, return how many bytes of it form
that valid command or 0 if invalid.

Will perform various tasks on the command, such as updating the stored
status of things referenced in the command. When threading, it also
sends a signal to indicate that new status has arrived, if relevant.

=cut

sub verify_recv_command {
	my $self = shift;
	my $cmd = shift;

	my $data = $self->{'data'};
	my $c = _find_cmd(substr($cmd, 0, 6), $recv_commands);
	if($c) {
		# found it!
		my $len = length($c);
		my $chk = substr($cmd, 0, $recv_commands->{$c}->{'length'});
		if(1 || $self->{'debug'}>1) {  # !!! For some reason, not doing this causes a deadlock
			my $type = $recv_commands->{$c}->{'type'};
			my $txt = _decode_cmd($chk, $len, $type);
			$type = 0 if(!$type);
			$self->_dbg("verify_recv_command: cmd \"$c\" -> \"".
				$recv_commands->{$c}->{'desc'}."\"".
				($txt ne ''?": $txt":""), 1);
		}
		# flag received status
		if($c ne 'R') { # only if not an eeprom
			my $f = 'rcvd '.$c;
			lock($data->{$f});
			$data->{$f} = 1;
			$self->_dbg("verify_recv_command: flag rcvd data->{$f} = 1", 2);
			$data->{'rcvdcmd '.$c} = $chk; # store whole rcvd cmd too
			cond_signal($data->{$f});
		}

		if(defined($set_map->{$c})) { # save new status
			my $k = $set_map->{$c};
			if($data->{'changed '.$k}) {
				# we have a pending write on the same value - flush all pending writes!
				# This does mean that, at least temporarily, we might not reflect our
				# written state correctly, but it will recover on a subsequent read.
				# We don't update the timestamp in this case, to encourage a faster
				# refresh.
				$self->indirect_write_send;
			} else {
				$data->{'ts '.$k} = Time::HiRes::time();
			}
			$data->{'prev '.$k} = $data->{$k};
			$data->{$k} = unpack("x$len C", $cmd);
			$self->_dbg("verify_recv_command: set_map \"$c\" ($k) = ".
				sprintf("%02.2x", $data->{$k}), 2);
			my $fn = $self->{'async_status_sub'};
			if(defined($fn) && ref($fn) eq 'CODE') {
				# call the handler
				$self->_dbg("verify_recv_command: calling async handler", 2);
				&$fn($data, $k, $data->{$k}, $data->{'prev '.$k});
			}
		} elsif($c eq 'R') { # save eeprom data
			# eepromness
			my($addr, $msb, $lsb) = unpack("x$len CCC", $chk);
			$data->{'eeprom '.$addr} = ($msb * 256) + $lsb;
			$self->_dbg("verify_recv_command: eeprom \"$c\" addr $addr = ".
				sprintf("%02.2x %02.2x", $msb, $lsb), 2);

			my $f = 'rcvd eeprom '.$addr;
			lock($data->{$f});
			$data->{$f} = 1;
			$self->_dbg("verify_recv_command: flag rcvd data->{$f} set to 1", 2);
			$data->{'rcvdcmd '.$c} = $chk; # store whole rcvd cmd too
			cond_signal($data->{$f});
		}
		return $recv_commands->{$c}->{'length'};
	}

	$self->_dbg("verify_recv_command: cmd unknown: \"".substr($cmd, 0, 2)."\"", 0);

	return 0;
}

# =============================================================================

=item I<send_command($cmd)>

Send a packet to the EtherIO24 unit. Passes it through verify_send_command
and then to send_pkt.

Returns 0 on failure, or the result of send_pkt otherwise.

=cut

sub send_command {
	my $self = shift;
	my $cmd = shift;

	return 0 if(!verify_send_command($self, $cmd));

	return send_pkt($self, $cmd);
}


=item I<recv_command>

Not normally called directly. See C<recv_result()> instead.

Wait for a packet from the EtherIO24 unit. Returns an array of received commands
upto any point where an invalid command was found in the input. Is NOT
thread-friendly unless used in a particular way!

Received packets are passed through verify_recv_command to parse into
commands and perform any automatic processing on them.

=cut

sub recv_command {
	my $self = shift;

	my $data = $self->{'data'};
	my $cmds = $self->recv_pkt;
	if(!$cmds) {
		return 0;
	}

	my @cmds = ();
	while(length($cmds)) {
		my $len = verify_recv_command($self, $cmds);
		if(!$len) {
			$self->_dbg("recv_command encountered invalid command. Returning ".
				scalar(@cmds)." commands to caller.", 0);
			last;
		}
		push(@cmds, substr($cmds, 0, $len));
		$cmds = substr($cmds, $len);
	}
	$_error = 0;
	return @cmds;
}

=item I<recv_result($cmd)>

Wait for results to arrive. May happen sync or async. Is thread-friendly.

Need to give $cmd for threaded operation so it knows what result in particular to wait for.
Returns undef if there was a problem doing this, such as a timeout waiting for the reply.

Replies with the reply command as received, except when it's an eeprom command and threads
are being used. In this case the actual command returned is an indeterminate recent eeprom
related reply.

=cut

sub recv_result {
	my $self = shift;
	my $cmd = shift; # what we wait for

	my $data = $self->{'data'};
	if($self->{'threaded'}) {
		# wait for our result to arrive
		my $c = _find_cmd($cmd, $send_commands);
		$c = _find_cmd($cmd, $recv_commands) if(!$c);
		$c = $cmd if(!$c);

		if($cmd_map->{$c}) {
			$c = $cmd_map->{$c};
		}
		my $f = 'rcvd '.$c;
		if($c eq 'R') {
			my $len = length(_find_cmd($cmd, $send_commands));
			my($addr, $msb, $lsb) = unpack("x$len CCC", $cmd);
			$f = 'rcvd eeprom '.$addr;
		}

		my $timeout = time() + $self->{'recv_timeout'};
		lock($data->{$f});
		while(!$data->{$f}) {
			$self->_dbg("recv_result: flag check data->{$f} = ".$data->{$f}, 2);
			last if(!cond_timedwait($data->{$f}, $timeout));
		}
		$self->_dbg("recv_result: flag result data->{$f} = ".$data->{$f}, 2);
		if(!$data->{$f}) {
			$_error = 'Timeout waiting for reply';
			return undef;
		}
		if(!defined($data->{'rcvdcmd '.$c})) {
			# eek, strange error
			$_error = 'Data not delivered to main thread.';
			return 0;
		}
		$_error = 0;
		return $data->{'rcvdcmd '.$c};
	}

	# Go-do in realtime
	return recv_command($self);
}

# =============================================================================

=item I<read_eeprom($index, [$index, ...])>

Reads the given eeprom locations. Always waits for the answer.

Returns the count of locations sucessfuly read or 0 on error.

=cut

sub read_eeprom {
	my $self = shift;

	my $count = 0;
	while(@_) {
		my $addr = shift;
		my $cmd = "'R".pack("CCC", $addr, 0, 0);
		my $retries = $self->{'eeprom_read_retries'};
		while($retries) {
			if(!send_command($self, $cmd)) {
				$self->_dbg("WARNING: Unable to send eeprom read request for location $addr.", 0);
				next;
			} else {
				if(!recv_result($self, $cmd)) {
					$retries--;
					if(!$retries) {
						$self->_dbg("ERROR: Timeout waiting for eeprom reply for location $addr.", 0);
					} else {
						$self->_dbg("WARNING: Timeout waiting for eeprom reply for location $addr. Retrying.", 1);
					}
					next;
				} else {
					$count++;
					last;
				}
			}
		}
	}
	return $count;
}

=item I<write_eeprom($index, [$index, ...])>

Write the contents of our local eeprom cache for the given index(es) to the
Elexol device.

It includes a 100ms delay after each write in order to let the eeprom settle.

=cut

sub write_eeprom {
	my $self = shift;
	my $data = $self->{'data'};

	while(@_) {
		my $index = shift;

		my $lsb = $data->{'eeprom '.$index} & 0xff;
		my $msb = ($data->{'eeprom '.$index} >> 8) & 0xff;

		$self->send_command("'W".pack('C*', $index, $msb, $lsb));

		Time::HiRes::usleep(100000); # let it settle
	}
}

=item I<eeprom_write_enable($enable)>

Enables or disables the "write" flag for the eeprom on the Elexol device.

=cut

sub eeprom_write_enable {
	my $self = shift;
	my $enable = shift;

	if($enable) {
		$self->_dbg("Sending eeprom write enable...", 2);
		return $self->send_command("'1" . pack("C*", 0x00, 0xaa, 0x55));  # write enable
	} else {
		$self->_dbg("Sending eeprom write disable...", 2);
		return $self->send_command("'0" . pack("C*", 0x00, 0x00, 0x00));  # write disable
	}
}

# =============================================================================

=item I<send_pkt>

Send a packet over the socket. Not normally called directly.

=cut

sub send_pkt {
	my $self = shift;
	my $pkt = shift;

	my $socket = $self->{'socket'};
	$self->_dbg("send_pkt: Sending ".length($pkt)." bytes", 1);
	$self->_dbg_packet($pkt, 3);
	my $ret = $socket->send($pkt);
	if(!defined($ret) || $ret<=0) {
		$self->_dbg("send_pkt: Unable to send packet: $!", 0);
		return 0;
	}
	return 1;
}

=item I<recv_pkt>

Wait for a packet to come in. Not normally called directly.

=cut

sub recv_pkt {
	my $self = shift;

	my $data = $self->{'data'};
	my $socket = $self->{'socket'};

	# see if anything waits for us
	my @ready = ();
	my $timeout = $self->{'service_recv_timeout'};
	my $sel = new IO::Select($socket);
	@ready = $sel->can_read($timeout);

	foreach my $fh (@ready) {
		if($fh = $socket) {
			# get packet
			my $pkt;
			if(!defined($socket->recv($pkt, 8192))) {
				$_error = "Unable to receive packet: $!";
				$self->_dbg("recv_pkt: Unable to receive packet: $!", 0);
				return 0;
			}
			$self->_dbg("recv_pkt: Received ".length($pkt)." bytes", 1);
			$self->_dbg_packet($pkt, 3);
			$_error = 0;
			return $pkt;
		} else {
			# some other socket issue perhaps
		}
	}
	return 0;
}

# =============================================================================

sub _getgrp {
	my $line = shift;

	my $grp;
	$grp = "A" if($line >= 0 && $line < 8);
	$grp = "B" if($line >= 8 && $line < 16);
	$grp = "C" if($line >= 16 && $line < 24);
	my $bit = $line % 8;

	return ($grp, $bit, (1 << $bit));
}

# =============================================================================

=item I<reboot>

Restarts the module. Needed to make any eeprom changes take affect.

=cut

sub reboot {
	my $self = shift;

	$self->indirect_write_send;

	return $self->send_command("'@".pack('C*', 0x00, 0xaa, 0x55));
}

sub _chkts {
	my $self = shift;
	my $item = shift;

	# Check the timestamp for an item and if in need of a refresh, go
	# refresh it and wait for the result.

	my $data = $self->{'data'};

	my $ts = $data->{'ts '.$item} + $self->{'indirect_read_interval'};
	my $now = Time::HiRes::time();
	if($self->{'direct_reads'} || ($ts < $now)) {
		if($self->{'debug'}>3) {
			if($self->{'direct_reads'}) {
				$self->_dbg("_chts: direct_reads, fetching data...", 3);
			} else {
				$self->_dbg("_chkts: ts for '$item' (ts=$ts now=$now iv=".$self->{'indirect_read_interval'}.") expired, fetching...", 3);
			}
		}
		my $cmd = $status_commands->{$item};
		send_command($self, $cmd);
		recv_result($self, $cmd);
		return 1;
	}
	return 0;
}

=item I<set_line($line, $val)>

Sets the line to boolean val and sends to EtherIO module.

Ignored if line is (believed to be) an input.

=cut

sub set_line {
	my $self = shift;
	my $line = shift;
	my $val = shift;

	return undef if(!defined($line));
	return undef if(!defined($val));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	my $var;
	$var = "dir ".$linegrp;
	if(($data->{$var} & $bitval)) {
		$self->_dbg("set_line: line $line ignored, is input", 1);
		return 0;
	}

	$var = "status ".$linegrp;
	$self->_chkts($var) if($self->{'read_before_write'}); # read (possibly cached) data if we read_before_write
	if($val) {
		$self->_dbg("set_line: line $line set to ON", 1);
		$data->{$var} |= $bitval;
	} else {
		$self->_dbg("set_line: line $line set to OFF", 1);
		$data->{$var} &= ~$bitval;
	}

	if($self->{'direct_writes'}) {
		return send_command($self, $set_commands->{$var}.pack("C", $data->{$var}));
	} else {
		$data->{'changed '.$var} = 1;
		return 1;
	}
}

=item I<get_line_live($line)>

Returns live boolean value of line.

=cut

sub get_line_live {
	my $self = shift;
	my $line = shift;

	return undef if(!defined($line));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	# get live value
	my $var;
	$var = "status ".$linegrp;
	send_command($self, $status_commands->{$var});
	recv_result($self, $status_commands->{$var});

	$var = "status ".$linegrp;
	my $val = (($data->{$var} & $bitval) != 0) + 0;
	$self->_dbg("get_line_live: line $line = ".($val?"ON":"OFF"), 1);
	return $val;
}

=item I<get_line($line)>

Returns the value of the specified I/O line.

If using direct_reads then this method always queries the device. Otherwise
this method uses the cached value, unless expired (See I<indirect_read_interval>
constructor parameter) whereupon it will query the device.

=cut

sub get_line {
	my $self = shift;
	my $line = shift;

	return undef if(!defined($line));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	my $var = "status ".$linegrp;
	$self->_chkts($var); # check timestamp
	my $val = (($data->{$var} & $bitval) != 0) + 0;
	$self->_dbg("get_line: line $line = ".($val?"ON":"OFF"), 1);
	return $val;
}

=item I<set_line_dir($line, $dir)>

Set line direction. 0 = output, 1 = input.

=cut

sub set_line_dir {
	my $self = shift;
	my $line = shift;
	my $dir = shift;

	return undef if(!defined($line));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	my $var;
	$var = "dir ".$linegrp;
	$self->_chkts($var) if($self->{'read_before_write'}); # read (possibly cached) data if we read_before_write
	if($dir) {
		$self->_dbg("set_line_dir: line $line set to ON", 1);
		$data->{$var} |= $bitval;
	} else {
		$self->_dbg("set_line_dir: line $line set to OFF", 1);
		$data->{$var} &= ~$bitval;
	}

	if($self->{'direct_writes'}) {
		return send_command($self, $set_commands->{$var}.pack("C", $data->{$var}));
	} else {
		$data->{'changed '.$var} = 1;
		return 1;
	}
}

=item I<get_line_dir($line)>

Returns direction setting for $line. 0 = output, 1 = input.

See I<get_line> for direct_reads and cachine heuristics.

=cut

sub get_line_dir {
	my $self = shift;
	my $line = shift;

	return undef if(!defined($line));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	my $var;
	$var = "dir ".$linegrp;
	$self->_chkts($var); # check timestamp
	my $val = (($data->{$var} & $bitval) != 0) + 0;
	$self->_dbg("get_line_dir: line $line = ".($val?"IN":"OUT"), 1);
	return $val;
}

=item I<set_line_pullup($line, $pullup)>

Set input line pullup. 0 = pullup off, 1 = pullup on.

=cut

sub set_line_pullup {
	my $self = shift;
	my $line = shift;
	my $pullup = shift;

	return undef if(!defined($line));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	my $var;
	$var = "pullup ".$linegrp;
	$self->_chkts($var) if($self->{'read_before_write'}); # read (possibly cached) data if we read_before_write
	if($pullup) {
		$self->_dbg("set_line_pullup: line $line set to pullup ON", 1);
		$data->{$var} |= $bitval;
	} else {
		$self->_dbg("set_line_pullup: line $line set to pullup OFF", 1);
		$data->{$var} &= ~$bitval;
	}

	if($self->{'direct_writes'}) {
		return send_command($self, $set_commands->{$var}.pack("C", $data->{$var}));
	} else {
		$data->{'changed '.$var} = 1;
		return 1;
	}
}

=item I<get_line_pullup($line)>

Returns pullup setting for $line. 0 = pullup off, 1 = pullup on.

See I<get_line> for direct_reads and cachine heuristics.

=cut

sub get_line_pullup {
	my $self = shift;
	my $line = shift;

	return undef if(!defined($line));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	my $var;
	$var = "pullup ".$linegrp;
	$self->_chkts($var); # check timestamp
	my $val = (($data->{$var} & $bitval) != 0) + 0;
	$self->_dbg("get_line_pullup: line $line = ".($val?"pullup ON":"pullup OFF"), 1);
	return $val;
}

=item I<set_line_thresh($line, $thresh)>

Set line threshhold. 0 = 2.5v (TTL), 1 = 1.4v (CMOS).

=cut

sub set_line_thresh {
	my $self = shift;
	my $line = shift;
	my $thresh = shift;

	return undef if(!defined($line));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	my $var;
	$var = "thresh ".$linegrp;
	$self->_chkts($var) if($self->{'read_before_write'}); # read (possibly cached) data if we read_before_write
	if($thresh) {
		$self->_dbg("set_line_thresh: line $line set to 1.4v (CMOS)", 1);
		$data->{$var} |= $bitval;
	} else {
		$self->_dbg("set_line_thresh: line $line set to 2.5v (TTL)", 1);
		$data->{$var} &= ~$bitval;
	}

	if($self->{'direct_writes'}) {
		return send_command($self, $set_commands->{$var}.pack("C", $data->{$var}));
	} else {
		$data->{'changed '.$var} = 1;
		return 1;
	}
}

=item I<get_line_thresh($line)>

Returns threshold setting for $line. 0 = 2.5v (TTL), 1 = 1.4v (CMOS).

See I<get_line> for direct_reads and cachine heuristics.

=cut

sub get_line_thresh {
	my $self = shift;
	my $line = shift;

	return undef if(!defined($line));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	my $var;
	$var = "thresh ".$linegrp;
	$self->_chkts($var); # check timestamp
	my $val = (($data->{$var} & $bitval) != 0) + 0;
	$self->_dbg("get_line_thresh: line $line = ".($val?"1.4v (CMOS)":"2.5v (TTL)"), 1);
	return $val;
}

=item I<set_line_schmitt($line, $schmitt)>

Set line Schmitt trigger. 0 = off, 1 = on.

=cut

sub set_line_schmitt {
	my $self = shift;
	my $line = shift;
	my $schmitt = shift;

	return undef if(!defined($line));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	my $var;
	$var = "schmitt ".$linegrp;
	$self->_chkts($var) if($self->{'read_before_write'}); # read (possibly cached) data if we read_before_write
	if($schmitt) {
		$self->_dbg("set_line_schmitt: line $line set to ON", 1);
		$data->{$var} |= $bitval;
	} else {
		$self->_dbg("set_line_schmitt: line $line set to OFF", 1);
		$data->{$var} &= ~$bitval;
	}

	if($self->{'direct_writes'}) {
		return send_command($self, $set_commands->{$var}.pack("C", $data->{$var}));
	} else {
		$data->{'changed '.$var} = 1;
		return 1;
	}
}

=item I<get_line_schmitt($line)>

Returns schmitt setting for $line. 0 = off, 1 = on.

See I<get_line> for direct_reads and cachine heuristics.

=cut

sub get_line_schmitt {
	my $self = shift;
	my $line = shift;

	return undef if(!defined($line));
	return undef if($line < 0 || $line > 23);

	my $data = $self->{'data'};

	my ($linegrp, $bitno, $bitval) = _getgrp($line);

	my $var;
	$var = "schmitt ".$linegrp;
	$self->_chkts($var); # check timestamp
	my $val = (($data->{$var} & $bitval) != 0) + 0;
	$self->_dbg("get_line_schmitt: line $line = ".($val?"IN":"OUT"), 1);
	return $val;
}

=item I<set_autoscan_addr($addr, $port)>

Programs an IP address to use for autoscan functions.

$addr is an ASCII string representation of an IP address.
$port is a numeric UDP port number.

If not specified, it will attempt to determine the current
IP address and port of the open UDP socket. This may not be
wholly portable and your mileage may vary. Unix-like platforms
should fare best.

If $addr is a numeric 0 then the autoscan function will be disabled
on the module.

Changes made by this function require a module restart to take effect.

Before making changes to the eeprom, this method always reads in the
current value first.

=cut

sub set_autoscan_addr {
	my $self = shift;
	my $addr = shift;
	my $port = shift;

	# Bit 2 of eeprom word 5 controls autoscan enable
	# Words 22,23 are the autoscan ip addr
	# Word 24 is the autoscan udp port

	my $data = $self->{'data'};

	if(defined($addr) && $addr eq '0') {
		$self->read_eeprom(5); # refresh, just in case
		$data->{'eeprom 5'} |= 4; # add bit 4 to disable autoscan
		$self->write_eeprom(5);

		Time::HiRes::usleep(500000); # let the eeprom settle

		$self->read_eeprom(5); # refresh, one more time

	} else {

		my $sockaddr = $self->{'socket'}->sockname;
		my @s = sockaddr_in($sockaddr);
		if(!$addr) {
			$addr = inet_ntoa($s[1]);
		}
		if(!$port) {
			$port = $s[0];
		}

		$self->_dbg("set_autoscan_addr: set addr to $addr:$port", 1);


		$self->eeprom_write_enable(1);

		my @a = split(/\./, $addr, 4);

		$data->{'eeprom 22'} = ($a[1] << 8) | $a[0];
		$data->{'eeprom 23'} = ($a[3] << 8) | $a[2];
		$data->{'eeprom 24'} = $port;

		my ($w22, $w23, $w24) = ($data->{'eeprom 22'}, $data->{'eeprom 23'}, $data->{'eeprom 24'}); # keep a copy

		$data->{'eeprom 18'} = 4; # 125 scans per second (1000 / 4)

		$self->write_eeprom(18, 22, 23, 24); # write these values out

		$self->read_eeprom(22, 23, 24); # read it back in

		# TODO: verify the written values made it in.

		$self->read_eeprom(5); # refresh, just in case
		$data->{'eeprom 5'} &= ~4; # subtract bit 4 to enable autoscan
		$self->write_eeprom(5);

		$self->read_eeprom(5); # refresh, one more time

		# TODO: verify the flag was set

		$self->eeprom_write_enable(0);
	}
}

=item I<set_autoscan_lines($line => $state, ...)>

Sets the autoscan state of the given lines to the given state.

Where $state = 1, the module will send status changes for $line.

Changes made by this function require a module restart to take effect.

=cut

sub set_autoscan_lines {
	my $self = shift;

	return 0 if(!@_);

	my %args = @_;

	my $data = $self->{'data'};

	$self->read_eeprom(16, 17); # get a fresh copy
	foreach my $line (keys %args) {
		my $state = $args{$line};

		my $bit = $line % 16;
		my $mask = 1 << $bit;

		my $addr;
		$addr = 16 if($line >= 0  && $line <= 15);
		$addr = 17 if($line >= 16 && $line <= 23);

		my $val = $data->{'eeprom '.$addr};
		if($state) {
			$val &= ~$mask;
		} else {
			$val |= $mask;
		}
		$data->{'eeprom '.$addr} = $val;
	}
	$self->write_eeprom(16, 17); # save new version

	return 1;
}

=item I<set_startup_status($state)>

If $state is 1, uses the current status to set the startup status. Details such
as line direction, trigger levels, etc are programmed into the
eeprom. Status from the module is fetched prior to setting
the startup status if not pre-fetched at object creation.

Otherwise, disables startup port status setting.

Changes made by this function require a module restart to take effect.

=cut

sub set_startup_status {
	my $self = shift;
	my $state = shift || 1;

	my $data = $self->{'data'};

	if(!$self->{'prefetch_status'}) {
		$self->status_fetch(1);  # 1=wait for response
		$self->eeprom_fetch(1);  # 1=wait for response
	}

	my $fields = {
		8	=> [ 'status A',  'dir A' ],
		9	=> [ 'pullup A',  'thresh A' ],
		10	=> [ 'dir B',     'schmitt A' ],
		11	=> [ 'thresh B',  'status B' ],
		12	=> [ 'schmitt B', 'pullup B' ],
		13	=> [ 'status C',  'dir C' ],
		14	=> [ 'pullup C',  'thresh C' ],
		15	=> [ 0,           'schmitt C' ],
	};


	$self->read_eeprom(5); # ensure a fresh copy

	if($state) {
		$data->{'eeprom 5'} &= ~2; # subtract bit 1 (value 2) to enable port preset

		foreach my $field (sort { $a <=> $b } keys %$fields) {
			my $arr = $fields->{$field};
			$data->{'eeprom '.$field} = ((@$arr[0]?$data->{@$arr[0]}:0) * 256) + (@$arr[1]?$data->{@$arr[1]}:0);
		}
	} else {
		$data->{'eeprom 5'} |= 2; # add bit 1 (value 2) to enable port preset

		foreach my $field (sort { $a <=> $b } keys %$fields) {
			$data->{'eeprom '.$field} = 0xffff;
		}
	}

	$self->eeprom_write_enable(1);
	$self->write_eeprom(5, sort keys %$fields);
	$self->eeprom_write_enable(0);

	return 1;
}

=back

=head1 NOTE

The author is not in any way affiliated with Elexol, the manufacturer of the device
this Perl module is designed to operate. This module has been developed using only
data available in the public domain.

=head1 SEE ALSO

L<http://www.flirble.org/chrisy/elexol/>, L<http://www.elexol.com/>, L<http://www.elexol.com/Downloads/EtherIO24UM11.pdf>

=head1 AUTHOR

Chris Luke C<< <chrisy@flirble.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-elexol-etherio24@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Elexol-EtherIO24>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005..2008 Chris Luke, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Net::Elexol::EtherIO24

