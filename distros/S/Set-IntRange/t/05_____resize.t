#!perl -w

use strict;
no strict "vars";

use Set::IntRange;

# ======================================================================
#   $set->Resize($lower,$upper);
# ======================================================================

print "1..81\n";

$n = 1;

$lower = -997;
$upper = 1049;

@ref = (0) x ($upper-$lower+1);

$ref[-987 - $lower] = 1;
$ref[-610 - $lower] = 1;
$ref[-377 - $lower] = 1;
$ref[-233 - $lower] = 1;
$ref[-144 - $lower] = 1;
$ref[-89 - $lower] = 1;
$ref[-55 - $lower] = 1;
$ref[-34 - $lower] = 1;
$ref[-21 - $lower] = 1;
$ref[-13 - $lower] = 1;
$ref[-8 - $lower] = 1;
$ref[-5 - $lower] = 1;
$ref[-3 - $lower] = 1;
$ref[-2 - $lower] = 1;
$ref[-1 - $lower] = 1;
$ref[2 - $lower] = 1;
$ref[3 - $lower] = 1;
$ref[5 - $lower] = 1;
$ref[7 - $lower] = 1;
$ref[11 - $lower] = 1;
$ref[13 - $lower] = 1;
$ref[17 - $lower] = 1;
$ref[19 - $lower] = 1;
$ref[23 - $lower] = 1;
$ref[29 - $lower] = 1;
$ref[31 - $lower] = 1;
$ref[37 - $lower] = 1;
$ref[41 - $lower] = 1;
$ref[43 - $lower] = 1;
$ref[47 - $lower] = 1;
$ref[53 - $lower] = 1;
$ref[59 - $lower] = 1;
$ref[61 - $lower] = 1;
$ref[67 - $lower] = 1;
$ref[71 - $lower] = 1;
$ref[73 - $lower] = 1;
$ref[79 - $lower] = 1;
$ref[83 - $lower] = 1;
$ref[89 - $lower] = 1;
$ref[97 - $lower] = 1;
$ref[101 - $lower] = 1;
$ref[103 - $lower] = 1;
$ref[107 - $lower] = 1;
$ref[109 - $lower] = 1;
$ref[113 - $lower] = 1;
$ref[127 - $lower] = 1;
$ref[131 - $lower] = 1;
$ref[137 - $lower] = 1;
$ref[139 - $lower] = 1;
$ref[149 - $lower] = 1;
$ref[151 - $lower] = 1;
$ref[157 - $lower] = 1;
$ref[163 - $lower] = 1;
$ref[167 - $lower] = 1;
$ref[173 - $lower] = 1;
$ref[179 - $lower] = 1;
$ref[181 - $lower] = 1;
$ref[191 - $lower] = 1;
$ref[193 - $lower] = 1;
$ref[197 - $lower] = 1;
$ref[199 - $lower] = 1;
$ref[211 - $lower] = 1;
$ref[223 - $lower] = 1;
$ref[227 - $lower] = 1;
$ref[229 - $lower] = 1;
$ref[233 - $lower] = 1;
$ref[239 - $lower] = 1;
$ref[241 - $lower] = 1;
$ref[251 - $lower] = 1;
$ref[257 - $lower] = 1;
$ref[263 - $lower] = 1;
$ref[269 - $lower] = 1;
$ref[271 - $lower] = 1;
$ref[277 - $lower] = 1;
$ref[281 - $lower] = 1;
$ref[283 - $lower] = 1;
$ref[293 - $lower] = 1;
$ref[307 - $lower] = 1;
$ref[311 - $lower] = 1;
$ref[313 - $lower] = 1;
$ref[317 - $lower] = 1;
$ref[331 - $lower] = 1;
$ref[337 - $lower] = 1;
$ref[347 - $lower] = 1;
$ref[349 - $lower] = 1;
$ref[353 - $lower] = 1;
$ref[359 - $lower] = 1;
$ref[367 - $lower] = 1;
$ref[373 - $lower] = 1;
$ref[379 - $lower] = 1;
$ref[383 - $lower] = 1;
$ref[389 - $lower] = 1;
$ref[397 - $lower] = 1;
$ref[401 - $lower] = 1;
$ref[409 - $lower] = 1;
$ref[419 - $lower] = 1;
$ref[421 - $lower] = 1;
$ref[431 - $lower] = 1;
$ref[433 - $lower] = 1;
$ref[439 - $lower] = 1;
$ref[443 - $lower] = 1;
$ref[449 - $lower] = 1;
$ref[457 - $lower] = 1;
$ref[461 - $lower] = 1;
$ref[463 - $lower] = 1;
$ref[467 - $lower] = 1;
$ref[479 - $lower] = 1;
$ref[487 - $lower] = 1;
$ref[491 - $lower] = 1;
$ref[499 - $lower] = 1;
$ref[503 - $lower] = 1;
$ref[509 - $lower] = 1;
$ref[521 - $lower] = 1;
$ref[523 - $lower] = 1;
$ref[541 - $lower] = 1;
$ref[547 - $lower] = 1;
$ref[557 - $lower] = 1;
$ref[563 - $lower] = 1;
$ref[569 - $lower] = 1;
$ref[571 - $lower] = 1;
$ref[577 - $lower] = 1;
$ref[587 - $lower] = 1;
$ref[593 - $lower] = 1;
$ref[599 - $lower] = 1;
$ref[601 - $lower] = 1;
$ref[607 - $lower] = 1;
$ref[613 - $lower] = 1;
$ref[617 - $lower] = 1;
$ref[619 - $lower] = 1;
$ref[631 - $lower] = 1;
$ref[641 - $lower] = 1;
$ref[643 - $lower] = 1;
$ref[647 - $lower] = 1;
$ref[653 - $lower] = 1;
$ref[659 - $lower] = 1;
$ref[661 - $lower] = 1;
$ref[673 - $lower] = 1;
$ref[677 - $lower] = 1;
$ref[683 - $lower] = 1;
$ref[691 - $lower] = 1;
$ref[701 - $lower] = 1;
$ref[709 - $lower] = 1;
$ref[719 - $lower] = 1;
$ref[727 - $lower] = 1;
$ref[733 - $lower] = 1;
$ref[739 - $lower] = 1;
$ref[743 - $lower] = 1;
$ref[751 - $lower] = 1;
$ref[757 - $lower] = 1;
$ref[761 - $lower] = 1;
$ref[769 - $lower] = 1;
$ref[773 - $lower] = 1;
$ref[787 - $lower] = 1;
$ref[797 - $lower] = 1;
$ref[809 - $lower] = 1;
$ref[811 - $lower] = 1;
$ref[821 - $lower] = 1;
$ref[823 - $lower] = 1;
$ref[827 - $lower] = 1;
$ref[829 - $lower] = 1;
$ref[839 - $lower] = 1;
$ref[853 - $lower] = 1;
$ref[857 - $lower] = 1;
$ref[859 - $lower] = 1;
$ref[863 - $lower] = 1;
$ref[877 - $lower] = 1;
$ref[881 - $lower] = 1;
$ref[883 - $lower] = 1;
$ref[887 - $lower] = 1;
$ref[907 - $lower] = 1;
$ref[911 - $lower] = 1;
$ref[919 - $lower] = 1;
$ref[929 - $lower] = 1;
$ref[937 - $lower] = 1;
$ref[941 - $lower] = 1;
$ref[947 - $lower] = 1;
$ref[953 - $lower] = 1;
$ref[967 - $lower] = 1;
$ref[971 - $lower] = 1;
$ref[977 - $lower] = 1;
$ref[983 - $lower] = 1;
$ref[991 - $lower] = 1;
$ref[997 - $lower] = 1;
$ref[1009 - $lower] = 1;
$ref[1013 - $lower] = 1;
$ref[1019 - $lower] = 1;
$ref[1021 - $lower] = 1;
$ref[1031 - $lower] = 1;
$ref[1033 - $lower] = 1;
$ref[1039 - $lower] = 1;
$ref[1049 - $lower] = 1;

