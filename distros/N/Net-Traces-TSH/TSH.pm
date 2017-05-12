package Net::Traces::TSH;

use 5.6.1;
use strict;
use warnings;
use autouse 'Carp' => qw(carp croak confess);

our $VERSION = 0.16;

=head1 NAME

Net::Traces::TSH - Analyze IP traffic traces in TSH format

=head1 SYNOPSIS

  use Net::Traces::TSH qw(:traffic_analysis);

  # Display progress indicators
  #
  verbose;

  # Process the trace in file some_trace.tsh
  #
  process_trace 'some_trace.tsh';

  # Then, write a summary of the trace contents to some_trace.csv, in
  # comma-separated values (CSV) format
  #
  write_trace_summary 'some_trace.csv';

=cut

require Exporter;

our @ISA       = qw( Exporter );

our @EXPORT    = qw( );

# Exportable subroutine definitions
#
sub configure( % );
sub date_of( $ );
sub get_IP_address ( $ );
sub get_interfaces_href();
sub get_interfaces_list();
sub get_trace_summary_href();
sub process_trace( $ );
sub records_in( $ );
sub verbose();
sub write_interface_summaries( ; $);
sub write_trace_summary( ; $ );

our @EXPORT_OK = qw(
		    configure
		    date_of
		    get_IP_address
		    get_interfaces_href
		    get_interfaces_list
		    get_trace_summary_href
		    numerically
		    process_trace
		    records_in
		    verbose
		    write_interface_summaries
		    write_trace_summary
		   );

our %EXPORT_TAGS = (
		    traffic_analysis  => [ qw( verbose
					       process_trace
					       write_interface_summaries
					       write_trace_summary
					     )
					 ],

		    trace_information => [ qw( date_of records_in ) ],

		    all => [@EXPORT_OK],
		   );

# Internal/utility subroutine definitions
#
sub progress( $ );
sub write_summary( *$ ; $ );
sub print_value( *$ );

our %options;

# Load the IANA protocol numbers from the __DATA__ section.  If by any
# chance we end up having duplicate keywords, something must have
# corrupted the __DATA__ section, so abort.
#
my %iana_protocol_numbers;

INIT {
  while (<DATA>) {
    chomp;
    my ($k, $v) = split " ", $_, 2;

    # Sanity check
    #
    die "Duplicate IANA protocol keyword detected"
      if defined $iana_protocol_numbers{$k};

    $iana_protocol_numbers{$k} = $v;
  }

  # Default options, parameters and output
  #
  %options = (
	      # Do not display progress information
	      Verbosity => 0,

	      'Link Capacity' => 0, # Bits per second

	      # Filename to store TCP traffic in tcpdump format
	      tcpdump => 0,

	      # Filename to store TCP traffic in ns2 format
	      ns2 => 0,
	     );
}

# Used to sort the keys of a hash in numeric order instead of the
# default alphabetical order.  Borrowed from "Programming Perl 3/e" by
# Wall, Christiansen and Orwant (p. 790).
#
sub numerically { $a <=> $b; }

=head1 INSTALLATION

C<Net::Traces::TSH> can be installed like any CPAN module.  In
particular, consider using Andreas Koenig's CPAN module for all your
CPAN module installation needs.

To find out more about installing CPAN modules type

 perldoc perlmodinstall

at the command prompt.

If you have already downloaded the C<Net::Traces::TSH> tarball,
decompress and untar it, and proceed as follows:

 perl Makefile.PL
 make
 make test
 make install

=head1 DESCRIPTION

C<Net::Traces::TSH> can assist you in analyzing Internet Protocol (IP)
packet traces in Time Sequenced Headers (TSH) format, a binary network
trace format.  Daily TSH traces are available from the L<NLANR PMA web
site|"SEE ALSO">.  Each 44-byte TSH record corresponds to an IP packet
passing by a monitoring point.  Although there are no explicit
delimiters, each record is composed of three sections.

=over

=item Time and Interface

The first section uses 8 bytes to store the time (with microsecond
granularity) and the interface number of the corresponding packet, as
recorded by the (passive) monitor.

=item IP

The next 20 bytes contain the standard IP packet header.  IP options
are not recorded.

=item TCP

The third and last section contains the first 16 bytes of the standard
TCP segment header.  The TCP checksum, urgent pointer, and TCP options
(if any) are not included in a TSH record.

=back

If a record does not correspond to a TCP segment, it is not clear how
to interpret the last section.  As such, C<Net::Traces::TSH> makes no
assumptions, and does not analyze the last section of a TSH record
unless it corresponds to a TCP segment.  In other words,
C<Net::Traces::TSH> reports on protocols other than TCP based solely
on the first two sections.

The following diagram illustrates a TSH record.

     0                   1                   2                   3
     0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1  Section
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  0 |                      Timestamp (seconds)                      | Time
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  1 | Interface  No.|          Timestamp (microseconds)             |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  2 |Version|  IHL  |Type of Service|          Total Length         | IP
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  3 |         Identification        |Flags|      Fragment Offset    |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  4 |  Time to Live |    Protocol   |         Header Checksum       |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  5 |                       Source Address                          |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  6 |                    Destination Address                        |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  7 |          Source Port          |       Destination Port        | TCP
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  8 |                        Sequence Number                        |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
  9 |                    Acknowledgment Number                      |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    |  Data |       |C|E|U|A|P|R|S|F|                               |
 10 | Offset|RSRV-ed|W|C|R|C|S|S|Y|I|            Window             |
    |       |       |R|E|G|K|H|T|N|N|                               |
    +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

This diagram is an adaptation of the original TSH diagram (found on
the L<NLANR PMA web site|"SEE ALSO">), which reflects the changes due
to the addition of Explicit Congestion Notification (ECN) in the TCP
header flags.  Also, keep in mind that recent Internet Engineering
Task Force (IETF) Requests for Comments (RFCs) have deprecated the IP
header I<Type of Service> field in favor of L<Differentiated Services
and Explicit Congestion Notification|"SEE ALSO">.

You can use C<Net::Traces::TSH> to L<gather
information|"process_trace"> from a TSH packet trace, perform
statistical analysis on Transport protocol, Differentiated Services
(DiffServ) and ECN usage, and obtain packet and segment size
distributions.  The trace L<summary statistics|"write_trace_summary">
are stored in comma separated values (CSV), a platform independent
text format.

=head2 Data Structures

A single TSH trace may contain records for packets observed on several
different interfaces.  For example, the daily TSH traces from the
NLANR PMA repository typically contain records from two different
interfaces. In such cases, incoming and outgoing traffic can be
differentiated based on the interface number (despite the scrabbling of
IP addresses to protect privacy).  C<Net::Traces::TSH> users may be
interested in collecting statistical information for each interface
separately or aggregating across the entire trace.
C<Net::Traces::TSH> uses two hashes to maintain these statistics:
%Interfaces and %Trace.

B<%Interfaces> contains counts of several protocol particulars on a
per-interface basis.  For example, %Interfaces can tell you how many
IP packets, TCP segments, and UDP datagrams were recorded in the trace
for each interface.

B<%Trace> contains general information about the trace (date, number
of records, duration, number of interfaces, etc.) as well as the
aggregate data points across all interfaces.  As such, %Trace will
report the I<total> number of UDP datagrams in the trace, the total
number of TCP SYNs, and so on.

Both %Trace and %Interfaces are I<initialized and populated> by
L<process_trace|"process_trace">.  The recommended way to get the
trace summary information, after processing a trace is to call
L<write_trace_summary|"write_trace_summary">, which stores the
contents of %Trace in a CSV-formated text file, as shown in
L<SYNOPSIS|"SYNOPSIS">.  Similarly, If you want summaries for the
traffic on each interface, use
L<write_interface_summaries|"write_interface_summaries">.

