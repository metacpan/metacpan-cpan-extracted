#!perl -w

use strict;
no strict "vars";

use Set::IntRange;

# ======================================================================
#   $set->Interval_Empty($lower,$upper);
#   $set->Interval_Fill($lower,$upper);
#   $set->Interval_Flip($lower,$upper);
#   ($min,$max) = $set->Interval_Scan_inc($start);
#   ($min,$max) = $set->Interval_Scan_dec($start);
# ======================================================================

print "1..532\n";

$lim = 16384;

$set = new Set::IntRange(-$lim,$lim-1);

$n = 1;
if ($set->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() > $lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < -$lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Fill();

if ($set->Norm() == $lim * 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == -$lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == $lim-1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Empty();

if ($set->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() > $lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < -$lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Complement($set);

if ($set->Norm() == $lim * 2)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() == -$lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() == $lim-1)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

$set->Complement($set);

if ($set->Norm() == 0)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Min() > $lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;
if ($set->Max() < -$lim)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

for ( $i = 0; $i < 32; $i++ )
{
    test_set_clr(-$i,$i);      test_flip(-$i,$i);
}

test_set_clr(-63,63);          test_flip(-63,63);
test_set_clr(-127,127);        test_flip(-127,127);
test_set_clr(-255,255);        test_flip(-255,255);

test_set_clr(-$lim,$lim-1);    test_flip(-$lim,$lim-1);

eval { $set->Interval_Empty(-$lim-1,$lim-1); };
if ($@ =~ /Set::IntRange::Interval_Empty\(\): minimum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Fill(-$lim-1,$lim-1); };
if ($@ =~ /Set::IntRange::Interval_Fill\(\): minimum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Flip(-$lim-1,$lim-1); };
if ($@ =~ /Set::IntRange::Interval_Flip\(\): minimum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Empty(-$lim,$lim); };
if ($@ =~ /Set::IntRange::Interval_Empty\(\): maximum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Fill(-$lim,$lim); };
if ($@ =~ /Set::IntRange::Interval_Fill\(\): maximum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Flip(-$lim,$lim); };
if ($@ =~ /Set::IntRange::Interval_Flip\(\): maximum index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Empty(1,-1); };
if ($@ =~ /Set::IntRange::Interval_Empty\(\): minimum > maximum index/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Fill(1,-1); };
if ($@ =~ /Set::IntRange::Interval_Fill\(\): minimum > maximum index/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { $set->Interval_Flip(1,-1); };
if ($@ =~ /Set::IntRange::Interval_Flip\(\): minimum > maximum index/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($min,$max) = $set->Interval_Scan_inc(-$lim-1); };
if ($@ =~ /Set::IntRange::Interval_Scan_inc\(\): start index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($min,$max) = $set->Interval_Scan_dec(-$lim-1); };
if ($@ =~ /Set::IntRange::Interval_Scan_dec\(\): start index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($min,$max) = $set->Interval_Scan_inc($lim); };
if ($@ =~ /Set::IntRange::Interval_Scan_inc\(\): start index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

eval { ($min,$max) = $set->Interval_Scan_dec($lim); };
if ($@ =~ /Set::IntRange::Interval_Scan_dec\(\): start index out of range/)
{print "ok $n\n";} else {print "not ok $n\n";}
$n++;

exit;

sub test_set_clr
{
    my($lower,$upper) = @_;
    my($span) = $upper - $lower + 1;

    $set->Interval_Fill($lower,$upper);
    if ($set->Norm() == $span)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (($min,$max) = $set->Interval_Scan_inc(-$lim))
    {print "ok $n\n";} else {print "not ok $n\n";
      $min = $set->Min(); $max = $set->Max(); }
    $n++;
    if ($min == $lower)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($max == $upper)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $set->Interval_Empty($lower,$upper);
    if ($set->Norm() == 0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($set->Min() > $lim)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($set->Max() < -$lim)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

sub test_flip
{
    my($lower,$upper) = @_;
    my($span) = $upper - $lower + 1;

    $set->Interval_Flip($lower,$upper);
    if ($set->Norm() == $span)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if (($min,$max) = $set->Interval_Scan_dec($lim-1))
    {print "ok $n\n";} else {print "not ok $n\n";
      $min = $set->Min(); $max = $set->Max(); }
    $n++;
    if ($min == $lower)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($max == $upper)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;

    $set->Interval_Flip($lower,$upper);
    if ($set->Norm() == 0)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($set->Min() > $lim)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
    if ($set->Max() < -$lim)
    {print "ok $n\n";} else {print "not ok $n\n";}
    $n++;
}

__END__

