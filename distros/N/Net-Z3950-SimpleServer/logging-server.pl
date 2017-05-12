#!/usr/bin/perl -w

# This is just about the simplest possible SimpleServer-based Z39.50
# server.  It exists only to log the data-structures that are handed
# to the back-end functions, and does only enough work otherwise to
# hand the client a coherent (if useless) response to its requests.

use strict;
use warnings;
use Net::Z3950::SimpleServer;
use Data::Dumper;

my $handler = new Net::Z3950::SimpleServer(INIT => \&init_handler,
					   CLOSE => \&close_handler,
					   SEARCH => \&search_handler,
					   FETCH => \&fetch_handler);
$handler->launch_server("logging-server.pl", @ARGV);

sub init_handler {
    my $href = shift;
    print "INIT: ", Dumper($href);
}

sub search_handler {
    my $href = shift;
    print "Search: ", Dumper($href);
    $href->{HITS} = 1;
}

sub fetch_handler {
    my $href = shift;
    print "Fetch: ", Dumper($href);
    my $record = "<dummy>foo</dummy>";
    $href->{RECORD} = $record;
    $href->{LEN} = length($record);
    $href->{NUMBER} = 1;
    $href->{BASENAME} = "Test";
}

sub close_handler {
    my $href = shift;
    print "Close: ", Dumper($href);
}
