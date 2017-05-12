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
        for my $key ( keys %$info ) {
            $stat{$key} = {} unless exists $stat{$key};
            $stat{$key}->{$zone}++;
        }
        print "done\n"
    }
    else {
        print "error\n";
    }
#    $limit++;
#    last if $limit >=3;
}

delete $stat{emails};

print
    "\nKey stat:\n\n",
    join("\n\n", map {get_zones($_)} sort keys %stat), 
    "\n";

sub get_zones {
    my $zones = $stat{$_[0]};
    return 
        "$_:\n" . 
        join("\n", map { "\t$_:\t" . $zones->{$_} } sort keys %$zones);
        "\n";
}