Neither %Trace nor %Interfaces are exported by default and are not
meant to be accessed directly by user code.  However, if you know what
you are doing, you can get a reference to %Trace by calling
L<get_trace_summary_href|"get_trace_summary_href">, and a reference to
%Interfaces by calling L<get_interfaces_href|"get_interfaces_href">.
If you choose to do so, the following subsections explain how you can
access some of the information stored in %Trace.  The %Interfaces
structure is virtually the same only lacking the "general trace
information" part.  See also L<Using the Net::Trace::TSH trace summary
hashes|"Using the Net::Trace::TSH trace summary hashes">.

=head3 General Trace Information

=over

=item $Trace{filename}

The L<trace FILENAME|"process_trace">.

=item $Trace{date}

The estimated date of the trace (see L<date_of|date_of>).

=item $Trace{summary}

The trace L<summary FILENAME|"write_trace_summary">.

=item $Trace{starts}

The first trace timestamp, in seconds, as it is recorded in the trace.

=item $Trace{ends}

The last trace timestamp, in seconds, after being "normalized".
Essentially, the number of seconds since $Trace{starts}.

=item $Trace{records}

L<Number of records|"records_in"> in the trace.

Similarly, if I<$if> is the interface number,
C<$Interfaces{$if}{records}> contains the number or records
corresponding to packets observed on interface I<$if>.

=item $Trace{interfaces}

Number of interfaces recorded in the trace.

=item $Trace{unidirectional}

True, if each interface carries unidirectional traffic.

False, if there is bidirectional traffic in at least one interface.

C<undef> if traffic directionality was not examined.

=item $Trace{'Link Capacity'}

The L<capacity of the monitored link|"configure"> in bits per
second (b/s).

=back

=head3 Internet Protocol

=over

=item $Trace{IP}{Total}{Packets}

=item $Trace{IP}{Total}{Bytes}

Number of IP packets and bytes, respectively, in the trace.  The
number of IP packets should equal the number of records in the trace.

As mentioned earlier, %Trace has virtually the same structure as
%Interfaces. Therefore, if I<$if> is the interface number,
C<$Interfaces{$if}{IP}{Total}{Packets}> and
C<$Interfaces{$if}{IP}{Total}{Bytes}> contain the number of IP
packets and bytes, respectively, observed on interface I<$if>.  The
same "rule" applies to all %Trace fields presented below.

=back

=head4 Fragmentation

=over

=item $Trace{IP}{DF}{Packets}

=item $Trace{IP}{DF}{Bytes}

Number of IP packets and bytes, respectively, requesting no
fragmentation ('Do not Fragment').

=item $Trace{IP}{MF}{Packets}

=item $Trace{IP}{MF}{Bytes}

Number of IP packets and bytes, respectively, indicating that 'More
Fragments' follow.

=back

=head4 Differentiated Services

=over

=item $Trace{IP}{Normal}{Packets}

=item $Trace{IP}{Normal}{Bytes}

Number of IP packets and bytes, respectively, requesting no particular
treatment (best effort traffic).  No DiffServ or ECN bits are set.

=item $Trace{IP}{'Class Selector'}{Packets}

=item $Trace{IP}{'Class Selector Bytes'}

Number of IP packets and bytes, respectively, with Class Selector bits
set.

=item $Trace{IP}{'AF PHB Packets'}

=item $Trace{IP}{'AF PHB Bytes'}

Number of IP packets and bytes, respectively, requesting Assured
Forwarding Per-Hop Behavior (PHB).

=item $Trace{IP}{'EF PHB'}{Packets}

=item $Trace{IP}{'EF PHB'}{Bytes}

Number of IP packets and bytes, respectively, requesting Expedited
Forwarding Per-Hop Behavior (PHB)

=back

=head4 Explicit Congestion Notification

=over

=item $Trace{IP}{ECT}{Packets}

=item $Trace{IP}{ECT}{Bytes}

Number of IP packets and bytes, respectively, with either of the ECT
bits set.  These packets should be carrying traffic from ECN-aware
hosts.

=item $Trace{IP}{CE}{Packets}

=item $Trace{IP}{CE}{Bytes}

Number of IP packets and bytes, respectively, with the CE bit set.
These packets carry ECN-capable traffic that has been marked at an
ECN-aware router.

=back

=head4 IP Options

=over

=item $Trace{IP}{'No IP Options'}{Packets}

=item $Trace{IP}{'No IP Options'}{Bytes}

Number of IP packets and bytes, respectively, carrying no IP header options.

=item $Trace{IP}{'IP Options'}{Packets}

=item $Trace{IP}{'IP Options'}{Bytes}

Number of IP packets and bytes, respectively, carrying IP header options.

=back

The following diagram summarizes the %Trace data structure up to here.

 Trace
   - filename
   - summary
   - date
   - starts
   - ends
   - records
   - interfaces
   - unidirectional
   - 'Link Capacity'
   - IP
       - Total
           - Packets
           - Bytes
       - DF
           - Packets
           - Bytes
       - MF
           - Packets
           - Bytes
       - Normal
           - Packets
           - Bytes
       - 'Class Selector'
           - Packets
           - Bytes
       - 'AF PHB'
           - Packets
           - Bytes
       - 'EF PHB'
           - Packets
           - Bytes
       - ECT
           - Packets
           - Bytes
       - CE
           - Packets
           - Bytes
       - 'No IP Options'
           - Packets
           - Bytes
       - 'IP Options'
           - Packets
           - Bytes

=head3 Transport Protocols

Besides the summary information about the trace itself and statistics
about IP, %Trace maintains information about the transport protocols
present in the trace.  Based on the IP header, %Trace maintains the
same statistics mentioned in the L<previous section|"Internet
Protocol"> for all transport protocols with an IANA assigned number
(including, of course, TCP and UDP).  For example,

=over

=item $Trace{Transport}{TCP}{Total}{Packets}

=item $Trace{Transport}{TCP}{Total}{Bytes}

Number of TCP segments and the corresponding bytes (including the IP
and TCP headers) in the trace.

=item $Trace{Transport}{UDP}{Total}{Packets}

=item $Trace{Transport}{UDP}{Total}{Bytes}

Ditto, for UDP.

=item $Trace{Transport}{ICMP}{DF}{Packets}

=item $Trace{Transport}{ICMP}{DF}{Bytes}

Number of ICMP packets and bytes, respectively, with the DF bit set.

=back

=head2 Using the Net::Trace::TSH trace summary hashes

The following example creates the trace summary file only if TCP
accounts for more than 90% of the total IP traffic, in terms of bytes.

 # Explicitly import process_trace(), write_trace_summary(), and
 # get_trace_summary_href():

 use Net::Traces::TSH qw( process_trace
                          write_trace_summary
                          get_trace_summary_href
                        );

 # Process a trace file...
 #
 process_trace "some.tsh";

 # Get a reference to %Trace
 #
 my $ts_href = get_trace_summary_href;

 # ...and generate a summary only if the condition is met.
 #
 write_trace_summary
    if ( ( $ts_href->{Transport}{TCP}{Total}{Bytes}
           / $ts_href->{IP}{Total}{Bytes}
         ) > 0.9
       );

=cut

# Hash containing aggregate (across all interfaces) information about
# the trace currently being processed.  Daily TSH traces from NLANR
# PMA usually contain records from two interfaces (incoming and
# outgoing).
#
my %Trace;

# Hash containing per-interface information about the trace currently
# being processed.
#
my %Interfaces;

# Make sure that all data points are accounted for and are in correct
# order, thus saving some of hash key sorting operations.  Moreover,
# this allows us to use more descriptive, i.e. self-documenting hash
# key names for the data hashes, %Trace and %Interfaces.
#
my @data_points = ( 'Total', 'DF', 'MF', 'ECT', 'CE',
		    'Normal', 'Class Selector', 'AF PHB', 'EF PHB',
		    'No IP Options', 'IP Options'
		  );

=head1 FUNCTIONS

