# Thanks to Michael Wright for this test and for
# finding the bug that it exposed.

use String::RexxParse qw(parse);
$input="this , is , a line of , string input";

use vars qw($var1 $var2 $var3 $var4 $var5);

print "1..10\n";
parse $input, q! $var1 . ',' $var2 . ',' $var3 . ',' $var4 .  ',' $var5!;
print $var1 eq 'this' ? "ok\n" : "not ok\n";
print $var2 eq 'is' ? "ok\n" : "not ok\n";
print $var3 eq 'a' ? "ok\n" : "not ok\n";
print $var4 eq 'string' ? "ok\n" : "not ok\n";
print $var5 eq '' ? "ok\n" : "not ok\n";
parse $input, q! $var1 ',' $var2 ',' $var3 ',' $var4 ',' $var5!;
print $var1 eq 'this ' ? "ok\n" : "not ok\n";
print $var2 eq ' is ' ? "ok\n" : "not ok\n";
print $var3 eq ' a line of ' ? "ok\n" : "not ok\n";
print $var4 eq ' string input' ? "ok\n" : "not ok\n";
print $var5 eq '' ? "ok\n" : "not ok\n";

