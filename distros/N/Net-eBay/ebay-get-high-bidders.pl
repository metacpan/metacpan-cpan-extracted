#!/usr/bin/perl

#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;
use DateTime::Precise;

die "Usage: $0 item-ids..." unless @ARGV;

my ($detail, $debug);

my $done;

do {
  $done = 0;
  if($ARGV[0] eq '--detail' ) {
    shift;
    $done = 1;
    $detail = 1;
  }
  if($ARGV[0] eq '--debug' ) {
    shift;
    $done = 1;
    $debug = 1;
  }
} while( $done );


my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => $debug } );

foreach my $item (@ARGV) {
  my $result = $eBay->submitRequest( "GetHighBidders",
                                     {
                                      ItemID => $item
                                     }
                                   );
  if( ref $result ) {
    print "Result: " . Dumper( $result ) . "\n";
    
    my $offers = $result->{BidArray}->{Offer};

    if( $offers ) {
      #print "Offers = $offers.\n";
      $offers = [$offers] unless (ref $offers) =~ /^ARRAY/;
      foreach my $offer ( @$offers) {
        my $address = $offer->{User}->{BuyerInfo}->{ShippingAddress};
        my $email = $offer->{User}->{Email};
        print "$offer->{User}->{UserID} ($offer->{User}->{FeedbackScore}) bid $offer->{MaxBid}->{content} $offer->{MaxBid}->{currencyID}, lives in $address->{PostalCode}, $address->{Country}, email $email\n";
      }
    } else {
      print "No bids on item $item\n";
    }
    
  } else {
    print "Unparsed result: \n$result\n\n";
  }
}