C<Net::Traces::TSH> does not export any functions by default.  The
following functions, listed in alphabetical order, are
L<exportable|"EXPORTS">.

=head2 configure

  configure %OPTIONS

Used to specify verbosity, the link capacity, and the types of outputs
requested.  For example,

 configure(
           # Display progress information, equivalent to calling verbose()
           #
           Verbosity       => 1, # default is 0, no progress information

           'Link Capacity' => 100_000_000, # bits per second

           # Convert the TCP records in the TSH trace to tcpdump
           # format and store in 'trace.tcpdump'.
           #
           tcpdump         => 'trace.tcpdump',

           # Convert the TCP data-carrying segment records to binary
           # ns2 traffic trace format.  Create one binary file per
           # interface and use 'trace.ns2' as the file prefix.
           #
           ns2         => 'trace.ns2',

          );

=cut

sub configure ( % ) {
  while ( defined ($_ = shift) ) {
    if ( defined $options{$_} ) {
      $options{$_} = shift;
    }
    else {
      $options{$_} = undef;
      shift;
      carp "Ignoring unknown configuration option '$_'...";
    }
  }
}

=head2 date_of

  date_of FILENAME

TSH traces downloaded from the L<NLANR PMA trace repository|"SEE
ALSO"> typically contain a timestamp as part of their filename.
date_of() converts the timestamp to a human readable format.  That is,
if FILENAME contains a valid timestamp, date_of() returns the
corresponding GMT date as a human readable string.  For example,

 date_of 'ODU-1073132115.tsh'

returns C<Sat Jan  3 12:15:15 2004 GMT>.

If the FILENAME does not contain a timestamp, date_of() returns
I<false>.

Note that there is nothing special about FILENAME: It can be any
string.  The goal here is to get an idea of the period the trace was
collected.

=cut

sub date_of( $ ) {
  $_ = shift and /(\d{10})/ and return join ' ', scalar gmtime $1, 'GMT';
}

=head2  get_IP_address

 get_IP_address INTEGER

Converts a 32-bit integer to an IP address in dotted decimal
notation. For example,

 get_IP_address(167772172)

returns C<10.0.0.12>.

=cut

sub get_IP_address ( $ ) {
  return join '.', unpack('C4', pack('N', shift));
}

=head2 get_interfaces_href

 get_interfaces_href

Returns a hash I<reference> to L<%Interfaces|"Data Structures">.

=cut

sub get_interfaces_href() {

  return \%Interfaces;

}


=head2 get_interfaces_list

 get_interfaces_list

In list context returns a sorted list of all interfaces recorded in
the trace.  In scalar context returns the number of unique interfaces
in the trace.

=cut

sub get_interfaces_list() {

  return wantarray ? sort numerically keys %Interfaces
                   : scalar keys %Interfaces;

}

=head2 get_trace_summary_href

 get_trace_summary_href

Returns a hash I<reference> to L<%Trace|"Data Structures">.

=cut

sub get_trace_summary_href() {

  return \%Trace;

}

=head2 process_trace

 process_trace FILENAME

In a void context, process_trace() examines the binary TSH trace stored
in FILENAME, and populates L<%Trace and %Interfaces|"Data
Structures">.

In a list context process_trace() in addition to collecting summary
statistics, it extracts all TCP flows and TCP data-carrying segments
from the trace, returning two hash references.  For example,

 my ($senders_href, $segments_href) = process_trace 'trace.tsh';

will process C<trace.tsh> and return two hash references:
I<$senders_href> and I<$segments_href>.

I<$senders_href> is a reference to a hash which contains an entry for
each TCP sender in the trace file.  A TCP sender is identified by the
ordered 4-tuple

 (src, src port, dst, dst port)

where I<src> and I<dst> are the L<32-bit integers|"get_IP_address">
corresponding to the IP addresses of the sending and receiving hosts,
respectively.  Similarly, I<src port> and I<dst port> are the sending
and receiving processes' port numbers.  Senders are categorized on a
per interface basis.  For example, the following accesses the list of
segments sent from 10.0.0.12:80 to 10.0.0.14:1080 (on interface 1):

 $senders_href->{1}{167772172,80,167772174,1080}

Each hash entry is a list of timestamps extracted from the trace
records and stored after being "normalized" (start of trace = 0.0
seconds, always).

In theory, records corresponding to packets transmitted on the same
interface should have different timestamps.  In practice, although it
is not very likely that two data segments have the same timestamp, I
encountered a few traces that did have duplicate timestamps.
process_trace() checks for such cases and implements a timestamp
"collision avoidance" algorithm.  A timestamp collision threshold is
defined and is currently set to 3.  Trace processing is aborted if the
number of records with the same timestamp exceeds this threshold.  If
you encounter such traces, it is not a bad idea to investigate why
this is happening, as the trace may be corrupted.

The second returned value, I<$segments_href>, is another hash
reference, which can be used to access any individual I<data-carrying
TCP segment> in the trace.  Again, segments are categorized on a per
interface basis.  Three values are stored per segment: the total
number of bytes (including IP and TCP headers, and application
payload), the segment sequence number, and whether the segment was
retransmitted or not.

For example, assuming the first record corresponds to a TCP segment,
here is how you can print its packet size and the sequence number
carried in the TCP header:

 my $interface = 1;
 my $timestamp = 0.0;

 print $segments_href->{$interface}{$timestamp}{bytes};
 print $segments_href->{$interface}{$timestamp}{seq_num};

You can also check whether a segment was retransmitted or not:

 if ( segments_href->{$interface}{$timestamp}{retransmitted} ) {
   print "Segment was retransmitted by the TCP sender.";
 }
 else {
   print "Segment must have been acknowledged by the TCP receiver.";
 }

Note that process_trace() only initializes the "retransmitted" value
to false (0).  It is write_sojourn_times() that detects retransmitted
segments and updates the "retransmitted" entry to I<true>, if it is
determined that the segment was retransmitted.

CAVEAT: write_sojourn_times() is not currently included in the stable,
CPAN version of the module.  L<Contact me|"AUTHOR"> if you want to get
a copy of the bleeding edge version.

=head3 Using a TSH trace in ns2 simulations

In addition to extracting %senders and %segments, C<Net::Traces::TSH>
allows you to generate binary files suitable for driving L<ns2
simulations|"SEE ALSO">.  For example,

 configure(ns2 => 'some.tsh');

 process_trace 'some.tsh';

After the call to configure(), process_trace() will generate a binary
file for each interface found in the trace.  For example, assume that
F<some.tsh> has recorded traffic from two interfaces, 1 and 2.
process_trace() will generate two binary files:

  some.tsh-if1.bin
  some.tsh-if2.bin

Each of these files L<can be used in ns2 simulations|"SEE ALSO"> in
conjunction Application/Traffic/Trace.  For example, the following ns2
script fragment illustrates how to attach F<some.tsh-if2.bin> to a
traffic source

 # ...

 # Initialize a trace file
 #
 set tfile [new Tracefile]
 $tfile filename some.tsh-2.bin

 # Attach the tracefile
 #
 set trace [new Application/Traffic/Trace]
 $trace attach-tracefile $tfile

 # ...

Note that both F<some.tsh-if1.bin> and F<some.tsh-if1.bin> include
only the I<TCP data-carrying segments> in the trace.  If you want to
convert the I<entire> TSH trace to Traffic/Trace files, see
C<converters/tsh2ns2.pl>.


=head3 Converting TSH to F<tcpdump>

If you would like to extract the TCP traffic and store it in
F<tcpdump> format, use

 configure(tcpdump => 'tcpdump_filename');

before calling process_trace(). process_trace() will generates a text
file based on the trace records in a format similar to the modified
output of F<tcpdump>, as presented in I<TCP/IP Illustrated Volume 1>
by W. R. Stevens (see pp. 230-231).

