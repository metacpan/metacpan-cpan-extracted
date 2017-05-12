use warnings; use strict;
use Test::More tests => 33;

BEGIN { 
$::W4 = 0;
$SIG{__WARN__} = sub { 
	my($t) = @_;
	if ($t =~ m"\Awarning: Object::Import cannot find methods of " ||
		$t =~ m"\ASubroutine .* redefined at .*\bObject/Import\.pm ") 
	{
		$::W4++;
	}
	warn $t;
};
}

is($::W4, 0, "no warn 0");

BEGIN { 
require_ok("Math::BigInt"); 
}

{
my $bi = Math::BigInt->new("90");
use_ok("Object::Import", \$bi, deref => 1, prefix => "bi_");
is(bi_bmul(2), "180");
$bi = Math::BigInt->new("100");
is(bi_as_hex(), "0x64");
}

{
package X0;
BEGIN { $::C0 = 0; }
sub new { $::C0++; bless {}, $_[0] }
sub greet { "hello" }
DESTROY { $::C0--; }
}

{
package G0;
use Test::More;

use_ok("Object::Import", \my $ex, deref => 1, list => ["greet"]);
is($::C0, 0, "G0.0 C");
eval { greet() }; like($@, qr/\ACan't call method "greet" on an undefined value/, "G0.0 &greet dies");
$ex = X0->new;
is($::C0, 1, "G0.1 C");
is(greet(), "hello", "G0.1 &greet");
$ex = undef;
is($::C0, 0, "G0.2 C");
eval { greet() }; like($@, qr/\ACan't call method "greet" on an undefined value/, "G0.2 &greet dies");
}

{
package X1;
BEGIN { $::C1 = 0; }
sub new { $::C1++; bless {}, $_[0] }
sub greet { "hello" }
DESTROY { $::C1--; }
}

{
package G1;
use Test::More;

my $ex;
BEGIN { use_ok("Object::Import", \($ex = X1->new), deref => 1, list => ["greet"]); }
is($::C1, 1, "G1.1 C");
is(greet(), "hello", "G1.1 &greet");
$ex = undef;
is($::C1, 0, "G1.2 C");
eval { greet() }; like($@, qr/\ACan't call method "greet" on an undefined value/, "G1.2 &greet dies");
}

{
package X2;
sub greet { ${$_[0]}[0] }
}

{
package G2;
use Test::More;

our $ex = X1->new;
use_ok("Object::Import", \$ex, deref => 1, prefix => "hr");
use_ok("Object::Import", "G2::ex", deref => 1, prefix => "gr");
use_ok("Object::Import", *ex, deref => 1, prefix => "sr");
for (qw"hrgreet grgreet srgreet") {
	no strict "refs";
	ok(defined(&$_), "G2 def\&$_");
	is(&$_(), "hello", "&hrgreet");
}
$ex = bless ["bye"], X2::;
for (qw"hrgreet grgreet srgreet") {
	no strict "refs";
	ok(defined(&$_), "G2 def\&$_");
	is(&$_(), "bye", "&hrgreet");
}
}

is($::W4, 0, "no warn");

__END__
