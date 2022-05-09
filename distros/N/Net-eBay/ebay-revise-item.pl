#!/usr/bin/perl

use strict;
use warnings;

use IgorBusinessRules;
use Net::eBay;
use Data::Dumper;

my $title               = undef;
my $subtitle            = undef;
my $price               = undef;
my $quantity            = undef;
my $category            = undef;
my $bin                 = undef;
my $blockForeignBidders = undef;
my $call                = "ReviseItem";
my $gallery             = undef;
my $duration            = undef;
my $description         = undef;
my $siteid              = 0;
my $bestoffer           = undef;
my $nobestoffer         = undef;
my $to_store            = undef;
my $pid                 = undef;
my $item                = undef;
my $returnpolicy        = undef;
my $nopaypal            = undef;
my $nopickup            = undef;
my $dispatchtimemax     = undef;
my $flatshipping        = undef;
my $verbose             = undef;

if ( -f 'item.txt' ) {
  $item = `cat item.txt`;
  chomp $item;
}

my $use_descr = 1;

my $done = 1;

sub get_argument {
  my ($name,$ref) = @_;
  if ( $ARGV[0] eq "--$name" ) {
    shift @ARGV;
    $$ref = shift @ARGV;
    die "--$name requires an argument!" unless defined $$ref;
    return 1;
  }
  return undef;
}

while ( $done && defined $ARGV[0]) {
  $done = 0;

  if ( $ARGV[0] eq '--relist' ) {
    $call = 'RelistItem';
    $done = 1;
    shift @ARGV;
    next;
  }

  if ( $ARGV[0] eq '--bestoffer' ) {
    $bestoffer = 1;
    $done = 1;
    shift @ARGV;
    next;
  }

  if ( $ARGV[0] eq '--nobestoffer' ) {
    $nobestoffer = 1;
    $done = 1;
    shift @ARGV;
    next;
  }

  if ( $ARGV[0] eq '--verbose' ) {
    $verbose = 1;
    $done = 1;
    shift @ARGV;
    next;
  }

  if ( $ARGV[0] eq '--to_store' ) {
    $to_store = 1;
    $done = 1;
    shift @ARGV;
    next;
  }

  if ( $ARGV[0] eq '--pid' ) {
    $pid = 1;
    $done = 1;
    shift @ARGV;
    next;
  }

  if ( $ARGV[0] eq '--nopaypal' ) {
    $nopaypal = 1;
    $done = 1;
    shift @ARGV;
    next;
  }

  if ( $ARGV[0] eq '--nopickup' ) {
    $nopickup = 1;
    $done = 1;
    shift @ARGV;
    next;
  }

  next if $done = get_argument( 'title', \$title );
  next if $done = get_argument( 'subtitle', \$subtitle );
  next if $done = get_argument( 'price', \$price );
  next if $done = get_argument( 'quantity', \$quantity );
  next if $done = get_argument( 'siteid', \$siteid );
  next if $done = get_argument( 'bin', \$bin );
  next if $done = get_argument( 'category', \$category );
  next if $done = get_argument( 'gallery', \$gallery );
  next if $done = get_argument( 'duration', \$duration );
  next if $done = get_argument( 'description', \$description );
  next if $done = get_argument( 'returnpolicy', \$returnpolicy );
  next if $done = get_argument( 'flatshipping', \$flatshipping );
  next if $done = get_argument( 'block-foreign-bidders', \$blockForeignBidders );
  next if $done = get_argument( 'dispatchtimemax', \$dispatchtimemax );

  if ( $done = get_argument( 'item', \$item ) ) {
    $use_descr = undef;
    next;
  }
}

die "Need to have item number either from item.txt or from --item argument" unless defined $item;

die "invalid itemid '$item'" unless $item =~ /^\d+$/;

my $request = {
               Item => {
                        ItemID => $item,
                       },
              };



$request->{Item}->{DispatchTimeMax} = $dispatchtimemax if $dispatchtimemax;

$request->{Item}->{Title}         = $title if ( $title );
$request->{Item}->{SubTitle}      = $subtitle if ( $subtitle );
$request->{Item}->{StartPrice}    = $price if ( $price );
$request->{Item}->{Quantity}      = $quantity if ( $quantity );
$request->{Item}->{BuyItNowPrice} = $bin if ( $bin );

if ( $pid ) {
  $request->{Item}->{ProductListingDetails} = {
                                               BrandMPN => {
                                                            Brand => 'Does not apply',
                                                            MPN   => 'Does not apply',
                                                           },
                                               UPC => 'Does not apply',
                                              };

  $request->{Item}->{ItemSpecifics}->{NameValueList} =
    [
     { Name => 'Brand', Value => 'Does not apply' },
     { Name => 'MPN', Value => 'Does not apply' },
    ];
}

if ( $to_store ) {
  $request->{Item}->{BestOfferDetails}->{BestOfferEnabled} = 'true';
  $request->{Item}->{ListingDuration} = "GTC";
  $request->{Item}->{ListingType}     = "StoresFixedPrice";
} else {
  $request->{Item}->{ListingDuration}      = "Days_$duration" if ( $duration );
}

