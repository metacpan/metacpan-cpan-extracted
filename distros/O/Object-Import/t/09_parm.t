use warnings; use strict;
use Test::More tests => 12;

# some basic tests on whether arguments and returns are passed correctly

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

{
package X;
sub con {
	if (!defined(wantarray)) {
		$_[1] = "void";
	} elsif (wantarray) {
		return "two", "elements";
	} else {
		return "grich";
	}
}
sub cnt {
	0 + @_;
}
sub bsl {
	\$_[1];
}
}

{
package G;

use Test::More;

import Object::Import X::;

is("" . con((my $c_s = "scalar")), "grich", "scalar con");
is($c_s, "scalar", "scalar con arg");
is(join(":", con((my $c_l = "list"))), "two:elements", "list con");
is($c_l, "list", "list con arg");
con((my $c_v = "unknown"));
is($c_v, "void", "void con arg");

is(cnt(), 1, "cnt 1");
is(cnt(4, 9), 3, "cnt 3");
is(cnt("boo", "zrk", undef, undef), 5, "cnt 5");
is(cnt([]), 2, "cnt 2");

my $t;
is(ref(bsl($t)), "SCALAR", "bsl");
is(bsl($t), \$t, "bsl");
}

is($::W4, 0, "no warn");

__END__
