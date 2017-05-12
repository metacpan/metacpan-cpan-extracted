package spice ;
require 5.001 ;

##################################################################
#    Copyright (c) 2000 Rohit Sharma. All rights reserved.
#    This program is free software; you can redistribute it and/or
#    modify it under the same terms as Perl itself.
##################################################################

#############
#Author      : Rohit Sharma
#Date        : 21 August, 2000.
#Description : SPICE netlist interface
#
#
#
#############



BEGIN {
   require Exporter;
   use Carp ;
   use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION) ;
   @ISA = qw(Exporter);
   @EXPORT = qw(&spiceInit &getTopSubckts &getSubcktList &getSubckt &getResistors &getCapacitors &getTransistors &getInstances &getBulkConnections) ;
   $VERSION = 0.01 ;

   $SIG{INT} = sub { die "... wait wait. one sec, huh?\n" } ;
   #initilize global variables ;
   $spice::error = "" ;
   $spice::warn = "" ;
   $spice::verbose = 0 ;
   $spice::DEBUG_ = 0 ;
   $spice::tmpFile = "" ;
   $spice::topSubckt = "top" ;
   %spice::subckts = ( ) ;
   }

use strict ;

sub spiceInit {
   my ( $file ) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;

   do {
      carp "no spice file given." ;
      $spice::error = "no spice file given." ;
      return "-1";
      } unless ( defined $file ) ;
   do {
      carp "spice file $file is not a plain text file." ;
      $spice::error = "spice file $file is not a plain text file." ;
      return "-1";
      }unless ( -f $file && -T $file ) ;

   Log ( "Processing spice file $file: phase1\n" )
      if ( $spice::verbose ) ;
   my $retValue ;
   $retValue = processSpice ( $file ) ;
   return "-1" if ( $retValue == "-1" ) ;

   Log ( "Processing spice file $file: phase2\n" )
      if ( $spice::verbose ) ;
   $retValue = readSpice ( $spice::tmpFile ) ;
   return "-1" if ( $retValue == "-1" ) ;
   return 0; # Initialization sucessful.
   }

sub processSpice {
   my ( $file ) = @_ ;
   do {
      $spice::tmpFile = "${file}.tmp" if ($file) ;
      } unless ( -f $spice::tmpFile ) ;
   do {
      carp "Could not open new spice File $spice::tmpFile for writing." ;
      $spice::error = "Could not open new spice File $spice::tmpFile for writing." ;
      return "-1" ;
      } unless open ( TMPSPICE, ">$spice::tmpFile" ) ;
   do {
      carp "Could not open spice File $file for reading." ;
      $spice::error = "Could not open spice File $file for reading." ;
      return "-1" ;
      } unless open ( SPICE, "<$file" ) ;

   Log ( "reading spice file ..." ) if ( $spice::verbose ) ;
   my $line ;
   my $prevLine ;
   my $lineNo  = 0;

   while ( $line = <SPICE> ) {
      $lineNo++ ;
      Log ( "." ) if ( $lineNo/1000==int($lineNo/1000) && $spice::verbose) ;

      $line =~ s/\n//g ;
      next unless ( length $line ) ;# ignore blank lines.
      next if ( $line =~ m/^\s*\*/ );# weed out comments.
      if ( $line =~ m/^\s*\+/ ) {
         $line =~ s/^\s*\+/ /g ; # eat up continuation character +.
         $prevLine .= $line ;
         }
      else {
         print TMPSPICE "$prevLine\n" if ( $prevLine ) ;
         $prevLine = $line ;
         }
      }
   print TMPSPICE "$prevLine\n" if ( $prevLine ) ;
   Log ( "... done.\n" ) if ( $spice::verbose ) ;
   close SPICE ;
   close TMPSPICE ;
   return 0; #phase 1 successful.
   }

