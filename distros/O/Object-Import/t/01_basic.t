use warnings; no warnings qw"uninitialized reserved prototype"; use strict;
use Test::More tests => 34;

BEGIN { 
$::W1 = $::W2 = $::W3 = 0; 
$SIG{__WARN__} = sub { 
	my($t) = @_;
	if ($t =~ m"\ASubroutine G1::greet redefined at .*\bObject/Import\.pm ") {
		$::W1++;
	} elsif ($t =~ /\Awarning: Object::Import cannot find methods of /) {
		$::W2++;
	} elsif ($t =~ m"\ASubroutine .* redefined at .*\bObject/Import\.pm ") {
		$::W3++;
	} else {
		warn $t;
	}
};
}

is($::W1, 0, "no warn redefined 0");
is($::W2, 0, "no warn nometh 0");
is($::W3, 0, "no warn redefined other 0");
$::W1 = $::W2 = $::W3 = 0; 

{
package X;
sub greet {
	my($o, $i) = @_;
	(ref($o) ? $$o[0] : $o) . ", " . $i;
}
}


{
package Hi;
BEGIN { @Hi::ISA = X::; }
}

{
package G0;
use Test::More;

ok(defined(\&greet), "G0 def&greet");
is(greet("world"), "hello, world", "G0 &greet");

use Object::Import bless(["hello"], X::), list => ["greet"];

is($::W1, 0, "no warn redefined G0");
is($::W2, 0, "no warn nometh G0");
is($::W3, 0, "no warn redefined other G0");
$::W1 = $::W2 = $::W3 = 0; 
}

{
package G1;
use Test::More;

ok(!exists(&greet), "G1 !exi&greet");
my $v = eval q'no strict; greet';
is($@, "", "G1 greet bare err");
is($v, "greet", "G1 greet bare");
ok(defined(&thank), "G1 def&thank");

import Object::Import bless(["hey"], X::), list => ["greet"];

ok(defined(&greet), "G1.1 def&greet");
is(greet("world"), "hey, world", "G1.1 &greet");
$v = eval q'no strict; greet';
is($@, "", "G1.1 greet err");
is($v, "hey, ", "G1.1 greet");
$v = eval q'no strict; greet world';
is($@, "", "G1.1 greet w err");
is($v, "hey, world", "G1.1 greet w");
is($::W1, 0, "no warn redefined G1.1");
is($::W2, 0, "no warn nometh G1.1");
is($::W3, 0, "no warn redefined other G1.1");
$::W1 = $::W2 = $::W3 = 0; 

import Object::Import Hi::, list => ["greet"], nowarn_redefine => 1; 

ok(defined(&greet), "G1.2 def&greet");
is(greet("perl"), "Hi, perl", "G1.2 &greet");
is($::W1, 0, "no warn redefined G1.2");
is($::W2, 0, "no warn nometh G1.2");
is($::W3, 0, "no warn redefined other G1.2");
$::W1 = $::W2 = $::W3 = 0; 

import Object::Import bless(["welcome"], Hi::), list => ["greet"]; 

ok(defined(&greet), "G1.3 def&greet");
is(greet("perl"), "welcome, perl", "G1.3 &greet");
is($::W1, 1, "warn redefined G1.3");
is($::W2, 0, "no warn nometh G1.3");
is($::W3, 0, "no warn redefined other G1.3");
$::W1 = $::W2 = $::W3 = 0; 

use Object::Import bless(["hullo"], X::), list => ["thank"];
}

is($::W1, 0, "no warn redefined \$");
is($::W2, 0, "no warn nometh \$");
is($::W3, 0, "no warn redefined other \$");

__END__
