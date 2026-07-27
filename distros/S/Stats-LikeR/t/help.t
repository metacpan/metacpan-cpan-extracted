#!/usr/bin/env perl
# h(), and the '?' / 'h' arguments the pure Perl functions take.
#
# The contract under test:
#   * h('name'), h(*name) and h(\&name) print that function's section of the
#     documentation to STDOUT and return the name -- for every function in the
#     distribution, XS and Perl alike, since h() looks the name up;
#   * h() with no argument prints the general help and the list of topics;
#   * the pure Perl functions also take '?' or 'h' in place of their arguments,
#     which prints the same text and then dies;
#   * a column really named h still reaches the XS functions as a column name;
#   * $Stats::LikeR::HELP = 0 switches the argument form off; h() is unaffected.
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

# Wrap a call so any help text lands in a string instead of the TAP stream.
# Returns ($printed, $died_with, @returned).
sub capture {
	my ($code) = @_;
	my ($out, $err, @ret) = ('');
	{
		local *STDOUT;
		open STDOUT, '>', \$out or die "cannot redirect STDOUT: $!";
		@ret = eval { $code->() };
		$err = $@ if $@;
	}
	return ($out, $err, @ret);
}

sub call_named {
	my ($name, @args) = @_;
	return capture(sub { no strict 'refs'; &{"Stats::LikeR::$name"}(@args) });
}

# ---------------------------------------------------------------------------
# h() reaches every documented function, however the name is spelled
# ---------------------------------------------------------------------------
# A mix of XS-implemented (quantile, aov, write_table, vals, ...) and pure Perl
# (agg, view, melt, ...) functions, so both halves of the distribution are
# covered by the same lookup.
my @FUNCS = qw(
	add_data age_standardize agg anova aoh2hoa aoh2hoh aov assign auc auroc
	bedroc bfill binom_test cfilter chisq_test chunk cmh_test cohen_d col
	col2col colnames concat cor cor_test cov coxph cramers_v csort dnorm
	drop_cols drop_duplicates dropna dunn_test epi_2x2 eta_squared ffill
	fillna filter fisher_test friedman_test get_union glm group_by h hist
	hoa2aoh hoa2hoh hoh2hoa hosmer_lemeshow interpolate intersection
	is_equivalent kruskal_test ks_test ljoin lm logrank_test Lonly matrix max
	mcnemar_test mean median melt merge min mode ncol nrow oneway_test
	p_adjust pivot_table pnorm power_t_test prcomp predict prop_test qcut
	quantile rank rbinom read_table rename_cols rnorm roc Ronly rownames runif
	sample scale sd select_cols seq shapiro_test smd sum summary survfit
	table_one transpose t_test uniq vals value_counts var var_test view vif
	wilcox_test write_table
);

for my $f (@FUNCS) {
	my ($out, $err, @ret) = capture(sub { Stats::LikeR::h($f) });
	is($err, undef, "h('$f') does not die");
	is_deeply(\@ret, [ $f ], "h('$f') returns the name");
	like($out, qr/\QStats::LikeR::$f\E/, "h('$f') names itself in the help");
	like($out, qr/\bh\('\Q$f\E'\)/, "h('$f') shows how to ask again");
}

# the glob and code-reference spellings agree with the string one
for my $f (qw(quantile agg write_table col)) {
	my ($by_string) = capture(sub { Stats::LikeR::h($f) });
	my ($by_glob)   = capture(sub { no strict 'refs'; Stats::LikeR::h(*{"Stats::LikeR::$f"}) });
	my ($by_code)   = capture(sub { no strict 'refs'; Stats::LikeR::h(\&{"Stats::LikeR::$f"}) });
	is($by_glob, $by_string, "h(*$f) matches h('$f')");
	is($by_code, $by_string, "h(\\&$f) matches h('$f')");
}

# a package-qualified name, and a leading &
{
	my ($a) = capture(sub { Stats::LikeR::h('Stats::LikeR::smd') });
	my ($b) = capture(sub { Stats::LikeR::h('&smd') });
	my ($c) = capture(sub { Stats::LikeR::h('smd') });
	is($a, $c, "h('Stats::LikeR::smd') matches h('smd')");
	is($b, $c, "h('&smd') matches h('smd')");
}

