#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;
use DateTime::Precise;

die "Usage: $0 user itemid requester" unless @ARGV;

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

my $user = shift @ARGV;
my $itemid = shift @ARGV;
my $requester = shift @ARGV;

my $result = $eBay->submitRequest( "GetUserContactDetails",
                                     {
                                      ItemID => $itemid,
                                      ContactID => $user,
                                      RequesterID => $requester
                                     }
                                   );
  if( ref $result ) {
    #print "Result: " . Dumper( $result ) . "\n";
    if( $result && $result->{ContactAddress} ) {
      print Dumper( $result->{ContactAddress} );
    }
  } else {
    print "Unparsed result: \n$result\n\n";
  }

