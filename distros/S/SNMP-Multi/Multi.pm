# $Id: Multi.pm,v 1.5 2003/12/18 02:35:29 toni Exp $
#
# SNMP::Multi -- Perl 5 object-oriented module to simplify SNMP operations
# on multiple simultaneous agents.
#
# Written by Karl "Rat" Schilke for Electric Lightwave, Inc.
# Copyright (c) 2000-2002 Electric Lightwave, all rights reserved.
#
# This software is provided I<``as is''> and without any express or implied
# warranties, including, without limitation, the implied warranties of
# merchantibility and/or fitness for a particular purpose.
#
# This program is free software; you may redistribute it and/or modify it 
# under the same terms as Perl itself.

=pod

=head1 NAME

SNMP::Multi - Perform SNMP operations on multiple hosts simultaneously

=head1 SYNOPSIS

    use SNMP::Multi;

    my $req = SNMP::Multi::VarReq->new (
	nonrepeaters => 1,
	hosts => [ qw/ router1.my.com router2.my.com / ],
	vars  => [ [ 'sysUpTime' ], [ 'ifInOctets' ], [ 'ifOutOctets' ] ],
    );
    die "VarReq: $SNMP::Multi::VarReq::error\n" unless $req;

    my $sm = SNMP::Multi->new (
	Method      => 'bulkwalk',
	MaxSessions => 32,
	PduPacking  => 16,
	Community   => 'public',
	Version     => '2c',
	Timeout     => 5,
	Retries     => 3,
	UseNumeric  => 1,
	# Any additional options for SNMP::Session::new() ...
    )
    or die "$SNMP::Multi::error\n";

    $sm->request($req) or die $sm->error;
    my $resp = $sm->execute() or die "Execute: $SNMP::Multi::error\n";

    print "Got response for ", (join ' ', $resp->hostnames()), "\n";
    for my $host ($resp->hosts()) {

	print "Results for $host: \n";
	for my $result ($host->results()) {
	    if ($result->error()) {
		print "Error with $host: ", $result->error(), "\n";
		next;
	    }

	    print "Values for $host: ", (join ' ', $result->values());
	    for my $varlist ($result->varlists()) {
		print map { "\t" . $_->fmt() . "\n" } @$varlist;
	    }
	    print "\n";
	}
    }


=head1 DESCRIPTION

The SNMP::Multi package provides a mechanism to perform SNMP operations
on several hosts simultaneously.  SNMP::Multi builds on G. Marzot's SNMP
Perl interface to the UC-Davis SNMP libraries, using asynchronous SNMP 
operations to send queries/sets to multiple hosts simultaneously.

Results from all hosts are compiled into a single object, which offers
methods to access the data in aggregate, or broken down by host or the
individual request.

SNMP::Multi supports SNMP GET, SET, GETNEXT, GETBULK and BULKWALK requests.
It also performs PDU packing in order to improve network efficiency, when
packing is possible.


=head1 OPTIONS

The SNMP::Multi constructor takes the following options to control its
behavior.  Any other options are stored and handed to the SNMP::Session
constructor when a new SNMP session is created.  As the behavior of
SNMP::Multi depends upon certain SNMP::Session parameters (i.e. Timeout),
these will be listed below as SNMP::Multi options.  These "overlapped"
options will be passed un-changed to SNMP::Session's constructor.

=item ``Method''

=over 4

Specify one of B<get>, B<set>, B<getnext>, B<getbulk> or B<bulkwalk>.  The
appropriate SNMP request will be made to each host for each set of variables
requested by the user.

This parameter is required.  There is no default value.

=back

=item ``Requests''

=over 4

The SNMP::Multi object may be given a new set of requests via the B<request()>
method, or by passing a reference to an SNMP::Multi::VarReq object into the
constructor.  Any VarReq requests given to the SNMP::Multi object through the
constructor will be overwritten by subsequent calls to SNMP::Multi::request().

This parameter is optional.

=back

=item ``PduPacking''

=over 4

The maximum number of variable requests that will be packed into a single SNMP
request is controlled by the ``PduPacking'' parameter.  PDU packing improves
the efficiency and accuracy of SNMP requests by reducing the number of packets
exchanged.  Setting this variable to '0' will disable PDU packing altogether.
PDU packing is not performed for SNMP GETBULK or BULKWALK requests.

This optional parameter defaults to the value of $SNMP::Multi::pdupacking.

=back

=item ``MaxSessions''

=over 4

This variable controls the maximum number of SNMP sessions that will be kept
open simultaneously.  Setting ``MaxSessions'' higher increases the number of
agents being queried at any time, up to the maximum limit of file descriptors
available to the process.  SNMP::Multi detects "out of resources" conditions
(i.e. EMFILE) and adjusts the number of open connections accordingly.

This optional parameter defaults to the value of $SNMP::Multi::maxsessions.

=back

=item ``Concurrent''

=over 4

The value of ``Concurrent'' limits the number of requests that may be
"in flight" at any time.  It defaults to the value of ``MaxSessions''
(see above).  Setting this value higher may reduce the overall runtime
of the SNMP::Multi request, but will also likely increase network
traffic and congestion (current maintainer has had SNMP::Multi running
smoothly with concurrent set to 512).

This optional parameter defaults to the value of $SNMP::Multi::maxsessions
or the object's 'MaxSessions' parameter.

=back

=item ``GetbulkMax''

=over 4

Sets the default "maxrepetitions" value for SNMP GETBULK and BULKWALK requests.
This value may be overridden on a per-request basis (by specifying the
'maxrepetitions' parameter in the SNMP::Multi::VarReq constructor).

This optional parameter defaults to the value of $SNMP::Multi::getbulkmax.

=back

=item ``ExternalSelect''

=over 4

If ``ExternalSelect'' is specified, the SNMP::Multi's B<execute()> method
will return immediately after dispatching the first volley of SNMP requests.
The caller can then use B<SNMP::select_info()> to get a list of the current
file descriptors for the SNMP sessions, and select() on them.  When one of
the fd's becomes readable, it should be handed to SNMP::reply_cb() to handle
it.

Note that SNMP bulkwalks use the callbacks to dispatch continuing GETBULK
requests.  This causes the file descriptor to be readable, but SNMP::reply_cb()
calls an internal callback in SNMP.xs's bulkwalk implementation, not the
SNMP::Multi handler callback.  When the walk completes, the SNMP::Multi
callback will be called with the specified arguments.

=back

=item ``Retries'' (shared with SNMP::Session)

=over 4

The ``Retries'' options specifies the maximum number of retries for each
SNMP request.  Note that this is the number of retries, not the total number
of attempted requests.

This optional parameter defaults to the value of $SNMP::Multi::maxretries.

=back

=item ``Timeout'' (shared with SNMP::Session)

=over 4

The ``Timeout'' parameter specifies the timeout in seconds between successive
retries for SNMP requests.  The overall runtime for the complete SNMP::Multi
request will be approximately :

	(retries + 1) * timeout

Please note that this is the lower-bound on the time-out.  Without sufficient
resources (especially file descriptors) to optimize the network communications,
completing all requested SNMP operations can take considerably longer.

An over-all timeout may be specified as the optional "timeout" parameter to
the SNMP::Multi's B<execute()> method.

This optional parameter defaults to the value of $SNMP::Multi::timeout.

=back

=item ``Community'' (shared with SNMP::Session)

=over 4

The ``Community'' parameter specifies the SNMP community string to use when
making requests from SNMP agents.  No mechanism exists at this time to 
specify a different community for individual agents.

This optional parameter defaults to the value of $SNMP::Multi::community.

=back

=item ``Version'' (shared with SNMP::Session)

=over 4

The ``Version'' option specifies the SNMP protocol to use with the agents.
Due to the poor error reporting in SNMP v1, it is recommended that SNMP v2c
or v3 be used to communicate with the agents when possible.

This optional parameter defaults to the value of $SNMP::Multi::snmpversion.

=back

=head1 METHODS

The SNMP::Multi object provides several methods for the caller.  In most cases,
only the B<new()>, B<request()>, and B<execute()> methods need to be used.  The
various methods are documented in approximately the order in which they are
normally called.

=item SNMP::Multi::new(...)

=over 4

Create a new instance of an SNMP::Multi object.  See above for a description of
the available constructor options.

=back

=item SNMP::Multi::request( <ref to SNMP::Multi::VarReq> )

=over 4

B<request()> arranges for the set of host/variable requests stored in the
SNMP::Multi::VarReq object to be transferred to the SNMP::Multi object.  This
can also be done in the constructor using the ``requests'' option.

Note that the B<request()> method is not cumulative -- previous requests will
be overwritten by subsequent calls to B<request()>.

=item SNMP::Multi::execute( [timeout] )

=over 4

