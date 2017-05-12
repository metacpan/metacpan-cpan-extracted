#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;
use DateTime::Precise;

my $eBay = new Net::eBay;

# use new eBay API
$eBay->setDefaults( { API => 2, debug => 0 } );

die "Usage: $0 search terms..." unless @ARGV;

my $query = join( ' ', @ARGV );

my $result = $eBay->submitRequest( "GetSuggestedCategories",
                                   {
                                    Query => $query
                                   }
                                 );
if( ref $result ) {
  #print "Result: " . Dumper( $result ) . "\n";


#   $VAR1 = {
#            'Category' => {
#                           'CategoryParentID' => [
#                                                  '220',
#                                                  '479'
#                                                 ],
#                           'CategoryID' => '487',
#                           'CategoryName' => 'Other Scales',
#                           'CategoryParentName' => [
#                                                    'Toys & Hobbies',
#                                                    'Model RR, Trains'
#                                                   ]
#                          },
#            'PercentItemFound' => '3'
#           };

  my $count = 0;

  if( defined $result->{SuggestedCategoryArray}->{SuggestedCategory} ) {
    my @array;
    
    if( ref( $result->{SuggestedCategoryArray}->{SuggestedCategory} ) =~ /HASH/ ) {
      @array = ($result->{SuggestedCategoryArray}->{SuggestedCategory});
    } else {
      @array = @{$result->{SuggestedCategoryArray}->{SuggestedCategory}};
    }
    
    splice @array, 8 if @array > 8;
    @array = reverse @array;
    foreach my $cat (@array) {
      print sprintf( "\%5d  \%2d%% ", $cat->{Category}->{CategoryID}, $cat->{PercentItemFound} );
      if( !(ref $cat->{Category}->{CategoryParentName}) ) {
        print "$cat->{Category}->{CategoryParentName} => ";
      } else {
        foreach my $p ( @{$cat->{Category}->{CategoryParentName}}) {
          print "$p => ";
        }
      }
      print "$cat->{Category}->{CategoryName}\n";
      
      last if $count > 6;
    }
  } else {
    print STDERR "Error, no categories returned.\n\n" . Dumper( $result ) . "\n\n";
  }
} else {
  print "Unparsed result: \n$result\n\n";
}
