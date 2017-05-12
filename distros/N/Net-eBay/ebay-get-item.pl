#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;
use DateTime::Precise;

use HTML::TreeBuilder;
use Text::Format;
use HTML::PrettyPrinter;
use HTML::FormatText;

die "Usage: $0 item-ids..." unless @ARGV;

my ($detail, $debug, $description, $csv);

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
  if($ARGV[0] eq '--description' ) {
    shift;
    $done = 1;
    $description = 1;
  }
  if($ARGV[0] eq '--csv' ) {
    shift;
    $done = 1;
    $csv = 1;
  }
} while( $done );


my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => $debug } );

foreach my $item (@ARGV) {
  my $result = $eBay->submitRequest( "GetItem",
                                     {
                                      ItemID => $item,
                                      DetailLevel => $description ? "ReturnAll" : "ItemReturnAttributes",
                                      # DetailLevel => "ReturnAll",
                                     }
                                   );
  if( ref $result ) {
    if( $debug ) {
      print "Result: " . Dumper( $result ) . "\n";
    }

    if( $result->{Errors} ) {
      print STDERR "Error selecting item $item: $result->{Errors}->{ShortMessage}\n";
      next;
    }
    
    my $high_bidder = $result->{Item}->{SellingStatus}->{HighBidder}->{UserID} || "-- NO BIDS --";
    my $bidcount = "";
    my $c = $result->{Item}->{SellingStatus}->{BidCount};

    my $quantity = $result->{Item}->{Quantity} || die "No quantity";
    my $sold = $result->{Item}->{SellingStatus}->{QuantitySold} || 0;
    my $qleft = $quantity - $sold;
    
    $bidcount = "($c bids)";
    my $left = "";
    my $tl = $result->{Item}->{TimeLeft};
    $left .= "$1 days, " if $tl =~ /(\d+)D/;    
    $left .= "$1 hours, " if $tl =~ /(\d+)H/;    
    $left .= "$1 minutes, " if $tl =~ /(\d+)M/;    
    $left .= "$1 seconds" if $tl =~ /(\d+)S/;
    $left =~ s/\, *$//;

    my $endtime = $result->{Item}->{ListingDetails}->{EndTime};
    $endtime =~ s/T/ /;
    $endtime =~ s/\.\d\d\d//;
    $endtime =~ s/Z/ GMT/;

    ############################################################
    # now figure out ending time in the LOCAL timezone
    # (not GMT and not necessarily California time)
    ############################################################
    my $local_endtime;
    {
      my $t1 = DateTime::Precise->new;
      $t1->set_from_datetime( $endtime );
      my $epoch = $t1->unix_seconds_since_epoch;
      my $t2 = DateTime::Precise->new;
      $t2->set_localtime_from_epoch_time( $epoch );
      #print "t1=" . $t1->asctime . " ($epoch) -> " . $t2->asctime . ".\n";
      $local_endtime = $t2->dprintf("%h:%m:%s %~M %D %^Y");
    }

    my $info = "";
    my $hb = $result->{Item}->{SellingStatus}->{HighBidder};
    if( $hb ) {
      $info .= "$hb->{Email}" if defined $hb->{Email};
      $info .= " $hb->{BuyerInfo}->{ShippingAddress}->{PostalCode}, $hb->{BuyerInfo}->{ShippingAddress}->{Country}"
        if defined $hb->{BuyerInfo}->{ShippingAddress}->{PostalCode} && defined $hb->{BuyerInfo}->{ShippingAddress}->{Country};

      if( defined $hb->{FeedbackScore} && defined $hb->{PositiveFeedbackPercent} ) {
        $info .= ", $hb->{FeedbackScore}\@$hb->{PositiveFeedbackPercent}\%";
      }
      $info = "($info)" if $info;
    }

    if( $csv ) {
      my $t = $result->{Item}->{Title};
      $t =~ s/,/;/g;
      print "item=$item,$t,Q=$quantity,Sold=$sold,$high_bidder $info $bidcount,Price=$result->{Item}->{SellingStatus}->{CurrentPrice}->{content}\n";
    } else {
      print "Item $item: $result->{Item}->{Title}
Ends:            $local_endtime (your local time)
Time Left:       $left
Quantity $quantity, $sold sold, $qleft left
High Bidder:     $high_bidder $info $bidcount
High Bid:        $result->{Item}->{SellingStatus}->{CurrentPrice}->{content}

";
    }
    if( $description ) {
      my $html =  $result->{Item}->{Description} . "\n";
      my $tree = HTML::TreeBuilder->new;
      $tree->parse( $html );

      if( 0 ) {
        #my $fmt = new Text::Format;
        #print $fmt->format( $tree->as_text ) . "\n";
      }

      if( 0 ) {
        my $hpp = new HTML::PrettyPrinter ('linelength' => 78,
                                           'quote_attr' => 1);
        
        # format the source
        my $linearray_ref = $hpp->format($tree);
        print @$linearray_ref;
      }

      if( 0 ) {
        print $html;
      }

      if( 1 ) {
        my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 78 );
        print $formatter->format($tree);
      }
      next;
    }
    
    if( $detail ) {
      print Dumper( $result );
    }
  } else {
    print "Unparsed result: \n$result\n\n";
  }
}
