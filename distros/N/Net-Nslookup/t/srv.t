#!/usr/bin/perl -w

# vim: set ft=perl:

use strict;
use Test::More tests => 2;
my (@res);

use_ok("Net::Nslookup");

# Get A record
@res = nslookup(host => "_jabber._tcp.gmail.com", type => "SRV");

ok(grep("xmpp-server.l.google.com", @res), "Jabber SRV record for gmail.com contains xmpp-server.l.google.com");
