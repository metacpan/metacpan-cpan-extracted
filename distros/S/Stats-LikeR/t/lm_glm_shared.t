#!/usr/bin/env perl

# lm() and glm() read their formula and their data through one shared parser
# (lm_formula_split / lm_formula_terms / lm_read_rows in LikeR.xs).  These tests
# pin the behaviour that used to differ between them: which formula spellings are
# understood, and what a row is called.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Stats::LikeR qw(lm glm predict);
use Test::LeakTrace;

my %d = (
	y => [1, 3, 2, 5, 4, 6, 8, 7, 9, 11],
	x => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	z => [2, 1, 4, 3, 6, 5, 8, 7, 10, 9],
);

sub linear   { lm(formula => $_[0], data => $_[1]) }
sub gaussian { glm(formula => $_[0], data => $_[1], family => 'gaussian') }

# --- the formula spellings both must now understand -----------------------
# Each was already right in lm() and wrong in glm(): glm() had no '.', no '+0',
# a fixed 512-byte formula buffer, and a substring search for '-1' that reached
# inside I(...).

for my $case (
	['y ~ x',      [qw(Intercept x)]],
	['y ~ .',      [qw(Intercept x z)]],
	['y ~ x - 1',  [qw(x)]],
	['y ~ 0 + x',  [qw(x)]],
	['y ~ x + 0',  [qw(x)]],
	['y ~ 1 + x',  [qw(Intercept x)]],
	['y ~ x * z',  [qw(Intercept x z x:z)]],
	['y ~ 1',      [qw(Intercept)]],
) {
	my ($formula, $want) = @$case;
	my $l = lm(formula => $formula, data => \%d);
	my $g = gaussian($formula, \%d);
	is_deeply([sort @{ $l->{terms} }], [sort @$want], "lm: '$formula' terms");
	is_deeply([sort @{ $g->{terms} }], [sort @$want], "glm: '$formula' terms");
	for my $c (@$want) {
		is($g->{coefficients}{$c}, $l->{coefficients}{$c},
			"'$formula': lm and gaussian glm agree on $c");
	}
}

# A formula longer than the 512-byte buffer glm() used to copy into.  25 columns
# of ~30 characters each is 742 characters; glm() previously lost the tail, and
# the truncated final term named no column, so every row was dropped.
{
	my $N = 60;
	my %wide = (response_variable => [map { $_ * 1.3 + $_ % 5 } 1 .. $N]);
	my @preds;
	for my $k (1 .. 25) {
		my $name = sprintf 'predictor_column_number_%02d', $k;
		$wide{$name} = [map { ($_ * $k) % 17 + $_ / 3 } 1 .. $N];
		push @preds, $name;
	}
	my $long = 'response_variable ~ ' . join ' + ', @preds;
	cmp_ok(length $long, '>', 512, 'test formula is longer than the old fixed buffer');

	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->($long, \%wide);
		is(scalar @{ $r->{terms} }, 26, "$fn->[0]: long formula keeps every term");
		is($r->{terms}[-1], $preds[-1], "$fn->[0]: long formula keeps the last term");
	}
}

# I(x-1) is not a term either function can build -- I() takes only ^power -- but
# glm() used to read the '-1' as intercept suppression and quietly fit I(x)
# instead.  Both must now refuse it rather than one of them guessing.
throws_ok { lm(formula => 'y ~ I(x-1)', data => \%d) }
	qr/0 degrees of freedom/, 'lm: I(x-1) is not silently rewritten';
throws_ok { gaussian('y ~ I(x-1)', \%d) }
	qr/0 degrees of freedom/, 'glm: I(x-1) is not silently rewritten';

# --- row names -----------------------------------------------------------
# lm() used to label every row 1..n.  It now takes glm()'s labels, which is what
# predict() already documented and returned.