You can use such an output as input to other tools, present real
traffic scenarios in a classroom, or simply "eyeball" the trace.  For
example, here are the first ten lines of the contents of such a file:

 0.000000000 10.0.0.1.6699 > 10.0.0.2.55309: . ack 225051666 win 65463
 0.000014000 10.0.0.3.80 > 10.0.0.4.14401: S 457330477:457330477(0) ack 810547499 win 34932
 0.000014000 10.0.0.1.6699 > 10.0.0.2.55309: . 3069529864:3069531324(1460) ack 225051666 win 65463
 0.000024000 10.0.0.5.12119 > 10.0.0.6.80: F 2073668891:2073668891(0) ack 183269290 win 64240
 0.000034000 10.0.0.7.4725 > 10.0.0.8.445: S 3152140131:3152140131(0) win 16384
 0.000067000 10.0.0.1.6699 > 10.0.0.2.55309: P 3069531324:3069531944(620) ack 225051666 win 65463
 0.000072000 10.0.0.11.3381 > 10.0.0.12.445: S 1378088462:1378088462(0) win 16384
 0.000083000 10.0.0.13.1653 > 10.0.0.1.6699: P 3272208349:3272208357(8) ack 501563814 win 32767
 0.000093000 10.0.0.14.1320 > 10.0.0.15.445: S 3127123478:3127123478(0) win 64170
 0.000095000 10.0.0.4.14401 > 10.0.0.3.80: R 810547499:810547499(0) ack 457330478 win 34932

Note that this output is similar to what F<tcpdump> with options C<-n>
and C<-S> would have produced.  The only missing fields are related to
the TCP options negotiated during connection setup.  Unfortunately,
L<TSH records|"DESCRIPTION"> include only the first 16 bytes of the
TCP header, making it impossible to record the options from the
segment header.

=cut

# A TSH record is 44 bytes long.
#
use constant TSH_RECORD_LENGTH => 44;

# If more than so many records have the same timestamp, abort
# processing.
#
use constant TIMESTAMP_COLLISION_THRESHOLD => 3;