The B<execute()> function performs the actual work in SNMP::Multi, returning
when all requests have been answered or timed out.  An optional `timeout'
argument to B<execute()> specifies an overall timeout, regardless of the
number and timing of retries.

B<execute()> returns a reference to an SNMP::Multi::Response object.  This
object provides methods to conveniently access the returned data values.

=back

=item SNMP::Multi::error()

=over 4

If an error occurs while SNMP::Multi is executing, the caller may retrieve
a descriptive string describing the error from the B<error()> method.

=back

=item SNMP::Multi::remaining( $req )

=over 4

The B<remaining()> method produces an SNMP::Multi::VarReq that is populated 
with the requests for any un-answered or un-sent request hunks.  This VarReq
may then be passed to another SNMP::Multi object (or the same one).  This
allows an application to loop on timeouts like this:

    my $req = SNMP::Multi::VarReq->new( ... );
    my $sm  = SNMP::Multi->new( ... );
    while ($req) {
	$sm->request($req);
	my $resp = $sm->execute();
	handle_response($resp);

	print "Timeout - retrying" if ($req = $sm->remaining());
    }

You can accumulate remaining requests by passing an already existing
SNMP::Multi::VarReq object as an argument. Remaining requests will
then be added to that object. That allows us to to collect all
remaining ones with ease, while looping over huge number of hosts.

=back

=head1 Building SNMP::Multi::VarReq Requests

SNMP variable requests are composed and passed to the SNMP::Multi object
through an auxiliary class called an B<SNMP::Multi::VarReq>.  This class
simply collects SNMP requests for variables and hosts (and optionally
validates them).

The interface to SNMP::Multi::VarReq is very simple, providing only B<new()>
and B<add()> methods.  They take the following arguments:

    'vars'           => [ list of Varbinds to be requested (REQUIRED) ]
    'hosts'          => [ list of hosts for this variable list ]
    'nonrepeaters'   => [ GETBULK/BULKWALK "nonrepeaters" parameter ]
    'maxrepetitions' => [ GETBULK/BULKWALK "maxrepetitions" parameter ]

Every call to new() or add() must contain a list of SNMP variables.  If the
B<hosts> parameter is not specified, the variable list will be requested from
all hosts currently known by the SNMP::Multi::VarReq object.  If a host list
is given, the variables will be requested only from the named hosts.

Some simple sanity checks can be performed on the VarReq by calling its
B<validate()> method, or by setting $SNMP::Multi::VarReq::autovalidate to 1
before calling the B<new()> method.

An example of building up a complicated request using new() and add():

    Start with:

	$r = SNMP::Multi::VarReq->new(
	    hosts => [ qw/ A B C / ],
	    vars  => [ qw/ 1 2 3 / ]
	);

    to get:

	A: 1 2 3
	B: 1 2 3
	C: 1 2 3

    Now add a var to each host:

	$r->add( vars => [ qw/ 4 / ] );

    to get:

	A: 1 2 3 4
	B: 1 2 3 4
	C: 1 2 3 4

    Add a var to a specific set of hosts:

	$r->add( hosts => [ qw/ A C / ],
		 vars  => [ qw/ 5   / ] );

    to get:

	A: 1 2 3 4 5
	B: 1 2 3 4
	C: 1 2 3 4 5

    Finally, create two new hosts and add a pair of vars to them:

	$r->add( hosts => [ qw/ D E / ],
		 vars =>  [ qw/ 6 7 / ] );

    to get:

	A: 1 2 3 4 5
	B: 1 2 3 4
	C: 1 2 3 4 5
	D: 6 7
	E: 6 7

The SNMP::Multi::VarReq object also provides a B<dump()> method which 
generates a simple dump of the current host/var requests.

=head1 SNMP PDU Packing Features

SNMP::Multi packs SNMP::Varbind requests into larger request "hunks" to reduce
the number of request/response pairs required to complete the SNMP::Multi
request.  This packing is controlled by the SNMP::Multi 'PduPacking' parameter.

For instance, assume your application creates an SNMP::Multi object with a
'PduPacking' value of 3.  SNMP::Multi will pack 5 single SNMP variable 
requests into two distinct requests.  The first request will contain the first
3 variables, the second will get the remaining two variables.

PDU packing is not done for SNMP GETBULK and BULKWALK requests.  The feature
may be disabled by setting the 'PduPacking' parameter to '0'.

=head1 Accessing SNMP Data From Agent Responses

The SNMP::Multi::execute() method returns the responses from the SNMP agents
in an SNMP::Multi::Response object.  This object, indexed by hostname, consists
of per-host response objects (SNMP::Multi::Response::Host's), each of which
contains a list of SNMP::Multi::Result objects.  The Result objects connect
an SNMP::VarList with the error status (if any) from the SNMP request.  An 
entry is only made in the Response object if the SNMP agent returned some 
response to SNMP::Multi.

This is fairly complicated, but the various objects provide accessor methods 
to make access to the SNMP responses simple.  Assume your application is 
structured something like this example source code:

    my $req = SNMP::Multi::VarReq->new( hosts => [...],
                                        vars  => [...] );
    my $sm  = SNMP::Multi->new( ... requests => $req, ... );
    my $response = $sm->execute( $overall_timeout );
    die $sm->error() if $sm->error();

Now the data can be accessed through methods on the objects that make up the 
SNMP::Multi::Response returned by execute().  An SNMP::VarList object is 
returned for each variable requested.  This normalizes the return format 
across all SNMP operations (including bulkwalks).

See the B<SYNOPSIS> section above for an example of how to access the SNMP
data values after calling the execute() method.

=item SNMP::Multi::Response methods

=over 4

=item hostnames()

=over 4

Return a list of the hosts that responded to the SNMP queries made by execute().

=back

=item values()

=over 4

Return all values returned by the SNMP agents, collated into a single list. 
This method can be used when the application is not concerned with which value
was returned by a specific host (i.e. summing up octet counts on router 
interfaces).

=back

=item hosts()

=over 4

Returns a list of SNMP::Multi::Response::Host objects, one per host queried
by the SNMP::Multi::execute() method.

=back

=back

=back

=item SNMP::Multi::Response::Host methods

=over 4

=item hostname()

=over 4

Return the hostname associated with this set of responses.  The reference may
also be stringified to get the hostname :

	print "This is the list of results for $host: \n";

=back

=item values()

=over 4

Return all values received in response to requests made to the associated host. 

=back

=item results()

=over 4

Returns a list of SNMP::Multi::Result objects for this host.  There is one
Result object for each request sent to the SNMP agent on this host.

=back

=back

=item SNMP::Multi::Result methods

The SNMP::Multi::Result object correlates SNMP error information with the 
response to an SNMP request.

=over 4

=item error()

=over 4

Return a printable string describing the error encountered for this variable,
or undef if no error occurred.

=back

=item values()

=over 4

Return a list of the values received for this request.

=back

=item varlists()

=over 4

Return an array of SNMP::VarList objects, one per variable requested in the
SNMP packet.  This format is consistent for all SNMP operations, and is 
required to support bulkwalks (in which the number of returned values per 
variable is not known a priori to the calling application).

=back

=back

=head1 EXAMPLES

A complete example is given in the "SYNOPSIS" section above.

=head1 CAVEATS

The VarList returned for GETBULK requests is "decoded" by SNMP::Multi into an
array of single VarLists, one for each requested variable.  This behavior 
differs from the return from the getbulk() method in the SNMP.pm module, but
is consistent with the return value of SNMP.pm's bulkwalk() method.

Note that the V1 SNMP protocol has very limited error reporting (the agent
returns no values, and the 'errind' is set to the index of the offending
SNMP variable request).  The SNMP::Multi module adjusts the 'errind' index
to indicate which of the variables request requested for a host have failed,
regardless of the number of actual packets exchanged.  This is necessary to
support SNMP::Multi's transparent pdu-packing feature.

SNMP::Multi relies on features added to the SNMP module by Electric
Lightwave, Inc.  These features have been incorporated into UCD-SNMP
releases 4.2 and later.  You must have SNMP 4.2 or later installed
to use this package.

Using SNMP::Multi with large numbers of hosts or large requests may cause
network congestion.  All targets may send PDU's to the originating host
simultaneously, which could cause heavy traffic and/or dropped packets
at the host.  Adjusting the I<Concurrent> and I<PduPacking> variables can
mitigate this problem.

Network congestion may be a serious problem for bulkwalks, due to multiple
packets being exchanged per session.  However, network latency and variable
target response times cause packets in multiple bulkwalk exchanges to become
spread out as the walk progresses.  The initial exchange, however, will always
cause congestion. 

=head1 BUGS

There is no interface to specify a different SNMP community string for a
specific host, although the community is stored on a per-host basis.

=head1 SEE ALSO

L<SNMP>, the NetSNMP homepage at http://www.net-snmp.org/.

=head1 AUTHOR

Karl ("Terminator rAT") Schilke <rat@eli.net>

=head1 CONTRIBUTORS

Joshua Keroes, Todd Caine, Toni Prug <tony@irational.org>

=head1 COPYRIGHT

Developed by Karl "Terminator rAT" Schilke for Electric Lightwave, Inc.
Copyright (c) 2000-2002 Electric Lightwave, Inc.  All rights reserved.

Co-maintained by Toni Prug. 

This software is provided I<``as is''> and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantibility and/or fitness for a particular purpose.

This program is free software; you may redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------------
package SNMP::Multi;
#-----------------------------------------------------------------------------

require 5.005_62;
use strict;
use warnings;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA       = qw(Exporter);
@EXPORT    = qw( );

$VERSION = "2.1";

# Global variables that can be set by the user, used to set defaults for
# unspecified values in constructors, etc.
#
use vars qw/$DEBUGGING $error $timeout $retries $verbose
    $pdupacking $maxsessions $community $snmpversion
    $getbulkmax $fatalwarn $timestamps $usenumeric %_handler/;

$DEBUGGING   = 0;
$error       = undef;		# SNMP::Multi global error (used by new()).
$timeout     = 30;		# SNMP timeout value.
$retries     = 5;		# Maximum number of retries per request
$verbose     = 0;		# Be verbose if non-zero.
$pdupacking  = 16;		# Max number of vars to pack into one PDU
$maxsessions = 16;		# Max SNMP sessions to open.
$community   = 'public';	# Default SNMP community string.
$snmpversion = '2c';		# Default SNMP protocol version number.
$getbulkmax  = 100;		# Default maximum repeaters for GETBULK
$fatalwarn   = 0;		# Croak on non-fatal exceptions (if true).
$timestamps  = 0;		# Add timestamps to received vars
$usenumeric  = 1;		# Don't convert iod's to strings, keep numeric

# Error message "catalog".
my %errors = (
    TIMED_OUT	=> "SNMP::Multi timed out",
);

# Use more user-friendly warning/fatal routines.
use Carp;

# Get system error numbers for checking $!.
use POSIX qw(:errno_h);

# Use ELI-specific SNMP code.  This is necessary for the following features:
#
#   - SNMP::finish() to interrupt SNMP::MainLoop()
#   - SNMP::bulkwalk() to perform bulkwalks
#   - Timestamps on returned Varbinds.
use SNMP;
#$SNMP::dump_packet = 1;

# "Private" state variables used by SNMP::Multi.
%_handler = (
    'set'      => \&_handle_VarList,	# These return a VarList, which must
    'get'      => \&_handle_VarList,	# be converted into an array of single-
    'getnext'  => \&_handle_VarList,	# Varbind VarLists for storage, unlike
    'getbulk'  => \&_handle_VarList,	# the bulkwalk() method.
    'bulkwalk' => \&_handle_AoVarLists,	# Returns array of VarLists already.
);

# "Nag" -- carp or croak depending on $fatalwarn.  The carp() is not reached
# if we call croak() first (sort of an implied "else" there... 8^).
#
sub _nag { croak (@_) if $fatalwarn; carp(@_); }

#------------- SNMP::Multi PUBLIC INTERFACE FUNCTIONS -----------------------
#
# Construct a new SNMP::Multi object and initialize the private metadata for
# the object.
#
sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    my %args = @_;

    my $obj = { };
    bless $obj, $class;

    # Require the object method to be defined and match one of the sending
    # functions in %_handler ...
    #
    unless (defined $args{Method} && exists $_handler{lc $args{Method}}) {
	_nag "Constructor SNMP 'method' must be one of ", 
	     join ', ', (sort keys %_handler);
	return undef;
    }

    # Set up default values if they were not defined by the user.
    #
    $obj->{Method}      = lc $args{Method};
    $obj->{Timeout}     = $args{Timeout}     || $timeout;
    $obj->{Retries}     = $args{Retries}     || $retries;
    $obj->{Verbose}     = $args{Verbose}     || $verbose;
    $obj->{MaxSessions} = $args{MaxSessions} || $maxsessions;
    $obj->{Concurrent}  = $args{Concurrent}  || $obj->{MaxSessions};
    $obj->{Community}   = $args{Community}   || $community;
    $obj->{Version}     = $args{Version}     || $snmpversion;
    $obj->{GetbulkMax}  = $args{GetbulkMax}  || $getbulkmax;
    $obj->{TimeStamp}   = $args{TimeStamp}   || $timestamps;
    $obj->{UseNumeric}  = $args{UseNumeric}  || $usenumeric;

    # Flag case where execute() should return after dispatching the first
    # volley of SNMP requests.  This is useful if you need to do the select
    # and callbacks externally to SNMP::Multi (i.e. when integrating with
    # POE or other select-based frameworks).
    #
    $obj->{ExternalSelect} = $args{ExternalSelect} || 0;

    # Need to handle this carefully -- '0' is a good value for pdupacking.
    $obj->{PduPacking}  = $args{PduPacking};
    $obj->{PduPacking}  = $pdupacking unless defined $obj->{PduPacking};

    $obj->{error}       = undef;	# Overall error.
    $obj->{_remain}     = 0;		# Number of outstanding requests.
    $obj->{_nsessions}  = 0;		# Number of current SNMP sessions
    $obj->{_inflight}   = 0;		# Number of currently pending requests
    $obj->{_hosts}      = { };		# Per-host context, hashed by name
    $obj->{_sessions}   = { };		# Per-host SNMP session objects.

    # Fix some minor stuff.
    $obj->{Version} =~ s/^v//;	# Remove 'v' from 'v2c', etc.

    # Initialize the object's request list, if a VarReq was passed in.
    # If the method fails, copy the object's error field to the SNMP::Multi
    # global error variable -- the object is destroyed before the caller
    # could see the error message otherwise.  $obj->request() will create
    # an empty SNMP::Multi::Response for us.
    #
    if (exists $args{Requests}) {
	unless (defined $obj->request($args{Requests})) {
	    $error = $obj->error();
	    return undef;
	}
	delete $args{Requests};

    } else {
	# Setup an empty S::M::Response for this object.  Presumably the
	# caller will call $obj->request() to fill it in later.
	#
	$obj->{_response}   = SNMP::Multi::Response->new();
    }

    # Remove any SNMP::Multi-specific options from the caller's arguments,
    # and store the resulting pairs as an array.  This will be handed to the
    # SNMP::Session constructor.  Get rid of some silly things as well.
    #
    for my $key (keys %$obj) {
	next if $key =~ m/^_/;
	delete $args{$key};
    }

    delete $args{SessPtr};
    delete $args{DestHost};
    delete $args{DestAddr};

    $obj->{_SNMPArgs} = [ %args ];

    return $obj;
}

# Take an SNMP::Multi::VarReq structure and apply the SNMP::Multi object's
# PDU packing parameters to convert the raw request blocks into chunks that
# will be scheduled for transmission by the execute() engine.
#
sub request {
    my ($multi, $vreq) = @_;

    my $count = 0;

    # Take the VarReq a host at a time, and pack the data onto the internal
    # _host structures.  This list may or may not be sorted -- we don't really
    # care.
    #
    my @hosts = $vreq->hosts();
    for my $host (@hosts) {
	my $reqs = $vreq->requests($host);

	croak "VarReq didn't return a request list!" unless defined $reqs;

	# If it doesn't already exist, initialize this host's metadata.
	unless (exists $multi->{_hosts}{$host}) {
	    next unless $multi->_init_host($host);
	}

	my $reqno = 0;
	for my $req (@$reqs) {
	    $reqno++;

	    my $did = $multi->_pack_request($host, $req);

	    unless ($did) {
		$multi->error("Failed packing request $reqno for host $host");
		return undef;
	    }
	    $count += $did;
	}
    }

    # Clear out any old contents in the Multi's Response field.
    $multi->{_response} = SNMP::Multi::Response->new();

    return $count;
}

# "Execute" the requests queued for each host.
# Note: Caller should check $multi->error() to see if an error or timeout
# occurred.
#
sub execute {
    my $multi   = shift;
    my $timeout = shift;

    if (!defined $timeout) {
	if ($multi->{Retries} >= 1) {
	    $timeout = $multi->{Timeout} * ($multi->{Retries} + 1);
	} else {
	    $timeout = 0;
	}
    }

    # Get the initial order of the requests.  Currently only round-robin
    # is supported (and, in fact, the argument is ignored).
    #
    my $rreqlist = $multi->_order_reqs('round-robin');
    return undef unless defined $rreqlist;
    $multi->{_reqlist} = $rreqlist;

    # Initiate the transmission of the requests.  This will send to no more
    # than '$multi->concurrent' hosts at once.  Any requests that were not
    # transmitted by this initial call will be sent during callbacks.
    #
    return undef unless $multi->_dispatch();

    # In order to facilitate using SNMP::Multi with other select loops (i.e.
    # in a POE-based collector), we offer the option to allow an external
    # callback loop with SNMP::select_info() and SNMP::reply_cb().  If the
    # execute() method is called with Multi's "ExternalSelect" option, it 
    # returns immediately after the initial set of requests is dispatched.
    # The caller is responsible for select()ing on the fd's, and calling
    # SNMP::reply_cb() on each one.  Caller should also check the return
    # status of SNMP::Multi::complete() to see if the Multi is completed.
    # After completion, the responses are available to the caller through
    # the SNMP::Multi::response() method.
    #
    # Note that the caller must implement the "overall timeout" if needed.
    #
    return 1 if $multi->{'ExternalSelect'};

    # Now wait for the replies to come back, and possibly transmit any 
    # additional requests.
    #
    SNMP::MainLoop($timeout, [ \&_timeout, $multi ]);

    print "All requests completed or timed out.\n"		if $DEBUGGING;

    # Caller should check $multi->error() to see if an error or timeout
    # occurred.
    return $multi->{_response};
}

# Accessor functions for values in the SNMP::Multi object.  If modifying
# the value, these return the original value (as before the modify).
#
sub verbose {
    my $self = shift;
    my $old  = $self->{Verbose};
    $self->{Verbose} = shift if @_;
    return $old;
}
sub error {
    my $self = shift;
    my $old  = $self->{error};
    $self->{error} = shift if @_;
    return $old;
}

sub remaining {
    my $self    = shift;
    my $remain  = shift || SNMP::Multi::VarReq->new();
    my $anyleft = 0;

    my $resp  = $self->{_response};
    my @hosts = keys %{$self->{_hosts}};
    for my $host (@hosts)  {
	my $reqs  = $self->{_hosts}{$host}{requests};
	for (my $index = 0; $index < @$reqs; $index ++) {
	    next if $resp->get_result($host, $index);

	    my $r = $reqs->[$index];
	    $remain->add(hosts => [ $host ], vars => $r);
	    $anyleft = 1;
	}
    }

    return $anyleft ? $remain : undef;
}
sub response {
    my $multi = shift;
    return $multi->{_response};
}

#------------- SNMP::Multi PRIVATE INTERFACE FUNCTIONS ----------------------

# Handle timeout from SNMP::MainLoop().  Set the error flag in the Multi
# object, and arrange for the MainLoop() to terminate.
sub _timeout {
    my $self = shift;

    if ($DEBUGGING) {
	print "Timed out with "
	    . $self->{_inflight} . " requests in flight, "
	    . "on $self->{_nsessions} open sessions:\n";
        print "    ", 
	    (join ', ', sort keys %{$self->{_sessions}}),
	    "\n";
    }

    $self->{error} = $errors{TIMED_OUT};
    SNMP::finish();
}

# Create a new set of metadata for a single host.  This metadata will keep
# track of things like variable requests, number of remaining requests, SNMP
# session data, etc.
#
sub _init_host {
    my ($multi, $host) = @_;

    _nag "_init_host: undefined hostname", return undef unless defined $host;

    # Create a new hash for the host information and initialize it with the
    # appropriate variables and objects.
    #
    my $hent = { };

    # These fields are all arrays, with an element for each Request requested
    # for this host.  They are populated as the Requests are added to the host
    # structure.
    #
    $hent->{requests}	= [];	# SNMP::VarLists of reqs for this host
    $hent->{sendargs}	= [];	# Add'tl arguments for send functions
    $hent->{reqoffs}	= [];	# Offsets of each set of vars in the requests

    # These fields contain counters, references to other objects, and other
    # scalar data.
    #
    $hent->{remain}     = 0;		# Count of requests remaining for host

    # Default SNMP version and community strings.  The user should be able to
    # specify a per-host version and community, but it's not yet implemented.
    #
    $hent->{community}   = $multi->{Community};
    $hent->{snmpversion} = $multi->{Version};

    # Place the completed metadata into the Multi's %_hosts hash and return
    # the reference.
    #
    $multi->{_hosts}{$host} = $hent;

    print "New host $host\n"				if $DEBUGGING;
    return $hent;
}

# Build an SNMP::VarList out of variables.  This is directly stolen from the
# SNMP perl module, so should have roughly the same look and feel ;^).
#
sub _build_varlist {
    my $vars = shift;
    $vars = shift if (ref($vars) =~ /MultiGet::/);      # function or method

    my $vlref = undef;

    if (ref($vars) =~ /SNMP::VarList/) {        # Already a VarList, so use
        $vlref = $vars;                         # it unmodified.

    } elsif (ref($vars) =~ /SNMP::Varbind/) {   # A VarList is just an array
        $vlref = [$vars];                       # of Varbind's, so build it.

    } elsif (ref($vars) =~ /ARRAY/) {           # Array of Varbinds.
        $vlref = [$vars];
        $vlref = $vars if ref($$vars[0]) =~ /ARRAY/;    # oops, array of arrays

    } else {
        # Parse the string into tag and iid (if declared), and create a VarList
        # with one Varbind from the values.
        my ($tag, $iid) = ($vars =~ /^((?:\.\d+)+|\w+)\.?(.*)$/);

        $vlref = [[$tag, $iid]];

    }

    bless ($vlref, 'SNMP::VarList');
}

# Pack the SNMP variables in a Request onto the requests queues for the 
# hosts, creating chunks of no more than the $multi->PduPacking variables.
# Note that this is not done for getbulk and bulkwalk requests -- packing
# them would destroy the non-repeater/repeater distinction.
#
sub _pack_request {
    my ($multi, $host, $req) = @_;

    my $count    = 0;				# Count of requests added
    my $maxvars  = $multi->{PduPacking};	# Max vars per request
    my @args     = ();				# Extra args for this chunk
    my $rhost    = undef;

    $rhost = $multi->{_hosts}{$host};
    unless ($rhost) {
        print "Failed to look up $host in hosts\n" if $DEBUGGING;
	return undef;
    }

    print "Packing request for $host (", scalar @{$req->{vars}}," vars)\n"
								if $DEBUGGING;

    # Find index of the last hunk on the reqlist, and get a reference to the
    # last VarList (the contents of the last element) if there is one (i.e.
    # $last isn't -1).
    #
    my $last   = $#{$rhost->{requests}};
    my $target = ($last >= 0) ? $rhost->{requests}->[$last] : undef;
    my $offset = ($last >= 0) ? $rhost->{reqoffs}->[$last] : 0;

    my $began  = ($last >= 0) ? $last : 0;

    $offset += scalar @$target if defined ($target);

    # Create a new VarList from the request's list of variables if not already
    # a VarList.
    #
    my $vlist = $req->{vars};
    $vlist = _build_varlist($vlist) unless (ref($vlist) =~ m/SNMP::VarList/);
    _nag "Bad variable list in request", return undef unless defined($vlist);

    # For getbulk and bulkwalk, each varlist gets to be on its own in the
    # requests.  We need to provide the sendargs for nonrepeaters and max
    # repeater counts (or defaults).  Adjust the $maxvars count to be
    # exactly the size of the variable list.  Also undef $target to force
    # creation of a new chunk below.
    #
    if ($multi->{Method} eq 'getbulk' || $multi->{Method} eq 'bulkwalk') {

	# Create 2-element arg list for nonrepeater and maxreps arguments.
	@args = ($req->{nonrepeaters}   || 0,
		 $req->{maxrepetitions} || $multi->{GetbulkMax});

	$maxvars = scalar @$vlist;	# Enough space, but it doesn't matter,
	$target  = undef;		# since we'll create a new one anyway.
    }

    # If pdupacking is turned off, just use this chunk.
    #
    if ($multi->{PduPacking} == 0) {
	$maxvars = scalar @$vlist;	# Enough space, but it doesn't matter,
	$target  = undef;		# since we'll create a new one anyway.
    }

    # Build a list of the VarBinds in the VarList referenced by the chunks 
    # on the requests queue.
    #
    for my $vbref (@$vlist) {
	# Need a new chunk or out of room on the existing one?  Build a new
	# VarList on which to stash the variables.
	#
	unless ((defined $target) && (scalar @$target < $maxvars)) {
	    $target = SNMP::VarList->new;
	    push @{$rhost->{requests}}, $target;
	    push @{$rhost->{reqoffs}}, $offset;
	    push @{$rhost->{sendargs}}, [@args];	# Extra send arguments.

	    print "Created new request for $host, index ", 
		scalar @{$rhost->{requests}}, 
		", now $rhost->{remain}/$multi->{_remain} reqs\n" if $DEBUGGING;
	}

	# Copy the VarBind and push it onto the target chunk array.
	#
	my @vbcopy  = @$vbref;
	my $rvbcopy = SNMP::Varbind->new(\@vbcopy);
	push @$target, $rvbcopy;
	$count ++;
	$offset ++;
    }

    print "Packed $count requests on ", (scalar @{$rhost->{requests}}) - $began,
	" request chunks\n"					if $DEBUGGING;
    return $count;
}

# Generate an array of host/index tuples which describes the order in which
# the requests should be sent out.  This list is stored on the Multi object,
# and traversed as sessions (or inflight requests) become available to send
# more requests.  This is currently a round-robin algorithm, to reduce the
# amount of traffic generated to any one router concurrently (hopefully).  It
# should be easy to add additional algorithms to it, by selecting one of 
# several routines based on $algorithm.
#
# This is just the starting/preferred order.  If enough concurrent sessions
# are not allowed, the list will be re-ordered as requests for some hosts 
# will be deferred until the requests for other hosts are completed, and 
# their sessions can be recycled.
#
sub _order_reqs {
    my ($multi, $algorithm) = @_;	# $algorithm currently unused

    # Generate a list of the hostnames to which we will be sending the
    # requests.  This will be used to generate a list of hosts to round-
    # robin.
    #
    my $rhosts = $multi->{_hosts};
    my @hosts = keys %$rhosts;

    # Create a new array of host/index pairs from the host list.  The index
    # is the element index of the first un-sent request for this host, starting
    # with element 0.  Walk through the hosts, adding a tuple for each host
    # that has a request in index $index.
    #
    my @rr    = ();	# Round-robin list of host/index tuples.
    my $index = 0;	# Current index into request lists.
    my $host;		# Current host being added...
    my $done  = 0;	# Not done yet!

    while (!$done) {
	$done = 1;				# Assume we'll finish this time.

	foreach $host (@hosts) {		# Get requests for each host
	    my $reqs = $rhosts->{$host}{requests};

	    my $nreqs = scalar @$reqs;		# How many requests are there?
	    next unless $index < $nreqs;	# Next host if no more reqs.

	    push @rr, ($host, $index);		# Add the tuple to the RR list.
	    $done = 0;				# Need to go on.

	    $multi->{_remain} ++;
	    $rhosts->{$host}{remain} ++;
	}
	$index ++;
    }

    if ($DEBUGGING) {
	print "Order of requests:\n";
	for (my $index = 0; $index < scalar @rr; $index += 2) {
	    my $host = $rr[$index];
	    my $rind = $rr[$index + 1];
	    my $reqs = $rhosts->{$host}{requests};
	    my $vlen = scalar @{$reqs->[$rind]};
	    print "    ", $index / 2, " -> host $host, index $rind ($vlen var", 
		($vlen == 1 ? "" : "s"), ")\n";
	}
    }

    return \@rr;
}

# Send off some (or all) of the SNMP requests in the Multi's request queue.
# Any requests that cannot be sent will be re-queued at the end of the list.
#
sub _dispatch {
    my $multi = shift;
    my $count = 0;

    my @retry = ();	# Requests to retry on next run.

    # Don't bother doing anything if no more inflight requests are allowed.
    #
    return 0 if $multi->{_inflight} >= $multi->{Concurrent};

    # How many (if any) SNMP sessions are available to allocate?
    #
    my $availsess = $multi->{MaxSessions} - $multi->{_nsessions};
    my $rsessions = $multi->{_sessions};

    # Any extra arguments for SNMP::Session?
    #
    my @SNMPargs = @{$multi->{_SNMPArgs}};

    # Iterate through the round-robin list, popping host/index pairs off of
    # the front of @rrhosts, and pushing the "next" pair on the end if more
    # requests remain.
    #
RR: while (@{$multi->{_reqlist}}) {

	# Pull the next host/index pair off of the front of @rrhosts.
	#
	my $host  = shift @{$multi->{_reqlist}};
	my $index = shift @{$multi->{_reqlist}};
	my $rhost = $multi->{_hosts}{$host};

	# Skip this host/index if a new session to that host is needed,
	# but there are no available sessions.
	#
	my $rsess = $rsessions->{$host};
	if (!defined($rsess) && !$availsess) {
	    print "No SNMP sessions available for $host (all "
		. "$multi->{MaxSessions} sessions in use)\n"	if $DEBUGGING;

	    # Push the request on the tail of the retry request list.
	    push @retry, ($host, $index);
	    next RR;
	}

	# There is either a current session for this host, or a new one can
	# be created.  Get handles for the metadata for this host.
	#
	my $rreqs = $rhost->{requests};
	my $nreqs = scalar @$rreqs;

	croak "Request $host:$index outside range [0..$nreqs]"
		unless ($index < $nreqs);

	# Get a reference to the request, and its additional arguments.
	#
	my $request = $rreqs->[$index];
	croak "Request is undef!" unless defined $request;

	my $rargs = $rhost->{sendargs}->[$index];

	# Create a new session for this request if one does not already exist.
	unless (defined $rsess) {

	    $! = 0;	# Reset system errno before calling new() (see below)

	    $rsess = SNMP::Session->new( @SNMPargs,
					 DestHost    => $host,
					 Community   => $rhost->{community},
					 Version     => $rhost->{snmpversion}, 
					 Timeout     => $multi->{Timeout} * 1e6,
					 Retries     => $multi->{Retries},
					 TimeStamp   => $multi->{TimeStamp},
					 #UseNumeric => $multi->{UseNumeric},
					 # UseNumeric BOMBS PERL CORE !!!
					 UseNumeric  => 0,
				       );

	    # Give up on this particular request for now.  At some point in
	    # the future, we should probably flag the session as failed, and
	    # provide an option to avoid retrying any further requests on the
	    # host.
	    #
	    # This is a little tricky -- SNMP::Session::new() doesn't set any
	    # sort of error flag.  We can, however, tell if it was a hostname
	    # lookup failure by examining $! (errno).  It will be 0 if the
	    # problem occurred before the call into the XS code, otherwise
	    # a system-level error occured which we can trap based on $!.
	    #
	    unless (defined $rsess) {
		my $err;
		unless ($!) {
		    # Couldn't look up the host, so set the error code
		    # especially for this.
		    $err = "Couldn't resolve hostname";

		    # We are discarding this request.
		    #
		    $rhost->{remain} --;
		    $multi->{_remain} --;

		} else {
		    # Some system-level error occurred.  Handle a few simple
		    # resource problems by (hopefully) waiting for things to
		    # subside, and retry later.
		    #
		    # Copy error string, and force numeric errno
		    $err = "" . $!;
		    my $errno = $! + 0;
		    if (($errno == EINTR)  || 	# Interrupted system call
			($errno == EAGAIN) ||	# Resource temp. unavailable
			($errno == ENOMEM) ||	# No memory (temporary)
			($errno == ENFILE) ||	# Out of file descriptors
			($errno == EMFILE))	# Too many open fd's
		    {
			# Push the request onto the retry request list.
			push @retry, ($host, $index);

			# Prevent further attempts to get a new session
			# until the blockage clears, but only if there's
			# a chance a current connection will finish and
			# free up resources.
			$availsess = 0 if $multi->{_nsessions};

			# Note that we'll retry later.
			$err .= " (will retry)";
		    } else {

			# We are discarding this request.
			#
			$rhost->{remain} --;
			$multi->{_remain} --;
		    }
		}

		_nag "Couldn't create SNMP v$rhost->{snmpversion} session for "
		   . "$host: $err\n";

		next RR;
	    }

	    # Work around a work-around.  When UseNumeric is set, the SNMP
	    # module forces UseLongNames.  This may or may not be what was
	    # intended by the user.  Assume that the user knows what they're
	    # doing if numeric and no long names...  Note that this is digging
	    # around in the SNMP object -- a no-no, but life's hard.
	    #
	    if ($rsess->{UseNumeric} && ! $SNMP::use_long_names) {
	    	print "UseNumeric set with SNMP::use_long_names, resetting...\n"
				if $DEBUGGING;
		$rsess->{UseLongNames} = 0;
	      }

	    # Store the session for future use, and note the new session in
	    # the in-use and available counts.
	    #
	    $rsessions->{$host} = $rsess;
	    $multi->{_nsessions} ++;
	    $availsess --;
	    print "Created new SNMP session for $host, now $multi->{_nsessions}"
		. " of $multi->{MaxSessions} sessions\n"	if $DEBUGGING;
	}

	# Send the hunk of variable requests.  Arrange for the Perl callback
	# to get back the host and index number of the request.  This allows
	# the callback to place the returned values (or error) into the 
	# correct host slot.  Async calls return the request ID for the request,
	# or undef on failure.
	#
	# Call $rsess->'get'() or whatever the method requested was.  THe
	# name of the method was validated by the 'new()' function.
	#
	my $method   = $multi->{Method};
	my $callback = [ $_handler{$method}, $multi, $host, $index ];
	my @args = @$rargs;
	push @args, $request;
	push @args, $callback;

	my $res = $rsess->$method(@args);

	if (defined $res) {
	    # Note another request successfully sent, and increment the count
	    # of inflight requests.
	    # 
	    $count ++;
	    $multi->{_inflight} ++;

	    print "Sent request for $host:$index (", scalar @$request, " var",
		(scalar @$request == 1 ? "" : "s"), "), ", 
		scalar @{$multi->{_reqlist}} / 2, " reqs remain to try, ",
		"will retry ", scalar @retry / 2, " reqs\n"
		if $DEBUGGING;

	} else {
	    my $result = SNMP::Multi::Result->new (
		    varlist => SNMP::VarList->new($request),
		    errnum  => $rsess->{ErrorNum},
		    errstr  => $rsess->{ErrorNum} ? $rsess->{ErrorStr} : "",
		    reqind  => $rsess->{ErrorInd},
		    errind  => $rsess->{ErrorInd} + $rhost->{reqoffs}->[$index]
	    );
	    $multi->{_response}->add_result($host, $result, $index);

	    _nag "Cannot do $method request #$index on $host (session $rsess)"
	      . " -- " . $result->error();
	}

	# Have we reached the limit of inflight requests?
	last RR if $multi->{_inflight} >= $multi->{Concurrent};
    }

    # If any requests were attempted but couldn't be sent, push them onto
    # the tail of the requests list.
    push @{$multi->{_reqlist}}, @retry;

    return $count;
}


# Functions to handle variable lists handed back through the async perl
# callback.  The "normal" SNMP operations return a VarList (an array of
# Varbinds), while bulkwalk() returns an array of VarLists (one VarList
# for each requested variable).  The return values are stored as arrays
# of VarLists, so handle_VarList() converts the VarList to an array of a
# VarList's to match bulkwalk()'s return format.  handle_AoVarLists()
# handles the array-of-VarLists return from bulkwalk (basically passes
# it through unmodified).
#
# Note : These are not really methods, although they look like them.
#
sub _handle_VarList {
    my ($multi, $host, $index, $rvlist) = @_;
    my $raovl = undef;

    croak "No host entry for $host!" unless exists $multi->{_hosts}{$host};

    if (defined $rvlist) {
	my @aovl = ();

	# Special case for 'getbulk' method.  Create an array of VarLists,
	# one per non-repeater, then the list of values for each repeater in
	# its own VarList.  Returned values for getbulk are non-repeaters,
	# followed by the values for each repeater interleaved, one VarBind
	# per instance.
	#
	if ($multi->{Method} ne "getbulk") {
	    # Not getbulk method, build one VarList per Varbind.
	    #
	    for my $vb (@$rvlist) {
		# internal work-around: translates text tags back to IOD's,
		# needed because of SNMP.pm bug - see below comment next to
                # the sub itself
		$vb = _translateObj($vb) if $multi->{UseNumeric};
		push @aovl, SNMP::VarList->new($vb);
	    }
	} else {
	    # Getbulk support.  Need to "decode" the VarList returned by the
	    # getbulk method.
	    #
	    my $rhost    = $multi->{_hosts}{$host};
	    my $nonreps  = $rhost->{sendargs}->[0];
	    my $reqcount = scalar @{$rhost->{requests}->[$index]};
	    my $repeats  = $reqcount - $nonreps;

	    # Build an empty VarList for variable requested.
	    for (my $i = 0; $i < $reqcount; $i ++) {
		push @aovl, SNMP::VarList->new();
	    }

	    # Push each non-repeater Varbind onto the appropriate VarList.
	    my $nr = 0;
	    while ($nr < $nonreps) {
		push @{$aovl[$nr]}, shift @$rvlist;
		$nr ++;
	    }

	    # Now cycle through all the remaining Varbinds, pushing them onto
	    # the appropriate VarList.
	    $nr = 0;
	    while (scalar @$rvlist) {
		push @{$aovl[$nr + $nonreps]}, shift @$rvlist;
		$nr = ($nr + 1) % $repeats;
	    }
	}

	$raovl = \@aovl;	# Take a ref to the resulting array of varlists
    }

    # Hand the array reference (or undef for timeout) to _handle_AoVarLists(),
    # which will actually place the data in the SNMP::Multi::Response object.
    #
    _handle_AoVarLists($multi, $host, $index, $raovl);
}

#====================================================================
# internal work-around function: specific to SNMP::Varbind objects.
# It is needed because of SNMP.pm bug where option UseNumeric makes
# it dump core. So, when UseNumeric is set, we don't pass that
# information to SNMP.pm, instead, to achieve the same effect, but
# without perl core dumps, we let it convert OID's to text tags
# which we then convert back to OID's here. Ironically enough, we do
# that by using a wrapper around SNMP.pm own method.
# -- 16 Dec 2003  toni@irational.org --
#=====================================================================
sub _translateObj {
    my ( $varbind ) = @_;

    my $type = "SNMP::Varbind";
    if (not ref($varbind) eq $type ) {
        printf( "\tERROR in %s: called from the %s (line %s)" .
		" with the wrong type of argument. Only %s" .
		" object are accepted.\n", (caller(0))[3],
		(caller(1))[3], (caller(0))[2], $type);
	return;
    }

    # accessors for SNMP::Varbind
    my @vbaccessors = qw/ tag iid val type /;
    my $new_varbind;
    foreach my $method ( @vbaccessors ) {
        my $value = $varbind->$method;
	if ($method  eq "tag") {
	    $value = SNMP::translateObj($value);
	    $value =~ s/.//;
	}
	push @$new_varbind, $value;
    };
    # pack it back in the format we received it in
    return bless ($new_varbind, 'SNMP::Varbind');
}

sub _handle_AoVarLists {
    my ($multi, $host, $index, $raovl) = @_;

    croak "No host entry for $host!" unless exists $multi->{_hosts}{$host};

    my $rhost = $multi->{_hosts}{$host};

    if ($DEBUGGING) {
	my $vlen = defined $raovl ? scalar @$raovl : 0;
	print "Received response for $host:$index ($vlen var", 
	    ($vlen == 1 ? "" : "s"), ").\n";
	print "$rhost->{remain} reqs remain to receive from $host\n";
	print "$multi->{_remain} reqs remain for Multi($multi->{Method}).\n";
    }

    # If undef, we got a timeout.  Otherwise copy the error from the SNMP
    # session to the Result object.
    #
    my @errs;
    if (defined ($raovl)) {
	$errs[0] = $multi->{_sessions}{$host}{ErrorNum};
	$errs[1] = $errs[0] ? $multi->{_sessions}{$host}{ErrorStr} : "";
	$errs[2] = $multi->{_sessions}{$host}{ErrorInd};
    } else {
	$errs[0] = -24;
	$errs[1] = 'Timeout';
	$errs[2] = 0;
    }

    my $result = SNMP::Multi::Result->new (
	    varlist => $raovl,
	    errnum  => $errs[0],
	    errstr  => $errs[1],
	    reqind  => $errs[2],
	    errind  => $errs[0] ? $errs[2] + $rhost->{reqoffs}->[$index] : 0
    );
    $multi->{_response}->add_result($host, $result, $index);

    # Track the number of in-flight, per-host, and total remaining requests.
    $multi->{_inflight} --;
    $multi->{_remain} --;
    $rhost->{remain} --;

    # If all requests for this host have been completed or timed out, we
    # can free the session pointer for someone else to use.
    #
    unless ($rhost->{remain}) {
	delete $multi->{_sessions}{$host};
	$multi->{_nsessions} --;
	print "All $host requests done, closing SNMP session "
	    . "($multi->{_nsessions} still in use)\n"	if $DEBUGGING;
    }

    # If any requests remain at all, attempt to send some more out.  Otherwise,
    # if no outstanding requests remain, and none are inflight, we're done.
    # Interrupt the MainLoop so it can return the results.
    if ($multi->{_remain}) {
	$multi->_dispatch();
    } else {
	SNMP::finish() unless $multi->{_inflight};
    }
}

# Return non-zero if the Multi request has been completed (i.e. no requests
# remain to send, and no in-flight requests are outstanding).
#
sub complete {
    my $multi = shift;
    return ($multi->{_remain} || $multi->{_inflight}) ? 0 : 1;
}

#-----------------------------------------------------------------------------
package SNMP::Multi::Result;
#-----------------------------------------------------------------------------
use Carp;
use strict;

#
# The SNMP::Multi::Result class encapsulates the returned data (if any)
# from the SNMP agent, as well as any error information.  It supplies a
# few methods to access this data, but is essentially just a container.
#
# The object is simply a hash arranged like this:
#
#	+---------------------+----------+
#	| SNMP::Multi::Result | varlist -+---> SNMP::VarList
#	|                     | errnum   |
#	|                     | errstr   |
#	|                     | errind   |
#	|                     | reqind   |
#	+---------------------+----------+
#
#   $smr->varlists() returns a reference to the array of SNMP::VarList
#       object for this result.
#
#   All of these methods return undef if no error occurred:
#
#	$smr->errnum() returns numeric number of SNMP error.
#	$smr->errstr() returns printable string describing the error.
#	$smr->errind() returns the index of the variable causing the error.
#	$smr->reqind() returns the index in the request of a bad variable.
#	$smr->error()  returns "$errstr ($errnum)"
#
#   The _set_error() method can be used to change the error information:
#
#	$smr->_set_error( <errnum>, <errstr> );

sub new {
    my $type  = shift;
    my $class = ref($type) || $type;

    my %args = @_;

    my $self = { 
	varlist		=> $args{'varlist'},
	errnum		=> $args{'errnum'},
	errstr		=> $args{'errstr'},
	errind		=> $args{'errind'},
	reqind		=> $args{'reqind'},
    };
    bless $self, $class;
    return $self;
}

sub error {
    my $self = shift;
    return undef unless defined $self->{errnum} && $self->{errnum} != 0;
    return $self->{errstr} . " (err " . $self->{errnum}
			   . " at var $self->{errind})";
}

sub _set_error {
    my ($self, $errnum, $errstr) = @_;
    $self->{errnum} = $errnum;
    $self->{errstr} = $errstr;
    return $self;
}

# Simple accesssor functions.
#
sub varlists {
    my $self = shift;
    my $vl = $self->{varlist};

    # Can't use an undefined value as an ARRAY reference [on next line]
    if (wantarray) {
	return UNIVERSAL::isa($vl, "ARRAY") ? @$vl : ();
    } else {
	return $vl;
    }
}

sub errnum {
    my $self = shift;
    return undef unless defined $self->{errnum} && $self->{errnum} != 0;
    return $self->{errnum};
}
sub errstr {
    my $self = shift;
    return undef unless defined $self->{errnum} && $self->{errnum} != 0;
    return $self->{errstr};
}
sub errind {
    my $self = shift;
    return undef unless defined $self->{errnum} && $self->{errnum} != 0;
    return $self->{errind};
}
sub reqind {
    my $self = shift;
    return undef unless defined $self->{errnum} && $self->{errnum} != 0;
    return $self->{reqind};
}

sub values {
    my $self = shift;
    return if $self->error();

    my @values = ();

    for my $varlist ($self->varlists) {
	for my $vb (@$varlist) {
	     push @values, $vb->val();
	}
    }

    return wantarray ? @values : \@values;
}

###########################################################################
package SNMP::Multi::VarReq;
#
# This object is used to build up a set of host/OID requests that will
# be handed to the SNMP::Multi object to pack and transmit.
#
# Note that we have no a priori knowledge of how the request will be
# packed (or even what sort of SNMP request this will finally be).  No
# variable packing is done at this point.
#
# If 'autovalidate' is true, the variables and hostnames being requested
# will be looked up and an error returned.  The VarReq can be explicitly
# checked at any time by calling the validate() method.
#
use strict;
use Carp;

# Declare and initialize global variables/flags.
use vars	qw/ $DEBUGGING $error $sorthosts $autovalidate /;
$DEBUGGING	= 0;
$error		= undef;
$sorthosts	= 0;
$autovalidate	= 0;

sub new {
    my $type  = shift;
    my $class = ref($type) || $type;

    $error = '';

    my $req = {
	'error'		=> undef,
	'sorthosts'	=> $sorthosts,
	'autovalidate'	=> $autovalidate,
	'requests'	=> {},
    };
    bless $req, $class;
    print "new() => $req\n"	if $DEBUGGING;

    if (@_) {
	# add() sets $req's 'error' string, but we won't return the
	# request object.  Copy error to global $error string.
	unless ($req->add(@_)) {
	    $error = $req->error();
	    return undef;
	}
    }
    return $req;
};

sub DESTROY { print "DESTROY: $_[0]\n" if $DEBUGGING };

######### Accessor methods:
#
sub error {			# read-only
    my $self = shift;
    return $self->{'error'};
}
sub set_error {			# read-write (undef okay)
    my ($self, $new) = @_;
    my $old = $self->{'error'};
    $self->{'error'} = $new;
    return $old;
}
sub sorthosts {			# read-write
    my ($self, $new) = @_;
    my $old = $self->{'sorthosts'};
    $self->{'sorthosts'} = $new if (defined $new);
    return $old;
}
sub autovalidate {		# read-write
    my ($self, $new) = @_;
    my $old = $self->{'autovalidate'};
    $self->{'autovalidate'} = $new if (defined $new);
    return $old;
}

# hosts():
#
#   Return a list (or array ref) of the hosts mentioned in
#   the VarReq object.  If 'sorthosts' is true, the list will
#   be sorted into a more readable order for the caller.
#
sub hosts {			# read-only
    my $self = shift;
    my @hosts = keys %{$self->{'requests'}};

    @hosts = (sort _by_host @hosts) if ($self->sorthosts() || $sorthosts);

    return wantarray ? @hosts : \@hosts;
}

# Return a list of the variable request chunks for a host.  If no
# host is returned, the requests for all hosts are returned (note
# that no attempt is made to reduce or consolidate the data).
#
sub requests {
    my ($self, $host) = @_;

    my @hlist = (defined $host) ? ($host) : $self->hosts();

    my @reqs = ();
    for my $h (@hlist) {
	push @reqs, @{$self->{'requests'}{$h}};
    }
    return wantarray ? @reqs : \@reqs;
}

# Like requests() above, but returns a list of just the 'vars' portion
# of the request lists.  See dump() for an example of usage.
#
sub requests_list {
    my ($self, $host) = @_;

    my @hlist = (defined $host) ? ($host) : $self->hosts();

    my @reqs = ();
    for my $h (@hlist) {
	my $varlist = $self->{'requests'}{$h};
	for my $hash (@$varlist) {
	    my $vars = $hash->{'vars'};
	    push @reqs, @$vars;
	}
    }
    return wantarray ? @reqs : \@reqs;
}

######### Action methods:
#
# add():
#
#   Add a set of variables to the current request object.  The 'vars' argument
#   is mandatory, and specifies the variables to request from the agents.  An
#   optional 'hosts' field specifies a list of hosts for which this variable
#   request should be made.  If no 'hosts' argument is given, the var request
#   will be applied to the currently-existing list of hosts.
#
#   For SNMP getbulk and bulkwalk requests, optional arguments 'nonrepeaters'
#   and 'maxrepetitions' can be specified.  These parameters will be ignored
#   by SNMP::Multi for non-bulk requests, and will receive the SNMP::Multi's
#   default values unless specified for a request.
#
#   Note that no variable packing is done at this time.  The SNMP::Multi object
#   does packing based on its parameters when the VarReq is handed to it.
#
sub add {
    my $self = shift;

    my %arg = @_;	# Convert arglist to a hash for key-value access.
    
    # Each added request block must have at least one element in
    # the 'vars' slot.  Ensure that we have an array of vars.
    #
    my $vars = $arg{'vars'} || $arg{'-vars'} || $arg{varlist} || $arg{-varlist};
    unless (defined $vars) {
	$error = "No 'vars' argument to " . __PACKAGE__ . "::add()";
	return undef;
    }
    $vars = [ $vars ] unless (ref($vars) =~ m/ARRAY/ || 
			      ref($vars) =~ m/SNMP::VarList/ );

    # Now see if a specific set of hosts was mentioned.  If not, we'll
    # just use whatever exists.  Obviously, the 'hosts' argument is not
    # optional if there are no hosts already defined.
    #
    my $hosts = $arg{'hosts'} || $arg{'-hosts'};

    unless (defined $hosts || $self->hosts()) {
	$error = "No 'hosts' for VarReq in " . __PACKAGE__ . "::add()";
	return undef;
    }

    # If hosts were not specified, apply the var request to all current
    # hosts.  If a single host was specified, turn it into a 1-element
    # array.
    #
    if (defined $hosts) {
	$hosts = [ $hosts ] unless ref($hosts) =~ m/ARRAY/;
    } else {
	$hosts ||= $self->hosts();
    }
    print "Adding " . scalar @$vars . " var(s) to $self\n"	if $DEBUGGING;

    # We may also have a set of values for this request (if it's an SNMP
    # "SET" operation).  Store these too, they'll be ignored for anything
    # but a SET request.
    #
    my $values = $arg{'values'} || $arg{'-values'};

    # The SNMP "GETBULK" and "BULKWALK" requests have two additional
    # parameters (non-repeaters and max-repetitions).  If provided, store
    # them, otherwise they'll be given default values by SNMP::Multi.
    #
    my $nonreps = $arg{'nonrepeaters'}   || $arg{'-nonrepeaters'};
    my $maxreps = $arg{'maxrepetitions'} || $arg{'-maxrepetitions'};

    # We don't have enough information to do the PDU packing here, so we just
    # store up the requests and leave packing up to the SNMP::Multi object.
    # If necessary, create a new entry in the VarReq object for this host.
    #
    my @reqbits  = ( 'vars'           => $vars );
    push @reqbits, ( 'values'         => $values )	if defined $values;
    push @reqbits, ( 'nonrepeaters'   => $nonreps )	if defined $nonreps;
    push @reqbits, ( 'maxrepetitions' => $maxreps )	if defined $maxreps;

    my $new_req = { @reqbits };

    for my $h (@$hosts) {
	unless (exists $self->{'requests'}{$h}) {
	    $self->{'requests'}{$h} = [];
	    print "  Created new entry in $self for $h\n"	if $DEBUGGING;
	}
	my $reqlist = $self->{'requests'}{$h};
	push @$reqlist, $new_req;
	print "  Added " . scalar @$vars . " VarReq for $h\n" if $DEBUGGING;
    }

    if ($self->autovalidate || $autovalidate) {
	print "  Validating request -- this may take a bit...\n" if $DEBUGGING;

	return undef unless $self->validate(@$hosts);
    }

    return $self;
}

# validate():
#
#   Sanity-check the current contents of the VarReq object.  An optional
#   host list can be used to reduce the validation scope.
#
#   XXX - Not yet fully implemented.
#
sub validate {
    my $self  = shift;
    my @hosts = (scalar @_) ? @_ : $self->hosts; 

    # Attempt DNS name lookup on each host.  If it fails, try to figure
    # out why and return an error in the VarReq's error slot.
    #
    for my $host (@hosts) {
	my $ip = gethostbyname($host);	# Could try to canonicalize here.
	next unless $?;

	# These error codes are implementation-specific -- check against
	# the values #define'd in <netdb.h>!
	my $err = "$host: ";
	$err   .= "unknown hostname"		if ($? == 1);
	$err   .= "nameserver failed"		if ($? == 2);
	$err   .= "unrecoverable error"		if ($? == 3);
	$err   .= "no data from nameserver"	if ($? == 4);
	$err   .= "unspecified/unknown error"	if ($? >= 5);

	$self->set_error($err);
	return undef;
    }

    # Now look through the list of variable requests, checking that they
    # are reasonable.  We should be able to ask the SNMP module if these
    # are valid or not.  XXX dunno how to do this yet...
    #
#   my @reqs = $self->requests(@hosts);
#   my %seen = ();
#
#   for my $req (@reqs) {
#	my $vars = $req->{'vars'};
#	for my $var (@$vars) {
#	    # Check if we've already looked this one up, and ignore it if
#	    # that's the case.
#	    #
#	    next if exists $seen{$var};
#	    $seen{$var} = undef;
#
#	    # Look for the variable in the MIB if it's not all-numeric.
#	    #
#	    next if ($var =~ m/^\.?(\d+\.)*\d+$/);
#	    next unless SNMP::translateObj($var);
#
#	    $self->set_error("$var: Unknown var/OID");
#	    return undef;
#	}
#   }

    return $self;
}

# dump():
#
#   Returns a printable string outlining the variable and host requests
#   contained in the VarReq.  Probably should set 'sorthosts' before calling
#   this routine.
#
sub dump {
    my $self = shift;

    my $out = '';
    my $l = 0;

    my @hosts = $self->hosts();
    for my $h (@hosts) {
	$l = length($h) if length($h) > $l;
    }
    
    for my $h (@hosts) {
	my $rl = $self->requests_list($h);
	$out .= sprintf "%${l}s: ", $h;
	$out .= join ' ', 
		    map { (ref($_) =~ m/ARRAY/) ? (join '.', @$_) : ($_) } @$rl;
	$out .= "\n";
    }

    return $out;
}

# _by_host():
#
#   Sorting logic to sort hostnames into a "reader friendly" order.  This
#   algorithm compares hostnames sub-domain by sub-domain, starting with the
#   top-level domains, sorting alphabetically at each point.
#
#	- eli.net
#	- nosferatu.eli.net
#	- surly.eli.net
#	- www.eli.net
#	- er02.plal.eli.net
#	- er01.ptld.eli.net
#	- gw01.ptld.eli.net
#	- gw02.ptld.eli.net
#
#   This isn't perfect, but it does help group together related host-names.
#   A far better algorithm would be recursive, generating a tree from the
#   pieces of the hostname, then doing an in-order traversal of that tree.
#   But that would vaguely resemble work.  Exercise Left For Reader.  8^)
#
sub _by_host {
    my (@a, @b, $A, $B);

    return 0 if (lc $a eq lc $b);	# Shortcut if names are identical.

    # Compare each element in the '.'-separated hostnames individually,
    # starting with the least significant (i.e. the TLD).
    #
    @a = split /\./, lc $a;
    @b = split /\./, lc $b;

    # Sort hostnames with more pieces (more specific) to the bottom.
    return (scalar @a <=> scalar @b) unless (scalar @a == scalar @b);

    while (($A = pop @a) && ($B = pop @b)) {
	return ($A cmp $B) if ($A cmp $B);	# Different?
    }

    # Ran out of pieces in one of the names.  If the first was more
    # specific, sort it to the bottom.  Otherwise, sort to top.
    #
    return 1  if (defined $A);
    return -1;
}

#-----------------------------------------------------------------------------
package SNMP::Multi::Response;
#-----------------------------------------------------------------------------
#
# This object encapsulates the returned data from the hosts, providing a
# simple interface for accessing the data.  It is returned by the Session
# object's execute() method.
#
# The layout is basically a hash of SNMP::Multi::Response::Host objects,
# each of which has a list of SNMP::Multi::Result objects:
#
#    my $resp = $sms->execute();
#    for my $host ($resp->hosts()) {
#        for my $result ($host->results()) {
#	    if ($result->error()) {
#		print $result->error();
#	    } else {
#		print map { "    " . $_->fmt() . "\n" } $result->varlist();
#	    }
#        }
#    }
#

use Carp;
use strict;

sub new {
    my $self = shift;
    my $class = ref($self) || $self;

    my $resp = {};
    bless $resp, $class;

    return $resp;
}

# Access methods:
#
#   add_result($host, $result, $index):
#	Add the SNMP::Multi::Result object '$result' to the Response
#	object, possibly making a new SNMP::Multi::Response::Host
#	object from '$host'.  The Result is stored at array position
#	$index in the SNMP::Multi::Response::Host 'results' entry.
#
#   get_result($host, $index):
#	Return the $index'th result for the host $host in the Response
#	object.  Returns undef if the requested result has not yet been
#	returned by the host (or if the host has not yet replied).
#
#   hostnames():
#	Returns a list [or array ref in scalar context] of the hosts
#	for which data was received.
#
#   hosts():
#	Returns a list [or array ref in scalar context] of the SNMP data
#	for each host, contained in SNMP::Multi::Response::Host objects.
#
#   values([@hosts]):
#	Returns a list [or array ref in scalar context] of the values from
#	the SNMP data for the specified hosts (or all hosts).  This might
#	be useful if, for instance, you wish to simply sum up interface
#	octet counts for a set of routers without regard for the mapping
#	of hosts to sets of data values.
#
sub add_result {
    my ($self, $host, $result, $index) = @_;

    unless (exists $self->{$host}) {
        $self->{$host} = SNMP::Multi::Response::Host->new(hostname => $host);
    }

    # Add the SNMP::Multi::Results object to the SNMP::Multi::Response::Host
    # object at the appropriate slot ($index).
    #
    $self->{$host}->store_result($result, $index);;
}

sub get_result {
    my ($self, $host, $index) = @_;

    return undef unless (exists $self->{$host});
    $self->{$host}->get_result($index);
}

sub hostnames {
    my $self  = shift;
    my @names = keys %$self;
    return wantarray ? @names : \@names;
}
sub hosts {
    my $self  = shift;
    my @hosts = values %$self;
    return wantarray ? @hosts : \@hosts;
}
sub values {
    my $self  = shift;
    my @hosts = (scalar @_ ? @_ : $self->hosts);

    my @values = ();

    for my $host (@hosts) {
	next unless (exists $self->{$host});

	push @values, $host->values();
    }
    return wantarray ? @values : \@values;
}

#-----------------------------------------------------------------------------
package SNMP::Multi::Response::Host;
#-----------------------------------------------------------------------------
#
# This class simply encapsulates the SNMP::Multi::Results for a host.  The
# SNMP::Multi::Response object is a hash of these objects.
#
use Carp;
use strict;

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $host = { 
	'hostname'	=> undef,
	'results'	=> [],
	@_
    };

    bless $host, $class;
}

sub store_result {
    my ($self, $results, $index) = @_;

    $self->{results}->[$index] = $results;
    return $results;
}

sub get_result {
    my ($self, $index) = @_;

    return $self->{results}->[$index];
}

sub hostname {
    my $self = shift;
    return $self->{'hostname'};
}

sub results {
    my $self = shift;
    my $rlist = $self->{'results'};
    return wantarray ? @$rlist : $rlist;
}

# Return a list or array ref of all values from all results for this host.
#
sub values {
    my $self = shift;
    my @vals = ();
    for my $result ($self->results()) {
	next if $result->error();
	push @vals, $result->values();
    }

    return wantarray ? @vals : \@vals;
}

use overload '""' => sub { hostname $_[0] };

1;