sub readSpice ( ) {
   my ( $file ) = @_ ;
   my $subcktName = "" ;
   
   do {
      carp "Could not open new spice File $file for reading." ;
      $spice::error = "Could not open new spice File $file for reading." ;
      return "-1" ;
      } unless open ( TMPSPICE, "<$file" ) ;

   my $line ; 
   while ( $line = <TMPSPICE> ) {
      if( $line =~ m/^\s*\+/ ) { # self validation. 
         Log ( "processSpice subroutine didnt work correctly. Bug in the spice.pm\n" ) ;
         return "-1" ;
         }

      next unless ( $line =~ m/^\s*x/i ||
                    $line =~ m/^\s*r/i ||
                    $line =~ m/^\s*c/i ||
                    $line =~ m/^\s*m/i ||
                    $line =~ m/^\s*\.subckt/i ||
                    $line =~ m/^\s*\.end/i
                    ) ;

      if ( $line =~ m/^\s*\.subckt/i ) {
         $subcktName = getSubcktName ( $line ) ; 
         do {
            carp "WARN: incorrect .subckt definition: $line.\n" ;
            $spice::warn = "WARN: incorrect .subckt definition: $line.\n" ;
            next ;
            } if ( $subcktName eq "-1" ) ;
         $spice::subckts{$subcktName} = $line ;
         next ;
         }
      elsif ( $line =~ m/^\s*\.ends/i ) {
         do {
            carp "WARN:.ends statment without subckt definition. $line.\n" ;
            $spice::warn = "WARN:.ends statment without subckt definition. $line.\n";
            next ;
            }unless ( $subcktName ) ;
         $spice::subckts{$subcktName} .= $line ;
         $subcktName = "" ;
         next ;
         }
      elsif ( $line =~ m/^\s*x/i ) {
        $subcktName = $spice::topSubckt unless ( $subcktName ) ;
        $spice::subckts{$subcktName} .= $line ;
        next ;
        } 
      elsif ( $line =~ m/^\s*r/i ) {
        $subcktName = $spice::topSubckt unless ( $subcktName ) ;
        $spice::subckts{$subcktName} .= $line ;
        next ;
        } 
      elsif ( $line =~ m/^\s*c/i ) {
        $subcktName =  $spice::topSubckt unless ( $subcktName ) ;
        $spice::subckts{$subcktName} .= $line ;
        next ;
        } 
      elsif ( $line =~ m/^\s*m/i ) {
        $subcktName = $spice::topSubckt unless ( $subcktName ) ;
        $spice::subckts{$subcktName} .= $line ;
        next ;
        } 
      elsif ( $line =~ m/^\s*\.end[\s+|\n]/i ) { last; }
      }

   close TMPSPICE ;
   unlink ( $spice::tmpFile ) if ( -f $spice::tmpFile ) ;
   return 0 ; # mission successful :=)
   }

sub getBulkConnections {
   my ($txName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   $spice::warn = "This subroutine has not been implemented yet.\n" ;
   return "-1";
   }

sub getSubcktName {
   my ( $stmt ) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my @parts ;
   $stmt =~ s/^\s*\.subckt\s+//i ;
   @parts = split /\s+/, $stmt ;
if ($spice::DEBUG_ ) { print "\t\tsubckt Name : $parts[0].\n" ; }
   if ( $parts[0] ) { return $parts[0]; }
   else { return "-1" ; }
   }

sub getSubckt {
   my ($subckt) = @_ ;
   $spice::error = "" ;
   if ( $subckt && $spice::subckts{$subckt} ) {
      return $spice::subckts{$subckt} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      } 
   }

sub getCapacitors {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;

   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/^\s*c/i ) ;
      my @retValue ;
      @retValue = getResCapName ( $line ) ;
      if ( $#retValue > 0 ) { # make sure it has returned 2 elements.
         push @list, @retValue ;
         }
      }
   return @list ;
   }

sub getResistors {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;

   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/^\s*r/i ) ;
      my @retValue ;
      @retValue = getResCapName ( $line ) ;
      if ( $#retValue > 0 ) { # make sure it has returned 2 elements.
         push @list, @retValue ;
         }
      }
   return @list ;
   }

