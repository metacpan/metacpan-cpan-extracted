#!/usr/bin/perl
use strict;
use lib '../lib';
use Net::BCCN;
use Data::Dumper;

my $nt = new Net::BCCN PORT => 1122, SS => 60;

$nt->open() or die "cannot open sockets: " . $nt->err();

print Dumper( $nt );



my $msg;
#$msg = $nt->listen( 'test' );
#print Dumper( 'RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR', $msg );

#sleep 5;
while(1)
  {
  $msg = $nt->listen( 'test', { TIMEOUT => 5 } );
  print( "housekeeping..." . time() . "\n" ) unless $msg;
  print( "YEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEES!!!!!!" . time() . "\n" . Dumper( $msg ) ) if $msg;

  print Dumper( $nt->stats() ) unless time() % 7;
  }
