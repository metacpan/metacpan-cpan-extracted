
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

use Data::Dumper ;

tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;
my $ss = tied %ss ;

# formula relocating
$ss->{DEBUG}{PRINT_FORMULA}++ ; # the formula is displayed when the formula sub is created

$ss{'A1:A3'} = 1 ;

# example 1
$ss{'C1:C2'} = PerlFormula('$ss->Sum("A1:A2")') ;
print "Example 1 => @{@ss{'C1:C2'}}\n" ;

# example 2
$ss->Reset() ;
$ss{'A1:A3'} = 1 ;
$ss{'D1:E2'} = PerlFormula('$ss->Sum("[A]1:A[3]")',) ;
print "Example 2 => @{@ss{'D1:E2'}}\n" ;

# Relative and fixed cell addresses
#  some errors in the range that are caught at run time
$ss->{DEBUG}{PRINT_FORMULA}-- ;
$ss->{DEBUG}{DEFINED_AT}++ ;

$ss{'D1:D2'} = PerlFormula('$ss->Sum("[A1]:[A3]")') ;
print "D1:D2 => @{@ss{'D1:D2'}}\n" ;

$ss{'E1:E2'} = PerlFormula('$ss->Sum("[A]1]:[A]3")') ; # ugly but accepted
print "E1:E2 => @{@ss{'E1:E2'}}\n" ;

$ss{'F1:F2'} = PerlFormula('$ss->Sum("[A[1]:A[3]")') ;
print "F1:F2 => @{@ss{'F1:F2'}}\n" ;

$ss{'G1:G2'} = PerlFormula('$ss->Sum("[A][1]:A3")') ;
print "G1:G2 => @{@ss{'G1:G2'}}\n" ;

$ss{'H1:H2'} = PerlFormula('$ss->Sum("[A]]1]:[A3]")') ; #error in the address
print "H1:H2 => @{@ss{'H1:H2'}}\n" ;

$ss{'I1:I2'} = PerlFormula('$ss->Sum("[A]]1]:")') ; #error in the address
print "I1:I2 => @{@ss{'I1:I2'}}\n" ;

$ss{'J1:J2'} = PerlFormula('$ss->Sum("[A]]1]")') ; #error in the address

print $ss->Dump() ;
print "J1:J2 => @{@ss{'J1:J2'}}\n" ;

