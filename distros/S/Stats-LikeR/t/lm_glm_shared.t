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
use Stats::LikeR qw(lm glm predict anova);
use Test::LeakTrace;

my %d = (
	y => [1, 3, 2, 5, 4, 6, 8, 7, 9, 11],
	x => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
	z => [2, 1, 4, 3, 6, 5, 8, 7, 10, 9],
);

sub linear   { lm(formula => $_[0], data => $_[1]) }
sub gaussian { glm(formula => $_[0], data => $_[1], family => 'gaussian') }

# the formula spellings both must now understand
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

# R's term removal, `a - b`.  Through 0.3217 the parser split only on '+', so
# "z-w" was looked up as one column, no row had it, and both functions died
# with "0 degrees of freedom".  Each case's terms are the term labels R 4.6.1
# gives for the same formula, attr(terms(f), "term.labels"), and its fit must
# be the fit of the formula written without the removal.
{
	my %d3 = (%d, w => [3, 1, 4, 1, 5, 9, 2, 6, 5, 3]);
	for my $case (
		['y ~ x + z - w',     'y ~ x + z',      [qw(Intercept x z)]],   # w is not in the model
		['y ~ x + z + w - w', 'y ~ x + z',      [qw(Intercept x z)]],
		['y ~ . - w',         'y ~ x + z',      [qw(Intercept x z)]],
		['y ~ x*z - x:z',     'y ~ x + z',      [qw(Intercept x z)]],
		['y ~ x*z - z:x',     'y ~ x + z',      [qw(Intercept x z)]],   # a:b and b:a are one term
		['y ~ x*z*w - x:z:w', 'y ~ x + z + w + x:z + x:w + z:w', [qw(Intercept x z w x:z x:w z:w)]],
		# R labels these x:w and x:z:w: it orders a term's variables by the
		# whole formula, removed terms and all, where the design orders them
		# by the terms that remain, and w is the first of those.  The fit is
		# the same; README.md lists this among the differences from R.
		['y ~ x*z*w - x*z',   'y ~ w + x:w + z:w + x:z:w',       [qw(Intercept w w:x w:z w:x:z)]],
		['y ~ -x + z',        'y ~ z',          [qw(Intercept z)]],
		['y ~ x + z - x - 1', 'y ~ z - 1',      [qw(z)]],
	) {
		my ($formula, $plain, $want) = @$case;
		for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
			my $r = $fn->[1]->($formula, \%d3);
			my $p = $fn->[1]->($plain, \%d3);
			is_deeply([sort @{ $r->{terms} }], [sort @$want], "$fn->[0]: '$formula' terms");
			is_deeply($r->{coefficients}, $p->{coefficients}, "$fn->[0]: '$formula' fits '$plain'");
		}
	}
	my $a = anova(\%d3, 'y ~ x*z - x:z');
	is_deeply([sort grep { $_ ne 'Residuals' } keys %$a], [qw(x z)], "anova: 'y ~ x*z - x:z' has terms x and z");
	# a '-' inside parentheses is not removal, and a chunk that names a column
	# is that column, as it was before '-' meant anything
	my %h = (%d, 'a-b' => [2, 7, 1, 8, 2, 8, 1, 8, 2, 8]);
	is_deeply(linear('y ~ a-b + x', \%h)->{terms}, [qw(Intercept a-b x)], "lm: a column named 'a-b' is still a column");
	is_deeply(gaussian('y ~ a-b + x', \%h)->{terms}, [qw(Intercept a-b x)], "glm: a column named 'a-b' is still a column");
}

# Seven variables crossed are 128 terms.  The parser's list of distinct terms
# was allocated at 64 beside the list of all of them, and only that one grew
# inside lm_expand_cross(), so this formula wrote past the end of it.  It ran
# clean only by luck; valgrind reported the invalid writes.
{
	srand(1);
	my %d7 = map { $_ => [ map { rand() } 1 .. 200 ] } qw(y a b c d e f g);
	is(scalar @{ linear('y ~ a*b*c*d*e*f*g', \%d7)->{terms} }, 128, 'lm: a 7-way cross has 128 columns');
	is(scalar @{ gaussian('y ~ a*b*c*d*e*f*g', \%d7)->{terms} }, 128, 'glm: a 7-way cross has 128 columns');
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

# row names
# lm() used to label every row 1..n.  It now takes glm()'s labels, which is what
# predict() already documented and returned.

{
	my %named = (%d, 'row_names' => [map { "obs$_" } 1 .. 10]);
	my @want = map { "obs$_" } 1 .. 10;

	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->('y ~ x', \%named);
		is_deeply([sort keys %{ $r->{'fitted_values'} }], [sort @want],
			"$fn->[0]: fitted_values keys come from the row_names column");
	}

	my $l = lm(formula => 'y ~ x', data => \%named);
	is_deeply([sort keys %{ $l->{residuals} }], [sort @want],
		'lm: residuals key on the same names as fitted_values');
	is_deeply([sort keys %{ predict($l) }], [sort @want],
		'lm: predict with no newdata keys on the same names');

	# A row label is not a measurement, so '.' must leave it out.
	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->('y ~ .', \%named);
		is_deeply([sort @{ $r->{terms} }], [sort qw(Intercept x z)],
			"$fn->[0]: '.' skips the row_names column");
	}
}