sub process_trace( $ ) {

  # Sanity checks
  #
  my $trace = shift;
  croak 'No trace filename provided' unless $trace;

  my $records = records_in $trace;
  croak "Number of records in $trace not an integer. Is $trace corrupted?"
    unless $records;

  # Open trace file
  #
  open(INPUT, '<', $trace)
    or croak "Cannot open $trace for processing. $!";

  binmode INPUT; # Needed for non-UNIX OSes; no harm in UNIX

  $options{tcpdump} and
    ( open(TCPDUMP, '>', $options{tcpdump})
      or croak "Cannot open $options{tcpdump}. $!"
    );

  my %ns2_fh;
  my %ns2_previous_timestamp;

  progress "Initializing data structures... ";

  %Trace = %Interfaces = ();

  $Trace{filename} = $trace;
  $Trace{records} = $records;
  $Trace{'Link Capacity'} = $options{'Link Capacity'};

  # If process_trace() is called in a void context, we will not
  # examine traffic direction, thus undef $Trace{unidirectional}.
  # Otherwise, assume that traffic is unidirectional, until proven
  # otherwise.
  #
  $Trace{unidirectional} = defined wantarray ? 1 : undef;

  my (%senders, %segments);

  progress "Processing $Trace{filename}...\n";

  # Read the trace file, record by record
  #
  my $record;

  while( read(INPUT, $record, TSH_RECORD_LENGTH) ) {
    # Extract the fields from the TSH record in a platform-independent way
    #
    my ($t_sec,
	$if, $t_usec,
	$version_ihl, $tos, $ip_len,
	$id, $flags_offset,
	$ttl, $protocol, $chk_sum,
	$src,
	$dst,
	$src_port, $dst_port,
	$seq_num,
	$ack_num,
	$data_offset, $tcp_flags, $win) =
	  unpack( "# Time
                   N       # timestamp (seconds)
                   C B24   # interface, timestamp (microseconds)

                   # IP
                   C C n   # Version & IHL, Type of Service, Total Length
                   n n     # Identification, Flags & Fragment Offset
                   B8 B8 n # TTL, Protocol, Header Checksum
                   N       # Source Address
                   N       # Destination Address

                   # TCP
                   n n     # Source Port, Destination Port
                   N       # Sequence Number
                   N       # Acknowledgment Number
                   C C n   # Data Offset & Reserved bits, Flags, Window
                  ", $record
		);

    ##################################################################
    #                           TIME
    ##################################################################
    # Sanity: make absolutely sure that $t_sec is considered an
    # integer in the code below
    #
    $t_sec = int $t_sec;

    # Extract the microseconds part of the timestamp
    #
    $t_usec = oct("0b$t_usec") / 1_000_000;

    # Sanity check
    #
    croak 'Microseconds record field exceeds 1,000,000. Processing aborted'
      unless $t_usec < 1;

    unless ( defined $Trace{starts} ) {
      # Get the first timestamp in the trace, and use it to normalize
      # the rest of the timestamps in the trace.
      #
      $Trace{starts} = $t_sec + $t_usec;

      # Identify the period the trace was collected
      #
      $Trace{date} = date_of $Trace{filename} || date_of $t_sec || 'Unknown';

      # Timestamp of the last processed record.
      #
      $Trace{ends} = 0.0;
    }

    $Interfaces{$if}{records}++;

    # Combine the two parts of the timestamp ($t_sec and $t_usec) in
    # one variable and normalize using the first timestamp in the trace
    #
    my $timestamp = $t_sec + $t_usec - $Trace{starts};

    # Convert the $protocol number to the corresponding protocol name
    #
    $protocol = $iana_protocol_numbers{oct "0b$protocol"} || 'Unknown';

    # Sanity check: Timestamps must increase monotonically in a TSH
    # trace.
    #
    if ( $Trace{ends} > $timestamp ) {
      # If this is a TCP segment then this can play a big role if we
      # are interested in extracting the segment time series, so it's
      # better that we abort processing.
      #
      print "Timestamps do not increase monotonically (Prot $protocol)\n";

      croak "Processing aborted for $Trace{filename}" if wantarray;
    }

    ##################################################################
    #                              IP
    ##################################################################
    $Interfaces{$if}{IP}{Total}{Packets}++;
    $Interfaces{$if}{IP}{Total}{Bytes} += $ip_len;

    # Packet size distribution
    #
    $Interfaces{$if}{IP}{'Packet Size'}{$ip_len}++;

    # Get the IP version
    #
    my $version = ($version_ihl & 0xf0) >> 4;

    # We shouldn't see anything other than IPv4.  If we do, issue a
    # warning.
    #
    carp "IPv$version packet detected" unless $version == 4;

    # Get the IP header length (IHL)
    #
    my $ihl = ($version_ihl & 0xf) << 2;

    ##################################################################
    #                      Transport protocols
    ##################################################################
    $Interfaces{$if}{Transport}{$protocol}{Total}{Packets}++;
    $Interfaces{$if}{Transport}{$protocol}{Total}{Bytes} += $ip_len;

    # Packet size distribution
    #
    $Interfaces{$if}{Transport}{$protocol}{'Packet Size'}{$ip_len}++;

    ##################################################################
    #                      D(o not)F(ragment) bit
    ##################################################################
    if ($flags_offset & 0x4000) {
      $Interfaces{$if}{IP}{DF}{Packets}++;
      $Interfaces{$if}{IP}{DF}{Bytes} += $ip_len;

      $Interfaces{$if}{Transport}{$protocol}{DF}{Packets}++;
      $Interfaces{$if}{Transport}{$protocol}{DF}{Bytes} += $ip_len;
    }

    ##################################################################
    #                      M(ore)F(ragments) bit
    ##################################################################
    if ($flags_offset & 0x2000) {
      $Interfaces{$if}{IP}{MF}{Packets}++;
      $Interfaces{$if}{IP}{MF}{Bytes} += $ip_len;

      $Interfaces{$if}{Transport}{$protocol}{MF}{Packets}++;
      $Interfaces{$if}{Transport}{$protocol}{MF}{Bytes} += $ip_len;
    }

    ##################################################################
    #                             DiffServ
    ##################################################################
    #
    # Convert the ToS field and gather DiffServ statistics.
    #
    # Extract the Differentiated Services Code Point (DSCP) from ToS
    #
    my $dscp = $tos >> 2;

    if ( $dscp == 0 ) {
      # The usual suspect, the default value most of the time.  This
      # is compatible with RFC 791 (original ToS definition), RFC 1349
      # (updated ToS definition), RFC 2474 (DiffServ defines DSCP),
      # RFC 2780: No DiffServ code point (DSCP) set
      #
      $Interfaces{$if}{IP}{Normal}{Packets}++;
      $Interfaces{$if}{IP}{Normal}{Bytes} += $ip_len;

      $Interfaces{$if}{Transport}{$protocol}{Normal}{Packets}++;
      $Interfaces{$if}{Transport}{$protocol}{Normal}{Bytes} += $ip_len;
    }
    elsif ( $dscp % 0b001000 == 0 ) {
      # Class Selector Code points     -- RFC 2474
      #
      $Interfaces{$if}{IP}{'Class Selector'}{Packets}++;
      $Interfaces{$if}{IP}{'Class Selector'}{Bytes} += $ip_len;

      $Interfaces{$if}{Transport}{$protocol}{'Class Selector'}{Packets}++;
      $Interfaces{$if}{Transport}{$protocol}{'Class Selector'}{Bytes}
	+=$ip_len;
    }
    elsif ( $dscp % 2 == 0 ) {
      $dscp >>= 1;
      if ( 0b00100 < $dscp and $dscp < 0b10100 ) {
	# Assured Forwarding (AF) PHB -- RFC 2597
	#
	$Interfaces{$if}{IP}{'AF PHB'}{Packets}++;
	$Interfaces{$if}{IP}{'AF PHB'}{Bytes} += $ip_len;

	$Interfaces{$if}{Transport}{$protocol}{'AF PHB'}{Packets}++;
	$Interfaces{$if}{Transport}{$protocol}{'AF PHB'}{Bytes} += $ip_len;
      }
      elsif ( $dscp == 0b10111 ) {
	# Expedited Forwarding (EF) PHB -- RFC 2598
	#
	$Interfaces{$if}{IP}{'EF PHB'}{Packets}++;
	$Interfaces{$if}{IP}{'EF PHB'}{Bytes} += $ip_len;

	$Interfaces{$if}{Transport}{$protocol}{'EF PHB'}{Packets}++;
	$Interfaces{$if}{Transport}{$protocol}{'EF PHB'}{Bytes} += $ip_len;
      }
    }

    ##################################################################
    #                             ECN
    ##################################################################
    #
    # Extract ECN from ToS and gather ECN statistics
    #
    my $ecn = $tos & 0b11;
    if ( $ecn ) {
      $Interfaces{$if}{IP}{ECT}{Packets}++;
      $Interfaces{$if}{IP}{ECT}{Bytes} += $ip_len;

      $Interfaces{$if}{Transport}{$protocol}{ECT}{Packets}++;
      $Interfaces{$if}{Transport}{$protocol}{ECT}{Bytes} += $ip_len;
    }

    if ( $ecn == 0b11 ) {
      $Interfaces{$if}{IP}{CE}{Packets}++;
      $Interfaces{$if}{IP}{CE}{Bytes} += $ip_len;

      $Interfaces{$if}{Transport}{$protocol}{CE}{Packets}++;
      $Interfaces{$if}{Transport}{$protocol}{CE}{Bytes} += $ip_len;
    }

    ##################################################################
    #                          IP Options
    ##################################################################
    if ( $ihl ==  20 ) {
      $Interfaces{$if}{IP}{'No IP Options'}{Packets}++;
      $Interfaces{$if}{IP}{'No IP Options'}{Bytes} += $ip_len;

      $Interfaces{$if}{Transport}{$protocol}{'No IP Options'}{Packets}++;
      $Interfaces{$if}{Transport}{$protocol}{'No IP Options'}{Bytes} += $ip_len;
    }
    elsif ( $ihl > 20 ) {
      $Interfaces{$if}{IP}{'IP Options'}{Packets}++;
      $Interfaces{$if}{IP}{'IP Options'}{Bytes} += $ip_len;

      $Interfaces{$if}{Transport}{$protocol}{'IP Options'}{Packets}++;
      $Interfaces{$if}{Transport}{$protocol}{'IP Options'}{Bytes} += $ip_len;
    }
    else {
      # This is an extremely unlikely event, but just in case...
      #
      carp "IP header with only $ihl bytes detected";
    }

    ##################################################################
    #                       TCP-related counts
    ##################################################################
    if ( $protocol eq 'TCP' ) {
      # Extract TCP header length from $data_offset, and right shift,
      # since the TCP header length is expressed in 4-byte words.
      #
      my $tcp_hl = ( $data_offset & 0xf0 ) >> 2;
      my $tcp_payload = $ip_len - $ihl - $tcp_hl;

      # TCP flags
      #
      my ($cwr, $ece, $urg, $ack, $psh, $rst, $syn, $fin) =
	split '', unpack('B8', pack('C', $tcp_flags));

      if ( $syn ) {
	# Count the number of SYNs, SYN/ACKs and SYNs carrying a
	# payload in the trace.
	#
	$Interfaces{$if}{Transport}{TCP}{SYN}{$tcp_hl}++;
	$Interfaces{$if}{Transport}{TCP}{'SYN/ACK'}{$tcp_hl}++
	  if $ack;
	$Interfaces{$if}{Transport}{TCP}{'SYN/Payload'}++
	  if $tcp_payload > 0;

	# Collect the receiver's advertised window (awnd), for all
	# SYNs that have the standard TCP header.  We will refer to
	# that as the "hard count".  For larger SYNs, we cannot say
	# for sure what is the receiver's advertised window, but we
	# can collect a count for comparison (rwnd).  We will refer to
	# this as the "soft count".
	#
	$Interfaces{$if}{Transport}{TCP}{rwnd}{$win}++;
	$Interfaces{$if}{Transport}{TCP}{awnd}{$win}++
	  if $tcp_hl == 20;
      }

      # Count the number of ACKs, pure ACKs, etc.
      #
      if ( $ack ) {
	if ( $tcp_hl < 20 ) {
	  # Yet another extremely unlikely event, but just in case...
	  #
	  carp "TCP header with only $tcp_hl bytes detected and ignored";
	}
	else {
	  $Interfaces{$if}{Transport}{TCP}{'Total ACKs'}++;

	  if ( $tcp_hl == 20 ) {
	    $Interfaces{$if}{Transport}{TCP}{'Cumulative ACKs'}++;

	    $Interfaces{$if}{Transport}{TCP}{'Pure ACKs'}++
	      if $tcp_payload == 0;
	  }
	  else {
	    $Interfaces{$if}{Transport}{TCP}{'Options ACKs'}++;
	    $Interfaces{$if}{Transport}{TCP}{'ACK Option Size'}{$tcp_hl}++;
	  }
	}
      }

      ##################################################################
      #                Export %senders and %segments
      ##################################################################
      # Determine if we should collect statistics about the %senders and
      # the %segments.  If process_trace() was called in a void context
      # then we do not need to collect such data, which results in
      # tremendous memory usage savings.
      #
      if ( $tcp_payload > 0 ) {
	if ( wantarray ) {
	  # Add elements to the hashes ONLY if the segment carries
	  # some payload.  This way, one can be more sure if a given
	  # segment was retransmitted or not, since ACKs are not
	  # guaranteed reliable delivery.
	  #
	  # Occasionally, we may get 2 or more TCP segments with the
	  # same $timestamp.  We would like to keep them in the
	  # segments hash and be able to discriminate between the
	  # different segments, so we use the following (hash)
	  # collision avoidance mechanism.
	  #
	  my $collisions = 0;

	  while ( exists $segments{$if}{$timestamp}{bytes} ) {
	    # Sanity check: If more than TIMESTAMP_COLLISION_THRESHOLD
	    # trace records have the same timestamp, it is better to
	    # abort processing.  Theoretically there shouldn't be two
	    # segments with the same timestamp.
	    #
	    croak 'Too many duplicate timestamps: ', $collisions,
	          ' trace records have the same timestamp. Processing aborted'
	    if $collisions++ == TIMESTAMP_COLLISION_THRESHOLD;

	    carp "Duplicate timestamp $timestamp detected & replaced with ",
	         $timestamp .= "1";

	    $Trace{Transport}{TCP}{'Concurrent Segments'}++;
	  }

	  # Store the total length of the segment (headers +
	  # application payload), and the sequence number it carries
	  #
	  $segments{$if}{$timestamp}{bytes} = $ip_len;
	  $segments{$if}{$timestamp}{seq_num} = $seq_num;

	  # In addition, flag by default every segment as an original
	  # transmission.  Detection of retransmitted segments is not
	  # done in process_trace(), but rather in
	  # write_sojourn_times()
	  #
	  $segments{$if}{$timestamp}{retransmitted} = undef;

	  # Add the packet timestamp to the respective sender list
	  #
	  push @{ $senders{$if}{"$src,$src_port,$dst,$dst_port"} },
	     $timestamp;

	  # Flag bidirectional traffic found in the *same* interface.
	  # If bidirectional traffic is present in the same interface,
	  # it is not clear (yet) how to isolate "incoming" from
	  # "outgoing" traffic.
	  #
	  $Trace{unidirectional} = 0
	    if ( $Trace{unidirectional} and
		 exists $senders{$if}{"$dst,$dst_port,$src,$src_port"}
	       );
	}

	##################################################################
	#        Export TSH to ns2 binary traffic trace format
	##################################################################
	# Generate an ns2 binary traffic trace. (TCP data-carrying
	# segements only)
	#
	if ( $options{ns2} ) {

	  unless ( defined $ns2_fh{$if}) {
	    open($ns2_fh{$if}, '>', "$options{ns2}-if$if.bin")
	      or croak "Cannot open $options{ns2}-if$if.bin. $!";
	    binmode $ns2_fh{$if}; # Needed for non-UNIX OSes; no harm in UNIX

	    $ns2_previous_timestamp{$if} = $timestamp;
	  }

	  print
	    { $ns2_fh{$if} }
	    pack('NN', # two integers: interpacket time (usec), packet size (B)
		 sprintf("%.0f", ( $timestamp
				   - $ns2_previous_timestamp{$if} ) * 1_000_000
			),
		 $ip_len
		);

	  $ns2_previous_timestamp{$if} = $timestamp;
	}
      }

      ##################################################################
      #                Export TSH to tcpdump format
      ##################################################################
      # Print a tcpdump-like time line of the TSH trace (for TCP
      # segments only)
      #
      if ( $options{tcpdump}) {
	printf TCPDUMP "%1.9f ", $timestamp;
	print TCPDUMP
	  get_IP_address $src, ".$src_port > ",
	  get_IP_address $dst, ".$dst_port: ",

	  $syn ? 'S' : '', # SYN: Synchronize sequence numbers
	  $fin ? 'F' : '', # FIN: Sender is finished sending data
	  $psh ? 'P' : '', # PSH: Push data to receiving process ASAP
	  $rst ? 'R' : '', # RST: Reset Connection
	  $cwr ? 'C' : '', # ECN: Congestion Window Reduced bit
	  $ece ? 'E' : '', # ECN: ECN-capable Transport

	  ($syn + $fin + $psh + $rst + $cwr + $ece) ? ' ' : '. ',

	  ($tcp_payload or $syn or $fin or $rst)
	    ? join('', "$seq_num:", $seq_num + $tcp_payload, "($tcp_payload) ")
	    : '',

	  $ack ? "ack $ack_num " : '',
	  "win $win ",
	  $urg ? "urg 1\n": "\n",
	}
    }

    # The following is used both for sanity checks and to store the
    # the duration of the trace
    #
    $Trace{ends} = $Interfaces{$if}{ends} = $timestamp;

  } # end of while( read...)

  close INPUT;

  close TCPDUMP and
    progress "TCP activity stored in text format in $options{tcpdump}\n"
  if $options{tcpdump};

  carp $Trace{Transport}{TCP}{'Concurrent Segments'},
    ' TCP segments had the same timestamp with another segment'
  if $Trace{Transport}{TCP}{'Concurrent Segments'} and wantarray;

  # Since we keep track of statistics on a per-interface basis, we
  # need to copy the data to %Trace for backwards compatibility.
  #
  my @interfaces = get_interfaces_list;
  $Trace{interfaces} = scalar @interfaces;

  my $total_records = 0;

  foreach my $if ( @interfaces ) {

    $total_records += $Interfaces{$if}{records};

    no warnings qw(uninitialized);

    my @transports = sort keys %{$Interfaces{$if}{Transport}};

    foreach my $metric ('Packets', 'Bytes') {
      foreach ( @data_points ) {
	$Trace{IP}{$_}{$metric} += $Interfaces{$if}{IP}{$_}{$metric};

	foreach my $protocol ( @transports ) {
	  $Trace{Transport}{$protocol}{$_}{$metric}
	    += $Interfaces{$if}{Transport}{$protocol}{$_}{$metric};
	}
      }
    }

    # ACKs
    #
    foreach ( 'Total ACKs', 'Cumulative ACKs', 'Pure ACKs', 'Options ACKs' ) {
      $Trace{Transport}{TCP}{$_} += $Interfaces{$if}{Transport}{TCP}{$_};
    }

    # Advertised window
    #
    foreach ( keys %{$Interfaces{$if}{Transport}{TCP}{rwnd}} ) {
      $Trace{Transport}{TCP}{rwnd}{$_}
	+= $Interfaces{$if}{Transport}{TCP}{rwnd}{$_};

      $Trace{Transport}{TCP}{awnd}{$_}
	+= $Interfaces{$if}{Transport}{TCP}{awnd}{$_};
    }

    # SYN and SYN/ACKs
    #
    foreach ( keys %{$Interfaces{$if}{Transport}{TCP}{SYN}} ) {
      $Trace{Transport}{TCP}{SYN}{$_}
	+= $Interfaces{$if}{Transport}{TCP}{SYN}{$_};

      $Trace{Transport}{TCP}{'SYN/ACK'}{$_}
	+= $Interfaces{$if}{Transport}{TCP}{'SYN/ACK'}{$_};

      $Trace{Transport}{TCP}{'SYN/Payload'}
	+= $Interfaces{$if}{Transport}{TCP}{'SYN/Payload'};
    }

    # TCP Options ACKs
    #
    while ( my ($k, $v) = each
	    %{$Interfaces{$if}{Transport}{TCP}{'ACK Option Size'}} ) {
      $Trace{Transport}{TCP}{'ACK Option Size'}{$k} += $v;
    }

    # Packet size distribution
    #
    while ( my ($k, $v) = each %{$Interfaces{$if}{IP}{'Packet Size'}} ) {
      $Trace{IP}{'Packet Size'}{$k} += $v;

      foreach ( @transports ) {
	$Trace{Transport}{$_}{'Packet Size'}{$k}
	  += $Interfaces{$if}{Transport}{$_}{'Packet Size'}{$k};
      }
    }
  }

  # Sanity checks
  #
  my $total_packets;
  while ( ($_) = each %{$Trace{Transport}} ) {
    $total_packets += $Trace{Transport}{$_}{Total}{Packets};
  }

  croak "Total number of packets is not equal to the number of trace records"
    unless $Trace{records} == $total_packets;

  croak "The estimated number of records based on the file size does not equal the number of records observed across all interfaces"
    unless $total_records == $Trace{records};

  return (\%senders, \%segments) if defined wantarray;
}

