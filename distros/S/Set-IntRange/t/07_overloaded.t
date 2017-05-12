#!perl -w

use strict;
no strict "vars";

use Set::IntRange;

# ======================================================================
#   test overloaded operations
# ======================================================================

print "1..174\n";

$n = 1;

$set = Set::IntRange->new(-499,499);
if (abs($set) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() > 499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < -499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set += 0;
if (abs($set) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless (! $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set ^= -199;
if (abs($set) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set += 401;
if (abs($set) == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 401)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set ^= 0;
if (abs($set) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 401)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $set;
if ($ref == $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $set->new(-499,499);
if (! $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref->Copy($set);
if ($ref == $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $set + 11;
if (abs($ref) == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == 401)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->contains(11))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($ref == $set))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref != $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set < $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set <= $ref)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref > $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref >= $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $set + -499;
if (abs($ref) == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == -499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == 401)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $ref - 401;
if (abs($ref) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == -499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref = $ref - -499;
if (abs($ref) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref -= 199;
if (abs($ref) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref -= 0;
if (abs($ref) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() == -199)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$ref -= -199;
if (abs($ref) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Min() > 499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($ref->Max() < -499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$limit = 1000; # some tests below assume this limit to be even!

$primes = Set::IntRange->new(2,$limit);
if (! $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$primes->Fill();
if ($primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (abs($primes) == ($limit-1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes->Min() == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes->Max() == $limit)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

for ( $j = 4; $j <= $limit; $j += 2 ) { $primes -= $j; }

for ( $i = 3; ($j = $i * $i) <= $limit; $i += 2 )
{
    for ( ; $j <= $limit; $j += $i ) { $primes -= $j; }
}

if (abs($primes) == 168)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes->Min() == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes->Max() == 997)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$odd = $primes->new(2,$limit);
if (! $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

for ( $i = 3; $i <= $limit; $i += 2 ) { $odd += $i; }

if ($odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (abs($odd) == ($limit-2)/2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd->Min() == 3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd->Max() == 999)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($odd == $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd != $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes < $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes <= $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes > $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes >= $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes - $odd;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (2 == $temp)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$odd = $odd + 2;
if (abs($odd) == ($limit/2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd->Min() == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd->Max() == 999)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($odd == $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd != $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes < $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes <= $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes > $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes >= $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd > $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($odd >= $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($odd < $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($odd <= $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes * $odd;
if ($temp == $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes + $odd;
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes ^ $odd;

$xor = $primes->new(2,$limit);
if (! $xor)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$xor->ExclusiveOr($primes,$odd);
if ($xor)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($temp == $xor)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($temp->equal($xor))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (23 < $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (23 <= $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!(23 > $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!(23 >= $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($primes > 23)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($primes >= 23)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes < 23))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!($primes <= 23))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = ($primes + $odd) - ($primes * $odd);

if ($temp == $xor)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($temp->equal($xor))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$even = $xor;
$even->Empty();
for ( $i = 2; $i <= $limit; $i += 2 ) { $even += $i; }

if (($primes * $even) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($odd * $even) == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$full = $temp;
$full->Fill();
if (($odd + $even) == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($primes + $even) == -($odd - $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($primes + $even) == ~($odd - $primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($primes + $even) == -($odd * ~$primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($primes + $even) == ~($odd * -$primes))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set = Set::IntRange->new(-499,499);
if (abs($set) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() > 499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < -499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set++;
if (abs($set) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set--;
if (abs($set) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() > 499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < -499)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
unless ($set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($primes cmp $odd) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($odd cmp $primes) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($odd + $even) cmp $full) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((($odd * $even) cmp 2) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ((2 cmp ($odd * $even)) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($odd ^= 2) == ($full - $even))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

# systematic tests:

$temp = $odd + $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp += $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $odd + 2;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
$temp += 4;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $odd | $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp |= $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $odd | 2;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
$temp |= 4;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $full - $even;
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$empty = $temp->new(2,$limit);

$temp -= $odd;
if ($temp == $empty)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $even - 2;
if (abs($temp) == abs($even) - 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($even);
if ($temp == $even)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp -= 8;
if (abs($temp) == abs($even) - 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes * $even;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($primes);
if ($temp == $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp *= $even;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes * 2;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($primes);
$temp *= 2;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes & $even;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($primes);
if ($temp == $primes)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp &= $even;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $primes & 2;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($primes);
$temp &= 2;
if ($temp == 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $odd ^ $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp ^= $even;
if ($temp == $full)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp = $odd ^ 2;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp->Copy($odd);
$temp ^= 4;
if (abs($temp) == abs($odd) + 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($odd cmp $even) == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($even cmp $odd) == -1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$temp ^= 4;
if ($temp == $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($temp cmp $odd) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (($odd cmp $temp) == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($odd eq $temp)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($odd ne $temp))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($primes eq $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($primes ne $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($odd gt $even)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($odd ge $even)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($even gt $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($even ge $odd))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($odd lt $even))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (!($odd le $even))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($even lt $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if ($even le $odd)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

__END__