# h() with no argument
{
	my ($out, $err, @ret) = capture(sub { Stats::LikeR::h() });
	is($err, undef, 'h() does not die');
	is_deeply(\@ret, [ '' ], 'h() returns the empty name');
	like($out, qr/h\('quantile'\)|Getting help/, 'h() explains how to ask');
	like($out, qr/Documented functions/,          'h() introduces the topic list');
	like($out, qr/\bwilcox_test\b/,               'h() lists documented functions');
	unlike($out, qr/no documentation section/, 'h() is not the not-found message');
	my ($undef_out) = capture(sub { Stats::LikeR::h(undef) });
	is($undef_out, $out, 'h(undef) is h()');
}

# bad arguments to h()
{
	my (undef, $err) = capture(sub { Stats::LikeR::h(\&capture) });
	like($err || '', qr/not a Stats::LikeR function/, 'h(\&foreign_sub) dies');
	my (undef, $err2) = capture(sub { Stats::LikeR::h([ 'agg' ]) });
	like($err2 || '', qr/expected a function name/, 'h(\@ref) dies');
}

# ---------------------------------------------------------------------------
# the help text is the documentation, not a stub
# ---------------------------------------------------------------------------
{
	my ($out) = capture(sub { Stats::LikeR::h('cohen_d') });
	like($out, qr/COHEN_D/,  'the section heading is rendered');
	like($out, qr/pooled/i,  'prose from the section is present');
	like($out, qr/hedges_g/, 'the output-variable table is rendered');
	like($out, qr/\n\s*Variable\s+Type\s+Description/,
		'an =begin html table comes out as aligned plain text');
	unlike($out, qr/<t[dhr]\b|<\/table>/, 'no raw HTML leaks through');
	unlike($out, qr/[A-Z]<[^<>]*>/,       'no raw POD formatting codes leak through');
}

# a function whose documentation lives under another name
{
	my ($out, $err) = capture(sub { Stats::LikeR::h('rbind') });
	is($err, undef, "h('rbind') does not die");
	like($out, qr/\bconcat\b/, "h('rbind') shows concat's section (same sub)");
}

# a function with no section of its own falls back to the list of topics
{
	my ($out, $err) = capture(sub { Stats::LikeR::h('ptukey') });
	is($err, undef, "h('ptukey') does not die");
	like($out, qr/no documentation section/, 'the fallback explains itself');
	like($out, qr/\bwilcox_test\b/,          'the fallback lists documented functions');
}

# ---------------------------------------------------------------------------
# the '?' / 'h' arguments: pure Perl functions only
# ---------------------------------------------------------------------------
my @PERL_FUNCS = qw(
	age_standardize agg aoh2hoh assign bfill chunk cohen_d col colnames concat
	cramers_v drop_cols drop_duplicates dropna eta_squared ffill fillna
	hosmer_lemeshow interpolate melt ncol nrow pivot_table qcut read_table
	rename_cols rownames select_cols smd summary table_one TukeyHSD view vif
);

for my $f (@PERL_FUNCS) {
	for my $flag ('h', '?') {
		my ($out, $err) = call_named($f, $flag);
		like($err || '', qr/help requested/, "$f('$flag') dies with the help notice");
		like($out, qr/\QStats::LikeR::$f\E/, "$f('$flag') printed its documentation");
	}
}

# recognized anywhere in the argument list, not just first
{
	for my $call ( [ 'view', [ { a => [1] } ], 'n', 'h' ],
	               [ 'agg',  [ { a => [1] } ], 'agg', '?' ] ) {
		my ($name, @args) = @$call;
		my ($out, $err) = call_named($name, @args);
		like($err || '', qr/help requested/, "$name: help found in a later argument");
		like($out, qr/\QStats::LikeR::$name\E/, "$name: right section shown");
	}
}

# A column really named h reaches the XS functions as a column name.  This is
# the behaviour the argument form would have cost, and the reason h() exists;
# what an individual XS function makes of a lone 'h' is its own business, so
# nothing here asserts a blanket rule over them.
{
	my $got = Stats::LikeR::vals({ h => [ 4, 5, 6 ] }, 'h');
	is_deeply($got, [ 4, 5, 6 ], "vals(\$df, 'h') returns the column named h");

	my ($sorted) = Stats::LikeR::csort([ { h => 2 }, { h => 1 } ], 'h');
	is($sorted->[0]{h}, 1, "csort(\$df, 'h') sorts by the column named h");
}

