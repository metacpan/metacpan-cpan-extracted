#!/usr/bin/perl

use Getopt::Long;
use Data::Dumper;
use Net::eBay;

my $reason = "NotAvailable";

GetOptions(
           "reason=s" => \$reason,
           );

my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => $debug } );

foreach my $item (@ARGV) {
  my $result = $eBay->submitRequest( "EndItem",
                                     {
                                      ItemID => $item,
                                      EndingReason => $reason,
                                     }
                                   );
  if( ref $result ) {
    print Dumper( $result );
  } else {
    print "ERROR: $result\n\n";
  }
}
