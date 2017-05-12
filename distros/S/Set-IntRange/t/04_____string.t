#!perl -w

use strict;
no strict "vars";

use Bit::Vector;

use Set::IntRange;

# ======================================================================
#   $set->from_Hex($string);
#   $set->to_Hex();
#   $set->from_Enum($string);
#   $set->to_Enum();
# ======================================================================

print "1..13\n";

$n = 1;

$lower = -500;
$upper =  500;

$limit = $upper - $lower;

$set1 = Bit::Vector->new($limit+1);

$set1->Fill();
$set1->Bit_Off(0);
$set1->Bit_Off(1);
for ( $j = 4; $j <= $limit; $j += 2 ) { $set1->Bit_Off($j); }
for ( $i = 3; ($j = $i * $i) <= $limit; $i += 2 )
{
    for ( ; $j <= $limit; $j += $i ) { $set1->Bit_Off($j); }
}

$set1->Interval_Empty(0,768);
$set1->Interval_Fill(1,2);
$set1->Interval_Fill(4,8);
$set1->Interval_Fill(16,32);
$set1->Interval_Fill(64,128);
$set1->Interval_Fill(256,512);

$str1 = $set1->to_Hex();

$set2 = Set::IntRange->new($lower,$upper);

eval { $set2->from_Hex($str1); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str2 = $set2->to_Hex();
if ($str1 eq $str2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str3 = $set2->to_Enum();

$str4 = "-499,-498,-496..-492,-484..-468,-436..-372,-244..12,269,273,287,297,309,311,321,323,327,329,339,353,357,359,363,377,381,383,387,407,411,419,429,437,441,447,453,467,471,477,483,491,497";

if ($str3 eq $str4)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set3 = $set2->Shadow();

eval { $set3->from_Enum($str3); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($set2->equal($set3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str4 = "297,387,329,453,287,327,477,273,309,429,383,441,471,323,497,467,321,437,377,339,447,419,311,359,269,411,363,353,357,-484..-468,-436..-372,-499,491,-244..12,381,407,-496..-492,483,-498";

eval { $set3->from_Enum($str4); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($set2->equal($set3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set3->from_Enum("${lower}..${upper}"); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set2->Fill();
if ($set2->equal($set3))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str4 = ($lower+1) . '..' . ($upper-1);
eval { $set3->from_Enum($str4); };
unless ($@)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$str4 = ($lower-1) . '..' . ($upper-1);
eval { $set3->from_Enum($str4); };
if ($@ =~ /^Set::IntRange::from_Enum\(\): minimum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n$@";}
$n++;

$str4 = ($lower+1) . '..' . ($upper+1);
eval { $set3->from_Enum($str4); };
if ($@ =~ /^Set::IntRange::from_Enum\(\): maximum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n$@";}
$n++;

eval { $set3->from_Enum("${upper}..${lower}"); };
if ($@ =~ /^Set::IntRange::from_Enum\(\): minimum > maximum index/)
{print "ok $n\n";} else {print "not ok $n\n$@";}
$n++;

__END__