# ---------------------------------------------------------------------------
# nothing else triggers the argument form
# ---------------------------------------------------------------------------
{
	my ($out, $err) = capture(sub { my $n = Stats::LikeR::ncol({ a => [1, 2] }); $n });
	is($err, undef, 'an ordinary call does not die');
	is($out, '',    'an ordinary call prints nothing');

	for my $arg ('H', 'help', 'hh', 'h ', ' h', '??', 'Q', '', 0, 1, undef) {
		my $shown = defined $arg ? "'$arg'" : 'undef';
		my ($o, $e) = call_named('ncol', { a => [1, 2] }, $arg);
		unlike($e || '', qr/help requested/, "ncol(..., $shown) is not a help request");
		is($o, '', "ncol(..., $shown) prints no help");
	}
}

# ---------------------------------------------------------------------------
# the off switch
# ---------------------------------------------------------------------------
{
	local $Stats::LikeR::HELP = 0;

	my ($out, $err) = capture(sub { Stats::LikeR::filter([ { h => 1 }, { h => 5 } ],
	                                                     Stats::LikeR::col('h') > 3) });
	is($out, '', 'HELP = 0: col(\'h\') prints no help');
	is($err, undef, 'HELP = 0: col(\'h\') does not die');

	my $kept = Stats::LikeR::filter([ { h => 1 }, { h => 5 } ], Stats::LikeR::col('h') > 3);
	is(scalar(@$kept), 1, 'HELP = 0: the predicate on column h works');

	# h() ignores the switch: it was asked by name, not by argument
	my ($hout, $herr) = capture(sub { Stats::LikeR::h('agg') });
	is($herr, undef, 'HELP = 0: h() still works');
	like($hout, qr/Stats::LikeR::agg/, 'HELP = 0: h() still prints');
}

# and the argument form is back on outside the local
{
	my (undef, $err) = call_named('agg', 'h');
	like($err || '', qr/help requested/, 'the argument form is on again');
}

# ---------------------------------------------------------------------------
# renderer details worth pinning down
# ---------------------------------------------------------------------------
{
	my $longest = sub {
		my $n = 0;
		for my $l (split /\n/, $_[0]) { $n = length $l if length($l) > $n }
		return $n;
	};

	local $ENV{COLUMNS} = 60;
	my ($narrow) = capture(sub { Stats::LikeR::h('agg') });
	{
		local $ENV{COLUMNS} = 100;
		my ($wide) = capture(sub { Stats::LikeR::h('agg') });
		cmp_ok($longest->($wide), '>', $longest->($narrow),
			'COLUMNS widens the rendered help');
	}
	# verbatim code samples are never rewrapped, whatever the width
	like($narrow, qr/\n\s+my \$/, 'code samples survive at 60 columns');
}

# _pod_section finds a heading however the generator dressed it up
{
	ok(scalar(Stats::LikeR::_pod_section('aoh2hoh')),   'heading wrapped in C<> is found');
	ok(scalar(Stats::LikeR::_pod_section('hoa2hoh')),   'heading carrying a signature is found');
	is(scalar(Stats::LikeR::_pod_section('no_such_fn')), 0, 'an unknown name finds nothing');
}

# The same table in the other spelling.  This file's POD writes its tables as
# =begin html / =end html, but Pod::Weaver folds each one into a single =for html
# paragraph when the distribution is built, so that is the form the shipped copy
# carries and the renderer has to read both.
{
	require File::Temp;
	my ($fh, $file) = File::Temp::tempfile('likerhelpXXXX', TMPDIR => 1, UNLINK => 1);
	print {$fh} <<'POD';
=head2 widget

Prose about the widget.

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>estimate</code></td>
  <td><code>Double</code></td>
  <td>The estimate itself.</td>
</tr>
</tbody>
</table>

=cut
POD
	close $fh;

	local $Stats::LikeR::POD_FILE = $file;
	my ($out) = capture(sub { Stats::LikeR::h('widget') });
	like($out, qr/\n\s*Variable\s+Type\s+Description/,
		'a =for html table comes out as aligned plain text');
	like($out, qr/\bestimate\b.*\bDouble\b/, 'the =for html table body is rendered');
	unlike($out, qr/<t[dhr]\b|<\/table>/, 'no raw HTML leaks out of a =for block');
}

done_testing();
