###
# Copyright 1998, 1999 Massachusetts Institute of Technology
# Copyright 2001 Janos Mohacsi
#
# Permission to use, copy, modify, distribute, and sell this software and its
# documentation for any purpose is hereby granted without fee, provided that
# the above copyright notice appear in all copies and that both that
# copyright notice and this permission notice appear in supporting
# documentation.  
# It is provided "as is" without express or implied warranty.

###
# File:		Traceroute6.pm
# Author:	Janos Mohacsi mohacsi@ik.bme.hu
# Original Traceroute.pm Author: Daniel Hagerty, hag@ai.mit.edu
# Date:		Thu Aug 30 19:07:59 CEST 2001
# Description:  Perl traceroute module for performing traceroute6(1)
#		functionality. Most of the code is imported from the 
#               Net::Traceroute perl module. Added to support IPv6 and 
#		IPv6/IPv4 selection. You need Socket6 perl module for 
#		low-level IPv6 support
#

# Currently attempts to parse the output of the system traceroute command,
# which it expects will behave like the standard LBL traceroute program.
# If it doesn't, (Windows, HPUX come to mind) you may lose.
#
# It tries figure out the particular traceroute from the configuration
# and parse it.
#
# The IPv6 traceroute makes the situation worse, becuase no standard systax 
# IPv6 traceroute. Some system prefer separate traceroute (understandable
# since the ICMPv6 error options are so different.
# For IPv6 currently only on some system is known to work:
# *BSD (FreeBSD 4.0 or later, NetBSD 1.5 or later. OpenBSD 2.8 and later) 
# 	+ any KAME patched BSD
# Solaris 8 or later
#
# BUGS: currently only few ICMPv6 error options are recognised.
#
# Changelog:
# Version 0.01 : inital version
# Version 0.02 : Solaris support
# Version 0.03 : removing some debugging information
#
# Has a couple of random useful hooks for child classes to override.

package Net::Traceroute6;

use Config;
use strict;
no strict qw(subs);

#require 5.xxx;			# We'll probably need this

use vars qw(@EXPORT $VERSION @ISA);

use Exporter;
use IO::Pipe;
use IO::Select;
use Socket;
use Socket6;
use Data::Dumper;		# Debugging

$VERSION = "0.03";		# Version number is only incremented by
				# hand.

@ISA = qw(Exporter);

@EXPORT = qw(TRACEROUTE_OK
	     TRACEROUTE_TIMEOUT
	     TRACEROUTE_UNKNOWN
	     TRACEROUTE_BSDBUG
	     TRACEROUTE_UNREACH_NET
	     TRACEROUTE_UNREACH_HOST
	     TRACEROUTE_UNREACH_PROTO
	     TRACEROUTE_UNREACH_NEEDFRAG
	     TRACEROUTE_UNREACH_SRCFAIL
	     TRACEROUTE_UNREACH_ADDR
	     TRACEROUTE_UNREACH_FILTER_PROHIB);

###

## Exported functions.

# Perl's facist mode gets very grumbly if a few things aren't declared
# first.

sub TRACEROUTE_OK { 0 }
sub TRACEROUTE_TIMEOUT { 1 }
sub TRACEROUTE_UNKNOWN { 2 }
sub TRACEROUTE_BSDBUG { 3 }
sub TRACEROUTE_UNREACH_NET { 4 }
sub TRACEROUTE_UNREACH_HOST { 5 }
sub TRACEROUTE_UNREACH_PROTO { 6 }
sub TRACEROUTE_UNREACH_NEEDFRAG { 7 }
sub TRACEROUTE_UNREACH_SRCFAIL { 8 }
sub TRACEROUTE_UNREACH_FILTER_PROHIB { 9 }
sub TRACEROUTE_UNREACH_ADDR { 10 }

## Internal data used throughout the module

# Instance variables that are nothing special, and have an obvious
# corresponding accessor/mutator method.
my @simple_instance_vars = qw(base_port
			      debug
			      host
			      max_ttl
			      queries
			      query_timeout
			      timeout
                              af 
                              host_address);

