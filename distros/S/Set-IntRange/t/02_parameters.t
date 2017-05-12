#!perl -w

use strict;
no strict "vars";

use Set::IntRange;

# ======================================================================
#   parameter checks
# ======================================================================

$prefix = 'Set::IntRange';

$bad_idx = "${prefix}::\\w+\\(\\): (?:minimum |maximum |start |)index out of range";

$bad_size = "${prefix}::\\w+\\(\\): set size mismatch";

$numeric  = 1 << 3;

$limit = $numeric;

$method_list{'Size'}              = 1;
$method_list{'Empty'}             = 1;
$method_list{'Fill'}              = 1;
$method_list{'Flip'}              = 1;
$method_list{'Interval_Empty'}    = 3 + $numeric;
$method_list{'Interval_Fill'}     = 3 + $numeric;
$method_list{'Interval_Flip'}     = 3 + $numeric;
$method_list{'Interval_Scan_inc'} = 2 + $numeric;
$method_list{'Interval_Scan_dec'} = 2 + $numeric;
$method_list{'Bit_Off'}           = 2 + $numeric;
$method_list{'Bit_On'}            = 2 + $numeric;
$method_list{'bit_flip'}          = 2 + $numeric;
$method_list{'bit_test'}          = 2 + $numeric;
$method_list{'contains'}          = 2 + $numeric;
$method_list{'Norm'}              = 1;
$method_list{'Min'}               = 1;
$method_list{'Max'}               = 1;
$method_list{'Union'}             = 3;
$method_list{'Intersection'}      = 3;
$method_list{'Difference'}        = 3;
$method_list{'ExclusiveOr'}       = 3;
$method_list{'Complement'}        = 2;
$method_list{'is_empty'}          = 1;
$method_list{'is_full'}           = 1;
$method_list{'equal'}             = 2;
$method_list{'subset'}            = 2;
$method_list{'Lexicompare'}       = 2;
$method_list{'Compare'}           = 2;
$method_list{'Copy'}              = 2;
$method_list{'Bit_Vector'}         = 1;

$operator_list{'+'}   = 1;
$operator_list{'|'}   = 1;
$operator_list{'-'}   = 1;
$operator_list{'*'}   = 1;
$operator_list{'&'}   = 1;
$operator_list{'^'}   = 1;
$operator_list{'=='}  = 1;
$operator_list{'!='}  = 1;
$operator_list{'<'}   = 1;
$operator_list{'<='}  = 1;
$operator_list{'>'}   = 1;
$operator_list{'>='}  = 1;
$operator_list{'cmp'} = 1;
$operator_list{'eq'}  = 1;
$operator_list{'ne'}  = 1;
$operator_list{'lt'}  = 1;
$operator_list{'le'}  = 1;
$operator_list{'gt'}  = 1;
$operator_list{'ge'}  = 1;

print "1..1227\n";

$n = 1;

