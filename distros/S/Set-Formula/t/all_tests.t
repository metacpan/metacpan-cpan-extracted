#!/usr/local/bin/perl -T

use Test::More tests => 21;

my $debug = (defined $ARGV[0])?1:0; 

BEGIN { use_ok( 'Set::Formula' ); }

my %result = ();
my $result ;
my $formula;

# ----------------------------------------------------#
#         Test of formula_checker ()                  #
# ----------------------------------------------------#
#             negative examples                       #
# ----------------------------------------------------#
ok( ! defined formula_checker ( ")F + G("  ),
   '")F + G("                    has false parentheses');

ok( ! defined formula_checker ( "(((x+Y))" ),
   '"(((x+Y))"                   has false parentheses' );

ok( ! defined formula_checker ( "((x+Y)))" ),
   '"((x+Y)))"                   has false parentheses' );

ok( ! defined formula_checker ( "(x+Y"     ),
   '"(x+Y"                       has false parentheses' );

ok( ! defined formula_checker ( "(x+)Y"     ),
   '"(x+)Y"                      has false parentheses' );

ok( ! defined formula_checker ( "x(+Y)"     ),
   '"x(+Y)"                      has false parentheses' );

ok( ! defined formula_checker ( "t1^A B+c"     ),
   '"t1^A B+c"                   is false formula' );

ok( ! defined formula_checker ( "A + -B"     ),
   '"A + -B"                     is false formula' );

ok( ! defined formula_checker ( "F + G - ()"  ),
   '"F + G - ()"                 is false formula');

ok( ! defined formula_checker ( "- F + G"  ),
   '"- F + G"                    is false formula');

ok( ! defined formula_checker ( "F + G ^"  ),
   '"F + G ^"                    is false formula');

# ----------------------------------------------------#
#             positive examples                       #
# ----------------------------------------------------#
ok( defined formula_checker ("setA + setB ^ setC"),
   '"setA + setB ^ setC"         is correct formula' );

ok( defined formula_checker ( "(((F + (G-R)^ (T1 + T2))))" ),
   '"(((F + (G-R)^ (T1 + T2))))" is correct formula' );

$formula  = "a ^ (
 b + (c ^
 d)) -
 e" ;
ok( defined formula_checker ( $formula ),
   "formula                      is correct multiline formula" );

# ----------------------------------------------------#
#         Test of formula_calcul ()                   #
# ----------------------------------------------------#
@A{qw (bisque  red      blue  yellow)} = (); 
@B{qw (bisque  brown    white yellow)} = (); 
@C{qw (magenta pink     green       )} = (); 
@D{qw (magenta pink     rose        )} = (); 
@E{qw (bisque  honeydew             )} = (); 
my %HoH_sets = ( A=>\%A, B=>\%B, C=>\%C, D=>\%D, E=>\%E );

$formula  = "A ^ ( B + (C ^ D) ) - E" ;
if (defined formula_calcul ($formula, \%result, \%HoH_sets))
{ for (keys %result) { $result .= sprintf "$_ "; } }
#print "1. $result\n";
is( $result, 'yellow ',
   "'$formula'    produces yellow ");

@a{qw (bisque  red      blue  yellow)} = (); 
@b{qw (bisque  brown    white yellow)} = (); 
@c{qw (magenta pink     green       )} = (); 
@d{qw (magenta pink     rose        )} = (); 
@e{qw (bisque  honeydew             )} = (); 
undef %HoH_sets;
%HoH_sets = ( a=>\%a, b=>\%b, c=>\%c, d=>\%d, e=>\%e );

$formula  = "a ^ (
 b + (c ^
 d)) -
 e" ;
$result = '';
if (defined formula_calcul ($formula, \%result, \%HoH_sets))
{ for (keys %result) { $result .= sprintf "$_ "; } }
#print "2. $result\n";
is( $result, 'yellow ',
   "multiline formula            produces yellow ");

$formula  = "A ^ ( B + (C ^ D)) * E" ;
ok ( ! defined formula_calcul ($formula, \%result, \%HoH_sets),
   "'$formula'     has rightly failed" );

#$formula  = "A ^ ( B + (C ^ D)) -- E" ;
#ok ( ! defined formula_calcul ($formula, \%result, \%HoH_sets),
#   "'$formula'    has rightly failed" );

$formula  = "A^(B+C)- UNDEFINED_OPERAND" ;
ok ( ! defined formula_calcul ($formula, \%result, \%HoH_sets),
   "'$formula' has rightly failed" );

#$formula  = "A ^ ( B + (C ^ D) - E" ;
#ok ( ! defined formula_calcul ($formula, \%result, \%HoH_sets),
#   "'$formula'    has rightly failed" );

# ----------------------------------------------------#
#         Test of equality_checker ()                 #
# ----------------------------------------------------#
%c = ();
%d = ();
%e = ();
@c{qw (magenta pink     green       )} = (); 
@d{qw (magenta pink     rose        )} = (); 
@e{qw (magenta pink     rose        )} = (); 
ok (! equality_checker(\%c, \%d), "not equal"); 
ok (  equality_checker(\%d, \%e), "equal"); 
