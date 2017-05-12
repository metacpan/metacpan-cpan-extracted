#!/usr/bin/perl

$| = 1;

use strict;
use utf8;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Net::Whois::Parser;
%Net::Whois::Parser::FIELD_NAME_CONV = ();
$Net::Whois::Raw::TIMEOUT = 10;

my %stat = ();
my $limit = 0;
for my $zone ( keys %Net::Whois::Raw::Data::servers ) {
    $zone = lc $zone;
    my $domain = "www.$zone";
    print "Get $domain ... "; 
    my $info = parse_whois(domain => $domain);

    if ( $info ) {
        $stat{$_}++ for ( keys %$info );
        print "done\n"
    }
    else {
        print "error\n";
    }
    $limit++;
    last if $limit >=3;
}

delete $stat{emails};

print
    "\nKey stat:\n\n",
    join( "\n", map { "$_: " . $stat{$_} } sort keys %stat), 
    "\n";