$set = Set::IntRange->new(-$limit,$limit);
if (defined $set)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set) eq $prefix)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set->Bit_On(-1);
if ($set->Norm() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set0 = Set::IntRange->new(-$limit,$limit);
if (defined $set0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set0) eq $prefix)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set0->Bit_On(-1);
if ($set0->Norm() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set1 = Set::IntRange->new(-$limit+1,$limit-1);
if (defined $set1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set1) eq $prefix)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set1->Bit_On(-1);
if ($set1->Norm() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set2 = Set::IntRange->new(-$limit+2,$limit-2);
if (defined $set2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set2) eq $prefix)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set2->Bit_On(-1);
if ($set2->Norm() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set3 = Set::IntRange->new(-$limit+3,$limit-3);
if (defined $set3)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (ref($set3) eq $prefix)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set3->Bit_On(-1);
if ($set3->Norm() == 1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (! $set->contains(0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set->Bit_On(0);
if ($set->contains(0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set->Bit_Off(0);
if (! $set->contains(0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->bit_flip(0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->contains(0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $set->bit_flip(0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $set->contains(0))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (! $set->contains(1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set->Bit_On(1);
if ($set->contains(1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set->Bit_Off(1);
if (! $set->contains(1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->bit_flip(1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->contains(1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $set->bit_flip(1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $set->contains(1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (! $set->contains($limit-2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set->Bit_On($limit-2);
if ($set->contains($limit-2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set->Bit_Off($limit-2);
if (! $set->contains($limit-2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->bit_flip($limit-2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->contains($limit-2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $set->bit_flip($limit-2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $set->contains($limit-2))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

if (! $set->contains($limit-1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set->Bit_On($limit-1);
if ($set->contains($limit-1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
$set->Bit_Off($limit-1);
if (! $set->contains($limit-1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->bit_flip($limit-1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->contains($limit-1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $set->bit_flip($limit-1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (! $set->contains($limit-1))
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

foreach $method (keys %method_list)
{
    $parms = $method_list{$method};
    next unless ($parms & $numeric);
    $parms -= $numeric;
    next unless ($parms > 1);
    for ( $i = -($limit+1); $i <= $limit+1; $i++ )
    {
        undef @parameters;
        for ( $j = 0; $j < $parms - 1; $j++ )
        {
            $parameters[$j] = $i;
        }
        for ( $j = 0; $j <= 3; $j++ )
        {
            $action = "${prefix}::$method(\$set${j},\@parameters)";
            eval "$action";
            if (($i >= -($limit - $j)) && ($i <= ($limit - $j)))
            {
                unless ($@)
                {print "ok $n\n";} else {print "not ok $n\n";}
                $n++;
            }
            else
            {
                if ($@ =~ /$bad_idx/o)
                {print "ok $n\n";} else {print "not ok $n\n";}
                $n++;
            }
        }
    }
}

foreach $method (keys %method_list)
{
    $num_flag = 0;
    $parms = $method_list{$method};
    if ($parms & $numeric) { $parms -= $numeric; $num_flag = 1; }
    for ( $i = 0; $i <= $parms + 1; $i++ )
    {
        undef @parameters;
        for ( $j = 0; $j < $i - 1; $j++ )
        {
            if ($num_flag) { $parameters[$j] = $limit+1; }
            else           { $parameters[$j] = $set; }
        }
        if ($i == 0)
        {
            $action = "${prefix}::$method()";
        }
        elsif ($i == 1)
        {
            $action = "${prefix}::$method(\$set)";
        }
        else
        {
            $action = "${prefix}::$method(\$set,\@parameters)";
        }
        eval "$action";
        if ($i != $parms)
        {
            if ($@ =~ /^Usage: (?:\$\w+ = |\([\w\$,]+\) = |if \()?\$\w+->\w+(?:\([\w\$,]*\)|->)/)
            {print "ok $n\n";} else {print "not ok $n\n";}
            $n++;
        }
        else
        {
            if ($num_flag)
            {
                if ($@ =~ /$bad_idx/o)
                {print "ok $n\n";} else {print "not ok $n\n";}
                $n++;
            }
            else
            {
                unless ($@)
                {print "ok $n\n";} else {print "not ok $n\n";}
                $n++;
            }
            if ((! $num_flag) && ($parms > 1))
            {
                if ($parms == 2)
                {
                    $action = "${prefix}::$method(\$set1,\$set2)";
                    eval "$action";
                    if ($@ =~ /$bad_size/o)
                    {print "ok $n\n";} else {print "not ok $n\n";}
                    $n++;
                }
                elsif ($parms == 3)
                {
                    $action = "${prefix}::$method(\$set1,\$set1,\$set2)";
                    eval "$action";
                    if ($@ =~ /$bad_size/o)
                    {print "ok $n\n";} else {print "not ok $n\n";}
                    $n++;
                    $action = "${prefix}::$method(\$set1,\$set2,\$set1)";
                    eval "$action";
                    if ($@ =~ /$bad_size/o)
                    {print "ok $n\n";} else {print "not ok $n\n";}
                    $n++;
                    $action = "${prefix}::$method(\$set1,\$set2,\$set2)";
                    eval "$action";
                    if ($@ =~ /$bad_size/o)
                    {print "ok $n\n";} else {print "not ok $n\n";}
                    $n++;
                    $action = "${prefix}::$method(\$set1,\$set2,\$set3)";
                    eval "$action";
                    if ($@ =~ /$bad_size/o)
                    {print "ok $n\n";} else {print "not ok $n\n";}
                    $n++;
                }
                else { }
            }
        }
    }
}

foreach $operator (keys %operator_list)
{
    $obj = 0x000E9CE0;
    $fake = \$obj;
    if (ref($fake) eq 'SCALAR')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    &test_fake;

    $fake = [ ];
    if (ref($fake) eq 'ARRAY')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    &test_fake;

    $fake = { };
    if (ref($fake) eq 'HASH')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    &test_fake;

    $fake = sub { };
    if (ref($fake) eq 'CODE')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    &test_fake;

    $obj = { };
    $fake = \$obj;
    if (ref($fake) eq 'REF')
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    &test_fake;
}

exit;

sub test_fake
{
    my($message);

    if ($operator =~ /^[a-z]+$/)
        { $message = quotemeta("$prefix cmp: wrong argument type"); }
    elsif ($operator eq '|')
        { $message = quotemeta("$prefix '+': wrong argument type"); }
    elsif ($operator eq '&')
        { $message = quotemeta("$prefix '*': wrong argument type"); }
    else
        { $message = quotemeta("$prefix '$operator': wrong argument type"); }

    $action = "\$temp = \$set $operator \$fake";
    eval "$action";
    if ($@ =~ /$message/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    $action = "\$temp = \$fake $operator \$set";
    eval "$action";
    if ($@ =~ /$message/)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

