#!perl 

use Test::More tests => 19;
use strict;

BEGIN {
	use_ok( 'Object::Boolean' );
}

use Object::Boolean;

my $a = Object::Boolean->new('false');
my $b = Object::Boolean->new('true');

ok($b, 'true is true');
ok("$a" eq "false", "Stringify false");
ok("$b" eq "true", "Stringify true");
ok($b ? 1 : 0, "Test ?: operator");

if ($b and !$a) {
    ok(1,"Boolean expression");
} else {
    ok(0,"Boolean expression");
}

my $true = 0;
$true = 1 if not $a;
ok($true,"not");

my $c = Object::Boolean->new("true");
ok($c==$b ? 1 : 0, "comparison ==");
ok($c!=$a ? 1 : 0, "comparison !=");
ok($c ne $a ? 1 : 0, "comparison ne");
ok(($a xor $b) ? 1 : 0, "xor okay");
ok(($c xor $b) ? 0 : 1, "xor okay");
ok ($b.", sir" eq 'true, sir', "stringify");
ok ($a eq $a ? 1 : 0, "a variable is equal to itself");

my $d = Object::Boolean->new(0);
ok ($d eq $d ? 1 : 0, "ditto");
ok ($d == $a, "numeric equality between two Boolean's");
ok ($d eq $a ? 1 : 0, "string equality between two Boolean's");
ok ($a eq 'false' ? 1 : 0, "string equality between a Boolean and a string");
ok ($a eq 'something' ? 0 : 1, "string inequality between a Boolean and a string");