# Field offsets for query info array
my $query_stat_offset = 0;
my $query_host_offset = 1;
my $query_time_offset = 2;

#real address family if you specify PF_UNSPEC
my $real_af = -1;

# check whether we have IPv6 support;
my $inet6 = defined(eval 'PF_INET6');

###
# Public methods

# Constructor

sub new {
    my $self = shift;
    my $type = ref($self) || $self;

    my %hash = ();

    my %arg = @_;

    my $me = bless \%hash, $type;

    # If we've been called through an object, use that one as a template.
    # Does a shallow copy of the hash key/values to the new hash.
    if(ref($self)) {
	my($key, $val);
	while(($key, $val) = each %{$self}) {
	    $me->{$key} = $val;
	}
    }

    # Take our constructer arguments and initialize the attributes with
    # them.
    my $var;
    foreach $var (@simple_instance_vars)  {
	if(defined($arg{$var})) {
	    $me->$var($arg{$var});
	}
    }

    # Initialize debug if it isn't already.
    $me->debug(0) if(!defined($me->debug));

    $me->debug_print(1, "Running in debug mode\n");

    # Initialize status
    $me->stat(TRACEROUTE_UNKNOWN);

    # Initialize address family
    $me->af(PF_UNSPEC) if (!defined($me->af));


    if(defined($me->host)) {
	$me->traceroute;
    }

    $me->debug_print(9, Dumper($me));

    $me;
}

##
# Methods

