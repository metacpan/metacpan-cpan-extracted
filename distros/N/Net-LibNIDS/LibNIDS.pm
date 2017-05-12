package Net::LibNIDS;

use 5.008;
use strict;
use warnings;
use Carp;

our @ISA = qw();

our $VERSION = '0.14';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Lib::nids::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

sub init {
    nids_init();
}

*run = *nids_run;

require XSLoader;
XSLoader::load('Net::LibNIDS', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Net::LibNIDS - Perl extension for reassembly of TCP/IP streams using the libnids package

=head1 SYNOPSIS

  use Net::LibNIDS;
  Net::LibNIDS::param::set_device('en1');  #set which device to use, see pcap documentation
  Net::LibNIDS::init();                    # processes all parameters
  Net::LibNIDS::tcp_callback(\&collector ); # a callback to be called for each packet
  Net::LibNIDS::run();                      # start the collection
  sub collector {
    my $connection = shift;
    if($connection->state == Net::LibNIDS::NIDS_JUST_EST()) {
       $connection->server->collect_on;  #start tracing data from server     
       $connection->client->collect_on;  #start tracing data from server     
    }
    if($connect->state == Net::LibNIDS::NIDS_DATA()) {
       if($connection->client->count_new) {
	 print ">" . $connection->client->data;
       } else {
	 print "<" . $connection->server->data;
       }
    }
  }

=head1 ABSTRACT

  This module embeds the libnids C library written by Rafal Wojtczuk E<lt>nergal@avet.com.plE<gt>.
  libnids is designed to do all lowlevel network code required by a network intrusion detection 
  system (whichis what NIDS stands for). This module uses libnids to allow you to read 
  the reassembled tcp stream without any duplicates or incorrect order. That is, like a normal 
  host would have seen the stream.

=head1 DESCRIPTION

The workflow of using libnids is to set all parameters, then call init, set up a callback then run.

=head1 Net::LibNIDS::init( )

Must be called once before run() is called, will return 1 if successful, will croak with a message if it fails.

=head1 Net::LibNIDS::tcp_callback( collector_callback )

This registers the tcp_callback function that will be invoked with each packet. The callback function is called with an object of Net::LibNIDS::tcp_stream

=head1 Net::LibNIDS::run( )

This starts the NIDS collector, it will not finish until you call exit() or the packet file you are processing is finished

=head1 Net::LibNIDS::checksum_off( )

Disables libnids internal checksumming for all packets by setting NIDS_DONT_CHKSUM.

=head1 Net::LibNIDS::nids_discard($tcp_stream, $num_bytes)

Exports the nids_discard function, which may be called from within your TCP callback.  See the libnids documentation for further information on how to use this function.

=head1 Net::LibNIDS::tcp_stream

This object is called as the first argument to tcp_callback function. It has the following methods

=head2 $tcp_stream->state( )

Returns the state of this connection. It can be one of the following:

=over 4

=item NIDS_JUST_EST

Set when a connection is just established, if you don't register your interest in it, you will not see this connection again.

=item NIDS_DATA

Set when there is more data on the connection

=item NIDS_CLOSE

Set when the connection has been closed normally

=item NIDS_RESET

Set when the connection has been closed by a reset

=item NIDS_TIMEOUT

Set when the connection has been closed by a timeout

=item NIDS_EXITING

Set when NIDS is exiting, this is the last time you will get this callback, so if you want to save any data you have to do it now.

=back

=head2 $tcp_stream->state_string

Returns the state as a string instead of an integer, easier for debugging.

=head2 $tcp_stream->server_ip  $tcp_stream->client_ip

Returns the IP address of the server and client. Client is the initiator of the connection. Returned as a string.

=head2 $tcp_stream->server_port  $tcp_stream->client_port

Returns the port of the server and client. Client is the initiator of the connection.

=head2 $tcp_stream->lastpacket_sec

Returns the seconds from epoch that this packet was recorded. Only available with libnids version >= 1.19.

=head2 $tcp_stream->lastpacket_usec

Returns the microsecond fraction that this packet was recorded. Used together with $tcp_stream->lastpacket to get the most correct timestamp possible. Only available with libnids version >= 1.19.

=head2 $tcp_stream->server $tcp_stream->client

Returns a Net::LibNIDS::tcp_stream::half object, corresponding to the client half and the server half.

=head1 Net::LibNIDS::tcp_stream::half

=head2 $tcp_stream->server->collect( ) $tcp_stream->client->collect( )

Returns a boolean, 1 if it is collecting, 0 if it is not

=head2 $tcp_stream->server->collect_on( ) $tcp_stream->client->collect_on( )

Turns on collection for selected half_stream.

=head2 $tcp_stream->server->collect_off( ) $tcp_stream->client->collect_off( )

Turns off collection for selected half_stream.

=head2 $tcp_stream->server->collect_urg( ) $tcp_stream->client->collect_urg( )

Returns a boolean, 1 if it is collecting urgent data, 0 if it is not

=head2 $tcp_stream->server->collect_urg_on( ) $tcp_stream->client->collect_urg_on( )

Turns on collection for urgent data on selected half_stream.

=head2 $tcp_stream->server->collect_urg_off( ) $tcp_stream->client->collect_urg_off( )

Turns off collection for urgent data on selected half_stream.

=head2 $tcp_stream->server->count( ) $tcp_stream->client->count( )

Length of all data recieved on the respective half_stream since start of connection.

=head2 $tcp_stream->server->count_new( ) $tcp_stream->client->count_new( )

Amount of data that has been added since the last time the callback has been invoked. As far as I can tell from libnids documentation, count_new can only be set in client or server half_stream for a given callback. This is the best way to check which side is active.

=head2 $tcp_stream->server->count_urg_new( ) $tcp_stream->client->count_urg_new( )

Same as above, but for URGent data.

=head2 $tcp_stream->server->offset( ) $tcp_stream->client->offset( )

See libnids documentation, this maps directly down to its' underlying data structures.

=head2 $tcp_stream->server->data( ) $tcp_stream->client->data( )

The new data that has arrived since the last the callback was called. Should match the count_new field in length.

=head1 Net::LibNIDS::param

This maps down the libnids nids.params configuration structure, there is a get and a set function for each parameter. Some of them are not certain they work yet.

=head2 device (Net::LibNIDS::param::set_device(dev) Net::LibNIDS::param::get_device)

Sets the device libnids uses

=head2 filename (Net::LibNIDS::param::set_filename(filename) Net::LibNIDS::param::get_filename)

Sets the filename to read packets from (tcpdump file), if this is set, then libnids will process that filename.

=head2 pcap_filter (Net::LibNIDS::param::set_pcap_filter(pcap_filter) Net::LibNIDS::param::get_pcap_filter)

The pcap filter to apply on the packets. Note however that if you have fragmented packets you cannot use the pcap filter on for example ports, since fragmented IP packets might not contain enough tcp information to determine port.

See the note in the libnids manpage for a workaround, or check the code in example.pl.

=head2 n_tcp_streams (Net::LibNIDS::param::set_n_tcp_streams(numbers) Net::LibNIDS::param::get_n_tcp_streams)

From libnids documentation:
"size of the hash table used for storing structures
tcp_stream; libnis will follow no more than
3/4 * n_tcp_streams connections simultaneously
default value: 1040. If set to 0, libnids will
not assemble TCP streams."

=head2 n_hosts (Net::LibNIDS::param::set_n_hosts(numbers) Net::LibNIDS::param::get_n_hosts)

From libnids documentation:
"size of the hash table used for storing info on IP defragmentation; default value: 256"

=head2 sk_buff_size (Net::LibNIDS::param::set_sk_buff_size(numbers) Net::LibNIDS::param::get_sk_buff_size)

From libnids documentation:
" size of struct sk_buff, a structure defined by
Linux kernel, used by kernel for packets queuing. If
this parameter has different value from
sizeof(struct sk_buff), libnids can be bypassed
by attacking resource managing of libnis (see TEST
file). If you are paranoid, check sizeof(sk_buff)
on the hosts on your network, and correct this
parameter. Default value: 168"

=head2 dev_addon (Net::LibNIDS::param::set_dev_addon(numbers) Net::LibNIDS::param::get_dev_addon)

From libnids documentation:
"how many bytes in structure sk_buff is reserved for
information on net interface; if dev_addon==-1, it
will be corrected during nids_init() according to
type of the interface libnids will listen on.
Default value: -1."

=head2 syslog

Not supported by this extension

=head2 syslog_level (Net::LibNIDS::param::set_syslog_level(numbers) Net::LibNIDS::param::get_syslog_level)

From libnids documentation:
"if nids_params.syslog==nids_syslog, then this field
determines loglevel used by reporting events by
system daemon syslogd; default value: LOG_ALERT"

=head2 scan_num_hosts (Net::LibNIDS::param::set_scan_num_hosts(numbers) Net::LibNIDS::param::get_scan_num_hosts)

From libnids documentation:
" size of hash table used for storing info on port
scanning; the number of simultaneuos port
scan attempts libnids will detect. if set to
0, port scanning detection will be turned
off. Default value: 256."


=head2 scan_num_ports (Net::LibNIDS::param::set_scan_num_ports(numbers) Net::LibNIDS::param::get_scan_num_ports)

From libnids documentation:
" how many TCP ports has to be scanned from the same
source. Default value: 10."

=head2 scan_delay (Net::LibNIDS::param::set_scan_delay(numbers) Net::LibNIDS::param::get_scan_delay)
From libnids documentation:
" with no more than scan_delay milisecond pause
between two ports, in order to make libnids report
portscan attempt. Default value: 3000"

=head2 promisc (Net::LibNIDS::param::set_promisc(numbers) Net::LibNIDS::param::get_promisc)

From libnids documentation:
"if non-zero, the device(s) libnids reads packets
from will be put in promiscuous mode. Default: 1"

=head2 one_loop_less (Net::LibNIDS::param::set_one_loop_less(numbers) Net::LibNIDS::param::get_one_loop_less)

Set libnids API.txt documentation on how to use.

=head2 ip_filter

Not currently supported by this extension

=head2 no_mem

Not currently supported by this extension

=head2 Note

Previous versions of Net::LibNIDS included a patch against libnids in order to obtain packet timings.  This is no longer necessary as long as libnids-1.19 or greater is used.

=head1 SEE ALSO

libnids man page
libpcap man page
API.txt documentation from libnids distributions
example.pl and performance.pl 

=head1 AUTHOR

Arthur Bergman, E<lt>sky@nanisky.comE<gt>
Modified for libnids >= 1.19 by David Cannings, E<lt>david@edeca.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Arthur Bergman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