$set = Set::IntRange->new($lower,$upper);

$set->Interval_Fill(0,$upper);

$set->Bit_Off(0);
$set->Bit_Off(1);

for ( $j = 4; $j <= $upper; $j += 2 ) { $set->Bit_Off($j); }

for ( $i = 3; ($j = $i * $i) <= $upper; $i += 2 )
{
    for ( ; $j <= $upper; $j += $i ) { $set->Bit_Off($j); }
}

@fib = ( 0, -1, 0 );

while (1)
{
    $fib[2] = $fib[1] + $fib[0];
    $fib[0] = $fib[1];
    $fib[1] = $fib[2];
    last if ($fib[2] < $lower);
    $set->Bit_On($fib[2]);
}

foreach $lower_offset (0,-97,-128,-997,97,128,997,998,1024)
{
    $lower_new = $lower + $lower_offset;
    $lower_max = max($lower,$lower_new);
    foreach $upper_offset (0,-97,-128,-1049,97,128,1049,-1050,-1536)
    {
        $upper_new = $upper + $upper_offset;
        $upper_min = min($upper,$upper_new);
        $new = $set->Clone();
        if ($set->equal($new))
        {
            eval { $new->Resize($lower_new,$upper_new); };
            if ($lower_new > $upper_new)
            {
                if ($@ =~
                    /^Set::IntRange::Resize\(\): lower > upper boundary/)
                {print "ok $n\n";} else {print "not ok $n\n";}
            }
            else { &verify; }
        }
        else {print "not ok $n\n";}
        $n++;
    }
}

exit;

sub min
{
    return( ($_[0] < $_[1]) ? $_[0] : $_[1] );
}

sub max
{
    return( ($_[0] > $_[1]) ? $_[0] : $_[1] );
}

sub verify
{
    my($ok) = 1;
    my($i);

    if ($new->Min() >= $lower_max)
    {
        if ($new->Max() <= $upper_min)
        {
            for ( $i = $lower_max; $ok && $i <= $upper_min; $i++ )
            {
                $ok = ($ref[$i-$lower] == $new->bit_test($i));
            }
            if ($ok)
            {print "ok $n\n";} else {print "not ok $n\n";}
        }
        else {print "not ok $n\n";}
    }
    else {print "not ok $n\n";}
}

__END__

