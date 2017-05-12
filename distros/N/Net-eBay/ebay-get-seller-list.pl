#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;

my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => 0 } );

my $seller = shift @ARGV || die "Usage: $0 seller-id";

my $result = $eBay->submitRequest( "GetSellerList",
                                   {
                                    UserID => $seller
                                   }
                                 );
if( ref $result ) {
  print "Result: " . Dumper( $result ) . "\n";
} else {
  print "Unparsed result: \n$result\n\n";
}

