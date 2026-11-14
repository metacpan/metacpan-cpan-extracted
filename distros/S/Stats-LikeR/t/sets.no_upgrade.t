#!/usr/bin/env perl
# Provenance: there is no R or SciPy counterpart to the set operations (they
# follow Perl's List::Compare), so the expected values here are worked by hand
# from the definitions; nothing is taken from a reference suite.  What the file
# pins is a property of the implementation: get_union(), intersection(),
# Lonly(), Ronly() and is_equivalent() key their values by stringification,
# and up to 0.3418 did so with SvPV() on the caller's own SV, which formats a
# plain IV or NV and leaves the string cached on it for good (an NV became a
# PVNV with POK set: Devel::Peek showed it, Lonly() of two 1e6-element double
# arrays grew the process by 304MB).  The sets are now keyed from a scratch
# buffer or a scratch copy, as uniq() is, and the caller's numbers must stay
# numbers.
require 5.010;
use strict; use warnings FATAL => 'all';
use Test::More;
use B ();
use Stats::LikeR qw(get_union intersection Lonly Ronly is_equivalent);

# A PV cached by SvPV() shows as a PVNV/PVIV body even where perl (5.36 and
# up) leaves POK off, so the body class is compared, not the POK flag.
sub bare_num { my $c = ref B::svref_2object(\$_[0]); return $c eq 'B::IV' || $c eq 'B::NV' }

# 0.5, 0.1 and 1/3 print as non-integral doubles; 0.1 + 0.2 lands where %.15g
# must round (0.3); 2**60 is an IV.  Chosen so both the fast renderer and the
# fallback (any NV on a long double build) are exercised.
my @vals = (0.5, 0.1, 1/3, 0.1 + 0.2, 1e15 + 0.5, -2.25, 7, -3, 2**60, 1e300);
my %fn = (
	get_union    => sub { get_union(@_) },
	intersection => sub { intersection(@_) },
	Lonly        => sub { Lonly(@_) },
	Ronly        => sub { Ronly(@_) },
	is_equivalent => sub { is_equivalent(@_) },
);
for my $name (sort keys %fn) {
	for my $ctx (qw(list scalar)) {
		my @a = @vals;
		my @b = reverse @vals;
		push @b, 99.75;
		my @r;
		if ($ctx eq 'list') { @r = $fn{$name}->(\@a, \@b) }
		else                { @r = scalar $fn{$name}->(\@a, \@b) }
		my $bad = grep { !bare_num($_) } @a, @b;
		is($bad, 0, "$name ($ctx): the caller's numbers are still plain IV/NV bodies");
		is(scalar(grep { !bare_num($_) } @r), 0, "$name ($ctx): results are plain IV/NV bodies") if $ctx eq 'list' && $name ne 'is_equivalent';
	}
}

# values, from the definitions (a = @vals, b = reverse(@vals), 99.75)
{
	my @a = @vals; my @b = (reverse(@vals), 99.75);
	is_deeply([get_union(\@a, \@b)], [@vals, 99.75], 'get_union: first-appearance order, one copy each');
	is(scalar get_union(\@a, \@b), 11, 'get_union: scalar context is the distinct count');
	is_deeply([intersection(\@a, \@b)], [@vals], 'intersection: everything of a is in b');
	is_deeply([Lonly(\@a, \@b)], [], 'Lonly: nothing of a is absent from b');
	is_deeply([Ronly(\@a, \@b)], [99.75], 'Ronly: only 99.75 is exclusive to b');
	is(scalar Ronly(\@a, \@b), 1, 'Ronly: scalar context is the count');
	ok(!is_equivalent(\@a, \@b), 'is_equivalent: b has an extra value');
	ok(is_equivalent(\@a, [reverse @a, @a]), 'is_equivalent: order and multiplicity ignored');
}

# key equivalence is `eq` on the stringification: 1, 1.0, "1" are one value,
# 0.1+0.2 and "0.3" are one value (both print 0.3), and -0.0 against "-0"
# is whatever uniq() makes of it
{
	is(scalar get_union([1, 1.0, "1"], ["1.0"]), 2, '1 / 1.0 / "1" collapse, "1.0" is another');
	is(scalar get_union([0.1 + 0.2], ["0.3"]), 1, '0.1+0.2 stringifies as 0.3');
	# How -0.0 is keyed moves with the perl: 5.10 and 5.12 print it as "-0" and
	# newer perls as "0", and a double build renders a bare number itself where
	# a long double one asks perl.  What must hold everywhere is that the set
	# functions key it exactly as uniq() does, whose table they now share.
	my $negzero = -0.0;
	is(scalar get_union([$negzero], ["-0"]), scalar(my @u = Stats::LikeR::uniq([$negzero, "-0"])),
		'-0.0 against the string "-0" is keyed as uniq() keys it');
	is(scalar get_union(["\xe9"], ["\x{e9}"]), 1, 'a downgradable UTF-8 string equals its byte form');
	is(scalar get_union(["\x{263A}"], ["\xe2\x98\xba"]), 2, 'a wide character is not its UTF-8 bytes');
	my $n = 5; my $s = "$n";	# $n is now IV+PV
	is(scalar get_union([$n], [5.0]), 1, 'IV with a cached PV keys as 5');
}

# an unaltered caller after a croak, too
{
	my @a = (0.25, 0.5); my @b = (0.5, undef);
	ok(!eval { Lonly(\@a, \@b); 1 }, 'undef element croaks');
	like($@, qr/undefined value at array ref index 1 \(argument 1\)/, 'croak names the index and argument');
	is(scalar(grep { !bare_num($_) } @a, $b[0]), 0, 'and the numbers read before it are untouched');
}

# srv_read() (survfit's group labels) had the same defect: SvPV on a numeric
# group cell cached a PV on it
{
	require Stats::LikeR;
	my @t = (1, 2, 3, 4, 5, 6); my @s = (1, 1, 0, 1, 1, 0); my @g = (0.5, 0.5, 2, 2, 7, 7);
	my $r = Stats::LikeR::survfit(\@t, \@s, group => \@g);
	ok($r, 'survfit with numeric groups runs');
	is(scalar(grep { !bare_num($_) } @g), 0, 'survfit: numeric group cells stay plain IV/NV bodies');
}

done_testing;
