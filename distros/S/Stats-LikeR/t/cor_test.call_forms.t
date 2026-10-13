#!/usr/bin/env perl
#
# cor_test's two call forms.  The documentation has always shown the all-named
# cor_test(x => \@x, y => \@y, ...), but through 0.3216 only the positional
# cor_test(\@x, \@y, ...) was parsed: the named form took the string 'x' for x
# and croaked "unknown argument 'y'".  Both forms are now accepted and must give
# the same answer, under every method and with other options after them.
#
# No reference values are needed here: the claim is only that the two forms
# are the same call.  The numbers themselves are pinned against R in
# t/cor_test.{pearson.ci,spearman,kendall}.R.t.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR 'cor_test';
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my @x = (44.4, 45.9, 41.9, 53.3, 44.7, 44.1, 50.7, 45.2, 60.1);
my @y = ( 2.6,  3.1,  2.5,  5.0,  3.6,  4.0,  5.2,  2.8,  3.8);

for my $method (qw(pearson spearman kendall)) {
	for my $alt (qw(two.sided less greater)) {
		my %opt = (method => $method, alternative => $alt);
		my $pos   = cor_test(\@x, \@y, %opt);
		my $named = cor_test(x => \@x, y => \@y, %opt);
		my $later = cor_test(%opt, y => \@y, x => \@x);
		is_deeply($named, $pos, "$method $alt: x => , y => matches positional");
		is_deeply($later, $pos, "$method $alt: options first, y before x, matches positional");
	}
}

# an undef first argument is still positional x, so its message is unchanged
my %croak = (
	'no arguments'           => [ [], qr/^cor_test: both x and y are required/ ],
	'named, y missing'       => [ [ x => \@x ], qr/^cor_test: both x and y are required/ ],
	'named, x missing'       => [ [ y => \@y, method => 'kendall' ], qr/^cor_test: both x and y are required/ ],
	'positional, y missing'  => [ [ \@x ], qr/^Usage: cor_test/ ],
	'named, odd pair count'  => [ [ x => \@x, y => \@y, 'method' ], qr/^Usage: cor_test/ ],
	'positional, odd count'  => [ [ \@x, \@y, 'method' ], qr/^Usage: cor_test/ ],
	'named, x not an array'  => [ [ x => 'abc', y => \@y ], qr/^cor_test: x and y must be array references/ ],
	'undef x is positional'  => [ [ undef, \@y ], qr/^cor_test: x and y must be array references/ ],
	'named, unknown key'     => [ [ x => \@x, y => \@y, z => 1 ], qr/^cor_test: unknown argument 'z'/ ],
	'positional, x as a key' => [ [ \@x, \@y, x => \@x ], qr/^cor_test: unknown argument 'x'/ ],
);
for my $name (sort keys %croak) {
	my ($args, $re) = @{ $croak{$name} };
	eval { cor_test(@$args) };
	like($@, $re, "croaks: $name");
}

no_leaks_ok { cor_test(x => \@x, y => \@y, method => 'kendall') }
	'named form: no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { eval { cor_test(x => \@x) } }
	'named form, y missing: no leaks' unless $INC{'Devel/Cover.pm'};

done_testing;
