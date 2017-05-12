#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;

my $eBay = new Net::eBay;

my $site = shift @ARGV;

unless( $site ) {
  print STDERR "You did not specify eBay site ID (a number). No problem!\nI will use eBay main site number 0.\n";
  $site = 0;
}

# Sample XML:
#  <DetailLevel>1</DetailLevel>
#  <ErrorLevel>1</ErrorLevel>
#  <Verb>GetCategories</Verb>
#  <SiteId>0</SiteId>
#  <ViewAllNodes>1</ViewAllNodes>

print STDERR "GetCategories is a VERY expensive call. Do not make it often!\n";

my $result = $eBay->submitRequest( "GetCategories",
                                   {
                                    #ErrorLevel => 1,
                                    DetailLevel => 'ReturnAll',
                                    #Verb => "ValidateTestUserRegistration",
                                    #CategorySiteID => $site,
                                    #ViewAllNodes => 1
                                   }
                                 );

if( ref $result ) {
  my $vec = $result->{CategoryArray}->{Category};
  my $comma = "";
  foreach my $cat (@$vec) {
    foreach my $k (sort keys %$cat) {
      print "$comma$k=$cat->{$k}";
      $comma = ';';
    }
    print "\n";
  }
} else {
  print "Unparsed result: \n$result\n\n";
}
