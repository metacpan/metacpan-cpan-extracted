#!/usr/bin/perl

use strict;
use warnings;
  
use Net::eBay;
use Data::Dumper;

my $eBay = new Net::eBay;

if( $eBay->{SiteLevel} ne 'dev' ) {
  print "Warning, you are trying to do a wrong thing. Validating test users works only on eBay sandbox, not in production. This script will now promptly fail, that's normal.\n";
}

my $result = $eBay->submitRequest( "ValidateTestUserRegistration",
                                   {
                                    ErrorLevel => 1,
                                    DetailLevel => 0,
                                    Verb => "ValidateTestUserRegistration",
                                    SiteId => 0,
                                   }
                                 );
if( ref $result ) {
  print "Result: " . Dumper( $result ) . "\n";
} else {
  print "Unparsed result: \n$result\n\n";
}
