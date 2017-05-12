# -*- perl -*-

use strict;
use Set::IntSpan 1.17;

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

print "1..", 6 + 8 + 1 + 8 + 4 + 12 + 7 + 1 + 12 + 2, "\n";

my $a = new Set::IntSpan "1-5";
my $e = new Set::IntSpan;
my $i = new Set::IntSpan "(-)";


# Conversion
$a or  Not; OK;
$e and Not; OK;
$i or  Not; OK;

"$a" eq "1-5" or Not; OK;
"$e" eq "-"   or Not; OK;
"$i" eq "(-)" or Not; OK;

# Equality
$a eq "1-5" or Not; OK;  $a eq "6-9" and Not; OK;
"1-5" eq $a or Not; OK;  "6-9" eq $a and Not; OK;
$a ne "6-9" or Not; OK;  $a ne "1-5" and Not; OK;
"6-9" ne $a or Not; OK;  "1-5" ne $a and Not; OK;

# Unary
~$a eq "(-0,6-)" or Not; OK;

# Binary
my $u1 = $a + "3-8";
my $u2 = "3-8" + $a;
$u1 eq "1-8" or Not; OK;
$u2 eq "1-8" or Not; OK;

my $d1 = $a - "3-8";
my $d2 = "3-8" - $a;
$d1 eq "1-2" or Not; OK;
$d2 eq "6-8" or Not; OK;

my $i1 = $a * "3-8";
my $i2 = "3-8" * $a;
$i1 eq "3-5" or Not; OK;
$i2 eq "3-5" or Not; OK;

# Assignment
my $x1 = $a ^ "3-8";
my $x2 = "3-8" ^ $a;
$x1 eq "1-2,6-8" or Not; OK;
$x2 eq "1-2,6-8" or Not; OK;

$a += "3-8";
$a eq "1-8" or Not; OK;

$a -= "3-8";
$a eq "1-2" or Not; OK;

$a *= "3-8";
$a eq "-"   or Not; OK;

$a ^= "3-8";
$a eq "3-8" or Not; OK;

# Equivalence
$a == 6 or Not; OK;	 $a == 7 and Not; OK;
$a != 7 or Not; OK;	 $a != 6 and Not; OK;
$a <  7 or Not; OK;	 $a <  6 and Not; OK;
$a <= 6 or Not; OK;	 $a <= 5 and Not; OK;
$a >  5 or Not; OK;	 $a >  6 and Not; OK;
$a >= 6 or Not; OK;	 $a >= 7 and Not; OK;

($a <=>  7) == -1 or Not; OK;
($a <=>  6) ==  0 or Not; OK;
($a <=>  5) ==  1 or Not; OK;
( 5 <=> $a) == -1 or Not; OK;
( 7 <=> $a) ==  1 or Not; OK;
($a <=> $i) == -1 or Not; OK;
($i <=> $a) ==  1 or Not; OK;

my @c = sort($i, $a, $e);
$c[0] eq $e and $c[1] eq $a and $c[2] eq $i or Not; OK;

$a lt $i or Not; OK;     $i lt $a and Not; OK;
$a le $i or Not; OK;     $i le $a and Not; OK;
$i gt $a or Not; OK;     $a gt $i and Not; OK;
$i ge $a or Not; OK;     $a ge $i and Not; OK;
$a le $a or Not; OK;     $a lt $a and Not; OK;
$a ge $a or Not; OK;     $a gt $a and Not; OK;

"3-8" le $a or Not; OK;
"3-8" ge $a or Not; OK;
