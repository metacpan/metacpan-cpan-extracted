#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;

my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => 0 } );

#my $seller = shift @ARGV || die "Usage: $0 seller-id";

my $kind = 'ActiveList';
my $status = 'active';
if( @ARGV && $ARGV[0] eq '--sold' ) {
  shift @ARGV;
  $kind = 'SoldList';
  $status = 'sold';
}

my $result = $eBay->submitRequest( "GetMyeBaySelling",
                                   {
                                    $kind => {
                                                   Sort => 'EndTime',
                                                   Pagination => {
                                                                  EntriesPerPage => 199,
                                                                  PageNumber => 1
                                                                 }
                                                  }
                                   }
                                 );
if( ref $result ) {
  #print "Result: " . Dumper( $result ) . "\n";

  print "   Item      W  B   Price Q   Title\n";
  #7551933377   0  0   49.99 1 Siliconix Transistor tester IPT II 2 Monitor

  my $arrayref;
  if( $status eq 'active' ) {
    $arrayref = $result->{$kind}->{ItemArray}->{Item};
  } elsif( $status eq 'sold' ) {
    $arrayref = $result->{$kind}->{OrderTransactionArray}->{Item};
  }
  
  foreach my $item (@$arrayref) {
    print "$item->{ItemID} ";
    print sprintf( "%3d ", $item->{WatchCount} || 0 );
    print sprintf( "%2d ", $item->{SellingStatus}->{BidCount} || 0 );
    print sprintf( "%7.2f ", $item->{SellingStatus}->{CurrentPrice}->{content} );
    print "$item->{Quantity} $item->{Title} ";
    print "\n";
  }

  print "$result->{SellingSummary}->{AuctionBidCount} bids\n";
} else {
  print "Unparsed result: \n$result\n\n";
}