sub progress( $ ) {
  print STDERR shift if $options{Verbosity};
}

=head2 records_in

 records_in FILENAME

Estimates the number to records in FILENAME based on its file size.
It returns an integer corresponding to the "expected" number of
records in the trace, or I<false> if the file size does not seem to
correspond to a legitimate TSH trace.

=cut

sub records_in( $ ) {
  my $no_records = (-s shift) / TSH_RECORD_LENGTH;

  $no_records == int $no_records and return $no_records;
}


=head2 verbose

 verbose

As you might expect, this function sets the verbosity level of the
module.  By default C<Net::Traces::TSH> remains "silent".  Call
verbose() to see trace processing progress indicators on standard
error.

As of version 0.13, verbose() is equivalent to

 configure(Verbosity => 1);

=cut

sub verbose () {

  $options{Verbosity} = 1;

}

# Utility function to export the information stored in %Trace and
# %Interfaces in CSV format
#
sub write_summary( *$ ; $ ) {
  my ( $FH, $href, $if ) = @_;

   confess "usage: write_summary(FILEHANDLE, HASH_REFERENCE)"
    unless ref($FH) eq 'GLOB' and ref($href) eq 'HASH';

  # Prepare to print general trace file information
  #
  print $FH <<GENERAL_INFO;
GENERAL TRACE INFORMATION
Filename,$Trace{filename},$Trace{date}
Duration,$Trace{ends}
Records,$Trace{records}
Interfaces,$Trace{interfaces}
GENERAL_INFO

  print $FH "Link Capacity,$Trace{'Link Capacity'}\n"
    if $Trace{'Link Capacity'};

  print $FH 'Duplicate timestamps,',
    $Trace{Transport}{TCP}{'Concurrent Segments'}, "\n"
  if $Trace{Transport}{TCP}{'Concurrent Segments'};

  if ( defined $if ) {
    print $FH <<INTERFACE_INFO;

INTERFACE INFORMATION
Interface Number,$if
Duration,$href->{ends}
Records,$href->{records}

INTERFACE TRAFFIC DENSITY
,Pkts/s,Bytes/Pkt,b/s
INTERFACE_INFO

    printf $FH
      "IP Total,%.0f,%.0f,%.0f\n",
      $href->{IP}{Total}{Packets} / $href->{ends},
      $href->{IP}{Total}{Bytes} / $href->{IP}{Total}{Packets},
      $href->{IP}{Total}{Bytes} * 8 / $href->{ends};

    if ( $href->{Transport}{TCP}{Total}{Packets}) {
      printf $FH "TCP Total,%.0f,%.0f,%.0f",
	$href->{Transport}{TCP}{Total}{Packets} / $href->{ends},
	( $href->{Transport}{TCP}{Total}{Bytes}
	  / $href->{Transport}{TCP}{Total}{Packets}
	),
	( ( $href->{Transport}{TCP}{Total}{Bytes} * 8 )
	  / $href->{ends}
	);
    }
    else {
      print $FH "TCP Total,0,0,0";
    }
  }

  my @transports = sort keys %{$href->{Transport}};

  foreach my $metric ('Packets', 'Bytes') {
    print $FH
      "\n\nIP STATISTICS (", uc($metric),
      ")\n,,Fragmentation,,Explicit Congestion Notification,,",
      "Differentiated Services,,,,IP Options\n,",
      join( ',', @data_points), "\nIP";

    # Some of the entries in the hashes below are naturally
    # uninitialized.  For example, a given trace may not have any
    # packets the MF bit set.  We take advantage of Perl's automatic
    # conversion of uninitialized values to 0 (in a scalar/number
    # context).  However, with warnings on, this may cause a
    # considerable number warnings re: uninitialized values possibly
    # leading a novice user to believe that something REALLY BAD
    # happened, which is not the case.  So we disable these particular
    # warnings for the rest of the block.  This "practice is followed
    # in the rest of the code below, as necessary.
    #
    no warnings qw(uninitialized);

    foreach ( @data_points ) {
      printf $FH ",%d", $href->{IP}{$_}{$metric};
    }

    foreach my $protocol ( @transports ) {
      print $FH "\n$protocol";

      foreach ( @data_points ) {
	printf $FH ",%d", $href->{Transport}{$protocol}{$_}{$metric};
      }
    }
  }

  # Print distribution of ACKs
  #
  if ( $href->{Transport}{TCP}{'Total ACKs'} ) {
    print $FH "\n\nTCP ACKNOWLEDGEMENTS\n";

    foreach ( 'Total ACKs', 'Cumulative ACKs', 'Pure ACKs', 'Options ACKs' ) {
      printf $FH "$_,%d\n", $href->{Transport}{TCP}{$_};
    }
  }

  # Print the TCP Advertised window distribution
  #
  if ( $href->{Transport}{TCP}{rwnd} ) {
    print $FH
      "\nRECEIVER ADVERTISED WINDOW\nSize (Bytes),Soft Count,Hard Count\n";

    no warnings qw(uninitialized);

    foreach ( sort numerically keys %{$href->{Transport}{TCP}{rwnd}} ) {
      printf $FH "%d,%d,%d\n", $_,

                               $href->{Transport}{TCP}{rwnd}{$_}
                               - $href->{Transport}{TCP}{awnd}{$_},

                               $href->{Transport}{TCP}{awnd}{$_};
    }
  }

  # Print the TCP Options-carrying SYN size distribution
  #
  if ( $href->{Transport}{TCP}{SYN} ) {
    print $FH
      "\nTCP OPTIONS NEGOTIATION\n",
      'TCP Header Length (Bytes),SYN,SYN/ACK';

    no warnings qw(uninitialized);

    foreach ( sort numerically keys %{$href->{Transport}{TCP}{SYN}} ) {
      print $FH "\n$_,",
	$href->{Transport}{TCP}{SYN}{$_}
	  - $href->{Transport}{TCP}{'SYN/ACK'}{$_}, ',',
	$href->{Transport}{TCP}{'SYN/ACK'}{$_};
    }

    print $FH "\nSYN/Payload,", $href->{Transport}{TCP}{'SYN/Payload'};
  }

  # Print the distribution of ACKs carrying TCP options
  #
  if ( $href->{Transport}{TCP}{'Options ACKs'}) {
    print $FH "\n\nTCP OPTIONS ACK USAGE\nTCP Header Length (Bytes),Count";

    no warnings qw(uninitialized);

    foreach ( sort numerically keys
	     %{$href->{Transport}{TCP}{'ACK Option Size'}} )
    {
      print $FH "\n$_,", $href->{Transport}{TCP}{'ACK Option Size'}{$_};
    }
  }

  # Print the packet size distribution
  #
  print $FH join ',', "\n\nPACKET SIZE DISTRIBUTION\nBytes,IP", @transports;

  foreach ( sort numerically keys %{$href->{IP}{'Packet Size'}} ) {
      print $FH "\n$_,$href->{IP}{'Packet Size'}{$_}";

      foreach my $prt ( @transports ) {
	print_value(\*$FH, $href->{Transport}{$prt}{'Packet Size'}{$_});
      }
    }

  print $FH "\n";
}

