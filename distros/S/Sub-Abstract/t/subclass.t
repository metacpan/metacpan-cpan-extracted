use strict;
use warnings;
use Test::Most;
use Sub::Abstract;

# Subclass scenarios: single-level, multi-level, SUPER::, overriding abstract with abstract.

local $ENV{HARNESS_ACTIVE}   = 0;
local $Sub::Abstract::BYPASS = 0;

{
	package Base;
	use Sub::Abstract;
	sub new    { bless {}, shift }
	sub render :Abstract { }
}

{
	package Mid;
	our @ISA = ('Base');
	sub new { bless {}, shift }
	# Mid does NOT implement render -- still abstract
}

{
	package Leaf;
	our @ISA = ('Mid');
	sub new    { bless {}, shift }
	sub render { 'leaf render' }
}

{
	package LeafEmpty;
	our @ISA = ('Mid');
	sub new { bless {}, shift }
	# LeafEmpty does NOT implement render
}

# Two-hop subclass that implements: ok
lives_and { is(Leaf->new->render, 'leaf render') }
	'two-hop subclass implementing method: wrapper never fires';

# Mid does not implement it: invocant is Mid
throws_ok { Mid->new->render }
	qr/\Qrender() is an abstract method of Base and must be implemented by Mid\E/,
	'intermediate subclass omitting method: invocant is Mid';

# LeafEmpty does not implement it: invocant is LeafEmpty
throws_ok { LeafEmpty->new->render }
	qr/\Qrender() is an abstract method of Base and must be implemented by LeafEmpty\E/,
	'leaf subclass omitting method: invocant is LeafEmpty';

# ---- Abstract method overridden by ANOTHER abstract in a subclass ----
# Mid2 re-declares render as abstract (via declarative form); Impl implements it.
{
	package Base2;
	use Sub::Abstract qw(render);
	sub new { bless {}, shift }
}

{
	package Mid2;
	our @ISA = ('Base2');
	use Sub::Abstract qw(render);   # re-abstract in the subclass
	sub new { bless {}, shift }
}

{
	package Impl;
	our @ISA = ('Mid2');
	sub new    { bless {}, shift }
	sub render { 'impl' }
}

lives_and { is(Impl->new->render, 'impl') }
	'concrete implementation satisfies re-abstracted method in subclass';

throws_ok { Mid2->new->render }
	qr/abstract method/,
	'calling re-abstracted method on the intermediate class croaks';

# ---- Package name prefix collision -- not a subclass ----
{
	package BaseXtra;
	sub new   { bless {}, shift }
	sub probe { Base->new->render }
}

throws_ok { BaseXtra::probe() }
	qr/\Qrender() is an abstract method of Base and must be implemented by Base\E/,
	'package sharing a name prefix but no ISA relation: invocant is Base';

done_testing;