$request->{Item}->{PrimaryCategory}->{CategoryID} = $category if ( $category );

$request->{Item}->{PictureDetails}->{GalleryURL}         = $gallery  if $gallery;
$request->{Item}->{PictureDetails}->{PictureURL}         = $gallery  if $gallery;
$request->{Item}->{PictureDetails}->{ExternalPictureURL} = $gallery  if $gallery;
$request->{Item}->{PictureDetails}->{GalleryType}        = 'Gallery' if $gallery;

$request->{Item}->{BuyerRequirements}->{MinimumFeedbackScore} = -1;
$request->{Item}->{BuyerRequirements}->{ShipToRegistrationCountry} = $blockForeignBidders if defined $blockForeignBidders;

$request->{Item}->{PayPalEmailAddress} = 'ichudov@gmail.com';
$request->{Item}->{UseTaxTable} = 'true';

$request->{Item}->{BestOfferDetails}->{BestOfferEnabled} = 'true'
  if $bestoffer;

$request->{Item}->{BestOfferDetails}->{BestOfferEnabled} = 'false'
  if $nobestoffer;

if( $flatshipping ) {
    $request->{Item}->{ShippingDetails} = 
    {
        ShippingServiceOptions => {
            ShippingService => 'Other',
            ShippingServiceCost => $flatshipping,
        },
        ShippingType => 'Flat',
    };
}

if ( $price ) {
  $request->{Item}->{ListingDetails} =
    {
     BestOfferAutoAcceptPrice => sprintf( "%.2f", $price * igor_ebay_min_autoaccept_factor ),
     MinimumBestOfferPrice    => sprintf( "%.2f", $price * igor_ebay_max_autoreject_factor ),
    };
}

if ( $nopaypal ) {
  $request->{Item}->{PaymentMethods} = [ 'CashOnPickup', 'AmEx' ];
}

if ( $nopickup ) {
  $request->{Item}->{PaymentMethods} = [ 'PayPal' ];
}

if ( $returnpolicy ) {
  if ( $returnpolicy eq 'noreturns' ) {
    $request->{Item}->{ReturnPolicy} = {
                                        Description           => 'No Returns',
                                        ReturnsAccepted       => 'No Returns',
                                        ReturnsAcceptedOption => 'ReturnsNotAccepted',
                                       };
  } elsif ( $returnpolicy =~ /^(\d+)\%/ ) {
    my $pct = $1;
    $request->{Item}->{ReturnPolicy} = {
                                        'RefundOption' => 'MoneyBack',
                                        'RestockingFeeValueOption' => "Percent_$pct",
                                        'Refund' => 'Money Back',
                                        'ShippingCostPaidByOption' => 'Buyer',
                                        'ReturnsWithin' => '14 Days',
                                        'ReturnsAccepted' => 'Returns Accepted',
                                        'ShippingCostPaidBy' => 'Buyer',
                                        'ReturnsWithinOption' => 'Days_14',
                                        'ReturnsAcceptedOption' => 'ReturnsAccepted',
                                        'Description' => "Restocking fees: $pct%",
                                        'RestockingFeeValue' => "$%pct%"
                                       };
  } else {
    die "Error, invalid returnpolicy argument.";
  }
}

if ( $use_descr || $description ) {
  my $descr;
  if ( $description ) {
    $descr = $description;
  } else {

    die 'no file index.html'
      unless -f 'index.html';

    $descr = `cat index.html`;
  }

  $request->{Item}->{Description} = "<![CDATA[ $descr ]]>";


  if ( -f ".picurl" ) {
    open( PIC, ".picurl" );
    my $picurl = <PIC>;
    chomp $picurl;
    close( PIC );

    $request->{Item}->{PictureDetails} = {
                                          GalleryType => 'Gallery',
                                          GalleryURL  => $picurl,
                                          PictureURL  => $picurl,
                                         };
  }
}

my $ebay = new Net::eBay;
$ebay->setDefaults( { siteid => $siteid } );

#print STDERR "Calling $call...\n";

print Dumper( $request ) if $verbose;

my $result = $ebay->submitRequest( $call, $request );

print Dumper( $result ) if $verbose;

if ( ref $result ) {

  if ( $result->{Errors} && !($result->{Fees}) ) {
    print "FAILED $item!!!\n" . Dumper( $result->{Errors} ) . "\n\n";
    exit 1;
  }

  #print "Succeeded!\n\n";

  my $total = 0;
  foreach my $fee (@{$result->{Fees}->{Fee}}) {
    my $amount = $fee->{Fee}->{content};

    next unless $amount > 0 && $fee->{Name} ne 'ListingFee';

    print "Fee: $fee->{Name}: $amount.\n";
    $total += $amount;
  }

  print "TOTAL FEE: $total, Item $result->{ItemID}\n";

  if ( $call eq 'RelistItem' ) {
    if ( $result->{ItemID} ) {
      #open( ITEM, ">item.txt" );
      #print ITEM "$result->{ItemID}\n";
      #close( ITEM );
    } else {
      print STDERR "Strange, no item id given by relisting.\n";
    }
  }

} else {
  print "Failed: " . Dumper( $result ) . "\n";
}

#system( "bash -i -c reset-ebay" );
