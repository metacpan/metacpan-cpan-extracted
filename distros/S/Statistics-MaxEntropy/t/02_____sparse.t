#!/usr/bin/perl

print "1..7\n";
$i = 1;

use Statistics::SparseVector;


$vec = Statistics::SparseVector->new(10);
$vec->Bit_On(2);
if ($vec->to_Bin() eq "0000000100") {
    print "ok $i\n";
}
else {
    print "not ok $i\n";
}
$i++;

if ($vec->to_Enum() eq "2") {
    print "ok $i\n";
}
else {
    print "not ok $i\n";
}
$i++;

$othervec = Statistics::SparseVector->new(2);
$othervec->Bit_On(1);
if ($othervec->to_Enum() eq "1") {
    print "ok $i\n";
}
else {
    print "not ok $i\n";
}
$i++;

$vec->Interval_Substitute($othervec, $vec->Size(), 0, 1, 1);
if ($vec->to_Bin() eq  "10000000100") {
    print "ok $i\n";
}
else {
    print "not ok $i\n";
}
$i++;

$vec->Interval_Substitute($othervec, $vec->Size(), 0, 0, 1);
if ($vec->to_Bin() eq  "010000000100") {
    print "ok $i\n";
}
else {
    print "not ok $i\n";
}
$i++;

$othervec->Interval_Substitute($vec, 1, 0, 0, $vec->Size);
if ($othervec->to_Bin() eq  "10100000001000") {
    print "ok $i\n";
}
else {
    print "not ok $i\n";
}
$i++;

# remove the last bit of $vec
$othervec->Interval_Substitute("", $othervec->Size()-1, 1, 0, 0);
if ($othervec->to_Bin() eq  "0100000001000") {
    print "ok $i\n"; 
}
else {
    print "not ok $i\n";
}
$i++;


__END__
