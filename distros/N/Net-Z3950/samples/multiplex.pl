#!/usr/bin/perl -w

# $Id: multiplex.pl,v 1.6 2005/01/05 16:24:53 mike Exp $

use Net::Z3950;
use strict;

# Feel free to modify @servers and @searches
my @servers = (
	       ['Z3950cat.bl.uk',     9909, "BLAC"],
	       ['bagel.indexdata.dk', 210,  "gils"],
	       ['z3950.loc.gov',      7090, "Voyager"],
	       );

my @searches = ('computer', 'data', 'survey', 'mineral');
my %conn2si;			# Indicates, for each connection, how
				# far through @searches it has got.

my $mgr = new Net::Z3950::Manager(async => 1,
				  preferredRecordSyntax => "usmarc");
my @conn;
foreach my $spec (@servers) {
    my($host, $port, $dbname) = @$spec;
    my $conn = new Net::Z3950::Connection($mgr, $host, $port, \&done_init,
					  databaseName => $dbname)
	or die "can't connect to $host:$port: $!";
    #print "> got $conn, added it to $mgr\n";
}


#$Event::DebugLevel = 5;
$mgr->wait();
print "Finished.\n";
use Errno qw(ECONNREFUSED);
if ($! == ECONNREFUSED) {
    ###	At present, a single connection failing to connect makes the
    #   whole concurrent session end.  Need to consider the interface.
    print "(Possible premature exit due to $!)\n";
}


sub done_init {
    my($conn, $apdu) = @_;

    print $conn->name(), " - done init\n";
    $conn2si{$conn} = 0;
    $conn->startSearch($searches[0], \&done_search);
}

sub done_search {
    my($conn, $apdu) = @_;

    my $si = $conn2si{$conn};
    my $rs = $conn->resultSet();
    if (!defined $rs) {
	print $conn->name(), " - search failed: ", $conn->errmsg(), "\n";
    } else {
	print $conn->name(), " - search ", $si+1,
	      " found ", $rs->size(), " records\n";
    }
    my $search = $searches[++$conn2si{$conn}];
    if (defined $search) {
	$conn->startSearch($search, \&done_search);
    } else {
	print $conn->name(), " finished!\n";
	$conn->close();
    }
}
