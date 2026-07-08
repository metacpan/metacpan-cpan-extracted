#!/usr/bin/env perl

# Tests for filter()'s row-identifier argument, added this cycle.
#
# filter() now calls the predicate with the row as $_ / $_[0] AND the row's
# identifier as $_[1]:
#   * HoH  -> $_[1] is the outer key (the "row_name")
#   * AoH  -> $_[1] is the 0-based row index
#   * HoA  -> $_[1] is the 0-based row index
#
# Before this change filter() pushed only the row, so $_[1] was undef and there
# was no way to filter a HoH on its row name at all. The predicates below use
# `defined($_[1]) && ...` so that on the OLD behavior they select nothing
# (empty result) rather than warning under `warnings FATAL => 'all'` -- which
# makes every "by identifier" assertion below fail on the pre-fix code and pass
# on the fixed code. The backward-compatibility block ($_ / $_->{col}) passes on
# both and guards against regressing existing predicates.

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok / throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("         got: $got\n    expected: $expected; diff = $diff");
		return 0;
	}
}

# Sorted list of the outer keys of a HoH result.
sub hoh_keys { [ sort keys %{ $_[0] } ] }
# Sorted list of one column pulled from an AoH result.
sub aoh_col  { my ($r, $c) = @_; [ sort { $a <=> $b } map { $_->{$c} } @$r ] }

my $LIKE = 'x';   # avoid "used only once" style noise from the pragma

#--------------------------------------------------------------------------
# HoH: filter on the row name via $_[1]  (the headline feature)
#--------------------------------------------------------------------------
my $score = {
	'1cka' => { anomaly_rank => 162, regression_score => -7.2986 },
	'1ckb' => { anomaly_rank =>  66, regression_score => -7.2501 },
	'1d4t' => { anomaly_rank =>  53, regression_score => -8.0329 },
	'2xyz' => { anomaly_rank =>  10, regression_score => -9.1000 },
};
my $grps = '1cka|1d4t';

{
	my $sub_score = filter( $score, sub { defined($_[1]) && $_[1] =~ m/^(?:$grps)$/ } );
	is( ref($sub_score), 'HASH', 'HoH by row name: result is a HoH ref' );
	is_deeply( hoh_keys($sub_score), ['1cka', '1d4t'],
		'HoH by row name: $_[1] selects the matching outer keys' );
	is_deeply( $sub_score->{'1cka'}, $score->{'1cka'},
		'HoH by row name: kept rows share the original inner hash' );
}

# exact-match on the row name
{
	my $one = filter( $score, sub { defined($_[1]) && $_[1] eq '1d4t' } );
	is_deeply( hoh_keys($one), ['1d4t'], 'HoH by row name: exact eq match' );
}

# row name AND a column predicate together
{
	my $both = filter( $score, sub { defined($_[1]) && $_[1] =~ /^1/ && $_->{anomaly_rank} < 100 } );
	is_deeply( hoh_keys($both), ['1ckb', '1d4t'],
		'HoH: combine $_[1] (row name) with $_->{col}' );
}

# HoH filtered by row name, projected to AoH output
{
	my $aoh = filter( $score, sub { defined($_[1]) && $_[1] =~ m/^(?:$grps)$/ },
	                  'output.type' => 'aoh' );
	is( ref($aoh), 'ARRAY', 'HoH->aoh by row name: result is an AoH ref' );
	is( scalar(@$aoh), 2,    'HoH->aoh by row name: two rows kept' );
	is_deeply( aoh_col($aoh, 'anomaly_rank'), [53, 162],
		'HoH->aoh by row name: correct rows projected' );
}

# direct check: the predicate actually receives every outer key as $_[1]
{
	my %seen;
	filter( $score, sub { $seen{ $_[1] // '(undef)' } = 1; 1 } );
	is_deeply( [ sort keys %seen ], [ sort keys %$score ],
		'HoH: predicate receives each outer key as $_[1]' );
}

#--------------------------------------------------------------------------
# AoH: $_[1] is the 0-based row index
#--------------------------------------------------------------------------
my $aoh_in = [ { id => 'a', v => 1 }, { id => 'b', v => 5 }, { id => 'c', v => 9 } ];

{
	my $r = filter( $aoh_in, sub { defined($_[1]) && ( $_[1] == 0 || $_[1] == 2 ) } );
	is_deeply( [ map { $_->{id} } @$r ], ['a', 'c'],
		'AoH by index: $_[1] selects rows 0 and 2' );
}
{
	my %seen;
	filter( $aoh_in, sub { $seen{ $_[1] // 'U' } = 1; 1 } );
	is_deeply( [ sort { $a <=> $b } keys %seen ], [0, 1, 2],
		'AoH: predicate receives each row index as $_[1]' );
}

#--------------------------------------------------------------------------
# HoA: $_[1] is the 0-based row index; shape is preserved
#--------------------------------------------------------------------------
my $hoa_in = { id => ['a', 'b', 'c'], v => [1, 5, 9] };

{
	my $r = filter( $hoa_in, sub { defined($_[1]) && $_[1] != 1 } );
	is( ref($r), 'HASH', 'HoA by index: result is a HoA ref' );
	is_deeply( $r, { id => ['a', 'c'], v => [1, 9] },
		'HoA by index: $_[1] drops row 1, preserves HoA shape' );
}

#--------------------------------------------------------------------------
# Backward compatibility: predicates that ignore $_[1] still behave.
# (Passes on both old and new code; guards against regressing $_ / $_->{col}.)
#--------------------------------------------------------------------------
{
	my $r = filter( $aoh_in, sub { $_->{v} >= 5 } );
	is_deeply( [ map { $_->{id} } @$r ], ['b', 'c'],
		'compat: AoH $_->{col} predicate unaffected' );
}
{
	my $r = filter( $score, sub { $_->{anomaly_rank} < 100 } );
	is_deeply( hoh_keys($r), ['1ckb', '1d4t', '2xyz'],
		'compat: HoH $_->{col} predicate unaffected' );
}

#--------------------------------------------------------------------------
# Usage guards still fire.
#--------------------------------------------------------------------------
throws_ok { filter($score) } qr/Usage: filter/, 'filter: missing predicate croaks';
throws_ok { filter('not a ref', sub { 1 }) } qr/data frame/,
	'filter: non-ref data frame croaks';

#--------------------------------------------------------------------------
# Leak check (real calls hoisted out of the closure first, per convention).
#--------------------------------------------------------------------------
filter( $score, sub { defined($_[1]) && $_[1] =~ m/^(?:$grps)$/ } );
filter( $aoh_in, sub { defined($_[1]) && $_[1] == 0 } );
filter( $hoa_in, sub { defined($_[1]) && $_[1] != 1 } );
no_leaks_ok {
	eval {
		my $h = filter( $score,  sub { defined($_[1]) && $_[1] =~ m/^(?:$grps)$/ } );
		my $a = filter( $aoh_in, sub { defined($_[1]) && $_[1] == 0 } );
		my $o = filter( $hoa_in, sub { defined($_[1]) && $_[1] != 1 } );
		my $p = filter( $score,  sub { defined($_[1]) && $_[1] =~ /^1/ },
		                'output.type' => 'aoh' );
	}
} 'filter(): no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing;