# The other three spellings of a row-name column, and the AoH/HoH shapes.
for my $key (qw(_row rownames .rownames)) {
	my %named = (%d, $key => [map { "r$_" } 1 .. 10]);
	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->('y ~ x', \%named);
		is_deeply([sort keys %{ $r->{'fitted_values'} }], [sort map { "r$_" } 1 .. 10],
			"$fn->[0]: HoA row names from '$key'");
	}
}

{
	my @aoh = map { { _row => "s$_", y => $_, x => ($_ * 3) % 7 } } 1 .. 10;
	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->('y ~ x', \@aoh);
		is_deeply([sort keys %{ $r->{'fitted_values'} }], [sort map { "s$_" } 1 .. 10],
			"$fn->[0]: AoH row names from a per-row _row key");
	}

	my %hoh = map { ("k$_" => { y => $_, x => ($_ * 3) % 7 }) } 1 .. 10;
	for my $fn (['lm', \&linear], ['glm', \&gaussian]) {
		my $r = $fn->[1]->('y ~ x', \%hoh);
		is_deeply([sort keys %{ $r->{'fitted_values'} }], [sort map { "k$_" } 1 .. 10],
			"$fn->[0]: HoH rows keep their outer keys as names");
	}
}

# Rows without a name fall back to their 1-based index, so a data set with no
# row-name column is labelled exactly as before.
{
	my $l = lm(formula => 'y ~ x', data => \%d);
	is_deeply([sort keys %{ $l->{'fitted_values'} }], [sort 1 .. 10],
		'lm: no row-name column still means 1-based integer labels');
}

# shared code, separate messages
# The helpers take the caller's name so an error still says which function the
# user called.

throws_ok { lm(formula => 'y + x', data => \%d) }
	qr/\nlm: error: invalid formula, missing '~'/, 'lm: keeps its own prefix on a bad formula';
throws_ok { glm(formula => 'y + x', data => \%d) }
	qr/\nglm: error: invalid formula, missing '~'/, 'glm: keeps its own prefix on a bad formula';
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

# A call of the wrong form dies with the function's argparse-style help screen
# (lib/Stats/LikeR/Usage.pm), then "fn: error: ..." as its last line.
{
	my $err = eval { lm(formula => 'y ~ x', data => { x => [1, 2], y => [1, 2] }, colour => 1); 1 } ? '' : $@;
	like($err, qr/\Ausage: lm\(.*^example:\n.*\n\nlm: error: \Qunknown argument 'colour'\E\n\z/ms,
		'lm: unknown argument \'colour\', under the help screen');
}
{
	my $err = eval { lm('y ~ x'); 1 } ? '' : $@;
	like($err, qr/\Ausage: lm\(.*^example:\n.*\n\nlm: error: \Qarguments must be name => value pairs\E\n\z/ms,
		'lm: arguments must be name => value pairs, under the help screen');
}
{
	my $err = eval { glm(formula => 'y ~ x', data => { x => [1, 2], y => [1, 2] }, family => 'gamma'); 1 } ? '' : $@;
	like($err, qr/\Ausage: glm\(.*^example:\n.*\n\nglm: error: \Qunsupported family 'gamma' (gaussian, binomial, poisson, negbin)\E\n\z/ms,
		'glm: unsupported family \'gamma\' (gaussian, binomial, poisson, negbin), under the help screen');
}
{
	my $err = eval { glm(formula => 'y ~ x', data => { x => [1, 2], y => [1, 2] }, offset => {}); 1 } ? '' : $@;
	like($err, qr/\Ausage: glm\(.*^example:\n.*\n\nglm: error: \Q'offset' must be a column name or an array ref\E\n\z/ms,
		'glm: \'offset\' must be a column name or an array ref, under the help screen');
}

done_testing();
