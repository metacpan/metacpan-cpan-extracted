#!/usr/bin/perl -w

#  $Id: client.cgi,v 1.4 2000/11/26 21:27:27 aigan Exp $  -*-perl-*-

#=====================================================================
#
# DESCRIPTION
#   The Wraf CGI client
#
# AUTHOR
#   Jonas Liljegren   <jonas@paranormal.se>
#
# COPYRIGHT
#   Copyright (C) 2000 Jonas Liljegren.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
#=====================================================================

use strict;
use CGI;
use IO::Socket;
use FreezeThaw qw( freeze );

#warn "Client started\n";

my $q = new CGI;
my $sock = new IO::Socket::INET (
      PeerAddr => 'localhost',
      PeerPort => '7789',
      Proto => 'tcp',
     );
die "Could not create socket: $!\n" unless $sock;

#warn "Established connection to server\n";

my $value = freeze [ $q, [%ENV], ];
my $length = length $value;
print $sock "$length\x00$value";

#warn "Sent data to server\n";

while( $_ = <$sock> )
{
    print( $_ );
}

#warn "Response recieved\n\n\n";
