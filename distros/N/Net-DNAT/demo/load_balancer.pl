#!/usr/bin/perl -w -T

# Complex example configuration to forward incoming
# requests on port 80 to various remote pools of
# machines and/or local services based on the URL
# or other request header information.

use strict;
use Net::DNAT;

# Pools definition configuration
my $pools = {
  # If no port is supplied, the standard
  # HTTP port (80) is used
  pool1 => "10.0.1.100",
  # If an array ref is used, connections
  # are cycled through each destination.
  pool2 => [ "10.0.2.2", "10.0.2.3", "10.0.2.4" ],
  pool3 => [ "10.0.3.2:8000", "10.0.3.3:8000" ],
  pool4 => "127.0.0.1:2001",
  # If words are used instead of the
  # dotted IP notation, they are resolved
  # using gethostbyname.
  pool5 => "localhost:2002",
  # If there exists more than one A record,
  # all are stored and are cycled.
  pool6 => "www.yahoo.com.:3001",
  pool7 => [ "www.yahoo.com.", "geocities.com." ],
};

my $default_pool = "pool1";

# Host needs to match exactly.
my $host_dest = {
  "Domain.com"     => "pool2",
  "www.domain.com" => "pool2",
  "dev.domain.com" => "pool3",
};

# Regexp and code refs all operate
# on the entire header string, which
# is stored in the $_ variable.
my $headers_directors =
  [
   # An array ref is used to preserve
   # the order in which the header
   # checks are to be made.  Also,
   # refs do not go very well as
   # keys in a hash.
   qr%^Host:.*\.domain4\.com%im => "pool4",
   # The Remote-Addr and Remote-Port
   # headers are inserted on the fly
   # and can be used in the URL parsing.
   qr%^Remote\-Addr: 192\.168\.%im => "pool5",
   # Code refs must return a true value
   # when executed to direct the request.
   sub {
     m%^Referer:\s*http://domain.com/%im
       && m%^Host:\s*banner\.%im
         && m%GET /\S+\.gif%;
   } => "pool6",
  ];

run Net::DNAT
  port => 80,
  pools => $pools,
  default_pool => $default_pool,
  host_switch_table => $host_dest,
  switch_filters => $headers_directors,
  user => "nobody",
  group => "nobody",
  ;
