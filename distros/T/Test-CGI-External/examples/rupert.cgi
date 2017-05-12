#!/home/ben/software/install/bin/perl
use warnings;
use strict;
my $query = $ENV{QUERY_STRING};
if ($query =~ /rupert/i) {
    print "Content-Type: text/plain\n\nEveryone knows his name.\n";
}
else {
    print "Status: 500\nContent-Type: text/plain\n\nNo rupert\n";
}
