#!/usr/bin/perl -w
#########################################
#
# Nikto::Parser v0.1
#
#########################################

use strict;
use Data::Dumper;
use Nikto::Parser;

use Getopt::Long;
use vars qw( $PROG );
( $PROG = $0 ) =~ s/^.*[\/\\]//;    # Truncate calling path from the prog name

my $npx = new Nikto::Parser;

my $file;

sub usage {
    print "usage: $0 [file.xml]\n";
    exit;
}

if ( $ARGV[0] ) {
    $file = $ARGV[0];
}
else {
    usage;
}
my $parser = $npx->parse_file("$file");

foreach my $h ( $parser->get_all_hosts() ) {
    print "ip is: " . $h->ip . "\n";
    foreach my $p ( $h->get_all_ports  ) {
        print "port: " . $p->port . "\n";
        print "banner: " . $p->banner . "\n";
        foreach my $i ( $p->get_all_items ) {
            print "Description:\n" . $i->description . "\n";
        }
    }
}
