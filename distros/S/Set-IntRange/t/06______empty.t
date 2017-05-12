#!perl -w

use strict;
no strict "vars";

use Set::IntRange;

# ======================================================================
#   $set->is_empty();
#   $set->is_full();
# ======================================================================

print "1..64\n";

$n = 1;

$set = Set::IntRange->new(-2500,2500);

if ($set->is_empty())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$set->is_full())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Flip();

if (!$set->is_empty())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->is_full())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Complement($set);

if ($set->is_empty())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if (!$set->is_full())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&Empty(-2499);
&Empty(-2498);
&Empty(   -1);
&Empty(    0);
&Empty(    1);
&Empty( 2498);
&Empty( 2499);

$set->Fill();

if (!$set->is_empty())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->is_full())
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

&Full(-2499);
&Full(-2498);
&Full(   -1);
&Full(    0);
&Full(    1);
&Full( 2498);
&Full( 2499);

exit;

sub Empty
{
    my($bit) = @_;

    $set->bit_flip($bit);

    if (!$set->is_empty())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (!$set->is_full())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $set->bit_flip($bit);

    if ($set->is_empty())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (!$set->is_full())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub Full
{
    my($bit) = @_;

    $set->bit_flip($bit);

    if (!$set->is_empty())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (!$set->is_full())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $set->bit_flip($bit);

    if (!$set->is_empty())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($set->is_full())
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

