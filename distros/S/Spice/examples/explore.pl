#!/usr/bin/perl
##################################################################
#    Copyright (c) 2000 Rohit Sharma. All rights reserved.
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
##################################################################

#############
#Author      : Rohit Sharma
#Date        : 21 August, 2000.
#Description : Spice Netlist Explorer.
#############


use spice ;
$spice::verbose = 1 ;

my $spiceFile ;

if ( $#ARGV < 0 ) {
   while (1) {
      print "Enter spice file:" ;
      $spiceFile = <STDIN>; chop $spiceFile ;
      last if ( length $spiceFile ) 
      }
   }
else {
   $spiceFile = $ARGV[0] ;
   } 

   my $init ;
   $init = spiceInit ( $spiceFile ) ;
   if ( $init == -1 ) {
     print "$spice::error\n" ;
     exit 0 ;
     }

while (1) {
   print " print the option number:
               1. Subckt Defn
               2. Top subckts
               3. Instance List
               4. Transistor List
               5. Resistor List
               6. Capacitor List
               9. Quit           :" ;
   my $option = <STDIN> ; chop $option ;
   if ( $option == 1 ) {
      print "Subckt Name:" ;
      my $ans = <STDIN> ; chop $ans ;
      my $ret = getSubckt ( $ans ) ;
      if ( $ret ) { print $ret ; }
      else { print "$spice::error\n" ; }
      }
   if ( $option == 2 ) {
      print "wait a sec...\n" ;
      my @ret = getTopSubckts ( ) ;
      $" = "\n" ;
      if ( $#ret >= 0 ) { print "@ret\n" ; }
      else { print "$spice::error\n" ; }
      $" = ' ' ;
      }
   elsif ( $option == 3 ) {
      print "Subckt Name:" ;
      my $ans = <STDIN> ; chop $ans ;
      my @ret = getInstances( $ans ) ;
      if ( $#ret>0 ) { print "@ret\n" ; }
      else { print "$spice::error\n" ; }
      }
   elsif ( $option == 4 ) {
      print "Subckt Name:" ;
      my $ans = <STDIN> ; chop $ans ;
      my @ret = getTransistors( $ans ) ;
      if ( $#ret>0 ) { print "@ret\n" ; }
      else { print "$spice::error\n" ; }
      }
   elsif ( $option == 5 ) {
      print "Subckt Name:" ;
      my $ans = <STDIN> ; chop $ans ;
      my @ret = getResistors( $ans ) ;
      if ( $#ret>0 ) { print "@ret\n" ; }
      else { print "$spice::error\n" ; }
      }
   elsif ( $option == 6 ) {
      print "Subckt Name:" ;
      my $ans = <STDIN> ; chop $ans ;
      my @ret = getCapacitors( $ans ) ;
      if ( $#ret>0 ) { print "@ret\n" ; }
      else { print "$spice::error\n" ; }
      }
   elsif ( $option == 9 || $option == 'q' ) { last ; }
   else { print "unrecognised option.\n" ; }
   }

exit 0 ;
