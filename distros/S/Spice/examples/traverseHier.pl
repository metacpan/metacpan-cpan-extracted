#!/usr/bin/perl

##################################################################
#    Copyright (c) 2000 Rohit Sharma. All rights reserved.
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
##################################################################

#############
#Author      : Rohit Sharma
#Date        : 21 August, 2000.
#Description : This script extracts the spice netlist hierarchy.
#############

use spice ;
$spice::verbose = 0 ;

my $spiceFile ;
my $subckt ;

if ( $#ARGV < 0 ) {
   while (1) {
      print "Enter spice file:" ;
      $spiceFile = <STDIN>; chop $spiceFile ;
      last if ( length $spiceFile )
      }
   print "Enter subckt name(default-top):" ;
   $subckt = <STDIN>; chop  $subckt ;
   }
else {
   $spiceFile = $ARGV[0] ;
   $subckt = $ARGV[1] ;
   }

my $init ;
$init = spiceInit ( $spiceFile ) ;
   if ( $init == -1 ) {
     print "$spice::error\n" ;
     exit 0 ;
     }

my @subckts ;
($subckt) ? ( @subckts = ( $subckt) ) : ( @subckts = getTopSubckts() ) ;

foreach $subckt ( @subckts ) {
   traverseHier ( $subckt, 0 ) ;
   }

sub traverseHier ( ) {
   my ( $node, $count ) = @_ ;
   my $i ;
   for ($i=0; $i<$count; $i++ ) { print "\t" ; }
   $count = $count + 1;
   print "$count.$node\n" ;
   my %subckts = getInstances ($node) ;
   my @children = values %subckts ;
   @children = removeDup ( @children ) ;
   undef %subckts ;
   if ( $#children < 0 ) { return ; }
   my $child ;
   foreach $child ( @children ) {
      traverseHier ( $child, $count ) ;
      }
   return ;
   }

sub removeDup {
   my ( @list ) = @_ ;
   my $part ;
   my %hash = ( ) ;
   foreach $part ( @list ) {
      $part =~ s/\s+//g ;
      $hash{$part} = 1 if ( length ( $part ) ) ;
      }
   @list = keys %hash ;
   return @list ;
   }

exit 0 ;
