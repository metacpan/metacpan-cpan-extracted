use warnings; no warnings qw"prototype"; use strict;
use Test::More tests => 39;

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

use Object::Import ();

is($::W4, 0, "no warn 0");

{
package X0;
sub greet {
	my($o, $i) = @_;
	(ref($o) ? $$o[0] : $o) . ", " . $i;
}
}

{
package G0;
use Test::More;

import Object::Import bless(["hello"], X0::);

ok(defined(\&greet), "G0 def&greet");
is(greet("world"), "hello, world", "G0 &greet");

import Object::Import bless(["hai"], X0::); # shall not redefine greet

is(greet("world"), "hello, world", "G0.1 &greet");

import Object::Import bless(["welcome"], X0::), list => ["greet"], nowarn_redefine => 1; 

is(greet("world"), "welcome, world", "G0.2 &greet");
}

is($::W4, 0, "no warn G0");

{
package X1;

sub greet { "hello " . ${$_[0]}[0] }
sub cos { "dust " . ${$_[0]}[0] }
sub getprotobynumb { "tcp " . ${$_[0]}[0] }
sub _frobnicate { die }
DESTROY { }

}

{
package X1B;
BEGIN { @X1B::ISA = X1::; }
}

{
package G1;
use Test::More;

ok(defined(&{$_}), "G1 def\&$_") for qw"greet cos getprotobynumb greeter coser getprotobynumber _frobnicate";
is(greet(), "hello bunny", "G1 &greet");
is(greeter(), "hello package", "G1 &greeter");
is(cos(0), 1, "G1 COREcos");
is(getprotobynumber(1), "icmp", "G1 COREgetprotobynumber");

use Object::Import bless(["bunny"], X1B::), list => [qw"greet cos getprotobynumb _frobnicate"];

is(cos(0), "dust bunny", "G1.1 &cos");
is(getprotobynumber(1), "icmp", "G1.1 COREgetprotobynumber");

use Object::Import bless(["package"], X1B::), list => [qw"greet cos getprotobynumb"], suffix => "er";

is(cos(0), "dust bunny", "G1.2 &cos");
is(getprotobynumber(1), "tcp package", "G1.2 &getprotobynumber");

}

{
package G2;
use Test::More;

our %nm2;
use Object::Import bless(["bunny"], X1B::);
use Object::Import bless(["package"], X1B::), suffix => "er", savenames => \%nm2, debug => 0;
use Object::Import bless(["package"], X1B::), prefix => "mal";
use Object::Import bless(["package"], X1B::), prefix => "bis", underscore => 1;

ok(defined(&{$_}), "G2 def\&$_") for qw"greet getprotobynumb greeter coser bis_frobnicate";
ok(!exists(&{$_}), "G2 !exi\&$_") for qw"cos getprotobynumber DESTROY DESTROYer _frobnicate _frobnicateer mal_frobnicate";
is_deeply(\%nm2, {greeter => 1, coser => 1}, "G2 savenames");

is(greet(), "hello bunny", "G2 &greet");
is(greeter(), "hello package", "G2 &greeter");
is(cos(0), 1, "G2 COREcos");
is(getprotobynumber(1), "icmp", "G2 COREgetprotobynumber");
}

is($::W4, 0, "no warn");

__END__