# Do the actual work.  Not really a published interface; completely
# useable from the constructor.
sub traceroute {
    my $self = shift;
    my $host = shift || $self->host();
    my $af = shift || $self->af();

    $self->debug_print(1, "Want to perform traceroute for $host on address family $af\n");
    die "No host provided!" unless $host;

    # get socket information for $host for service=0, specified address 
    # family , 
    # should be raw socket type, ICMPv6 protocol (but SOCK_STREAM is the 
    # only working at the moment )
    # and return canonical name

    my @tmp = getaddrinfo($host, 0, $af, SOCK_STREAM, 0, AI_CANONNAME);
    if (scalar(@tmp) >= 5) {
	my($family, $socktype, $protocol, $sin, $canonname)=splice(@tmp, $[, 5);
	my($addr, $port)=getnameinfo($sin, NI_NUMERICHOST |NI_NUMERICSERV);
	
	# print the real information 
    	$self->debug_print(1, "In reality performing traceroute for canonnical name: $canonname adress: $addr on address family $family\n");

    	$self->af($family);
	$self->host_address($addr);

    } else {
	die "No Address for specified host: $host, address family: $af!";
    }


    # Sit in a select loop on the incoming text from traceroute,
    # waiting for a timeout if we need to.  Accumulate the text for
    # parsing later in one fell swoop.

    # Note time
    my $start_time = time();
    my $total_wait = $self->timeout();
    my @this_wait = defined($total_wait) ? ($total_wait) : ();

    my $tr_pipe = $self->_make_pipe();
    my $select = new IO::Select($tr_pipe);

    $self->_zero_text_accumulator();
    $self->_zero_hops();

    my @ready;
  out:
    while( @ready = $select->can_read(@this_wait)) {
	my $fh;
	foreach $fh (@ready) {
	    my $buf;
	    my $len = $fh->read($buf, 2048);

	    die "read error: $!" unless(defined($len));

	    last out if(!$len);	# EOF

	    $self->_text_accumulator($buf);
	}

	# Check for timeout
	my $now = time();
	if(defined($total_wait)) {
	    if($now > ($start_time + $total_wait)) {
		$self->stat(TRACEROUTE_TIMEOUT);
		last out;
	    }
	    $this_wait[0] = ($start_time + $total_wait) - $now;
	}
    }

    $tr_pipe->close();

    # Do the grunt parsing work
    $self->_parse($self->_text_accumulator());

    if($self->stat() != TRACEROUTE_TIMEOUT) {
	$self->stat(TRACEROUTE_OK);
    }

    $self;
}

##
# Accesssor/mutators for ordinary instance variables.  (Read/Write)

sub base_port {
    my $self = shift;
    my $elem = "base_port";

    my $old = $self->{$elem};
    $self->{$elem} = $_[0] if @_;
    return $old;
}

sub debug {
    my $self = shift;
    my $elem = "debug";

    my $old = $self->{$elem};
    $self->{$elem} = $_[0] if @_;
    return $old;
}

sub max_ttl {
    my $self = shift;
    my $elem = "max_ttl";

    my $old = $self->{$elem};
    $self->{$elem} = $_[0] if @_;
    return $old;
}

sub queries {
    my $self = shift;
    my $elem = "queries";

    my $old = $self->{$elem};
    $self->{$elem} = $_[0] if @_;
    return $old;
}

sub query_timeout {
    my $self = shift;
    my $elem = "query_timeout";

    my $old = $self->{$elem};
    $self->{$elem} = $_[0] if @_;
    return $old;
}

sub host {
    my $self = shift;
    my $elem = "host";

    my $old = $self->{$elem};
    $self->{$elem} = $_[0] if @_;
    return $old;
}

sub host_address {
    my $self = shift;
    my $elem = "host_address";

    my $old = $self->{$elem};

    # Internal representation always uses IP address in string form.
    if(@_) {
	$self->{$elem} = $_[0];
    }
    return $old;
}

sub timeout {
    my $self = shift;
    my $elem = "timeout";

    my $old = $self->{$elem};
    $self->{$elem} = $_[0] if @_;
    return $old;
}

sub af {
    my $self = shift;
    my $elem = "af";

    my $old = $self->{$elem};
    if (@_) {
	
    	$self->{$elem} = PF_UNSPEC  if ($_[0]== PF_UNSPEC) ;
    	$self->{$elem} = PF_INET  if ($_[0]== PF_INET) ;
    	$self->{$elem} = PF_INET6 if ($inet6 && ($_[0] == PF_INET6));
    }
    return $old;
}

# Accessor for status of this traceroute object.  Externally read only
# (not enforced).
sub stat {
    my $self = shift;
    my $elem = "stat";

    my $old = $self->{$elem};
    $self->{$elem} = $_[0] if @_;
    return $old;
}

##
# Hop and query functions

sub hops {
    my $self = shift;

    my $hop_ary = $self->{"hops"};

    return() unless $hop_ary;

    return(int(@{$hop_ary}));
}

sub hop_queries {
    my $self = shift;
    my $hop = (shift) - 1;

    $self->{"hops"} && $self->{"hops"}->[$hop] &&
	int(@{$self->{"hops"}->[$hop]});
}

sub found {
    my $self = shift;
    my $hops = $self->hops();

    if($hops) {
	my $host_address = $self->host_address;

	my $last_hop = $self->hop_query_host($hops, 0);
	my $stat = $self->hop_query_stat($hops,  0);

	if( $last_hop eq $host_address &&
	   (($stat == TRACEROUTE_OK) || ($stat == TRACEROUTE_BSDBUG) ||
	    ($stat == TRACEROUTE_UNREACH_PROTO))) {
	    return(1);
	}
    }
    return(undef);
}

sub hop_query_stat {
    _query_accessor_common(@_,$query_stat_offset);
}

sub hop_query_host {
    _query_accessor_common(@_,$query_host_offset);
}

sub hop_query_time {
    _query_accessor_common(@_,$query_time_offset);
}

###
# Various internal methods

# Many of these would be useful to override in a derived class.

# Build and return the pipe that talks to our child traceroute.
sub _make_pipe {
    my $self = shift;

    my @tr_args = $self->_tr_program_name();

    push(@tr_args, $self->_tr_cmd_args());
    push(@tr_args, $self->host_address());

    # XXX we probably shouldn't throw stderr away.
    open(SAVESTDERR, ">&STDERR");
    #open(STDERR, ">/tmp/log");
    open(STDERR, ">/dev/null");

    my $pipe = new IO::Pipe;

    # IO::Pipe is very unhelpful about error catching.  It calls die
    # in the child program, but returns a reasonable looking object in
    # the parent.  This is really a standard unix fork/exec issue, but
    # the library really doesn't help us.
    my $result = $pipe->reader(@tr_args);

    open(STDERR, ">& SAVESTDERR");
    close(SAVESTDERR);

    # XXX We're going to assume that an eof right after fork/exec is
    # actually a failure.  This is quite dubious.
    if($result->eof) {
  	die "No output from traceroute.  Exec failure?";
    }

    $result;
}

# Return the name of the traceroute executable itself
sub _tr_program_name {
    my $self = shift;
    my @args; # collector of arguments
    my $os=$Config{'osname'};
    my $prg_sw;

OSNAMESW: {
    # here comes Solaris
    if ($os = ~ /solaris/) {
	push (@args, "traceroute");
	push (@args, "-A");
    	$prg_sw = ($self->af == PF_INET6) ? "inet6" : "inet";
	push (@args, $prg_sw);
	last OSNAMESW;
    }
    # here comes AIX
    #
    # here comes Tru64 UNIX
    #
    # here comes W2K
    #
    # for the rest we assume traceroute6/traceroute
    
   	$prg_sw = ($self->af == PF_INET6) ? "traceroute6" : "traceroute";
	push (@args, $prg_sw);
	last OSNAMESW;
    }

    @args;
}

# How to map some of the instance variables to command line arguments
my %cmdline_map = ("base_port" => "-p",
		   "max_ttl" => "-m",
		   "queries" => "-q",
		   "query_timeout" => "-w");

# Build a list of command line arguments
sub _tr_cmd_args {
    my $self = shift;

    my @result;

    push(@result, "-n");

    my($key, $flag);
    while(($key, $flag) = each %cmdline_map) {
	my $val = $self->$key();
	if(defined $val) {
	    push(@result, $flag, $val);
	}
    }

    @result;
}

# Map !<Mumble> notation traceroute uses for various icmp packet types
# it may receive.
my %icmp_map = (N => TRACEROUTE_UNREACH_NET,
		H => TRACEROUTE_UNREACH_HOST,
		P => TRACEROUTE_UNREACH_PROTO,
		F => TRACEROUTE_UNREACH_NEEDFRAG,
		S => TRACEROUTE_UNREACH_SRCFAIL,
		A => TRACEROUTE_UNREACH_ADDR,
		X => TRACEROUTE_UNREACH_FILTER_PROHIB);

# Do the grunt work of parsing the output.
sub _parse {
    my $self = shift;
    my $tr_output = shift;

  ttl:
    foreach $_ (split(/\n/, $tr_output)) {

	# Some traceroutes appear to print informational line to stdout,
	# and we don't care.
	/^traceroute to / && next;

	# Each line starts with the ttl (space padded to two characters)
	# and a space.
	/^([0-9 ][0-9]) / || die "Unable to traceroute output: $_";
	my $ttl = $1 + 0;

	my $query = 1;
	my $addr;
	my $time;

	$_ = substr($_,length($&));

	# Munch through the line
      query:
	while($_) {
	    # ip address of a response
	    /^ (\d+\.\d+\.\d+\.\d+)/ && do {
		$addr = $1;
		$_ = substr($_, length($&));
		next query;
	    };
	    # ipv6 address of a response
	    /^ ([0-9a-fA-F:]+)/ && do {
		$addr = $1;
		$_ = substr($_, length($&));
		next query;
	    };
	    # round trip time of query
	    /^  ([0-9.]+) ms/ && do {
		$time = $1 + 0;

		$self->_add_hop_query($ttl, $query,
				     TRACEROUTE_OK, $addr, $time);
		$query++;
		$_ = substr($_, length($&));
		next query;
	    };
	    # query timed out
	    /^ +\*/ && do {
		$self->_add_hop_query($ttl, $query,
				     TRACEROUTE_TIMEOUT,
				     inet_ntoa(INADDR_NONE), 0);
		$query++;
		$_ = substr($_, length($&));
		next query;
	    };
	    # extra information from the probe (random ICMP info
	    # and such).
	    /^ (![NHPFSAX]?|!<\d+>)/ && do {
		my $flag = $1;
		my $matchlen = length($&);

		# Flip the counter back one;  this flag only appears
		# optionally and by now we've already incremented the
		# query counter.
		my $query = $query - 1;

		if($flag =~ /^!<\d>$/) {
		    $self->_change_hop_query_stat($ttl, $query,
						 TRACEROUTE_UNKNOWN);
		} elsif($flag =~ /^!$/) {
		    $self->_change_hop_query_stat($ttl, $query,
						 TRACEROUTE_BSDBUG);
		} elsif($flag =~ /^!([NHPFSAX])$/) {
		    my $icmp = $1;

		    # Shouldn't happen
		    die "Unable to traceroute output (flag $icmp)!"
			unless(defined($icmp_map{$icmp}));

		    $self->_change_hop_query_stat($ttl, $query,
						 $icmp_map{$icmp});
		}
		$_ = substr($_, $matchlen);
		next query;
	    };
	    # Nothing left, next line.
	    /^$/ && do {
		next ttl;
	    };
	    # Some LBL derived traceroutes print ttl stuff
	    /^ \(ttl ?= ?\d+!\)/ && do {
		$_ = substr($_, length($&));
		next query;
	    };

	    die "Unable to parse traceroute output: $_";
	}
    }
}

sub _text_accumulator {
    my $self = shift;
    my $elem = "_text_accumulator";

    my $old = $self->{$elem};
    $self->{$elem} .= $_[0] if @_;
    return $old;
}

sub _zero_text_accumulator {
    my $self = shift;
    my $elem = "_text_accumulator";

    delete $self->{$elem};
}

# Hop stuff
sub _zero_hops {
    my $self = shift;

    delete $self->{"hops"};
}

sub _add_hop_query {
    my $self = shift;

    my $hop = (shift) - 1;
    my $query = (shift) - 1;

    my $stat = shift;
    my $host = shift;
    my $time = shift;

    $self->{"hops"}->[$hop]->[$query] = [ $stat, $host, $time ];
}

sub _change_hop_query_stat {
    my $self = shift;

    # Zero base these
    my $hop = (shift) - 1;
    my $query = (shift) - 1;

    my $stat = shift;

    $self->{"hops"}->[$hop]->[$query]->[ $query_stat_offset ] = $stat;
}

sub _query_accessor_common {
    my $self = shift;

    # Zero base these
    my $hop = (shift) - 1;
    my $query = (shift) - 1;

    my $which_one = shift;

    # Deal with wildcard
    if($query == -1) {
	my $query_stat;

	my $aref;
      query:
	foreach $aref (@{$self->{"hops"}->[$hop]}) {
	    $query_stat = $aref->[$query_stat_offset];
	    $query_stat == TRACEROUTE_TIMEOUT && do { next query };
	    $query_stat == TRACEROUTE_UNKNOWN && do { next query };
	    do { return $aref->[$which_one] };
	}
	return undef;
    } else {
	$self->{"hops"}->[$hop]->[$query]->[$which_one];
    }
}

sub debug_print {
    my $self = shift;
    my $level = shift;
    my $fmtstring = shift;

    return unless $self->debug() >= $level;

    my($package, $filename, $line, $subroutine,
       $hasargs, $wantarray, $evaltext, $is_require) = caller(0);

    my $caller_line = $line;
    my $caller_name = $subroutine;
    my $caller_file = $filename;

    my $string = sprintf($fmtstring, @_);

    my $caller = "${caller_file}:${caller_name}:${caller_line}";

    print STDERR "$caller: $string";
}

1;

__END__

=head1 NAME

Net::Traceroute6 - traceroute(1)/traceroute6(1) functionality in perl

=head1 SYNOPSIS

    use Socket6;
    use Net::Traceroute6;
    $tr = Net::Traceroute6->new(host=> "hydra6.ik.bme.hu");
    if($tr->found) {
	my $hops = $tr->hops;
	if($hops > 1) {
	    print "Router was " .
		$tr->hop_query_host($tr->hops - 1, 0) . "\n";
	}
    }

=head1 DESCRIPTION

This module implements traceroute(1)/traceroute6(1) functionality for perl5.  It
allows you to trace the path IP packets take to a destination.  It is
currently implemented as a parser around the system traceroute
command.

=head1 OVERVIEW

A new Net::Traceroute6 object must be created with the I<new> method.
Depending on exactly how the constructor is invoked, it may perform
the traceroute immediately, or it may return a "template" object that
can be used to set parameters for several subsequent traceroutes.

Methods are available for accessing information about a given
traceroute attempt.  There are also methods that view/modify the
options that are passed to the object's constructor.

To trace a route, UDP packets are sent with a small TTL (time-to-live)
field in an attempt to get intervening routers to generate ICMP
TIME_EXCEEDED messages.

=head1 CONSTRUCTOR

    $obj = Net::Traceroute6->new([base_port	=> $base_port,]
				[debug		=> $debuglvl,]
				[max_ttl	=> $max_ttl,]
				[host		=> $host,]
				[queries	=> $queries,]
				[query_timeout	=> $query_timeout,]
				[af	        => $address_family,]
				[timeout	=> $timeout,]);
    $frob = $obj->new([options]);

This is the constructor for a new Net::Traceroute6 object.  If given
C<host>, it will actually perform the traceroute; otherwise it will return
an empty template object.  This can be used to setup a template object
with some preset defaults for firing off multiple traceroutes.

Given an existing Net::Traceroute object $obj as a template, you can
call $obj->new() with the usual parameters.  The same rules apply
about defining host; that is, traceroute will be run if it is defined.
You can always pass host => undef in the constructor call.

To use a template objects to perform a traceroute, you invoke new on
it and pass a host option.

Possible options are:

B<host> - A host to traceroute to.  If you don't set this, you get a
Traceroute object with no traceroute data in it.  The module always
uses IP addresses internally and will attempt to lookup host names via
inet_aton.

B<base_port> - Base port number to use for the UDP queries.
Traceroute assumes that nothing is listening to port C<base_port> to
C<base_port + (nhops - 1)>
where nhops is the number of hops required to reach the destination
address.  Default is what the system traceroute uses (normally 33434).
C<Traceroute>'s C<-p> option.

B<debuglvl> - A number indicating how verbose debug information should
be.  Please include debug=>9 output in bug reports.

B<max_ttl> - Maximum number of hops to try before giving up.  Default
is what the system traceroute uses (normally 30).  C<Traceroute>'s
C<-m> option.

B<queries> - Number of times to send a query for a given hop.
Defaults to whatever the system traceroute uses (3 for most
traceroutes).  C<Traceroute>'s C<-q> option.

B<query_timeout> - How many seconds to wait for a response to each
query sent.  Uses the system traceroute's default value of 5 if
unspecified.  C<Traceroute>'s C<-w> option.

B<timeout> - Maximum time, in seconds, to wait for the traceroute to
complete.  If not specified, the traceroute will not return until the
host has been reached, or traceroute counts to infinity (C<max_ttl> *
C<queries> * C<query_timeout>).  Note that this option is implemented
by Net::Traceroute, not the underlying traceroute command.

B<address_family> - Which address family to use. Currently supported address 
families: PF_UNSPEC, PF_INET, PF_INET6 (if IPv6 is supported). If PF_UNSPEC 
used the C<host> is specifying the currently used address family. If 
C<host> has both A and AAAA addresses, then you can select the desired 
address family. The default is PF_UNSPEC. The Net::Traceroute6 
automatically select the right traceroute tool.

=head1 METHODS

=head2 Controlling traceroute invocation

Each of these methods return the current value of the option specified
by the corresponding constructor option.  They will set the object's
instance variable to the given value if one is provided.

Changing an instance variable will only affect newly performed
traceroutes.  Setting a different value on a traceroute object that
has already performed a trace has no effect.

See the constructor documentation for information about each
method/constructor option.

=over 4

=item base_port([PORT])

=item max_ttl([PORT])

=item queries([QUERIES])

=item query_timeout([TIMEOUT])

=item host([HOST])

=item timeout([TIMEOUT])

=back

=head2 Obtaining information about a Trace

These methods return information about a traceroute that has already
been performed.

Any of the methods in this section that return a count of something or
want an I<N>th type count to identify something employ one based
counting.

=over 4

=item stat

Returns the status of a given traceroute object.  One of
TRACEROUTE_OK, TRACEROUTE_TIMEOUT, or TRACEROUTE_UNKNOWN (each defined
as an integer).  TRACEROUTE_OK will only be returned if the host was
actually reachable.

=item found

Returns 1 if the host was found, undef otherwise.

=item hops

Returns the number of hops that it took to reach the host.

=item hop_queries(HOP)

Returns the number of queries that were sent for a given hop.  This
should normally be the same for every query.

=item hop_query_stat(HOP, QUERY)

Return the status of the given HOP's QUERY.  The return status can be
one of the following (each of these is actually an integer constant
function defined in Net::Traceroute's export list):

=over 4

=item TRACEROUTE_OK

Reached the host, no problems.

=item TRACEROUTE_TIMEOUT

This query timed out.

=item TRACEROUTE_UNKNOWN

Your guess is as good as mine.  Shouldn't happen too often.

=item TRACEROUTE_UNREACH_NET

This hop returned an ICMP Network Unreachable.

=item TRACEROUTE_UNREACH_HOST

This hop returned an ICMP Host Unreachable.

=item TRACEROUTE_UNREACH_PROTO

This hop returned an ICMP Protocol unreachable.

=item TRACEROUTE_UNREACH_NEEDFRAG

Indicates that you can't reach this host without fragmenting your
packet further.  Shouldn't happen in regular use.

=item TRACEROUTE_UNREACH_SRCFAIL

A source routed packet was rejected for some reason.  Shouldn't happen.

=item TRACEROUTE_UNREACH_FILTER_PROHIB

A firewall or similar device has decreed that your traffic is
disallowed by administrative action.  Suspect sheer, raving paranoia.

=item TRACEROUTE_BSDBUG

The destination machine appears to exhibit the 4.[23]BSD time exceeded
bug.

=back

=item hop_query_host(HOP, QUERY)

Return the dotted quad IP address of the host that responded to HOP's
QUERY.

=item hop_query_time(HOP, QUERY)

Return the round trip time associated with the given HOP's query.  If
your system's traceroute supports fractional second timing, so
will Net::Traceroute.

=back

In the previous methods, you can get the first successfull QUERY parameters, 
if you specify QUERY number as 0.

=head1 BUGS

Net::Traceroute parses the output of the system traceroute command.
As such, it may not work on your system.  Support for more traceroute
outputs (e.g. Windows, HPUX) could be done, although currently the
code assumes there is "One true traceroute".

For IPv6 currently only on some system is known to work:

*BSD (FreeBSD 4.0 or later, NetBSD 1.5 or later. OpenBSD 2.8 and later) 
+ any KAME patched BSD

Solaris 8 or later

Currently only few ICMPv6 error options are recognised.

The actual functionality of traceroute could also be implemented
natively in perl or linked in from a C library.

=head1 SEE ALSO

traceroute(1)
traceroute6(1)

=head1 AUTHOR

Janos Mohacsi <janos.mohacsi@dante.org.uk>
Daniel Hagerty <hag@ai.mit.edu>

=head1 COPYRIGHT

Copyright 1998, 1999 Massachusetts Institute of Technology
Copyright 2001 Janos Mohacsi

=cut
