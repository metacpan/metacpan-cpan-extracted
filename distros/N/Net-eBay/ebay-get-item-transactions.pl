#!/usr/bin/perl

#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;
use DateTime::Precise;

die "Usage: $0 item-ids..." unless @ARGV;

my ($detail, $debug);
my $days = 10;

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
  if($ARGV[0] eq '--days' ) {
    shift;
    $days = shift;
    $done = 1;
  }
} while( $done );


my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => $debug } );

my $today = new DateTime::Precise;
my $ago   = new DateTime::Precise;
$ago->inc_day( -$days );

sub eBayDate {
  my ($dtp) = @_;
  # '2007-02-20T19:06:54.992Z',
  my $e = $dtp->dprintf( "%^Y-%M-%DT%h:%m:%s.00Z" );
  return $e;
}

foreach my $item (@ARGV) {
  my $result = $eBay->submitRequest( "GetItemTransactions",
                                     {
                                      ItemID => $item,
                                      ModTimeFrom => eBayDate( $ago ),
                                      ModTimeTo => eBayDate( $today ),
                                     }
                                   );
  if( ref $result ) {
    #print "Result: " . Dumper( $result ) . "\n";
    
    my $offers = $result->{TransactionArray}->{Transaction};

    if( $offers ) {
      #print "Offers = $offers.\n";
      $offers = [$offers] unless (ref $offers) =~ /^ARRAY/;
      foreach my $offer ( @$offers) {
        #print "OFFER ==== \n\n" . Dumper( $offer ) . "\n\n";
        #my $address = $offer->{User}->{BuyerInfo}->{ShippingAddress};
        #my $email = $offer->{User}->{Email};
        #print "$offer->{User}->{UserID} ($offer->{User}->{FeedbackScore}) bid $offer->{MaxBid}->{content} $offer->{MaxBid}->{currencyID}, lives in $address->{PostalCode}, $address->{Country}, email $email\n";
        print "$item $offer->{CreatedDate} \$$offer->{TransactionPrice}->{content} $offer->{Buyer}->{UserID} $offer->{Buyer}->{FeedbackScore}\n";
      }
    } else {
      #print "No bids on item $item\n";
    }
    
  } else {
    print "Unparsed result: \n$result\n\n";
  }
}
