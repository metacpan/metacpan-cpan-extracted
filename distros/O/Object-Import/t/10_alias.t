use warnings; use strict;
use Test::More tests => 55;

# test that the module keeps the reference to the object correctly

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

sub bself {
	\$_[0];
}

$::DC = 0;
DESTROY {
	$::DC++;
}

}

{
package G;

use Test::More;
use Scalar::Util "reftype";

my $o0 = bless [], X::;
import Object::Import $o0, "prefix", "o0_";
my $o0b = o0_bself();
is(reftype($o0b), "REF", "o0 ref bself");
isnt(\$o0, $o0b, "o0 id bself");
is(reftype($$o0b), "ARRAY", "o0 ref self");
is($$o0b, $o0, "o0 id self");

my $o1 = bless [], X::;
import Object::Import \$o1, "deref", 1, "prefix", "o1_";
my $o1b = o1_bself();
is(reftype($o1b), "REF", "o1 ref bself");
is(\$o1, $o1b, "o1 id bself");
is(reftype($$o1b), "ARRAY", "o1 ref self");
is($$o1b, $o1, "o1 id self");
is($::DC, 0, "dcb 0");
$o1 = bless {}, X::;
is($::DC, 1, "dc 1");
is(reftype(o1_bself()), "REF", "o1 ref new bself");
is(o1_bself(), $o1b, "o1 id new bself");
is(reftype($$o1b), "HASH", "o1 ref new self");
is($$o1b, $o1, "o1 id new self");

my $k0;
eval { 
	${o0_bself()} = bless \$k0, X::; 
};
my $err0 = $@;
is($@, "", "o0 sneaky eval");
is(reftype(o0_bself()), "REF", "o0 ref sneaky bself");
is(o0_bself(), $o0b, "o0 id sneaky bself");
is(reftype($$o0b), "SCALAR", "o0 ref sneaky self");
isnt($$o0b, $o0, "o0 id sneaky self not");
is($$o0b, \$k0, "o0 id sneaky self");
is(reftype($o0), "ARRAY", "o0 ref sneaky var");
is($::DC, 1, "dcb 1");
$o0 = ();
is($::DC, 2, "dc 2");
is(${o0_bself()}, \$k0, "o0 id still sneaky self");

is($::DC, 2, "dcb 2");
my $k1;
eval { 
	${o1_bself()} = bless \$k1, X::; 
};
my $err1 = $@;
is($::DC, 3, "dc 3");
is($@, "", "o1 sneaky eval");
is(reftype(o1_bself()), "REF", "o1 ref sneaky bself");
is(o1_bself(), $o1b, "o1 id sneaky bself");
is(reftype($$o1b), "SCALAR", "o1 ref sneaky self");
is($$o1b, $o1, "o1 id sneaky self same");
is($$o1b, \$k1, "o1 id sneaky self");
is(reftype($o1), "SCALAR", "o1 ref sneaky var");
is($o1, \$k1, "o1 id sneaky var");
}

{
package G;

no warnings qw"redefine prototype";

is($::DC, 3, "dcb 3");
*o0_bself = sub { -1 };
is($::DC, 4, "dc 4 del sub");
*o1_bself = sub { -1 };
is($::DC, 5, "dc 5 del sub");
}

{
package G1;

use Test::More;
use Scalar::Util "reftype";

my $c0 = X::;
import Object::Import $c0, "prefix", "c0_";
my $c0b = c0_bself();
is(reftype($c0b), "SCALAR", "c0 ref bself");
isnt(\$c0, $c0b, "c0 id bself");
is(reftype($$c0b), undef, "c0 ref self");
is($$c0b, $c0, "c0 val self");

my $c1 = X::;
import Object::Import \$c1, "deref", 1, "prefix", "c1_";
my $c1b = c1_bself();
is(reftype($c1b), "SCALAR", "c1 ref bself");
is(\$c1, $c1b, "c1 id bself");
is(reftype($$c1b), undef, "c1 ref self");
is($$c1b, $c1, "c1 val self");

my @k0;
eval { 
	${c0_bself()} = bless \@k0, X::; 
};
my $err0 = $@;
is($@, "", "c0 sneaky eval");
is(reftype(c0_bself()), "REF", "c0 ref sneaky bself");
is(c0_bself(), $c0b, "c0 id sneaky bself");
is(reftype($$c0b), "ARRAY", "c0 ref sneaky self");
isnt($$c0b, $c0, "c0 id sneaky self not");
is($$c0b, \@k0, "c0 id sneaky self");
is(reftype($c0), undef, "o0 ref sneaky var");
is($c0, X::, "o0 val sneaky var");
}

is($::DC, 5, "dcf very end 5");

is($::W4, 0, "no warn");

__END__
