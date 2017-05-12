BEGIN { 
   $::DEBUG_ = 0 ;
   push @INC, ".." if ( $::DEBUG_ ) ;
   }

use strict ;
use spice ;
$spice::verbose = 0 ;

my $spiceFile ;
if ( $::DEBUG_ ) {
   $spiceFile = "/home/rohit/eda_tools/spiner/t/netlist.sp" ;
   }
else {
   $spiceFile = "t/netlist.sp" ;
   }

print "1..8\n" ;
my $init ;
$init = spiceInit ( $spiceFile ) ;
if ( $init == "-1" ) {
   print "$spice::error\n" ;
   print "not ok\n" ;
   }
else {
   print "ok\n" ;
   }

my @subckts ;
@subckts  = getTopSubckts( ) ;
my $subckts = join ' ', @subckts ;
print "@subckts" if ( $::DEBUG_ ) ;
if ( $subckts eq "mux2")  {
   print "ok\n" ;
   }
else {
   print "not ok\n" ;
   }

my $subckt = $subckts ;
undef @subckts ;
undef $subckts ;

my @list = getSubcktList ( )  ;
print "@list" if ( $::DEBUG_ ) ;
if ( $#list == 5 )  {
   print "ok\n" ;
   }
else {
   print "not ok\n" ;
   }
undef @list ;

my $defn = getSubckt ( "inv" ) ;
if ( $defn != "-1" ) {
   print "ok\n" ;
   }
else {
   print "not ok\n" ;
   }
undef $defn ;

my @res = getResistors ("mux2") ;
my $res = join ' ', @res ;
print "$res" if ( $::DEBUG_ ) ;
if ( $res != "-1" ) {
   print "ok\n" ;
   }
else {
   print "not ok\n" ;
   }
undef $res ;
undef @res ;

my @cap = getCapacitors ("mux2") ;
my $cap = join ' ', @cap ;
print "$cap" if ( $::DEBUG_ ) ;
if ( $cap != "-1" ) {
   print "ok\n" ;
   }
else {
   print "not ok\n" ;
   }
undef $cap ;
undef @cap ;

my @tx = getTransistors ( "inv" ) ;
my $tx = join ' ', @tx ;
print "$tx" if ( $::DEBUG_ ) ;
if ( $tx != "-1" ) {
   print "ok\n" ;
   }
else {
   print "not ok\n" ;
   }
undef $tx ;
undef @tx ;

my @inst = getInstances ( "mux2" ) ;
my $inst = join ' ', @inst ;
print "$inst" if ( $::DEBUG_ ) ;
if ( $inst != "-1" ) {
   print "ok\n" ;
   }
else {
   print "not ok\n" ;
   }
undef $inst ;
undef @inst ;
