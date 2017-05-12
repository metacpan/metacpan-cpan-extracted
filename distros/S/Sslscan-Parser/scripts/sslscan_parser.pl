#!/usr/bin/perl -w
#####################################################
#
# Sslscan::Parser v.01 example script for google.xml
#
#####################################################
use strict;
use Sslscan::Parser;
use Getopt::Long;
use vars qw( $PROG );
( $PROG = $0 ) =~ s/^.*[\/\\]//;    # Truncate calling path from the prog name

my $sslpx = new Sslscan::Parser;
my $file;

sub usage {
    print "usage: $0 [google.xml]\n";
    exit;
}
if ( $ARGV[0] ) {
    $file = $ARGV[0];
}
else {
    usage;
}

my $parser = $sslpx->parse_file("$file");
my $host = $parser->get_host('google.com');
print "ip is: " . $host->ip . "\n";
foreach my $p ( $host->get_all_ports  ) {
    print "port: " . $p->port . "\n";
    print "accpeted ciphers are \n";
    foreach my $i ( grep( $_->status =~ /accepted/i, $p->get_all_ciphers() ) ) {
        print "sslversion is " . $i->sslversion . "\n"; 
        print "ciphers is " . $i->cipher . "\n";
        print "bits is " . $i->bits . "\n";
    }
}
