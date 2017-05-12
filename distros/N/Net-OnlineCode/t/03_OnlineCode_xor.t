# -*- Perl -*-

use Test::More tests => 15;

BEGIN { use_ok('Net::OnlineCode', ':xor') }

# See the ctest/ directory for C-based testing of fast xor routine

# strings are assumed to be ASCII (note in particular that lower-case
# xor space -> UPPER-CASE
my $str1 = "abcdefg";
my $str2 = "       ";
my $str3 = "ABCDEFG";
my $str4 = "\0" x 7;

# save strings (xor can change them)
my @stash = ($str1, $str2, $str3, $str4);

ok(safe_xor_strings(\$str1) eq $stash[0], "safe xor: no xors");
ok(fast_xor_strings(\$str1) eq $stash[0], "fast xor: no xors");

# my fast_xor_strings routine had an issue with mortality, causing the
# passed reference to be freed after return. Tests like the one below
# are designed to check that the code doesn't still have that bug
ok($str1 eq $stash[0], "fast xor: refcount problem (\$\$dest deallocated)");

# reset values after each set of tests
($str1, $str2, $str3, $str4) = @stash;

ok(safe_xor_strings(\$str1,$str1) eq $str4, "safe xor: self xor => nulls");

($str1, $str2, $str3, $str4) = @stash;

ok(fast_xor_strings(\$str1,$str1) eq $str4, "fast xor: self xor => nulls");
ok($str1 eq $str4, "fast xor: refcount problem (\$\$dest deallocated)");

($str1, $str2, $str3, $str4) = @stash;

ok(safe_xor_strings(\$str1,$str2) eq $str3, "safe xor: lower => upper");

($str1, $str2, $str3, $str4) = @stash;

ok(fast_xor_strings(\$str1,$str2) eq $str3, "fast xor: lower => upper");
ok($str1 eq $str3, "fast xor: refcount problem (\$\$dest deallocated)");

($str1, $str2, $str3, $str4) = @stash;

ok(safe_xor_strings(\$str1,$str2,$str3) eq $str4, "safe xor: 3-way => nulls");

($str1, $str2, $str3, $str4) = @stash;

ok(fast_xor_strings(\$str1,$str2,$str3) eq $str4, "fast xor: 3-way => nulls");
ok($str1 eq $str4, "fast xor: refcount problem (\$\$dest deallocated)");
ok($str2 eq $stash[1], "fast xor: shouldn't change source strings");
ok($str3 eq $stash[2], "fast xor: shouldn't change source strings");
