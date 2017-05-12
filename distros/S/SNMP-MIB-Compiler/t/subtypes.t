# -*- mode: Perl -*-

BEGIN { unshift @INC, "lib" }
use strict;
use FileHandle;
use SNMP::MIB::Compiler;
use Data::Compare;

local $^W = 1;

print "1..9\n";
my $t = 1;

my $mib = new SNMP::MIB::Compiler();
$mib->{'filename'} = '<DATA>';
$mib->{'debug_lexer'} = 0;

# create a stream to the pseudo MIB file
my $s = Stream->new(*DATA);
$mib->{'stream'} = $s;

my ($res, $good);

# Test 1 : (3)
$res = $mib->parse_subtype();
$good = 3;
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# Test 2 : (1..3)
$res = $mib->parse_subtype();
$good = { 'range' => { 'min' => 1, 'max' => 3 } };
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# Test 3 : (1|3)
$res = $mib->parse_subtype();
$good = { 'choice' => [ 1, 3 ] };
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# Test 4 : (1|3|5)
$res = $mib->parse_subtype();
$good = { 'choice' => [ 1, 3, 5 ] };
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# Test 5 : (1..3|5)
$res = $mib->parse_subtype();
$good = { 'choice' => [ { 'range' => { 'min' => 1, 'max' => 3 } }, 5 ] };
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# Test 6 : (1|3..5)
$res = $mib->parse_subtype();
$good = { 'choice' => [ 1, { 'range' => { 'min' => 3, 'max' => 5 } } ] };
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# Test 7 : (1..3|5..7)
$res = $mib->parse_subtype();
$good = { 'choice' => [ { 'range' => { 'min' => 1, 'max' => 3 } },
			{ 'range' => { 'min' => 5, 'max' => 7 } } ] };
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# Test 8 : (1|3..5|7)
$res = $mib->parse_subtype();
$good = { 'choice' => [ 1, { 'range' => { 'min' => 3, 'max' => 5 } }, 7 ] };
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# Test 9 : (SIZE (1 | 4..85))
$res = $mib->parse_subtype();
$good = { 'size' => { 'choice' =>
		      [ 1, { 'range' => { 'min' => 4, 'max' => 85 } } ] } };
print Compare($res, $good) ? "" : "not ", "ok ", $t++, "\n";

# end

__DATA__

-- tests for subtypes

(3)

(1..3)

(1 | 3)

(1 | 3 | 5)

(1..3 | 5)

(1 | 3..5)

(1..3 | 5..7)

(1 | 3..5 | 7)

(SIZE (1 | 4..85))
