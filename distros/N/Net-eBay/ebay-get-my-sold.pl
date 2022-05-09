#!/usr/bin/perl

use strict;
use warnings;

use Net::eBay;
use Data::Dumper;
use Getopt::Long;

my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => 0 } );

my $status  = undef;
my $verbose = undef;

GetOptions(
           "status=s" => \$status,
           "verbose!" => \$verbose,
          );

my $request = {
               SoldList => {
                            Sort           => 'EndTimeDescending',
                            DurationInDays => 30,
                            Pagination     => {
                                               EntriesPerPage => 199,
                                               PageNumber     => 1
                                              }
                           },
              };

$request->{SoldList}->{OrderStatusFilter} = $status
  if $status;

my $result = $eBay->submitRequest( "GetMyeBaySelling", $request );

if ( $verbose ) {
  print "Request: " . Dumper( $request ) . "\n";
  print "Result:  " . Dumper( $result  ) . "\n";
}

my $count = 0;

if ( ref $result ) {
  #print "Result: " . Dumper( $result ) . "\n";

  #7551933377   0  0   49.99 1 Siliconix Transistor tester IPT II 2 Monitor

  my $arrayref;
  $arrayref = $result->{SoldList}->{OrderTransactionArray}->{OrderTransaction};
  $arrayref = [$arrayref] if ref $arrayref eq 'HASH';

  exit 0 unless $arrayref;

  foreach my $transaction (@$arrayref) {

    #
    # I am sorry that ebay result has such insane structure. It looks and
    # feels outright crazed, like they were on highly illegal drugs.
    #
    my @transactions = ();
    if ( $transaction->{Transaction} ) {
      @transactions = ($transaction->{Transaction});
    } elsif ( $transaction->{Order}->{TransactionArray}->{Transaction} ) {
      @transactions = @{$transaction->{Order}->{TransactionArray}->{Transaction}};
    }


    foreach my $transaction1 (@transactions) {
      my $buyer = $transaction1->{Buyer}->{UserID} || "UNKNOWN";

      my $items = $transaction1->{Item};
      $items = [$items] if ref $items eq 'HASH';

      my $price  = $transaction1->{TotalTransactionPrice}->{content} || "UNKNOWN";

      foreach my $item ( @$items ) {
        print "$buyer $price $item->{ItemID} $item->{Title}\n";
        $count++;
      }
    }
  }

} else {
  print "Unparsed result: \n$result\n\n";
}

print "$count items.\n";
