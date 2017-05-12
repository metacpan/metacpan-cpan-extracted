#!/usr/bin/perl

use Net::LibNIDS;
use strict;
use warnings;
use Socket qw(inet_ntoa);

my $total_connections = 0;
my $current_connections = 0;

# This is an example of how to use Net::LibNIDS and not of decent perl coding!
# Please report any bugs or suggestions on the cpan bug tracker.

# Either set a device name (requires priviledges) or choose a filename
# This script prints data to the terminal, it might be a bad idea to capture straight
# from a network device.  Either filter below or load the HTTP sample capture from the t/ 
# directory.
#Net::LibNIDS::param::set_device('eth0');
Net::LibNIDS::param::set_filename('t/http-test.dump');

# Set a pcap filter, see the manpage for tcpdump for more information.  The manpage for
# libnids explains why the 'or (..)' is required.
Net::LibNIDS::param::set_pcap_filter('port 80 or (ip[6:2] & 0x1fff != 0)');

if (!Net::LibNIDS::init()) {
  warn "Uh oh, libnids failed to initialise!\n";
  warn "Check you have successfully built and installed the module first.\n";
  exit;
}

# Set the callback function and run libnids
Net::LibNIDS::tcp_callback(\&collector );
Net::LibNIDS::run();

print "Finished!  There were $total_connections connections in total, $current_connections of these were still established at the end.\n";


sub collector {
  my $args = shift;
  #print "Collector subroutine was called with state: " . $args->state_string . "\n";

  # A new connection was established
  if($args->state == Net::LibNIDS::NIDS_JUST_EST()) {
    $total_connections++;
    $current_connections++;

    # Here you can specify whether or not to collect the data from this connection.  You could
    # also filter using set_pcap_filter().
    #if($args->server_ip eq '127.0.0.1' || $args->server_port eq '1234') {
    #}

    # By default, this script captures all traffic.
    $args->server->collect_on();
    $args->client->collect_on();

    print "New connection: " . $args->client_ip . ":" . $args->client_port . " -> " . $args->server_ip . ":" . $args->server_port;
    print " (currently handling $current_connections connections)\n";
    return;

  } elsif ($args->state == Net::LibNIDS::NIDS_CLOSE()) {
    print "Connection from " . $args->client_ip . " was closed\n";
    $current_connections--;
    return;

  } elsif ($args->state == Net::LibNIDS::NIDS_RESET()) {
    print "Connection from " . $args->client_ip . " was reset\n";
    $current_connections--;
    return;

  } elsif ($args->state == Net::LibNIDS::NIDS_TIMED_OUT()) {
    print "Connection from " . $args->client_ip . " timed out\n";
    $current_connections--;
    return;

  } elsif ($args->state == Net::LibNIDS::NIDS_DATA()) {
    # Data toward the server
    if ($args->server->count_new) {
      print $args->lastpacket_sec . " " . $args->client_ip . ":" . $args->client_port . " -> " . $args->server_ip . ":" . $args->server_port . " (" . $args->server->count_new . " new, " . $args->server->count . " total, offset " . $args->server->offset . ")\n";
      print "***\n";
      print substr($args->server->data, 0, $args->server->count_new);
      print "***\n";
      return;
    } 

    # Data toward the client
    if ($args->client->count_new) {
      print $args->lastpacket_sec . " " . $args->client_ip . ":" . $args->client_port . " <- " . $args->server_ip . ":" . $args->server_port . " (" . $args->client->count_new . " new, " . $args->client->count . " total, offset " . $args->client->offset . ")\n";
      print "***\n";
      print substr($args->client->data, 0, $args->client->count_new);
      print "***\n";
      return;
    }
  }
}