sub getResCapName {
   my ( $stmt ) = @_ ;
   if ( $stmt !~ m/^\s*[rc]/i ) {
      $spice::error = "Not a valid resistor or capacitor declaration.  :$stmt" ;
      return "-1" ;
      }
   my @tmp ;
   @tmp = split /\s+/, $stmt ;
   if ( $#tmp < 3 ) {
      $spice::error = "Not a valid resistor or capacitor declaration.  :$stmt" ;
      return "-1" ;
      }
   return ( $tmp[0], $tmp[3] ) ;
   }

sub getTransistors {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;

   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/^\s*m/i ) ;
      my @retValue ;
      @retValue = getTxName ( $line ) ;
      if ( $#retValue > 0  ) { # make sure it has returned 2 elements.
         push @list, @retValue ;
         }
      }
   return @list ;
   }

sub getTxName {
   my ( $stmt ) = @_ ;
   if ( $stmt !~ m/^\s*m/i ) {
      $spice::error = "Not a valid instance statement.  :$stmt" ;
      return "-1" ;
      }
   my $tx ;
   my $type ;
   ( $tx ) = split /\s+/, $stmt ;
   my @tmp ;
   if ( $stmt =~ m/\=/ ) {
      ( @tmp ) = split /\s*\=\s*/, $stmt ;
      ( @tmp ) = split /\s+/, $tmp[0] ;
      if ( $tmp[$#tmp-1] ) {
         $type = $tmp[$#tmp-1] ;
         }
      else {
         $spice::error = "could not find transistor type." ;
         return "-1" ;
         } 
      }
   else {
      ( @tmp ) = split /\s+/, $stmt ;
      if ( $tmp[$#tmp] ) {
         $type = $tmp[$#tmp] ;
         }
      elsif ( $tmp[$#tmp-1] ) {
         $type = $tmp[$#tmp-1] ;
         }
      else {
         $spice::error = "could not find transistor type." ;
         return "-1" ;
         }
      }
   return ( $tx, $type ) ;
   }

sub getInstances {
   my ($subcktName) = @_ ;
   $spice::error = "" ;
   $spice::warn = "" ;
   my $subcktDefn ;

   $spice::error = "" ;
   if ( $subcktName && $spice::subckts{$subcktName} ) {
      $subcktDefn = $spice::subckts{$subcktName} ;
      }
   else {
      $spice::error = "Subckt definition not found in spice." ;
      return "-1" ;
      }
   my @list ;
   my $line ;
   foreach $line ( split /\n/, $subcktDefn )  {
      next unless ( $line =~ m/^\s*x/i ) ;
      my @retValue ;
      @retValue = getInstName ( $line ) ;
      if ( $#retValue > 0 ) { # make sure it has returned 2 elements.
         push @list, @retValue ;
         }
      }
   return @list ;
   }

sub getInstName {
   my ( $stmt ) = @_ ;
   if ( $stmt !~ m/^\s*x/i ) {
      $spice::error = "Not a valid instance statement." ;
      return "-1" ;
      }
   my $inst ;
   my $subckt ;
   ( $inst ) = split /\s+/, $stmt ;
   my @tmp ;
   if ( $stmt =~ m/\=/ ) {
      ( @tmp ) = split /\s*\=\s*/, $stmt ;
      ( @tmp ) = split /\s+/, $tmp[0] ;
      if ( $tmp[$#tmp-1] ) {
         $subckt = $tmp[$#tmp-1] ;
         }
      else {
         $spice::error = "could not find subckt name." ;
         return "-1" ;
         } 
      }
   else {
      ( @tmp ) = split /\s+/, $stmt ;
      if ( $tmp[$#tmp] ) {
         $subckt = $tmp[$#tmp] ;
         }
      elsif ( $tmp[$#tmp-1] ) {
         $subckt = $tmp[$#tmp-1] ;
         }
      else {
         $spice::error = "could not find subckt name." ;
         return "-1" ;
         }
      }
   return ( $inst, $subckt ) ;
   }

sub getTopSubckts {
   my @nodes ;
   $spice::error = "" ;
   $spice::warn = "" ;
   @nodes = keys %spice::subckts ;
   my @list ;
   my $node1 ;
   my $node2 ;
   foreach $node1 ( @nodes ) {
      my $top = 1 ;
      foreach $node2 ( @nodes ) {
         next if ( $node2 eq $node1 ) ;
         my $inst ;
         my @instances ;
         my %tmp ;
         %tmp = getInstances($node2) ;
         @instances = values %tmp ;
         undef %tmp ;
         foreach $inst ( @instances ) {
            if ( $inst eq $node1 ) {$top = 0;  last ;}
            }
         last if ( not $top ) ;
         }
         push @list, $node1 if ( $top ) ;
      }
   return @list ;
   }

sub getSubcktList {
   $spice::error = "" ;
   $spice::warn = "" ;
   my @list ;
   @list =  keys %spice::subckts ;
   if ( $#list == -1 ) {
      $spice::error = "could not find subckt name." ;
      return "-1" ;
      }
   return @list ;
   }

sub Log {
   my ( $msg ) = @_ ;
   print $msg ;
   }

END {
   Log ( "exiting spice... \n" ) if ( $spice::verbose ) ;
   undef $spice::error ;
   undef $spice::warn  ;
   undef $spice::verbose  ;
   undef $spice::DEBUG_ ;
   undef $spice::tmpFile ;
   undef $spice::topSubckt ;
   undef %spice::subckts ;
   }
1; #just for fun.

__END__

=pod

=head1 NAME

   spice - interface calls for parsing spice netlst.

=head1 SYNOPSIS

   use spice ;
   spiceInit ( $file ) ;
      #returns 0 if initilization is successful and >0 otherwise.
      #check $spice::error in case of failure.

=head1 DESCRIPTION

=head2 CALLING spice.pm ROUTINES

   This package only cares about m, R, C, X, and subckts.
   spice-decks are ignored.

   This priliminary version of spice supports following subroutine
   calls-

   @subckt = getTopSubckts ( ) ;
      returns a list of subckts, top in the hierarchy.

   @subcktList = getSubcktList ( ) ;
      returns a list of subckts present in the netlist.

   $subcktDefn = getSubckt ( $subckt ) ;
      returns a string containing the definition of subckt.

   getResistors ( $subckt ) ;
      returns a hash containing the name and value of Resistors.

   getCapacitors ( $subckt ) ;
      returns a hash containing the name and value of capacitors.

   getTransistors ( $subckt ) ;
      returns a hash of transitor names and their types. i.e. n or p.

   getInstances ( $subckt ) ;
      returns a hash of instantion name and their subckt names.

=head2 ERROR HANDLING

   All these subroutines return a value less than 0 upon failure.

   you may want to check following strings for the reason-
   $spice::error
   $spice::warn

   You may want to set $spice::verbose to 1, for a detailed message on
   the standard output.

=head1 APPLICATION

This release
   o Extracting the hierarchy.
   o Traversing the netlist.
   o Creating html document for an easy naviagation of netlist.
   o any other appication, which requires netlist specific information.

Future release
Current version does not support more than one netlist open at a time.
Future version, (Object Oriented Design) shall support this feature.
It can help developing the following applications-
   o Comparing two spice netlists.
   o extracting the netlist difference.

Here is the code of traversing the netlist-

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
   if ( $init == "-1" ) {
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

=head1 INTERNALS

   The netlist is parsed in two simple phases. First phase requires
   opening a temporary file, which is deleted soon after creating
   the data-structures. This was done to manage unusually large
   netlist, to reduce on run time memory requirements. (With earlier
   implementation, where I do not write any tmp files, I came across
   a testcase, which took huge memory to build the internal data
   structures.)

   You may have problems running the scripts using this package in the
   directories, where you do not have write permission. Please set
   $spice::tmpFile variable to a file name with absolute path, where
   you have write permissions.

   Top level instances are stored in a hypothetical subcircuit called
   B<top>. If you need to change this subcircuit name, please set the
   variable $spice::topSubckt to the name you desire.

=head1 LIMITATION

   As mentioned earlier, this package only cares about the circuit
   elements like Resistors, Capacitors and Transistors along with
   subcircuit deinition and instances. Everything else is ignored.

   user can open only one file at a time. Future version shall
   support opening more tha one netlist at a time.

=head1 AUTHOR

Rohit Sharma,
srohit@cpan.org

=cut