=head2 write_interface_summaries

 write_interface_summaries
 write_interface_summaries FILE_PREFIX

Writes a CSV summary similar to what write_trace_summary() generates
for each interface in the trace (see L<%Interfaces|"Data
Structures">).  Each summary file has a C<.if-X.csv> suffix, where X
is the number of the interface. If FILE_PREFIX is provided,
write_interface_summaries() will append to it this standard suffix
(indicative of the interface).

=cut

sub write_interface_summaries( ; $ ) {

  foreach my $if ( get_interfaces_list ) {
    # Open the interface-specific summary
    #
    my $if_summary = shift || $Trace{filename};
    $if_summary .= ".if-$if.csv";

    open(LOG, '>', $if_summary)
      or croak "Cannot open interface-specific summary. $!";

    progress 'Generating interface-specific summary... ';

    write_summary( \*LOG, $Interfaces{$if}, $if );

    close LOG;

    progress "see $if_summary\n";
  }

}

=head2 write_trace_summary

 write_trace_summary
 write_trace_summary FILENAME

Writes the contents of L<%Trace|"Data Structures"> to FILENAME
in comma separated values (CSV) format, a platform independent text
format, excellent for storing tabular data.  CSV is both
human-readable and suitable for further analysis using Perl or direct
import to a spreadsheet application.  Although not required, it is
recommended that FILENAME should have a I<.csv> suffix.

If FILENAME is not specified, write_trace_summary() will create one
for you by appending the suffix I<.csv> to the L<filename|"General
Trace Information"> of the trace being processed.

If you want FILENAME to contain meaningful data you should call
write_trace_summary() I<after> calling process_trace().

=cut

sub write_trace_summary( ; $ ) {

  croak
    'Important trace information was not found. Call process_trace() before ',
    "calling write_trace_summary().\nTrace summary generation aborted"
  unless ( $Trace{IP}{Total}{Bytes}
	   and $Trace{IP}{Total}{Packets}
	   and $Trace{ends}
	 );
	
  # Open the log file (expected to be .csv)
  #
  $Trace{summary} = shift || "$Trace{filename}.csv";

  open(LOG, '>', $Trace{summary})
    or croak "Cannot write trace summary to $Trace{summary}. $!";

  progress 'Generating trace summary... ';

  write_summary( \*LOG, \%Trace );

  close LOG;

  progress "see $Trace{summary}\n";
}

sub print_value(*$) {
  my ($fh, $value) = @_;
  print {$fh} $value ? ",$value" : ',0';
}

# Mandatory: the module must return "true"
#

1;

=head1 DEPENDENCIES

Nothing non-standard: L<strict>, L<warnings> and L<Carp>.

=head2 EXPORTS

None by default.

=head3 Exportable

configure() date_of() get_IP_address() get_interfaces_href()
get_interfaces_list() get_trace_summary_href() numerically()
process_trace() records_in() verbose() write_trace_summary()

In addition, the following export tags are defined:

=over

=item :traffic_analysis

verbose() process_trace() write_interface_summaries()
write_trace_summary()

=item :trace_information

date_of() records_in()

=back

Finally, all exportable functions can be imported with

 use Net::Traces::TSH qw(:all);

=head1 VERSION

This is C<Net::Traces::TSH> version 0.16.

=head1 SEE ALSO

The NLANR MOAT Passive Measurement and Analysis (PMA) web site at
http://pma.nlanr.net/PMA provides more details on the process of
collecting packet traces.  The site features a set of Perl programs
you can download, including several converters from other packet trace
formats to TSH.

TSH trace files can be downloaded from the NLANR/PMA trace repository
at http://pma.nlanr.net/Traces .  The site contains a variety of
traces gathered from several monitoring points at university campuses
and (Giga)PoPs connected to a variety of large and small networks.

C<Net::Traces::TSH> version 0.11 was presented in YAPC::NA 2004.  The
presentation slides are available at
http://www.cs.stonybrook.edu/~kostas/art/yapc .

=head2 DiffServ

If you are not familiar with Differentiated Services (DiffServ), good
starting points are the following RFCs:

K. Nichols I<et al.>, I<Definition of the Differentiated Services
Field (DS Field) in the IPv4 and IPv6 Headers>, RFC 2474. Available at
http://www.ietf.org/rfc/rfc2474.txt

S. Blake I<et al.>, I<An Architecture for Differentiated Services>,
RFC 2475. Available at http://www.ietf.org/rfc/rfc2475.txt

See also RFC 2597 and RFC 2598.

=head2 ECN

If you are not familiar Explicit Congestion Notification (ECN) make
sure to read

K. K. Ramakrishnan I<et al.>, I<The Addition of Explicit Congestion
Notification (ECN) to IP>, RFC 3168. Available at
http://www.ietf.org/rfc/rfc3168.txt

=head2 The ns2 network simulator

C<Net::Traces::TSH> can convert TSH traces to binary files suitable to
drive simulations in ns2. More information about ns2 is available at
http://www.isi.edu/nsnam/ns .

=head1 AUTHOR

Kostas Pentikousis, kostas AT cpan DOT org.

=head1 ACKNOWLEDGMENTS

Professor Hussein Badr provided invaluable guidance while crafting the
main algorithms of this module.

Many thanks to Wall, Christiansen and Orwant for writing I<Programming
Perl 3/e>.  It has been indispensable while developing this module.

=head1 COPYRIGHT AND LICENSE

Copyright 2003, 2004 by Kostas Pentikousis.  All Rights Reserved.

This library is free software with ABSOLUTELY NO WARRANTY.  You can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

__DATA__
0 HOPOPT
1 ICMP
2 IGMP
3 GGP
4 IP
5 ST
6 TCP
7 CBT
8 EGP
9 IGP
10 BBN-RCC-MON
11 NVP-II
12 PUP
13 ARGUS
14 EMCON
15 XNET
16 CHAOS
17 UDP
18 MUX
19 DCN-MEAS
20 HMP
21 PRM
22 XNS-IDP
23 TRUNK-1
24 TRUNK-2
25 LEAF-1
26 LEAF-2
27 RDP
28 IRTP
29 ISO-TP4
30 NETBLT
31 MFE-NSP
32 MERIT-INP
33 SEP
34 3PC
35 IDPR
36 XTP
37 DDP
38 IDPR-CMTP
39 TP++
40 IL
41 IPV6
42 SDRP
43 IPV6-ROUTE
44 IPV6-FRAG
45 IDRP
46 RSVP
47 GRE
48 MHRP
49 BNA
50 ESP
51 AH
52 I-NLSP
53 SWIPE
54 NARP
55 MOBILE
56 TLSP
57 SKIP
58 IPV6-ICMP
59 IPV6-NONXT
60 IPV6-OPTS
61 HOST INTERNAL PROTOCOL
62 CFTP
63 LOCAL NETWORK
64 SAT-EXPAK
65 KRYPTOLAN
66 RVD
67 IPPC
68 DISTRIBUTED FILE SYSTEM
69 SAT-MON
70 VISA
71 IPCV
72 CPNX
73 CPHB
74 WSN
75 PVP
76 BR-SAT-MON
77 SUN-ND
78 WB-MON
79 WB-EXPAK
80 ISO-IP
81 VMTP
82 SECURE-VMTP
83 VINES
84 TTP
85 NSFNET-IGP
86 DGP
87 TCF
88 EIGRP
89 OSPFIGP
90 SPRITE-RPC
91 LARP
92 MTP
93 AX.25
94 IPIP
95 MICP
96 SCC-SP
97 ETHERIP
98 ENCAP
99 PRIVATE ENCRYPTION SCHEME
100 GMTP
101 IFMP
102 PNNI
103 PIM
104 ARIS
105 SCPS
106 QNX
107 A/N
108 IPCOMP
109 SNP
110 COMPAQ-PEER
111 IPX-IN-IP
112 VRRP
113 PGM
114 0-HOP PROTOCOL
115 L2TP
116 DDX
117 IATP
118 STP
119 SRP
120 UTI
121 SMP
122 SM
123 PTP
124 ISIS
125 FIRE
126 CRTP
127 CRUDP
128 SSCOPMCE
129 IPLT
130 SPS
131 PIPE
132 SCTP
133 FC
134 RSVP-E2E-IGNORE
135 MOBILITY
136 UDPLITE
253 EXPERIMENTATION1
254 EXPERIMENTATION2
255 RESERVED