{
	my %named = (%d, 'row.names' => [map { "obs$_" } 1 .. 10]);
	my @want = map { "obs$_" } 1 .. 10;

	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->('y ~ x', \%named);
		is_deeply([sort keys %{ $r->{'fitted.values'} }], [sort @want],
			"$fn->[0]: fitted.values keys come from the row.names column");
	}

	my $l = lm(formula => 'y ~ x', data => \%named);
	is_deeply([sort keys %{ $l->{residuals} }], [sort @want],
		'lm: residuals key on the same names as fitted.values');
	is_deeply([sort keys %{ predict($l) }], [sort @want],
		'lm: predict with no newdata keys on the same names');

	# A row label is not a measurement, so '.' must leave it out.
	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->('y ~ .', \%named);
		is_deeply([sort @{ $r->{terms} }], [sort qw(Intercept x z)],
			"$fn->[0]: '.' skips the row.names column");
	}
}

# The other three spellings of a row-name column, and the AoH/HoH shapes.
for my $key (qw(_row rownames .rownames)) {
	my %named = (%d, $key => [map { "r$_" } 1 .. 10]);
	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->('y ~ x', \%named);
		is_deeply([sort keys %{ $r->{'fitted.values'} }], [sort map { "r$_" } 1 .. 10],
			"$fn->[0]: HoA row names from '$key'");
	}
}

{
	my @aoh = map { { _row => "s$_", y => $_, x => ($_ * 3) % 7 } } 1 .. 10;
	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->('y ~ x', \@aoh);
		is_deeply([sort keys %{ $r->{'fitted.values'} }], [sort map { "s$_" } 1 .. 10],
			"$fn->[0]: AoH row names from a per-row _row key");
	}

	my %hoh = map { ("k$_" => { y => $_, x => ($_ * 3) % 7 }) } 1 .. 10;
	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->('y ~ x', \%hoh);
		is_deeply([sort keys %{ $r->{'fitted.values'} }], [sort map { "k$_" } 1 .. 10],
			"$fn->[0]: HoH rows keep their outer keys as names");
	}
}

# Rows without a name fall back to their 1-based index, so a data set with no
# row-name column is labelled exactly as before.
{
	my $l = lm(formula => 'y ~ x', data => \%d);
	is_deeply([sort keys %{ $l->{'fitted.values'} }], [sort 1 .. 10],
		'lm: no row-name column still means 1-based integer labels');
}

# --- shared code, separate messages --------------------------------------
# The helpers take the caller's name so an error still says which function the
# user called.

throws_ok { lm(formula => 'y + x', data => \%d) }
	qr/^lm: invalid formula, missing '~'/, 'lm: keeps its own prefix on a bad formula';
throws_ok { glm(formula => 'y + x', data => \%d) }
	qr/^glm: invalid formula, missing '~'/, 'glm: keeps its own prefix on a bad formula';
throws_ok { lm(formula => 'y ~ x', data => [1, 2, 3]) }
	qr/^lm: Array values must be HashRefs/, 'lm: keeps its own prefix on bad data';
throws_ok { glm(formula => 'y ~ x', data => [1, 2, 3]) }
	qr/^glm: Array values must be HashRefs/, 'glm: keeps its own prefix on bad data';
throws_ok { lm(formula => 'y ~ x', data => {}) }
	qr/^lm: Data hash is empty/, 'lm: keeps its own prefix on an empty hash';
throws_ok { glm(formula => 'y ~ x', data => {}) }
	qr/^glm: Data hash is empty/, 'glm: keeps its own prefix on an empty hash';
# Which of the two shape messages a ragged HoH gets depends on whether hash
# iteration reaches the bad value first, so only the prefix is asserted.
throws_ok { lm(formula => 'y ~ x', data => { a => { y => 1 }, b => 'scalar' }) }
	qr/^lm: Hash values must/, 'lm: keeps its own prefix on a ragged HoH';
throws_ok { glm(formula => 'y ~ x', data => { a => { y => 1 }, b => 'scalar' }) }
	qr/^glm: Hash values must/, 'glm: keeps its own prefix on a ragged HoH';

unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok { eval { lm(formula => 'y ~ .', data => \%d) } }
		'lm: no leaks expanding the dot operator';
	no_leaks_ok { eval { gaussian('y ~ .', \%d) } }
		'glm: no leaks expanding the dot operator';
	no_leaks_ok { eval { lm(formula => 'y + x', data => \%d) } }
		'lm: no leaks when the formula has no ~';
	no_leaks_ok { eval { glm(formula => 'y ~ x', data => [1, 2, 3]) } }
		'glm: no leaks when the data shape is wrong';
}

done_testing();
