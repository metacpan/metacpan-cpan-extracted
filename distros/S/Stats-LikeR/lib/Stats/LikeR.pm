#!/usr/bin/env perl
# ABSTRACT: Get basic statistical functions, like in R, but with Perl using XS for performance
require 5.010;
use strict;
package Stats::LikeR;
our $VERSION = 0.25;
require XSLoader;
use warnings FATAL => 'all';
use autodie ':default';
use Exporter 'import';
use Scalar::Util qw(reftype looks_like_number);
XSLoader::load('Stats::LikeR', $VERSION);
our @EXPORT_OK = qw(add_data agg anova aoh2hoa aoh2hoh aov assign bfill binom_test cfilter chisq_test chunk col col2col colnames concat cor cor_test cov csort dnorm drop_cols drop_duplicates dropna ffill fillna filter fisher_test get_union glm group_by hoa2aoh hoa2hoh hoh2hoa hist interpolate intersection is_equivalent kruskal_test ks_test Lonly ljoin lm map_cell matrix max mean median melt merge min mode ncol nrow oneway_test p_adjust pivot_table pnorm power_t_test predict prcomp ptukey qcut qtukey quantile rank Ronly rbind rbinom read_table rename_cols rnorm rownames runif sample scale sd select_cols seq shapiro_test sum summary t_test transpose TukeyHSD uniq vals value_counts var var_test view wilcox_test write_table);
our @EXPORT = @EXPORT_OK;

# colnames($df) / rownames($df)
#
# Return the column names and row names of any of the four Stats::LikeR
# frame shapes, as a list (R's colnames()/rownames()).  In scalar context
# each returns the count, so `scalar colnames($df) == ncol($df)` and
# `scalar rownames($df) == nrow($df)` on a rectangular frame.
#
# Ordering mirrors view() exactly, so what you name is what you would see:
#   * positional axes are 0-based integer indices --
#       AoA columns, and the rows of AoA / AoH / HoA
#   * key-based axes are the string-sorted union of keys --
#       AoH / HoH columns (union across every row), HoA columns,
#       and HoH rows (the outer keys)
#
# Shape is classified by _df_shape (the same detector agg() uses), so a
# ragged AoA/HoA is tolerated for enumeration: colnames() spans the widest
# row and rownames() the longest column.  Empty frames yield an empty list.
# Like agg()/view(), the classifier is ref-based (not reftype), so hand it
# an unblessed frame -- blessed frames are the one case ncol()/nrow() take
# that this family does not.

sub colnames {
	my ($df) = @_;
	die "colnames: undefined data in first position\n" unless defined $df;
	my $shape = _df_shape($df, 'colnames');
	my @cols;
	if ($shape eq 'AoA') {                       # widest row -> 0 .. m-1
		my $m = 0;
		for my $row (@$df) {
			next unless ref $row eq 'ARRAY';
			$m = scalar @$row if scalar @$row > $m;
		}
		@cols = (0 .. $m - 1);
	} elsif ($shape eq 'HoA') {                  # keys ARE the columns
		@cols = sort keys %$df;
	} else {                                     # AoH / HoH: union of row keys
		my @rows = $shape eq 'AoH' ? @$df : values %$df;
		my %seen;
		for my $row (@rows) {
			next unless ref $row eq 'HASH';
			$seen{$_} = 1 for keys %$row;
		}
		@cols = sort keys %seen;
	}
	return wantarray ? @cols : scalar @cols;
}

sub rownames {
	my ($df) = @_;
	die "rownames: undefined data in first position\n" unless defined $df;
	my $shape = _df_shape($df, 'rownames');
	my @rows;
	if ($shape eq 'HoH') {                        # outer keys ARE the rows
		@rows = sort keys %$df;
	} elsif ($shape eq 'HoA') {                   # longest column -> 0 .. n-1
		my $n = 0;
		for my $v (values %$df) {
			next unless ref $v eq 'ARRAY';
			$n = scalar @$v if scalar @$v > $n;
		}
		@rows = (0 .. $n - 1);
	} else {                                      # AoA / AoH: one row per element
		@rows = (0 .. $#$df);
	}
	return wantarray ? @rows : scalar @rows;
}

# =====================================================================
# The XSUBs _cols_select / _cols_drop / _cols_rename are PRIVATE -- do NOT
# export them.  (See select_drop_rename_cols.xs for the C side.)
#
# NAMING: `select` and `rename` are Perl core builtins, so exporting bare
# `select`/`rename` would shadow them in the caller.  The `_cols` suffix
# avoids that and reads as a trio.
# =====================================================================


# select_cols($df, @cols) | select_cols($df, \@cols)
# drop_cols($df,   @cols) | drop_cols($df,   \@cols)
# rename_cols($df, old => new, ...) | rename_cols($df, { old => new, ... })
#
# Column subset / drop / rename over the four frame shapes -- the Stats::LikeR
# form of pandas df[['a','b']] / df.drop(columns=..) / df.rename(columns=..).
#
#   * AoA  -- identifiers are 0-based integer positions; rename_cols dies
#            (an AoA has no labels; convert to AoH/HoA first).
#   * AoH  -- identifiers are the row-hash keys.
#   * HoA  -- identifiers are the top-level keys (the columns themselves).
#   * HoH  -- identifiers are the inner-row keys.
#
# VIEW SEMANTICS (fast + low RAM).  Every result is a shallow view of the
# source, so huge frames cost almost nothing to slice:
#   * the row shapes (AoH/HoH/AoA) build fresh row containers but SHARE the
#     cell scalars by reference -- no per-cell copy, no duplicate scalar
#     bodies (this is the XS path; see below);
#   * HoA shares the whole column arrayrefs (a pure-Perl alias).
# The operation never mutates the source.  But because cells/columns are
# shared, later IN-PLACE mutation of a result cell (e.g. $r->[0]{a}++) or a
# push/splice on a result HoA column reaches the source.  Assigning a whole
# cell ($r->[0]{a} = ...) is always safe.  Need an independent copy?  Clone
# the result (e.g. Storable::dclone).
#
# IN-PLACE RENAME (rename_cols only).  Called in VOID context, rename_cols
# mutates the source frame in place -- it renames the keys inside each AoH/HoH
# row, or the column keys of a HoA -- and returns nothing.  In ANY other
# context it returns a fresh view (as above) and never touches the source:
#
#     rename_cols(\%d, resolution => 'Resolution (A)'); # void   -> %d in place
#     %d = %{ rename_cols(\%d, resolution => 'Resolution (A)') }; # capture view
#
# (select_cols/drop_cols are always pure and ignore calling context -- a void
# call to either is a no-op.)  Note: `\%d = rename_cols(...)` is not valid Perl
# (a reference constructor is not an lvalue before 5.22 refaliasing); use one
# of the two forms above.
#
# The row shapes are dispatched to XS (_cols_* ), which shares cells and
# hashes each column key once instead of once per row -- ~2x (select), ~3x
# (drop), ~4x (rename) faster than the pure-Perl rebuild at scale, and lower
# peak RAM (no copied cells).  HoA/AoA-by-alias need no XS.  All validation
# stays here in Perl, so the XS never has to croak mid-build.
#
# STRICT: a missing/renamed-away column, a duplicate in a select/drop list,
# or a rename whose targets are not distinct, all die with a labelled message.
# A column present in only some AoH/HoH rows is filled with undef by
# select_cols (rectangular); drop_cols/rename_cols leave ragged frames ragged.

sub _cols_arg {                         # normalise + validate a column list
	my ($fn, @a) = @_;
	my @cols = (@a == 1 && ref $a[0] eq 'ARRAY') ? @{ $a[0] } : @a;
	die "$fn: at least one column is required\n" unless @cols;
	my %seen;
	for my $c (@cols) {
		die "$fn: column identifier is undefined\n" unless defined $c;
		die "$fn: duplicate column '$c' in the list\n" if $seen{$c}++;
	}
	return @cols;
}

sub _aoa_width {                        # widest row of an AoA (ragged-safe)
	my $df = shift;
	my $w = 0;
	for my $r (@$df) { $w = scalar @$r if ref $r eq 'ARRAY' && @$r > $w }
	return $w;
}

sub _aoa_int_cols {                     # validate integer positions in range
	my ($fn, $df, @cols) = @_;
	my $w = _aoa_width($df);
	for my $c (@cols) {
		die "$fn: AoA column '$c' is not a non-negative integer\n"
			unless $c =~ /^\d+$/;
		die "$fn: AoA column index $c out of range (max index " . ($w - 1) . ")\n"
			if $c >= $w;
	}
	return $w;
}

sub _present_keys {                     # union of keys over AoH/HoH rows
	my ($df, $shape) = @_;
	my @rows = $shape eq 'AoH' ? @$df : values %$df;
	my %seen;
	for my $r (@rows) { next unless ref $r eq 'HASH'; $seen{$_} = 1 for keys %$r }
	return \%seen;
}

sub _rename_inplace {                   # VOID-context rename: mutate the source
	my ($df, $shape, $map) = @_;
	if ($shape eq 'HoA') {                          # rename the column keys
		my %vals;                                   # gather-then-set = swap-safe
		for my $o (keys %$map) {
			next unless exists $df->{$o};
			$vals{ $map->{$o} } = delete $df->{$o};
		}
		$df->{$_} = $vals{$_} for keys %vals;
		return;
	}
	my @rows = $shape eq 'AoH' ? @$df : values %$df;    # AoH / HoH row hashes
	for my $row (@rows) {
		next unless ref $row eq 'HASH';
		my %vals;                                   # gather-then-set = swap-safe
		for my $o (keys %$map) {
			next unless exists $row->{$o};
			$vals{ $map->{$o} } = delete $row->{$o};
		}
		$row->{$_} = $vals{$_} for keys %vals;
	}
	return;
}

# shape code passed to the XS: 1 = AoH, 2 = HoH, 3 = AoA
sub select_cols {
	my $df = shift;
	die "select_cols: undefined data in first position\n" unless defined $df;
	my @cols  = _cols_arg('select_cols', @_);
	my $shape = _df_shape($df, 'select_cols');

	if ($shape eq 'HoA') {                          # alias columns (pure Perl)
		for my $c (@cols) {
			die "select_cols: column '$c' not found\n" unless exists $df->{$c};
		}
		my %out;
		$out{$_} = $df->{$_} for @cols;
		return \%out;
	}
	if ($shape eq 'AoA') {
		_aoa_int_cols('select_cols', $df, @cols);
		return _cols_select($df, 3, [ @cols ]);
	}
	my $present = _present_keys($df, $shape);
	for my $c (@cols) {
		die "select_cols: column '$c' not found\n" unless $present->{$c};
	}
	return _cols_select($df, $shape eq 'AoH' ? 1 : 2, [ @cols ]);
}

sub drop_cols {
	my $df = shift;
	die "drop_cols: undefined data in first position\n" unless defined $df;
	my @cols  = _cols_arg('drop_cols', @_);
	my %drop  = map { $_ => 1 } @cols;
	my $shape = _df_shape($df, 'drop_cols');

	if ($shape eq 'HoA') {                          # alias survivors (pure Perl)
		for my $c (@cols) {
			die "drop_cols: column '$c' not found\n" unless exists $df->{$c};
		}
		my %out;
		for my $k (keys %$df) { next if $drop{$k}; $out{$k} = $df->{$k} }
		return \%out;
	}
	if ($shape eq 'AoA') {
		my $w    = _aoa_int_cols('drop_cols', $df, @cols);
		my @keep = grep { !$drop{$_} } 0 .. $w - 1;
		return _cols_select($df, 3, [ @keep ]);     # keep == select the rest
	}
	my $present = _present_keys($df, $shape);
	for my $c (@cols) {
		die "drop_cols: column '$c' not found\n" unless $present->{$c};
	}
	return _cols_drop($df, $shape eq 'AoH' ? 1 : 2, \%drop);
}

sub rename_cols {
	my $df = shift;
	die "rename_cols: undefined data in first position\n" unless defined $df;
	my %map;
	if (@_ == 1 && ref $_[0] eq 'HASH') {
		%map = %{ $_[0] };
	} else {
		die "rename_cols: arguments after the data frame must be old => new pairs (or one hashref)\n"
			if @_ % 2;
		%map = @_;
	}
	die "rename_cols: at least one old => new mapping is required\n" unless %map;
	for my $o (keys %map) {
		die "rename_cols: new name for '$o' is undefined\n" unless defined $map{$o};
	}
	my $shape = _df_shape($df, 'rename_cols');
	die "rename_cols: an AoA has no column names to rename (convert to AoH/HoA first)\n"
		if $shape eq 'AoA';

	my @present = $shape eq 'HoA' ? keys %$df
	                              : keys %{ _present_keys($df, $shape) };
	my %present = map { $_ => 1 } @present;
	for my $o (keys %map) {
		die "rename_cols: column '$o' not found\n" unless $present{$o};
	}
	my %final;                                      # target names stay distinct
	for my $c (@present) {
		my $nn = exists $map{$c} ? $map{$c} : $c;
		die "rename_cols: rename collides -- two columns would both become '$nn'\n"
			if $final{$nn}++;
	}

	# VOID context -> mutate the source in place and return nothing; any other
	# context returns a fresh shallow view exactly as before.
	unless (defined wantarray) {
		_rename_inplace($df, $shape, \%map);
		return;
	}

	if ($shape eq 'HoA') {                          # alias under new keys
		my %out;
		for my $k (keys %$df) {
			my $nk = exists $map{$k} ? $map{$k} : $k;
			$out{$nk} = $df->{$k};
		}
		return \%out;
	}
	return _cols_rename($df, $shape eq 'AoH' ? 1 : 2, \%map);
}

sub aoh2hoh {
	my ($aoh, $key) = @_;
	die 'aoh2hoh: first argument is undefined' unless defined $aoh;
	die 'aoh2hoh: first argument must be an arrayref of hashrefs'
	  unless ref($aoh) eq 'ARRAY';
	die 'aoh2hoh: a row key must be defined' unless defined $key;
	my %out;
	my $i = 0;
	for my $row (@$aoh) {
		die "index $i is not a hash" unless ref($row) eq 'HASH';
		die "index $i has no key \"$key\"" unless defined $row->{$key};
		my $rk = $row->{$key};
		die "aoh2hoh: duplicate key '$rk' has >= 2 occurrences"
			if exists $out{$rk};
		$out{$rk} = { %$row }; # shallow copy of the row
		$i++;
	}
	return \%out;
}
# =======================================================================
# agg / concat / rbind  --  additions to lib/Stats/LikeR.pm
# Splice these in after the dropna sub. Also add  agg concat rbind  to
# @EXPORT_OK. rbind is a true glob-alias synonym for concat.
# =======================================================================

sub _df_shape {
	my ($df, $caller) = @_;
	$caller = 'data frame' unless defined $caller;
	die "$caller: data frame must be an ARRAY (AoA/AoH) or HASH (HoA/HoH) ref\n"
		unless ref $df;
	if (ref $df eq 'ARRAY') {
		for my $e (@$df) {
			next unless defined $e;
			return 'AoA' if ref $e eq 'ARRAY';
			return 'AoH' if ref $e eq 'HASH';
			die "$caller: array elements must be ARRAY (AoA) or HASH (AoH) refs\n";
		}
		return 'AoH';                         # empty -> harmless default
	}
	# HASH: HoA vs HoH, rejecting a mix
	my ($saw_arr, $saw_hash) = (0, 0);
	for my $v (values %$df) {
		next unless ref $v;
		$saw_arr++  if ref $v eq 'ARRAY';
		$saw_hash++ if ref $v eq 'HASH';
	}
	die "$caller: hashref mixes array and hash values (ambiguous HoA/HoH)\n"
		if $saw_arr and $saw_hash;
	return 'HoH' if $saw_hash;
	return 'HoA';                             # arrays, or empty -> default
}

# ---------------------------------------------------------------------------
# agg($df, agg => { col => 'mean' | [ 'mean', 'sd', .. ] | \&code, .. }, %opts)
#
# Split-apply-combine over any of the four data-frame shapes.  With `by` it is
# the combine half of group_by (which only splits); without `by` it collapses
# the whole frame to a single row, like pandas df.agg(...).
#
# $df   : AoA | AoH | HoA | HoH.  For AoA the column identifiers in `by` and in
#         the `agg` spec are integer positions; for the other three they are
#         column names.
#
# OPTIONS
#   agg  => { col => spec, .. }   REQUIRED.  spec is one aggregator name, an
#           arrayref of names, or a coderef.  Named aggregators:
#             mean median sum sd var min max  (numeric; call the XS functions)
#             count    number of defined (non-undef) cells
#             n        number of cells, undef included
#             nunique  number of distinct defined cells
#             first    first defined cell   (undef if none)
#             last     last  defined cell   (undef if none)
#             mode     modal defined cell; ties resolved deterministically
#                      (smallest number, else lowest string)
#           A coderef is called as $code->(\@cells) with every cell for that
#           column in the group (undef included) and must return one scalar.
#   by   => $col | \@cols         optional grouping column(s).
#   skipna => 0|1                 default 1.  When 0, a numeric named aggregator
#           (mean median sum sd var mode) over a group that contains any undef
#           yields undef, matching pandas skipna=False; count/n/nunique/first/
#           last always ignore this flag.
#   sort => 0|1                   default 1.  Sort output groups by key
#           (numeric if every key looks like a number, else string); 0 keeps
#           first-seen order.
#   'output.type' => aoa|aoh|hoa|hoh    default: same family as $df.
#
# OUTPUT COLUMN ORDER is deterministic: the `by` columns in the given order,
# then the aggregated columns sorted (numerically for AoA integer columns, else
# as strings), each expanded over its aggregator list in the order supplied.  A
# column reduced by a single aggregator keeps its own name; with two or more it
# becomes "<col>_<func>" (e.g. age_mean, age_sd).  For hoh output the row label
# is the group value (multiple `by` columns joined with '.'), 'all' when there
# is no grouping, and made unique with a .N suffix on collision.
#
# Numeric aggregators need enough defined cells or the cell is undef: mean /
# median / sum / min / max need >= 1, sd / var need >= 2.  The original $df is
# never modified.
# ---------------------------------------------------------------------------
{
	my %AGG_MIN = (          # minimum defined count for the XS numeric reducers
		mean => 1, median => 1, sum => 1, min => 1, max => 1,
		sd   => 2, var    => 2,
	);
	my %AGG_NUMERIC = map { $_ => 1 } qw(mean median sum sd var mode);

	sub _agg_reduce {
		my ($func, $raw, $def, $skipna) = @_;   # $raw, $def: arrayrefs (def excl. undef)
		return $func->($raw) if ref $func eq 'CODE';
		# NA policy for numeric reducers when the caller asked for skipna => 0
		return undef if !$skipna && $AGG_NUMERIC{$func} && @$def != @$raw;
		if ($func eq 'count')   { return scalar @$def }
		if ($func eq 'n')       { return scalar @$raw }
		if ($func eq 'nunique') { my %s; @s{ @$def } = (); return scalar keys %s }
		if ($func eq 'first')   { return @$def ? $def->[0]  : undef }
		if ($func eq 'last')    { return @$def ? $def->[-1] : undef }
		if ($func eq 'mode') {
			return undef unless @$def;
			my @m = mode($def);
			return (grep { !looks_like_number($_) } @m)
				? (sort @m)[0]
				: (sort { $a <=> $b } @m)[0];
		}
		die "agg: unknown aggregator '$func'\n" unless exists $AGG_MIN{$func};
		return undef if @$def < $AGG_MIN{$func};
		return mean($def)   if $func eq 'mean';
		return median($def) if $func eq 'median';
		return sum($def)    if $func eq 'sum';
		return sd($def)     if $func eq 'sd';
		return var($def)    if $func eq 'var';
		return min($def)    if $func eq 'min';
		return max($def)    if $func eq 'max';
	}

	sub agg {
		my $df = shift;
		die 'agg: undefined data in first position' unless defined $df;
		my $shape = _df_shape($df, 'agg');
		die "agg: arguments after the data frame must be name => value pairs\n"
			if @_ % 2;
		my %arg = @_;
		my %known = ( agg => 1, by => 1, skipna => 1, sort => 1, 'output.type' => 1 );
		my @bad = sort grep { !$known{$_} } keys %arg;
		die "agg: unknown argument(s): @bad\n" if @bad;

		my $spec = $arg{agg};
		die "agg: an 'agg' spec (hashref of column => aggregator) is required\n"
			unless ref $spec eq 'HASH' and %$spec;

		my @by = !defined $arg{by}          ? ()
		       : ref $arg{by} eq 'ARRAY'    ? @{ $arg{by} }
		       :                              ( $arg{by} );
		my $skipna = exists $arg{skipna} ? ($arg{skipna} ? 1 : 0) : 1;
		my $dosort = exists $arg{sort}   ? ($arg{sort}   ? 1 : 0) : 1;
		my $otype  = defined $arg{'output.type'} ? lc $arg{'output.type'}
		           : lc $shape;
		my %ok_otype = ( aoa => 1, aoh => 1, hoa => 1, hoh => 1 );
		die "agg: output.type '$otype' isn't allowed (aoa, aoh, hoa, hoh)\n"
			unless $ok_otype{$otype};

		# columns actually needed (grouping + aggregated), classified once ---
		my @agg_cols = keys %$spec;
		{
			my $all_num = !grep { !looks_like_number($_) } @agg_cols;
			@agg_cols = $all_num ? sort { $a <=> $b } @agg_cols : sort @agg_cols;
		}
		my %need; $need{$_} = 1 for @by, @agg_cols;

		# extract each needed column ONCE, aligned to row positions 0 .. R-1.
		# access is specialised per shape (no per-cell closure); for HoA the
		# columns already are arrays, so they are aliased rather than rebuilt.
		my (%col, $R);
		if ($shape eq 'AoA') {
			my @h = grep { defined } @$df;
			$R = scalar @h;
			for my $c (keys %need) { $col{$c} = [ map { $_->[$c] } @h ] }
		} elsif ($shape eq 'AoH') {
			my @h = grep { defined } @$df;
			$R = scalar @h;
			for my $c (keys %need) { $col{$c} = [ map { $_->{$c} } @h ] }
		} elsif ($shape eq 'HoA') {
			$R = 0;
			for my $v (values %$df) { $R = @$v if ref $v eq 'ARRAY' && @$v > $R }
			for my $c (keys %need) {
				$col{$c} = ref $df->{$c} eq 'ARRAY' ? $df->{$c} : [];
			}
		} else { # HoH
			my @h = map { $df->{$_} } sort keys %$df;
			$R = scalar @h;
			for my $c (keys %need) { $col{$c} = [ map { $_->{$c} } @h ] }
		}

		# split row indices into groups, preserving first-seen order --------
		my (%group, @order, %repr);
		my $one = @by == 1 ? $by[0] : undef;   # single-key fast path
		for (my $i = 0; $i < $R; $i++) {
			my $key;
			if (!@by) {
				$key = "\0all";
			} elsif (defined $one) {
				my $v = $col{$one}[$i];
				$key = defined $v ? "v$v" : "\0";
			} else {
				$key = join "\x1e",
					map { my $v = $col{$_}[$i]; defined $v ? "v$v" : "\0" } @by;
			}
			my $g = $group{$key};
			unless ($g) {
				$group{$key} = $g = [];
				push @order, $key;
				$repr{$key} = [ map { $col{$_}[$i] } @by ];
			}
			push @$g, $i;
		}
		if ($dosort && @by) {                  # sort by the group value(s)
			my $all_num = 1;
			SORTNUM: for my $k (@order) {
				for my $v (@{ $repr{$k} }) {
					unless (defined $v && looks_like_number($v)) { $all_num = 0; last SORTNUM }
				}
			}
			if ($all_num) {
				@order = sort {
					my ($ra, $rb) = ($repr{$a}, $repr{$b});
					my $c = 0;
					for my $j (0 .. $#$ra) { last if $c = $ra->[$j] <=> $rb->[$j] }
					$c;
				} @order;
			} else {
				@order = sort {
					my ($ra, $rb) = ($repr{$a}, $repr{$b});
					my $c = 0;
					for my $j (0 .. $#$ra) {
						my $x = defined $ra->[$j] ? $ra->[$j] : '';
						my $y = defined $rb->[$j] ? $rb->[$j] : '';
						last if $c = $x cmp $y;
					}
					$c;
				} @order;
			}
		}

# output plan: by-columns pass through, then each agg column with its
# aggregator list contiguous.  A single aggregator keeps the column
# name; two or more become "<col>_<func>".
		my @agg_plan; # [ col, [funcs], [out_names] ]
		for my $c (@agg_cols) {
			my $s = $spec->{$c};
			my @funcs = ref $s eq 'ARRAY' ? @$s : ($s);
			die "agg: empty aggregator list for column '$c'\n" unless @funcs;
			my $multi = @funcs > 1;
			my @names = map {
				my $l = ref $_ eq 'CODE' ? 'fn' : $_;
				$multi ? "${c}_${l}" : $c;
			} @funcs;
			push @agg_plan, [ $c, \@funcs, \@names ];
		}
		my @out_names = ( @by, map { @{ $_->[2] } } @agg_plan );

# combine + materialise straight into the requested shape -----------
		my (@aoa_rows, @aoh_rows, %hoa, %hoh, %seen);
		if ($otype eq 'hoa') { $hoa{$_} = [] for @out_names }

		for my $key (@order) {
			my $idx = $group{$key};
			my @vals = @{ $repr{$key} };            # by-column values, in order
			for my $ap (@agg_plan) {
				my ($c, $funcs, undef) = @$ap;
				my @raw = @{ $col{$c} }[ @$idx ];   # one slice, shared by all funcs
				my @def = grep { defined } @raw;
				push @vals, _agg_reduce($_, \@raw, \@def, $skipna) for @$funcs;
			}
			if ($otype eq 'aoa') {
				push @aoa_rows, \@vals;
			} elsif ($otype eq 'aoh') {
				my %h; @h{ @out_names } = @vals; push @aoh_rows, \%h;
			} elsif ($otype eq 'hoa') {
				push @{ $hoa{ $out_names[$_] } }, $vals[$_] for 0 .. $#out_names;
			} else { # hoh
				my $label = @by
					? join('.', map { defined $_ ? $_ : '' } @{ $repr{$key} })
					: 'all';
				my $uniq = $label; my $j = 0;
				while (exists $seen{$uniq}) { $uniq = $label . '.' . (++$j) }
				$seen{$uniq} = 1;
				my %h; @h{ @out_names } = @vals; $hoh{$uniq} = \%h;
			}
		}
		return \@aoa_rows if $otype eq 'aoa';
		return \@aoh_rows if $otype eq 'aoh';
		return \%hoa      if $otype eq 'hoa';
		return \%hoh;
	}
}


# assign($df, name => \&code, name2 => \&code2, ...)
#
# Add (or overwrite) columns derived from existing ones, dplyr-mutate style.
# Each coderef is called once per row with the row as $_ (a hashref) and also
# as $_[0]; $_[1] is the 0-based row index. For HoH inputs, $_[2] is the row key.
# It returns the new cell value.
#
# Works on all three data-frame shapes:
#   AoH  [ {weight=>70, height=>1.8}, ... ]        (arrayref of row hashrefs)
#   HoA  { weight=>[70,...], height=>[1.8,...] }   (hashref of column arrayrefs)
#   HoH  { r1 => {weight=>70}, r2 => {...} }       (hashref of row hashrefs)
#
# Pairs are applied in order, so a later column may use an earlier new one.
# Modifies $df in place (lowest RAM/CPU) and returns it for chaining.
# To keep the original intact, hand it a copy: assign(clone($df), ...).
#
# A value may also be a map_cell { ... } block (see below) for an in-place
# per-cell edit of the named column, instead of a CODE ref or ready-made ARRAY.
#

# ---------------------------------------------------------------------------
# map_cell { ... }   -- in-place per-cell transform for assign().
#
# Wraps a block so assign() runs it once per row with $_ aliased to a copy of
# the NAMED column's current cell; the (possibly modified) $_ is stored back and
# the block's return value is ignored.  This makes an in-place edit read
# naturally, without the "copy, substitute, return" dance a plain sub needs
# (perl 5.10 has no s///r):
#
#   assign($tbl, 'Res.' => map_cell { s/^[A-Z]:// });   # strip a leading "X:"
#   assign($tbl, 'Res.' => map_cell { $_ = uc });        # upper-case in place
#
# The row is still available as $_[0] (and the index as $_[1]) if the transform
# needs a sibling column.  A plain sub { ... } keeps its existing meaning
# ($_ = the whole row, the return value is stored), so map_cell is purely
# additive and changes nothing for existing callers.
#
# An undef cell is left untouched (undef in -> undef out): the block never runs
# on it, so s/// and friends don't warn on uninitialized values and a missing
# cell stays missing rather than becoming ''.
# ---------------------------------------------------------------------------
sub map_cell (&) {
	my ($code) = @_;
	die "map_cell: expects a code block, e.g. map_cell { s/x//g }\n"
		unless ref $code eq 'CODE';
	return bless { code => $code }, 'Stats::LikeR::map_cell';
}

sub assign {
	my $df = shift;
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	die "$current_sub: first argument is undefined" unless defined $df;
	die "$current_sub: first argument must be a data frame (AoH arrayref or HoA/HoH hashref)"
		unless ref $df;
	die "$current_sub: expected an even list of (name => value) pairs" if @_ % 2;

	my $r = ref $df;

	# Each value is CODE (per-row scalar OR whole-column list) or ARRAY (ready column).
	# CODE is probed once in list context: >1 return value => whole column.

	if ($r eq 'ARRAY') {                            # ----- AoH -----
		my $n = @$df;
		while (@_) {
			my ($name, $spec) = (shift, shift);
			my $sref = ref $spec;
			if ($sref eq 'Stats::LikeR::map_cell') {   # in-place per-cell edit; $_ = current cell
				my $code = $spec->{code};
				for my $i (0 .. $n - 1) {
					my $row = $df->[$i];
					die "$current_sub: row $i is not a hashref" unless ref $row eq 'HASH';
					local $_ = $row->{$name};
					next unless defined $_;   # undef cells pass through untouched (undef in -> undef out)
					$code->($row, $i);
					$row->{$name} = $_;
				}
				next;
			}
			die "$current_sub: value for '$name' must be a CODE or ARRAY ref"
				unless $sref eq 'CODE' or $sref eq 'ARRAY';

			if ($sref eq 'ARRAY') {                 # ready-made column
				die "$current_sub: column '$name' has " . @$spec . " values but data frame has $n rows"
					unless @$spec == $n;
				for my $i (0 .. $n - 1) {
					die "$current_sub: row $i is not a hashref" unless ref $df->[$i] eq 'HASH';
					$df->[$i]{$name} = $spec->[$i];
				}
				next;
			}

			next unless $n;                         # empty AoH: nothing to compute

			my $row0 = $df->[0];
			die "$current_sub: row 0 is not a hashref" unless ref $row0 eq 'HASH';
			my @out;
			{
				local $_ = $row0;
				@out = $spec->($row0, 0);
			}
			if (@out > 1) {                         # whole-column list (e.g. rank())
				die "$current_sub: column '$name' produced " . @out . " values but data frame has $n rows"
					unless @out == $n;
				for my $i (0 .. $n - 1) {
					die "$current_sub: row $i is not a hashref" unless ref $df->[$i] eq 'HASH';
					$df->[$i]{$name} = $out[$i];
				}
				next;
			}
			$row0->{$name} = $out[0];               # per-row: row 0 already computed
			for my $i (1 .. $n - 1) {
				my $row = $df->[$i];
				die "$current_sub: row $i is not a hashref" unless ref $row eq 'HASH';
				local $_ = $row;
				$row->{$name} = $spec->($row, $i);
			}
		}
		return $df;
	}

	if ($r eq 'HASH') {
		my $is_hoh = 0;
		for my $v (values %$df) {
			my $ref = ref $v;
			if    ($ref eq 'HASH')  { $is_hoh = 1; last }
			elsif ($ref eq 'ARRAY') { $is_hoh = 0; last }
			else { die "$current_sub: value is a \"$ref\" which is neither a HASH nor an ARRAY" }
		}

		if ($is_hoh) {                              # ----- HoH -----
			my @rk = sort keys %$df;
			my $n  = @rk;
			while (@_) {
				my ($name, $spec) = (shift, shift);
				my $sref = ref $spec;
				if ($sref eq 'Stats::LikeR::map_cell') {   # in-place per-cell edit; $_ = current cell
					my $code = $spec->{code};
					for my $i (0 .. $n - 1) {
						my $row = $df->{ $rk[$i] };
						die "$current_sub: row '$rk[$i]' is not a hashref" unless ref $row eq 'HASH';
						local $_ = $row->{$name};
						next unless defined $_;   # undef cells pass through untouched (undef in -> undef out)
						$code->($row, $i, $rk[$i]);
						$row->{$name} = $_;
					}
					next;
				}
				die "$current_sub: value for '$name' must be a CODE or ARRAY ref"
					unless $sref eq 'CODE' or $sref eq 'ARRAY';

				if ($sref eq 'ARRAY') {
					die "$current_sub: column '$name' has " . @$spec . " values but data frame has $n rows"
						unless @$spec == $n;
					for my $i (0 .. $n - 1) {
						my $row = $df->{ $rk[$i] };
						die "$current_sub: row '$rk[$i]' is not a hashref" unless ref $row eq 'HASH';
						$row->{$name} = $spec->[$i];
					}
					next;
				}

				next unless $n;

				my $row0 = $df->{ $rk[0] };
				die "$current_sub: row '$rk[0]' is not a hashref" unless ref $row0 eq 'HASH';
				my @out;
				{
					local $_ = $row0;
					@out = $spec->($row0, 0, $rk[0]);
				}
				if (@out > 1) {
					die "$current_sub: column '$name' produced " . @out . " values but data frame has $n rows"
						unless @out == $n;
					for my $i (0 .. $n - 1) {
						my $row = $df->{ $rk[$i] };
						die "$current_sub: row '$rk[$i]' is not a hashref" unless ref $row eq 'HASH';
						$row->{$name} = $out[$i];
					}
					next;
				}
				$row0->{$name} = $out[0];
				for my $i (1 .. $n - 1) {
					my $row = $df->{ $rk[$i] };
					die "$current_sub: row '$rk[$i]' is not a hashref" unless ref $row eq 'HASH';
					local $_ = $row;
					$row->{$name} = $spec->($row, $i, $rk[$i]);
				}
			}
			return $df;
		}
		else {                                      # ----- HoA -----
			my $n = 0;
			for my $v (values %$df) {
				$n = @$v if ref $v eq 'ARRAY' and @$v > $n;
			}
			while (@_) {
				my ($name, $spec) = (shift, shift);
				my $sref = ref $spec;
				if ($sref eq 'Stats::LikeR::map_cell') {   # in-place per-cell edit; $_ = current cell
					my $code = $spec->{code};
					my $tgt  = $df->{$name};
					die "$current_sub: map_cell target column '$name' must already exist as an ARRAY ref\n"
						unless ref $tgt eq 'ARRAY';
					my @keys = keys %$df;
					my @col  = map { my $c = $df->{$_}; ref $c eq 'ARRAY' ? $c : undef } @keys;
					for my $i (0 .. $n - 1) {
						my %view;
						$view{ $keys[$_] } = defined $col[$_] ? $col[$_][$i] : $df->{ $keys[$_] }
							for 0 .. $#keys;
						local $_ = $tgt->[$i];
						next unless defined $_;   # undef cells pass through untouched (undef in -> undef out)
						$code->(\%view, $i);
						$tgt->[$i] = $_;
					}
					next;
				}
				die "$current_sub: value for '$name' must be a CODE or ARRAY ref"
					unless $sref eq 'CODE' or $sref eq 'ARRAY';

				if ($sref eq 'ARRAY') {
					die "$current_sub: column '$name' has " . @$spec . " values but data frame has $n rows"
						unless @$spec == $n;
					$df->{$name} = [ @$spec ];
					next;
				}

				if (not $n) { $df->{$name} = []; next }

				# snapshot current columns once (refs, not data)
				my @keys = keys %$df;
				my @col  = map { my $c = $df->{$_}; ref $c eq 'ARRAY' ? $c : undef } @keys;
				my $view_for = sub {
					my $i = shift;
					my %view;
					$view{ $keys[$_] } = defined $col[$_] ? $col[$_][$i] : $df->{ $keys[$_] }
						for 0 .. $#keys;
					return \%view;
				};

				my $v0 = $view_for->(0);
				my @out;
				{
					local $_ = $v0;
					@out = $spec->($v0, 0);
				}
				if (@out > 1) {                     # whole-column list
					die "$current_sub: column '$name' produced " . @out . " values but data frame has $n rows"
						unless @out == $n;
					$df->{$name} = [ @out ];
					next;
				}
				my @new;
				$#new = $n - 1;                     # preallocate
				$new[0] = $out[0];
				for (my $i = 1; $i < $n; $i++) {
					my $view = $view_for->($i);
					local $_ = $view;
					$new[$i] = $spec->($view, $i);
				}
				$df->{$name} = \@new;
			}
			return $df;
		}
	}
	die "$current_sub: data frame must be an arrayref (AoH) or hashref (HoA/HoH)";
}

sub chunk {
	my ($aref, %opt) = @_;
	die "chunk: first argument must be an ARRAY reference\n"
		unless ref $aref eq 'ARRAY';

	die "chunk: pass exactly one of size => N or parts => K\n"
		if  (defined $opt{size} && defined $opt{parts})
		||  (!defined $opt{size} && !defined $opt{parts});

	my $n = scalar @$aref;
	return () unless $n; # empty input -> no groups

	my @groups;
	if (defined $opt{size}) {
		my $sz = $opt{size};
		die "chunk: size must be a positive integer\n"
			unless $sz =~ /\A[1-9][0-9]*\z/;
		for (my $i = 0; $i < $n; $i += $sz) {
			my $hi = $i + $sz - 1;
			$hi = $n - 1 if $hi > $n - 1;
			push @groups, [ @{$aref}[$i .. $hi] ];
		}
	} else {
		my $k = $opt{parts};
		die "chunk: parts must be a positive integer\n"
			unless $k =~ /\A[1-9][0-9]*\z/;
		for my $i (0 .. $k - 1) {
			my $lo = int( $i       * $n / $k );
			my $hi = int( ($i + 1) * $n / $k );
			push @groups, [ @{$aref}[$lo .. $hi - 1] ];
		}
	}
	return @groups;
}

# ---- filter DSL: col() builds a predicate via overloading (pure Perl) -------
# col('name') returns an overloaded object; comparing it (col('age') >= 18) or
# combining comparisons with & | ! builds a predicate that carries its per-row
# test in a {code} closure. filter() (XS) unwraps that closure, so col() and a
# plain coderef share one evaluation path -- no XS evaluator, no Carp.
#
# Rules: numeric ops > < >= <= == != compare as numbers; string ops gt lt ge le
# eq ne compare as strings; & | ! combine; operands may be in either order; a
# missing/undef cell (and, for numeric ops, a non-numeric cell) never matches.
sub col { Stats::LikeR::col::_new(@_) }
{
	package Stats::LikeR::col;
	use warnings;
	use Scalar::Util qw(blessed looks_like_number);
	use overload
		'>'	 => sub { _num($_[0], '>',	$_[1], $_[2]) },
		'<'	 => sub { _num($_[0], '<',	$_[1], $_[2]) },
		'>=' => sub { _num($_[0], '>=', $_[1], $_[2]) },
		'<=' => sub { _num($_[0], '<=', $_[1], $_[2]) },
		'==' => sub { _num($_[0], '==', $_[1], $_[2]) },
		'!=' => sub { _num($_[0], '!=', $_[1], $_[2]) },
		'gt' => sub { _str($_[0], 'gt', $_[1], $_[2]) },
		'lt' => sub { _str($_[0], 'lt', $_[1], $_[2]) },
		'ge' => sub { _str($_[0], 'ge', $_[1], $_[2]) },
		'le' => sub { _str($_[0], 'le', $_[1], $_[2]) },
		'eq' => sub { _str($_[0], 'eq', $_[1], $_[2]) },
		'ne' => sub { _str($_[0], 'ne', $_[1], $_[2]) },
		'&'	 => sub { _logic($_[0], '&', $_[1]) },
		'|'	 => sub { _logic($_[0], '|', $_[1]) },
		'!'	 => sub { _not($_[0]) },
		'""'   => sub { 'Stats::LikeR::col predicate' },
		'bool' => sub { 1 },
		fallback => 0;

	sub _new {
		my ($name) = @_;
		die "col(): expects a single column name\n" if !defined($name) || ref $name;
		return bless { name => $name }, __PACKAGE__;
	}

	my %NUM = (
		'>'	 => sub { $_[0] >  $_[1] }, '<'	 => sub { $_[0] <  $_[1] },
		'>=' => sub { $_[0] >= $_[1] }, '<=' => sub { $_[0] <= $_[1] },
		'==' => sub { $_[0] == $_[1] }, '!=' => sub { $_[0] != $_[1] },
	);
	my %STR = (
		'gt' => sub { $_[0] gt $_[1] }, 'lt' => sub { $_[0] lt $_[1] },
		'ge' => sub { $_[0] ge $_[1] }, 'le' => sub { $_[0] le $_[1] },
		'eq' => sub { $_[0] eq $_[1] }, 'ne' => sub { $_[0] ne $_[1] },
	);

	# numeric comparison: undef OR non-numeric cells never match
	sub _num {
		my ($self, $op, $other, $swap) = @_;
		my $name = $self->{name};
		die "col(): the '$op' comparison must start from a bare column, e.g. col('x') $op ...\n"
			unless defined $name;
		my $f = $NUM{$op};
		my $code = $swap
			? sub { my $c = $_[0]{$name}; (defined($c) && looks_like_number($c)) ? ($f->($other, $c) ? 1 : 0) : 0 }
			: sub { my $c = $_[0]{$name}; (defined($c) && looks_like_number($c)) ? ($f->($c, $other) ? 1 : 0) : 0 };
		return bless { code => $code }, __PACKAGE__;
	}

	# string comparison: undef cells never match
	sub _str {
		my ($self, $op, $other, $swap) = @_;
		my $name = $self->{name};
		die "col(): the '$op' comparison must start from a bare column, e.g. col('x') $op ...\n"
			unless defined $name;
		my $f = $STR{$op};
		my $code = $swap
			? sub { my $c = $_[0]{$name}; defined($c) ? ($f->($other, $c) ? 1 : 0) : 0 }
			: sub { my $c = $_[0]{$name}; defined($c) ? ($f->($c, $other) ? 1 : 0) : 0 };
		return bless { code => $code }, __PACKAGE__;
	}

	sub _logic {
		my ($self, $op, $other) = @_;
		my $lc = $self->{code};
		die "col(): the left operand of '$op' is not a comparison (build it like (col('x') > 0))\n"
			unless ref $lc eq 'CODE';
		my $rc = (blessed($other) && $other->isa(__PACKAGE__)) ? $other->{code} : undef;
		die "col(): the right operand of '$op' must be a col() comparison too\n"
			unless ref $rc eq 'CODE';
		my $code = $op eq '&'
			? sub { ($lc->($_[0]) && $rc->($_[0])) ? 1 : 0 }
			: sub { ($lc->($_[0]) || $rc->($_[0])) ? 1 : 0 };
		return bless { code => $code }, __PACKAGE__;
	}

	sub _not {
		my ($self) = @_;
		my $c = $self->{code};
		die "col(): the operand of '!' is not a comparison (build it like !(col('x') > 0))\n"
			unless ref $c eq 'CODE';
		return bless { code => sub { $c->($_[0]) ? 0 : 1 } }, __PACKAGE__;
	}

	# regex predicates.  Perl cannot overload =~, so col('x') =~ /re/ can never
	# be intercepted; these methods give the same deferred, composable predicate
	# instead.  The pattern is a qr// or a string (compiled with qr//); an undef
	# cell never matches (mirroring the string comparisons).
	#   filter($df, col('id')->match(qr/^5iz/));
	#   filter($df, col('id')->nomatch('^5iz'));            # string pattern ok
	#   filter($df, col('id')->match(qr/^5iz/) & (col('res') < 2.5));
	sub _match {
		my ($self, $re, $want, $how) = @_;
		die "col(): ->$how must start from a bare column, e.g. col('x')->$how(qr/.../)\n"
			unless defined $self->{name};
		die "col(): ->$how needs a pattern (a qr// or a string)\n" unless defined $re;
		my $qr   = ref $re eq 'Regexp' ? $re : qr/$re/;
		my $name = $self->{name};
		my $code = sub {
			my $c = $_[0]{$name};
			return 0 unless defined $c;
			return ( ($c =~ $qr) ? 1 : 0 ) == $want ? 1 : 0;
		};
		return bless { code => $code }, __PACKAGE__;
	}
	sub match   { _match($_[0], $_[1], 1, 'match') }
	sub nomatch { _match($_[0], $_[1], 0, 'nomatch') }
}

# ---------------------------------------------------------------------------
# concat(@frames)   /   rbind(@frames)   -- row-bind data frames (pandas concat
# axis=0, R rbind).  rbind is a true synonym (same subroutine).
#
# Every frame must be the same shape (AoA/AoH/HoA/HoH); a mix dies with a hint
# to convert first (aoh2hoa, hoa2aoh, hoh2hoa, aoh2hoh).  undef frames and
# empty frames are skipped, and shape is taken from the first non-empty frame;
# passing nothing usable dies.  A NEW top-level frame of that shape is returned;
# the original frames are never modified.
#
#   AoA  outer arrays concatenated in order (row arrayrefs reused by ref).
#        Ragged rows are kept as-is; a short row reads undef past its end.
#   AoH  rows concatenated in order (row hashrefs reused by ref).  The result is
#        the union of columns; a column absent from a given row reads undef,
#        matching this library's "missing key == undef" convention (dropna,
#        view, summary).
#   HoA  union of columns (sorted for a deterministic layout).  Each column is
#        the per-frame arrays joined in frame order; a frame lacking a column,
#        or a ragged short column, is padded with undef so every column ends up
#        the same length (= total rows).
#   HoH  outer hashes merged in frame order (inner row hashrefs reused by ref).
#        Because a Perl hash cannot hold duplicate keys, a repeated row name is
#        made unique R-style (name, name.1, name.2, ...) and a single warning is
#        emitted noting that row names collided.
# ---------------------------------------------------------------------------
sub concat {
	my @frames = grep { defined } @_;
	die "concat: needs at least one data frame\n" unless @frames;

	# reference shape = first non-empty frame; remember a fallback for all-empty
	my $ref_shape;
	for my $f (@frames) {
		my $nonempty = ref $f eq 'ARRAY' ? scalar(@$f)
		             : ref $f eq 'HASH'  ? scalar(keys %$f)
		             : die "concat: every frame must be an ARRAY or HASH ref\n";
		next unless $nonempty;
		$ref_shape = _df_shape($f, 'concat');
		last;
	}
	unless (defined $ref_shape) {           # all frames empty
		return ref $frames[0] eq 'ARRAY' ? [] : {};
	}
	# all non-empty frames must agree
	for my $f (@frames) {
		my $nonempty = ref $f eq 'ARRAY' ? scalar(@$f) : scalar(keys %$f);
		next unless $nonempty;
		my $s = _df_shape($f, 'concat');
		die "concat: cannot mix a $s frame with a $ref_shape frame; "
		  . "convert them to one shape first (aoh2hoa, hoa2aoh, hoh2hoa, aoh2hoh)\n"
			if $s ne $ref_shape;
	}

	if ($ref_shape eq 'AoA') {
		my @out;
		for my $f (@frames) {
			for my $row (@$f) {
				die "concat: AoA row is not an ARRAY ref\n" unless ref $row eq 'ARRAY';
				push @out, $row;
			}
		}
		return \@out;
	}
	if ($ref_shape eq 'AoH') {
		my @out;
		for my $f (@frames) {
			for my $row (@$f) {
				die "concat: AoH row is not a HASH ref\n" unless ref $row eq 'HASH';
				push @out, $row;
			}
		}
		return \@out;
	}
	if ($ref_shape eq 'HoA') {
		my (@cols, %seen);                  # union of columns, sorted
		for my $f (@frames) { $seen{$_} = 1 for keys %$f }
		@cols = sort keys %seen;
		my %out = map { $_ => [] } @cols;
		for my $f (@frames) {
			my $n = 0;
			for my $c (keys %$f) {
				$n = @{ $f->{$c} } if ref $f->{$c} eq 'ARRAY' && @{ $f->{$c} } > $n;
			}
			for my $c (@cols) {
				if (ref $f->{$c} eq 'ARRAY') {
					push @{ $out{$c} }, @{ $f->{$c} };
					push @{ $out{$c} }, (undef) x ($n - @{ $f->{$c} })
						if @{ $f->{$c} } < $n;   # ragged short column
				} else {
					push @{ $out{$c} }, (undef) x $n; # column absent in this frame
				}
			}
		}
		return \%out;
	}
	# HoH
	my (%out, $collided);
	for my $f (@frames) {
		for my $rk (sort keys %$f) {
			die "concat: HoH row '$rk' is not a HASH ref\n"
				unless ref $f->{$rk} eq 'HASH';
			my $label = $rk;
			my $j = 0;
			while (exists $out{$label}) { $collided = 1; $label = $rk . '.' . (++$j) }
			$out{$label} = $f->{$rk};       # reuse the row ref
		}
	}
	warn "concat: duplicate HoH row name(s) made unique with a .N suffix\n"
		if $collided;
	return \%out;
}
{ no warnings 'once'; *rbind = \&concat; }  # true synonym
#
# dropna($df, cols => \@cols, how => 'any'|'all')	# NA mode
# dropna($df, rows => \@rows)						 # literal deletion
#
# $df may be:
#	AoH	 [ { A=>.., B=>.. }, ... ]			rows are 0-based indices
#	HoA	 { A=>[..], B=>[..] }				rows are 0-based indices
#	HoH	 { r1=>{ A=>.. }, r2=>{ .. } }		rows are the outer keys
#
# cols mode (NA): inspect the named columns and drop the rows that are undef
#	in them. how => 'any' (default) drops a row when any named column is undef;
#	how => 'all' drops it only when every named column is undef. Columns that
#	are not named are untouched but stay aligned (their cell at a dropped index
#	goes too). A missing key counts as undef.
#
# rows mode: delete exactly the listed rows (indices for AoH/HoA, keys for HoH);
#	no NA check. Indices/keys that aren't present are ignored.
#
# Returns a NEW top-level data frame; the original is never modified. For HoA
# the column arrays are rebuilt (cell values copied); for AoH/HoH the surviving
# row references are reused, not deep-copied (dropna never mutates a row).
#
sub dropna {
	my $df = shift;
	die 'dropna: first argument is undefined' unless defined $df;
	die "dropna: first argument must be a data frame (HoA/HoH hashref or AoH arrayref)\n"
		unless ref $df;
	die "dropna: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;

	my %known = ( cols => 1, rows => 1, how => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "dropna: unknown argument(s): @bad\n" if @bad;

	my $have_cols = exists $arg{cols};
	my $have_rows = exists $arg{rows};
	die "dropna: pass exactly one of 'cols' or 'rows'\n"
		unless $have_cols xor $have_rows;

	my $sel = $have_cols ? $arg{cols} : $arg{rows};
	die "dropna: '" . ($have_cols ? 'cols' : 'rows') . "' must be an arrayref\n"
		unless ref $sel eq 'ARRAY';

	my $how = defined $arg{how} ? lc $arg{how} : 'any';
	die "dropna: 'how' must be 'any' or 'all'\n"
		unless $how eq 'any' or $how eq 'all';

	my $r = ref $df;

	#----- AoH -----
	if ($r eq 'ARRAY') {
		if ($have_rows) {						# literal index deletion
			my %drop = map { $_ => 1 } @$sel;
			return [ map { $df->[$_] } grep { !$drop{$_} } 0 .. $#$df ];
		}
		my @cols = @$sel;
		return [ @$df ] unless @cols;			# nothing to check -> keep all
		return [] unless @$df;				# empty frame -> empty result
		my %seen;
		for my $row (@$df) {
			next unless ref $row eq 'HASH';
			$seen{$_} = 1 for keys %$row;
		}
		for my $c (@cols) {
			die "dropna: column '$c' not found\n" unless $seen{$c};
		}
		my @keep;
		for my $i (0 .. $#$df) {
			my $row = $df->[$i];
			my $nundef = (ref $row eq 'HASH')
				? (grep { !defined $row->{$_} } @cols)
				: @cols;						# malformed row counts as all-NA
			my $drop = $how eq 'any' ? $nundef > 0 : $nundef == @cols;
			push @keep, $i unless $drop;
		}
		return [ map { $df->[$_] } @keep ];
	}

	#----- HoA vs HoH -----
	if ($r eq 'HASH') {
		my ($saw_arr, $saw_hash) = (0, 0);
		for my $v (values %$df) {
			next unless ref $v;
			$saw_arr++	if ref $v eq 'ARRAY';
			$saw_hash++ if ref $v eq 'HASH';
		}
		die "dropna: hashref mixes array and hash values (ambiguous HoA/HoH)\n"
			if $saw_arr and $saw_hash;

		#----- HoH -----
		if ($saw_hash) {
			if ($have_rows) {					# delete row keys
				my %drop = map { $_ => 1 } @$sel;
				return { map { $_ => $df->{$_} } grep { !$drop{$_} } keys %$df };
			}
			my @cols = @$sel;
			return { %$df } unless @cols;
			my %out;
			for my $rk (keys %$df) {
				my $row = $df->{$rk};
				my $nundef = (ref $row eq 'HASH')
					? (grep { !defined $row->{$_} } @cols)
					: @cols;
				my $drop = $how eq 'any' ? $nundef > 0 : $nundef == @cols;
				$out{$rk} = $row unless $drop;
			}
			return \%out;
		}

		#----- HoA (also the empty-hash fallthrough) -----
		my $n = 0;
		for my $v (values %$df) {
			$n = @$v if ref $v eq 'ARRAY' and @$v > $n;
		}
		if ($have_rows) {						# delete indices
			my %drop = map { $_ => 1 } @$sel;
			my @keep = grep { !$drop{$_} } 0 .. $n - 1;
			return { map { $_ => [ @{ $df->{$_} }[@keep] ] } keys %$df };
		}
		my @cols = @$sel;
		return { map { $_ => [ @{ $df->{$_} } ] } keys %$df } unless @cols;
		for my $c (@cols) {
			die "dropna: column '$c' not found\n" unless exists $df->{$c};
		}
		my @keep;
		for my $i (0 .. $n - 1) {
			my $nundef = grep { !defined $df->{$_}[$i] } @cols;
			my $drop = $how eq 'any' ? $nundef > 0 : $nundef == @cols;
			push @keep, $i unless $drop;
		}
		return { map { $_ => [ @{ $df->{$_} }[@keep] ] } keys %$df };
	}

	die "dropna: data frame must be an arrayref (AoH) or hashref (HoA/HoH)\n";
}

# drop_duplicates($df, subset => $col | \@cols, keep => 'first' | 'last' | 0)
#
# Remove duplicate rows, loosely modeled on pandas' DataFrame.drop_duplicates.
# Works on the three positional/columnar shapes -- AoA, AoH, HoA -- but NOT
# HoH (its rows are labeled, so "drop_duplicates" has no natural meaning; call
# hoh2aoh/hoh2hoa first).  Two rows are duplicates when their cells are equal
# in every subset column; comparison is by stringified value with a distinct
# undef (NA), exactly the key semantics merge() uses, so 1 and "1.0" differ.
#
#   subset  scalar or arrayref of the columns that define a row's identity;
#           default every column.  For AoA these are 0-based integer positions
#           (default 0 .. widest-row-1); for AoH/HoA they are column names
#           (AoH default: the sorted union of row keys; HoA: the sorted keys).
#   keep    which occurrence to keep: 'first' (default) keeps the earliest,
#           'last' the latest, 0 (or 'none') drops every row that has a dup.
#
# Row order is preserved (first-seen positions for the survivors).  Returns a
# NEW top-level frame of the same family; the original is never modified.  For
# AoA/AoH the surviving row refs are reused (cells shared, not deep-copied);
# for HoA the columns are rebuilt with the surviving cells copied.
sub drop_duplicates {
	my $df = shift;
	die "drop_duplicates: undefined data in first position\n" unless defined $df;
	die "drop_duplicates: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( subset => 1, keep => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "drop_duplicates: unknown argument(s): @bad\n" if @bad;

	my $shape = _df_shape($df, 'drop_duplicates');
	die "drop_duplicates: an HoH data frame is not supported (convert to AoH/HoA/AoA first)\n"
		if $shape eq 'HoH';

	# keep -> code: 1 = first, -1 = last, 0 = drop every duplicate
	my $keep = exists $arg{keep} ? $arg{keep} : 'first';
	die "drop_duplicates: 'keep' is undefined (use 'first', 'last', or 0)\n"
		unless defined $keep;
	my $kc;
	if    ($keep eq 'first') { $kc =  1 }
	elsif ($keep eq 'last')  { $kc = -1 }
	elsif ($keep eq 'none' || $keep eq '' || (looks_like_number($keep) && $keep == 0)) { $kc = 0 }
	else  { die "drop_duplicates: 'keep' must be 'first', 'last', or 0 (got '$keep')\n" }

	# subset -> ordered column list
	my @sub;
	if (exists $arg{subset} && defined $arg{subset}) {
		my $s = $arg{subset};
		if    (ref $s eq 'ARRAY') { @sub = @$s }
		elsif (!ref $s)           { @sub = ($s) }
		else { die "drop_duplicates: 'subset' must be a column or an arrayref of columns\n" }
		die "drop_duplicates: 'subset' is empty\n" unless @sub;
		my %seen;
		for my $c (@sub) {
			die "drop_duplicates: undefined column in 'subset'\n" unless defined $c;
			die "drop_duplicates: duplicate column '$c' in 'subset'\n" if $seen{$c}++;
		}
	}

	if ($shape eq 'AoA') {
		if (@sub) { _aoa_int_cols('drop_duplicates', $df, @sub) }
		else      { @sub = (0 .. _aoa_width($df) - 1) }
		return _drop_dups_core($df, 3, [ @sub ], $kc);
	}
	if ($shape eq 'AoH') {
		my $present = _present_keys($df, 'AoH');
		if (@sub) {
			for my $c (@sub) {
				die "drop_duplicates: column '$c' not found\n" unless $present->{$c};
			}
		} else {
			@sub = sort keys %$present;
		}
		return _drop_dups_core($df, 1, [ @sub ], $kc);
	}
	# HoA
	if (@sub) {
		for my $c (@sub) {
			die "drop_duplicates: column '$c' not found\n" unless exists $df->{$c};
		}
	} else {
		@sub = sort keys %$df;
	}
	return _drop_dups_core($df, 4, [ @sub ], $kc);
}
# Count rows across Stats::LikeR frame forms: AoH, AoA, HoA, HoH.

# Count columns across Stats::LikeR frame forms: AoH, AoA, HoA, HoH
# (plain vector => 1 column). Uses die, not croak. reftype => blessed frames ok.
sub ncol {
	my ($data) = @_;
	my $type = reftype $data;
	die 'ncol: expected an ARRAY or HASH ref (got '
		. (defined $data ? (ref($data) || 'non-ref scalar') : 'undef') . ")\n"
		unless defined $type && ($type eq 'ARRAY' || $type eq 'HASH');

	if ($type eq 'ARRAY') {
		return 0 unless @$data;                     # empty frame
		my $r0 = reftype $data->[0];                # element 0 decides the form

		# AoH: columns = keys per row; every row a hash ref of equal key count
		if (defined $r0 && $r0 eq 'HASH') {
			my $ncol = scalar keys %{ $data->[0] };
			for my $i (1 .. $#$data) {
				my $row = $data->[$i];
				die "ncol: AoH row $i is not a hash ref\n"
					unless defined(reftype $row) && reftype($row) eq 'HASH';
				my $k = scalar keys %$row;
				die "ncol: ragged AoH — row $i has $k columns, but row 0 has $ncol\n"
					if $k != $ncol;
			}
			return $ncol;
		}

		# AoA: columns = row length; every row an array ref of equal length
		if (defined $r0 && $r0 eq 'ARRAY') {
			my $ncol = scalar @{ $data->[0] };
			for my $i (1 .. $#$data) {
				my $row = $data->[$i];
				die "ncol: AoA row $i is not an array ref\n"
					unless defined(reftype $row) && reftype($row) eq 'ARRAY';
				my $len = scalar @$row;
				die "ncol: ragged AoA — row $i has $len columns, but row 0 has $ncol\n"
					if $len != $ncol;
			}
			return $ncol;
		}

		return 1 unless defined $r0;                # plain 1-D vector: one column

		die "ncol: array element 0 is a $r0 ref; expected HASH (AoH), ARRAY (AoA), or plain scalars (vector)\n";
	}

	# HASH: HoA (keys are columns) or HoH (keys are rows)
	return 0 unless %$data;

	my $probe;                                      # first defined value decides the form
	foreach my $k (keys %$data) {
		next unless defined $data->{$k};
		$probe = $data->{$k};
		last;
	}
	my $vtype = reftype $probe;

	# HoA: keys ARE the columns. Validate values are array refs so a malformed
	# frame dies deterministically rather than depending on which key `probe` hit.
	if (defined $vtype && $vtype eq 'ARRAY') {
		foreach my $col (keys %$data) {
			die "ncol: HoA column '$col' is not an array ref\n"
				unless defined(reftype $data->{$col}) && reftype($data->{$col}) eq 'ARRAY';
		}
		return scalar keys %$data;
	}

	# HoH: keys are rows; columns = keys of a row hash, consistent across rows
	if (defined $vtype && $vtype eq 'HASH') {
		my ($ncol, $ref_row);
		foreach my $row_key (keys %$data) {
			my $row = $data->{$row_key};
			die "ncol: HoH row '$row_key' is not a hash ref\n"
				unless defined(reftype $row) && reftype($row) eq 'HASH';
			my $k = scalar keys %$row;
			if (not defined $ncol) { $ncol = $k; $ref_row = $row_key }
			elsif ($k != $ncol) {
				die "ncol: ragged HoH — row '$row_key' has $k columns, but '$ref_row' has $ncol\n";
			}
		}
		return $ncol;
	}

	die "ncol: HASH values are neither ARRAY refs (HoA) nor HASH refs (HoH)\n";
}

sub nrow {
	my ($data) = @_;
	my $type = reftype $data;
	die 'nrow: expected an ARRAY or HASH ref (got '
		. (defined $data ? (ref($data) || 'non-ref scalar') : 'undef') . ')'
		unless defined $type;

	# AoH / AoA (and a plain vector): one top-level element per row.
	return scalar @$data if $type eq 'ARRAY';

	# HASH: HoA (keys are columns) or HoH (keys are rows).
	return 0 unless %$data;                     # empty frame, either form

	my $probe;                                  # first defined value decides the form
	foreach my $k (keys %$data) {
		next unless defined $data->{$k};
		$probe = $data->{$k};
		last;
	}
	my $vtype = reftype $probe;

	return scalar keys %$data                   # HoH: one key per row
		if defined $vtype && $vtype eq 'HASH';

	if (defined $vtype && $vtype eq 'ARRAY') {  # HoA: rows = common column length
		my ($n, $ref_col);
		foreach my $col (keys %$data) {         # verify columns agree, so a ragged
			my $vec = $data->{$col};            # frame can't return a silently-wrong
			die "nrow: HoA column '$col' is not an array ref"  # (and, given hash
				unless defined(reftype $vec) && reftype($vec) eq 'ARRAY'; # ordering,
			my $len = scalar @$vec;             # nondeterministic) count
			if (not defined $n) { $n = $len; $ref_col = $col }
			elsif ($len != $n) {
				die "nrow: ragged HoA — column '$col' has $len rows, but '$ref_col' has $n";
			}
		}
		return $n;
	}
	die 'nrow: HASH values are neither ARRAY refs (HoA) nor HASH refs (HoH)';
}
sub qcut {
	my ($data, $q, %opt) = @_;

	# help: qcut('h') / qcut('H'), or that string in the q slot
	if ( (!ref $data && defined $data && $data =~ /\A[hH]\z/)
	  || (!ref $q    && defined $q    && $q    =~ /\A[hH]\z/) ) {
		my $h = <<'HELP';
qcut - equal-frequency binning of a numeric column (analog of pandas qcut)

  USAGE
    my @edges            = qcut($data, $q);                 # default: edge list
    my @edges            = qcut($data, $q, edges => 1);     # same, explicit
    my $codes            = qcut($data, $q, codes => 1);     # bin codes (arrayref)
    my ($codes, $edges)  = qcut($data, $q, codes => 1, edges => 1);
    my $labels           = qcut($data, $q, labels => [...]);
    qcut('h');  # or qcut('H')  -> print this help and die

  ARGUMENTS
    $data   arrayref of numbers; undef entries are missing (NA) and are
            skipped for cutpoints, returned as undef in code output
    $q      positive integer (number of equal-frequency bins) OR an arrayref
            of probabilities in [0,1], e.g. [0, 0.5, 0.95, 1]

  OPTIONS
    edges => 1        include the edge vector (default unless codes requested)
    codes => 1        include 0-based bin codes (one per element)
    labels => [...]   map codes onto your labels; implies codes => 1
    labels => 'interval'   label each element with its interval, e.g. "(3.25, 5.5]"
    duplicates => 'drop'   merge non-unique cutpoints instead of dying ('raise')

  RETURN
    edges only (default) .... a flat list of edges  (call in list context)
    codes only .............. an arrayref of codes/labels
    both .................... ($codes_ref, $edges_ref)

  NOTES
    Cutpoints use linear interpolation between order statistics (numpy/pandas
    default), so results match pandas.qcut. Bins are right-closed (a, b] with
    the lowest bin closed on both ends [a, b].
HELP
		die $h;
	}

	die "qcut: first argument must be an ARRAY reference (try qcut('h'))\n"
		unless ref $data eq 'ARRAY';

	# probability vector: q+1 evenly spaced points, or an explicit list
	my $probs;
	if (ref $q eq 'ARRAY') {
		$probs = [ sort { $a <=> $b } @$q ];
	} else {
		die "qcut: number of quantiles must be a positive integer\n"
			unless defined $q && $q =~ /\A[1-9][0-9]*\z/;
		$probs = [ map { $_ / $q } 0 .. $q ];
	}

	my $drop   = (($opt{duplicates} // 'raise') eq 'drop') ? 1 : 0;
	my $labels = $opt{labels};

	# codes are opt-in (labels imply them); edges are on unless codes asked for
	my $want_codes = ($opt{codes} || defined $labels) ? 1 : 0;
	my $want_edges = exists $opt{edges}
		? ($opt{edges} ? 1 : 0)
		: ($want_codes ? 0 : 1);
	die "qcut: nothing to return (set edges => 1 or codes => 1)\n"
		unless $want_edges || $want_codes;

	# does the column contain any NA?
	my $has_na = 0;
	for my $x (@$data) { if (!defined $x) { $has_na = 1; last } }

	my ($codes, $edges, @pos);
	if ($want_codes && $has_na) {
		# strip NA, remember positions, scatter codes back afterwards
		my @vals;
		for my $i (0 .. $#$data) {
			next unless defined $data->[$i];
			push @vals, $data->[$i] + 0;
			push @pos,  $i;
		}
		die "qcut: no non-missing values\n" unless @vals;
		($codes, $edges) = _qcut_core(\@vals, $probs, $drop, 1);
	} elsif ($has_na) {
		# edges only: drop NA so cutpoints ignore them, positions don't matter
		my @vals = grep { defined } @$data;
		die "qcut: no non-missing values\n" unless @vals;
		($codes, $edges) = _qcut_core(\@vals, $probs, $drop, 0);
	} else {
		# no NA: hand the original arrayref straight to XS (no copy)
		($codes, $edges) = _qcut_core($data, $probs, $drop, $want_codes);
	}

	# edges-only: return the flat list
	return @$edges unless $want_codes;

	# turn integer codes into requested labels, or keep the XS arrayref as-is
	my $out;
	if (defined $labels && ref $labels eq 'ARRAY') {
		my $nbin = scalar(@$edges) - 1;
		die "qcut: got $nbin bins but " . scalar(@$labels) . " labels\n"
			unless @$labels == $nbin;
		$out = [ map { $labels->[$_] } @$codes ];
	} elsif (defined $labels && $labels eq 'interval') {
		my @iv;
		for my $b (0 .. $#$edges - 1) {
			my $l = $edges->[$b];
			my $r = $edges->[$b + 1];
			$iv[$b] = $b == 0 ? "[$l, $r]" : "($l, $r]";
		}
		$out = [ map { $iv[$_] } @$codes ];
	} else {
		$out = $codes;			# reuse XS result; no copy
	}

	# scatter NA positions back in (codes path only)
	if ($has_na) {
		my @r = (undef) x scalar(@$data);
		@r[@pos] = @$out;
		$out = \@r;
	}

	return $want_edges ? ($out, $edges) : $out;
}

# summary($data, %opts) -- R-style five-number-plus-mean summary.
#
# Accepts every shape view() does and computes one statistics row per numeric
# "variable": a flat vector (one row); an AoA (one row per inner array, labelled
# by Index); a HoA (one row per key); and -- like view() -- an AoH or HoH (one
# row per column, gathered across the rows). Non-numeric and undefined cells are
# ignored (they never count toward '# values'); an all-non-numeric variable
# shows 0 values and 'na' statistics. Output, colour, and the display options
# are rendered exactly like view() via the shared _render_grid().
sub summary {
	my $current_sub = (split(/::/,(caller(0))[3]))[-1];
	# options view() understands, plus the row-cap synonyms
	my %opt_key = map { $_ => 1 } qw(
		nrows nrow n rows
		na color colors max_width ellipsis gap width to return_only
	);
	my ($data, %args);
	if (@_ && ref $_[0]) {
		# summary(\@arr, ...) / summary(\%h, ...)
		$data = shift;
		%args = @_;
	} else {
		# summary(@vector) / summary(@vector, nrows => N): peel recognised
		# trailing key/value option pairs off the flat list; the rest is data.
		while (@_ >= 2 && defined $_[-2] && !ref($_[-2]) && $opt_key{ $_[-2] }) {
			my $val = pop @_;
			my $key = pop @_;
			$args{$key} = $val;
		}
		my @list = @_;
		$data = \@list;
	}
	my @bad = sort grep { !$opt_key{$_} } keys %args;
	die "$current_sub: unknown argument(s): @bad\n" if @bad;
	# row cap: nrows / nrow / n / rows are synonyms (default 10)
	my $nrows = exists $args{nrows} ? $args{nrows} : exists $args{nrow} ? $args{nrow}
			  : exists $args{n}     ? $args{n}     : exists $args{rows} ? $args{rows}
			  :                       10;
	die "$current_sub: 'nrows' must be a non-negative integer\n"
		unless defined $nrows && $nrows =~ /^\d+$/;

	my $rt = ref $data;
	die "$current_sub: data must either be a hash or an array, not \"$rt\"\n"
		unless $rt eq 'ARRAY' or $rt eq 'HASH';

	# --- resolve the data shape into (label, numeric-vector) series ---
	my (@labels, @vecs, $lab_header);
	if ($rt eq 'ARRAY') {
		my $first;
		for my $e (@$data) { if (defined $e) { $first = $e; last } }
		my $ft = ref $first;
		if ($ft eq 'HASH') {			# AoH: one series per column
			$lab_header = 'Column';
			my %seen;
			for my $row (@$data) { next unless ref $row eq 'HASH'; $seen{$_} = 1 for keys %$row }
			for my $col (sort keys %seen) {
				push @labels, $col;
				push @vecs, [ map { ref $_ eq 'HASH' ? $_->{$col} : undef } @$data ];
			}
		} elsif ($ft eq 'ARRAY') {		# AoA: one series per inner array
			$lab_header = 'Index';
			for my $i (0 .. $#$data) {
				push @labels, $i;
				push @vecs, (ref $data->[$i] eq 'ARRAY' ? [ @{ $data->[$i] } ] : []);
			}
		} else {						# flat vector: a single series
			$lab_header = '';
			push @labels, '';
			push @vecs, [ @$data ];
		}
	} else { # HASH
		my @keys = keys %$data;
		my $sample;
		for my $k (@keys) { $sample = $data->{$k}; last if defined $sample }
		my $vt = ref $sample;
		if ($vt eq 'ARRAY') {			# HoA: one series per key
			$lab_header = 'Key';
			for my $k (sort { lc $a cmp lc $b } @keys) {
				push @labels, $k;
				push @vecs, (ref $data->{$k} eq 'ARRAY' ? [ @{ $data->{$k} } ] : []);
			}
		} elsif ($vt eq 'HASH') {		# HoH: one series per column (inner key)
			$lab_header = 'Column';
			my %seen;
			for my $k (@keys) { next unless ref $data->{$k} eq 'HASH'; $seen{$_} = 1 for keys %{ $data->{$k} } }
			for my $col (sort keys %seen) {
				push @labels, $col;
				push @vecs, [ map { ref $data->{$_} eq 'HASH' ? $data->{$_}{$col} : undef } @keys ];
			}
		} else {						# flat hash: its values as one series
			$lab_header = '';
			push @labels, '';
			push @vecs, [ map { $data->{$_} } @keys ];
		}
	}

	# --- compute the statistics grid ---
	my @colnames = ('# values', 'Min.', '1st Qu.', 'Median', 'Mean', '3rd Qu.', 'Max.');
	my @raw;
	for my $vec (@vecs) {
		my @numeric = grep { defined $_ && looks_like_number($_) } @$vec;
		if (!@numeric) { push @raw, [ 0, (undef) x 6 ]; next }	# empty -> na stats
		my $q = quantile(\@numeric, probs => [0.25, 0.75]);
		# format as %.4g strings; they still look numeric, so _render_grid
		# right-aligns and colours them as numbers.
		push @raw, [
			scalar @numeric,
			sprintf('%.4g', min(\@numeric)),    sprintf('%.4g', $q->{'25%'}),
			sprintf('%.4g', median(\@numeric)), sprintf('%.4g', mean(\@numeric)),
			sprintf('%.4g', $q->{'75%'}),       sprintf('%.4g', max(\@numeric)),
		];
	}

	# cap the number of series shown (keep the true total for the "... more" note)
	my $total = scalar @labels;
	if ($nrows < $total) { $#labels = $nrows - 1; $#raw = $nrows - 1; }

	return _render_grid(
		kind => 'summary', total => $total,
		cols => \@colnames, labels => \@labels, raw => \@raw, lab_header => $lab_header,
		na          => $args{na},
		max_width   => $args{max_width},
		ellipsis    => $args{ellipsis},
		gap         => (exists $args{gap} ? ' ' x $args{gap} : undef),
		width       => $args{width},
		to          => $args{to},
		return_only => $args{return_only},
		color       => (exists $args{color} ? $args{color} : undef),
		colors      => $args{colors},
	);
}

# --- .xlsx support (pure Perl, no CPAN deps) -------------------------------
# An .xlsx file is a ZIP archive of XML parts. IO::Uncompress::Unzip is a core
# module, so we can pull the parts out and parse the (very regular) XML with
# regexes, then feed rows to read_table's callback exactly like _parse_csv_file
# does. A workbook with more than one worksheet is read into a hash keyed by
# sheet name (see read_table). Limitations: dates/times come back as their raw
# serial numbers (no style-based formatting); shared-string rich-text runs are
# concatenated.

# Return the decompressed bytes of a named archive member, or undef if absent.
sub _unzip_member {
	my ($file, $member) = @_;
	require IO::Uncompress::Unzip;
	my $z = IO::Uncompress::Unzip->new($file, Name => $member)
		or return undef;
	my $content = '';
	my $buf;
	while ((my $n = $z->read($buf)) > 0) { $content .= $buf }
	$z->close;
	return $content;
}

# Decode the five predefined XML entities plus numeric character references.
# Numeric refs are re-encoded to UTF-8 bytes so the result stays byte-consistent
# with the rest of the file (which we read, and return, as raw UTF-8 bytes).
sub _xml_unescape {
	my ($s) = @_;
	return $s unless defined $s && index($s, '&') >= 0;
	$s =~ s/&#x([0-9a-fA-F]+);/my $c = chr hex $1; utf8::encode($c); $c/ge;
	$s =~ s/&#([0-9]+);/my $c = chr $1; utf8::encode($c); $c/ge;
	$s =~ s/&lt;/</g;
	$s =~ s/&gt;/>/g;
	$s =~ s/&quot;/"/g;
	$s =~ s/&apos;/'/g;
	$s =~ s/&amp;/&/g;	# must be last so "&amp;lt;" -> "&lt;", not "<"
	return $s;
}

# "AB12" (or "AB") -> 0-based column index (A=0, Z=25, AA=26, ...).
# Hot path (called once per cell): walk the leading letters by ordinal and stop
# at the first non-letter (the row number), avoiding a regex substitution and a
# split // on every call.
sub _xlsx_col_idx {
	my ($ref) = @_;
	my $idx = 0;
	for my $i (0 .. length($ref) - 1) {
		my $o = ord(substr($ref, $i, 1));
		if    ($o >= 65 && $o <=  90) { $idx = $idx * 26 + ($o - 64) }	# A-Z
		elsif ($o >= 97 && $o <= 122) { $idx = $idx * 26 + ($o - 96) }	# a-z
		else  { last }							# reached the digits
	}
	return $idx - 1;
}

# Shared strings (optional part): each <si> may hold several <t> runs, which
# are concatenated. Returns an arrayref indexed by shared-string id.
sub _xlsx_shared_strings {
	my ($file) = @_;
	my @sst;
	if (defined(my $ss = _unzip_member($file, 'xl/sharedStrings.xml'))) {
		while ($ss =~ m{<si\b[^>]*>(.*?)</si>}gs) {
			my $si  = $1;
			my $str = '';
			$str .= _xml_unescape($1) while $si =~ m{<t\b[^>]*>(.*?)</t>}gs;
			push @sst, $str;
		}
	}
	return \@sst;
}

# The workbook's worksheets, in document order, as a list of
# { name => $sheet_name, path => 'xl/worksheets/sheetN.xml' } hashrefs. The path
# is resolved through workbook.xml.rels; a sheet with no resolvable relationship
# (or a workbook with no metadata at all) falls back to a positional sheetN.xml.
sub _xlsx_sheets {
	my ($file) = @_;
	my %target;
	if (defined(my $rels = _unzip_member($file, 'xl/_rels/workbook.xml.rels'))) {
		while ($rels =~ m{<Relationship\b([^>]*?)/?>}gs) {
			my $a = $1;
			my ($id) = $a =~ /\bId="([^"]*)"/;
			my ($tg) = $a =~ /\bTarget="([^"]*)"/;
			$target{$id} = $tg if defined $id && defined $tg;
		}
	}
	my @sheets;
	if (defined(my $wb = _unzip_member($file, 'xl/workbook.xml'))) {
		while ($wb =~ m{<sheet\b([^>]*?)/?>}gs) {
			my $a = $1;
			my ($name) = $a =~ /\bname="([^"]*)"/;
			my ($rid)  = $a =~ /\br:id="([^"]*)"/;
			my $path;
			if (defined $rid && defined $target{$rid}) {
				(my $tg = $target{$rid}) =~ s{^/}{};	# strip absolute-package "/"
				$path = $tg =~ m{^xl/} ? $tg : "xl/$tg";	# else relative to xl/
			}
			push @sheets, {
				name => defined $name ? _xml_unescape($name) : undef,
				path => $path,
			};
		}
	}
	@sheets = ({ name => undef, path => undef }) unless @sheets;	# no metadata
	# any sheet still lacking a path falls back to its positional worksheet file
	$sheets[$_]{path} //= 'xl/worksheets/sheet' . ($_ + 1) . '.xml'
		for 0 .. $#sheets;
	return \@sheets;
}

# Resolve a 'sheet' argument (undef -> first; a 1-based index; or a name) to one
# of the hashrefs from _xlsx_sheets, dying with a clear message on a bad request.
sub _xlsx_choose_sheet {
	my ($file, $sheets, $sheet) = @_;
	return $sheets->[0] unless defined $sheet;
	if ($sheet =~ /^\d+\z/) {
		die "read_table: sheet index $sheet is out of range (1..${\ scalar @$sheets}) in $file\n"
			if $sheet < 1 || $sheet > @$sheets;
		return $sheets->[$sheet - 1];
	}
	my ($chosen) = grep { defined $_->{name} && $_->{name} eq $sheet } @$sheets;
	die "read_table: sheet '$sheet' not found in $file (have: "
		. join(', ', map { defined $_->{name} ? "'$_->{name}'" : '?' } @$sheets)
		. ")\n"
		unless $chosen;
	return $chosen;
}

# Parse one worksheet, invoking $callback->(\@fields) once per non-empty row
# (header row included) with all rows padded to the same width -- the same
# contract _parse_csv_file offers read_table's callback. $sst is the shared
# strings arrayref from _xlsx_shared_strings.
sub _parse_xlsx_sheet {
	my ($file, $sst, $path, $callback) = @_;
	my $ws = _unzip_member($file, $path);
	die "read_table: could not read worksheet '$path' in $file\n"
		unless defined $ws;

	# collect cells, positioning each by its column reference so gaps stay
	# aligned, then pad every row to the widest row seen.
	my @rows;
	my $global_max = -1;
	while ($ws =~ m{<row\b[^>]*>(.*?)</row>}gs) {
		my $rowxml = $1;
		my @cells;
		my $maxc = -1;
		# The r="A1" reference is almost always the first attribute, so the
		# tokenizer captures its column letters ($1) directly -- computing the
		# index from a group the match already produced is the single biggest
		# win in this loop. If the capture misses (r= absent, not first, or a
		# non-standard lowercase ref), $cattrs still holds the full attributes
		# and we parse r= from there; only then do we fall back to sequential.
		while ($rowxml =~ m{<c(?:\s+r="([A-Z]+)\d+")?([^>]*?)(?:/>|>(.*?)</c>)}gs) {
			my ($ref, $cattrs, $cbody) = ($1, $2, $3);
			my $ci;
			if (defined $ref) {
				$ci = 0;
				$ci = $ci * 26 + (ord(substr($ref, $_, 1)) - 64)
					for 0 .. length($ref) - 1;
				$ci--;
			} elsif ($cattrs =~ /\br="([A-Za-z]+)/) {
				$ci = _xlsx_col_idx($1);
			} else {
				$ci = $maxc + 1;
			}
			# Cell type: a plain substring test on the (short) attribute run is
			# markedly cheaper than a capturing /\bt="..."/ match run once per
			# cell. Only "s" and "inlineStr" denote strings; every other type
			# value (str/b/e/n) and a missing t= take the raw <v> path, exactly
			# as the previous /\bt="..."/ dispatch did. Cell-element attribute
			# names are a fixed set (r,s,t,cm,vm,ph) whose other values are
			# numeric refs, so 't="s"' / 't="inlineStr"' can only ever appear as
			# the genuine type attribute -- no false substring match is possible.
			my $val = '';
			if (defined $cbody) {
				if (index($cattrs, 't="s"') >= 0) {		# shared-string index
					# Almost every string cell body is exactly <v>DIGITS</v>; an
					# anchored match reads it in one step, falling back to the
					# general <v ...> scan only for the rare attributed <v>.
					my $v = ($cbody =~ m{\A<v>([^<]*)</v>\z})
						? $1 : ($cbody =~ m{<v\b[^>]*>(.*?)</v>}s)[0];
					$val = (defined $v && $v =~ /^\d+\z/) ? ($sst->[$v] // '') : '';
				} elsif (index($cattrs, 't="inlineStr"') >= 0) {
					$val .= _xml_unescape($1) while $cbody =~ m{<t\b[^>]*>(.*?)</t>}gs;
				} else {			# number / formula str / bool / error
					my $v = ($cbody =~ m{\A<v>([^<]*)</v>\z})
						? $1 : ($cbody =~ m{<v\b[^>]*>(.*?)</v>}s)[0];
					$val = defined $v ? _xml_unescape($v) : '';
				}
			}
			$cells[$ci] = $val;
			$maxc = $ci if $ci > $maxc;
		}
		push @rows, \@cells;
		$global_max = $maxc if $maxc > $global_max;
	}
	undef $ws;	# free the (potentially large) worksheet XML before emitting

	# Emit each row padded to the widest row seen, consuming @rows as we go
	# (shift, not foreach) so the parsed AoA and the caller's growing structure
	# never both sit fully in memory at once. Pad and fill holes in place -- the
	# callback reads by index and never retains the ref -- so this is a light
	# touch, not a second full copy.
	while (my $cells = shift @rows) {
		$#$cells = $global_max;			# extend to the common width
		$_ //= '' for @$cells;			# fill gaps + padding in place
		next unless grep { length } @$cells;	# skip fully blank rows, as CSV does
		$callback->($cells);
	}
	return;
}

sub read_table {
	my $file = shift;
	die "read_table: \"$file\" is not a file\n"   unless -f $file;
	die "read_table: \"$file\" is not readable\n" unless -r $file;

	my %input_args = @_;
	if (exists $input_args{delim}) {
		# FIX: sep + delim together used to silently prefer delim
		die "read_table: pass either 'sep' or 'delim', not both\n"
			if exists $input_args{sep};
		$input_args{sep} = delete $input_args{delim};
	}

	my $is_xlsx = $file =~ /\.xlsx\z/i;
	my $default_sep = $file =~ /\.tsv$/i ? "\t" : ',';
	my %args = (
		sep => $default_sep, comment => '#', %input_args,
	);

	my %allowed_args = map { $_ => 1 } (
		'comment', 'output.type', 'filter', 'row.names', 'sep',
		'auto.row.names', 'sheet',
		# private, undocumented: the multi-sheet expansion passes an already
		# parsed worksheet list / shared-string table to each per-sheet recursion
		# so a big sharedStrings.xml is not re-decompressed once per worksheet.
		'_xlsx_sheets', '_sst',
	);
	my @undef_args = sort grep { !$allowed_args{$_} } keys %args;
	if (@undef_args) {
		my $current_sub = ( split /::/, (caller(0))[3] )[-1];
		die "the args \"@undef_args\" aren't defined for $current_sub\n";
	}
	my $otype = $args{'output.type'} // 'aoh';
	die "read_table: output.type \"$otype\" isn't allowed (aoh, hoa, hoh)\n"
		unless $otype =~ m/^(?:aoh|hoa|hoh)$/;

	# A multi-worksheet .xlsx with no explicit 'sheet' is returned as a hash
	# keyed by worksheet name, each value being that sheet parsed with the same
	# options (recursing one sheet at a time keeps every table's state, and any
	# hoh row.names default, independent). A single-worksheet workbook, or an
	# explicit 'sheet', still returns that one table directly.
	# Resolve the worksheet list once and reuse it below (it decompresses and
	# parses workbook.xml + its rels, so recomputing it in the main xlsx branch
	# would double that work for every single-sheet / explicit-sheet read).
	my $xlsx_sheets;
	if ($is_xlsx) {
		# Reuse a caller-supplied worksheet list (from the multi-sheet expansion
		# below) rather than re-parsing workbook.xml + its rels for every sheet.
		$xlsx_sheets = $args{_xlsx_sheets} // _xlsx_sheets($file);
		if (!defined $args{sheet} && @$xlsx_sheets > 1) {
			# Decompress + parse the shared-string table once for the whole
			# workbook and hand it to each per-sheet read, instead of every
			# recursion re-reading (a potentially large) sharedStrings.xml.
			my $sst = _xlsx_shared_strings($file);
			my %book;
			for my $i (0 .. $#$xlsx_sheets) {
				my $name = $xlsx_sheets->[$i]{name};
				$name = 'Sheet' . ($i + 1) unless defined $name;
				$book{$name} = read_table($file, %input_args,
					sheet        => $i + 1,
					_xlsx_sheets => $xlsx_sheets,
					_sst         => $sst);
			}
			return \%book;
		}
	}

# R's write.table(col.names=TRUE) default omits the header label for the
# row-names column, so a header comes out one field short of every data
# row. With 'auto.row.names' set, mirror read.table's rule: when (and only
# when) the header is exactly one field short, treat the first data field
# as an (otherwise unlabelled) row-names column. Any truthy value enables
# it; a non-1 string is used as the synthesized column name.
	my $want_auto_rn = $args{'auto.row.names'} ? 1 : 0;
	my $auto_rn_name =
		($want_auto_rn && "$args{'auto.row.names'}" ne '1')
			? $args{'auto.row.names'} : 'row_name';

	my $filter = $args{filter};
	if (defined $filter && ref($filter) eq 'CODE') {
		$filter = { 0 => $filter };
	} elsif (defined $filter && ref($filter) ne 'HASH') {
		die "'filter' must be a CODE or HASH reference\n";
	}

	my (@data, %data, @header, @uniq_header,
	    %mapped_filters, @sorted_filter_flds, %seen_rownames);
	my ($data_row, $header_seen, $header_done, $provisional_hdr) = (0, 0, 0, 0);

	# Everything that depends on the (possibly augmented) @header lives here so
	# it can run either right after the header line (strict mode) or deferred
	# to the first data row (auto.row.names mode, once the width is known).
	my $finalize_header = sub {
		if (@header && $header[0] eq '') {
			$header[0] = 'row_name';
		}
		my %seen_h;
		@uniq_header = grep { !$seen_h{$_}++ } @header;
		my @dup_cols = grep { $seen_h{$_} > 1 } @uniq_header;
		warn "read_table: duplicate column name(s) in $file: @dup_cols (later values win)\n"
			if @dup_cols;
		if ($otype eq 'hoh' && !defined $args{'row.names'}) {
			$args{'row.names'} = $header[0];
		}
		if (defined $args{'row.names'}
				&& !grep { $_ eq $args{'row.names'} } @header) {
			die "\"$args{'row.names'}\" isn't in the header of $file\n";
		}
		if ($filter) {
			%mapped_filters = ();
			for my $k (keys %$filter) {
				if ($k =~ /^\d+$/) {
					die "read_table: numeric filter key $k exceeds the "
					  . scalar(@header) . " columns of $file\n"
						if $k > @header;
					$mapped_filters{$k} = $filter->{$k};
				} else {
					my ($idx) = grep { $header[$_] eq $k } 0 .. $#header;
					if (!defined $idx && length( $args{comment} // '' )) {
						# A commented-out header has its marker (and any
						# following whitespace) stripped from the first
						# column, so a key written as it appears in the file
						# (e.g. "# PDB") won't match the clean name ("PDB").
						# Normalize the key the same way and retry.
						(my $nk = $k) =~ s/^\s*\Q$args{comment}\E\s*//;
						($idx) = grep { $header[$_] eq $nk } 0 .. $#header;
					}
					unless (defined $idx) {
						die "read_table: Filter column '$k' not found in the "
						  . "header of $file; header is: "
						  . join( ', ', map { "'$_'" } @header ) . "\n";
					}
					$mapped_filters{ $idx + 1 } = $filter->{$k};
				}
			}
			@sorted_filter_flds = sort { $a <=> $b } keys %mapped_filters;
		}
	};

	# _parse_csv_file() treats a line whose comment marker is followed by
	# whitespace (e.g. "# PDB\tscore") as a comment and drops it, so a header
	# written that way never reaches the callback and the first data row would
	# be mistaken for the header. Recover it: read the first physical line, and
	# if it is marker + whitespace and splits into >=2 fields, hold it as a
	# CANDIDATE header. It is confirmed (in the callback) only if its field
	# count matches the first data row; otherwise it was an ordinary leading
	# comment and is discarded. A marker hugging its text ("#id,val") is
	# delivered by the parser and un-commented in the callback as usual, so it
	# never reaches this branch.
	if (!$is_xlsx && length( $args{comment} // '' ) && length( $args{sep} // '' )) {
		open my $fh, '<', $file
			or die "read_table: can't open $file: $!\n";
		my $first = <$fh>;
		close $fh;
		if (defined $first && $first =~ /^\Q$args{comment}\E\s/) {
			$first =~ s/\r?\n\z//;
			my @cols = split /\Q$args{sep}\E/, $first, -1;
			if (@cols >= 2) {
				$cols[0] =~ s/^\Q$args{comment}\E\s*//;
				@header          = @cols;
				$header_seen     = 1;
				$provisional_hdr = 1;	# confirm against the first data row
			}
		}
	}

	my $on_line = sub {
		my ($line_ref) = @_;

		if (!$header_seen) {
			# --- HEADER CAPTURE (copy made only here; runs once) ---
			my @line = @$line_ref;
			$line[0] =~ s/^\Q$args{comment}\E\s*//
				if @line && defined $line[0] && length( $args{comment} // '' );
			@header      = @line;
			$header_seen = 1;
			unless ($want_auto_rn) {	# strict: finalize immediately
				$finalize_header->();
				$header_done = 1;
			}
			return;
		}

		if (!$header_done) {
			# Confirm or reject a provisionally-captured commented-out header:
			# it is a real header only if its field count matches the first
			# data row. If not, the candidate was an ordinary leading comment;
			# discard it and treat THIS delivered line as the header instead.
			if ($provisional_hdr) {
				$provisional_hdr = 0;
				if (@$line_ref != @header) {
					@header = @$line_ref;
					$header[0] =~ s/^\Q$args{comment}\E\s*//
						if @header && defined $header[0]
						&& length( $args{comment} // '' );
					unless ($want_auto_rn) {
						$finalize_header->();
						$header_done = 1;
					}
					return;	# this line WAS the header, not data
				}
				# widths match: accept the commented header, and let the
				# auto.row.names / finalize logic below run on THIS data row.
			}

# First data row in auto.row.names mode: now the data width is
# known, so decide whether the file carries an unlabelled leading
# row-names column (header exactly one field short).
			if ($want_auto_rn && @$line_ref == @header + 1) {
				unshift @header, $auto_rn_name;
			}
			$finalize_header->();
			$header_done = 1;
			# fall through and process THIS line as data
		}

# --- DATA PROCESSING (operate on $line_ref directly; no row copy)
		$data_row++;
		if (@$line_ref != @header) {
			# FIX: alignment errors now say WHICH row is ragged
			die sprintf "Alignment error on %s data row %d (%d fields vs %d headers).\n",
				$file, $data_row, scalar @$line_ref, scalar @header;
		}
		my %line_hash;
		for my $i (0 .. $#header) {
			my $v = $line_ref->[$i];
			$line_hash{ $header[$i] } = ( !defined($v) || $v eq '' ) ? undef : $v;
		}
# --- APPLY FILTERS ---
		if (@sorted_filter_flds) {
			local *_ = \%line_hash;
			my $skip = 0;
			foreach my $fld (@sorted_filter_flds) {
				local $_ = $fld == 0 ? $line_ref : $line_hash{ $header[ $fld - 1 ] };
				if ( !$mapped_filters{$fld}->( $line_ref, \%line_hash ) ) {
					$skip = 1;
					last;
				}
				if ( $fld > 0 ) {	# write back any mutation made to $_
					$line_ref->[ $fld - 1 ] = $_;
					$line_hash{ $header[ $fld - 1 ] }
						= ( !defined($_) || $_ eq '' ) ? undef : $_;
				}
			}
			return if $skip;
		}
# Populate requested data structure
		if ($otype eq 'aoh') {
			push @data, \%line_hash;
		} elsif ($otype eq 'hoa') {
			push @{ $data{$_} }, $line_hash{$_} for @uniq_header;
		} elsif ($otype eq 'hoh') {
			my $row_name = $line_hash{ $args{'row.names'} };
			die sprintf "read_table: undefined row name (column '%s') in %s data row %d\n",
				$args{'row.names'}, $file, $data_row
				unless defined $row_name;
			warn "read_table: duplicate row name '$row_name' in $file (later values win)\n"
				if $seen_rownames{$row_name}++;
			foreach my $col (@uniq_header) {
				next if $col eq $args{'row.names'};
				$data{$row_name}{$col} = $line_hash{$col};
			}
		}
	};
	if ($is_xlsx) {
		my $sst    = $args{_sst} // _xlsx_shared_strings($file);
		my $chosen = _xlsx_choose_sheet($file, $xlsx_sheets, $args{sheet});
		_parse_xlsx_sheet($file, $sst, $chosen->{path}, $on_line);
	} else {
		_parse_csv_file($file, $args{sep} // '', $args{comment} // '', $on_line);
	}
	# header-only files never hit a data row. A provisional (commented-out)
	# header was never confirmed against a data row, but with no data to
	# contradict it we accept it; either way still validate.
	$finalize_header->() if $header_seen && !$header_done;
	if ($otype eq 'aoh') {
		return \@data;
	} else { # hoa or hoh
		return \%data;
	}
}
# view($data, %opts) -- pretty-print an AoH / HoA / HoH / flat-hash table.
#
sub view {
	my $data = shift;
	if (not defined $data) {
		die 'view received undefined data';
	}
	my %args = @_;
	# --- reject unknown arguments (mirrors read_table/write_table) ---
	my %allowed = map { $_ => 1 } qw(
		n rows na max_width ellipsis gap cols columns width
		to return_only row.names row_names color colors
	);
	my @bad = sort grep { !$allowed{$_} } keys %args;
	die "view: unknown argument(s): @bad\n" if @bad;
	# --- n / rows (synonyms); reject conflicting or non-integer values ---
	die "view: pass either 'n' or 'rows', not both\n"
		if exists $args{n} && exists $args{rows};
	my $n = exists $args{rows} ? $args{rows}
		  : exists $args{n}    ? $args{n}
		  :                      6;
	die "view: 'n'/'rows' must be a non-negative integer\n"
		unless defined $n && $n =~ /^\d+$/;
	my $na    = exists $args{na}        ? $args{na}       : 'undef';
	my $maxw  = exists $args{max_width} ? $args{max_width} : 80;
	my $ell   = exists $args{ellipsis}  ? $args{ellipsis}  : '...';
	my $gap   = exists $args{gap}       ? (' ' x $args{gap}) : '  ';
	my $ucols = $args{cols} || $args{columns};
	my $fh    = $args{to};
	my $quiet = $args{return_only};
	# terminal width used to break wide tables into column chunks (R-style).
	# precedence: explicit 'width' arg -> $ENV{COLUMNS} -> 80 (R's default).
	my $tw = exists $args{width} ? $args{width}
		   : (defined $ENV{COLUMNS} && $ENV{COLUMNS} =~ /^[1-9][0-9]*\z/)
			 ? $ENV{COLUMNS}
			 : 80;
	die "view: 'width' must be a positive integer\n"
		unless defined $tw && $tw =~ /^[1-9][0-9]*\z/;
	# 'row.names' takes precedence over the row_names alias (both accepted)
	my $label_col = exists $args{'row.names'} ? $args{'row.names'}
				  : exists $args{row_names}   ? $args{row_names}
				  : undef;
	my $rt = ref $data;
	die "view: expected an ARRAY (AoH) or HASH (HoA/HoH) reference, got "
	  . ($rt || 'a non-reference') . "\n"
	  unless $rt eq 'ARRAY' or $rt eq 'HASH';
	my ($kind, @cols, @labels, @raw, $total, $lab_header);
	if ($rt eq 'ARRAY') {
		# distinguish AoA (rows are arrayrefs) from AoH (rows are hashrefs)
		# by the first defined element; an empty array stays the AoH path.
		my $first;
		for my $e (@$data) { if (defined $e) { $first = $e; last } }
		if (ref $first eq 'ARRAY') { # ---- AoA ----
			$kind  = 'AoA';
			$total = scalar @$data;
			my $show = $n < $total ? $n : $total;
			# column count from the shown rows (at least one row if any exist)
			my $scan = $show > 0 ? $show : ($total > 0 ? 1 : 0);
			my $m = 0;
			for my $i (0 .. $scan - 1) {
				my $row = $data->[$i];
				next unless ref $row eq 'ARRAY';
				$m = scalar @$row if scalar @$row > $m;
			}
			# 'cols'/'columns' selects & orders by 0-based column index
			my @idx = $ucols ? @$ucols : (0 .. $m - 1);
			# an integer 'row.names'/'row_names' names the label column index
			my $lc = (defined $label_col && $label_col =~ /^\d+$/ && $label_col < $m)
				   ? $label_col : undef;
			@idx = grep { $_ != $lc } @idx if defined $lc;
			@cols       = @idx;              # header = the 0-based array index
			$lab_header = defined $lc ? $lc : '';
			for my $i (0 .. $show - 1) {
				my $row = $data->[$i];
				$row = [] unless ref $row eq 'ARRAY';
				push @labels, defined $lc ? $row->[$lc] : $i;
				push @raw, [ map { $row->[$_] } @idx ];   # missing -> undef -> na
			}
		} else { # ---- AoH ----
			$kind  = 'AoH';
			$total = scalar @$data;
			my $show = $n < $total ? $n : $total;
			if ($ucols) {
				@cols = @$ucols;
			} else {
				my $scan = $show > 0 ? $show : ($total > 0 ? 1 : 0);
				my %seen;
				for my $i (0 .. $scan - 1) {
					my $row = $data->[$i];
					next unless ref $row eq 'HASH';
					$seen{$_} = 1 for keys %$row;
				}
				@cols = sort keys %seen;
			}
			my $lc = defined $label_col ? $label_col
				   : (grep { $_ eq 'row_name' } @cols) ? 'row_name' : undef;
			if (defined $lc) {
				@cols = grep { $_ ne $lc } @cols;
				$lab_header = $lc;
			}
			for my $i (0 .. $show - 1) {
				my $row = $data->[$i];
				$row = {} unless ref $row eq 'HASH';
				push @labels, defined $lc ? $row->{$lc} : $i;
				push @raw, [ map { $row->{$_} } @cols ];
			}
			$lab_header = '' unless defined $lab_header;
		}
	} elsif ($rt eq 'HASH') {
		my @keys = keys %$data;
		my $sample;
		for my $k (@keys) { $sample = $data->{$k}; last if defined $sample; }
		my $vt = ref $sample;
		if (!@keys) {
			$kind = 'Hash'; $total = 0; $lab_header = '';
		} elsif ($vt eq 'ARRAY') {							# ---- HoA ----
			$kind = 'HoA';
			my @allcols = $ucols ? @$ucols : sort @keys;
			$total = 0;
			for my $k (@keys) {
				next unless ref $data->{$k} eq 'ARRAY';
				my $l = scalar @{ $data->{$k} };
				$total = $l if $l > $total;
			}
			my $show = $n < $total ? $n : $total;
			my $lc = defined $label_col ? $label_col
				   : (grep { $_ eq 'row_name' } @allcols) ? 'row_name' : undef;
			@cols = grep { !defined $lc || $_ ne $lc } @allcols;
			$lab_header = defined $lc ? $lc : '';
			for my $i (0 .. $show - 1) {
				push @labels, defined $lc
					? (ref $data->{$lc} eq 'ARRAY' ? $data->{$lc}[$i] : undef)
					: $i;
				push @raw, [ map {
					ref $data->{$_} eq 'ARRAY' ? $data->{$_}[$i] : undef
				} @cols ];
			}
		} elsif ($vt eq 'HASH') {							# ---- HoH ----
			$kind = 'HoH';
			$total = scalar @keys;
			my @rk = sort @keys;
			my $show = $n < $total ? $n : $total;
			my @shown = $show > 0 ? @rk[0 .. $show - 1] : ();
			if ($ucols) { @cols = @$ucols; }
			else {
				my %seen;
				for my $rkk (@shown) {
					next unless ref $data->{$rkk} eq 'HASH';
					$seen{$_} = 1 for keys %{ $data->{$rkk} };
				}
				@cols = sort keys %seen;
			}
			@cols = grep { $_ ne $label_col } @cols if defined $label_col;
			$lab_header = defined $label_col ? $label_col : 'row_name';
			for my $rkk (@shown) {
				push @labels, $rkk;
				my $inner = ref $data->{$rkk} eq 'HASH' ? $data->{$rkk} : {};
				push @raw, [ map { $inner->{$_} } @cols ];
			}
		} else {											# ---- flat hash ----
			$kind = 'Hash'; $total = 1;
			my $show = $n < $total ? $n : $total;
			if ($ucols) { @cols = @$ucols; } else { @cols = sort @keys; }
			my $lc = defined $label_col ? $label_col
				   : (grep { $_ eq 'row_name' } @cols) ? 'row_name' : undef;
			if (defined $lc) { @cols = grep { $_ ne $lc } @cols; $lab_header = $lc; }
			$lab_header = '' unless defined $lab_header;
			for my $i (0 .. $show - 1) {
				push @labels, defined $lc ? $data->{$lc} : $i;
				push @raw, [ map { $data->{$_} } @cols ];
			}
		}
	}

	return _render_grid(
		kind => $kind, total => $total,
		cols => \@cols, labels => \@labels, raw => \@raw, lab_header => $lab_header,
		na => $na, max_width => $maxw, ellipsis => $ell, gap => $gap,
		width => $tw, to => $fh, return_only => $quiet,
		color => (exists $args{color} ? $args{color} : undef), colors => $args{colors},
	);
}

# _render_grid(%spec) -- shared, colourised table renderer used by view() and
# summary(). Given a fully-resolved grid (row labels + column headers + a
# row-major @raw of cell values) plus the display options, it produces the
# output view() has always emitted: a "# Kind: R rows x C cols" banner,
# wide-char-aware column widths, R-style column chunking to fit the terminal,
# optional Data::Printer-style colour, and a trailing "... N more rows" note.
sub _render_grid {
	my %s = @_;
	my $kind       = $s{kind};
	my $total      = $s{total};
	my @cols       = @{ $s{cols}   || [] };
	my @labels     = @{ $s{labels} || [] };
	my @raw        = @{ $s{raw}    || [] };
	my $lab_header = defined $s{lab_header} ? $s{lab_header} : '';
	my $na    = defined $s{na}        ? $s{na}        : 'undef';
	my $maxw  = defined $s{max_width} ? $s{max_width} : 80;
	my $ell   = defined $s{ellipsis}  ? $s{ellipsis}  : '...';
	my $gap   = defined $s{gap}       ? $s{gap}       : '  ';
	my $tw    = defined $s{width}     ? $s{width}     : 80;
	my $fh    = $s{to};
	my $quiet = $s{return_only};
	my $color  = $s{color};
	my $colors = $s{colors};

	# ---- display helpers (UTF-8 / wide-char aware) ----
	my $RESET = "\e[0m";
	my $decode = sub {
		my $s = shift;
		return ($s, 1) if utf8::is_utf8($s);	   # already-decoded chars: encode to bytes on output
		my $d = $s;
		return ($d, 1) if utf8::decode($d);	   # valid UTF-8 byte string -> chars
		return ($s, 0);						   # not UTF-8: leave bytes untouched
	};
	my $wide = sub {
		my $o = shift;
		return 1 if ($o >= 0x1100 && $o <= 0x115F)
				 || ($o >= 0x2E80 && $o <= 0xA4CF)
				 || ($o >= 0xAC00 && $o <= 0xD7A3)
				 || ($o >= 0xF900 && $o <= 0xFAFF)
				 || ($o >= 0xFE30 && $o <= 0xFE4F)
				 || ($o >= 0xFF00 && $o <= 0xFF60)
				 || ($o >= 0xFFE0 && $o <= 0xFFE6)
				 || ($o >= 0x1F300 && $o <= 0x1FAFF);
		return 0;
	};
	my $cwidth = sub {							# width of an already-decoded string
		my $s = shift; my $w = 0;
		for my $ch (split //, $s) { my $o = ord $ch; next if $o == 0; $w += $wide->($o) ? 2 : 1; }
		return $w;
	};
	my $dwidth = sub { my ($c) = $decode->(shift); return $cwidth->($c); };
	my $ell_w  = $dwidth->($ell);
	# stringify + sanitize + char-aware truncate; returns (output_bytes, width)
	my $prep = sub {
		my $v = shift;
		my $s = defined $v ? "$v" : $na;
		$s =~ s/\t/\\t/g; $s =~ s/\r/\\r/g; $s =~ s/\n/\\n/g;
		my ($c, $dec) = $decode->($s);
		if ($maxw && $cwidth->($c) > $maxw) {
			my $budget = $maxw - $ell_w; $budget = 0 if $budget < 0;
			my $keep = ''; my $w = 0;
			for my $ch (split //, $c) {
				my $cw = $wide->(ord $ch) ? 2 : 1;
				last if $w + $cw > $budget;
				$keep .= $ch; $w += $cw;
			}
			$c = $keep . $ell;
			$dec ||= utf8::is_utf8($ell);
		}
		my $w = $cwidth->($c);
		my $bytes = $c; utf8::encode($bytes) if $dec;
		return ($bytes, $w);
	};

	# ---- colour configuration (Data::Printer-style) ----
	my %default_colors = (
		array		=> 'bright_white',	number => 'bright_blue',
		string		=> 'bright_yellow', class  => 'bright_green',
		undef		=> 'bright_red',	hash   => 'magenta',
		caller_info => 'bright_cyan',	separator => 'white',
	);
	my %color = (%default_colors, %{ $colors || {} });
	my %fg = (
		black=>30, red=>31, green=>32, yellow=>33, blue=>34, magenta=>35, cyan=>36, white=>37,
		bright_black=>90, bright_red=>91, bright_green=>92, bright_yellow=>93,
		bright_blue=>94, bright_magenta=>95, bright_cyan=>96, bright_white=>97,
	);
	my $sgr = sub {
		my $spec = $color{ $_[0] };
		return '' unless defined $spec && length $spec;
		if ($spec =~ /^#?([0-9a-fA-F]{6})\z/) {
			my ($r, $g, $b) = map { hex } unpack 'a2a2a2', $1;
			return "\e[38;2;$r;$g;${b}m";
		}
		return "\e[$fg{$spec}m" if exists $fg{$spec};
		return "\e[$spec" . 'm'	 if $spec =~ /^\d[\d;]*\z/;
		return '';
	};
	my $want_color;
	if (!defined $color || (!ref $color && $color eq 'auto')) {
		my $target = defined $fh ? $fh : \*STDOUT;
		$want_color = (!$quiet && -t $target) ? 1 : 0;
	} else {
		$want_color = $color ? 1 : 0;
	}
	my $paint = sub {
		my ($text, $type) = @_;
		return $text unless $want_color;
		my $c = $sgr->($type);
		return length $c ? $c . $text . $RESET : $text;
	};

	# ---- column types (alignment) ----
	my @numeric = (1) x scalar @cols;
	for my $r (@raw) {
		for my $j (0 .. $#cols) {
			my $v = $r->[$j];
			next unless defined $v;
			$numeric[$j] = 0 unless looks_like_number($v);
		}
	}
	my $lab_numeric = @labels ? 1 : 0;
	for my $l (@labels) { $lab_numeric = 0, last unless defined $l && looks_like_number($l); }
	my $val_type = sub {
		my $v = shift;
		return 'undef'	unless defined $v;
		return 'number' if looks_like_number($v);
		return 'string';
	};

	# ---- prepare every cell once: [bytes, width, colour-type] ----
	my @lab_cell = map { [ $prep->($_), (!defined $_ ? 'undef' : $lab_numeric ? 'array' : 'hash') ] } @labels;
	my @row_cell;
	for my $r (@raw) {
		push @row_cell, [ map { [ $prep->($r->[$_]), $val_type->($r->[$_]) ] } 0 .. $#cols ];
	}
	my @head_cell = map { [ $prep->($_) ] } @cols;
	my ($lh_b, $lh_w) = $prep->($lab_header);

	# ---- column widths (display columns) ----
	my $lab_w = $lh_w;
	for my $c (@lab_cell) { $lab_w = $c->[1] if $c->[1] > $lab_w; }
	my @w;
	for my $j (0 .. $#cols) {
		my $width = $head_cell[$j][1];
		for my $r (@row_cell) { $width = $r->[$j][1] if $r->[$j][1] > $width; }
		$w[$j] = $width;
	}

	# ---- pad: spaces are never coloured; only the value text is ----
	my $field = sub {
		my ($bytes, $bw, $width, $right, $type) = @_;
		my $gapn = $width - $bw; $gapn = 0 if $gapn < 0;
		my $sp = ' ' x $gapn;
		my $painted = $paint->($bytes, $type);
		return $right ? $sp . $painted : $painted . $sp;
	};

	# ---- break columns into chunks that fit within $tw (R-style) ----
	# the label column (width $lab_w) is repeated at the front of every chunk.
	# $gap is spaces only, so its display width is length($gap).
	my $gap_w = length $gap;
	my @chunks;
	if (@cols) {
		my $j = 0;
		while ($j <= $#cols) {
			my $used = $lab_w;
			my @chunk;
			while ($j <= $#cols) {
				my $add = $gap_w + $w[$j];
				# always keep at least one column per chunk, even if it overflows
				last if @chunk && $used + $add > $tw;
				push @chunk, $j;
				$used += $add;
				$j++;
			}
			push @chunks, \@chunk;
		}
	} else {
		@chunks = ( [] );	# no data columns: just the label column
	}

	my @out;
	my $shown = scalar @row_cell;
	push @out, $paint->(
		sprintf("# %s: %d row%s x %d col%s	(showing %d)",
			$kind, $total, ($total == 1 ? '' : 's'),
			scalar(@cols), (@cols == 1 ? '' : 's'), $shown),
		'caller_info');

	for my $chunk (@chunks) {
		my @hcells = ( $field->($lh_b, $lh_w, $lab_w, 0, 'hash') );
		push @hcells, $field->($head_cell[$_][0], $head_cell[$_][1], $w[$_], $numeric[$_], 'hash') for @$chunk;
		push @out, join($gap, @hcells);
		for my $ri (0 .. $#row_cell) {
			my @cells = ( $field->($lab_cell[$ri][0], $lab_cell[$ri][1], $lab_w, $lab_numeric, $lab_cell[$ri][2]) );
			push @cells, $field->($row_cell[$ri][$_][0], $row_cell[$ri][$_][1], $w[$_], $numeric[$_], $row_cell[$ri][$_][2]) for @$chunk;
			push @out, join($gap, @cells);
		}
	}

	push @out, $paint->(
		sprintf("# ... %d more row%s", $total - $shown, ($total - $shown == 1 ? '' : 's')),
		'caller_info') if $shown < $total;

	my $str = join("\n", @out) . "\n";
	unless ($quiet) { defined $fh ? print {$fh} $str : print $str; }
	return $str;
}

# TukeyHSD($fit, %opts) -- Tukey Honest Significant Differences.
#
# Mirrors R's stats::TukeyHSD for the fitted objects produced by this
# module's aov(), lm() and glm().  Base R only defines TukeyHSD.aov; this
# extends the same all-pairwise studentized-range comparison to lm and glm
# outputs as well.
#
# The fitted objects here do not retain the model frame, so unlike R the
# response values and per-level replication counts are recomputed from the
# data.  Therefore the caller supplies the data frame and the response name:
#
#   my $fit = aov({ weight => \@w, group => \@g }, 'weight ~ group');
#   my $hsd = TukeyHSD($fit, data => $df, formula => 'weight ~ group');
#   # or:    TukeyHSD($fit, data => $df, response => 'weight');
#
# Options:
#   data        (required) the AoH / HoA / HoH used to fit the model
#   response    response column name; or give formula => 'y ~ ...'
#   formula     alternative to response: LHS is parsed for the response
#   which       factor name or arrayref of names (default: all factors)
#   conf.level  confidence level, default 0.95 (conf_level also accepted)
#   ordered     if true, order each factor's levels by increasing mean
#
# Returns a hashref: one entry per factor mapping to an arrayref of
# comparison hashes { comparison, diff, lwr, upr, 'p adj' } in R's
# lower-triangle order, plus the attributes 'conf.level' and 'ordered'.
#
# Scope: main-effect factors (those present in $fit->{xlevels}); a grouping
# variable must be categorical (string levels) to be treated as a factor,
# exactly as R requires factor().  MSE is the residual mean square (for glm
# this is deviance/df.residual: exact for the gaussian family, a Wald-type
# scale otherwise).  Per-level means are observed marginal means, which
# match R's model.tables means for one-way (and balanced) designs.
sub TukeyHSD {
	my ($fit, %opt) = @_;
	die 'TukeyHSD: first argument must be a fitted-model hashref (from aov/lm/glm)'
		unless ref($fit) eq 'HASH';

	my $conf = exists $opt{'conf.level'} ? $opt{'conf.level'}
	         : exists $opt{conf_level}   ? $opt{conf_level}
	         : 0.95;
	die 'TukeyHSD: conf.level must be between 0 and 1'
		unless $conf > 0 && $conf < 1;
	my $ordered = $opt{ordered} ? 1 : 0;

	my $data = $opt{data}
		or die "TukeyHSD: 'data' (the data frame used to fit the model) is required";

	# --- residual mean square (MSE) and residual d.f., per model type ---
	my ($mse, $df);
	if (ref($fit->{Residuals}) eq 'HASH') {                 # aov
		$df  = $fit->{Residuals}{Df};
		$mse = $fit->{Residuals}{'Mean Sq'};
	} elsif (exists($fit->{rss}) && exists($fit->{'df.residual'})) {         # lm
		$df  = $fit->{'df.residual'};
		$mse = ($df > 0) ? $fit->{rss} / $df : undef;
	} elsif (exists($fit->{deviance}) && exists($fit->{'df.residual'})) {    # glm
		$df  = $fit->{'df.residual'};
		$mse = ($df > 0) ? $fit->{deviance} / $df : undef;
	} else {
		die 'TukeyHSD: could not find residual MSE/df in the fit (expected aov/lm/glm output)';
	}
	die 'TukeyHSD: residual degrees of freedom must be >= 2 (got '
		. (defined($df) ? $df : 'undef') . ')'
		unless defined($df) && $df >= 2;
	die 'TukeyHSD: could not determine a positive residual mean square'
		unless defined($mse) && $mse > 0;

	# --- WIDE one-way layout ------------------------------------------------
	# data = { level => [observations], ... } with no response/formula: each
	# key is a group and its arrayref holds that group's values -- the same
	# shape aov() auto-stacks when the formula is omitted. Simpler than R's
	# long format: no stacked response column, no separate factor column.
	if (   !defined($opt{response}) && !defined($opt{formula})
		&& ref($data) eq 'HASH' && keys(%$data) >= 2
		&& (!grep { ref($_) ne 'ARRAY' } values %$data)
		&& (!grep { !grep { defined && looks_like_number($_) } @$_ } values %$data)) {
		my $label = (defined $opt{which} && !ref $opt{which}) ? $opt{which} : 'group';
		my (%sum, %cnt);
		for my $lev (keys %$data) {
			for my $yv (@{ $data->{$lev} }) {
				next unless defined($yv) && looks_like_number($yv);
				$sum{$lev} += $yv;
				$cnt{$lev}++;
			}
		}
		my @levels = grep { $cnt{$_} } sort keys %$data;  # R orders levels alphabetically
		die 'TukeyHSD: need at least 2 non-empty groups' unless @levels >= 2;
		my @means = map { $sum{$_} / $cnt{$_} } @levels;
		my @n     = map { $cnt{$_} }            @levels;
		return {
			$label       => _tukey_compare(\@levels, \@means, \@n, $mse, $df, $conf, $ordered),
			'conf.level' => $conf,
			ordered      => $ordered,
		};
	}

	# --- LONG layout (R-style): a response column + one or more factor columns
	my $resp = $opt{response};
	if (!defined($resp) && defined $opt{formula}) {
		($resp) = $opt{formula} =~ /\A\s*([^~]+?)\s*~/;
	}
	die "TukeyHSD: need the response variable; pass response => 'name' or formula => 'y ~ ...'"
		unless defined($resp) && length $resp;

	# --- factors present in the model (idx 0 of each xlevels entry = reference) ---
	my $xl = $fit->{xlevels};
	die 'TukeyHSD: no factors in the fitted model (nothing to compare)'
		unless ref($xl) eq 'HASH' && keys %$xl;

	my @which = defined($opt{which})
		? (ref($opt{which}) eq 'ARRAY' ? @{ $opt{which} } : ($opt{which}))
		: (sort keys %$xl);

	my @factors;
	for my $f (@which) {
		if (exists $xl->{$f}) { push @factors, $f }
		else { warn "TukeyHSD: '$f' is not a factor in the model and will be dropped\n" }
	}
	die "TukeyHSD: 'which' specified no factors" unless @factors;

	my $y = _tukey_col($data, $resp);

	my %out;
	for my $f (@factors) {
		my $g = _tukey_col($data, $f);
		die "TukeyHSD: response '$resp' and factor '$f' differ in length"
			unless scalar(@$y) == scalar(@$g);

		my (%sum, %cnt);
		for my $i (0 .. $#$g) {
			my $gv = $g->[$i];
			my $yv = $y->[$i];
			next unless defined($gv) && defined($yv) && looks_like_number($yv);
			$sum{$gv} += $yv;
			$cnt{$gv}++;
		}

		# canonical level order from xlevels, then any extra observed levels
		my @levels = @{ $xl->{$f} };
		my %seen = map { $_ => 1 } @levels;
		push @levels, sort grep { !$seen{$_} } keys %cnt;
		@levels = grep { $cnt{$_} } @levels;      # only levels that carry data

		die "TukeyHSD: factor '$f' needs at least 2 non-empty levels"
			unless scalar(@levels) >= 2;

		my @means = map { $sum{$_} / $cnt{$_} } @levels;
		my @n     = map { $cnt{$_} }            @levels;

		$out{$f} = _tukey_compare(\@levels, \@means, \@n, $mse, $df, $conf, $ordered);
	}

	$out{'conf.level'} = $conf;      # attributes, R-style
	$out{ordered}      = $ordered;
	return \%out;
}

# _tukey_compare(\@levels, \@means, \@n, $mse, $df, $conf, $ordered)
# Shared HSD math for one factor: builds the pairwise-comparison rows in R's
# lower-triangle, column-major order. Used by both the wide and long paths.
sub _tukey_compare {
	my ($levels, $means, $n, $mse, $df, $conf, $ordered) = @_;
	my @levels = @$levels;
	my @means  = @$means;
	my @n      = @$n;
	if ($ordered) {
		my @ord = sort { $means[$a] <=> $means[$b] } 0 .. $#means;
		@levels = @levels[@ord];
		@means  = @means[@ord];
		@n      = @n[@ord];
	}
	my $k    = scalar @means;
	my $crit = Stats::LikeR::qtukey($conf, $k, $df);    # nranges = 1
	my @rows;
	for my $j (0 .. $k - 1) {                            # column-major lower triangle
		for my $i ($j + 1 .. $k - 1) {
			my $diff  = $means[$i] - $means[$j];
			my $se    = sqrt( ($mse / 2) * (1 / $n[$i] + 1 / $n[$j]) );
			my $width = $crit * $se;
			my $est   = ($se > 0)
				? $diff / $se
				: ($diff >= 0 ? 9**9**9 : -(9**9**9));
			my $padj  = Stats::LikeR::ptukey(abs($est), $k, $df, 'lower.tail' => 0);
			push @rows, {
				comparison => "$levels[$i]-$levels[$j]",
				diff       => $diff,
				lwr        => $diff - $width,
				upr        => $diff + $width,
				'p adj'    => $padj,
			};
		}
	}
	return \@rows;
}

# =======================================================================
# melt / pivot_table / fillna / ffill / bfill
#   pure-Perl additions to lib/Stats/LikeR.pm
#
# Placement: splice the reshape pair (melt, pivot_table) in after concat/
# rbind, and the impute trio (fillna, ffill, bfill) in after dropna.  Add
#   melt pivot_table fillna ffill bfill
# to @EXPORT_OK (== @EXPORT).  All five reshape/impute at the Perl level
# only; the sole numeric work is in pivot_table, which reuses the XS
# reducers through _agg_reduce, so there is no XS/ABI surface added here.
#
# NA is undef throughout, exactly as dropna() treats it (a missing hash key
# counts as NA).  Every function returns a NEW top-level frame and never
# mutates its input.  Shape is classified by _df_shape (the agg()/view()
# detector); 'output.type' defaults to the input family, like agg().
# =======================================================================

# _frame_cols($df, $shape, \@need) -> (\%col, $R)
#
# Extract the named columns once, aligned to row positions 0 .. R-1, using
# the same per-shape access agg() uses.  For HoA the column arrays are
# aliased (read-only callers), not rebuilt; every other shape materialises
# a fresh per-column slice.  HoH rows are visited in string-sorted key
# order so a positional axis exists.  Not exported.
sub _frame_cols {
	my ($df, $shape, $need) = @_;
	my (%col, $R);
	if ($shape eq 'AoA') {
		my @h = grep { defined } @$df;
		$R = scalar @h;
		for my $c (@$need) { $col{$c} = [ map { $_->[$c] } @h ] }
	} elsif ($shape eq 'AoH') {
		my @h = grep { defined } @$df;
		$R = scalar @h;
		for my $c (@$need) { $col{$c} = [ map { $_->{$c} } @h ] }
	} elsif ($shape eq 'HoA') {
		$R = 0;
		for my $v (values %$df) { $R = @$v if ref $v eq 'ARRAY' && @$v > $R }
		for my $c (@$need) { $col{$c} = ref $df->{$c} eq 'ARRAY' ? $df->{$c} : [] }
	} else {                                     # HoH
		my @h = map { $df->{$_} } sort keys %$df;
		$R = scalar @h;
		for my $c (@$need) { $col{$c} = [ map { $_->{$c} } @h ] }
	}
	return (\%col, $R);
}

# _sort_group_keys(\@order, \%repr) -> \@sorted
#
# Order group keys by their representative value tuple, numerically when
# every tuple element (across every group) looks like a number, else as
# strings (undef sorts as ''); the same rule agg() uses for its groups.
# Not exported.
sub _sort_group_keys {
	my ($order, $repr) = @_;
	my $all_num = 1;
	SORTNUM: for my $k (@$order) {
		for my $v (@{ $repr->{$k} }) {
			unless (defined $v && looks_like_number($v)) { $all_num = 0; last SORTNUM }
		}
	}
	if ($all_num) {
		return [ sort {
			my ($ra, $rb) = ($repr->{$a}, $repr->{$b});
			my $c = 0;
			for my $j (0 .. $#$ra) { last if $c = $ra->[$j] <=> $rb->[$j] }
			$c;
		} @$order ];
	}
	return [ sort {
		my ($ra, $rb) = ($repr->{$a}, $repr->{$b});
		my $c = 0;
		for my $j (0 .. $#$ra) {
			my $x = defined $ra->[$j] ? $ra->[$j] : '';
			my $y = defined $rb->[$j] ? $rb->[$j] : '';
			last if $c = $x cmp $y;
		}
		$c;
	} @$order ];
}

# melt($df, id_vars => $col|\@cols, value_vars => $col|\@cols,
#      var_name => 'variable', value_name => 'value', 'output.type' => aoa|aoh|hoa|hoh)
#
# Wide -> long, like pandas DataFrame.melt.  Each cell of the value_vars
# columns becomes its own output row: the id_vars are copied across, the
# var_name column holds the source column identifier and the value_name
# column holds the cell.  Column identifiers are names for AoH/HoA/HoH and
# 0-based integer positions for AoA.
#
#   id_vars      scalar or arrayref; default none.
#   value_vars   scalar or arrayref; default every column not in id_vars
#                (column universe and order come from colnames()).
#   var_name     name of the variable column; default 'variable'.
#   value_name   name of the value column;    default 'value'.
#   'output.type' aoa|aoh|hoa|hoh; default the input family.  For aoa output
#                the columns are positional (id_vars.., variable, value) so
#                var_name/value_name are not used.  For hoh output the row
#                labels are reset to 0 .. N-1 (like pandas' RangeIndex).
#
# Row order is column-major, matching pandas: all rows for value_vars[0],
# then all rows for value_vars[1], and so on, preserving input row order
# within each block.  The original frame is never modified.
sub melt {
	my $df = shift;
	die 'melt: undefined data in first position' unless defined $df;
	my $shape = _df_shape($df, 'melt');
	die "melt: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( id_vars => 1, value_vars => 1, var_name => 1,
	              value_name => 1, 'output.type' => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "melt: unknown argument(s): @bad\n" if @bad;

	my @id = !defined $arg{id_vars}        ? ()
	       : ref $arg{id_vars} eq 'ARRAY'  ? @{ $arg{id_vars} }
	       :                                 ( $arg{id_vars} );
	my $var_name   = defined $arg{var_name}   ? $arg{var_name}   : 'variable';
	my $value_name = defined $arg{value_name} ? $arg{value_name} : 'value';
	my $otype = defined $arg{'output.type'} ? lc $arg{'output.type'} : lc $shape;
	my %ok_otype = ( aoa => 1, aoh => 1, hoa => 1, hoh => 1 );
	die "melt: output.type '$otype' isn't allowed (aoa, aoh, hoa, hoh)\n"
		unless $ok_otype{$otype};

	my @universe = colnames($df);
	my %uni = map { $_ => 1 } @universe;
	my %is_id = map { $_ => 1 } @id;
	my @val = !defined $arg{value_vars}        ? ( grep { !$is_id{$_} } @universe )
	        : ref $arg{value_vars} eq 'ARRAY'  ? @{ $arg{value_vars} }
	        :                                    ( $arg{value_vars} );
	for my $c (@id, @val) {
		die "melt: column '$c' not found\n" unless $uni{$c};
	}
	# name hygiene: the emitted variable/value columns must not collide
	die "melt: var_name and value_name must differ\n"
		if $var_name eq $value_name;
	if ($otype ne 'aoa') {
		for my $c (@id) {
			die "melt: var_name '$var_name' collides with an id_vars column\n"
				if $c eq $var_name;
			die "melt: value_name '$value_name' collides with an id_vars column\n"
				if $c eq $value_name;
		}
	}

	my %need; $need{$_} = 1 for @id, @val;
	my ($col, $R) = _frame_cols($df, $shape, [ keys %need ]);

	# column-major stack: [ \@id_values, variable, value ]
	my @rec;
	for my $v (@val) {
		for (my $i = 0; $i < $R; $i++) {
			my @idvals = map { $col->{$_}[$i] } @id;
			push @rec, [ \@idvals, $v, $col->{$v}[$i] ];
		}
	}

	if ($otype eq 'aoa') {
		return [ map { [ @{ $_->[0] }, $_->[1], $_->[2] ] } @rec ];
	} elsif ($otype eq 'aoh') {
		my @out;
		for my $r (@rec) {
			my %h;
			@h{ @id } = @{ $r->[0] };
			$h{$var_name}   = $r->[1];
			$h{$value_name} = $r->[2];
			push @out, \%h;
		}
		return \@out;
	} elsif ($otype eq 'hoa') {
		my %out = map { $_ => [] } @id, $var_name, $value_name;
		for my $r (@rec) {
			push @{ $out{ $id[$_] } }, $r->[0][$_] for 0 .. $#id;
			push @{ $out{$var_name} },   $r->[1];
			push @{ $out{$value_name} }, $r->[2];
		}
		return \%out;
	} else {                                     # hoh, RangeIndex 0..N-1
		my %out;
		my $n = 0;
		for my $r (@rec) {
			my %h;
			@h{ @id } = @{ $r->[0] };
			$h{$var_name}   = $r->[1];
			$h{$value_name} = $r->[2];
			$out{ $n++ } = \%h;
		}
		return \%out;
	}
}

# pivot_table($df, index => $col|\@cols, columns => $col|\@cols,
#             values => $col|\@cols, aggfunc => 'mean', fill_value => undef,
#             skipna => 1, sort => 1, sep => '.', 'output.type' => ...)
#
# Long -> wide with aggregation, like pandas DataFrame.pivot_table.  Rows are
# the distinct `index` tuples; the distinct `columns` tuples spread into new
# output columns; each cell is `aggfunc` applied to the `values` that fall in
# that (index, columns) bucket.  This is the combine half of agg() with the
# group value spread across columns instead of down rows, and it reuses the
# same aggregator vocabulary.
#
#   index        scalar/arrayref of columns that become output rows; default
#                none (a single aggregated row).
#   columns      scalar/arrayref whose distinct value tuples become output
#                columns.  REQUIRED.  A row whose `columns` tuple has any NA
#                is skipped (no column can be named from it).
#   values       scalar/arrayref of columns to aggregate; default every column
#                not used by index/columns.
#   aggfunc      one aggregator name, an arrayref of names, or a coderef;
#                default 'mean'.  Named: mean median sum sd var min max count
#                n nunique first last mode (the agg() set).  A coderef is
#                called as $code->(\@cells) with every cell (NA included).
#   fill_value   substituted for any NA result cell (missing bucket, or an
#                aggregate that came back undef); default leaves undef.
#   skipna       0|1, default 1; forwarded to the numeric reducers as in agg.
#   sort         0|1, default 1; sort output rows and columns by their key
#                (numeric if every key looks numeric, else string).
#   sep          separator for generated column names; default '.'.
#   'output.type' aoa|aoh|hoa|hoh; default input family.  For hoh the row
#                label is the index tuple joined with '.', uniquified with .N.
#
# Generated column names join, with `sep` and in this order, only the pieces
# that vary: the aggregator name (only when >1 aggregator), the value column
# (only when >1 value), and always the `columns` tuple.  With a single value
# and single aggregator the name is exactly the `columns` tuple, matching
# pandas' flat output.  A duplicate generated name is an error (raise `sep`).
# The original frame is never modified.
sub pivot_table {
	my $df = shift;
	die 'pivot_table: undefined data in first position' unless defined $df;
	my $shape = _df_shape($df, 'pivot_table');
	die "pivot_table: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( index => 1, columns => 1, values => 1, aggfunc => 1,
	              fill_value => 1, skipna => 1, sort => 1, sep => 1,
	              'output.type' => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "pivot_table: unknown argument(s): @bad\n" if @bad;
	die "pivot_table: 'columns' is required\n" unless defined $arg{columns};

	my @index   = !defined $arg{index}       ? ()
	            : ref $arg{index} eq 'ARRAY'  ? @{ $arg{index} }
	            :                               ( $arg{index} );
	my @columns = ref $arg{columns} eq 'ARRAY' ? @{ $arg{columns} } : ( $arg{columns} );
	die "pivot_table: 'columns' must name at least one column\n" unless @columns;

	my $sep      = defined $arg{sep} ? $arg{sep} : '.';
	my $skipna   = exists $arg{skipna} ? ($arg{skipna} ? 1 : 0) : 1;
	my $dosort   = exists $arg{sort}   ? ($arg{sort}   ? 1 : 0) : 1;
	my $has_fill = exists $arg{fill_value};
	my $fill     = $arg{fill_value};
	my $otype    = defined $arg{'output.type'} ? lc $arg{'output.type'} : lc $shape;
	my %ok_otype = ( aoa => 1, aoh => 1, hoa => 1, hoh => 1 );
	die "pivot_table: output.type '$otype' isn't allowed (aoa, aoh, hoa, hoh)\n"
		unless $ok_otype{$otype};

	my $af = exists $arg{aggfunc} ? $arg{aggfunc} : 'mean';
	my @funcs = ref $af eq 'ARRAY' ? @$af : ( $af );
	die "pivot_table: empty aggfunc list\n" unless @funcs;
	my %known_agg = map { $_ => 1 }
		qw(mean median sum sd var min max count n nunique first last mode);
	for my $f (@funcs) {
		next if ref $f eq 'CODE';
		die "pivot_table: unknown aggfunc '$f'\n" unless $known_agg{$f};
	}

	my @universe = colnames($df);
	my %uni = map { $_ => 1 } @universe;
	my %reserved = map { $_ => 1 } @index, @columns;
	my @values = !defined $arg{values}       ? ( grep { !$reserved{$_} } @universe )
	           : ref $arg{values} eq 'ARRAY'  ? @{ $arg{values} }
	           :                                ( $arg{values} );
	die "pivot_table: no value columns to aggregate\n" unless @values;
	for my $c (@index, @columns, @values) {
		die "pivot_table: column '$c' not found\n" unless $uni{$c};
	}

	my %need; $need{$_} = 1 for @index, @columns, @values;
	my ($col, $R) = _frame_cols($df, $shape, [ keys %need ]);

	# bucket every row under (index tuple, columns tuple), first-seen order
	my (%rrepr, @rorder, %rseen, %crepr, @corder, %cseen, %bucket);
	for (my $i = 0; $i < $R; $i++) {
		my @cv = map { $col->{$_}[$i] } @columns;
		next if grep { !defined } @cv;           # NA columns tuple -> unnameable
		my $ck = join "\x1e", map { "v$_" } @cv;
		unless ($cseen{$ck}) {
			$cseen{$ck} = 1; push @corder, $ck; $crepr{$ck} = [ @cv ];
		}
		my @iv = map { $col->{$_}[$i] } @index;
		my $rk = @index
			? join("\x1e", map { defined $_ ? "v$_" : "\0" } @iv)
			: "\0all";
		unless ($rseen{$rk}) {
			$rseen{$rk} = 1; push @rorder, $rk; $rrepr{$rk} = [ @iv ];
		}
		push @{ $bucket{$rk}{$ck}{$_} }, $col->{$_}[$i] for @values;
	}
	if ($dosort) {
		@rorder = @{ _sort_group_keys(\@rorder, \%rrepr) } if @index;
		@corder = @{ _sort_group_keys(\@corder, \%crepr) };
	}

	# output column plan: aggfunc-major, then value, then columns tuple
	my $multi_f = @funcs > 1;
	my $multi_v = @values > 1;
	my @colplan;                                 # [ ck, value, func, outname ]
	for my $f (@funcs) {
		my $fl = ref $f eq 'CODE' ? 'fn' : $f;
		for my $vv (@values) {
			for my $ck (@corder) {
				my $cstr = join $sep, map { defined $_ ? $_ : '' } @{ $crepr{$ck} };
				my @pieces;
				push @pieces, $fl if $multi_f;
				push @pieces, $vv if $multi_v;
				push @pieces, $cstr;
				push @colplan, [ $ck, $vv, $f, join($sep, @pieces) ];
			}
		}
	}
	my @out_names = ( @index, map { $_->[3] } @colplan );
	{
		my (%seen, @dup);
		for my $n (@out_names) { push @dup, $n if $seen{$n}++ == 1 }
		die "pivot_table: generated duplicate column name(s): @dup; "
		  . "pass a different 'sep' or rename inputs\n" if @dup;
	}

	# materialise straight into the requested shape
	my (@aoa, @aoh, %hoa, %hoh, %lseen);
	if ($otype eq 'hoa') { $hoa{$_} = [] for @out_names }
	for my $rk (@rorder) {
		my @vals = @{ $rrepr{$rk} };              # index values
		for my $cp (@colplan) {
			my ($ck, $vv, $f) = @$cp;
			my $raw = $bucket{$rk}{$ck}{$vv};
			my $cell;
			if (defined $raw && @$raw) {
				my @def = grep { defined } @$raw;
				$cell = _agg_reduce($f, $raw, \@def, $skipna);
			}
			$cell = $fill if !defined $cell && $has_fill;
			push @vals, $cell;
		}
		if ($otype eq 'aoa') {
			push @aoa, \@vals;
		} elsif ($otype eq 'aoh') {
			my %h; @h{ @out_names } = @vals; push @aoh, \%h;
		} elsif ($otype eq 'hoa') {
			push @{ $hoa{ $out_names[$_] } }, $vals[$_] for 0 .. $#out_names;
		} else {                                  # hoh
			my $label = @index
				? join('.', map { defined $_ ? $_ : '' } @{ $rrepr{$rk} })
				: 'all';
			my $uniq = $label; my $j = 0;
			while (exists $lseen{$uniq}) { $uniq = $label . '.' . (++$j) }
			$lseen{$uniq} = 1;
			my %h; @h{ @out_names } = @vals; $hoh{$uniq} = \%h;
		}
	}
	return \@aoa if $otype eq 'aoa';
	return \@aoh if $otype eq 'aoh';
	return \%hoa if $otype eq 'hoa';
	return \%hoh;
}

# fillna($df, value => $scalar | { col => val, ... }, cols => \@cols)
#
# Replace NA (undef) cells with a constant, like pandas DataFrame.fillna with
# a scalar or a dict.  `value` is REQUIRED and is either a single scalar (fill
# every NA in the frame, or only within `cols` when given) or a hashref mapping
# column => fill value (only those columns are touched; a dict key that names
# no existing column is ignored, matching pandas, and `cols` is then forbidden).
# For a scalar `value`, an explicit `cols` that names a missing column dies,
# like dropna().  Column identifiers are names for AoH/HoA/HoH and 0-based
# integer positions for AoA.
#
# A targeted column's missing hash key counts as NA and is materialised on
# fill (as in dropna's NA view).  AoA rows are not extended past their own
# length.  A structurally-undef (non-ref) row is passed through unchanged, not
# fabricated into a data row, matching ffill()/bfill().  For propagation instead
# of a constant use ffill()/bfill().  Returns
# a NEW frame (rows/columns rebuilt as needed); the original is never modified.
sub fillna {
	my $df = shift;
	die 'fillna: undefined data in first position' unless defined $df;
	my $shape = _df_shape($df, 'fillna');
	die "fillna: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( value => 1, cols => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "fillna: unknown argument(s): @bad\n" if @bad;
	die "fillna: a 'value' is required\n" unless exists $arg{value};

	my $value   = $arg{value};
	my $per_col = ref $value eq 'HASH';
	die "fillna: 'cols' cannot be combined with a per-column 'value' hashref\n"
		if $per_col && exists $arg{cols};

	my @universe = colnames($df);
	my %uni = map { $_ => 1 } @universe;

	my (%fillmap, $scalar_fill, %tset, @targets);
	if ($per_col) {
		%fillmap = %$value;
		@targets = grep { $uni{$_} } keys %fillmap;   # ignore unknown dict keys
	} else {
		$scalar_fill = $value;
		if (exists $arg{cols}) {
			die "fillna: 'cols' must be an arrayref\n"
				unless ref $arg{cols} eq 'ARRAY';
			for my $c (@{ $arg{cols} }) {
				die "fillna: column '$c' not found\n" unless $uni{$c};
			}
			@targets = @{ $arg{cols} };
		} else {
			@targets = @universe;
		}
	}
	%tset = map { $_ => 1 } @targets;
	my $tv = sub { $per_col ? $fillmap{ $_[0] } : $scalar_fill };

	if ($shape eq 'AoH') {
		my @out;
		for my $row (@$df) {
			unless (ref $row eq 'HASH') { push @out, $row; next }
			my %h = %$row;
			for my $c (@targets) { $h{$c} = $tv->($c) unless defined $h{$c} }
			push @out, \%h;
		}
		return \@out;
	}
	if ($shape eq 'HoH') {
		my %out;
		for my $rk (keys %$df) {
			my $row = $df->{$rk};
			unless (ref $row eq 'HASH') { $out{$rk} = $row; next }
			my %h = %$row;
			for my $c (@targets) { $h{$c} = $tv->($c) unless defined $h{$c} }
			$out{$rk} = \%h;
		}
		return \%out;
	}
	if ($shape eq 'HoA') {
		my $R = 0;
		for my $v (values %$df) { $R = @$v if ref $v eq 'ARRAY' && @$v > $R }
		my %out;
		for my $c (keys %$df) {
			my $arr = ref $df->{$c} eq 'ARRAY' ? $df->{$c} : [];
			if ($tset{$c}) {
				my $fv = $tv->($c);
				$out{$c} = [ map { defined $arr->[$_] ? $arr->[$_] : $fv } 0 .. $R - 1 ];
			} else {
				$out{$c} = [ @$arr ];
			}
		}
		return \%out;
	}
	# AoA
	my @out;
	for my $row (@$df) {
		unless (ref $row eq 'ARRAY') { push @out, $row; next }
		my @r = @$row;
		for my $c (@targets) {
			$r[$c] = $tv->($c) if $c <= $#r && !defined $r[$c];
		}
		push @out, \@r;
	}
	return \@out;
}

# _fill_seq(\@vals, $dir, $limit) -> \@vals   (modifies in place)
#
# Propagate the last (dir=1, forward) or next (dir=-1, backward) defined value
# over runs of undef.  With a defined `limit`, at most `limit` consecutive
# undefs are filled per gap; the rest stay undef.  Not exported.
sub _fill_seq {
	my ($vals, $dir, $limit) = @_;
	my $n = scalar @$vals;
	my @idx = $dir > 0 ? ( 0 .. $n - 1 ) : reverse( 0 .. $n - 1 );
	my ($last, $have, $run) = (undef, 0, 0);
	for my $i (@idx) {
		if (defined $vals->[$i]) {
			$last = $vals->[$i]; $have = 1; $run = 0;
		} elsif ($have) {
			next if defined $limit && $run >= $limit;
			$vals->[$i] = $last; $run++;
		}
	}
	return $vals;
}

# _impute_prop($df, $name, $dir, %opts) -- shared core of ffill/bfill.
#
# Propagate defined values along the row axis within each targeted column.
# Row order is positional for AoA/AoH/HoA and string-sorted key order for HoH
# (the only deterministic order a HoH has).  Options: cols => \@cols (default
# every column; an unknown column dies), limit => positive int (max fills per
# gap).  Fills within each column's existing length only (ragged HoA columns
# are not extended); AoA rows are not extended past their own length.  Returns
# a NEW frame; the original is never modified.  Not exported.
sub _impute_prop {
	my $df   = shift;
	my $name = shift;
	my $dir  = shift;
	die "$name: undefined data in first position" unless defined $df;
	my $shape = _df_shape($df, $name);
	die "$name: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( cols => 1, limit => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "$name: unknown argument(s): @bad\n" if @bad;

	my $limit = $arg{limit};
	die "$name: 'limit' must be a positive integer\n"
		if defined $limit
		&& ( !looks_like_number($limit) || $limit < 1 || $limit != int $limit );

	my @universe = colnames($df);
	my %uni = map { $_ => 1 } @universe;
	my @targets;
	if (exists $arg{cols}) {
		die "$name: 'cols' must be an arrayref\n" unless ref $arg{cols} eq 'ARRAY';
		for my $c (@{ $arg{cols} }) {
			die "$name: column '$c' not found\n" unless $uni{$c};
		}
		@targets = @{ $arg{cols} };
	} else {
		@targets = @universe;
	}
	my %tset = map { $_ => 1 } @targets;

	if ($shape eq 'AoH') {
		my @out = map { ref $_ eq 'HASH' ? { %$_ } : $_ } @$df;
		for my $c (@targets) {
			my @vals = map { ref $_ eq 'HASH' ? $_->{$c} : undef } @out;
			_fill_seq(\@vals, $dir, $limit);
			for my $i (0 .. $#out) {
				next unless ref $out[$i] eq 'HASH';
				$out[$i]{$c} = $vals[$i] if defined $vals[$i];
			}
		}
		return \@out;
	}
	if ($shape eq 'HoH') {
		my @keys = sort keys %$df;
		my %out = map {
			$_ => ( ref $df->{$_} eq 'HASH' ? { %{ $df->{$_} } } : $df->{$_} )
		} keys %$df;
		for my $c (@targets) {
			my @vals = map { ref $out{$_} eq 'HASH' ? $out{$_}{$c} : undef } @keys;
			_fill_seq(\@vals, $dir, $limit);
			for my $j (0 .. $#keys) {
				my $rk = $keys[$j];
				next unless ref $out{$rk} eq 'HASH';
				$out{$rk}{$c} = $vals[$j] if defined $vals[$j];
			}
		}
		return \%out;
	}
	if ($shape eq 'HoA') {
		my %out;
		for my $c (keys %$df) {
			my $arr = ref $df->{$c} eq 'ARRAY' ? [ @{ $df->{$c} } ] : [];
			_fill_seq($arr, $dir, $limit) if $tset{$c};
			$out{$c} = $arr;
		}
		return \%out;
	}
	# AoA
	my @out = map { ref $_ eq 'ARRAY' ? [ @$_ ] : $_ } @$df;
	for my $c (@targets) {
		my @vals = map { ref $_ eq 'ARRAY' ? $_->[$c] : undef } @out;
		_fill_seq(\@vals, $dir, $limit);
		for my $i (0 .. $#out) {
			next unless ref $out[$i] eq 'ARRAY';
			$out[$i][$c] = $vals[$i] if $c <= $#{ $out[$i] } && defined $vals[$i];
		}
	}
	return \@out;
}

# ffill($df, cols => \@cols, limit => $n)  -- forward-fill NA (last valid obs).
# bfill($df, cols => \@cols, limit => $n)  -- back-fill NA (next valid obs).
# See _impute_prop for the row-axis and shape semantics.
sub ffill { _impute_prop( shift, 'ffill',  1, @_ ) }
sub bfill { _impute_prop( shift, 'bfill', -1, @_ ) }

# The interpolate() numeric kernels now live in XS (see ip_fill_column and the
# _interp_column_xs XSUB in LikeR.xs); it is called once per target column below.

# interpolate($df, method => 'linear', cols => \@cols, x => ...,
#             order => $k, limit => $n,
#             limit_direction => 'forward'|'backward'|'both',
#             limit_area => 'inside'|'outside')
#
# Fill NA (undef) cells along the row axis, like pandas DataFrame.interpolate.
# It is the numeric sibling of ffill/bfill.  Row order and the four shapes match
# ffill/bfill (positional for AoA/AoH/HoA, sorted-key order for HoH), and it
# returns a NEW frame; the original is never modified.
#
#   method  the interpolant.  All of pandas' methods are supported:
#             linear (default), index, values, time  -- straight line; the
#               first three use `x`, 'linear' uses equal spacing.
#             slinear, nearest, zero                 -- piecewise, interior only.
#             pad/ffill, bfill/backfill              -- hold the last/next value.
#             quadratic, cubic                       -- interp1d B-splines.
#             cubicspline, pchip, akima, spline      -- SciPy-named splines.
#             polynomial, spline (need `order`)      -- degree-k spline.
#             barycentric, krogh                     -- global polynomial.
#   order   required for method 'polynomial' / 'spline' (degree 1, 2 or 3).
#   x       abscissae: an arrayref (one per row) or a column name/index whose
#           numeric values are the coordinates (default: equal spacing 0,1,2..).
#           Must be strictly increasing.  Used by every method except 'linear'.
#   limit_direction  'forward' (default), 'backward', or 'both'.
#   limit_area       'inside' fills only interior gaps, 'outside' only leading/
#                    trailing gaps, undef (default) fills both.
#   limit            max cells filled per undef run.
#   cols             columns to interpolate; default every column.
#
# The pipeline follows pandas exactly: fill every gap with the method, then
# blank the cells limit/direction/area forbid.  Only 'linear' and the hold/
# global methods reach leading/trailing gaps (the interp1d and akima methods
# are interior-only, matching SciPy).  Only numeric cells anchor a fill; a
# defined non-numeric cell is preserved (and, for the piecewise-local methods,
# blocks interpolation across it).  Interpolated cells are floats.  Fills within
# each column's existing length only; a non-ref row is passed through untouched.
sub interpolate {
	my $df = shift;
	die "interpolate: undefined data in first position" unless defined $df;
	my $shape = _df_shape($df, 'interpolate');
	die "interpolate: arguments after the data frame must be name => value pairs\n"
		if @_ % 2;
	my %arg = @_;
	my %known = ( cols => 1, limit => 1, limit_direction => 1,
	              limit_area => 1, method => 1, order => 1, x => 1 );
	my @bad = sort grep { !$known{$_} } keys %arg;
	die "interpolate: unknown argument(s): @bad\n" if @bad;

	my %known_method = map { $_ => 1 } qw(
		linear index values time slinear nearest zero pad ffill bfill backfill
		quadratic cubic cubicspline pchip akima barycentric krogh polynomial spline );
	my $method = defined $arg{method} ? lc $arg{method} : 'linear';
	die "interpolate: unknown method '$method'\n" unless $known_method{$method};

	my $order = $arg{order};
	if ($method eq 'polynomial' || $method eq 'spline') {
		die "interpolate: method '$method' requires an integer 'order' >= 1\n"
			unless defined $order && looks_like_number($order)
			    && $order >= 1 && $order == int $order;
	}

	my $limit = $arg{limit};
	die "interpolate: 'limit' must be a positive integer\n"
		if defined $limit
		&& ( !looks_like_number($limit) || $limit < 1 || $limit != int $limit );

	my $dir = defined $arg{limit_direction} ? lc $arg{limit_direction} : 'forward';
	my %okdir = ( forward => 1, backward => 1, both => 1 );
	die "interpolate: 'limit_direction' must be 'forward', 'backward', or 'both'\n"
		unless $okdir{$dir};
	# the directional-hold methods pin their own direction
	$dir = 'forward'  if $method eq 'pad'   || $method eq 'ffill';
	$dir = 'backward' if $method eq 'bfill' || $method eq 'backfill';

	my $area;
	if (defined $arg{limit_area}) {
		$area = lc $arg{limit_area};
		die "interpolate: 'limit_area' must be 'inside' or 'outside'\n"
			unless $area eq 'inside' || $area eq 'outside';
	}

	my @universe = colnames($df);
	my %uni = map { $_ => 1 } @universe;
	my @targets;
	if (exists $arg{cols}) {
		die "interpolate: 'cols' must be an arrayref\n" unless ref $arg{cols} eq 'ARRAY';
		for my $c (@{ $arg{cols} }) {
			die "interpolate: column '$c' not found\n" unless $uni{$c};
		}
		@targets = @{ $arg{cols} };
	} else {
		@targets = @universe;
	}
	my %tset = map { $_ => 1 } @targets;

	# x coordinate: arrayref, or a column key whose values are the coordinates
	my ($x_is_col, $x_col);
	if (defined $arg{x} && ref $arg{x} ne 'ARRAY') {
		$x_is_col = 1;
		$x_col = $arg{x};
		die "interpolate: x column '$x_col' not found\n" unless $uni{$x_col};
	}
	# validated coordinates of length $len; $xcolseq is the x column pulled in
	# the same row order (only consulted when x is a column key).
	my $mkcoords = sub {
		my ($len, $xcolseq) = @_;
		my @x;
		if    ($x_is_col)            {
			die "interpolate: x column '$x_col' length (${\ scalar @$xcolseq}) != column length ($len)\n"
				unless scalar @$xcolseq == $len;
			@x = @$xcolseq;
		}
		elsif (ref $arg{x} eq 'ARRAY') {
			die "interpolate: 'x' arrayref length (${\ scalar @{$arg{x}}}) != column length ($len)\n"
				unless scalar @{ $arg{x} } == $len;
			@x = @{ $arg{x} };
		} else                       { @x = (0 .. $len - 1); }
		for my $v (@x) {
			die "interpolate: 'x' coordinates must all be defined and numeric\n"
				unless defined $v && looks_like_number($v);
		}
		if (defined $arg{x}) {
			for my $i (1 .. $#x) {
				die "interpolate: 'x' coordinates must be strictly increasing\n"
					unless $x[$i] > $x[$i - 1];
			}
		}
		return \@x;
	};
	# shape dispatch mirrors _impute_prop (ffill/bfill).  The per-column numeric
	# fill (all methods, the dense solve, the preserve mask) is done in XS by
	# _interp_column_xs, which modifies the extracted @vals in place.
	# shape dispatch mirrors _impute_prop (ffill/bfill)
	if ($shape eq 'AoH') {
		my @out = map { ref $_ eq 'HASH' ? { %$_ } : $_ } @$df;
		my $xcolseq = $x_is_col ? [ map { ref $_ eq 'HASH' ? $_->{$x_col} : undef } @out ] : undef;
		my $coords = $mkcoords->(scalar @out, $xcolseq);
		for my $c (@targets) {
			my @vals = map { ref $_ eq 'HASH' ? $_->{$c} : undef } @out;
			_interp_column_xs(\@vals, $coords, $method, $order, $dir, $limit, $area);
			for my $i (0 .. $#out) {
				next unless ref $out[$i] eq 'HASH';
				$out[$i]{$c} = $vals[$i] if defined $vals[$i];
			}
		}
		return \@out;
	}
	if ($shape eq 'HoH') {
		my @keys = sort keys %$df;
		my %out = map {
			$_ => ( ref $df->{$_} eq 'HASH' ? { %{ $df->{$_} } } : $df->{$_} )
		} keys %$df;
		my $xcolseq = $x_is_col ? [ map { ref $out{$_} eq 'HASH' ? $out{$_}{$x_col} : undef } @keys ] : undef;
		my $coords = $mkcoords->(scalar @keys, $xcolseq);
		for my $c (@targets) {
			my @vals = map { ref $out{$_} eq 'HASH' ? $out{$_}{$c} : undef } @keys;
			_interp_column_xs(\@vals, $coords, $method, $order, $dir, $limit, $area);
			for my $j (0 .. $#keys) {
				my $rk = $keys[$j];
				next unless ref $out{$rk} eq 'HASH';
				$out{$rk}{$c} = $vals[$j] if defined $vals[$j];
			}
		}
		return \%out;
	}
	if ($shape eq 'HoA') {
		my %out;
		for my $c (keys %$df) {
			$out{$c} = ref $df->{$c} eq 'ARRAY' ? [ @{ $df->{$c} } ] : [];
		}
		for my $c (@targets) {
			my $arr = $out{$c};
			my $xcolseq = $x_is_col
				? [ @{ ref $df->{$x_col} eq 'ARRAY' ? $df->{$x_col} : [] } ]
				: undef;
			my $coords = $mkcoords->(scalar @$arr, $xcolseq);
			_interp_column_xs($arr, $coords, $method, $order, $dir, $limit, $area);
		}
		return \%out;
	}
	# AoA
	my @out = map { ref $_ eq 'ARRAY' ? [ @$_ ] : $_ } @$df;
	my $xcolseq = $x_is_col ? [ map { ref $_ eq 'ARRAY' ? $_->[$x_col] : undef } @out ] : undef;
	my $coords = $mkcoords->(scalar @out, $xcolseq);
	for my $c (@targets) {
		my @vals = map { ref $_ eq 'ARRAY' ? $_->[$c] : undef } @out;
		_interp_column_xs(\@vals, $coords, $method, $order, $dir, $limit, $area);
		for my $i (0 .. $#out) {
			next unless ref $out[$i] eq 'ARRAY';
			$out[$i][$c] = $vals[$i] if $c <= $#{ $out[$i] } && defined $vals[$i];
		}
	}
	return \@out;
}

# _tukey_col($data, $col) -- pull one column's cells, in row order, from any
# of the three data-frame shapes (AoH arrayref, HoA/HoH hashref).
sub _tukey_col {
	my ($data, $col) = @_;
	die 'TukeyHSD: data must be a reference (AoH / HoA / HoH)' unless ref $data;
	my $r = ref $data;
	if ($r eq 'ARRAY') {                              # AoH
		return [ map { $_->{$col} } @$data ];
	} elsif ($r eq 'HASH') {
		my ($first) = values %$data;
		if (ref($first) eq 'ARRAY') {                 # HoA
			die "TukeyHSD: column '$col' not found in data"
				unless exists $data->{$col};
			return [ @{ $data->{$col} } ];
		} else {                                      # HoH (row-name keyed)
			return [ map { $data->{$_}{$col} } sort keys %$data ];
		}
	}
	die 'TukeyHSD: unsupported data shape';
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Stats::LikeR - Get basic statistical functions, like in R, but with Perl using XS for performance

=head1 VERSION

version 0.25

=head1 Synopsis

Get basic statistical functions working in Perl as if they were part of List::Util, like C<min>, C<max>, C<sum>, etc.
I've used Artificial Intelligence tools such as Claude, Gemini, and Grok to write this as well as using my own gray matter.
There are other similar tools on CPAN, but I want speed and a form like List::Util, which I've gotten here with the help of AI, which often required many attempts to do correctly.
This is meant to call subroutines directly through eXternal Subroutines (XS) for performance and portability.

There B<are> other modules on CPAN that can do B<PARTS> of this, but this works the way that I B<want> it to.

=head1 Functions/Subroutines

========================================================================

=head2 add_data

Add data to an existing hash or array reference. This function acts as the equivalent of adding new rows, as well as an C<ljoin> (described below). It dynamically infers your target data structure, handles deeply nested records, and seamlessly coerces mismatched data shapes to preserve the structural integrity of your primary reference.

=head3 Hash of Hashes (HoH)

When the target is a Hash of Hashes, incoming hash keys update existing rows, and new keys create new rows.

 $data = { 'Jack Smith' => { age => 30 } };
 
 $n = { 
     'Jack Smith' => {    # Update existing (Hash)
         dept => 'Engineering'
      },
     'Jane Doe'   => { age => 25, dept => 'Sales' }, # Add new (Hash)
     'Invalid'    => 'Not a reference'               # Edge case safety
 };
 
 add_data($data, $n); 

B<Resulting Structure:>

 {
     "Jack Smith":  {
         "age":  30,
         "dept": "Engineering"
     },
     "Jane Doe":    {
         "age":  25,
         "dept": "Sales"
     }
 }

=head3 Hash of Arrays (HoA)

When the target is a Hash of Arrays, incoming arrays are pushed onto the existing arrays, appending the new elements, similarly to R's C<rbind>.

 $data = { 'Project Alpha' => [ 'task1', 'task2' ] };
 $n = {
     'Project Alpha' => [ 'task3' ],         # Appends to existing array
     'Project Beta'  => [ 'task1', 'task2' ] # Creates new array row
 };
 add_data($data, $n);

B<Resulting Structure:>

 {
     "Project Alpha": [ "task1", "task2", "task3" ],
     "Project Beta":  [ "task1", "task2" ]
 }

=head3 Array of Hashes / Arrays (AoH / AoA)

C<add_data> now natively supports Array references at the root level. When targeting an Array, it iterates through the source array and merges data at the corresponding indices.

 $data = [ 
     { id => 1, name => 'Alice' } 
 ];
 
 $n = [ 
     { role => 'Admin' },             # Updates index 0
     { id => 2, name => 'Bob' }       # Creates index 1
 ];
 
 add_data($data, $n);

B<Resulting Structure:>

 [
     { "id": 1, "name": "Alice", "role": "Admin" },
     { "id": 2, "name": "Bob" }
 ]

=head3 Advanced Structural Coercion & Cross-Merging

C<add_data> strictly enforces the primary structure of your target reference (determined by inspecting its outer and inner bounds). If you mix Array and Hash types, the function automatically coerces the incoming data to match the target.

B<1. Inner Coercion (Mixing Rows):>

=over

=item * B<Target is HoH:> Source Array rows are read in pairs and converted to key-value pairs.

=item * B<Target is HoA:> Source Hash rows are flattened into key-value pairs and pushed onto the array.

=back

B<2. Root-Level Coercion (Mixing Outer Containers):>

=over

=item * B<Target is Array, Source is Hash:> The function evaluates the Hash keys as numeric indices. (e.g., source key C<"0"> merges into target array index C<[0]>). Non-numeric keys are safely ignored.

=item * B<Target is Hash, Source is Array:> The function converts the Array indices into stringified Hash keys. (e.g., source array index C<[1]> merges into target hash key C<"1">).

=back

=head3 Source is a mixed Hash. Keys dictate the target array index!

 $n = {
     '0' => { y => 20 },                 # Merges into $data->[0]
     '1' => [ 'z', 30 ],                 # Array pair coerced to Hash, creates $data->[1]
     'ignored' => { k => 'v' }           # Ignored: cannot map to an array index
 };
 
 add_data($data, $n);

B<Resulting Structure strictly remains an Array of Hashes:>

 [
     { "x": 10, "y": 20 },
     { "z": 30 }
 ]

NB: If C<add_data> is called on a completely empty target reference (e.g., C<$data = {}> or C<$data = []>), it will intelligently infer the required inner structure (Hashes vs Arrays) by inspecting the first valid row of the source data.

=head2 agg

Split-apply-combine over a data frame: split the rows into groups, apply one or
more aggregators to chosen columns, and combine the results into a new frame.
This is the I<combine> half that C<group_by> (which only splits) leaves to you,
and the analog of pandas C<df.groupby(...).agg(...)>. With no C<by> it collapses
the whole frame to a single row, like pandas C<df.agg(...)>.

C<agg> accepts all four data-frame shapes and, by default, returns the same shape
it was given:

 AoA  [ [ .. ], [ .. ] ]      array of arrayrefs   (positional columns)
 AoH  [ { .. }, { .. } ]      array of hashrefs    (the read_table default)
 HoA  { c => [ .. ], .. }     hash of arrayrefs    (column-major)
 HoH  { r => { .. }, .. }     hash of hashrefs     (named rows)

For AoA the column identifiers in C<by> and in the C<agg> spec are integer
positions; for the other three shapes they are column names. The original frame
is never modified.

=head3 Usage

 use Stats::LikeR;
 
 # grouped, one aggregator per column
 my $out = agg($df, by => 'sex', agg => { wt => 'mean' });
 
 # grouped, several aggregators, several columns
 my $out = agg($df,
     by  => 'sex',
     agg => { wt => [ 'mean', 'sd' ], age => [ 'mean', 'count' ] },
 );
 
 # ungrouped: the whole frame becomes one row
 my $out = agg($df, agg => { wt => 'mean', age => 'count' });
 
 # group on two columns and emit a hash of hashes
 my $out = agg($df,
     by            => [ 'a', 'b' ],
     agg           => { v => 'sum' },
     'output.type' => 'hoh',
 );

=head3 Arguments

C<agg> takes the data frame first, then C<< name =E<gt> value >> pairs.

=over

=item * B<agg> (required) — a hashref mapping each column to an aggregator
I<spec>. A spec is one of: a single aggregator name (string), an arrayref of
names, or a coderef. See L<#aggregators> below.

=item * B<by> — a single column or an arrayref of columns to group on. Omit it to
aggregate the entire frame into one row.

=item * B<skipna> — C<1> (default) drops undef cells before a numeric aggregator
runs. C<0> makes any undef in a group poison the numeric result for that group
(the cell comes back undef), matching pandas C<skipna=False>. C<count>, C<n>,
C<nunique>, C<first>, and C<last> ignore this flag.

=item * B<sort> — C<1> (default) sorts the output groups by key (numerically when
every key looks like a number, otherwise as strings); C<0> keeps first-seen
order.

=item * B<output.type> — C<aoa>, C<aoh>, C<hoa>, or C<hoh>. Defaults to the same family
as the input frame.

=back

=head3 Aggregators

Named aggregators may be combined in any order per column:

=for html <table>
<thead>
<tr>
  <th>name</th>
  <th>result</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>mean</code></td>
  <td>arithmetic mean (needs ≥ 1 defined cell, else undef)</td>
</tr>
<tr>
  <td><code>median</code></td>
  <td>median (needs ≥ 1)</td>
</tr>
<tr>
  <td><code>sum</code></td>
  <td>sum (needs ≥ 1)</td>
</tr>
<tr>
  <td><code>sd</code></td>
  <td>sample standard deviation (needs ≥ 2, else undef)</td>
</tr>
<tr>
  <td><code>var</code></td>
  <td>sample variance (needs ≥ 2, else undef)</td>
</tr>
<tr>
  <td><code>min</code></td>
  <td>minimum (needs ≥ 1)</td>
</tr>
<tr>
  <td><code>max</code></td>
  <td>maximum (needs ≥ 1)</td>
</tr>
<tr>
  <td><code>count</code></td>
  <td>number of <i>defined</i> cells</td>
</tr>
<tr>
  <td><code>n</code></td>
  <td>number of cells, undef included</td>
</tr>
<tr>
  <td><code>nunique</code></td>
  <td>number of distinct defined cells</td>
</tr>
<tr>
  <td><code>first</code></td>
  <td>first defined cell (undef if none)</td>
</tr>
<tr>
  <td><code>last</code></td>
  <td>last defined cell (undef if none)</td>
</tr>
<tr>
  <td><code>mode</code></td>
  <td>modal defined cell; ties broken deterministically</td>
</tr>
</tbody>
</table>

The numeric aggregators call the module's XS functions of the same name, so they
inherit their precision. C<agg> filters undef itself before calling them, so they
never croak on missing cells. C<mode> is made deterministic: on a tie it returns
the smallest number, or the lowest string when the values are not numeric.

A B<coderef> may be supplied instead of a name for full control. It is called
once per group as C<< $code-E<gt>(\@cells) >>, where C<@cells> are every cell for that
column in the group B<including undef>, and must return a single scalar:

 # count the missing values in each group
 my $out = agg($df, by => 'sex', agg => {
     age => sub {
         my $cells = shift;
         scalar grep { !defined } @$cells;
     },
 });

=head3 Output shape and column naming

Output columns are laid out deterministically: the C<by> columns first, in the
order given, then the aggregated columns sorted (numerically for AoA integer
columns, otherwise as strings), each expanded over its aggregator list in the
order supplied.

A column reduced by a B<single> aggregator keeps its own name; reduced by
B<two or more> it becomes C<< E<lt>colE<gt>_E<lt>funcE<gt> >>:

 my $df = [
     { sex => 'M', wt => 70, age => 30    },
     { sex => 'F', wt => 60, age => 25    },
     { sex => 'M', wt => 80, age => 40    },
     { sex => 'F', wt => 55, age => undef },
 ];
 
 my $out = agg($df,
     by  => 'sex',
     agg => { wt => [ 'mean', 'sd' ], age => [ 'mean', 'count' ] },
 );

B<Resulting Structure> (AoH in, AoH out):

 [
     {
         sex       => 'F',
         wt_mean   => 57.5,
         wt_sd     => 3.53553390593274,
         age_mean  => 25,     # the undef age was skipped
         age_count => 1,      # count excludes the undef
     },
     {
         sex       => 'M',
         wt_mean   => 75,
         wt_sd     => 7.07106781186548,
         age_mean  => 35,
         age_count => 2,
     },
 ]

=head3 Ungrouped

Without C<by>, the frame collapses to one row:

 my $out = agg($df, agg => { wt => 'mean', age => 'count' });
 
 # [ { wt => 66.25, age => 3 } ]

=head3 Array of Arrays (AoA)

Columns are integer positions. Grouping on column 0 and reducing column 1:

 my $aoa = [ [ 'M', 70 ], [ 'F', 60 ], [ 'M', 80 ] ];
 my $out = agg($aoa, by => 0, agg => { 1 => [ 'mean', 'max' ] });
 
 # [ [ 'F', 60, 60 ], [ 'M', 75, 80 ] ]
 #     ^grp  ^mean ^max

The output row is positional: the C<by> columns first, then each aggregated
column in the plan order.

=head3 Hash of Hashes (HoH) output

With C<< output.type =E<gt> 'hoh' >> the row label is the group value; multiple C<by>
columns are joined with a dot, an ungrouped result is keyed C<all>, and a
collision is made unique with a C<.N> suffix.

 my $out = agg($df, by => 'sex', agg => { wt => 'mean' }, 'output.type' => 'hoh');
 
 # {
 #     F => { sex => 'F', wt => 57.5 },
 #     M => { sex => 'M', wt => 75   },
 # }

=head3 Missing values

By default (C<< skipna =E<gt> 1 >>) undef cells are removed before a numeric aggregator
runs, so a group of C<(60, 55)> with a third undef still yields the mean of the
two defined values. C<count> reports only defined cells while C<n> counts undef
too. With C<< skipna =E<gt> 0 >>, a group containing any undef returns undef for the
numeric aggregators (C<mean median sum sd var mode>); the counting and
positional aggregators are unaffected.

A group without enough data yields undef rather than an error: C<sd> and C<var>
need at least two defined cells, the other numeric aggregators need at least
one.

=head3 Errors

C<agg> dies (with a trailing newline, so the message prints cleanly) when:

=over

=item * the first argument is not an ARRAY or HASH ref;

=item * no C<agg> spec is given, or it is not a non-empty hashref;

=item * an unknown option is passed;

=item * an aggregator name is not recognized;

=item * an aggregator list for a column is empty;

=item * C<output.type> is not one of C<aoa>, C<aoh>, C<hoa>, C<hoh>;

=item * the trailing arguments are not C<< name =E<gt> value >> pairs.

=back

=head3 See also

C<group_by> (the split step), C<concat> / C<rbind> (row-binding frames),
C<dropna>, C<assign>, C<value_counts>.

=head2 anova

Sequential (Type-I) ANOVA table for a linear model, in the same shape C<aov>
returns. C<anova> fits C<response ~ terms>, then decomposes the model sum of
squares one term at a time, B<in formula order>, and F-tests each term
against the residual mean square.

 anova(
 {
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,     1,   1,   0,   0,   0]
 },
 'yield ~ ctrl');

returns

 {
     ctrl        {
         Df          1,
         "F value"   25.6000000000001,
         "Mean Sq"   1.70666666666667,
         "Pr(>F)"    0.00718232855871859,
         "Sum Sq"    1.70666666666667
     },
     Residuals   {
         Df          4,
         "Mean Sq"   0.0666666666666665,
         "Sum Sq"    0.266666666666666
     }
 }

Two-way (and higher) models use the C<*> operator, which implicitly evaluates
the main effects alongside the interaction (C<a * b> expands to C<a + b + a:b>;
C<a * b * c> to the full factorial C<a + b + c + a:b + a:c + b:c + a:b:c>):

 my $res_2way = anova($data_2way, 'len ~ supp * dose');

Bare string columns are treated as factors and treatment-coded (first level =
reference); numeric columns and C<I(x^2)> enter as single regressors. It is
robust against rank deficiency: collinear terms gracefully receive 0 degrees
of freedom and 0 sum of squares, matching R's behavior.

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>data_sv</code></td>
  <td><code>HashRef</code> or <code>ArrayRef</code></td>
  <td><i>(Required)</i></td>
  <td>The dataset. A Hash of Arrays (HoA, columns) or Array of Hashes (AoH, rows) — the same forms <code>aov</code>/<code>lm</code> accept.</td>
  <td></td>
</tr>
<tr>
  <td><code>formula_sv</code></td>
  <td><code>String</code></td>
  <td><i>(Required)</i></td>
  <td>Symbolic model <code>'response ~ rhs'</code>, with <code>+</code>, <code>:</code> and <code>*</code>. Unlike <code>aov</code>, <code>anova</code> does <b>not</b> auto-stack, so a formula is mandatory.</td>
  <td><code>'yield ~ N * P'</code></td>
</tr>
</tbody>
</table>

=head3 Output Variables

A single C<HashRef>; keys are the parsed term names, so the structure varies
with the formula.

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>(Term Name)</i></td>
  <td><code>HashRef</code></td>
  <td>ANOVA-table stats for each term (<code>'ctrl'</code>, <code>'N:P'</code>, …). <code>'Mean Sq'</code>, <code>'F value'</code> and <code>'Pr(>F)'</code> are omitted for 0-df (aliased) terms.</td>
  <td><code>{'Df'=>1,'Sum Sq'=>14.2,'Mean Sq'=>14.2,'F value'=>25.81,'Pr(>F)'=>0.0004}</code></td>
</tr>
<tr>
  <td><code>Residuals</code></td>
  <td><code>HashRef</code></td>
  <td>Residual (error) statistics; never carries an F test.</td>
  <td><code>{'Df'=>10,'Sum Sq'=>5.5,'Mean Sq'=>0.55}</code></td>
</tr>
</tbody>
</table>

=head3 C<anova> vs C<aov> — what's the difference?

For a B<single model they compute the identical Type-I table> — in R,
C<anova(lm(f))> and C<summary(aov(f))> return the same sums of squares, and the
same holds here (C<anova(\%d,'yield ~ ctrl')> reproduces the C<aov> table
above exactly). The difference is one of role, not arithmetic:

=over

=item * B<< C<aov> is the model-I<fitting> idiom for designed experiments. >> It leans
toward factors and balanced designs, and in this module it adds two
conveniences C<anova> deliberately leaves out: it can B<auto-stack> a named
list when you omit the formula (R's C<stack()> + C<Value ~ Group>), and it
returns a C<group_stats> block of per-group means and counts alongside the
table. Reach for C<aov> when your question is "do these treatment groups
differ, and what do the groups look like?"

=item * B<< C<anova> is the model-I<table> idiom. >> It always wants an explicit formula
and returns just the decomposition — nothing descriptive. Reach for it when
you already have a model in mind and only want its term-by-term SS /
F-tests, or when you want the leaner object to feed onward.

=back

In short: same numbers for one model; C<aov> is the richer "fit + describe"
call (and the only one that stacks), C<anova> is the minimal "give me the
table" call. Note that both are B<Type-I / sequential>, so term order in the
formula matters, and both share this module's C<pf>, so p-values agree with
C<oneway_test> and the rest of Stats::LikeR.

I<< (R's C<anova> generic can additionally compare several nested models,
C<anova(m1, m2)>, giving an F/LRT between them — a capability neither this
C<anova> nor C<aov> currently provides. Ask if that would be useful.) >>

=head2 aoh2hoa

C<aoh2hoa($aoh)> — transpose an B<array-of-hashes> (row-major) into a B<hash-of-arrays> (column-major).

 my $hoa = aoh2hoa([ { a => 1, b => 2 }, { a => 3 } ]);
 # $hoa = { a => [1, 3], b => [2, undef] }

Rows go in, columns come out: each distinct key across the input rows becomes one output column, and the values are gathered down that column in row order.

=head3 Arguments

C<$aoh> — an array ref of hash refs, one hash per row. This is the only argument, and it is required. Passing anything that is not an array ref is fatal:

 aoh2hoa({ a => 1 });   # dies: argument must be an arrayref of hashrefs

=head3 Returns

A hash ref of array refs. Each key is a column name (the union of all keys seen across the rows); each value is an array ref holding that column's cells. Every column has exactly C<scalar @$aoh> elements, so the result is rectangular even when the input is ragged.

=head3 Behavior

The column set is the B<union> of every row's keys — a key that appears in only some rows still produces a full-length column, with C<undef> in the rows that lacked it.

Each column is padded to exactly the row count. Cells missing from a given row come through as C<undef>, including trailing gaps (a column whose last contributing row is early still runs the full length). These absent cells are cheap holes in the array, not stored SVs.

Values are B<copied> (C<newSVsv>), so the returned structure is independent of the input — mutating C<$aoh> afterward won't disturb the result. The copy is shallow: a value that is itself a reference is copied the same way C<< $col-E<gt>[$i] = $row-E<gt>{$k} >> would, i.e. the ref is duplicated but its referent is shared.

Keys are handled SV-first (C<hv_iterkeysv> / C<hv_fetch_ent>), so UTF-8 and otherwise non-trivial hash keys round-trip correctly.

A row that is B<not> a hash ref is skipped rather than fatal: it contributes C<undef> to every column at its index. So a stray C<undef> or scalar in the input thins the columns at that position instead of dying.

=head3 Notes

The output column order follows hash iteration order and is therefore not guaranteed — sort the keys if you need a stable layout. Round-tripping through C<hoa2aoh> (or the reverse) reconstructs the data but not necessarily the original key/row ordering, and rows originally absent a key will gain it as an explicit C<undef>.

=head2 C<aoh2hoh>

Index an B<A>rray-B<o>f-B<H>ashes into a B<H>ash-B<o>f-B<H>ashes, keyed by the value of one column.

 my $hoh = aoh2hoh($aoh, $key);

Where C<aoh2hoa> I<transposes> rows into columns, C<aoh2hoh> I<indexes> rows by a chosen field, turning a sequential list into a lookup table. The chosen field is treated as a B<primary key>: it must be unique across the rows, and a repeat is fatal.

=head3 Signature

=for html <table>
<thead>
<tr>
  <th>Argument</th>
  <th>Type</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>$aoh</code></td>
  <td>arrayref</td>
  <td>The rows: an arrayref of hashrefs.</td>
</tr>
<tr>
  <td><code>$key</code></td>
  <td>scalar</td>
  <td>The column name whose value indexes each row.</td>
</tr>
</tbody>
</table>

Returns a hashref. Each top-level key is a row's C<< $row-E<gt>{$key} >> value; each value is a shallow copy of that row.

 my $rows = [
     { id => 'p1', kd => 12.4, chain => 'A' },
     { id => 'p2', kd =>  3.1, chain => 'B' },
 ];
 
 my $by_id = aoh2hoh($rows, 'id');
 # {
 #   p1 => { id => 'p1', kd => 12.4, chain => 'A' },
 #   p2 => { id => 'p2', kd =>  3.1, chain => 'B' },
 # }
 
 $by_id->{p2}{kd};   # 3.1 -- O(1) lookup instead of a linear scan

=head3 Semantics

These choices are the parts most worth keeping in mind, because the AoH->HoH mapping is ambiguous where a transpose is not.

B<Duplicate keys are fatal.> If two rows share the same key value, the call dies rather than silently dropping a row:

 aoh2hoh([ { id => 'a', x => 1 }, { id => 'a', x => 9 } ], 'id');
 # dies: aoh2hoh: duplicate key 'a' has >= 2 occurrences

This makes the chosen column an enforced primary key: the result is only returned if every row maps to a distinct bucket. If your data legitimately has repeats and you want to I<keep> them, you want a hash-of-arrays-of-rows instead -- a different return shape. If you want last-wins or first-wins collapse, dedup the input before calling.

B<The key column is retained> inside each inner hash (the copy is of the whole row). Drop it deliberately if you don't want the redundancy.

B<Shallow copy.> Inner hashes are fresh, so adding or removing keys on the output never touches the input. But a I<value> that is itself a reference is shared, exactly like C<< $out{$rk}{$_} = $row-E<gt>{$_} >>:

 my $shared = [ 1, 2, 3 ];
 my $out = aoh2hoh([ { id => 'a', data => $shared } ], 'id');
 push @{ $out->{a}{data} }, 4;   # $shared now has 4 elements too

A row that is not a hashref, or that lacks a defined value at C<$key>, is fatal.

B<Numeric vs string keys collide.> Hash keys are strings, so C<1> and C<"1"> map to the same bucket and therefore trip the duplicate-key die. Normalize the key column first if a row could carry both forms.

=head3 Use cases

B<Join / enrichment lookups.> Build an index once, then attach fields from one dataset onto another by shared id without an O(n*m) nested loop -- and the duplicate-key die guarantees the join side really is keyed uniquely:

 my $meta = aoh2hoh($pdb_metadata, 'pdb_id');
 for my $hit (@$results) {
     $hit->{resolution} = $meta->{ $hit->{pdb_id} }{resolution};
 }

B<Primary-key validation.> Because a repeat is fatal, the call doubles as an assertion that a column is unique -- a cheap way to catch a malformed table (duplicate accession, duplicate peptide id) at load time rather than downstream.

B<Random-access reshaping of tabular data.> After parsing a CSV/TSV into an array of row-hashes, re-index by a primary key so downstream code can fetch a row by name rather than scanning. Pairs naturally with the CSV-parsing side of the toolkit.

B<Set membership and difference.> C<< exists $hoh-E<gt>{$k} >> gives a cheap presence test, useful for asking which ids in one table are missing from another.

=head3 Relationship to C<aoh2hoa>

=for html <table>
<thead>
<tr>
  <th>Function</th>
  <th>Output shape</th>
  <th>Indexed by</th>
  <th>Typical question it answers</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>aoh2hoa</code></td>
  <td>hash of arrayrefs</td>
  <td>column name</td>
  <td>"give me every value in column X"</td>
</tr>
<tr>
  <td><code>aoh2hoh</code></td>
  <td>hash of hashrefs</td>
  <td>a row's key val</td>
  <td>"give me the whole row whose id is Y"</td>
</tr>
</tbody>
</table>

Reach for C<aoh2hoa> when you want columns (vectors to feed a statistic or a plot); reach for C<aoh2hoh> when you want addressable rows keyed by a unique field.

=head3 Implementation note

The operation is a single pass over the rows with one hash insert per row -- the same asymptotics in pure Perl as in XS, and Perl's hash operations are already C underneath. There is no meaningful speed or memory advantage to an XS implementation here, so pure Perl is preferred unless it must live in the same C<.xs> for packaging parity. The duplicate check is a single C<exists> per row and does not change that. (An XS version would C<croak> on the duplicate before allocating the second copy, so there is no extra cleanup to manage.)

=head2 aov

Warning: assumes normal distribution

 aov(
 {
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,     1,   1,   0,   0,   0]
 },
 'yield ~ ctrl');

which returns

 {
     ctrl        {
         Df          1,
         "F value"   25.6000000000001,
         "Mean Sq"   1.70666666666667,
         Pr(>F)      0.00718232855871859,
         "Sum Sq"    1.70666666666667
     },
     Residuals   {
         Df          4,
         "Mean Sq"   0.0666666666666665,
         "Sum Sq"    0.266666666666666
    }
 }

You can also perform Two-Way ANOVA with categorical interactions using the C<*> operator. The parser will implicitly evaluate the main effects alongside the interaction:

 my $res_2way = aov($data_2way, 'len ~ supp * dose');

It is robust against rank deficiency; collinear terms will gracefully receive 0 degrees of freedom and 0 sum of squares, matching R's behavior.

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>data_sv</code></td>
  <td><code>HashRef</code> or <code>ArrayRef</code></td>
  <td><i>(Required)</i></td>
  <td>The dataset to analyze. Accepts a Hash of Arrays (HoA) or Array of Hashes (AoH). If no formula is provided, it must be an HoA to allow automatic stacking (mimicking R's <code>stack()</code> on a named list).</td>
  <td></td>
</tr>
<tr>
  <td><code>formula_sv</code></td>
  <td><code>String</code></td>
  <td><code>undef</code></td>
  <td>A symbolic description of the model to be fitted. If omitted, the formula automatically defaults to <code>'Value ~ Group'</code> and the input data is stacked.</td>
  <td><code>'yield ~ N * P'</code></td>
</tr>
</tbody>
</table>

=head3 Output Variables

The function returns a single C<HashRef> containing the evaluated statistical results. Because the keys map dynamically to the terms parsed from your formula, the structure will vary based on your inputs.

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>(Term Name)</i></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>A nested hash for each independent term in the formula (e.g., <code>'Group'</code>, <code>'N:P'</code>), containing its ANOVA table statistics.</td>
  <td><code>{'Df' => 1, 'Sum Sq' => 14.2, 'Mean Sq' => 14.2, 'F value' => 25.81, 'Pr(>F)' => 0.0004}</code></td>
</tr>
<tr>
  <td><code>Residuals</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>A nested hash containing the residual (error) statistics for the fitted model.</td>
  <td><code>{'Df' => 10, 'Sum Sq' => 5.5, 'Mean Sq' => 0.55}</code></td>
</tr>
<tr>
  <td><code>group_stats</code></td>
  <td><code>HashRef</code></td>
  <td><code>undef</code></td>
  <td>A nested hash containing descriptive statistics (<code>mean</code> and <code>size</code> / count) for every column evaluated in the original unstacked data structure.</td>
  <td><code>{'mean' => {'A' => 2.1, 'B' => 5.4}, 'size' => {'A' => 10, 'B' => 10}}</code></td>
</tr>
</tbody>
</table>

=head3 omitting formula

As of version 0.07, in the case of an omitted formula, stacking is done:

 aov(
 {
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,     1,   1,   0,   0,   0]
 },
 );

is the equivalent of:

 yield <- c(5.5, 5.4, 5.8, 4.5, 4.8, 4.2)
 ctrl <- c(1,     1,   1,   0,   0,   0)
 
 # Combine them into a named list (the R equivalent of your hash)
 my_list <- list(yield = yield, ctrl = ctrl)
 
 # Convert the list into a "long" dataframe
 # This creates two columns: "values" and "ind" (the group name)
 my_data <- stack(my_list)
 
 # Rename columns for clarity (optional but good practice)
 colnames(my_data) <- c("Value", "Group")
 anova_model <- aov(Value ~ Group, data = my_data)
 summary(anova_model)

in R

=head2 assign

Add new columns to a data frame, computed from the columns already there — or handed in ready-made.

=head3 Usage

 assign($df, new_name => VALUE, another => VALUE, ...);

=over

=item * B<< C<$df> >> — your data frame, in any of three shapes:

=over

=item * B<AoH> — arrayref of row hashrefs: C<< [ {weight=E<gt>70, height=E<gt>1.75}, ... ] >>

=item * B<HoA> — hashref of column arrayrefs: C<< { weight=E<gt>[70,...], height=E<gt>[1.75,...] } >>

=item * B<HoH> — hashref of row hashrefs, keyed by row name: C<< { Alice=E<gt>{weight=E<gt>65}, ... } >>

=back

=item * B<< C<< new_name =E<gt> VALUE >> >> — one or more pairs. C<VALUE> is a B<coderef> (computed from the row), an B<arrayref> (a ready-made column), or a B<< C<map_cell { ... }> >> block (an in-place edit of the named column — see below).

=back

It changes C<$df> in place and also returns it (handy for chaining).

=head3 Coderef values

A coderef is classified by what it returns in list context:

=over

=item * B<One scalar → per-row.> The sub is called once per row and that scalar is the cell.

=over

=item * C<$_> (and C<$_[0]>) is the current row as a hashref, so you read other columns with C<< $_-E<gt>{colname} >>.

=item * C<$_[1]> is the row's index (0-based).

=item * C<$_[2]> is the row key — B<HoH only>.

=item * A single arrayref return is stored I<as the cell>, so C<< sub { [split /,/, $_-E<gt>{tags}] } >> gives an arrayref-valued column.

=back

=item * B<A list of more than one value → whole column.> The list becomes the entire column, distributed positionally. This is the natural fit for column functions like C<rank>:

 assign($df, 'ΔG rank' => sub { rank( vals($df, 'dG_kcal_mol') ) });
 # rank() returns a list, so the whole ranking lands in one column.

=back

=head3 Arrayref values

Pass a column you already have and it is copied in:

 assign($df, 'ΔG rank' => [ rank( vals($df, 'dG_kcal_mol') ) ]);

This is also how you install a computed I<list> when you'd otherwise trip the "single arrayref = one cell" rule above.

=head3 In-place edits with C<map_cell>

A plain coderef stores its B<return value>, so an in-place transform of an existing column means the "copy, edit, return" dance — and C<s///r> isn't available on the older perls this module supports:

 # awkward: copy to $v, edit $v, return $v
 assign($df, 'Res.' => sub { (my $v = $_->{'Res.'}) =~ s/^[A-Z]://; $v });

C<map_cell { ... }> removes the ceremony. Inside the block, B<< C<$_> is the named column's current cell >> (not the whole row), the block's return value is B<ignored>, and the modified C<$_> is stored back:

 use Stats::LikeR;   # exports map_cell alongside assign
 
 assign($df, 'Res.' => map_cell { s/^[A-Z]:// });   # strip a leading "X:"
 assign($df, 'Res.' => map_cell { $_ = uc });        # upper-case in place

The row is still reachable as B<< C<$_[0]> >> for sibling columns, the index as B<< C<$_[1]> >>, and (HoH only) the row key as B<< C<$_[2]> >>:

 assign($df, label => map_cell { $_ = "$_[0]{name} ($_[1])" });

Notes:
- B<Undef cells pass through untouched> (undef in → undef out). The block never runs on an undefined or missing cell, so C<s///> and friends don't warn on uninitialized values and a missing cell stays missing rather than becoming C<''>.
- Works on all three shapes (AoH, HoA, HoH). For HoA the target column B<must already exist> (there's no column to edit otherwise) — C<map_cell> on a missing HoA column dies.
- A plain C<sub { ... }> keeps its existing meaning (C<$_> = the whole row, return value stored); C<map_cell> is purely additive and changes nothing for existing callers.

=head3 Ordering and length

=over

=item * B<AoH> distributes by array order; B<HoH> by B<sorted key order> — so any list you compute or hand in must be in C<sort keys %$df> order.

=item * Whole-column and arrayref values must have exactly one entry per row; a length mismatch dies.

=back

=head3 Example

 my $df = [
     { weight => 70, height => 1.75 },
     { weight => 90, height => 1.80 },
 ];
 assign($df, bmi => sub { $_->{weight} / $_->{height} ** 2 });
 # $df is now:
 # [ { weight=>70, height=>1.75, bmi=>22.86 },
 #   { weight=>90, height=>1.80, bmi=>27.78 } ]

=head3 Good to know

=over

=item * B<Pairs run in order>, so a later column can use one you just made:

 assign($df,
     bmi   => sub { $_->{weight} / $_->{height} ** 2 },
     class => sub { $_->{bmi} > 25 ? 'high' : 'ok' },   # uses bmi
 );

=item * B<Same recipe, all shapes.> The same per-row C<< sub { $_-E<gt>{weight} / ... } >> works for AoH, HoA, and HoH; you always read the row through C<$_>.

=item * B<It modifies your data frame.> If you need to keep the original, pass a copy: C<assign(clone($df), ...)>.

=item * Reusing a column name B<overwrites> that column.

=back

=head2 bfill

Back-fill NA (undef) cells with the next valid value seen below them along the
row axis, like C<pandas.DataFrame.bfill>. See C<ffill> for the forward direction
and C<fillna> for constant fills.

 bfill($df,
     cols  => [ 'v' ],   # restrict to these columns (default: every column)
     limit => 2,         # max consecutive fills per gap (default: unlimited)
 );

Column identifiers are names for AoH/HoA/HoH and 0-based positions for AoA. The
row axis is positional for AoA/AoH/HoA and string-sorted key order for HoH (the
only deterministic order a HoH has). Filling stays within each column's
existing length: ragged HoA columns are not extended, and AoA rows are not
extended past their own length.

C<limit> caps the number of consecutive NA cells filled in a single gap; the
remaining cells in an over-long gap stay NA, and the count resets after the
next real value. A trailing run of NA (with nothing below it) is left as NA.

Returns a NEW frame; the input is never modified.

=head3 Example

 bfill([ { v => undef }, { v => 2 }, { v => undef } ], cols => [ 'v' ]);
 # [ { v => 2 }, { v => 2 }, { v => undef } ]   # trailing NA stays
 
 bfill({ b => { x => undef }, a => { x => 5 }, c => { x => undef } }, cols => [ 'x' ]);
 # sorted-key order a,b,c; nothing after a to pull back, so:
 # { a => { x => 5 }, b => { x => undef }, c => { x => undef } }

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; a
C<cols> column that does not exist; or a C<limit> that is not a positive integer.

=head2 binom_test

C<binom_test> answers one question: you ran a yes/no experiment C<n> times and
got C<x> successes — is that consistent with some assumed success rate, or is it
too far off to be chance? It is the exact binomial test, the same as R's
C<binom.test>.

=head3 A toddler and two cards

Show a toddler two cards each round and ask them to point at the one with the
star. If he/she is only guessing, he/she will be right half the time, so the
"pure guessing" success rate is C<p = 0.5>.

You play 10 rounds and the toddler gets 6 right. Real skill, or just luck?

 use Stats::LikeR 'binom_test';
 
 my $r = binom_test(6, 10, p => 0.5);   # 6 wins, 10 rounds, guessing rate 0.5
 
 print $r->{p_value};                   # 0.7539

The full result is a hashref:

 {
     statistic   => 6,            # times the toddler was right
     parameter   => 10,           # rounds played
     estimate    => 0.6,          # observed rate, 6/10
     null_value  => 0.5,          # the "pure guessing" rate we test against
     p_value     => 0.7539,
     conf_int    => [0.262, 0.878],
     conf_level  => 0.95,
     alternative => 'two.sided',
     method      => 'Exact binomial test',
 }

=head3 Reading the p-value

The p-value is the chance of seeing a result B<at least this surprising> if the
toddler were really just guessing.

Here C<p = 0.75>. That is enormous: a pure guesser scores 6/10 (or something
even further from 5) about three times out of four. So 6/10 is completely
ordinary luck — no evidence of skill.

The common cutoff is C<0.05>. Below it, you start to believe something real is
going on. Above it, chance explains the result fine. C<0.75> is nowhere close,
so we call this B<just chance>.

=head3 What "legit" would look like

Suppose the toddler had gone 9 for 10 instead:

 my $r = binom_test(9, 10, p => 0.5);
 
 print $r->{p_value};                   # 0.0215

Now C<p = 0.02>, under C<0.05>. A pure guesser almost never does that well, so
this B<is> good evidence the toddler can actually tell the cards apart.

=head3 The confidence interval

C<conf_int> is the plausible range for the toddler's true success rate. For
6/10 it runs from about C<0.26> to C<0.88> — wide, and it comfortably includes
C<0.5>. That overlap with the guessing rate is another way of seeing that luck
cannot be ruled out. For 9/10 the interval would sit well above C<0.5>.

=head3 Options

=over

=item * C<p> is the assumed success rate (default C<0.5>).

=item * C<alternative> is C<'two.sided'> (default), C<'less'>, or C<'greater'>. Use
C<'greater'> when you only care whether the toddler beats guessing, not
whether they do worse.

=item * C<conf_level> sets the interval width (default C<0.95>).

=back

You can also pass the counts as C<binom_test([6, 4])> — 6 right, 4 wrong — when
you have wins and losses instead of wins and a total.

=head2 cfilter

Select B<columns> out of a table and return it in the same shape. A column is
the inner (second-level) key of a B<hash of hashes> or an B<array of hashes>,
or the outer key of a B<hash of arrays>:

 use Stats::LikeR;
 my %hoa = ( x => [1,2,3], y => [4,5,6], z => [0,0,0] );
 cfilter(\%hoa, keep   => ['x','y']);  # { x => [1,2,3], y => [4,5,6] }
 cfilter(\%hoa, remove => ['z']);      # { x => [1,2,3], y => [4,5,6] }

C<cfilter> takes exactly one of C<keep> or C<remove>. C<keep> returns only the
matching columns; C<remove> returns everything except them. The result is the
same shape as the input (HoH → HoH, HoA → HoA, AoH → AoH), with cell values
copied and the original structure left untouched.

The selector — the value of C<keep> or C<remove> — can be given three ways:

=over

=item * an B<array ref> of exact column names,

=item * a B<< C<qr//> regex >> matched against column names,

=item * a B<predicate> (CODE ref or function name) evaluated against a column's
values.

=back

The first two select by name; the predicate is the one that looks at the data.

=head3 Selecting by name

Pass an array ref of column names. Naming a column that is not present in the
data is an error (it catches typos), and a row that happens not to contain a
kept column simply comes back without it:

 my @aoh = ( { a => 1, b => 2 }, { a => 3 } );
 cfilter(\@aoh, keep => ['b']);   # [ { b => 2 }, {} ]

=head3 Selecting by a name pattern

Pass a C<qr//> regex, and columns are kept (or removed) according to whether
their B<name> matches. This is the concise way to act on a family of columns:

 # drop every column whose name contains "step" or "bias_"
 cfilter(\%md, remove => qr/(?:step|bias_)/);
 # keep only the y0, y1, ... columns
 cfilter(\%md, keep => qr/^y\d+$/);

The pattern matches anywhere in the name (it is not anchored), exactly like
Perl's C<=~>. Unlike a named column, a pattern that matches nothing is not an
error — it simply keeps or removes nothing.

=head3 Selecting by a predicate

Instead of names, C<keep>/C<remove> accept a B<predicate> — a CODE ref or a
function name — evaluated once per column. It is called as

 $predicate->($column_values, $column_name)

where C<$column_values> is an array ref of the column's B<defined> cells (undef
and missing cells are dropped, so functions like C<sd> get clean input).
With C<keep>, columns for which the predicate is true are kept; with C<remove>,
those columns are dropped.

 # Keep only the constant columns (standard deviation zero):
 my $const = cfilter(\%hoa, keep => sub { sd($_[0]) == 0 });   # { z => [0,0,0] }
 # Drop the constant columns instead:
 my $varying = cfilter(\%hoa, remove => sub { sd($_[0]) == 0 }); # { x=>..., y=>... }
 # A bare function name resolves in Stats::LikeR:: (use a package for your own):
 cfilter(\%hoa, keep => 'some_predicate');

A bare string is always treated as a B<function name>, not a single column
name, so to keep one column by name use an array ref: C<< keep =E<gt> ['x'] >>.

=head3 Errors

C<cfilter> dies (via C<croak>) when:

=over

=item * neither C<keep> nor C<remove> is given, or both are,

=item * a named column is not present in the data,

=item * the selector is not an array ref, a C<qr//> regex, or a code ref / function
name, or the function name cannot be resolved,

=item * C<na> or C<against> is given with a by-name or regex selector (they apply only
to a value predicate),

=item * an unknown option is given, or the options are not C<< name =E<gt> value >> pairs,

=item * the data is not a hash/array reference of the expected shape (a hash of hash
refs or array refs, or an array of hash refs).

=back

=head2 chisq_test

The C<chisq_test> function performs chi-squared contingency table tests and goodness-of-fit tests. It natively accepts both arrays and hashes (1D and 2D) and mathematically mirrors R's C<chisq.test()>, returning a structured hash reference of the results.

For 2x2 matrices, Yates' Continuity Correction is applied automatically.

=head3 Accepted Inputs

=for html <table>
<thead>
<tr>
  <th>Input Type</th>
  <th>Data Structure</th>
  <th>Applied Test</th>
</tr>
</thead>
<tbody>
<tr>
  <td><b>1D Array</b></td>
  <td><code>[ $v1, $v2, ... ]</code></td>
  <td>Chi-squared test for given probabilities</td>
</tr>
<tr>
  <td><b>2D Array</b></td>
  <td><code>[ [ $v1, $v2 ], [ $v3, $v4 ] ]</code></td>
  <td>Pearson's Chi-squared test (Yates' correction if 2x2)</td>
</tr>
<tr>
  <td><b>1D Hash</b></td>
  <td><code>{ key1 => $v1, key2 => $v2 }</code></td>
  <td>Chi-squared test for given probabilities</td>
</tr>
<tr>
  <td><b>2D Hash</b></td>
  <td><code>{ row1 => { c1 => $v1, c2 => $v2 } }</code></td>
  <td>Pearson's Chi-squared test (Yates' correction if 2x2)</td>
</tr>
</tbody>
</table>

=head3 Output Object Structure

The function returns a single Hash Reference containing the following key-value pairs. The internal structure of C<expected> and C<observed> will always identically match the structure of your input.

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Data Type</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><b>data.name</b></td>
  <td>String</td>
  <td>Identifies the input type (e.g., <code>"Perl ArrayRef"</code> or <code>"Perl HashRef"</code>).</td>
</tr>
<tr>
  <td><b>expected</b></td>
  <td>Array/Hash Ref</td>
  <td>The expected frequencies, matching the geometry of the input.</td>
</tr>
<tr>
  <td><b>method</b></td>
  <td>String</td>
  <td>The specific statistical test applied.</td>
</tr>
<tr>
  <td><b>observed</b></td>
  <td>Array/Hash Ref</td>
  <td>The original data passed to the function.</td>
</tr>
<tr>
  <td><b>p.value</b></td>
  <td>Float</td>
  <td>The calculated p-value of the test.</td>
</tr>
<tr>
  <td><b>parameter</b></td>
  <td>Hash Ref</td>
  <td>Contains the degrees of freedom (<code>df</code>).</td>
</tr>
<tr>
  <td><b>statistic</b></td>
  <td>Hash Ref</td>
  <td>Contains the test statistic (<code>X-squared</code>).</td>
</tr>
</tbody>
</table>

=head3 Two-Dimensional Array

Passing an Array of Arrays (AoA) triggers a standard Pearson's Chi-squared test. If the input is exactly a 2x2 matrix, Yates' continuity correction is applied automatically.

 my $test_data = [
     [762, 327, 468], 
     [484, 239, 477]
 ];
 my $res = chisq_test($test_data);

B<Output:>

 {
     'data.name' => 'Perl ArrayRef',
     'expected'  => [
         [ 703.671381936888, 319.645266594124, 533.683351468988 ],
         [ 542.328618063112, 246.354733405876, 411.316648531012 ]
     ],
     'method'    => "Pearson's Chi-squared test",
     'observed'  => [
         [ 762, 327, 468 ],
         [ 484, 239, 477 ]
     ],
     'p.value'   => 2.95358918321176e-07,
     'parameter' => { 'df' => 2 },
     'statistic' => { 'X-squared' => 30.0701490957547 }
 }

=head3 1-Dimensional Array (Goodness of Fit)

Passing a flat Array Reference triggers a Goodness of Fit test, assuming equal expected probabilities across all items.

 my $data = [10, 20, 30];
 my $res = chisq_test($data);

B<Output:>

 {
     'data.name' => 'Perl ArrayRef',
     'expected'  => [ 20, 20, 20 ],
     'method'    => 'Chi-squared test for given probabilities',
     'observed'  => [ 10, 20, 30 ],
     'p.value'   => 0.00673794699908547,
     'parameter' => { 'df' => 2 },
     'statistic' => { 'X-squared' => 10 }
 }

=head3 2-Dimensional Hash (Pearson's Chi-squared)

Passing a Hash of Hashes (HoH) applies the exact same logic as a 2D Array, but preserves your nested string keys in the output. This is particularly useful when mapping data extracted directly from JSON, databases, or categorical mappings.

 my $data = {
     GroupA => { Success => 10, Failure => 15 },
     GroupB => { Success => 20, Failure => 5  }
 };
 
 my $res = chisq_test($data);

B<Output:>

 {
     'data.name' => 'Perl HashRef',
     'expected'  => {
     'GroupA' => { 'Failure' => 10, 'Success' => 15 },
     'GroupB' => { 'Failure' => 10, 'Success' => 15 }
 },
 'method'    => "Pearson's Chi-squared test with Yates' continuity correction",
     'observed'  => {
     'GroupA' => { 'Failure' => 15, 'Success' => 10 },
     'GroupB' => { 'Failure' => 5,  'Success' => 20 }
     },
     'p.value'   => 0.00937475878430379,
     'parameter' => { 'df' => 1 },
     'statistic' => { 'X-squared' => 6.75 }
 }

=head3 One-Dimensional Hash (Goodness of Fit)

Flat Hash References evaluate Goodness of Fit while preserving your categorical keys in the C<expected> and C<observed> output blocks.

 my $data = { 
     Apples  => 10, 
     Oranges => 20, 
     Bananas => 30 
 };
 
 my $res = chisq_test($data);

=head2 chunk

Split an array into contiguous, roughly equal groups by I<position>. Unlike
L<#qcut>, C<chunk> does not inspect values, sort, or compute cutpoints; it
slices the array in the order given. Use it for batching work, paginating, or
grouping non-numeric data such as strings.

=head3 Signature

 my @groups = chunk($data, size  => $n);   # fixed elements per group
 my @groups = chunk($data, parts => $k);   # fixed number of groups

=over

=item * C<$data> — an array reference. Its contents are never examined or sorted;
elements are grouped in input order.

=back

Pass exactly one of C<size> or C<parts>. Passing both, or neither, is a fatal
error — the two readings of "equal groups" differ (see below), so the caller
chooses which one is meant rather than relying on a default.

=over

=item * C<< size =E<gt> $n >> — each group holds C<$n> elements; the final group holds
whatever remains.

=item * C<< parts =E<gt> $k >> — the array is divided into C<$k> groups as equal as possible,
with any remainder spread across the leading groups.

=back

=head3 Return value

A list of array references, in input order — call it in list context:

 my @groups = chunk($data, parts => 4);

Passing more C<parts> than there are elements yields trailing empty groups
(matching C<numpy.array_split>), so no elements are ever dropped. An empty input
array returns an empty list.

=head3 Examples

C<size> fixes the elements per group; the last group is the remainder. Splitting
the 26 letters into groups of five leaves one over:

 my @groups = chunk(['a' .. 'z'], size => 5);
 # 6 groups, sizes 5,5,5,5,5,1
 # [a b c d e] [f g h i j] [k l m n o] [p q r s t] [u v w x y] [z]

C<parts> fixes the number of groups; the remainder is absorbed by the leading
groups instead:

 my @groups = chunk(['a' .. 'z'], parts => 5);
 # 5 groups, sizes 5,5,5,5,6
 # [a b c d e] [f g h i j] [k l m n o] [p q r s t] [u v w x y z]

When the split is even the two forms agree:

 my @a = chunk([1 .. 10], size  => 2);
 my @b = chunk([1 .. 10], parts => 5);
 # identical: 5 groups of 2

Order is preserved — C<chunk> never sorts. Sort the array yourself first if you
want ordered groups:

 my @groups = chunk([3, 1, 2], size => 2);
 # ([3, 1], [2])

More parts than elements gives empty trailing groups, losing nothing:

 my @groups = chunk([1, 2, 3], parts => 5);
 # 5 groups; flattening them back gives (1, 2, 3)

=head2 col2col

Apply a B<two-column function> to every pair of columns in a table and collect
the answers in a hash of hashes.

It's the workhorse behind things like correlation matrices: give it your data and
the name of a function that takes two columns (C<cor>, C<t_test>, …) and you get
back every column compared against every other column.

 use Stats::LikeR;
 
 my %data = (
     height => [ 170, 165, 180, 175 ],
     weight => [  70,  60,  85,  77 ],
     age    => [  30,  41,  25,  38 ],
 );
 
 my $result = col2col(\%data, 'cor');
 
 # $result->{height}{weight}  == correlation of height vs weight
 # $result->{height}{age}     == correlation of height vs age
 # ...and so on for every pair

========================================================================

=head3 Arguments

 col2col( $data, $command, $cols, %options )
 col2col( $data, $command, \%options )      # options in place of $cols

=for html <table>
<thead>
<tr>
  <th>Position</th>
  <th>Argument</th>
  <th>What it is</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>$data</code></td>
  <td>Your table, as a reference (see <b>Data shapes</b> below).</td>
</tr>
<tr>
  <td>2</td>
  <td><code>$command</code></td>
  <td>A code block <b>or</b> the name of a two-column function.</td>
</tr>
<tr>
  <td>3</td>
  <td><code>$cols</code></td>
  <td><i>(optional)</i> Which columns to use as the "from" side. Omit for all.</td>
</tr>
<tr>
  <td>4+</td>
  <td><code>%options</code></td>
  <td><i>(optional)</i> <code>na</code>, <code>skip.errors</code>, … (see <b>Options</b>).</td>
</tr>
</tbody>
</table>

========================================================================

=head3 Data shapes

C<col2col> understands three layouts. In every case a B<column> is the thing that
gets compared, and the result is keyed by column name.

B<Hash of arrays (HoA)> — keys are column names:

 my %hoa = ( a => [1, 2, 3], b => [4, 5, 6] );

B<Hash of hashes (HoH)> — First keys are row names, second keys are columns:

 my %hoh = (
     row1 => { a => 1, b => 4 },
     row2 => { a => 2, b => 5 },
 );

B<Array of hashes (AoH)> — each element is a row, inner keys are columns:

 my @aoh = ( { a => 1, b => 4 }, { a => 2, b => 5 } );

All three produce the same result for the same underlying numbers. Missing or
C<undef> cells are handled by the C<na> option (below).

========================================================================

=head3 The command

The second argument is the function applied to each pair of columns. It is called
as:

 $command->( $column_a, $column_b )    # two ARRAY refs

so inside a block the two columns arrive in C<@_>:

 my $result = col2col(\%data, sub {
     my ($x, $y) = @_;       # $x and $y are array refs
     cor($x, $y);
 });

You can also pass a B<function name as a string>. A bare name is looked up in
C<Stats::LikeR::>, so these two are equivalent:

 col2col(\%data, 'cor');
 col2col(\%data, sub { cor($_[0], $_[1]) });

========================================================================

=head3 The result

Always a hash of hashes: B<< C<< $result-E<gt>{from}{to} >> >>.

 for my $from (sort keys %$result) {
    for my $to (sort keys %{ $result->{$from} }) {
       printf "%s vs %s = %s\n", $from, $to, $result->{$from}{$to};
    }
 }

A column is never compared with itself, so C<< $result-E<gt>{a}{a} >> does not exist.

========================================================================

=head3 Restricting columns (C<$cols>)

By default every column is used as the "from" side. The third argument narrows
that down — handy when you only care about one variable.

 # all columns vs all columns
 my $all = col2col(\%data, 'cor');
 # just ONE column vs every other column
 my $one = col2col(\%data, 'cor', 'height');
 my $cors = $one->{height};          # { weight => ..., age => ... }
 # a FEW specific columns vs every other column
 my $few = col2col(\%data, 'cor', ['height', 'weight']);

The "to" side is always every other column; C<$cols> only limits the outer keys.

========================================================================

=head3 Options

Options can be given two ways:

 col2col(\%data, 'cor', $cols, 'skip.errors' => 0);   # after $cols
 col2col(\%data, 'cor', { 'skip.errors' => 0 });      # hash ref, no $cols needed

The hash-ref form is convenient when you have B<no> column restriction — it saves
you from passing a placeholder. (A hash ref I<replaces> C<$cols>, so you can't use
it to restrict columns at the same time; use the trailing form for that.)

=head4 C<na> — how undefined values are handled

Real data has gaps. C<na> decides what the function sees.

=for html <table>
<thead>
<tr>
  <th>Value</th>
  <th>Behaviour</th>
  <th>Use for</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>'pairwise'</code> <i>(default)</i></td>
  <td>A row is used for a pair only if <b>both</b> columns are defined there. The two columns arrive aligned and equal-length.</td>
  <td>Paired stats like <code>cor</code>.</td>
</tr>
<tr>
  <td><code>'omit'</code></td>
  <td>Each column drops <b>its own</b> undefined values independently. The two columns may end up <b>different lengths</b>.</td>
  <td>Unpaired tests like <code>t_test</code>, <code>kruskal_test</code>, where a gap in one sample shouldn't discard a value in the other.</td>
</tr>
<tr>
  <td><code>'keep'</code></td>
  <td>Every row is passed through, <code>undef</code> and all.</td>
  <td>When your function does its own missing-data handling.</td>
</tr>
</tbody>
</table>

 # correlation: keep only complete pairs (the default)
 col2col(\%data, 'cor');
 # two-sample test: each column keeps its own values
 col2col(\%data, 't_test', undef, na => 'omit');
 col2col(\%data, 't_test', { na => 'omit' });        # same, no placeholder

C<rm.undef> / C<rm.na> remain as boolean aliases for backward compatibility:
C<true> means C<'pairwise'>, C<false> means C<'keep'>. Don't combine them with C<na>.

=head4 C<skip.errors> — keep going when a pair fails I<(default: true)>

Some functions croak on degenerate input — for example C<cor> dies if a column has
zero variance. By default C<col2col> B<traps> that croak per pair: instead of
aborting the whole run, it stores the B<first line> of the error message in that
cell, so the result tells you I<which> pair failed and I<why>. Every other cell is
computed normally.

 my $r = col2col(\%data, 'cor');
 # a good pair:   $r->{a}{b} == 0.83
 # a bad pair:    $r->{a}{const} eq 'cor: standard deviation of y is 0'

To restore the old "die on the first error" behaviour, turn it off:

 col2col(\%data, 'cor', undef, 'skip.errors' => 0);
 col2col(\%data, 'cor', { 'skip.errors' => 0 });

Only errors from B<your function> are trapped. Mistakes in the call itself
(unknown column, bad data, unknown function name, unknown option) always die.

========================================================================

=head3 Worked examples

B<Full correlation matrix:>

 my $m = col2col(\%data, 'cor');

B<One variable against all others, sorted strongest first, skipping failures:>

 my $col  = 'Testosterone, total (nmol/L)';
 my $cors = col2col($hoa, 'cor', $col)->{$col};
 for my $other (sort { ($cors->{$b} // -2) <=> ($cors->{$a} // -2) } keys %$cors) {
     next unless $cors->{$other} =~ /^-?\d/;        # skip cells holding an error message
     printf "%-30s % .3f\n", $other, $cors->{$other};
 }

B<Two-sample test across columns of unequal completeness:>

 my $t = col2col($hoa, 't_test', undef, na => 'omit');

B<Find which pairs could not be computed:>

 my $m = col2col($hoa, 'cor');
 for my $from (sort keys %$m) {
     for my $to (sort keys %{ $m->{$from} }) {
         my $v = $m->{$from}{$to};
         warn "$from vs $to: $v\n" if defined $v && $v !~ /^-?\d/;   # non-numeric = error
     }
 }

========================================================================

=head3 Gotchas

=over

=item * B<Your function receives two array refs>, C<($col_a, $col_b)> — not a column and
a name. Unpack with C<my ($x, $y) = @_;>.

=item * B<< C<'pairwise'> can still hit a constant I<subset>. >> A column with overall
variance can be flat on just the rows it shares with one partner, so C<cor> may
still croak for that pair. With the default C<skip.errors>, that shows up as a
message in the single offending cell rather than killing the run.

=item * B<< C<col2col> does not modify your data. >> It reads the table and returns a new
hash of hashes.

=item * B<In the error message, "x" is the first column and "y" is the second> — i.e.
C<y> is the inner ("to") key. So C<< $result-E<gt>{A}{B} >> reading C<…deviation of y is 0>
means column C<B> is the degenerate one for that pair.

=back

=head2 colnames

Return the column names of a data frame, as a list (like R's C<colnames>).
Works on all four Stats::LikeR frame shapes and mirrors the column order
C<view> shows:

=over

=item * C<AoA> — 0-based integer indices, C<0 .. widest_row-1>

=item * C<AoH> — the string-sorted union of the keys of every row

=item * C<HoA> — the string-sorted keys (the keys I<are> the columns)

=item * C<HoH> — the string-sorted union of the inner-row keys

=back

In scalar context it returns the count, so C<scalar colnames($df)> equals
C<ncol($df)> for a rectangular frame.

 my $aoh = [ { b => 2, a => 1 }, { a => 3, c => 9 } ];
 my @cols = colnames($aoh);        # ('a', 'b', 'c')  -- union, sorted
 
 my $hoa = { z => [1,2], a => [3,4], m => [5,6] };
 my @cols = colnames($hoa);        # ('a', 'm', 'z')
 
 my $aoa = [ [1,2,3], [4,5,6] ];
 my @cols = colnames($aoa);        # (0, 1, 2)
 
 my $n = colnames($hoa);           # 3  (scalar context == ncol)

=head2 concat

Row-bind two or more data frames: stack their rows into one new frame, the
analog of pandas C<concat(..., axis=0)> and R's C<rbind>. C<rbind> is provided as a
true synonym (the same subroutine), so the two names are interchangeable.

C<concat> accepts all four data-frame shapes and returns a new frame of that same
shape:

 AoA  [ [ .. ], [ .. ] ]      array of arrayrefs   (positional columns)
 AoH  [ { .. }, { .. } ]      array of hashrefs    (the read_table default)
 HoA  { c => [ .. ], .. }     hash of arrayrefs    (column-major)
 HoH  { r => { .. }, .. }     hash of hashrefs     (named rows)

Every frame must be the same shape; mixing shapes dies with a hint to convert
first (C<aoh2hoa>, C<hoa2aoh>, C<hoh2hoa>, C<aoh2hoh>). undef frames and empty
frames are skipped, and the shape is taken from the first non-empty frame. The
original frames are never modified.

=head3 Usage

 use Stats::LikeR;
 
 my $all = concat($df1, $df2, $df3);   # any number of frames
 my $all = rbind($df1, $df2);          # identical: rbind is a synonym

=head3 Array of Arrays (AoA)

The outer arrays are concatenated in order and the row arrayrefs are reused by
reference (not copied). Ragged rows are kept as-is; reading past a short row
yields undef.

 my $a = [ [ 1, 2 ], [ 3, 4 ] ];
 my $b = [ [ 5, 6 ], [ 7 ]    ];   # ragged last row
 my $c = concat($a, $b);

B<Resulting Structure:>

 [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ], [ 7 ] ]

=head3 Array of Hashes (AoH)

The rows are concatenated in order and the row hashrefs are reused by reference.
The result is the union of columns; a column absent from a given row simply
reads as undef, matching this module's "missing key means undef" convention
(as used by C<dropna>, C<view>, and C<summary>).

 my $a = [ { id => 1, x => 10 } ];
 my $b = [ { id => 2, x => 20, y => 99 } ];   # extra column y
 my $c = concat($a, $b);

B<Resulting Structure:>

 [
     { id => 1, x => 10           },   # no 'y' key -> reads as undef
     { id => 2, x => 20, y => 99  },
 ]

=head3 Hash of Arrays (HoA)

The output columns are the union of all input columns, sorted for a
deterministic layout. Each column is the per-frame arrays joined in frame order.
Because HoA is column-major, a column missing from a frame — or a ragged short
column within a frame — is padded with undef so every output column ends up the
same length (the total number of rows).

 my $a = { g => [ 'a', 'a' ], v => [ 1, 2 ] };
 my $b = { g => [ 'b' ],      w => [ 9 ]    };   # v absent here, w is new
 my $c = concat($a, $b);

B<Resulting Structure:>

 {
     g => [ 'a',   'a',   'b' ],
     v => [ 1,     2,     undef ],   # padded for the frame that lacked 'v'
     w => [ undef, undef, 9     ],   # padded for the frame that lacked 'w'
 }

=head3 Hash of Hashes (HoH)

The outer hashes are merged in frame order and the inner row hashrefs are reused
by reference. Because a Perl hash cannot hold duplicate keys, a repeated row
name is made unique R-style — C<name>, C<name.1>, C<name.2>, … — and a single
warning is emitted noting that row names collided.

 my $a = { r => { v => 1 } };
 my $b = { r => { v => 2 } };
 my $c = concat($a, $b);
 # warns: concat: duplicate HoH row name(s) made unique with a .N suffix

B<Resulting Structure:>

 {
     r     => { v => 1 },
     'r.1' => { v => 2 },
 }

=head3 Empty and single inputs

undef and empty frames are skipped, so they can be threaded through a pipeline
harmlessly:

 concat(undef, [], [ { n => 1 } ], [ { n => 2 } ]);   # two rows

When every frame is empty the result is an empty frame matching the first
argument's reference type (C<[]> for an arrayref, C<{}> for a hashref). A single
frame round-trips unchanged.

=head3 rbind

C<rbind> is the same subroutine as C<concat>, exported under a second name for
readers who know it from R:

 my $c = rbind($df1, $df2);
 
 # they are literally the same code reference:
 \&Stats::LikeR::rbind == \&Stats::LikeR::concat;   # true

=head3 Errors

C<concat> (and therefore C<rbind>) dies (with a trailing newline) when:

=over

=item * no usable frame is given;

=item * a frame is neither an ARRAY nor a HASH ref;

=item * the frames are not all the same shape (the message names the two shapes and
suggests the relevant converter);

=item * an AoA element is not an arrayref, or an AoH/HoH row is not a hashref.

=back

=head3 See also

C<agg> (split-apply-combine), C<add_data> (which also appends HoA columns and
merges HoH rows), C<ljoin>, C<aoh2hoa>, C<hoa2aoh>, C<hoh2hoa>, C<aoh2hoh>.

=head2 cor

 cor($array1, $array2, $method = 'pearson'),

that is, C<pearson> is the default and will be used if C<$method> is not specified.

Just like R, C<pearson>, C<spearman>, and C<kendall> are available

If you provide an array of arrays (a matrix), C<cor> will compute the correlation matrix automatically. 

=head2 cor_test

 my $result = cor_test(
         'x'         => $x,
         'y'         => $y,
         alternative => 'two.sided',
         method      => 'pearson',
         continuity  => 1
     );

C<cor_test> safely handles C<undef> (or C<NA>) values seamlessly by computing over pairwise complete observations. 

=head2 cov

 cov($array1, $array2, 'pearson')

or

 cov($array1, $array2, 'spearman')

or

 cov($array1, $array2, 'kendall')

=head2 csort

Sort a data frame by a column or a custom comparator, returning a new
(sorted) copy. The input is never mutated.

 my $sorted = csort($data, $by);
 my $sorted = csort($data, $by, $output_shape);
 my $sorted = csort($hoh,  $by, 'aoh', 'row.name');   # HoH only

C<$data> may be any of four shapes:

 AoH   array-of-hashes    [ { col => val, ... }, ... ]   columns are hash keys
 HoA   hash-of-arrays      { col => [ val, ... ], ... }   columns are hash keys
 HoH   hash-of-hashes      { rowname => { col => val }, ... }
 AoA   array-of-arrays    [ [ val, ... ], ... ]           columns are integer indices

The shape is detected automatically. An array-ref whose first row is
itself an array-ref is treated as an AoA; otherwise an array-ref is an
AoH. A hash-ref whose first value is a hash-ref is a HoH (its outer keys
are folded into a row-name column, see below); any other hash-ref is a
HoA.

C<$by> selects the sort key:

 'No.'                          # a column: name (AoH/HoA/HoH) or integer index (AoA)
 2                              # AoA: sort by column index 2
 sub { $a->{'No.'} <=> $b->{'No.'} }   # comparator; $a/$b are the rows

For a column sort the values are compared numerically when every present
value looks like a number, and with string C<cmp> otherwise. For a
comparator, C<$a> and C<$b> are the row references (a hash-ref for
AoH/HoA/HoH, an array-ref for AoA), exactly as with Perl's own C<sort>.

=head3 Sorting an AoA

Columns in an AoA are addressed by non-negative integer index:

 my $rows = [
     [ 3, 30, 'gamma' ],
     [ 1, 10, 'alpha' ],
     [ 2, 20, 'beta'  ],
 ];
 
 my $s = csort($rows, 0);       # by column 0 -> id 1, 2, 3
 my $s = csort($rows, 2);       # by column 2 -> alpha, beta, gamma
 my $s = csort($rows, sub { $b->[1] <=> $a->[1] });   # by column 1, descending

The result reuses the original row array-refs (a reorder, not a deep
copy), so it is cheap and the caller's data is left untouched. A
non-integer or negative index croaks; an index no row contains is
reported as a missing column.

=head3 Undefined and missing values

Undefined or missing cells always sort to the end. A "missing" cell is a
row that lacks the key (AoH/HoH) or is shorter than the index (AoA); it
is treated the same as an explicit C<undef>. Defined values are ordered
first (ascending, or per the comparison type), undef/missing last, and
undef rows keep their original relative order.

 my $rows = [
     [ 1, 5 ],
     [ 2 ],           # no column 1
     [ 3, undef ],
     [ 4, 1 ],
 ];
 my $s = csort($rows, 1);       # column-0 order: 4, 1, 2, 3

This holds for every shape, for numeric and string columns, and for
B<both> a column/index sort and a comparator sort:

 # no need to guard undef yourself -- this does not warn or die,
 # even under  use warnings FATAL => 'all'
 my $s = csort($df, sub { $a->{'tau p'} <=> $b->{'tau p'} }, 'hoa');

For a comparator, csort can't see which field you key on, so it probes
each row once (comparing the row to itself) to find rows whose comparator
would read an C<undef>; those rows are moved to the end and the rest are
sorted normally, so your comparator never sees an C<undef>. A few
consequences worth knowing:

=over

=item * If your comparator reads several keys (a tie-break), a row is treated as
undef-keyed when I<any> key the comparator actually evaluates for that
row is undef. Such rows go to the bottom.

=item * A comparator that handles undef itself (e.g. C<< $a-E<gt>{v} // 0 >>) never trips
the probe, so csort leaves its ordering completely alone.

=item * A comparator that dies for a real reason still propagates that error
unchanged.

=item * The probe calls your comparator once per row, so keep comparators free
of side effects (they should be anyway).

=back

=head3 Choosing the output shape

The optional third argument picks the returned shape, one of C<'aoh'>,
C<'hoa'>, or C<'aoa'> (case-insensitive). It defaults to the input shape
(HoH defaults to AoH). Any shape can be converted to any other:

 csort($aoa, 0)               # AoA -> AoA (default)
 csort($aoa, 0, 'hoa')        # AoA -> HoA
 csort($aoh, 'No.', 'aoa')    # AoH -> AoA

When the target is AoH or HoA, an AoA's columns are keyed by their
stringified index (C<'0'>, C<'1'>, ...). When the target is AoA, the
positional column order is deterministic:

 from HoA   sorted column-key name
 from AoH   union of the rows' keys, sorted by name
 from AoA   integer index 0 .. widest-row-1 (ragged rows pad with undef)

Because Perl randomizes hash iteration order, the sort of key names is
what makes keyed-to-AoA conversions reproducible from run to run.

=head3 Sorting a HoH

For a HoH, each outer key is the row name. It is folded into a real
column so it survives into the output; the column is named C<row.name> by
default, overridable with a fourth argument:

 my $s = csort($hoh, 'score', 'aoh');           # row name in 'row.name'
 my $s = csort($hoh, 'score', 'aoh', 'sample'); # ... named 'sample' instead

=head2 dnorm

gives the density of the normal distribution, with the specified mean and standard deviation.

In other words, the predicted height of the value C<x>, given a mean, standard deviation, and whether or not to use a log value.

returns a single scalar/number if a single value is given, otherwise returns an array reference.

Usage:

 dnorm(4) # assumes a mean of 0 and standard deviation of 1

but default mean, standard deviation, and log can be passed as parameters:

 $x = dnorm(0, mean => 0, sd => 2, 'log' => 0);

=head2 drop_cols

Return a new data frame with the named columns removed and the rest kept —
C<df.drop(columns=[...])>. Same identifiers and argument forms as
C<select_cols>.

 my $hoa = { a => [1,4], b => [2,5], c => [3,6] };
 drop_cols($hoa, 'b');
 # { a => [1,4], c => [3,6] }
 
 my $aoa = [ [1,2,3], [4,5,6] ];
 drop_cols($aoa, 1);          # result is re-indexed 0,1
 # [ [1,3], [4,6] ]

Unlike C<select_cols>, C<drop_cols> touches only the keys a row actually has,
so a ragged frame stays ragged:

 drop_cols([ {a=>1,b=>2}, {a=>3,c=>9} ], 'a');
 # [ { b => 2 }, { c => 9 } ]

=head2 drop_duplicates

Remove duplicate rows, loosely modeled on pandas' C<DataFrame.drop_duplicates>.
Works on the three positional/columnar shapes — AoA C<[ [..], .. ]>, AoH
C<< [ {A=E<gt>..}, .. ] >>, and HoA C<< { A=E<gt>[..], .. } >> — but B<not> HoH: its rows are
labeled, so row-level de-duplication has no natural meaning (convert with
C<hoh2aoh>/C<hoh2hoa> first).

=head3 Usage

 drop_duplicates($df);                          # dedupe on every column
 drop_duplicates($df, subset => 'id');          # only look at column 'id'
 drop_duplicates($df, subset => ['a', 'b']);    # a composite key
 drop_duplicates($df, keep => 'last');          # keep the last occurrence
 drop_duplicates($df, keep => 0);               # drop EVERY duplicated row

Two rows are duplicates when their cells are equal in every C<subset> column.
Comparison is by B<stringified value with a distinct undef (NA)> — the same
key semantics C<merge> uses — so C<1> and C<"1.0"> are I<not> equal, while two
undef cells I<are> equal to each other.

=head3 C<subset> — which columns define a row's identity

Defaults to every column. Column identifiers are B<0-based integer positions>
for AoA and B<names> for AoH/HoA. Pass a single column as a scalar or several
as an arrayref. The default column set is the widest row's positions for AoA,
the sorted union of row keys for AoH, and the sorted keys for HoA.

 my $aoh = [ { id => 1, v => 'a' }, { id => 1, v => 'b' }, { id => 2, v => 'c' } ];
 drop_duplicates($aoh, subset => 'id');
 # [ { id => 1, v => 'a' }, { id => 2, v => 'c' } ]

Columns outside C<subset> are not compared, but they stay aligned — a surviving
row keeps all of its columns.

=head3 C<keep> — which occurrence survives

=over

=item * B<< C<'first'> >> (default) — keep the earliest occurrence of each row.

=item * B<< C<'last'> >> — keep the latest occurrence.

=item * B<< C<0> >> (or C<'none'>) — drop I<every> row that has a duplicate, keeping only
rows that were unique.

my $df = { id => [1, 1, 2], v => [10, 20, 30] };
drop_duplicates($df, subset => 'id');                 # { id => [1, 2], v => [10, 30] }
drop_duplicates($df, subset => 'id', keep => 'last'); # { id => [1, 2], v => [20, 30] }

=back

Row order is preserved: the survivors come out in their original first-seen
positions.

=head3 Good to know

=over

=item * B<Returns a new data frame; the original is never modified.> For HoA the
columns are rebuilt (cell values copied); for AoA and AoH the surviving row
references are reused, not deep-copied. Clone the result if you need full
independence.

=item * B<It dies> on: undefined or non-ref data; an HoH frame; an unknown argument;
an empty or duplicated C<subset>; an invalid C<keep>; an AoA position that is
not a non-negative integer or is out of range; or a C<subset> name absent from
an AoH or HoA.

=item * An empty frame returns empty rather than erroring.

=back

=head2 dropna

Drop missing data from a data frame, loosely modeled on pandas' C<dropna>. Works
on all three shapes: AoH C<< [ {A=E<gt>..}, .. ] >>, HoA C<< { A=E<gt>[..], .. } >>, and
HoH C<< { r1=E<gt>{A=E<gt>..}, .. } >>.

=head3 Usage

 # NA mode: drop rows that are undef in the named columns
 dropna($df, cols => ['A', 'B']);
 dropna($df, cols => ['A', 'B'], how => 'all');
 # deletion mode: remove specific rows outright
 dropna($df, rows => [2, 5]);          # indices for AoH/HoA, keys for HoH

You pass B<exactly one> of C<cols> or C<rows>.

=head3 C<cols> — drop rows with missing values

Inspect only the named columns and drop the rows where they're undef. Columns
you don't name are never inspected, but they stay aligned (their cell at a
dropped row goes too). A missing key counts as undef.

C<how> controls the threshold:

=over

=item * B<< C<'any'> >> (default) — drop a row if I<any> named column is undef there.

=item * B<< C<'all'> >> — drop a row only if I<every> named column is undef there.

my $df = { A => [1, 2, undef], B => [1, 2, 3], C => [undef, 2, 4] };
dropna($df, cols => ['A', 'B']);

=back

=head1 { A => [1, 2], B => [1, 2], C => [undef, 2] }

Index 2 is dropped because C<A> is undef there. C<C> is not consulted, so its own
undef at index 0 doesn't trigger a drop — but index 2 is still removed from C<C>
so every column stays the same length.

=head3 C<rows> — delete specific rows

Remove exactly the rows you list — no missing-value logic. Rows are 0-based
indices for AoH and HoA, or the outer keys for HoH. Anything not present is
ignored.

 dropna({ A => [10, 20, 30] }, rows => [1]);   # { A => [10, 30] }

=head3 Good to know

=over

=item * B<Returns a new data frame; the original is never modified.> For HoA the
column arrays are rebuilt (cell values copied); for AoH and HoH the surviving
row references are reused, not deep-copied (dropna never mutates a row). Clone
the result if you need full independence.

=item * B<It dies> on: a non-ref data frame; passing both or neither of C<cols>/C<rows>;
a non-arrayref selector; a C<cols> name absent from a non-empty HoA or AoH; an
invalid C<how>; an unknown argument; or a hashref that mixes array and hash
values (ambiguous HoA vs HoH).

=item * An empty AoH or HoA returns empty rather than erroring.

=item * HoH results come back in hash order, since HoH rows are unordered.

=back

=head2 ffill

Forward-fill NA (undef) cells with the last valid value seen above them along
the row axis, like C<pandas.DataFrame.ffill>. See C<bfill> for the backward
direction and C<fillna> for constant fills.

 ffill($df,
     cols  => [ 'v' ],   # restrict to these columns (default: every column)
     limit => 2,         # max consecutive fills per gap (default: unlimited)
 );

Column identifiers are names for AoH/HoA/HoH and 0-based positions for AoA. The
row axis is positional for AoA/AoH/HoA and string-sorted key order for HoH (the
only deterministic order a HoH has). Filling stays within each column's
existing length: ragged HoA columns are not extended, and AoA rows are not
extended past their own length.

C<limit> caps the number of consecutive NA cells filled in a single gap; the
remaining cells in an over-long gap stay NA, and the count resets after the
next real value. A leading run of NA (with nothing above it) is left as NA.

Returns a NEW frame; the input is never modified.

=head3 Example

 ffill([ { v => 1 }, { v => undef }, { v => undef }, { v => 4 }, { v => undef } ],
     cols => [ 'v' ]);
 # [ { v => 1 }, { v => 1 }, { v => 1 }, { v => 4 }, { v => 4 } ]
 
 ffill([ { v => 1 }, { v => undef }, { v => undef }, { v => 4 } ],
     cols => [ 'v' ], limit => 1);
 # [ { v => 1 }, { v => 1 }, { v => undef }, { v => 4 } ]

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; a
C<cols> column that does not exist; or a C<limit> that is not a positive integer.

=head2 fillna

Replace NA (undef) cells with a constant, like C<pandas.DataFrame.fillna> with
a scalar or a dict. For propagation from neighbouring rows instead of a
constant, use C<ffill>/C<bfill>.

 fillna($df,
     value => 0,                    # scalar: fill every NA (or only within C<cols>)
     value => { a => 9, b => -1 },  # dict: fill only these columns
     cols  => [ 'a', 'b' ],         # restrict a scalar fill (forbidden with a dict)
 );

C<value> is required. Column identifiers are names for AoH/HoA/HoH and 0-based
positions for AoA. A missing hash key counts as NA and is materialised when
filled (as in C<dropna>'s NA view). AoA rows are never extended past their own
length. Ragged HoA columns are extended to the longest column's length before
filling.

A B<scalar> C<value> fills every NA in the frame, or — with C<cols> — only NA
cells in the named columns. A B<hashref> C<value> fills only the columns it
names; a dict key that matches no existing column is ignored (matching
pandas), and C<cols> may not be combined with a dict.

Returns a NEW frame; the input is never modified.

=head3 Example

 fillna([ { a => 1, b => undef }, { a => undef, b => 4 } ], value => 0);
 # [ { a => 1, b => 0 }, { a => 0, b => 4 } ]
 
 fillna([ { a => undef, b => undef } ], value => { a => 9, Z => 1 });
 # [ { a => 9, b => undef } ]   # Z ignored, b left NA
 
 fillna([ { a => undef, b => undef } ], value => 7, cols => [ 'b' ]);
 # [ { a => undef, b => 7 } ]

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; a
missing C<value>; combining C<cols> with a dict C<value>; or a scalar-fill C<cols>
naming a column that does not exist.

=head2 filter

Return a new data frame containing only the rows of C<$df> that match a predicate. The original C<$df> is never modified.

 my $adults = filter($df, col('age') >= 18);

C<filter> accepts a predicate in one of two forms:

=over

=item 1. a B<< C<col()> expression >> — a small, composable comparison built with overloaded operators, and

=item 2. a B<code reference> — for anything the operators can't express (multiple columns, regexes, matching on the row name, arbitrary logic), in the same spirit as the C<filter> option of L<#>.

=back

Both C<filter> and C<col> are exported by default.

=head3 Arguments

=for html <table>
<thead>
<tr>
  <th>Position</th>
  <th>Name</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>$df</code></td>
  <td>The data frame: an <b>array of hashes</b> (AoH, the default <code>read_table</code> output), a <b>hash of arrays</b> (HoA), or a <b>hash of hashes</b> (HoH, e.g. <code>read_table</code> with <code>'output.type' => 'hoh'</code>).</td>
</tr>
<tr>
  <td>2</td>
  <td>predicate</td>
  <td>A <code>col()</code> comparison object <b>or</b> a <code>CODE</code> reference. A coderef receives the row as <code>$_</code> / <code>$_[0]</code> and the row identifier as <code>$_[1]</code> (see below).</td>
</tr>
<tr>
  <td>3 +</td>
  <td>`'output.type' => 'aoh'\</td>
  <td>'hoa'`</td>
  <td><i>Optional.</i> The shape of the returned frame. Omit it to keep the input's own shape. <code>'out'</code> and <code>'output_type'</code> are accepted aliases, and a bare <code>filter($df, $pred, 'aoh')</code> also works.</td>
</tr>
</tbody>
</table>

=head3 The C<col()> form

C<col('name')> is a deferred reference to a column. It carries no data — only the column name — so it can be compared with a literal to build a predicate that C<filter> evaluates once per row.

 filter($df, col('age') >= 18);  # keep rows where age >= 18
 filter($df, col('sex') eq 'f'); # keep rows where sex is 'f'
 filter($df, 18 <= col('age'));  # operands may be in either order

=for html <table>
<thead>
<tr>
  <th>Kind</th>
  <th>Operators</th>
  <th>Comparison</th>
</tr>
</thead>
<tbody>
<tr>
  <td>Numeric</td>
  <td><code>></code> <code><</code> <code>>=</code> <code><=</code> <code>==</code> <code>!=</code></td>
  <td>numeric (cell and value compared as numbers)</td>
</tr>
<tr>
  <td>String</td>
  <td><code>gt</code> <code>lt</code> <code>ge</code> <code>le</code> <code>eq</code> <code>ne</code></td>
  <td>string (cell and value compared as strings)</td>
</tr>
</tbody>
</table>

Predicates compose with bitwise C<&> (and), C<|> (or), and C<!> (not):

 filter($df, (col('age') > 18) & (col('sex') eq 'f'));   # and
 filter($df, (col('grp') eq 'a') | (col('grp') eq 'c')); # or
 filter($df, !(col('x') > 100));                         # not

Comparison operators bind more tightly than C<&> and C<|>, so C<< (col('a') E<gt> 4) & (col('b') E<lt> 2) >> is parsed correctly, but the parentheses are recommended for readability.

 > Note: C<< col('age') E<gt> 32 >> works because C<col('age')> is an object whose C<< E<gt> >> is overloaded. A B<bare string> cannot do this — C<< 'age' E<gt> 32 >> is computed by Perl to a plain boolean (the string numifies to 0) before C<filter> is ever called, so the column name is lost. Always wrap the column in C<col(...)>.

 > C<col()> addresses B<columns only> — it has no handle on a HoH's row name (the outer key). It also cannot express a regex match: there is no C<=~> operator to overload, so C<col('name') =~ /re/> runs the match immediately on the stringified object and never reaches C<filter>. For either case, use the code-reference form below.

=head3 The code-reference form

For logic the operators can't express, pass a C<sub>. It is called once per row and is given:

=over

=item * the B<row> as a hash reference, available both as C<$_> and as the first argument C<$_[0]>, and

=item * the B<row identifier> as the second argument, C<$_[1]> — the B<outer key (the row name)> for a HoH, or the B<0-based row index> for an AoH or HoA.

=back

Return a true value to keep the row.

 filter($df, sub { $_->{x} > 4 && $_->{grp} eq 'a' });
 filter($df, sub { $_->{name} =~ /^A/ });
 filter($df, sub { $_->{age} % 2 == 0 });            # things col() has no operator for
 filter($df, sub { $_[0]{score} > $_[0]{threshold} });

For a HoA, each row is assembled into a temporary C<< { column =E<gt> value, ... } >> hash before the sub (or the C<col()> test) is called, so the same C<< $_-E<gt>{column} >> syntax works regardless of the input shape.

=head4 Filtering on the row name (C<$_[1]>)

In a HoH the row name is the B<outer key>, not a field inside each row hash — so C<< $_-E<gt>{row_name} >> is C<undef>. Match on C<$_[1]> instead:

 # HoH keyed by structure id; keep the rows named in @ids
 my $grps = join '|', @ids;
 my $keep = filter($score, sub { $_[1] =~ m/^(?:$grps)$/ });
 
 # combine the row name with an ordinary column test
 filter($score, sub { $_[1] =~ /^1/ && $_->{anomaly_rank} < 100 });

For an AoH or HoA, C<$_[1]> is the 0-based row index:

 filter($aoh, sub { $_[1] % 2 == 0 });   # keep even-indexed rows
 filter($hoa, sub { $_[1] < 10 });        # keep the first ten rows

=head3 Choosing the output shape

By default C<filter> returns a frame of the B<same shape> as the input (AoH → AoH, HoA → HoA, HoH → HoH). Pass C<output.type> to convert while filtering:

 my $aoh = read_table('patients.csv');                          # array of hashes
 my $hoa = filter($aoh, col('Age') >= 18, 'output.type' => 'hoa');
 # $hoa->{Age}, $hoa->{Sex}, ... are all the same length and row-aligned

The two selectable output types are C<'aoh'> and C<'hoa'>. C<'hoh'> is B<not> selectable, because producing a hash of hashes would require choosing which column becomes the row key; an HoH input keeps its keys only when the output shape is left at the default (HoH → HoH).

=head3 Examples

 use Stats::LikeR;
 my $df = read_table('patients.csv');                 # array of hashes
 
 my $adults = filter($df, col('Age') >= 18);          # numeric threshold
 my $target = filter($df, (col('Age') >= 18) & (col('Sex') eq 'f'));   # combine
 my $flagged = filter($df, sub { $_->{ALT} > 40 || $_->{AST} > 40 });  # coderef
 
 # hash of arrays in -> hash of arrays out (columns filtered in parallel)
 my $hoa = read_table('patients.csv', 'output.type' => 'hoa');
 my $sub = filter($hoa, col('Age') > 32);
 
 # hash of hashes in -> the same row keys, fewer of them
 my $hoh = read_table('patients.csv', 'output.type' => 'hoh');
 my $keep = filter($hoh, col('Age') > 32);
 
 # hash of hashes: filter on the row name (the outer key) via $_[1]
 my $grps    = join '|', qw(1cka 1d4t);
 my $by_name = filter($hoh, sub { $_[1] =~ m/^(?:$grps)$/ });
 
 # convert shape while filtering
 my $as_hoa = filter($df, col('Age') > 32, 'output.type' => 'hoa');

=head3 Behavior and notes

=over

=item * B<The input is never modified.> C<filter> builds and returns a new frame; C<$df> is left untouched.

=item * B<< The predicate receives the row identifier as C<$_[1]>. >> For a HoH it is the outer key (the row name); for an AoH or HoA it is the 0-based row index. In a HoH the row name lives in the I<key>, not inside each row hash, so C<< $_-E<gt>{row_name} >> is C<undef> — filter on C<$_[1]> instead. C<col()> expressions see only columns, never the row key.

=item * B<< A missing or C<undef> cell never matches a C<col()> comparison. >> C<< col('x') E<gt> 0 >> silently drops any row whose C<x> is absent or C<undef>; for numeric operators a non-numeric cell is likewise dropped. With a coderef, C<undef> is whatever your sub makes of it.

=item * B<Rows are shared, not deep-copied, wherever possible.> When an AoH or HoH row is kept (output left as AoH/HoH, or converted to C<aoh>), the returned frame references the I<same> inner row hashes as the input. Mutating such a row in the result would also change it in the original. HoA inputs and any C<hoa> output build fresh arrays and fresh cell values.

=item * B<Keep-all / keep-none are well defined.> A predicate true for every row returns the whole frame in the chosen shape; true for none returns an empty frame: C<[]> for C<aoh>, a hash of empty (but present) columns for C<hoa>, and C<{}> for C<hoh>.

=item * B<Supported shapes are AoH, HoA, and HoH.> A non-reference, an AoH element that is not a hash reference, a HoA column that is not an array reference, or a HoH row that is not a hash reference all raise a descriptive error; a bare C<col('x')> with no comparison is also an error. An empty hash C<{}> is treated as an empty frame.

=item * B<Perl 5.10 compatible.> The C<col()>/operator layer is pure Perl (operator overloading building a per-row closure); filtering and any reshaping run in XS.

=back

=head3 See also

C<read_table> (whose C<filter> option applies the same coderef convention while reading a file), C<col2col>.

=head2 fisher_test

=head3 array reference entry

 my $array_data = [
     [10, 2],
     [3, 15]
 ];
 my $res1 = fisher_test($array_data);

which returns a hash reference:

 {
 alternative   "two.sided",
 conf_int      [
     [0] 2.75343836564204,
     [1] 300.682787419401
 ],
 conf_level    0.95,
 estimate      {
     "odds ratio"   21.3053312750168
 },
 method        "Fisher's Exact Test for Count Data",
 p_value       0.000536724119143435
 }

=head3 hash reference entry

 $ft = fisher_test( {
     Guess => {
         Milk => 3, Tea => 1
     },
     Truth => {
         Milk => 1, Tea => 3
     }
 });

=head3 larger (R x C) tables

Any table of at least 2x2 counts is accepted, as either a 2D array reference or a 2D hash reference:

 my $res = fisher_test([
     [5, 3, 2],
     [1, 4, 6],
     [7, 2, 1],
 ]);

For tables larger than 2x2 the p-value is computed by exact enumeration of
every contingency table sharing the observed row and column margins (the
multivariate hypergeometric distribution), and matches R's C<fisher.test> to
full precision. Only the two-sided test is defined in this case, so
C<alternative> is ignored and the returned hash reference omits C<conf_int> and
C<estimate> (the conditional-MLE odds ratio and its confidence interval are
reported for 2x2 tables only):

 {
 alternative   "two.sided",
 conf_level    0.95,
 method        "Fisher's Exact Test for Count Data",
 p_value       0.0540892411303451
 }

As with the 2x2 case, a hash-of-hashes input orders rows by their sorted keys
and columns by the sorted keys of the first row, so the result is deterministic;
every row must expose the same set of column keys, and every row of an array
input must have the same number of columns.

=head2 get_union

 my @all   = get_union(\@a, \@b, \@c); # every distinct value, any list
 my $count = get_union(\@a, \@b, \@c); # how many distinct values

Takes one or more array references and returns every value that appears in at
least one of them. Duplicates collapse and the result keeps first-appearance
order. In scalar context it returns the count. Values are compared by their
string form (like Perl hash keys), so C<1>, C<"1"> and C<1.0> are one element,
while a UTF-8 flagged string stays distinct from the same bytes without the
flag. A non-array-ref argument or an C<undef> element is fatal. Mirrors
C<List::Compare>'s C<get_union>.

 my @a = (1, 2, 3, 3);
 my @b = (3, 4);
 my @u = get_union(\@a, \@b);            # (1, 2, 3, 4)

=head2 glm

takes a hash of an array as input

 my %tooth_growth = (
     dose => [qw(0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0
 1.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5
 0.5 0.5 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0
 2.0 2.0 2.0)],
     len  => [qw(4.2 11.5  7.3  5.8  6.4 10.0 11.2 11.2  5.2  7.0 16.5 16.5 15.2 17.3 22.5
 17.3 13.6 14.5 18.8 15.5 23.6 18.5 33.9 25.5 26.4 32.5 26.7 21.5 23.3 29.5
 15.2 21.5 17.6  9.7 14.5 10.0  8.2  9.4 16.5  9.7 19.7 23.3 23.6 26.4 20.0
 25.2 25.8 21.2 14.5 27.3 25.5 26.4 22.4 24.5 24.8 30.9 26.4 27.3 29.4 23.0)],
     supp => [qw(VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC
 VC VC VC VC VC OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ
 OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ)]
 );
 
 my $glm_teeth = glm(
     data    => \%tooth_growth,
     formula => 'len ~ dose + supp',
     family  => 'gaussian'
 );

In addition to the C<gaussian> default, it fully supports logistic regression using the C<binomial> family parameter via Iteratively Reweighted Least Squares (IRLS):

 my $glm_bin = glm(formula => 'am ~ wt + hp', data => \%mtcars, family => 'binomial');

=head3 Input Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>formula</code></td>
  <td><code>String</code></td>
  <td><i>None (Required)</i></td>
  <td>A symbolic description of the model to be fitted. Supports operators like <code>+</code>, <code>:</code>, <code>*</code>, <code>^</code>, and <code>-1</code> (to remove the intercept).</td>
  <td><code>'am ~ wt + hp'</code>, <code>'y ~ x - 1'</code></td>
</tr>
<tr>
  <td><code>data</code></td>
  <td><code>HashRef</code> or <code>ArrayRef</code></td>
  <td><i>None (Required)</i></td>
  <td>The dataset containing the variables used in the formula. Accepts either a Hash of Arrays (HoA) or an Array of Hashes (AoH).</td>
  <td><code>\%mtcars</code>, <code>[{x => 1, y => 2}, ...]</code></td>
</tr>
<tr>
  <td><code>family</code></td>
  <td><code>String</code></td>
  <td><code>'gaussian'</code></td>
  <td>A description of the error distribution and link function to be used in the model. Currently supports <code>'gaussian'</code> (identity link) and <code>'binomial'</code> (logit link).</td>
  <td><code>'binomial'</code></td>
</tr>
</tbody>
</table>

=head3 Output variables

=for html <table>
<thead>
<tr>
  <th>Variable</th>
  <th>Type</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>aic</code></td>
  <td><code>Double</code></td>
  <td>Akaike's Information Criterion for the fitted model.</td>
  <td><code>123.45</code></td>
</tr>
<tr>
  <td><code>boundary</code></td>
  <td><code>Integer (Boolean)</code></td>
  <td><code>1</code> if the fitted values computationally reached the <code>0</code> or <code>1</code> boundary (specific to the binomial family), <code>0</code> otherwise.</td>
  <td><code>0</code></td>
</tr>
<tr>
  <td><code>coefficients</code></td>
  <td><code>HashRef</code></td>
  <td>A hash mapping the expanded model term names to their estimated coefficient values.</td>
  <td><code>{'Intercept' => 1.5, 'wt' => -0.5}</code></td>
</tr>
<tr>
  <td><code>converged</code></td>
  <td><code>Integer (Boolean)</code></td>
  <td><code>1</code> if the Iteratively Reweighted Least Squares (IRLS) algorithm converged within the maximum iterations, <code>0</code> otherwise.</td>
  <td><code>1</code></td>
</tr>
<tr>
  <td><code>deviance</code></td>
  <td><code>Double</code></td>
  <td>The residual deviance of the fitted model.</td>
  <td><code>15.2</code></td>
</tr>
<tr>
  <td><code>deviance.resid</code></td>
  <td><code>HashRef</code></td>
  <td>A hash mapping data row names to their computed deviance residuals.</td>
  <td><code>{'Mazda RX4' => 0.12}</code></td>
</tr>
<tr>
  <td><code>df.null</code></td>
  <td><code>Integer</code></td>
  <td>The residual degrees of freedom for the null model.</td>
  <td><code>31</code></td>
</tr>
<tr>
  <td><code>df.residual</code></td>
  <td><code>Integer</code></td>
  <td>The residual degrees of freedom for the fitted model.</td>
  <td><code>30</code></td>
</tr>
<tr>
  <td><code>family</code></td>
  <td><code>String</code></td>
  <td>The statistical family used to fit the model.</td>
  <td><code>"gaussian"</code></td>
</tr>
<tr>
  <td><code>fitted.values</code></td>
  <td><code>HashRef</code></td>
  <td>A hash mapping data row names to the fitted mean values (the model's predictions on the scale of the response).</td>
  <td><code>{'Mazda RX4' => 0.85}</code></td>
</tr>
<tr>
  <td><code>iter</code></td>
  <td><code>Integer</code></td>
  <td>The number of IRLS iterations performed before convergence or hitting the iteration limit.</td>
  <td><code>4</code></td>
</tr>
<tr>
  <td><code>null.deviance</code></td>
  <td><code>Double</code></td>
  <td>The deviance for the null model (a baseline model containing only an intercept, or an offset of 0 if the intercept is removed).</td>
  <td><code>43.5</code></td>
</tr>
<tr>
  <td><code>rank</code></td>
  <td><code>Integer</code></td>
  <td>The numeric rank of the fitted linear model (the number of estimated, non-aliased parameters).</td>
  <td><code>2</code></td>
</tr>
<tr>
  <td><code>summary</code></td>
  <td><code>HashRef</code></td>
  <td>A nested hash mapping each term to its detailed summary statistics, including <code>Estimate</code>, <code>Std. Error</code>, <code>t value</code> / <code>z value</code>, and <code>Pr(> t )</code> / <code>Pr(> z )</code>. Aliased parameters return <code>"NaN"</code>.</td>
  <td><code>{'wt' => {'Estimate' => -0.5, 'Std. Error' => 0.1, ...}}</code></td>
</tr>
<tr>
  <td><code>terms</code></td>
  <td><code>ArrayRef</code></td>
  <td>An ordered list of the expanded term names included in the model matrix.</td>
  <td><code>['Intercept', 'wt', 'hp']</code></td>
</tr>
</tbody>
</table>

=head2 group_by

Take a hash of arrays, hash of hashes, or array of hashes, and group a column by another column.

 my $aoh_data = [
     { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
     { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
     { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
     { 'Gender' => 'Female' } # Intentional missing target value
 ];

as well as

 $hoh_data = {
     'Patient_A' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
     'Patient_B' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
     'Patient_C' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
     'Patient_D' => { 'Gender' => 'Female' }, # Intentional missing target value
     'Patient_E' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => undef } # Explicit undef
     };

and

 my $hoa_data = {
     'Gender'                       => ['Male', 'Female', 'Male', 'Female'],
     'Testosterone, total (nmol/L)' => [22.1,   2.5,      19.4,   undef   ]
 };

then run the function thus:

 group_by( $hoa_data, 'Testosterone, total (nmol/L)', 'Gender');

The output can be thought of like a hash, with the first string broken down by the second.

all become hash of arrays:

 {
     Female   [
         [0] 1.8
     ],
     Male     [
         [0] 18.2,
         [1] 20.5
     ]
 }

A column that is present in some rows but missing in others is fine (those rows
are simply skipped), but naming a target, group, or filter column that is absent
from the data entirely is fatal: C<group_by> dies with
C<< group_by: "E<lt>columnE<gt>" is not present in the dataset >>.

=head3 Filtering

Data can be further broken down with filter/subs like in C<read_table>:

 my $testosterone = group_by($d, # group testosterone by "Gender"
     'Testosterone, total (nmol/L)',
     'Gender',
     { 'Race/Hispanic origin w/ NH Asian' => sub { $_ eq $n } },# filter
     { 'Testosterone, total (nmol/L)' => sub { $_ ne 'NA' } } # filter
 );

where each filter filters on the columns, e.g. second hash keys.

=head2 hoa2aoh

Turn a hash-of-arrays into an array-of-hashes.

=head3 Usage

 my $aoh = hoa2aoh($hoa);

=over

=item * B<< C<$hoa> >> — a hashref whose values are arrayrefs, one per column:

{ id => [1, 2, 3], name => ['a', 'b', 'c'] }

=item * B<returns> — an arrayref of row hashrefs:

[
    { id => 1, name => 'a' },
    { id => 2, name => 'b' },
    { id => 3, name => 'c' }
]

=back

It builds a brand-new structure and copies every cell, so the result is
completely independent of the input — changing one never affects the other.

=head3 Example

 my $hoa = { mpg => [21, 22.8, 18.1], cyl => [6, 4, 6] };
 my $aoh = hoa2aoh($hoa);
 $aoh->[1]{mpg};        # 22.8
 $hoa->{mpg}[1];        # still 22.8 — unaffected by edits to $aoh

=head3 Good to know

=over

=item * B<Row count> is the length of the longest column. If columns have different
lengths, the short ones are padded with C<undef> in the missing rows.

=item * B<< C<undef> cells >> are kept as C<undef>.

=item * An B<empty hash>, or one whose columns are all empty, gives back C<[]>.

=item * It B<dies> if the argument isn't a hashref, or if any column value isn't an
arrayref (the message names the offending column).

=back

=head3 See also

C<hoa2aoh> is the reverse of C<aoh2hoa>

=head2 hoa2hoh( \%hoa, $key )

Converts a hash-of-arrays (column-major) into a hash-of-hashes keyed by the
C<$key> column, i.e. C<< { $rowname =E<gt> { col =E<gt> value, ... } } >>. Analogous to
C<hoa2aoh>, but rows are indexed by their C<$key> value instead of positionally.

 my %hoa = (
     id => [ qw(a b c) ],
     x  => [ 1, 2, 3 ],
     y  => [ 4, 5, 6 ],
 );
 my $hoh = hoa2hoh( \%hoa, 'id' );
 # { a => { id => 'a', x => 1, y => 4 }, b => {...}, c => {...} }

The C<$key> column is retained in each inner row. Columns are copied by value.
Shorter columns are padded with C<undef>, matching C<hoa2aoh>.

Dies if: the first argument is not a hashref of arrayrefs; C<$key> is undef or
names a missing/non-array column; the C<$key> column holds an undefined value
for any row; or two rows share the same C<$key> value.

=head2 hoh2hoa

Convert a B<hash of hashes> (row-major: outer key = row, inner key = column)
into a B<hash of arrays> (column-major: key = column, value = that column's
cells down the rows).

 use Stats::LikeR;
 
 my %hoh = (
     'r1' => { 'a' => 1, 'b' => 2 },
     'r2' => { 'a' => 3, 'b' => 4 },
 );
 
 my $hoa = hoh2hoa(\%hoh);

which returns
    {
      a => [1, 3],
      b => [2, 4],
    }

=head3 Behavior

=over

=item * B<Columns> are the union of every inner key, so a key that appears in only
some rows still becomes a column.

=item * B<Rows> are emitted in sorted outer-key (row-name) order, and that one order
is used for every column, so the arrays stay aligned and the result is
reproducible regardless of hash ordering.

=item * B<Gaps> — a missing inner key, or a cell whose value is C<undef> — are filled
with the fill value (see C<undef.val> below). Every column therefore has
exactly one entry per row.

=item * Values are B<copied> into the result; the original structure is left
untouched.

=item * An B<empty> hash of hashes returns an empty hash of arrays (it is not an
error).

=back

=head3 Options

Options are passed as trailing C<< name =E<gt> value >> pairs.

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>undef.val</code></td>
  <td><code>undef</code></td>
  <td>Value used to fill a missing key or an <code>undef</code> cell. Any defined scalar works, including <code>0</code> and <code>''</code>. Passing <code>undef</code> keeps the default.</td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td><i>(none)</i></td>
  <td>If set to a string, an extra column of that name is added holding the sorted row labels, aligned with the data. Dies if the name collides with an existing column.</td>
</tr>
</tbody>
</table>

 # Ragged input with an explicit fill string:
 my %ragged = (
     'r1' => { 'a' => 1, 'b' => 2 },
     'r2' => { 'a' => 3, 'c' => 9 },
 );
 my $hoa = hoh2hoa(\%ragged, 'undef.val' => 'NA');
 # {
 #   a => [1,    3   ],
 #   b => [2,    'NA'],
 #   c => ['NA', 9   ],
 # }
 
 # Keep the row labels as a column:
 my $with_ids = hoh2hoa(\%ragged, 'row.names' => 'id');
 # {
 #   id => ['r1', 'r2'],
 #   a  => [1,    3   ],
 #   b  => [2,    undef],
 #   c  => [undef, 9  ],
 # }

=head3 Errors

C<hoh2hoa> dies (via C<croak>) when:

=over

=item * the argument is not a hash reference,

=item * any value in the hash is not itself a hash reference,

=item * an unknown option is given, or the options are not C<< name =E<gt> value >> pairs,

=item * C<row.names> is not a plain string, or it names an already-present column.

=back

=head2 hist

Computes the histogram of the given data values, operating in single $O(N)$ pass performance. It returns the bin counts, computed breaks, midpoints, and density. 

 my $res = hist([1, 2, 2, 3, 3, 3, 4, 4, 5], breaks => 4);

If C<breaks> is not explicitly provided, it defaults to calculating the number of bins using Sturges' formula.

=head2 interpolate

Fill NA (undef) cells along the row axis, like C<pandas.DataFrame.interpolate>.
It is the numeric sibling of C<ffill>/C<bfill>: rather than only propagating a
neighbour's value into a gap, it can fit a curve (line, spline, polynomial…)
through the surrounding numeric values and read the gap off that curve. B<Every
one of pandas' interpolation methods is supported> and matched to pandas /
scipy within C<1e-6> (see I<Method accuracy> below).

 interpolate($df,
     method          => 'cubic',      # any method below (default: 'linear')
     cols            => [ 'v' ],      # restrict to these columns (default: every column)
     order           => 3,            # degree, required by 'polynomial' / 'spline'
     x               => 't',          # abscissae: column name/index or arrayref
     limit           => 2,            # max cells filled per NA run (default: unlimited)
     limit_direction => 'forward',    # 'forward' (default), 'backward', or 'both'
     limit_area      => 'inside',     # 'inside', 'outside', or omit for both
 );

Column identifiers are names for AoH/HoA/HoH and 0-based positions for AoA. The
row axis is positional for AoA/AoH/HoA and string-sorted key order for HoH — the
same shape and ordering rules as C<ffill>/C<bfill>. Returns a NEW frame; the input
is never modified.

=head3 Methods

=for html <table>
<thead>
<tr>
  <th>`method`</th>
  <th>What it does</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>linear</code> <i>(default)</i></td>
  <td>straight line between the nearest anchors, rows equally spaced</td>
</tr>
<tr>
  <td><code>index</code>, <code>values</code>, <code>time</code></td>
  <td>straight line, but spaced by the <code>x</code> coordinates</td>
</tr>
<tr>
  <td><code>slinear</code></td>
  <td>piecewise linear, interior gaps only</td>
</tr>
<tr>
  <td><code>nearest</code></td>
  <td>value of the nearer anchor, interior only</td>
</tr>
<tr>
  <td><code>zero</code></td>
  <td>value of the left anchor (zero-order hold), interior only</td>
</tr>
<tr>
  <td><code>pad</code> / <code>ffill</code></td>
  <td>hold the last value forward</td>
</tr>
<tr>
  <td><code>bfill</code> / <code>backfill</code></td>
  <td>hold the next value backward</td>
</tr>
<tr>
  <td><code>quadratic</code>, <code>cubic</code></td>
  <td>degree-2 / degree-3 interpolating B-spline (scipy <code>interp1d</code>)</td>
</tr>
<tr>
  <td><code>cubicspline</code></td>
  <td>not-a-knot cubic spline (scipy <code>CubicSpline</code>)</td>
</tr>
<tr>
  <td><code>pchip</code></td>
  <td>monotone piecewise cubic Hermite (Fritsch–Carlson)</td>
</tr>
<tr>
  <td><code>akima</code></td>
  <td>Akima piecewise cubic</td>
</tr>
<tr>
  <td><code>barycentric</code>, <code>krogh</code></td>
  <td>single global polynomial through all anchors</td>
</tr>
<tr>
  <td><code>polynomial</code></td>
  <td>degree-<code>order</code> interpolating spline (<code>order</code> required)</td>
</tr>
<tr>
  <td><code>spline</code></td>
  <td>interpolating spline of degree <code>order</code> (<code>order</code> required)</td>
</tr>
</tbody>
</table>

=head3 How gaps and edges are filled

Interpolation follows pandas exactly: every gap is filled from the method, then
cells that C<limit> / C<limit_direction> / C<limit_area> forbid are blanked back to
NA. Only numeric cells B<anchor> a fill; a defined non-numeric cell is preserved
(and, for the piecewise-local methods, blocks interpolation across it).

B<Interior gaps> (anchors on both sides) are always filled. B<Leading/trailing
gaps> (an edge with anchors on one side only) behave by method family:

=over

=item * C<linear> and the hold methods (C<pad>/C<bfill>) fill the edge with the held
constant, subject to C<limit_direction>.

=item * C<barycentric>, C<krogh>, C<cubicspline>, C<pchip> B<extrapolate> the edge from
the fitted curve, again subject to C<limit_direction>.

=item * the C<interp1d> family (C<nearest>, C<zero>, C<slinear>, C<quadratic>, C<cubic>,
C<polynomial>), C<akima>, and C<spline> are B<interior-only> — they leave
leading/trailing gaps as NA, matching scipy.

=back

C<limit_direction> chooses which edge is filled (C<forward> → trailing, C<backward>
→ leading, C<both> → both) and, with C<limit>, which cells a run's cap reaches.
C<limit_area> restricts filling to C<'inside'> (interior) or C<'outside'>
(edges only). Interpolated cells are floats; filling stays within each column's
existing length (ragged HoA columns and short AoA rows are not extended).

=head3 The C<x> argument

By default rows are equally spaced (C<0, 1, 2, …>). Pass C<x> to interpolate
against real abscissae — either an arrayref (one coordinate per row) or a column
name/index whose numeric values are the coordinates. C<x> must be strictly
increasing and is used by every method except plain C<linear> semantics (use
C<index>/C<values> for a line on unequal spacing).

 # linear fit on unequal spacing
 interpolate({ v => [ 0, undef, undef, 10 ] }, method => 'index', x => [ 0, 1, 3, 4 ]);
 # { v => [ 0, 2.5, 7.5, 10 ] }
 
 # interpolate v against a time column t
 interpolate($df, cols => [ 'v' ], x => 't', method => 'index');

=head3 Examples

 # linear: interior interpolated, trailing held (forward default), leading NA
 interpolate({ v => [ undef, 1, undef, undef, 4, undef ] });
 # { v => [ undef, 1, 2, 3, 4, 4 ] }
 
 # cubic spline through four anchors that lie on x^2, so the fit is exact
 interpolate({ v => [ 0, undef, undef, 9, 16, 25 ] }, method => 'cubic', limit_direction => 'both');
 # { v => [ 0, 1, 4, 9, 16, 25 ] }
 
 # monotone pchip vs. a global polynomial on the same gaps
 interpolate({ v => [ 2, undef, 3, undef, undef, 2, 5, undef, 0 ] }, method => 'pchip', limit_direction => 'both');

=head3 Method accuracy

C<linear>, C<index>/C<values>/C<time>, C<slinear>, C<nearest>, C<zero>, C<pad>/C<ffill>,
C<bfill>/C<backfill>, C<quadratic>, C<cubic>, C<cubicspline>, C<pchip>, C<akima>,
C<barycentric>, C<krogh>, and C<polynomial> reproduce pandas/scipy to machine
precision (the test suite compares against pandas 2.2.3 / scipy 1.15.2).

Two deliberate departures from pandas:

=over

=item * B<< C<spline> >> is the I<interpolating> spline of degree C<order> (equivalent to
pandas' C<spline> with C<s=0>), because pandas' default C<spline> is a FITPACK
I<smoothing> spline that is not reproducible without FITPACK. It does not
extrapolate edges. C<polynomial>/C<spline> support C<order> 1, 2, or 3.

=item * A defined B<non-numeric> cell is treated as a barrier by the piecewise-local
methods; pandas has no equivalent (its columns are all-numeric).

=back

 > Performance: the per-column numeric core (every method, the linear solve and
 > the preserve mask) runs in XS. Versus the former pure-Perl kernels this is
 > roughly 5× faster for C<linear> on a large column, ~11× for C<pchip>, and ~50×
 > for the spline methods whose dense solve dominates. The fit-based methods
 > still use a dense solve, so they target modest per-column anchor counts.

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument or
method; C<polynomial>/C<spline> without an integer C<order> in 1–3; a C<cols> or C<x>
column that does not exist; too few anchors for the chosen method; an C<x> that is
not strictly increasing or whose length does not match; a C<limit> that is not a
positive integer; or an invalid C<limit_direction>/C<limit_area>.

=head2 intersection

Returns the set intersection (∩) of a list of array references: the values
that appear in B<every> array ref given.

 use Stats::LikeR;
 
 my @i = intersection([1, 2, 3], [2, 3, 4]);          # (2, 3)
 my @t = intersection([1, 2, 3, 4], [2, 3, 4], [3, 4]); # (3, 4)
 my $n = intersection([1, 2, 3], [2, 3, 4]);          # 2

Every argument must be an array reference: each one is treated as a set.
Unlike C<mean> and C<uniq>, bare scalars are not accepted; passing a non-reference
(or a non-array reference) croaks.

The result is B<deduplicated> and ordered by first appearance in the I<first>
array ref. Duplicate values within any single ref are counted once, so
C<intersection([1, 2, 2, 3], [2, 3, 3, 4])> is C<(2, 3)>, not C<(2, 2, 3)>.

Values are compared by stringification — the same C<eq> semantics used by
C<uniq>. C<1>, C<1.0>, and C<"1"> are treated as equal, while C<"3"> and C<"3.0">
are distinct. The UTF-8 flag is part of the comparison key, so a UTF-8 string
and a byte-identical non-UTF-8 string are kept separate.

In list context C<intersection> returns the shared values; in scalar context it
returns the cardinality (the number of shared values).

With a single array ref, the result is simply that ref's unique values. If any
ref is empty, the intersection is empty.

C<intersection> croaks on degenerate or ill-formed input, reporting the
offending position:

 intersection();              # croaks: intersection needs >= 1 array ref
 intersection([1, 2], 3);     # croaks: argument 1 is not an array ref
 intersection([1, undef, 3]); # croaks: undefined value at array ref index 1 (argument 0)

This matches the undef-handling of C<mean> and C<uniq> and the rest of the
numeric reducers in Stats::LikeR.

=head2 is_equivalent

C<is_equivalent(\@a, \@b, ...)> returns B<1> if every list holds the same
I<set> of distinct values, and B<0> otherwise. Order and duplicates don't
count — only which values are present.

Think of each list as a bag, dump each bag into its own set, and ask: are all
the sets identical?

 is_equivalent([1,2,3], [3,2,1])     # 1  same values, different order
 is_equivalent([1,1,2], [2,1])       # 1  duplicates ignored
 is_equivalent([1,2,3], [1,2])       # 0  right is missing 3
 is_equivalent([1,2],   [1,2,3])     # 0  right has an extra 4
 is_equivalent([1,2], [2,1], [1,2])  # 1  works for any number of lists

It generalises C<List::Compare>'s C<is_LequivalentR()> from two lists to N.

=head3 How it decides

Equivalence is transitive: if every list equals the first list, they all equal
each other. So the check is simple — build the distinct-value set of the
B<first> list, then hold each other list up against it. A list matches when:

=over

=item 1. it contains B<no value outside> the first set, and

=item 2. it B<covers every value> in the first set.

=back

Fail either test for any list and the answer is 0.

=head3 Edge cases

 is_equivalent([], [])        # 1  two empty sets are equal
 is_equivalent([], [1])       # 0  empty vs non-empty
 is_equivalent([1], [1], [1]) # 1

Values are compared B<as strings> (like hash keys), so C<1> and C<"1"> are the
same, but C<2> and C<"2.0"> are not.

=head3 Rules

=over

=item * Pass B<at least two> array refs. Fewer croaks.

=item * Every argument must be an B<array ref>; anything else croaks.

=item * B<< C<undef> inside a list croaks >> — decide what a missing value means before
calling, rather than letting it silently match.

=back

=head2 kruskal_test

Essentially the test determines if all groups have the same median (same distribution) (an excellent review is at https://library.virginia.edu/data/articles/getting-started-with-the-kruskal-wallis-test)

Performs a Kruskal-Wallis rank sum test, see 
https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/kruskal.test

=head3 hash of array entry

I feel that this is better, and more easily read, than what you get in R:

 my %x = (
 'normal.subjects' => [2.9, 3.0, 2.5, 2.6, 3.2],
 'obs. airway disease' => [3.8, 2.7, 4.0, 2.4],
 'asbestosis' => [2.8, 3.4, 3.7, 2.2, 2.0]
 );
 $kt = kruskal_test(\%x);

=head3 R-like array entry

 my @xk = (2.9, 3.0, 2.5, 2.6, 3.2); # normal subjects
 my @yk = (3.8, 2.7, 4.0, 2.4);      # with obstructive airway disease
 my @zk = (2.8, 3.4, 3.7, 2.2, 2.0); # with asbestosis
 my @x = (@xk, @yk, @zk);
 my @g = (
     (map {'Normal subjects'} 0..4),
     (map {'Subjects with obstructive airway disease'} 0..3),
     map {'Subjects with asbestosis'} 0..4
 );
 my $kt = kruskal_test(\@x, \@g);

=head2 ks_test

The Kolmogorov–Smirnov test checks whether two samples are drawn from the
same distribution (two-sample), or whether a single sample is drawn from a
given reference distribution (one-sample). It works by comparing the empirical
cumulative distribution functions (ECDFs) and measuring the largest gap
between them.

Two-sample form — pass two array references:

 $ks = ks_test(\@x, \@y);
 $ks = ks_test(\@x, \@y, alternative => 'greater');

One-sample form — pass one array reference and the name of a reference CDF.
Currently only C<'pnorm'> is supported, i.e. the standard normal distribution
(mean 0, standard deviation 1):

 $ks = ks_test(\@x, 'pnorm');

Arguments may be given positionally (as above) or by name:

 $ks = ks_test(x => \@x, y => \@y, alternative => 'less', exact => 1);

Non-numeric and undefined elements are silently dropped before the test runs.

C<alternative> selects which gap between the ECDFs is measured:

=over

=item * C<'two.sided'> (default) — the largest gap in either direction,
D = sup |F_x − F_y|.

=item * C<'greater'> — the largest gap where x's ECDF rises above the other,
D⁺ = sup (F_x − F_y).

=item * C<'less'> — the largest gap in the other direction, D⁻ = sup (F_y − F_x).

=back

These follow R's C<ks.test> convention: C<'greater'>/C<'less'> describe which CDF
lies I<above> the other, which (because a higher CDF means smaller values) is
the opposite of which sample tends to be larger.

C<exact> controls how the p-value is computed. Omit it to let the test choose:
the exact distribution is used for small samples (two-sample when nx·ny 
10000, one-sample when n < 100) and the asymptotic (Kolmogorov limiting)
approximation otherwise. Pass C<< exact =E<gt> 1 >> to force the exact computation or
C<< exact =E<gt> 0 >> to force the asymptotic one. Exact p-values cannot be computed
when the data contain ties; if ties are present on the exact path, the test
warns and falls back to the asymptotic p-value. (The exact one-sample test is
only available for the two-sided alternative; a one-sided one-sample request
also falls back to asymptotic.)

=head3 Return value

C<ks_test> returns a hash reference with four keys:

=over

=item * B<< C<statistic> >> — the KS statistic for the chosen C<alternative>: D, D⁺, or
D⁻. It is the maximum distance between the two ECDFs (or, for the one-sample
test, between the ECDF and the reference CDF), always in the range [0, 1].
Larger values mean the distributions are further apart.

=item * B<< C<p_value> >> — the probability, under the null hypothesis that the samples
share a distribution, of observing a statistic at least this large. It is
clamped to [0, 1]; a small value (e.g. < 0.05) is evidence against the null.

=item * B<< C<method> >> — a human-readable description of exactly what was run, handy
for logging or reproducing a result. One of:
C<"Two-sample Kolmogorov-Smirnov exact test">,
C<"Two-sample Kolmogorov-Smirnov test (asymptotic)">,
C<"One-sample Kolmogorov-Smirnov exact test">, or
C<"One-sample Kolmogorov-Smirnov test (asymptotic)">.

=item * B<< C<alternative> >> — the alternative hypothesis that was applied
(C<'two.sided'>, C<'greater'>, or C<'less'>), echoed back so the result is
self-describing.

=back

For example:

 my $ks = ks_test(\@x, \@y);
 if ($ks->{p_value} < 0.05) {
     printf "reject H0: D=%.4f, p=%.4g (%s)\n",
         $ks->{statistic}, $ks->{p_value}, $ks->{method};
 }

=head2 ljoin

Consider a hash: C<$h{$row}{$col}>, and another hash C<$i{$row}{$col2}>.
C<ljoin> will add information for C<$col> in C<%i> for each C<$row> to C<%h>, where C<$row> exists in both C<%h> and C<%i>.
Similar to C<cbind> in R.

For example,

 {
 "Jack Smith"   {
     age   30
 }
 }

and a second hash,
    {
        "Jack Smith"   {
            dept   "Engineering"
        },
        "Jane Doe"     {
            age   25
        }
    }

in this case, running C<ljoin(\%h, \%i)> will modify \%h to result:

 {
 "Jack Smith"   {
     age    30,
     dept   "Engineering"
 }
 }

=head2 lm

This is the linear models function.

 $lm = lm(formula =>  'mpg ~ wt + hp', data => $mtcars);

where C<$mtcars> is a hash of hashes

C<lm> also supports generating interaction terms directly within the formula using the C<*> operator:

 my $lm = lm(formula => 'mpg ~ wt * hp^2', data => \%mtcars);

If your data contains missing numbers (C<NA> or C<undef>), C<lm> handles listwise deletion dynamically to ensure mathematical integrity before fitting.

the dot operator also works:

 $lm = lm(formula => 'y ~ .', data => $dot_data);

=head2 Lonly

 my @only_first = Lonly(\@a, \@b, \@c);
 my $count      = Lonly(\@a, \@b, \@c);

Takes one or more array references and returns the values that appear in the
B<first> reference and in B<no other> reference; with a single reference it
returns that list's distinct values. Duplicates collapse, the result keeps
first-appearance order, and scalar context returns the count. Values are
compared by string form (see C<get_union>). A non-array-ref argument or an
C<undef> element is fatal. With exactly two references this is the left-only
set difference. Mirrors C<List::Compare>'s C<get_unique>, which likewise
defaults to the first list.

 my @a = (1, 2, 3);
 my @b = (3, 4, 5);
 my @c = (5, 6);
 my @u = Lonly(\@a, \@b, \@c);           # (1, 2)  -- 3 is also in @b

=head2 matrix

 my $mat1 = matrix(
     data => [1..6],
     nrow => 2
 );

You can also pass C<< byrow =E<gt> 1 >> if you want the matrix populated row-wise instead of column-wise.

As of version 0.10, parameters do not need to be named, so that C<matrix> works more like R:

 my $d = matrix(rnorm(32000), 1000, 32);

works as C<data>, C<nrow>, and C<ncol>

=head2 max

 max(1,2,3);

or

 my @arr = 1..8;
 max(@arr, 4, 5)

as of version 0.02, max will die if any undefined values are provided

=head2 mean

 mean(1,2,3);

or

 my @arr = 1..8;
 mean(@arr, 4, 5)

or

 mean([1,1], [2,2]) # 1.5

as of version 0.02, mean will die if any undefined values are provided

=head2 median

works like mean, taking array references and arrays:

 median( $test_data[$i][0] )

as of version 0.02, median will die if any undefined values are provided

=head2 melt

Reshape a wide frame to long form, like C<pandas.DataFrame.melt>. One or more
identifier columns (C<id_vars>) are repeated down the output; every other
selected column (C<value_vars>) is unpivoted into a C<variable>/C<value> pair.

 melt($df,
     id_vars      => 'A' | [ 'A', 'B' ],   # kept, repeated (default: none)
     value_vars   => 'C' | [ 'C', 'D' ],   # unpivoted (default: all non-id cols)
     var_name     => 'variable',           # name of the column-name column
     value_name   => 'value',              # name of the value column
     'output.type' => 'aoh',               # aoa|aoh|hoa|hoh (default: input family)
 );

Column identifiers are names for AoH/HoA/HoH frames and 0-based integer
positions for AoA. C<value_vars> defaults to every column not in C<id_vars>, in
C<colnames()> order.

Output row order is B<column-major>: all rows for C<value_vars[0]>, then all
rows for C<value_vars[1]>, and so on, preserving input row order within each
block. HoH output has no natural row axis, so labels are reset to a
C<0 .. N-1> range index.

Returns a NEW frame; the input is never modified.

=head3 Example

 my $df = [ { A => 'a', B => 1, C => 2 },
            { A => 'b', B => 3, C => 4 } ];
 melt($df, id_vars => 'A', value_vars => [ 'B', 'C' ]);
 # [ { A => 'a', variable => 'B', value => 1 },
 #   { A => 'b', variable => 'B', value => 3 },
 #   { A => 'a', variable => 'C', value => 2 },
 #   { A => 'b', variable => 'C', value => 4 } ]

NA cells (undef, or a missing hash key) melt through to C<< value =E<gt> undef >>.

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; an
unknown C<output.type>; a C<value_vars>/C<id_vars> column that does not exist;
C<var_name> equal to C<value_name>; or C<var_name>/C<value_name> colliding with an
C<id_vars> column name.

=head2 merge

A full relational join of two data frames, in the spirit of R's C<merge> and pandas' C<DataFrame.merge>. Where L<#ljoin> only does an in-place left join of a hash-of-hashes keyed by row name, C<merge> supports every common join type, single- or multi-column keys, keys with different names on each side, column-collision suffixes, and any mix of input/output shapes.

 my $joined = merge($left, $right, how => 'inner', on => 'id');

C<$left> and C<$right> may each be an B<AoH> (array of row hash references), a B<HoA> (hash of column array references), or a B<HoH> (hash of row hash references; the outer key is treated as a row and is B<not> used as a join key). Both frames are read non-destructively.

=head3 Join types (C<how>)

=over

=item * C<inner> (default) — only rows whose keys match in both frames.

=item * C<left> — every C<$left> row, plus matching C<$right> columns (unmatched C<$right> columns become C<undef>).

=item * C<right> — every C<$right> row; the mirror image of C<left>.

=item * C<outer> (alias C<full>) — the union: all rows from both frames.

=item * C<cross> — the Cartesian product of the two frames; takes no keys.

=back

=head3 Choosing the keys

=over

=item * C<< on =E<gt> 'col' >> or C<< on =E<gt> ['c1', 'c2'] >> — join on one or more columns present under the same name in both frames. C<by> is an accepted synonym (R spelling).

=item * C<< 'left.on' =E<gt> .., 'right.on' =E<gt> .. >> — keys with different names on each side (each a name or an array reference of equal length). C<by.x>/C<by.y> and C<left_on>/C<right_on> are accepted synonyms. The result carries a single key column under the B<left> name.

=item * If neither is given, C<merge> performs a B<natural join> on the sorted intersection of the two frames' column names (it dies if that intersection is empty).

=back

Keys are matched on the B<stringified> cell value. A row whose key cell is C<undef> (or absent) never matches — the pandas C<NaN> rule — so such a row is dropped by an inner/right join and appears only as a left- or right-only row in a left/outer/right join.

=head3 Colliding columns (C<suffixes>)

A non-key column that appears in B<both> frames would collide, so each copy is renamed by appending a suffix: C<.x> to the left copy and C<.y> to the right by default (R's convention). Override with C<< suffixes =E<gt> ['_left', '_right'] >>.

=head3 Output shape

By default the result matches the shape of C<$left> (a HoH left frame yields an AoH, since a joined frame has no single row-name key). Force it with C<< 'output.type' =E<gt> 'aoh' >> or C<< 'output.type' =E<gt> 'hoa' >>.

=head3 Example

 my $emp  = [ { id => 1, name => 'Alice', dept => 10 },
              { id => 2, name => 'Bob',   dept => 20 },
              { id => 3, name => 'Carol', dept => 30 } ];
 my $dept = [ { dept => 10, dname => 'Sales' },
              { dept => 20, dname => 'Engineering' } ];
 
 my $left = merge($emp, $dept, how => 'left', on => 'dept');
 #  [ { id => 1, name => 'Alice', dept => 10, dname => 'Sales' },
 #    { id => 2, name => 'Bob',   dept => 20, dname => 'Engineering' },
 #    { id => 3, name => 'Carol', dept => 30, dname => undef } ]

See also L<#ljoin> (in-place HoH left join), L<#concat> / L<#rbind> (stacking frames row-wise), and L<#group_by>.

=head2 min

 min(1,2,3);

or

 my @arr = 1..8;
 min(@arr, 4, 5)

as of version 0.02, min will die if any undefined values are provided

=head2 mode

Takes either an array or an array reference, and returns an array of the most common scalars (numbers or strings)

 @arr = mode([1,3,3,3]); # returns (3)
 
 @arr = mode('a','a','c','c','z'); # returns ('a', 'c')

=head2 ncol

C<ncol($frame)> returns how many B<columns> a data frame has. Like C<nrow>, it
works on all the Stats::LikeR frame shapes, so you don't have to remember which
one you're holding:

 ncol([ [1,2,3], [4,5,6] ])         # 3   array of arrays  (AoA)
 ncol([ {a=>1,b=>2}, {a=>3,b=>4} ]) # 2   array of hashes  (AoH)
 ncol({ a=>[1,2], b=>[3,4] })       # 2   hash of arrays   (HoA)
 ncol({ r1=>{...}, r2=>{...} })     # 2   hash of hashes   (HoH)

=head3 NB

A B<column> is one field of each record. Where the fields live depends on the
shape:

=over

=item * B<Array of hashes> (AoH) — each row is a hash; the columns are its keys, so
the count is how many keys a row has.

=item * B<Array of arrays> (AoA) — each row is a list; the columns are its slots, so
the count is how long a row is.

=item * B<Hash of arrays> (HoA) — the keys I<are> the columns, so the count is the
number of keys.

=item * B<Hash of hashes> (HoH) — each value is a row hash; the columns are that
hash's keys, so the count is how many keys a row has.

=back

A plain flat list (C<[1,2,3]>) is treated as a single column.

=head3 Edge cases

 ncol([])                    # 0
 ncol({})                    # 0
 ncol({ a=>[], b=>[] })      # 2

Empty frames are 0 columns. Note the last one: a HoA still has its columns even
when they hold no rows — the keys are the columns, rows or not.

=head3 What it refuses to do

C<ncol> would rather stop than hand back a wrong number:

=over

=item * B<Ragged frame> — if the rows disagree on how many columns they have (AoH,
AoA, or HoH), there is no single column count, so it dies instead of guessing.

=item * B<Junk input> — C<undef>, a plain scalar, a SCALAR/CODE/GLOB ref, or a hash
whose values aren't all arrays (HoA) or all hashes (HoH) dies with a message
saying what it got.

=back

Blessed frames are fine — it looks at the underlying array/hash, so your
objects count just like plain refs.

=head2 nrow

C<nrow($frame)> returns how many B<rows> a data frame has. It works on all the
Stats::LikeR frame shapes, so you don't have to remember which one you're
holding:

 nrow([ [1,2,3], [4,5,6] ])       # 2   array of arrays  (AoA)
 nrow([ {a=>1}, {a=>2} ])         # 2   array of hashes  (AoH)
 nrow({ a=>[1,2,3], b=>[4,5,6] }) # 3   hash of arrays   (HoA)
 nrow({ r1=>{...}, r2=>{...} })   # 2   hash of hashes   (HoH)

=head3 NB

A B<row> is one record. Where the records live depends on the shape:

=over

=item * B<Array on the outside> (AoH, AoA, or a plain list) — each top-level
element is a row, so the count is just the array's length.

=item * B<Hash of hashes> (HoH) — each key is a row, so the count is the number of
keys.

=item * B<Hash of arrays> (HoA) — the keys are I<columns>, not rows; the row count is
how long those columns are.

=back

=head3 Edge cases

 nrow([])   # 0
 nrow({})   # 0

Empty frames are 0 rows, whatever the shape.

=head3 What it refuses to do

C<nrow> would rather stop than hand back a wrong number:

=over

=item * B<Ragged HoA> — if the columns have different lengths there is no single row
count, so it croaks instead of guessing.

=item * B<Junk input> — C<undef>, a plain scalar, or a hash whose values aren't all
arrays (HoA) or all hashes (HoH) croaks with a message saying what it got.

=back

Blessed frames are fine — it looks at the underlying array/hash, so your
objects count just like plain refs.

=head2 oneway_test

A one-way test for equality of group means that, unlike C<aov>/ANOVA, B<does not
assume equal variances>. By default it performs B<Welch's one-way test> (the
same default as R's C<oneway.test>), so the residual degrees of freedom are
usually fractional. Pass C<< var_equal =E<gt> 1 >> for the classic equal-variance form.

 use Stats::LikeR qw(oneway_test);

=head3 Input

C<oneway_test> accepts your data in one of three shapes. In every case each
I<group> is a vector of at least two numeric observations.

=for html <table>
<thead>
<tr>
  <th>Shape</th>
  <th>What it means</th>
  <th>Group labels</th>
</tr>
</thead>
<tbody>
<tr>
  <td><b>Hash of arrays</b> <code>{ a => [...], b => [...] }</code></td>
  <td>Each key is a group (R's <code>stack()</code> view of a named list)</td>
  <td>the hash keys</td>
</tr>
<tr>
  <td><b>Array of arrays</b> <code>[ [...], [...] ]</code></td>
  <td>Each element is a group</td>
  <td><code>"Index 0"</code>, <code>"Index 1"</code>, …</td>
</tr>
<tr>
  <td><b>Hash + <code>formula</code></b> <code>{ resp => [...], grp => [...] }, formula => 'resp ~ grp'</code></td>
  <td>Long-format columns split by a factor column</td>
  <td>the distinct values of the factor</td>
</tr>
</tbody>
</table>

=head3 Options

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>var_equal</code> (alias <code>var.equal</code>)</td>
  <td><code>0</code> (false)</td>
  <td><code>0</code> → Welch's test (unequal variances). <code>1</code> → pooled-variance test.</td>
</tr>
<tr>
  <td><code>formula</code></td>
  <td><i>none</i></td>
  <td><code>'response ~ factor'</code>. Only valid with a <b>hash</b> input; an error with an array of arrays.</td>
</tr>
</tbody>
</table>

=head3 Data validation

Every observation must be B<defined and numeric>; an C<undef> or non-numeric
cell makes the call C<die> with the offending group and position. This matches
the rest of C<Stats::LikeR> (C<mean>, C<sum>, C<cor>, … all die on C<undef>) and
prevents missing values from being silently treated as C<0>.

Each group needs at least two observations, and you need at least two groups.

=head3 Output

A hash reference with three top-level keys:

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Value</th>
</tr>
</thead>
<tbody>
<tr>
  <td><i>factor name</i> (<code>Group</code>, or the formula's factor, e.g. <code>supp</code>)</td>
  <td>the between-groups row: <code>Df</code>, <code>Sum Sq</code>, <code>Mean Sq</code>, <code>F value</code>, <code>Pr(>F)</code></td>
</tr>
<tr>
  <td><code>Residuals</code></td>
  <td>the within-groups row: <code>Df</code>, <code>Sum Sq</code>, <code>Mean Sq</code> (<code>Df</code> is fractional under Welch)</td>
</tr>
<tr>
  <td><code>group_stats</code></td>
  <td><code>{ mean => { group => mean, … }, size => { group => n, … } }</code></td>
</tr>
</tbody>
</table>

=head3 Examples

=head4 Hash of arrays (each key is a group)

 my $res = oneway_test({
     yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     ctrl  => [1,   1,   1,   0,   0,   0  ],
 });
 
 {
     Group => {
         Df        => 1,
         "Sum Sq"  => 61.6533333333333,
         "Mean Sq" => 61.6533333333333,
         "F value" => 177.504798464491,
         "Pr(>F)"  => 1.31343255160843e-07,
     },
     Residuals => {
         Df        => 9.81767348326473,   # fractional: Welch correction
         "Sum Sq"  => 3.47333333333333,
         "Mean Sq" => 0.353783749200256,
     },
     group_stats => {
         mean => { ctrl => 0.5, yield => 5.03333333333333 },
         size => { ctrl => 6,   yield => 6 },
     },
 }

=head4 Array of arrays (groups named by index)

 my $res = oneway_test([
     [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
     [1,   1,   1,   0,   0,   0  ],
 ]);

Identical to the hash form, except C<group_stats> is keyed by position:

 group_stats => {
     mean => { "Index 0" => 5.03333333333333, "Index 1" => 0.5 },
     size => { "Index 0" => 6,                "Index 1" => 6   },
 }

=head4 Long format with a formula

When your data is in columns rather than pre-split groups, name the response
and factor columns with a formula. The factor's I<values> become the groups and
the factor's I<name> becomes the top-level key:

 my $res = oneway_test(
     {
         len  => [4.2, 11.5, 7.3, 16.5, 17.3, 13.6, 23.6, 18.5, 33.9],
         supp => [qw(VC VC VC OJ OJ OJ HI HI HI)],
     },
     formula => 'len ~ supp',
 );
 # $res->{supp}, $res->{Residuals}, $res->{group_stats} ...

=head3 Classic equal-variance form

 my $res = oneway_test(\%groups, var_equal => 1);   # or 'var.equal' => 1

=head3 Notes

=over

=item * The default (Welch) does B<not> require equal group sizes or equal variances;
the pooled form (C<< var_equal =E<gt> 1 >>) assumes equal variances.

=item * C<formula> is only meaningful for a hash input. Passing it with an array of
arrays is an error.

=item * Group order in the output is not guaranteed for hash inputs (it follows hash
iteration order); read results by name, not position.

=item * Avoid naming a factor C<Residuals> or C<group_stats> in a formula, since those
are reserved top-level keys in the result.

=back

=head2 p_adjust

Returns array of false-discovery-rate-corrected p-values, where methods available are "holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr"

 my @q = p_adjust(\@pvalues, $method);

=head2 pivot_table

Aggregate a long frame into a wide one, like C<pandas.pivot_table>. Rows are
grouped by an C<index> key, spread across columns generated from a C<columns>
key, and reduced with C<aggfunc>.

 pivot_table($df,
     index       => 'city' | [ 'city', 'q' ],  # row key (default: none -> one row)
     columns     => 'year' | [ 'a', 'b' ],      # REQUIRED, generates output columns
     values      => 'temp' | [ 't', 'h' ],      # aggregated (default: all remaining cols)
     aggfunc     => 'mean' | [ 'sum', ... ] | sub { ... },
     skipna      => 1,        # 0 -> any NA in a bucket poisons a numeric reducer
     fill_value  => 0,        # substitute for NA result cells (default: leave undef)
     sort        => 1,        # 0 -> keep first-seen row/column order
     sep         => '.',      # joins pieces of generated column names
     'output.type' => 'aoh',  # aoa|aoh|hoa|hoh (default: input family)
 );

C<columns> is required. C<values> defaults to every column that is neither
C<index> nor C<columns>. Column identifiers are names for AoH/HoA/HoH and
0-based positions for AoA.

C<aggfunc> accepts the same vocabulary as C<agg()> — C<mean median sum sd var min
max count n nunique first last mode> — or a coderef (called as
C<< $code-E<gt>(\@cells) >> with every cell in the bucket, including undef), or an
arrayref of any of these. With C<< skipna =E<gt> 1 >> (default) undef cells are dropped
before a numeric reduction; C<< skipna =E<gt> 0 >> makes a numeric reducer return NA if
its bucket contains any NA.

Rows whose C<columns>-tuple contains NA are skipped (an unnameable column).
With no C<index>, all rows collapse to a single C<all> row.

=head3 Generated column names

A single value column reduced by a single function names each output column
after the C<columns>-tuple value alone (flat, pandas-like). Multiple functions
and/or multiple value columns prefix the function and/or value, joined by
C<sep>, in B<aggfunc-major> order (function, then value, then columns-tuple).
A collision between two generated names dies — pass a different C<sep> or
rename inputs.

=head3 Example

 my $df = [ { city => 'NY', year => 2020, temp => 10 },
            { city => 'NY', year => 2020, temp => 20 },
            { city => 'NY', year => 2021, temp => 30 },
            { city => 'LA', year => 2020, temp => 40 } ];
 pivot_table($df, index => 'city', columns => 'year', values => 'temp');
 # [ { city => 'LA', 2020 => 40,  2021 => undef },
 #   { city => 'NY', 2020 => 15,  2021 => 30    } ]
 
 pivot_table($df, index => 'city', columns => 'year', values => 'temp',
     aggfunc => [ 'count', 'sum' ]);
 # names: count.2020 count.2021 sum.2020 sum.2021

Rows and columns are sorted by default (numeric if every key is numeric, else
string); C<< sort =E<gt> 0 >> keeps first-seen order. HoH output labels come from the
C<index> values (C<'all'> with no index) and are uniquified with a numeric
suffix if two joined labels collide. Returns a NEW frame; the input is never
modified.

=head3 Errors

Dies on: undefined data; an odd trailing argument list; an unknown argument; a
missing C<columns>; an C<index>/C<columns>/C<values> column that does not exist; an
unknown C<aggfunc> string; an empty C<aggfunc> list; an unknown C<output.type>; or
a generated duplicate column name.

=head2 power_t_test

 $test_data = power_t_test(
     n   => 30,  delta     => 0.5, 
     sd  => 1.0, sig_level => 0.05
 );

It also allows configuring the test type (C<< type =E<gt> 'one.sample' >>, C<'two.sample'>, C<'paired'>) and alternative hypothesis (C<< alternative =E<gt> 'one.sided' >>). You can also pass C<< strict =E<gt> 1 >> to strictly evaluate both tails of the distribution.

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>n</code></td>
  <td>Float</td>
  <td><code>undef</code></td>
  <td>Number of observations (per group for two-sample, pairs for paired).</td>
</tr>
<tr>
  <td><code>delta</code></td>
  <td>Float</td>
  <td><code>undef</code></td>
  <td>True difference in means.</td>
</tr>
<tr>
  <td><code>sd</code></td>
  <td>Float</td>
  <td>1.0</td>
  <td>Standard deviation.</td>
</tr>
<tr>
  <td><code>sig_level</code></td>
  <td>Float</td>
  <td>0.05</td>
  <td>Significance level (Type I error probability). Also accepts <code>sig.level</code>.</td>
</tr>
<tr>
  <td><code>power</code></td>
  <td>Float</td>
  <td><code>undef</code></td>
  <td>Power of test (1 minus Type II error probability).</td>
</tr>
<tr>
  <td><code>type</code></td>
  <td>String</td>
  <td><code>"two.sample"</code></td>
  <td>Type of t-test: <code>"two.sample"</code>, <code>"one.sample"</code>, or <code>"paired"</code>.</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>String</td>
  <td><code>"two.sided"</code></td>
  <td>One- or two-sided test: <code>"two.sided"</code>, <code>"one.sided"</code>, <code>"greater"</code>, or <code>"less"</code>.</td>
</tr>
<tr>
  <td><code>strict</code></td>
  <td>Boolean</td>
  <td>0 (False)</td>
  <td>Use strict interpretation of two-sided power calculations.</td>
</tr>
<tr>
  <td><code>tol</code></td>
  <td>Float</td>
  <td>~<code>1.22e-4</code></td>
  <td>Numerical tolerance used for the internal root-finding algorithm.</td>
</tr>
</tbody>
</table>

=head2 pnorm

The normal cumulative distribution function: the probability that a normal random variable is C<< E<lt>= x >>. Ports R's C<pnorm>.
That is, take the integral from negative infinity to the point that you want.

 my $p = pnorm(1.96);            # 0.9750021  (standard normal, P(X <= 1.96))

C<x> may be a single number or an array reference; an array reference returns an array reference of the same length.

 my $ps = pnorm([-1.96, 0, 1.96]);   # [0.0249979, 0.5, 0.9750021]

=head3 Arguments

=for html <table>
<thead>
<tr>
  <th>Position</th>
  <th>Name</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>x</code></td>
  <td>—</td>
  <td>A number, or an array reference of numbers.</td>
</tr>
<tr>
  <td>2 +</td>
  <td><code>mean</code></td>
  <td><code>0</code></td>
  <td>Mean of the distribution.</td>
</tr>
<tr>
  <td></td>
  <td><code>sd</code></td>
  <td><code>1</code></td>
  <td>Standard deviation.</td>
</tr>
<tr>
  <td></td>
  <td><code>lower</code></td>
  <td><code>1</code> (true)</td>
  <td><code>1</code> = lower tail <code>P(X <= x)</code>; <code>0</code> = upper tail <code>P(X > x)</code>. <code>'lower.tail'</code> is an accepted alias.</td>
</tr>
<tr>
  <td></td>
  <td><code>log</code></td>
  <td><code>0</code> (false)</td>
  <td>If true, return the log of the probability. <code>'log.p'</code> is an accepted alias.</td>
</tr>
</tbody>
</table>

=head3 Examples

 pnorm(1.96);                    # lower tail:  0.9750021
 pnorm(1.96, lower => 0);        # upper tail:  0.0249979
 pnorm(1.96, log => 1);          # log lower tail: -0.02531565
 pnorm(2, mean => 1, sd => 0.5); # standardizes to z = 2: 0.9772499

Use C<< log =E<gt> 1 >> for tails that would otherwise underflow to C<0>:

 pnorm(-40);           # 0  (underflows)
 pnorm(-40, log => 1); # -804.6084

=head3 Notes

=over

=item * C<< sd =E<gt> 0 >> gives a step at the mean: C<< x E<lt> mean >> returns C<0>, otherwise C<1>.

=item * C<< sd E<lt> 0 >> returns C<NaN> and warns.

=item * A C<NaN> input (or an C<undef> element of an array reference) yields C<NaN>.

=item * C<+Inf> returns C<1>, C<-Inf> returns C<0>.

=back

=head2 prcomp

Principal Component Analysis

=head3 Options

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>center</code></td>
  <td>Boolean</td>
  <td><code>1</code> (True)</td>
  <td>If true, the variables are shifted to be zero-centered before the analysis takes place.</td>
</tr>
<tr>
  <td><code>scale</code></td>
  <td>Boolean</td>
  <td><code>0</code> (False)</td>
  <td>If true, the variables are scaled to have unit variance before the analysis takes place. <i>Note: If a column has zero variance, the function will <code>croak</code> to prevent division by zero.</i></td>
</tr>
<tr>
  <td><code>retx</code></td>
  <td>Boolean</td>
  <td><code>1</code> (True)</td>
  <td>If true, the rotated data (the original data multiplied by the rotation matrix) is returned under the key <code>x</code>.</td>
</tr>
<tr>
  <td><code>tol</code></td>
  <td>Number</td>
  <td><code>undef</code></td>
  <td>A value indicating the magnitude below which components should be omitted. Components are omitted if their standard deviation is less than or equal to <code>tol</code> times the standard deviation of the first component.</td>
</tr>
<tr>
  <td><code>rank</code></td>
  <td>Integer</td>
  <td><code>undef</code></td>
  <td>Optionally specify a strict limit on the number of principal components to return. The function will return <code>min(rank, rows, columns)</code> components.</td>
</tr>
</tbody>
</table>

=head3 Results

=head4 Returned Data Structure

The C<prcomp> function returns a HashRef containing the following keys representing the results of the Principal Component Analysis:

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Type</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>sdev</code></td>
  <td>ArrayRef[Number]</td>
  <td>The standard deviations of the principal components. Mathematically, these are the square roots of the eigenvalues of the covariance matrix.</td>
</tr>
<tr>
  <td><code>rotation</code></td>
  <td>ArrayRef[ArrayRef]</td>
  <td>A 2D array representing the matrix of variable loadings (the eigenvectors). Each inner array represents a row, and the columns correspond to the principal components.</td>
</tr>
<tr>
  <td><code>x</code></td>
  <td>ArrayRef[ArrayRef]</td>
  <td>A 2D array containing the rotated data (often referred to as PCA scores). This is the original data projected onto the principal components. <i>Note: Only present if the <code>retx</code> option is true.</i></td>
</tr>
<tr>
  <td><code>center</code></td>
  <td>ArrayRef[Number] or <code>0</code></td>
  <td>The centering values used (typically the column means). Returns false (<code>0</code>) if centering was disabled.</td>
</tr>
<tr>
  <td><code>scale</code></td>
  <td>ArrayRef[Number] or <code>0</code></td>
  <td>The scaling values used (typically the column standard deviations). Returns false (<code>0</code>) if scaling was disabled.</td>
</tr>
<tr>
  <td><code>varnames</code></td>
  <td>ArrayRef[String]</td>
  <td>The sorted names of the original variables. <i>Note: Only present if the input data was a Hash of Arrays (HoA) or a Hash of Hashes (HoH).</i></td>
</tr>
</tbody>
</table>

=head3 Using array of arrays

 my $aoa = [ 
     [2, 4], 
     [4, 2], 
     [6, 6] 
 ];
 
 my $pca = prcomp($aoa);

which returns

 {
     center     [
         [0] 4,
         [1] 4
     ],
     rotation   [
         [0] [
                 [0] 0.707106781186547,
                 [1] 0.707106781186548
             ],
         [1] [
                 [0] 0.707106781186548,
                 [1] -0.707106781186547
             ]
     ],
     scale      0,
     sdev       [
         [0] 2.44948974278318,
         [1] 1.4142135623731
     ],
     x          [
         [0] [
                 [0] -1.41421356237309,
                 [1] -1.4142135623731
             ],
         [1] [
                 [0] -1.4142135623731,
                 [1] 1.41421356237309
             ],
         [2] [
                 [0] 2.82842712474619,
                 [1] 2.22044604925031e-16
             ]
     ]
 }

=head3 Hash of Arrays

 my $hoa = { B => [4, 2, 6], A => [2, 4, 6] };
 my $pca = prcomp($hoa);

=head2 predict

R-style prediction for the fitted objects returned by C<lm> and C<glm>. It rebuilds
each row's linear predictor from the model's coefficients and (for C<glm>) applies
the inverse link.

=head3 Usage

 my $fit  = lm(formula => 'mpg ~ wt + hp', data => $train);
 my $yhat = predict($fit, $newdata);              # predictions on new rows
 my $resp = predict($logit_fit, $newdata);        # glm: response scale (default)
 my $eta  = predict($logit_fit, $newdata, type => 'link');   # linear predictor
 my $fitted = predict($fit);                      # no newdata -> stored fitted.values

=over

=item * B<< C<$model> >> — a fitted C<lm>/C<glm> hashref. C<predict> reads its C<coefficients>
(and, for C<glm>, its C<family>).

=item * B<< C<$newdata> >> — a HoA, AoH, or HoH of new observations. Omit it (or pass
C<undef>) to get the model's own C<fitted.values> back.

=item * B<< C<type> >> — C<'response'> (default) returns predictions on the response scale
(the inverse link applied — logistic for binomial); C<'link'> returns the linear
predictor. For C<lm> and gaussian C<glm> the link is the identity, so the two are
the same.

=back

=head3 What it returns

A hashref keyed by row name → prediction, exactly like C<lm>/C<glm> key
C<fitted.values>: a C<row.names> column (or HoH key) if present, otherwise 1-based
integer labels.

 my $m = lm(formula => 'y ~ x + I(x^2)', data => $train);
 my $p = predict($m, { x => [1, 2, 3] });
 # { 1 => ..., 2 => ..., 3 => ... }

=head3 How it works

For each new row the prediction is

 eta = Intercept + Σ  coef[term] · term(row)

where each C<term> is evaluated with the same engine used to fit the model, so
interactions (C<x:z> → product) and transforms (C<I(x^2)> → power) behave
identically to fitting. Coefficients that the fit marked aliased (stored as NaN)
contribute nothing, just as they were excluded from the fitted values. For C<glm>
with C<< family =E<gt> 'binomial' >> and C<< type =E<gt> 'response' >>, C<eta> is passed through the
logistic function C<1 / (1 + exp(-eta))>; otherwise C<eta> is returned as is.

A consequence worth noting: predicting on the I<training> data reproduces the
model's C<fitted.values> for any model built from continuous terms, interactions,
or C<I()> transforms.

=head3 Good to know

=over

=item * A prediction comes back as B<NaN> when a required term can't be evaluated in
the new data (a missing column, or a value that makes the term undefined).

=item * B<Factors are a limitation.> The fitted object stores only the dummy term
I<names> (e.g. C<genderM>), not the underlying factor levels, so C<predict>
cannot re-expand a raw categorical column in new data. Either pass pre-expanded
0/1 dummy columns whose names match the coefficient names, or extend C<lm>/C<glm>
to retain the factor levels.

=item * B<It dies> on: a model that isn't a hashref or has no C<coefficients>; an
invalid C<type>; or C<newdata> that isn't a HoA/HoH hashref or AoH arrayref.

=back

=head2 qcut

Equal-frequency binning of a numeric column, which is the analog of pandas C<qcut>.
Where C<cut> would slice a value range into equal-I<width> intervals (and dump
most of a skewed distribution into one bin), C<qcut> chooses cutpoints so each
bin holds roughly the same I<number> of observations. This is the binning you
usually want for ranked-list work: deciles, quartiles, top-5% tranches.

Cutpoints are computed by linear interpolation between order statistics, the
same method as numpy/pandas, so results match C<pandas.qcut> exactly. Bins are
right-closed, C<(a, b]>, with the lowest bin closed on both ends, C<[a, b]>, so
the minimum value is always included.

=head3 Signature

 qcut($data, $q, %options)

=over

=item * C<$data> — an array reference of numbers. C<undef> entries are treated as
missing (NA): they are skipped when computing cutpoints and, when codes are
requested, come back as C<undef> in their original positions.

=item * C<$q> — either a positive integer (the number of equal-frequency bins) or an
array reference of probabilities in C<[0, 1]> giving explicit cut
boundaries, e.g. C<[0, 0.5, 0.95, 1]>.

=back

For a usage reminder at the prompt, call C<qcut('h')> (or C<qcut('H')>); it dies
with a short help message.

=head3 What it returns

By default C<qcut> returns the B<edge vector as a flat list> — the cheap,
common query — so call it in list context:

 my @edges = qcut($data, 4);          # ($e0, $e1, $e2, $e3, $e4)

The per-element bin assignment (the expensive part) is opt-in. Ask for it with
C<< codes =E<gt> 1 >> and you get an array reference parallel to C<$data>:

 my $codes = qcut($data, 4, codes => 1);

Ask for both in a single pass and you get two references, C<($codes, $edges)>:

 my ($codes, $edges) = qcut($data, 4, codes => 1, edges => 1);

=head3 Options

=over

=item * C<< edges =E<gt> 1 >> — include the edge vector. On by default; turned off
automatically when you request codes, so set it explicitly to get both.

=item * C<< codes =E<gt> 1 >> — include the 0-based integer bin codes.

=item * C<< labels =E<gt> [...] >> — map the bin codes onto your own labels (implies
C<< codes =E<gt> 1 >>). The list length must equal the number of bins.

=item * C<< labels =E<gt> 'interval' >> — label each element with its interval string,
e.g. C<(3.25, 5.5]> (also implies codes).

=item * C<< duplicates =E<gt> 'drop' >> — if tied data produces non-unique cutpoints, merge
them into fewer bins instead of dying. The default, C<'raise'>, throws an
error (as pandas does).

=back

=head3 Examples

Quartile edges (the default). The cutpoints match pandas exactly:

 my @edges = qcut([1 .. 10], 4);
 # @edges = (1, 3.25, 5.5, 7.75, 10)

Bin codes. They are 0-based; note the tie distribution matches pandas (inner
bins take 2 here, outer bins 3):

 my $codes = qcut([1 .. 10], 4, codes => 1);
 # $codes = [0, 0, 0, 1, 1, 2, 2, 3, 3, 3]

Edges and codes together, computed in one pass:

 my ($codes, $edges) = qcut([1 .. 10], 4, codes => 1, edges => 1);

Equal frequency on clean data — 100 values into 4 bins of 25:

 my $codes = qcut([1 .. 100], 4, codes => 1);
 # 25 elements in each of bins 0, 1, 2, 3

An explicit probability vector, for an asymmetric top-5% tranche:

 my @edges = qcut([1 .. 100], [0, 0.5, 0.95, 1]);
 my $codes = qcut([1 .. 100], [0, 0.5, 0.95, 1], codes => 1);
 # bin 0: lower half (50), bin 1: next 45%, bin 2: top 5%

Named labels instead of integer codes (implies codes):

 my $labels = qcut([1 .. 10], 4, labels => [qw/Q1 Q2 Q3 Q4/]);
 # ['Q1','Q1','Q1','Q2','Q2','Q3','Q3','Q4','Q4','Q4']

Interval-string labels:

 my $iv = qcut([1 .. 10], 4, labels => 'interval');
 # $iv->[0]  eq '[1, 3.25]'
 # $iv->[-1] eq '(7.75, 10]'

Missing values are ignored for cutpoints, and (when codes are requested) pass
straight through:

 my $codes = qcut([1, 2, undef, 4, 5, 6, 7, 8, 9, 10], 4, codes => 1);
 # $codes->[2] is undef; the rest are binned as usual

Tied data and C<duplicates>. Heavy ties can make adjacent cutpoints equal; the
default raises, C<'drop'> merges:

 my @tied = ((0) x 8, 1, 2, 3, 4);
 qcut(\@tied, 4);                         # dies: bin edges are not unique
 my @edges = qcut(\@tied, 4, duplicates => 'drop');
 # fewer than 5 edges; the empty quantile bands are collapsed

Get the usage summary and stop:

 qcut('h');   # dies with the help text above

=head2 quantile

Calculates sample quantiles using R's continuous Type 7 interpolation. 

 my $quantile = quantile('x' => [1..99], probs => [0.05, 0.1, 0.25]);

If the C<probs> parameter is omitted, it behaves identically to R by defaulting to the 0, 25, 50, 75, and 100 percentiles (C<c(0, .25, .5, .75, 1)>). The returned hash keys match R's standardized naming convention (e.g., C<"25%">, C<"33.3%">).

=head2 rank

Rank values like R's C<rank()>. Takes flat scalars and/or array refs (like C<min>), with optional trailing C<ties.method> / C<na.last> options. Returns the list of ranks in input order.

 my @r = rank(3, 1, 4, 1, 5);                           # 3, 1.5, 4, 1.5, 5
 my @r = rank([3, 1, 4, 1, 5], 'ties.method' => 'min'); # 3, 1, 4, 1, 5

Ranks are 1-based; C<average> may return half-ranks. C<undef> and NaN are treated as NA.

=head3 ties.method

How tied values share ranks (default C<average>):

=for html <table>
<thead>
<tr>
  <th>value</th>
  <th>behavior</th>
  <th>`rank(3, 1, 4, 1, 5)`</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>average</code></td>
  <td>mean of the tied ranks</td>
  <td>3, 1.5, 4, 1.5, 5</td>
</tr>
<tr>
  <td><code>min</code></td>
  <td>lowest rank in the group</td>
  <td>3, 1, 4, 1, 5</td>
</tr>
<tr>
  <td><code>max</code></td>
  <td>highest rank in the group</td>
  <td>3, 2, 4, 2, 5</td>
</tr>
<tr>
  <td><code>first</code></td>
  <td>ties keep input order</td>
  <td>3, 1, 4, 2, 5</td>
</tr>
<tr>
  <td><code>last</code></td>
  <td>ties keep reverse input order</td>
  <td>3, 2, 4, 1, 5</td>
</tr>
<tr>
  <td><code>random</code></td>
  <td>ties broken randomly (srand-aware)</td>
  <td>varies</td>
</tr>
</tbody>
</table>

=head3 na.last

How C<undef>/NaN elements are placed (default C<true>):

=for html <table>
<thead>
<tr>
  <th>value</th>
  <th>behavior</th>
  <th>`rank(5, undef, 1, ...)`</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>true</code></td>
  <td>NAs get the highest ranks</td>
  <td>2, 3, 1</td>
</tr>
<tr>
  <td><code>false</code></td>
  <td>NAs get the lowest ranks</td>
  <td>3, 1, 2</td>
</tr>
<tr>
  <td><code>keep</code></td>
  <td>NAs stay undef, in place</td>
  <td>2, undef, 1</td>
</tr>
<tr>
  <td><code>na</code> (or undef)</td>
  <td>NAs dropped (shorter list)</td>
  <td>2, 1</td>
</tr>
</tbody>
</table>

=head2 Ronly

 my @only_last = Ronly(\@a, \@b, \@c);
 my $count     = Ronly(\@a, \@b, \@c);

The mirror of C<Lonly>: takes one or more array references and returns the values
that appear in the B<last> reference and in B<no other> reference; with a
single reference it returns that list's distinct values. Duplicates collapse,
the result keeps the last list's first-appearance order, and scalar context
returns the count. Values are compared by string form (see C<get_union>). A
non-array-ref argument or an C<undef> element is fatal. With exactly two
references this is the right-only set difference, so C<Ronly(\@a, \@b)> equals
C<Lonly(\@b, \@a)>; more generally C<Ronly(@refs)> equals C<Lonly(reverse @refs)>.

 my @a = (1, 2, 3, 4, 5);
 my @b = (3, 4, 5, 6, 7);
 my @c = (5, 6, 7, 8);
 my @r = Ronly(\@a, \@b, \@c);           # (8)  -- 5,6,7 also appear in @a or @b

=head2 rbinom

Create a binomial distribution of numbers

 my $binom = rbinom( n => $n, prob => 0.5, size => 9);

=head2 read_table

minimal example:

 my $test_data = read_table('t/HepatitisCdata.csv');

=head3 options

=for html <table>
<thead>
<tr>
  <th>Option</th>
  <th>Description</th>
  <th>Example</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>comment</code></td>
  <td>Comment character, by default <code>#</code>; lines beginning with it are skipped</td>
  <td><code>comment => '%'</code></td>
</tr>
<tr>
  <td><code>output.type</code></td>
  <td>data type for output: array of hash, hash of array, or hash of hash</td>
  <td><code>'output.type' => 'aoh'</code></td>
</tr>
<tr>
  <td><code>filter</code></td>
  <td>Only take in rows matching a filter</td>
  <td><code>filter => { Sex => sub {$_ eq 'f'} }</code></td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td>include row names in retrieved data; off by default</td>
  <td></td>
</tr>
<tr>
  <td><code>sep</code></td>
  <td>field separator character; synonym with <code>delim</code></td>
  <td><code>sep => "\t"</code></td>
</tr>
<tr>
  <td><code>delim</code></td>
  <td>field separator character; synonym with <code>sep</code></td>
  <td><code>delim => "\t"</code></td>
</tr>
<tr>
  <td><code>sheet</code></td>
  <td>which worksheet to read from an <code>.xlsx</code> file: a 1-based index or a sheet name (default: first sheet). Ignored for text files</td>
  <td><code>sheet => 'Sheet2'</code></td>
</tr>
</tbody>
</table>

output types can be AOH (aoh), HOA (hoa), HOH (hoh)
    read_table($filename, 'output.type' => 'aoh');
    read_table($filename, 'output.type' => 'hoa');
and, like Text::CSV_XS, filters can be applied in order to save RAM on big files:
    $test_data = read_table(
        't/HepatitisCdata.csv',
        filter => {
            Sex => sub {$_ eq 'f'} # where "Sex" is the column name, and "$_" is the value for that column
        },
        'output.type' => 'aoh'
    );
the default delimiter is C<,>
Suffixes C<.csv> and C<.tsv> are automatically detected from file names, but if specified, are overridden by C<delim> and/or C<sep>. C<sep> is given priority.

=head3 commented-out headers

A header that is itself commented out is detected and used automatically, so
    # PDB   score
    1a2b    10
    3c4d    20
reads as though the header were C<PDB, score> (the comment marker and any
following whitespace are stripped from the first column). A commented line is
only taken as the header when its field count matches the data, so ordinary
leading comments are never mistaken for one. You may name such a column in a
C<filter> either as it appears in the file or by its clean name:
    read_table('ranks.tabular.tsv', filter => { '# PDB' => sub { $_ == 2 } });

=head3 Excel (.xlsx) files

A file whose name ends in C<.xlsx> is read directly, with B<no extra
dependencies> — the parser uses the core C<IO::Uncompress::Unzip> module to pull
the parts out of the (zipped) workbook and reads the XML itself. All
C<output.type>, C<filter>, and C<row.names> options work exactly as they do for
text files:

 my $data = read_table('samples.xlsx');
 my $data = read_table('samples.xlsx', sheet => 'Results');   # by name
 my $data = read_table('samples.xlsx', sheet => 2);           # 1-based index

B<Multiple worksheets.> If the workbook has more than one worksheet and no
C<sheet> is given, C<read_table> returns a B<hashref keyed by worksheet name>,
each value being that sheet parsed just as a single table would be (honouring
C<output.type>, C<filter>, etc.):

 my $book = read_table('report.xlsx');   # { Sheet1 => [...], Sheet2 => [...] }
 my $rows = $book->{Results};

A workbook with a single worksheet, or a call that names a C<sheet> explicitly,
returns that one table directly (not wrapped in a hash).

Limitations: dates and times are returned as their raw Excel serial numbers
(cell number formats are not applied); and shared-string rich-text runs are
concatenated into a single value. The C<sep>, C<delim>, and C<comment> options do
not apply to C<.xlsx> files. Tested in C<t/read_table.xlsx.t>.

=head2 rename_cols

 rename_cols($df, old => new, ...)
 rename_cols($df, { old => new, ... })

Rename one or more columns of a data frame. Works on the labelled shapes
(C<AoH>, C<HoA>, C<HoH>); an C<AoA> has no column names and dies (convert to
C<AoH>/C<HoA> first). Identifiers are the inner-row keys for C<AoH>/C<HoH> and the
top-level keys for C<HoA>.

Behaviour depends on calling context:

=over

=item * B<Non-void> (scalar or list context) returns a fresh shallow B<view> and
never mutates the source. Row shapes (C<AoH>/C<HoH>) share the cell scalars by
reference via XS; a C<HoA> aliases the whole column arrayrefs under their new
keys.

=item * B<Void> context renames the source B<in place> and returns nothing: the
edit lands in each C<AoH>/C<HoH> row hash, or on the top-level keys of a C<HoA>.

=back

<!-- -->

 # HoH: rename an inner-row key in every row, in place
 rename_cols(\%d, resolution => 'Resolution (Å)');
 
 # capture a fresh view instead; %d is left untouched by rename_cols itself
 %d = %{ rename_cols(\%d, resolution => 'Resolution (Å)') };
 
 # pairs or a single hashref; both forms are equivalent
 my $view = rename_cols($aoh, a => 'x', c => 'z');
 my $view = rename_cols($hoa, { b => 'B' });

Both the in-place and view paths are swap-safe (gather-then-set), so an
exchange renames correctly:

 rename_cols($sw, a => 'b', b => 'a');   # {a=>1,b=>2} -> {b=>1,a=>2}

Ragged C<AoH>/C<HoH> frames stay ragged: an old key that is absent from a given
row is simply skipped for that row. For a C<HoA>, the renamed key points at the
I<same> column arrayref (no copy), so a later C<push>/C<splice> on it is shared
with the source.

Dies (all validation runs B<before> any mutation, so a dying void call leaves
the source unchanged):

=over

=item * an old column that is not present anywhere in the frame,

=item * a new name that is C<undef>,

=item * a rename whose target collides with a kept column or another renamed target,

=item * an odd-length C<< old =E<gt> new >> argument list,

=item * an C<AoA> (no column names to rename).

=back

Note: C<\%d = rename_cols(...)> is B<not> valid Perl — a reference constructor
is not an lvalue before 5.22 refaliasing, which is out under the module's 5.10
back-compatibility. Use the void form or the C<%d = %{ ... }> capture idiom
above.

=head2 I<rename>inplace

 _rename_inplace($df, $shape, \%map)

Private helper (not exported) that backs C<rename_cols>'s void-context path;
C<rename_cols> performs all argument checking first, so this never has to croak.
For a C<HoA> it renames the top-level column keys; for C<AoH>/C<HoH> it renames
the keys inside each row hash. It gathers the moved values before re-storing
them, which makes it swap-safe, and it only touches keys that actually C<exists>
in a given row, which preserves ragged frames. Mutates C<$df> and returns
nothing.

=head2 rnorm

Make a normal distribution of numbers, with pre-set mean C<mean>, standard deviation C<sd>, and number C<n>.

 my ($rmean, $sd, $n) = (10, 2, 9999);
 my $normals = rnorm( n => $n, mean => $rmean, sd => $sd);

=head2 rownames

Return the row names of a data frame, as a list (like R's C<rownames>).
Only C<HoH> carries genuine row labels; the other shapes are positional and
so yield 0-based indices, again matching C<view>:

=over

=item * C<AoA> / C<AoH> — C<0 .. $#$df> (one index per top-level element)

=item * C<HoA> — C<0 .. longest_column-1>

=item * C<HoH> — the string-sorted outer keys (the row labels)

=back

In scalar context it returns the count, so C<scalar rownames($df)> equals
C<nrow($df)> for a rectangular frame.

 my $hoh = { r2 => { x => 1 }, r1 => { x => 2 }, r3 => { x => 3 } };
 my @rows = rownames($hoh);        # ('r1', 'r2', 'r3')  -- sorted labels
 
 my $aoh = [ { a => 1 }, { a => 2 } ];
 my @rows = rownames($aoh);        # (0, 1)
 
 my $hoa = { a => [1,2,3], b => [4,5,6] };
 my @rows = rownames($hoa);        # (0, 1, 2)
 
 my $n = rownames($hoh);           # 3  (scalar context == nrow)

=head3 notes

Shape is detected with the same C<_df_shape> classifier C<agg> uses, so both
functions accept exactly the frames C<agg>/C<view> accept. A ragged frame is
tolerated for enumeration: C<colnames> spans the widest row and C<rownames>
the longest column. An empty frame returns an empty list. Because the
classifier is C<ref>-based (not C<reftype>), pass an unblessed frame — blessed
frames are the one case C<ncol>/C<nrow> accept that this family does not.

=head2 runif

Make an approximately uniform distribution into an array

=head3 named arguments

 my $unif = runif( n => $n, min => 0, max => 1);

where C<n> is the number of items, the values are between C<min> and C<max>

=head3 positional args

this is to match R's behavior:

 runif( 9 )

will make 9 numbers in [0,1]

 runif(9, 0, 99)

will match C<n>, C<min>, and C<max> respectively

=head2 sample

take a sample of hash or array slices.

 my $h = sample(\%h, 4); # take 4 hash keys and their values into $h

or, alternatively, with arrays:

 my $arr = sample(\@arr, 3); # take 3 indices of an array

=head2 scale

 my @scaled_results = scale(1..5);

You can also pass an options hash to disable centering or scaling:

 my @scaled_results = scale(1..5, { center => false, scale => 1 });

It fully supports matrix operations. By passing an array of arrays, C<scale> processes the data column by column independently:

 my $scaled_mat = scale([[1, 2], [3, 4], [5, 6]]);

=head2 sd

 my $stdev = sd(2,4,4,4,5,5,7,9);

Correct answer is 2.1380899352994

C<sd> can accept both array references as well as arrays:

 my $stdev = sd([2,4,4,4,5,5,7,9]);

As of version 0.02, sd will croak/die if any undefined values are provided.

=head2 select_cols

Return a new data frame containing only the named columns, in the order
requested — the Stats::LikeR form of pandas C<df[['a','b']]>. Works on all
four frame shapes. For C<AoA> the identifiers are 0-based integer positions;
for C<AoH>, C<HoA>, and C<HoH> they are column names. Columns may be given as a
list or as a single arrayref.

 my $aoh = [ { a => 1, b => 2, c => 3 },
             { a => 4, b => 5, c => 6 } ];
 my $sub = select_cols($aoh, 'a', 'c');
 # [ { a => 1, c => 3 }, { a => 4, c => 6 } ]
 
 my $hoa = { a => [1,4], b => [2,5], c => [3,6] };
 my $sub = select_cols($hoa, ['c', 'a']);   # order preserved
 # { c => [3,6], a => [1,4] }
 
 my $aoa = [ [1,2,3], [4,5,6] ];
 my $sub = select_cols($aoa, 0, 2);
 # [ [1,3], [4,6] ]

A column that appears in only some C<AoH>/C<HoH> rows is filled with C<undef> in
the rows that lack it, so the selection comes back rectangular:

 select_cols([ {a=>1,b=>2}, {a=>3,c=>9} ], 'a', 'c');
 # [ { a => 1, c => undef }, { a => 3, c => 9 } ]

=head2 seq

Works as closely as I can to R's seq, which is very similar to Perl's C<for> loops.  Returns an array, not an array reference.

=head3 Standard integer sequence

 say 'seq(1, 5):';
 my @seq = seq(1, 5);
 say join(', ', @seq), "\n";
 
 say 'seq(1, 2, 0.25):';
 @seq = seq(1, 2, 0.25);

=head3 Fractional steps

 say 'seq(1, 2, 0.25):';
 @seq = seq(1, 2, 0.25);
 say join(", ", @seq), "\n";
 for (my $idx = 2; $idx >= 1; $idx -= 0.25) { # count down to pop
     is_approx(pop @seq, $idx, "seq item $idx with fractional step");
 }

=head3 Negative steps

 say 'seq(10, 5, -1):';
 @seq = seq(10, 5, -1);
 say join(", ", @seq), "\n";
 for (my $idx = 5; $idx <= 10; $idx++) { # count down to pop
     is_approx(pop @seq, $idx, "seq item $idx with negative step");
 }

=head2 shapiro_test

tests to see if an array reference is normally distributed, returns a p-value and a statistic

 my $shapiro = shapiro_test(
     [1..5]
 );

and returns the hash reference:

 {
 p.value     0.589650577093106,
 p_value     0.589650577093106,
 statistic   0.960870680168535,
 W           0.960870680168535
 }

=head2 sum

returns sum, but using both arrays and array references.

 my $test_data = [1..8];
 sum($test_data)

which I prefer, compared to List::Util's required casting into an array:

 sum(@{ $test_data });

which passing a reference is shorter and much easier to read.  Stats::LikeR, however, will work for B<both>

as of version 0.02, C<sum> will cause the script to die if any undefined values are provided

=head2 summary

Analogous to R's C<summary>: a five-number-plus-mean description (C<# values>, C<Min.>, C<1st Qu.>, C<Median>, C<Mean>, C<3rd Qu.>, C<Max.>) of the data as entered (it does not summarise fitted-model objects). It produces one statistics row per numeric I<variable> and renders the table exactly like L<#view> — the same colourised, wide-character-aware, terminal-fitting output — through the same internal renderer, so all of C<view>'s display options apply.

Which variable becomes a row depends on the shape (every shape C<view> accepts is accepted here):

=for html <table>
<thead>
<tr>
  <th>input</th>
  <th>one row per…</th>
  <th>label column</th>
</tr>
</thead>
<tbody>
<tr>
  <td>flat vector — <code>summary(@x)</code>, <code>summary(\@x)</code>, or a bare list</td>
  <td>the whole vector</td>
  <td><i>(none)</i></td>
</tr>
<tr>
  <td>array of arrays (AoA)</td>
  <td>inner array</td>
  <td><code>Index</code></td>
</tr>
<tr>
  <td>hash of arrays (HoA)</td>
  <td>key</td>
  <td><code>Key</code></td>
</tr>
<tr>
  <td>array of hashes (AoH) / hash of hashes (HoH)</td>
  <td>column, gathered across rows</td>
  <td><code>Column</code></td>
</tr>
</tbody>
</table>

The AoH/HoH case is the per-column summary R gives for a data frame — so the array-of-hashes that C<read_table> returns by default summarises column-by-column:

 summary(read_table('data.csv'));       # one row per column
 summary(\%hoh, nrows => 20);            # cap the rows shown
 summary(\@x, color => 1);               # force colour (default: auto on a TTY)
 my $txt = summary(\%hoa, return_only => 1);   # capture instead of printing

Non-numeric and undefined cells are ignored: they never count toward C<# values>, and a variable with no numeric values shows C<0> and C<na>. For example, C<summary> of an AoH:

 # summary: 2 rows x 7 cols  (showing 2)
 Column  # values  Min.  1st Qu.  Median  Mean  3rd Qu.  Max.
 x              3     1      1.5       2     2      2.5     3
 y              3    10       15      20    20       25    30

C<summary> prints the table (unless C<return_only> is set) and returns it as a string. C<nrows> (synonyms C<nrow>, C<n>, C<rows>) caps the rows shown, and the C<view> display options C<na>, C<color>, C<colors>, C<max_width>, C<ellipsis>, C<gap>, C<width>, C<to>, and C<return_only> all apply.

=head2 t_test

There are 1-sample and 2-sample t-tests, from one or two arrays:

 my $t_test = t_test( $array1, mu => 0.2334 );

or 2-sample:

 $t_test = t_test(
     $array1,    $array2,
     paired => 1
 );

returns a hash reference, which looks like:

 conf_int     => [
     -0.06672889, 0.25672889
 ],
 df        => 5,
 estimate  => 0.095,
 p_value   => 0.19143688433660,
 statistic => 1.50996688705414

the two groups compared can be specified, though not necessarily, as C<x> and C<y>, just like in R:

 $t_test = t_test(
     'x' => $array1, 'y' => $array2,
     paired => 1
 );

=head3 Parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>x</code></td>
  <td>Array Reference</td>
  <td>Required</td>
  <td>The first vector of data. Must contain at least 2 elements.</td>
</tr>
<tr>
  <td><code>y</code></td>
  <td>Array Reference</td>
  <td><code>undef</code></td>
  <td>The second vector of data. Required for two-sample or paired tests.</td>
</tr>
<tr>
  <td><code>mu</code></td>
  <td>Float</td>
  <td>0.0</td>
  <td>The true value of the mean (or difference in means) for the null hypothesis.</td>
</tr>
<tr>
  <td><code>paired</code></td>
  <td>Boolean</td>
  <td><code>FALSE</code></td>
  <td>If true, performs a paired t-test. <code>x</code> and <code>y</code> must be the same length.</td>
</tr>
<tr>
  <td><code>var_equal</code></td>
  <td>Boolean</td>
  <td><code>FALSE</code></td>
  <td>If true, assumes equal variances (standard two-sample). If false, performs Welch's t-test with unequal variances.</td>
</tr>
<tr>
  <td><code>conf_level</code></td>
  <td>Float</td>
  <td>0.95</td>
  <td>Confidence level for the returned confidence interval. Must be between 0 and 1.</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>String</td>
  <td><code>"two.sided"</code></td>
  <td>Direction of the alternative hypothesis: <code>"two.sided"</code>, <code>"less"</code>, or <code>"greater"</code>.</td>
</tr>
</tbody>
</table>

=head3 Return Hash

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>statistic</code></td>
  <td>The computed t-statistic.</td>
</tr>
<tr>
  <td><code>df</code></td>
  <td>Degrees of freedom for the test.</td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td>The calculated p-value based on the test directionality.</td>
</tr>
<tr>
  <td><code>conf_int</code></td>
  <td>An Array Reference containing two elements: <code>[lower_bound, upper_bound]</code>.</td>
</tr>
<tr>
  <td><code>estimate</code></td>
  <td>The estimated mean of <code>x</code> (one-sample) OR the mean of the differences (paired).</td>
</tr>
<tr>
  <td><code>estimate_x</code></td>
  <td>The estimated mean of the <code>x</code> vector (only returned in two-sample tests).</td>
</tr>
<tr>
  <td><code>estimate_y</code></td>
  <td>The estimated mean of the <code>y</code> vector (only returned in two-sample tests).</td>
</tr>
</tbody>
</table>

=head2 transpose

Transposes a two-dimensional data structure, swapping rows and columns. Accepts either an array of arrays or a hash of hashes.
Returns a new reference of the same type; the input is never modified.

=head3 Array of array input

Takes a reference to an array of array references and returns a new AoA where C<output[j][i] = input[i][j]>.

 my $matrix = [[1, 2, 3], [4, 5, 6]];
 my $t = transpose($matrix);
 # [[1, 4],
 #  [2, 5],
 #  [3, 6]]

All rows must be the same length; a ragged input is a fatal error.
C<undef> is valid as an element value and is preserved exactly. An empty outer array or an array of empty rows both return C<[]>.

Dies if:
- any inner element is not an array reference
- rows differ in length (ragged array)

=head3 Hash of hash input

Takes a reference to a hash of hash references and returns a new HoH where C<output{col}{row} = input{row}{col}>.

 my $table = { alice => { score => 97, grade => 'A' }, bob   => { score => 84, grade => 'B' } };
 my $t = transpose($table);
 # { score => { alice => 97,  bob => 84  },
 #   grade => { alice => 'A', bob => 'B' } }

Inner keys do not need to be uniform across rows. If a given column key appears in only some rows, the output hash for that column will simply contain only those rows — no padding or C<undef>-filling is performed.

 my $sparse = {
 a => { x => 1, y => 2 },
 b => { x => 3, z => 4 } };
 
 my $t = transpose($sparse);
 # { x => { a => 1, b => 3 },
 #   y => { a => 2 },
 #   z => { b => 4 } }

An empty outer hash or an outer hash whose inner hashes are all empty both return C<{}>.

Dies if any inner element is not a hash reference

=head2 uniq

Returns the distinct values of its arguments, in first-seen order.

 use Stats::LikeR;
 
 my @u = uniq(1, 2, 2, 3, 1);         # (1, 2, 3)
 my @s = uniq(qw/a b a c/);           # ('a', 'b', 'c')
 my @f = uniq(1, [2, 2, 3], [3, 4]);  # (1, 2, 3, 4)
 my $n = uniq(1, 2, 2, 3, 1);         # 3

C<uniq> accepts a flat list of scalars, array references, or any mix of the
two. Array references are expanded B<one level> — their elements are treated
as additional arguments, but nested array references are not recursed into and
are compared as opaque values.

Values are compared by stringification, the same C<eq> semantics used by
C<List::Util::uniq>: C<1>, C<1.0>, and C<"1"> all collapse to a single result, and
the first value seen is the one returned (as a fresh copy, never an alias to
the input). Order of first appearance is preserved.

In list context C<uniq> returns the distinct values. In scalar context it
returns the I<count> of distinct values, matching C<List::Util::uniq>.

The UTF-8 flag is part of the comparison key, so a UTF-8 string and a
byte-identical non-UTF-8 string are kept distinct — they are different strings.
Strings that are logically equal and consistently encoded collapse as expected.

Unlike C<List::Util::uniq>, which passes a single C<undef> through, C<uniq>
B<croaks> on any undefined value, reporting the offending argument index (and
the array-ref index, when the undef came from inside a reference):

 uniq(1, undef, 3);     # croaks: undefined value at argument index 1
 uniq([1, undef, 3]);   # croaks: undefined value at array ref index 1 (argument 0)

This matches the undef-handling of C<mean> and the other functions in Stats::LikeR.

=head2 vals

Extract a single column from a data frame as a flat array reference, similar to pandas' C<to_list>

 my $ages = vals($df, 'age');

C<vals> accepts all three data-frame shapes and always returns a new arrayref of that column's values:

=over

=item * B<AoH> (array of hashes) -- one value per row, in row order.

=item * B<HoA> (hash of arrays) -- the named column array, copied.

=item * B<HoH> (hash of hashes) -- one value per row, in B<ascending key order> (a HoH has no inherent row order, so keys are sorted as strings).

=back

=head3 Arguments

=for html <table>
<thead>
<tr>
  <th>Position</th>
  <th>Name</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td>1</td>
  <td><code>$df</code></td>
  <td>An AoH (arrayref), or a HoA/HoH (hashref). The shape is auto-detected by peeking the first hash value: a hashref value means HoH, otherwise HoA.</td>
</tr>
<tr>
  <td>2</td>
  <td><code>$col</code></td>
  <td>The column name (must be defined).</td>
</tr>
</tbody>
</table>

=head3 Behavior and notes

=over

=item * B<The result is a copy.> Every value is duplicated, so mutating the returned array never touches C<$df>, and C<undef> slots are ordinary writable scalars.

=item * B<< A missing cell is C<undef>. >> For AoH and HoH, a row that lacks the column (or isn't a hashref) yields C<undef> for that row.

=item * B<An absent column is strict only for HoA.> Because a HoA column I<is> the structure, asking for a column the hash doesn't have dies. For AoH/HoH the column is per-row, so an entirely-absent column simply yields all-C<undef> (it is not an error). This asymmetry is deliberate; pass the column name carefully for AoH/HoH, since a typo returns C<undef>s rather than dying.

=item * B<< Empty frames return C<[]> >> -- an empty AoH or an empty hash both give a clean empty arrayref.

=item * UTF-8 column names and HoH keys are handled correctly (lookups use the key SV; HoH keys sort by Perl string order).

=back

=head3 Examples

 my $aoh = read_table('patients.csv');                 # array of hashes
 my $age = vals($aoh, 'Age');                           # [ 34, 51, ... ]
 
 my $hoa = read_table('patients.csv', 'output.type' => 'hoa');
 my $sex = vals($hoa, 'Sex');                           # copy of the Sex column
 
 my $hoh = read_table('patients.csv', 'output.type' => 'hoh');
 my $age2 = vals($hoh, 'Age');                          # values in sorted row-key order
 
 # feed straight into the numeric routines
 my $m = mean( vals($aoh, 'Age') );

=head2 value_counts

Count the values in a given data set, return a hash reference showing how many times each particular value is present.

=head3 Scalar

 $hash = value_counts('c');

returns C<< { c =E<gt> 1 } >>

=head3 Array reference

 value_counts(['a','b','b']);

returns C<< { a =E<gt> 1, b =E<gt> 2} >>

=head3 Array

 my $value_counts = value_counts('a','b','b');

like an array reference above, returns C<< { a =E<gt> 1, b =E<gt> 2} >>

=head3 Array of hashes

 my @records = (
     { name => 'Alice', dept => 'Sales' },
     { name => 'Bob',   dept => 'Eng'   },
     { name => 'Carol', dept => 'Sales' },
 );
 my $vc = value_counts(\@records, 'dept');

with a key, the value at that key is counted in each hash, so the above returns C<< { Sales =E<gt> 2, Eng =E<gt> 1 } >>. A record that lacks the key is skipped. Passing an array of hashes without a key, or with an element that is not a hash reference, is a fatal error.

=head3 Array of arrays

 my @rows = (['a', 1], ['b', 1], ['a', 2]);
 my $vc = value_counts(\@rows, 0);

when the elements are array references, the key is treated as a numeric column index, so the above returns C<< { a =E<gt> 2, b =E<gt> 1 } >>. A non-numeric index against array-reference elements is a fatal error.

=head3 Hash

 my $value_counts = value_counts( { A => 'a', B => 'a', C => 'b' } );

returns C<< { a =E<gt> 2, b =E<gt> 1} >>

=head3 Hash of array

 my $value_counts = value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']});

without a key (like above), the occurences of C<j>, C<t>, and C<v> are counted.
With a key, like C<a> for above, only values within that hash key are counted:

 my $vc = value_counts({ 'a' => ['j', 't', 't'], 'b' => ['j', 't', 'v']}, 'a');

=head3 Hash of hash (table)

 $hash = value_counts( {
     A => {
         a => 'x',
         b => 'z'
     },
     B => {
         a => 'x'
     },
     C => {
         a => 'y'
     }
 }, 'a');

the column, or second hash key, that you wish to count, is specified at the command line

The two new subsections (Array of hashes, Array of arrays) are the only additions; everything else is unchanged. They're placed after the array-container forms to keep array inputs grouped, mirroring how Hash of array / Hash of hash sit together. If you'd rather I drop this into a C<.md> file or fold it into POD (C<=head3> headers, C<< CE<lt>E<gt> >> for the inline code) for the actual module docs, say the word.

=head2 var

as simple as possible:

 var(2, 4, 5, 8, 9)

as of version 0.02, C<var> will die if any undefined values are provided

like C<min>, C<max>, etc., C<var> can accept array references, to make code simpler:

 my $ref = \@arr;
 var($ref) = var(@arr)

=head2 var_test

As described by R: Performs an F test to compare the variances of two samples from normal populations

 use Stats::LikeR;
 
 my @x = (2.9, 3.0, 2.5, 2.6, 3.2);
 my @y = (3.8, 2.7, 4.0, 2.4);
 
 my $vt = var_test(\@x, \@y);

also, conf_level can be set:

 $vt = var_test(\@x, \@y, conf_level => 0.99);

as well as a ratio (from R: the hypothesized ratio of the population variances of C<x> and C<y>:

 $test_data = var_test(\@xk, \@yk, ratio => 2);

=head2 view

An R-style C<head> for the structures C<read_table> returns. Prints the first
few rows of a dataframe as an aligned text table, with numeric columns
right-justified, string columns left-justified, and undefined cells shown as
C<NA>.

=for html <table>
<thead>
<tr>
  <th>Input type</th>
  <th>Perl structure</th>
  <th>What `view` shows</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>aoa</code></td>
  <td>array of array refs</td>
  <td>values gathered column-wise by row index</td>
</tr>
<tr>
  <td><code>aoh</code></td>
  <td>array of hash refs</td>
  <td>one line per row, sequential row numbers</td>
</tr>
<tr>
  <td><code>hoa</code></td>
  <td>hash of array refs</td>
  <td>values gathered column-wise by row index</td>
</tr>
<tr>
  <td><code>hoh</code></td>
  <td>hash of hash refs</td>
  <td>top-level keys become the row label column</td>
</tr>
</tbody>
</table>

=head3 Synopsis

 my $aoh = read_table('all.data.tsv', 'output.type' => 'aoh');
 
 view($aoh);                       # first 6 rows, like head()
 view($aoh, n => 20);              # first 20 rows
 view($aoh, cols => [qw(id age tt)]);   # force a column order
 view($aoh, 'row.names' => 'id');  # use column 'id' as the row label
 view($aoh, na => '.', max_width => 30);
 
 my $txt = view($aoh, return_only => 1);  # capture the string, print nothing
 view($aoh, to => \*STDERR);              # print somewhere other than STDOUT

=head3 Output

 # AoH: 7 rows x 3 cols  (showing 6)
 row_name  Testosterone, total (nmol/L)  age  sex
 p1                                18.2   41  M
 p2                                  NA    7  F
 p3                                1.05   33  F
 p4                                22.9   55  M
 p5                                  14   29  M
 p6                                  NA   62  F
 # ... 1 more row

The banner reports the structure type, full dimensions, and how many rows are
displayed. A footer appears only when rows are hidden.

=head3 Arguments

All arguments after the data reference are optional name/value pairs.

=for html <table>
<thead>
<tr>
  <th>Argument</th>
  <th>Default</th>
  <th>Meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>n</code></td>
  <td><code>6</code></td>
  <td>Number of rows to show. <code>n</code> greater than the table shows everything.</td>
</tr>
<tr>
  <td><code>rows</code></td>
  <td><code>6</code></td>
  <td>Number of rows to show. <code>n</code> greater than the table shows everything  (synonymous with <code>n</code>)</td>
</tr>
<tr>
  <td><code>cols</code> / <code>columns</code></td>
  <td>—</td>
  <td>Array ref pinning column order (and which columns appear).</td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td>—</td>
  <td>Column to use as the row label (for <code>aoh</code>/<code>hoa</code>). See ordering note.</td>
</tr>
<tr>
  <td><code>na</code></td>
  <td><code>'NA'</code></td>
  <td>Token printed for undefined cells</td>
</tr>
<tr>
  <td><code>max_width</code></td>
  <td><code>80</code></td>
  <td>Truncate any cell wider than this (column names are never truncated)</td>
</tr>
<tr>
  <td><code>ellipsis</code></td>
  <td><code>'...'</code></td>
  <td>Marker appended to truncated cells</td>
</tr>
<tr>
  <td><code>gap</code></td>
  <td><code>2</code></td>
  <td>Spaces between columns</td>
</tr>
<tr>
  <td><code>to</code></td>
  <td>STDOUT</td>
  <td>Filehandle to print to.</td>
</tr>
<tr>
  <td><code>return_only</code></td>
  <td><code>0</code></td>
  <td>If true, return the string and print nothing</td>
</tr>
</tbody>
</table>

C<view> always returns the formatted string, whether or not it also prints.

=head3 A note on column order

C<read_table> stores rows as hashes, so the original CSV column order is not
preserved. C<view> therefore sorts columns by name for a stable, reproducible
layout. Two conveniences soften this:

=over

=item * A column literally named C<row_name> (the label C<read_table> assigns to a
leading blank header) is detected automatically and moved to the left as the
row label.

=item * Pass C<< cols =E<gt> [ ... ] >> to control both the order and the selection of columns
shown.

=back

When no label column is present, C<view> numbers the rows C<1, 2, 3, …>, the way
R prints row names for an unnamed data frame.

=head3 Edge cases

=over

=item * Empty input (C<[]> or C<{}>) prints a clean C<0 rows x 0 cols> banner.

=item * Tabs, carriage returns, and newlines inside a cell are escaped (C<\t>, C<\r>,
C<\n>) so one record always stays on one line.

=item * A non-reference argument, or a hash whose values are plain scalars, dies with
a clear message rather than producing garbled output.

=back

=head3 Tests

The behavior above is covered by C<view.t> (run with C<prove view.t>): the three
structure types, C<n> boundaries, alignment, C<NA> rendering, truncation,
C<row.names>/C<cols> handling, control-character escaping, the C<return_only> and
C<to> output paths, empty structures, and the error cases.

=head2 wilcox_test

 $test_data = wilcox_test(
     [1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
     [0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
 );

Computes the Wilcoxon rank-sum / Mann-Whitney test (two samples) or the Wilcoxon signed-rank test (one sample or paired), following R's C<wilcox.test> conventions.
This is an alternative to the t-test, that does not assume a normal distribution.
With two array refs and no C<paired> flag it runs the two-sample rank-sum test; with a single sample, or with C<< paired =E<gt> 1 >>, it runs the signed-rank test. It calculates exact p-values by default for C<< N E<lt> 50 >> without ties; when ties (or, for the signed-rank case, zero differences) are present it automatically switches to the normal approximation with continuity correction.

=head3 Calling conventions

The first one or two array-ref arguments are taken positionally as C<x> and C<y>; everything after that is parsed as C<< key =E<gt> value >> pairs. The named forms C<< x =E<gt> >> and C<< y =E<gt> >> are also accepted and override the positional values. The flat argument list following the positional refs must contain an even number of elements, or the call dies with a usage message.

 # positional
 wilcox_test(\@x, \@y, paired => 1);
 
 # fully named
 wilcox_test(x => \@x, y => \@y, alternative => "greater", exact => 0);

=head3 Input parameters

=for html <table>
<thead>
<tr>
  <th>Parameter</th>
  <th>Type</th>
  <th>Default</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>x</code></td>
  <td>ARRAY ref</td>
  <td><i>(required)</i></td>
  <td>The first sample. Passed positionally or as <code>x =></code>. Non-numeric and undefined elements are silently dropped; an empty or all-missing <code>x</code> is fatal. In the two-sample test <code>mu</code> is subtracted from each <code>x</code> value.</td>
</tr>
<tr>
  <td><code>y</code></td>
  <td>ARRAY ref</td>
  <td><code>undef</code></td>
  <td>The second sample. If present and <code>paired</code> is false, a two-sample rank-sum test is run. If <code>paired</code> is true, <code>y</code> is required and must be the same length as <code>x</code>. Omit it for the one-sample signed-rank test.</td>
</tr>
<tr>
  <td><code>paired</code></td>
  <td>boolean</td>
  <td><code>0</code> (false)</td>
  <td>Run a paired signed-rank test on the per-element differences <code>x[i] - y[i] - mu</code>. Requires <code>y</code> of equal length.</td>
</tr>
<tr>
  <td><code>correct</code></td>
  <td>boolean</td>
  <td><code>1</code> (true)</td>
  <td>Apply the continuity correction (±0.5) when using the normal approximation. Ignored when an exact p-value is computed.</td>
</tr>
<tr>
  <td><code>mu</code></td>
  <td>number</td>
  <td><code>0.0</code></td>
  <td>Null-hypothesis location shift. Subtracted from <code>x</code> (two-sample) or from each difference (one-sample / paired).</td>
</tr>
<tr>
  <td><code>exact</code></td>
  <td>boolean / undef</td>
  <td><code>undef</code> (auto)</td>
  <td>Tri-state. <code>undef</code> (or absent) selects exact automatically: when both group sizes are <code>< 50</code> and there are no ties (two-sample), or <code>n < 50</code> with no ties (signed-rank). A true value forces the exact test, a false value forces the approximation. Exact is impossible with ties — or, for the signed-rank test, with zero differences — and falls back to the approximation with a warning.</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>string</td>
  <td><code>"two.sided"</code></td>
  <td>One of <code>"two.sided"</code>, <code>"less"</code>, or <code>"greater"</code>. Selects the tail(s) used for the p-value.</td>
</tr>
</tbody>
</table>

=head3 Output

Returns a hash ref with the following keys:

=for html <table>
<thead>
<tr>
  <th>Key</th>
  <th>Type</th>
  <th>Description</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>statistic</code></td>
  <td>number</td>
  <td>The test statistic. For the two-sample test this is the Mann-Whitney <b>W</b> (the <code>x</code> rank sum minus <code>nx*(nx+1)/2</code>). For the signed-rank test it is <b>V</b>, the sum of the ranks assigned to the positive differences.</td>
</tr>
<tr>
  <td><code>p_value</code></td>
  <td>number</td>
  <td>The p-value for the chosen <code>alternative</code>, capped at <code>1.0</code>. Two-sided p-values are <code>2 * min(p_less, p_greater)</code>.</td>
</tr>
<tr>
  <td><code>method</code></td>
  <td>string</td>
  <td>A human-readable description of the exact test variant that was run (see below).</td>
</tr>
<tr>
  <td><code>alternative</code></td>
  <td>string</td>
  <td>Echoes the <code>alternative</code> actually used (<code>"two.sided"</code>, <code>"less"</code>, or <code>"greater"</code>).</td>
</tr>
</tbody>
</table>

The C<method> string reports which path executed:

=over

=item * Two-sample: C<"Wilcoxon rank sum exact test">, C<"Wilcoxon rank sum test with continuity correction">, or C<"Wilcoxon rank sum test">.

=item * One-sample / paired: C<"Wilcoxon exact signed rank test">, C<"Wilcoxon signed rank test with continuity correction">, or C<"Wilcoxon signed rank test">.

=back

=head3 Notes and edge cases

Missing data is handled by listwise removal of non-numeric / undefined cells before ranking; in the paired case a pair is dropped if either member is missing. An empty C<x> (or, in the two-sample case, an empty C<y>) after this filtering is fatal.

For the signed-rank test, exact zero differences are discarded before ranking (matching R), and their presence disables the exact computation. Both empty-after-filtering and all-zero-difference inputs are fatal.

Ties are detected during ranking and trigger the tie-corrected variance in the normal approximation; they also rule out the exact p-value. When C<exact> is left on auto, the size thresholds (C<< E<lt> 50 >> per group, or C<< E<lt> 50 >> differences) are what gate the exact vs. approximate decision.

=head2 write_table

mimics R's C<write.table>, with data as first argument to subroutine, and output file as second
    write_table(\@data_aoh, $tmp_file, sep => "\t", 'row.names' => 1);
C<write_table> accepts every data-frame shape: a flat hash (one row), a hash of arrays (HoA), a hash of hashes (HoH), an array of hashes (AoH), and an array of arrays (AoA). For an AoA the first inner array is taken as the header row unless C<col.names> is given, in which case every inner array is treated as data:
    write_table([[qw(gene score)], ['TP53', 0.9], ['BRCA1', 0.7]], $tmp_file, 'row.names' => 0);
    write_table([['TP53', 0.9], ['BRCA1', 0.7]], $tmp_file, 'col.names' => [qw(gene score)]);
You can also precisely filter and reorder which columns are written by passing an array reference to C<col.names>:
    write_table(\@data, $tmp_file, sep => "\t", 'col.names' => ['c', 'a']);
undefined variables are printed as C<NA> by default, but can be set as you wish using C<undef.val>
    write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan')
as of version 0.07, C<write_table> determines comma and tab-separated delimiters from the filename, but will override if C<sep> or C<delim> are explicitly set.
Args can also be accepted:
    write_table( 'data' => \%flat, 'file' => $f );

=head3 LaTeX output (C<tex>)

C<write_table> can write the output file as a LaTeX C<tabular> instead of a delimited table. This is selected either by naming the file C<*.tex> (auto-detected) or by passing C<< tex =E<gt> 1 >>; an explicit C<< tex =E<gt> 0 >> forces a delimited file even when the name ends in C<.tex>. The LaTeX table is built from the same rows as the delimited writer, so it works for every shape above (including arrays of arrays):
    write_table(\@data_aoh, 'table.tex');            # .tex name selects LaTeX
    write_table(\@data_aoh, $tmp_file, 'tex' => 1);  # force LaTeX for any name
The file begins with a C<< %written by E<lt>cwdE<gt>/E<lt>scriptE<gt> >> provenance comment (the working directory and script name). The header row is bold and the table is ruled with C<\hline>. Unlike the delimited writer, LaTeX output includes a row-label column as its first column by default: C<row.names> defaults on for LaTeX (matching R's C<write.table>), so pass C<< row.names =E<gt> 0 >> to omit it. The labels are the outer keys for a HoH and a 1-based index otherwise. Cell text is LaTeX-escaped: C<#>, C<_>, C<%>, and C<&> are backslash-escaped, C<< E<gt> >> becomes C<\textgreater{}>, and a cell consisting solely of C<\includesvg{...svg}> is passed through untouched. The C<tex.*> options tune the output:
    write_table(\@rows, 'table.tex',
        'tex.col.align'    => 'l',                   # 'c' (default), 'l', or 'r'
        'tex.bold.1st.col' => 0,                     # default 1: bold the first column
        'tex.format'       => 1,                     # %.4g-format numeric cells
        'tex.size'         => '\small',              # size directive after \begin{tabular}
        'tex.comment'      => ['run 3', 'q < 0.05'], # % comment line(s): string or array ref
    );
For a table that must span page breaks, C<< tex.longtable =E<gt> 1 >> writes only the table I<body> — the bold header row and the data rows, ruled with C<\hline> — but no C<\begin{tabular}>/C<\end{tabular}> and no column spec, so you can C<\input{}> it into a C<longtable> environment you write yourself. Setting C<tex.longtable> implies C<< tex =E<gt> 1 >>, so it applies to any file name (and overrides C<< tex =E<gt> 0 >>). After the provenance comment (and any C<tex.comment> lines) the file emits a C<% \begin{longtable}{...}> hint with one C<tex.col.align> character per column, so you can copy a column spec with the right count. In this mode C<tex.col.align> affects only that hint — the real alignment lives on your own C<\begin{longtable}>; the other C<tex.*> options (C<tex.bold.1st.col>, C<tex.format>, C<tex.size>, C<tex.comment>) still apply:
    write_table(\@rows, 'output.file.tex', 'tex.longtable' => 1);
writes a body-only file such as
    %written by /home/con/Scripts/stats/make_table.pl
    % \begin{longtable}{ccc}
    \hline
    \textbf{a} & \textbf{b} & \textbf{c} \ \hline
    1 & 2 & 3\
    \hline
which you wrap yourself:
    \begin{longtable}{ccc}
    \input{output.file.tex}
    \caption{}
    \label{}
    \end{longtable}

=head3 Excel output (C<xlsx>)

C<write_table> can write a real Excel C<.xlsx> workbook with B<no extra
dependencies> — it is built entirely in XS, packing hand-written XML parts into
an (uncompressed) ZIP, so there is no C<Excel::Writer::XLSX> or other CPAN
requirement. It is selected either by naming the file C<*.xlsx> (auto-detected)
or by passing C<< xlsx =E<gt> 1 >>; an explicit C<< xlsx =E<gt> 0 >> forces a delimited file even
for a C<.xlsx> name. Like LaTeX, it is built from the same rows as the delimited
writer, so it works for every shape above:

 write_table(\@data_aoh, 'table.xlsx');            # .xlsx name selects Excel
 write_table(\%data_hoa, $tmp_file, 'xlsx' => 1);  # force Excel for any name

A numeric-looking cell is written as a number; every other non-empty cell as an
inline string (C<undef>/empty cells are omitted). The result reads straight back
with L<#read_table>.

Mirroring C<Excel::Writer::XLSX>'s
C<< $workbook-E<gt>set_properties(comments =E<gt> comments()) >>, the same
C<< written by E<lt>cwdE<gt>/E<lt>scriptE<gt> >> provenance line the LaTeX writer emits is stored in
the workbook's document B<comments> property (C<dc:description> in
C<docProps/core.xml>); a C<xlsx.comment> string (or array ref of strings) is
appended after it. C<xlsx.sheet> sets the worksheet name (default C<Sheet1>):

 write_table(\@rows, 'report.xlsx',
     'xlsx.sheet'   => 'Results',
     'xlsx.comment' => 'batch 9',
 );

C<xlsx.freeze.rows> and C<xlsx.freeze.cols> freeze that many leading rows/columns in place (Excel's I<freeze panes>), so they stay visible while scrolling — most often used to pin the header row:

 write_table(\@rows, 'report.xlsx', 'xlsx.freeze.rows' => 1);                        # pin the header row
 write_table(\@rows, 'report.xlsx', 'xlsx.freeze.rows' => 1, 'xlsx.freeze.cols' => 2); # pin header + first two columns

C<tex> and C<xlsx> are mutually exclusive. Note: dates/times are written as their
raw values (no cell number formats), matching the round-trip behaviour of
C<read_table>.

=head3 Options

=for html <table>
<thead>
<tr>
  <th>option</th>
  <th>default</th>
  <th>applies to</th>
  <th>meaning</th>
</tr>
</thead>
<tbody>
<tr>
  <td><code>data</code> (1st positional, or <code>data =></code>)</td>
  <td><i>required</i></td>
  <td>both</td>
  <td>the table: flat hash, HoA, HoH, AoH, or AoA</td>
</tr>
<tr>
  <td><code>file</code> (2nd positional, or <code>file =></code>)</td>
  <td><i>required</i></td>
  <td>both</td>
  <td>output path; written as a delimited table, or as LaTeX when <code>tex</code> is on</td>
</tr>
<tr>
  <td><code>sep</code> / <code>delim</code></td>
  <td>from extension (<code>,</code> for <code>.csv</code>, tab for <code>.tsv</code>), else <code>,</code></td>
  <td>delimited</td>
  <td>field separator; the two are aliases</td>
</tr>
<tr>
  <td><code>row.names</code></td>
  <td>LaTeX: <code>1</code> (on); delimited: <code>0</code> (off)</td>
  <td>both</td>
  <td>true prepends a label column (numeric 1-based index, or the outer key for a HoH); <code>0</code> omits it. LaTeX output defaults on (R-compatible); delimited output defaults off; an explicit value overrides in either case. For a HoA/AoH a non-numeric <i>column name</i> uses that column's values as the labels and drops it from the body</td>
</tr>
<tr>
  <td><code>col.names</code></td>
  <td>all columns, sorted</td>
  <td>both</td>
  <td>array ref selecting and ordering columns; for an AoA it also supplies the column names</td>
</tr>
<tr>
  <td><code>undef.val</code></td>
  <td><code>''</code> (empty field)</td>
  <td>both</td>
  <td>text written for an undefined/missing cell, e.g. <code>'NA'</code></td>
</tr>
<tr>
  <td><code>tex</code></td>
  <td>auto: <code>1</code> when <code>file</code> ends in <code>.tex</code>, else <code>0</code></td>
  <td>LaTeX</td>
  <td>write the output file as a LaTeX <code>tabular</code> instead of a delimited table; <code>tex => 0</code> forces delimited even for a <code>.tex</code> name</td>
</tr>
<tr>
  <td><code>tex.col.align</code></td>
  <td><code>'c'</code></td>
  <td>LaTeX</td>
  <td>per-column alignment: <code>'c'</code>, <code>'l'</code>, or <code>'r'</code>; with <code>tex.longtable</code> on it sets only the <code>% \begin{longtable}{...}</code> hint</td>
</tr>
<tr>
  <td><code>tex.bold.1st.col</code></td>
  <td><code>1</code> (on)</td>
  <td>LaTeX</td>
  <td>bold the first column of each data row</td>
</tr>
<tr>
  <td><code>tex.format</code></td>
  <td><code>0</code> (off)</td>
  <td>LaTeX</td>
  <td>render numeric cells with <code>%.4g</code></td>
</tr>
<tr>
  <td><code>tex.size</code></td>
  <td><i>(none)</i></td>
  <td>LaTeX</td>
  <td>size directive emitted after <code>\begin{tabular}</code>, e.g. <code>\small</code></td>
</tr>
<tr>
  <td><code>tex.comment</code></td>
  <td><i>(none)</i></td>
  <td>LaTeX</td>
  <td><code>%</code> comment line(s) at the top of the LaTeX file: a string, or an array ref of strings</td>
</tr>
<tr>
  <td><code>tex.longtable</code></td>
  <td><code>0</code> (off)</td>
  <td>LaTeX</td>
  <td>write only the table body (header + data rows + <code>\hline</code>, no <code>\begin{tabular}</code>/<code>\end{tabular}</code> or column spec) for <code>\input{}</code> into a caller-supplied <code>longtable</code>; implies <code>tex => 1</code>, and emits a <code>% \begin{longtable}{...}</code> hint with one <code>tex.col.align</code> char per column</td>
</tr>
<tr>
  <td><code>xlsx</code></td>
  <td>auto: <code>1</code> when <code>file</code> ends in <code>.xlsx</code>, else <code>0</code></td>
  <td>Excel</td>
  <td>write a real <code>.xlsx</code> workbook (dependency-free, built in XS) instead of a delimited table; <code>xlsx => 0</code> forces delimited even for a <code>.xlsx</code> name. Mutually exclusive with <code>tex</code></td>
</tr>
<tr>
  <td><code>xlsx.sheet</code></td>
  <td><code>'Sheet1'</code></td>
  <td>Excel</td>
  <td>worksheet name</td>
</tr>
<tr>
  <td><code>xlsx.comment</code></td>
  <td><i>(none)</i></td>
  <td>Excel</td>
  <td>extra line(s) appended after the provenance in the workbook's document <i>comments</i> property (<code>dc:description</code>): a string, or an array ref of strings</td>
</tr>
<tr>
  <td><code>xlsx.freeze.rows</code></td>
  <td><code>0</code> (none)</td>
  <td>Excel</td>
  <td>number of leading rows to freeze in place (freeze panes), e.g. <code>1</code> to pin the header row</td>
</tr>
<tr>
  <td><code>xlsx.freeze.cols</code></td>
  <td><code>0</code> (none)</td>
  <td>Excel</td>
  <td>number of leading columns to freeze in place (freeze panes)</td>
</tr>
</tbody>
</table>

=head1 Changes

=head2 0.25 2026-07-19 CDT

https://www.cpantesters.org/cpan/report/3376f80e-83bf-11f1-a5f3-44496e8775ea

Fixed a use-after-free in C<fisher_test> on the hash (HoH) input path: the "row is missing column key" error freed its scratch arrays and then read the key strings back out of them to build the croak message. This was harmless on glibc but crashed (C<SIGBUS>) under stricter allocators such as FreeBSD's, failing C<t/fisher_test.t> on CPAN smokers. The key pointers are now captured before the arrays are freed.

=head2 0.24 2026-07-19 CDT

C<interpolate>'s numeric core moved from pure Perl to XS (C<_interp_column_xs>): ~5× faster for C<linear> on large columns, ~11× for C<pchip>, and ~50× for the spline methods whose dense solve dominates. Results are unchanged (bit-for-bit versus the former Perl kernels).

C<Ronly> now accepts one or more array references (like C<Lonly>), returning the values found only in the B<last> reference; the two-argument form is unchanged, and C<Ronly(@refs)> equals C<Lonly(reverse @refs)>.

C<interpolate> gains full C<pandas.DataFrame.interpolate> method parity: C<nearest>, C<zero>, C<slinear>, C<pad>/C<ffill>, C<bfill>/C<backfill>, C<quadratic>, C<cubic>, C<cubicspline>, C<pchip>, C<akima>, C<barycentric>, C<krogh>, C<polynomial>, C<spline>, and C<index>/C<values>/C<time>, plus an C<x> argument for custom abscissae and an C<order> argument. Matched to pandas/scipy within 1e-6.

C<t/transpose.t> no longer loads C<Devel::Confess> in its leak tests: its C<$SIG{__DIE__}> stack-trace objects landed in C<$@> and were reported as leaks by C<Test::LeakTrace> on the croak paths under older perls (e.g. 5.12.3). The die-path leak checks now also clear C<$@> so the exception object cannot be miscounted.

C<cfilter> simplification, use of C<qr///> filtering on columns

C<summary> output now looks more like C<view>, and accepts HoH

C<fisher_test> can compute larger tables than just 2x2

C<read_table> reads xlsx files significantly faster and with less RAM.

Addition of C<bfill>, C<drop_duplicates>, C<ffill>, C<melt>, and C<pivot_table>

Original C<Lonly> code removed, as it was a special case of C<get_unique>, and C<get_unique> was re-named to C<Lonly>.

Removal of C<Devel::Confess> from testing and dependencies.

=head2 0.23 2026-07-10 CDT

C<rename_cols> takes HoH as input

C<write_table> prints row names as first column; writes longtable with comments

C<assign> gains C<map_cell { ... }> for in-place per-cell column edits

=head3 assign

C<assign> now accepts a third kind of column value, C<map_cell { ... }>, for editing an existing column in place — no "copy, substitute, return" boilerplate and no dependence on C<s///r> (unavailable on the older perls this module supports).

=over

=item * Inside a C<map_cell> block, C<$_> is the B<named column's current cell> (not the whole row), the block's return value is B<ignored>, and the modified C<$_> is stored back: C<< assign($df, 'Res.' =E<gt> map_cell { s/^[A-Z]:// }) >>.

=item * The row is still available as C<$_[0]> (sibling columns), the index as C<$_[1]>, and the row key as C<$_[2]> (HoH only).

=item * B<Undef/missing cells pass through untouched> (undef in → undef out): the block is skipped for them, so C<s///> never warns on an uninitialized value.

=item * Supported on all three shapes; for HoA the target column must already exist. A plain C<sub { ... }> is unchanged, so C<map_cell> is purely additive.

=item * C<map_cell> is exported alongside C<assign>.

=back

Tests: C<assign.t> (AoH + HoA) and C<assign.HoH.t> gained C<map_cell> coverage — in-place C<s///>, C<$_[0]>/C<$_[1]>/C<$_[2]> context, new-column-from-undef, the missing-HoA-column death path, and C<no_leaks_ok> guards. Verified building and passing the full suite on perl 5.10.1, 5.12.5 (long-double), and 5.42.2.

=head3 C<group_by>

Fixed group_by to honor all filter hashrefs (option 1)

Root cause: the XS captured only ST(3), so every filter hashref after the first was silently dropped — including the README's documented multi-hashref form.

Change (LikeR.xs):
- Removed the single-ST(3) capture and the filter_hv PREINIT var.
- Added a FOR_EACH_FILTER(body) macro that walks the arg stack from ST(3) to ST(items-1), iterating every { column => sub } pair and ANDing them together. It iterates the stack directly rather than heap-collecting the hashrefs, so a croaking filter sub still can't leak anything (verified). Non-hashref args are skipped.
- Rewrote the filter loop in all three branches (AoH / HoA / HoH) to use the macro, keeping each branch's own value-fetch logic.

One build wrinkle worth noting: xsubpp parses every non-# line in the inter-XSUB region as a candidate function signature, so a /* ... */ comment there breaks the build (it tried to parse column => sub / (ST(3)..) as a signature). I moved the macro's documentation into the XSUB body (real C) and left the macro comment-free, matching the existing EVAL_FILTER style.

Tests (t/group_by.HoH.filter.t, 17 assertions):
- HoH single-column filter, AND filter (both the one-hashref and separate-hashref forms now give identical results), no-match → empty hash, missing/undef target excluded despite passing the filter, and no_leaks_ok

Mentioning a non-existent column is now fatal.

=head2 0.22 2026-07-07 CDT

returned C<Devel::Confess> to required dependencies to fix for CPAN testers.

=head2 0.21 2026-07-07 CDT

Better warning message for undefined data for C<aoh2hoh>, C<assign>, C<dropna>

addition of C<agg>, C<concat>, C<drop_cols>, C<rank>, C<rename_cols>, C<select_cols> functions

Improving Kwalitee (sic): added C<[PodWeaver]> to dist.ini; as well as C<Changes> file

=head3 C<assign>

C<assign> now accepts two kinds of column value, so a function that already returns a whole column (like C<rank>) drops in without wrapping.

=over

=item * B<Per-row coderef> (unchanged): called once per row, C<$_> is the row, and the single scalar it returns is the cell. A single arrayref return is still stored I<as the cell>, so arrayref-valued columns keep working.

=item * B<Whole-column coderef> (new): if the coderef returns a I<list> of more than one value, that whole list becomes the column, laid down positionally. This is what makes C<< 'ΔG rank' =E<gt> sub { rank( vals($df, 'dG_kcal_mol') ) } >> work directly — no C<[ ... ]> needed.

=item * B<Arrayref value> (new): a ready-made column, e.g. C<< col =E<gt> [ rank(...) ] >>, copied into the frame.

=back

The coderef is probed once (row 0 for AoH/HoH, the first synthesized view for HoA) to decide per-row vs whole-column, so per-row code is never run twice on row 0. Every column value is length-checked against the row count and a mismatch dies. B<HoH> is now a supported, documented shape alongside AoH and HoA; whole-column and arrayref values align to B<sorted key order>.

Tests: C<assign.t> (AoH + HoA) and C<assign_HoH.t> were expanded to cover every shape × value-kind combination — per-row scalar, whole-column list, arrayref value, single-arrayref-as-cell, C<rank()> integration, chaining, C<$_[1]> index, C<$_[2]> row key (HoH), overwrite, ragged HoA columns, empty frames, length-mismatch and bad-value / odd-arg / non-hash-row death paths, and C<no_leaks_ok> guards on the new whole-column and arrayref paths.

=head3 C<read_table>

Fixed handling of commented-out header lines and made filter columns
referenceable by the name as it appears in the file.

=over

=item * B<Commented-out header recovery.> C<_parse_csv_file> treats a line whose
comment marker is followed by whitespace (e.g. C<< # PDBE<lt>TABE<gt>score >>) as a
comment and drops it, so a header written that way never reached the
callback and the first I<data> row was silently mistaken for the header.
C<read_table> now recovers it: the first physical line, if it is
C<marker + whitespace> and splits into two or more fields, is held as a
candidate header and confirmed only when its field count matches the first
data row. If the counts disagree the candidate was an ordinary leading
comment and is discarded, so a prose comment that happens to contain the
separator (e.g. C<# note, see README>) is never mistaken for a header. A
marker hugging its text (C<#id,val>) is delivered by the parser and
un-commented in the callback as before. The marker and any following
whitespace are stripped, so C<# PDB> is stored as the clean name C<PDB>.

=item * B<Filter columns may be named as written in the file.> Filter keys are
matched against the header by exact name first, then retried with the
leading comment marker (and surrounding whitespace) stripped, so a
commented-header column resolves whether it is referenced as C<# PDB> or by
its clean name C<PDB>:

 read_table(
     'regression_rank.tabular.tsv',
     filter => { '# PDB' => sub { $_ == 2 } },
 );

=item * B<Clearer "column not found" error.> The failure now names the file and
lists the actual header instead of printing it to STDOUT (a library
shouldn't print):

 read_table: Filter column 'nope' not found in the header of FILE;
 header is: 'PDB', 'score'

=back

=head2 0.20

addition of C<ncol>, C<nrow>, and C<pnorm> functions

C<filter> can filter by row names with C<$_[1]>

C<view> now accepts array of arrays in addition to AoH, HoA, and HoH

=head3 csort

Two behavioural changes, both contained to the C<csort> XSUB (the C<cs_*> helpers are untouched).

B<Row names survive a Hash-of-Hashes sort.> Sorting a HoH previously discarded the outer keys. Now each row is folded into a I<fresh> row hash (a private container over aliased, read-only cells) that carries its outer key under a C<row.name> column, so the name flows into whichever shape you request:

 my $hoh = { alpha => { id => 1 }, beta => { id => 2 } };
 
 csort($hoh, 'id');          # AoH: each row gains a row.name field
 csort($hoh, 'id', 'hoa');   # HoA: an aligned row.name column

=over

=item * The column name defaults to C<row.name> and can be overridden with an optional 4th argument (mirroring C<hoa2hoh>'s named-key style): C<csort($df, 'id', 'aoh', 'sample')>.

=item * The outer key is authoritative — it wins over any pre-existing same-named field in the row.

=item * Once present, the column is sortable like any other: C<csort($hoh, 'row.name')>.

=item * Because rows are now I<copied> rather than shared, the caller's HoH is never mutated by the injection. (Minor behaviour change: output rows are no longer the same refs as the source rows.)

=back

B<Clearer usage message.> The signature is now C<csort(...)>, so xsubpp no longer emits the misleading auto-generated C<Usage: Stats::LikeR::csort(data, by, output=&PL_sv_undef)>. Argument count is checked by hand, and the croak now shows both real calling forms:

 Usage: csort($df, 'column.name', 'HoA')
    or  csort($df, sub { $b->{'No.'} <=> $a->{'No.'} }, 'hoa')
   (optional 4th arg names the row-name column when sorting a HoH; default 'row.name')

C<data>/C<by>/C<output> are read as C<ST(0..2)>; C<output> still defaults to matching the input shape.

B<Tightened validation messages.> The C<$data> croak now reads C<hash-ref (HoA or HoH)>, and the C<$by> croak includes a concrete example: C<< a column name (e.g. 'No.') or a comparator code-ref using $a and $b, e.g. sub { $b-E<gt>{'No.'} E<lt>=E<gt> $a-E<gt>{'No.'} } >>. Existing HoA croaks (C<unequal lengths>, C<not found>, C<not an array-ref>) are unchanged.

When sorting, undefined values in the sorting column are placed at the bottom

=head3 cor

Fixed an unsigned-integer underflow in C<kendall_tau_b> and added a regression test.

=head4 Bug

In C<kendall_tau_b>, concordant/discordant counts C<C> and C<D> are declared C<size_t> (unsigned). The numerator was computed as:

 return (NV)(C - D) / denom;

The subtraction C<C - D> happens in unsigned arithmetic I<before> the cast to C<NV>. When discordant pairs dominate (C<< D E<gt> C >>), the result wraps to a huge positive value instead of going negative.

For the arrays:

 dG_kcal_mol:  -7.765, -9.328, -10.326, -9.038, -9.608, -9.779, -9.975, -6.906
 anomaly_rank: 154, 155, 161, 188, 76, 172, 173, 69

there are C<C = 9> concordant and C<D = 19> discordant pairs (no ties). C<9 - 19> wraps to C<18446744073709551607>, so the function returned ~C<6.6e17> instead of the correct C<-10/28 = -0.3571428571>.

=head4 Fix

Cast each operand to C<NV> before subtracting, so the arithmetic is signed:

 return ((NV)C - (NV)D) / denom;

Only that one line changed. The denominator sums (C<C + D + tie_x>, C<C + D + tie_y>) are non-negative, so they were left as-is.

=head4 Regression test — C<cor.t>

=over

=item * Kendall on the offending arrays pinned to C<-0.3571428571>.

=item * Explicit C<[-1, 1]> range guard (the real backstop — the pre-fix value C<~6.6e17> blows past the bound regardless of exact magnitude), plus a negative-sign assertion.

=item * Pearson (C<-0.4889102301>), Spearman (C<-0.4761904762>), and default-method coverage of the three C<compute_cor> branches.

=item * Kendall boundary cases: perfectly concordant (C<+1>), perfectly discordant (C<-1>), self-correlation (C<+1>), and a tie case exercising C<tie_x> in the denominator.

=item * C<no_leaks_ok> per method (guarded with C<unless $INC{'Devel/Cover.pm'}>).

=item * Croak paths: length mismatch, unknown method, zero-variance input.

=back

=head3 XS refactor

Consolidate helper functions to reduce binary size, find bugs, and back the changes with tests. Every change was validated by translating the XS (C<ExtUtils::ParseXS>) and compiling the result
with the module's own C<ccflags>.

=head4 Outcome

=over

=item * B<Net change to the source:> ~154 fewer lines; helper-function count down by 4 (7 removed, 3 added).

=item * B<Genuine bugs fixed:> two instances of the same latent defect (see below). The rest of the work was behavior-preserving consolidation.

=back

=head4 Function consolidation

=for html <table>
<thead>
<tr>
  <th>Change</th>
  <th>Before</th>
  <th>After</th>
</tr>
</thead>
<tbody>
<tr>
  <td>Three-way <code>NV</code> comparator</td>
  <td><code>compare_rank</code>, <code>cmp_rank_item</code>, <code>cmp_rank_info</code>, <code>compare_NVs</code></td>
  <td>single <code>cmp_nv3</code> (reads the leading <code>NV</code> member, valid for <code>RankInfo</code>/<code>RankItem</code>/raw <code>NV</code>)</td>
</tr>
<tr>
  <td>Average-rank routine</td>
  <td><code>compute_ranks</code> + <code>compare_index</code> restoration sort</td>
  <td>existing <code>rank_data</code> (scatters ranks into <code>out[idx]</code>, no second sort)</td>
</tr>
<tr>
  <td>String comparator</td>
  <td><code>cmp_string_wt</code>, <code>lm_str_qsort</code> (byte-identical)</td>
  <td>single <code>cmp_string_wt</code></td>
</tr>
<tr>
  <td>Multiplicity filter & set difference</td>
  <td><code>intersection</code> + <code>get_unique</code> (~90% shared); <code>Lonly</code>/<code>Ronly</code> duplicated bodies; a separate <code>set_difference()</code></td>
  <td>one shared <code>set_multiplicity()</code> with an "all vs. one" mode flag and a <code>from_last</code> flag: <code>intersection</code> (all), <code>Lonly</code> (one, first array), <code>Ronly</code> (one, last array)</td>
</tr>
</tbody>
</table>

All merges were confirmed behavior-preserving: the collapsed comparators are
equivalent on ordinary values, C<NaN>, and infinities, and C<compute_ranks> and
C<rank_data> produce identical average ranks.

=head4 Bugs

Two comparators stabilized their sort by returning C<< a-E<gt>idx - b-E<gt>idx >> directly,
where the index field is an unsigned C<size_t>. The subtraction wraps and is then
truncated to C<int>, which is implementation-defined and gives the wrong sign
once a difference exceeds C<INT_MAX>.

=over

=item * C<compare_index> — removed entirely (the routine that used it, C<compute_ranks>, was replaced by C<rank_data>).

=item * C<cmp_pval> — the tie-break comparator in the p-adjust path. B<Missed in the initial review; found later> via a C<-Wconversion> compile of the earlier source. Fixed to compare with the C<< (a E<gt> b) - (a E<lt> b) >> idiom.

=back

B<Caveat on severity:> on every mainstream ABI (LP64, LLP64, ILP32), the
low-word truncation happens to reproduce the correct sign for any array smaller
than ~2^31 elements, so this never produces a wrong result at realistic sizes.
It is a portability/UB issue, not a runtime failure, which is why no functional
test detects it (see "Testing", below).

 C<LikeR.xs> — consolidated helpers; C<compare_index> removed; C<cmp_pval> fixed.

=head3 C<view>

 non-ASCII characters now print

=head3 C<write_table>

new option to output to LaTeX table

=head2 0.19

numerous C<SSize_t var1 = av_len(var) + 1> are changed to C<size_t var1 = av_len(var) + 1> as C<size_t>; as the result cannot be negative, in order to expand numerical range

Addition of C<hoa2hoh>, C<binom_test>, C<chunk>, C<get_union>, C<get_unique>, C<Lonly>, C<Ronly>, C<qcut>, and 3 tukey functions

Better warnings when non-array references are given to C<intersection>

C<view> now breaks columns into chunks for very wide data sets, more closely matching R's behavior

=head2 0.18

C<restrict> keyword added to numerous places within C<intersection> to decrease CPU time

fix to dist.ini for dependencies

fixed POD rendering

=head2 0.17

addition of C<assign>, which adds new columns based on calculations from other columns

addition of C<hoa2aoh>, transforming hash of arrays to array of hashes

addition of C<predict>, using results from C<aov>, C<glm>, and C<lm>

addition of C<aoh2hoh> transforming array of hash into hash of hashes, C<intersection>, C<uniq>, and C<vals>

=head3 C<aov>

=head4 Bug fixes

=over

=item * B<< C<size_t> underflow on empty arrays. >> Three loops were bounded by C<av_len(...)>
compared against an unsigned counter; C<av_len> returns C<-1> for an empty array,
which turned C<< k E<lt>= len >> into a C<SIZE_MAX> loop. The C<stack()> value loop, the C<.>
column-expansion loop, and the C<group_stats> column loop now use a signed
C<SSize_t> bound.

=item * B<HoH row count.> Row count for hash-of-hashes input was taken from the return
value of C<hv_iterinit>; it now uses C<HvUSEDKEYS(hv)> with a separate
C<hv_iterinit>, matching C<predict>.

=item * B<Buffer overflow in interaction parsing.> C<strcpy(right, colon + 1)> into a
fixed C<char right[256]> is now C<snprintf(right, sizeof(right), ...)>.

=back

=head4 Performance / memory

=over

=item * B<< Removed the per-row C<row_x> scratch allocation. >> Design rows are built
directly into C<X_mat[valid_n]>; C<valid_n> simply does not advance on a rejected
row. Interaction columns read their operands from the same in-progress row, so
the logic is unchanged.

=item * B<< C<row_names> is no longer dead. >> Surviving row names are transferred (pointer
move, no copy) into C<surv_names> to key C<fitted.values>; rejected rows are freed
in place.

=item * B<< Dropped a C<restrict> UB. >> C<orig_data_sv> aliases C<data_sv>; the C<restrict>
qualifier was removed.

=back

=head4 New, C<predict>-compatible output keys

=over

=item * B<< C<coefficients> >> — OLS estimates recovered by back-substitution on the R factor
left in C<X_mat> against Q'y in C<Y> (no re-derivation). Keys are the expanded term
names (C<Intercept>, continuous names, C<base.level> dummies, and C<a:b> interaction
products). Aliased columns are reported as C<NaN>, which C<predict> drops.

=item * B<< C<fitted.values> >> — C<Xb> over the non-aliased columns, keyed by surviving row
name. Computed from a snapshot of the design (C<Dsav>) taken before the QR
overwrites C<X_mat>. Costs one transient copy of the design matrix; negligible for
typical ANOVA where the column count is small.

=item * B<< C<xlevels> >> — sorted level list per factor, index 0 = reference, aligned with
the contrast coding used to build the dummies.

=item * B<< C<family> >> — C<"gaussian">.

=back

=head4 Cleanup-path correctness

=over

=item * C<xlevels_hv>, C<Dsav>, and C<surv_names> are freed on both the "0 degrees of
freedom" croak and the normal exit. The interaction-main-effects croak in
PHASE 3 also frees C<xlevels_hv>.

=back

=head4 Known limitations (unchanged)

=over

=item * The intercept-stripping string surgery (C<-1>, C<+0>, C<+1>, ...) operates on the
whole RHS and can still mangle C<I(x-1)>-style transforms; treat C<I()> with
arithmetic constants carefully.

=item * Top-level keys C<coefficients> / C<fitted.values> / C<xlevels> / C<family> /
C<group_stats> share the return hash with the ANOVA rows; a predictor literally
named one of those would collide.

=back

=head3 C<predict>

=head4 New: factor-bearing interaction terms

Previously, interaction coefficients such as C<GroupB:Sexmale> or C<GroupB:x> fell
through to the continuous C<evaluate_term> path and died on a nonexistent column.
They are now handled directly:

=over

=item * B<< C<dummy_hv> >> stores each dummy's factor base index (an C<IV>) instead of
C<&PL_sv_yes>, so a dummy name maps back to its C<(base, level)> in O(1)
(C<level == name + strlen(base)>). C<hv_exists> lookups are unaffected.

=item * During coefficient caching, any C<:> term with at least one factor-dummy component
is routed to a separate list (C<icopy> / C<ibeta>); pure-continuous interactions
(e.g. C<x:z>) stay on the existing C<evaluate_term> path, so prior behavior is
preserved.

=item * Each routed term is parsed once into flat component arrays. Factor components
store a base index and level pointer; continuous components store the term string
and get the same up-front column-existence validation as main terms.

=item * Per row, each factor's raw level is read once into C<raw_lv[]> and reused by both
main effects and interactions (no duplicate C<get_data_string_alloc>). An
interaction's value is the product of its components: a factor component
contributes C<1.0> iff the row's level matches the dummy's level (reference levels
give C<0>), continuous components go through C<evaluate_term>.

=back

This covers factor×factor, factor×continuous, continuous×continuous, and n-way
combinations.

=head4 Other

=over

=item * HoH row count uses C<HvUSEDKEYS> (already present).

=item * The unseen-factor-level croak now frees every level string already read for the
current row, not just the current one.

=back

=head3 Tests

=over

=item * B<< C<aov.t> >> — one-way ANOVA against hand-computed values (Df / Sum Sq / Mean Sq /
F / decomposition); identical results across HoA / HoH / AoH / stacked input;
simple regression; C<.> expansion; intercept removal (C<-1>); two-way with
interaction (Type I SS on a balanced design); NaN listwise deletion; all croak
paths; leak checks.

=item * B<< C<predict.t> >> — C<predict(training) == fitted.values> round-trips for one-way,
regression, factor×factor, factor×continuous, and continuous×continuous models;
explicit predicted values; agreement across HoA / AoH / HoH / flat newdata;
no-newdata path; binomial C<link> vs C<response>; gaussian identity link; all croak
paths; leak checks.

=back

Leak tests use C<no_leaks_ok> guarded by C<unless $INC{'Devel/Cover.pm'}> and skipped
when C<Test::LeakTrace> is absent.

=head4 Assumptions worth confirming

=over

=item * The NaN-deletion test relies on C<evaluate_term> returning C<NaN> for a non-finite
response value (an C<Inf - Inf> NaN is fed in deterministically).

=item * The continuous×continuous round-trip relies on C<evaluate_term("x:z")> yielding
C<x * z> — the same assumption the pre-existing C<predict> continuous-interaction
path already made. If that path was untested, this round-trip now exercises it.

=back

=head3 C<view>

now returns colored output; fixed bug with incorrect widths; undefined values show as C<undef> rather than C<NA>, as in Data::Printer

=head3 C<csort>

now accepts Hash of Hashes; addition of C<restrict> which should decrease calculation time

=head3 filter

=over

=item * B<Added hash-of-hashes (HoH) input.> In addition to AoH and HoA, C<filter> now accepts an HoH (C<< { key =E<gt> { col =E<gt> val, ... }, ... } >>); each inner hash is one row, and matching keys are preserved by default (HoH -> HoH).

=item * B<< Added C<output.type>. >> C<< filter($df, $pred, 'output.type' =E<gt> 'aoh'|'hoa') >> selects the returned shape (aliases C<out> / C<output_type>; a bare positional type also works). When omitted, the input shape is preserved. C<hoh> is not a selectable output, since it would require choosing a key column.

=item * B<< C<col()> reworked, not removed. >> Both predicate forms are kept: C<< col('age') E<gt>= 18 >> still works and is the concise/composable option, while a coderef covers everything else. Internally C<col()> is now B<pure Perl> — an overloaded class that builds a per-row closure — and C<filter> unwraps that closure so C<col()> and a coderef share one evaluation path. The previous standalone XS predicate evaluator (C<filt_eval>/C<filt_ctx>) is gone; delete it if your tree still has it. One consequence: a C<col()> comparison now costs the same per row as the equivalent coderef (a Perl call), rather than being evaluated in C.

=item * B<Unchanged guarantees:> the input frame is never modified; C<undef> (and, for numeric ops, non-numeric) cells never match a C<col()> comparison; AoH/HoH rows are shared rather than copied where possible; keep-all/keep-none shapes are well defined per output type; Perl 5.10 compatibility is retained. A latent C<SvTRUE(POPs)> double-evaluation in the per-row call helper (which crashed on perls where C<SvTRUE> is a multi-eval macro) was fixed along the way.

=back

=head3 read_table

Added an opt-in C<auto.row.names> argument so C<read_table> can read the file R
produces by default from C<write.table(x, sep="\t")>.

=head4 The problem

R's C<write.table> defaults to C<row.names=TRUE, col.names=TRUE>, which writes the
row-names column in every data row but emits B<no header label for it>. So a
frame with N columns comes out as N header fields over N+1 data fields — e.g.
C<mtcars> gives 11 headers but 12-field rows. By default C<read_table> (correctly)
rejects that as ragged:

 Alignment error on mtcars.tsv data row 1 (12 fields vs 11 headers).

=head4 The change

C<auto.row.names> turns on R's own C<read.table> rule: B<when, and only when, the
header is exactly one field short of the data rows, treat the first field of
each row as an (unlabelled) row-names column.>

 # default: the leading column is named 'row_name'
 my $df = read_table('mtcars.tsv', 'auto.row.names' => 1);
 
 # or give it a name
 my $df = read_table('mtcars.tsv', 'auto.row.names' => 'model');

The synthesized column behaves like any other first column: it appears in C<aoh>
and C<hoa> output, and for C<hoh> it becomes the default key (so rows are keyed by
the model name). This also lines up with the existing handling of R's
C<col.names=NA> output (a blank leading header), which still produces a
C<row_name> column with no flag needed.

=head4 What did not change

The strict alignment check is still the default. Without C<auto.row.names> the
lopsided file still croaks, and even with it, a row that is off by anything
other than exactly one field still croaks — so the corruption guard only relaxes
for the one case R itself treats specially.

Tested in C<t/read_table.2.t> (16 assertions, Perl 5.10.1 and 5.38): aoh / hoa /
hoh output, custom column name, the already-aligned file (flag is a no-op), the
C<col.names=NA> path, and the strict / ragged croak paths.

=head4 additional bugfix

 # This is a comment
 id,name,val
 1,Alice,10.5
 2,Bob,
 3,Charlie,15.2

would not be read correctly using C<read_table>, but now is read correctly

=head3 value_counts

now accepts array of hashes

=head2 0.16

changes to dist.ini, the minimum Perl version disappeared when I fixed other problems

clarifications between run time and test dependencies

addition of C<csort> function to sort AoH and HoA

addition of C<aoh2hoa> to translate array of hashes into a hash of arrays

fix of long double functions: https://www.cpantesters.org/cpan/report/5d5d9836-6a5f-11f1-aadb-63fd6d8775ea

=head3 C<glm>

output residual keys now use names, not integers

=head3 C<lm>

=head3 Bug fixes

B<Memory leak on the zero-degrees-of-freedom error path.> When
C<< valid_n E<lt>= p >>, the cleanup freed the C<valid_row_names> I<array> but not the
per-row name strings it held (those had been transferred out of C<row_names>,
whose own array was already freed). The strings leaked on every such error.
Added the per-entry C<Safefree> loop before freeing the array, matching the
normal path.

B<HoH input validated only the first row.> Only the first hash value was
checked to be a C<HASHREF>; subsequent values were C<SvRV>'d unconditionally, so
a malformed row (C<< { a =E<gt> {...}, b =E<gt> 5 } >>) dereferenced a non-reference. Every
row is now validated, with the partial allocations cleaned up before the
C<croak>, mirroring the existing AoH path.

B<< C<isspace> on a possibly-signed C<char>. >> C<isspace(*src)> is undefined for
byte values ≥ 0x80 on platforms where C<char> is signed. Cast to
C<(unsigned char)> before the call.

=head3 Speed / RAM improvements

B<Formula buffer is now heap-allocated to fit.> C<char f_cpy[512]> silently
truncated any longer formula. Replaced with a buffer sized to
C<strlen(formula) + 1>, so there is no fixed limit and no truncation.

B<< C<.>-expansion buffer is now a growable heap buffer. >> C<char rhs_expanded[2048]>
silently dropped expanded terms once full. It is now a buffer that doubles on
demand. Appends also went from C<strcat> (which rescans from the start every
time — O(n²) over many columns) to an O(1) amortised append that tracks the
write position.

B<No more per-row scratch allocation in matrix construction.> The original
C<safemalloc>'d a C<row_x> buffer, filled it, copied it into C<X>, and freed it
I<for every row> — C<n> allocations plus C<n*p> copies. Each candidate row is now
written straight into C<X> at its prospective commit slot; a row that fails
listwise deletion is simply overwritten by the next candidate. This removes the
C<n> allocate/free cycles and the copy loop entirely.

B<< Categorical levels sorted with C<qsort>. >> The level list used an O(n²) bubble
sort; replaced with C<qsort> (relevant only for high-cardinality factors).

B<< Unused tail of C<X> reclaimed after listwise deletion. >> C<X> is allocated for
all C<n> rows up front (C<valid_n> is unknown until rows are scanned). When rows
are dropped, C<X> is now C<Renew>ed down to C<valid_n * p>, returning the unused
tail to the allocator before the OLS phase.

B<Minor robustness.> The argument-parsing index was widened from
C<unsigned short> to C<I32> to match C<items>, and the HoH row count now uses
C<HvUSEDKEYS> rather than relying on C<hv_iterinit>'s return value.

=head3 Known limitations (left unchanged)

=over

=item * A multi-way term such as C<a*b*c> is split only on the first C<*>, so it yields
C<a>, C<b*c>, and C<a:b*c> rather than a full three-way expansion. Deeper
interactions silently fail (the unparsable term evaluates to C<NaN> and the
rows are dropped). This matches the documented two-way C<*> support.

=item * HoA input takes the row count from the first column; columns shorter than
that simply contribute dropped rows rather than raising an error.

=back

=head3 C<oneway_test>

=head4 Bug fixes

B<Memory leaks on error paths.> Nearly every C<croak> after an allocation
leaked memory. C<croak> does a C<longjmp>, so anything allocated but not yet
freed is lost. Affected paths:

=over

=item * AoA and hash first-pass errors leaked C<sizes> and any C<gnames[]> entries
allocated so far.

=item * Formula-mode "not found as an array ref" errors leaked C<lhs> and C<rhs>.

=back

All post-allocation errors now route through a single C<fail:> label that frees
every pointer unconditionally. Pointers are initialised to C<NULL> and C<gnames>
is zero-allocated with C<Newxz>, so the cleanup is always safe to run.

B<< Undefined and non-numeric cells silently coerced to C<0.0>. >> The original
second pass used C<(svp && *svp) ? SvNV(*svp) : 0.0>, meaning an C<undef> or
non-numeric cell was quietly treated as zero, silently corrupting the
F-statistic. Each cell is now validated with C<SvOK> and C<looks_like_number>;
the call dies naming the group and observation index, consistent with the rest
of C<Stats::LikeR> (C<mean>, C<sum>, C<cor>, etc.).

B<Unsigned wraparound on empty array input.> C<k = (size_t)av_len(in_av) + 1>
cast to C<size_t> I<before> adding, so an empty array (C<av_len> returns C<-1>)
produced C<SIZE_MAX> rather than C<0>. Changed to
C<k = (size_t)(av_len(in_av) + 1)> so the C<+1> is done in signed arithmetic
before the cast.

B<< Unreliable group count from C<hv_iterinit>. >> C<hv_iterinit> returns the
number of buckets in use rather than the number of keys for tied hashes.
Replaced with C<HvUSEDKEYS>, which always returns the correct key count.

=head4 Improvements

B<< C<var.equal> accepted as an alias for C<var_equal>. >> R users write
C<var.equal>; the argument parser now accepts both spellings.

B<Perl memory API used throughout.> C<safemalloc> and manual C<memcpy> replaced
with C<Newx>, C<Newxz>, C<savepv>, and C<savepvn>. C<savepvn> additionally
preserves embedded NUL bytes in group key strings, which the previous
C<strlen>-based copies silently truncated.

=head4 Known limitations (not changed)

=over

=item * A factor column named C<Residuals> or C<group_stats> in a formula call will
collide with reserved top-level keys in the result hash.

=item * Group names containing an embedded NUL are stored correctly but are still
truncated at C<strlen> when written into the output hash keys.

=back

=head3 C<view>

default view shifted to 80 characters to match Linux window length

=head4 New features

=over

=item * B<< C<rows> is accepted as a synonym for C<n> >> (the number of rows shown).
Passing both C<n> and C<rows> is an error.

=item * B<Unknown arguments are now rejected.> C<view> validates its argument names
against the documented set (C<n>, C<rows>, C<na>, C<max_width>, C<ellipsis>,
C<gap>, C<cols>, C<columns>, C<to>, C<return_only>, C<row.names>, C<row_names>) and
dies listing any it does not recognise, so a misspelt option (e.g. C<widht>)
is caught instead of silently ignored.

=item * B<< C<n> / C<rows> is validated. >> It must be a non-negative integer; C<undef> or
a non-numeric value now dies with a clear message instead of producing
warnings and being treated as C<0>.

=item * B<flat/simple hashes are accepted as input>

=back

=head4 Bug fixes

=over

=item * B<< C<< n =E<gt> 0 >> now still prints the column header. >> Column names were collected
only from the rows being shown, so requesting zero rows produced an empty
header line. At least one row is now scanned (when data exists) so the
header always lists the columns.

=item * B<< An empty hash (C<{}>) no longer dies. >> It was rejected as
I<"neither ARRAY nor HASH">; it is now shown as an empty table
(C<0 rows x 0 cols>), matching the handling of an empty array.

=item * B<< The C<row_names> alias now drives the Hash-of-Hashes label header. >> The
header for the row-label column consulted only C<row.names>, so
C<< row_names =E<gt> 'id' >> displayed C<row_name> instead of C<id>. Both spellings are
now honoured consistently.

=item * B<Malformed nested values degrade gracefully.> A Hash-of-Arrays column or
Hash-of-Hashes row whose value is not actually an array/hash reference now
renders as empty cells rather than throwing a dereference error.

=back

=head4 Performance

=over

=item * Column gathering no longer sorts once per scanned row. Unique column names
are collected across the scanned rows and sorted a single time (same output
order), and the ellipsis length is computed once rather than per cell.

=back

=head4 Tests

=over

=item * C<t/view.t> is self-contained (the C<view> implementation is inlined; it loads
no other files) and covers the new argument handling, the bug fixes above,
and the existing AoH / HoA / HoH behaviour, alignment, truncation, and
output-path handling.

=back

=head3 C<wilcox_test>

Corrected four bugs in the C<wilcox_test> XSUB plus a portability fix in its exact signed-rank helper. Behaviour on valid input is unchanged: the R-agreement cases (unpaired C<W = 58>, C<p = 0.13292>; paired one-sided C<V = 40>, C<p = 0.019531>; separated exact C<W = 0>, C<p = 0.028571>) all still match R's C<wilcox.test>.

=head4 Bug fixes

=over

=item * B<< Invalid C<alternative> is now rejected. >> Any value other than C<less> or C<greater> previously fell through to the two-sided branch and returned a two-sided result mislabelled with the bad string, so a typo like C<< alternative =E<gt> "twosided" >> silently "worked". It now croaks unless C<alternative> is one of C<two.sided>, C<less>, C<greater>.

=item * B<Zero/negative variance is guarded.> When every observation is tied the approximation's variance collapses to 0 and the old code divided by C<sqrt(0)>: C<wilcox_test([5,5,5], [5,5,5])> returned C<p = 0> (a "significant" difference between identical samples). It now warns and returns C<p = 1>.

=item * B<< Two-sided continuity correction at C<z = 0>. >> R uses C<sign(z) * 0.5>, so the correction is C<0> when the statistic sits exactly on its mean; the old code used C<-0.5>. Example: C<< wilcox_test([1,4], [2,3], exact =E<gt> 0) >> changed from C<p = 0.698535> to C<p = 1> (matches R).

=item * B<< C<exp> no longer shadows libm. >> The local C<exp> accumulator (mean of the statistic) shadowed the C library C<exp()>; renamed to C<mean_w> (two-sample) and C<mean_v> (signed-rank). No active miscompute, removed as a latent hazard.

=back

=head4 Cosmetic

=over

=item * Collapsed a no-op ternary that assigned the same signed-rank exact method string on both branches; the C<method> field is now simply C<Wilcoxon signed rank exact test>.

=back

=head4 Portability (exact signed-rank helper)

=over

=item * B<< C<exact_psignrank> no longer calls C<powl()>. >> The C<2^n> normaliser is now built by exact repeated doubling, which has no long-double libm dependency. This fixes an C<Undefined symbol "powl"> load failure reported by a CPAN smoker (FreeBSD, perl 5.20, C<nvtype=double>) whose libm lacks the long-double math functions; the symbol resolved on glibc, which is why local builds passed. C<long double> accumulation in the DP is retained — only the C<powl> call was at fault.

=item * B<< C<int> → C<size_t> >> for C<n>, C<max_v>, and the DP loop counters, which also removes a C<size_t>-to-C<int> narrowing at the call site. The C<floor()> result (C<k>) stays signed so its negative-C<q> sentinel still fires, and is cast to C<size_t> only after the C<< k E<lt> 0 >> check.

=back

=head4 Tests

=over

=item * Added C<t/wilcox_test.t> (flat, no subtests): R-agreement cases, option handling (C<paired>, C<correct>, C<exact>, C<mu>, named/positional C<x>/C<y>, NA dropping), regressions for all four bug fixes, argument-error and C<alternative>-validation checks, output shape, and C<no_leaks_ok> coverage of the two-sample, exact, and paired allocation paths.

=back

=head2 0.15

C<view> function added, similar to R's C<head>

C<read_table>:
    filter => {
        'Testosterone, total (nmol/L)' => sub { defined $_ },
    }

was broken by the change in undefined variables in 0.14, but is back to being C<undef>

C<col2col> improvement in sectioning in README

Numerous changes to prevent quadmath/long double CPAN test failures

Minimum Scalar::Util version in dist.ini is now 1.22, see https://www.cpantesters.org/cpan/report/6b682236-6567-11f1-a3bc-a055f9c4ba34

C<Digest::SHA> is no longer needed, and removed as a dependency

=head3 C<read_table>

=head4 Bug fixes

=over

=item * B<A comment-prefixed header is now read correctly.> C<read_table> strips a
leading comment marker from the header line (so a file may begin with
C<#id,val>), but that strip was dead code: the XS parser skipped I<every> line
beginning with the comment string before the callback ever saw it, so a
commented header was silently dropped and the first data row was mistaken for
the header. The parser now delivers the first content line even when it
begins with the comment marker, and only skips comment lines after the header
has been seen.

=item * B<Carriage returns inside quoted fields are preserved.> The parser stripped
C<\r> unconditionally, so a quoted value such as C<"x\ry"> lost its carriage
return and would not survive a C<write_table> -> C<read_table> round-trip. C<\r>
is now stripped only as part of a trailing CRLF line ending and as a stray CR
I<outside> quotes; inside quotes it is literal data.

=item * B<< Duplicate column names no longer corrupt C<hoa> output. >> With
C<< output.type =E<gt> 'hoa' >>, a repeated column name pushed the same cell once per
occurrence, so the affected columns came out longer than the others and the
arrays no longer lined up by row. Columns are now keyed by unique header name
(first-seen order preserved, later values win, one warning emitted).

=item * B<A defined non-CODE callback is now an error.> Passing a defined argument
that was not a CODE reference silently fell through to slurp mode and ignored
the argument; it now croaks
(I<"callback must be a CODE reference">).

=item * B<< An undefined/empty C<hoh> row-name now dies instead of keying on C<"">. >>
With C<< output.type =E<gt> 'hoh' >>, a row whose row-name column was empty/undef was
stored under the C<''> key and raised I<"uninitialized value"> warnings. It now
dies, naming the column and the offending data row.

=item * B<A numeric filter key past the last column now dies.> A 1-based numeric
filter key greater than the column count was accepted, then silently extended
every row through the C<$_> write-back. It is now rejected up front with a
message naming the column count.

=item * B<< C<sep> and C<delim> together now die. >> Supplying both silently preferred
C<delim>; passing both is now an explicit error (C<delim> remains an alias for
C<sep> when used alone).

=item * B<The library no longer prints to STDOUT.> The unknown-argument path used
C<say> to dump the offending names to STDOUT before dying; the names are now
carried in the C<die> message itself.

=back

=head4 Better diagnostics

=over

=item * Alignment errors now report B<which data row> is ragged
(I<"Alignment error on FILE data row N (X fields vs Y headers)">), instead of
only the field/header counts.

=back

=head4 Memory-leak fixes (exception paths)

The parser allocated its working buffers (C<current_row>, C<field>, and — in
slurp mode — C<data>) in the XS C<INIT:> block, i.e. I<before> any validation, and
freed them only by falling off the end of the function. Any non-local exit
therefore leaked:

=over

=item * the open-failure C<croak> leaked the row buffer and field (and the slurp
accumulator);

=item * far more commonly, a C<die> thrown B<inside the row callback> — which
C<read_table> does routinely on alignment errors, bad row names, and filter
exceptions — unwound straight out of the XS frame and leaked the field, the
current row, the line buffer, the slurp accumulator, I<and the open file
handle>.

=back

Allocations now happen in C<CODE:> after every croak-able check, and every
long-lived resource (the file handle via C<SAVEDESTRUCTOR_X>, the buffers via
C<SAVEFREESV>) is tied to the save stack, which an exception unwinds. Measured
with C<Test::LeakTrace>: a C<die> mid-file went from 5 leaked SVs to 0, and an
open failure from 2 to 0. This is the likely source of the constant-size leaks
seen in CPAN-tester reports for the exception-path tests.

=head4 Performance

=over

=item * B<~2.5x faster parsing> (57 -> 145 MB/s on a 100k-row quoted file). The core
loop appended one character at a time with C<sv_catpvn(field, &ch, 1)>; it now
scans runs of ordinary bytes with C<memchr> / a bounded scan and appends each
run in a single C<sv_catpvn>, copying field contents in bulk rather than byte
by byte.

=back

=head4 Internal / non-behavioral

=over

=item * XS declarations moved from C<INIT:> to C<PREINIT:>; allocations deferred into
C<CODE:> (see the leak fixes above).

=item * The filter loop now aliases the row hash with C<local *_ = \%line_hash>
instead of copying it with C<local %_ = %line_hash>. This removes a full
per-row hash copy for every filtered row and fixes a latent staleness bug:
after a filter mutated C<$_> and the change was written back, C<%_> still
reflected the pre-mutation copy, so a subsequent filter in the same row saw
stale values. With aliasing, C<%_> I<is> the row, so write-backs are always
visible.

=back

=head4 Known limitation (not changed)

=over

=item * B<< C<undef.val> does not round-trip back to C<undef>. >> C<write_table> renders an
C<undef> cell as an empty field by default, and C<read_table> maps an empty
field back to C<undef>, so the I<default> round-trip is clean. But if a file is
written with a token such as C<< 'undef.val' =E<gt> 'NA' >>, C<read_table> has no
inverse option and reads C<NA> back as the string C<'NA'>. C<read_table> also
cannot distinguish a deliberately quoted empty string (C<"">) from a missing
value -- both become C<undef>. Adding an C<na.strings>-style option to
C<read_table> (mapping configurable tokens and/or empty fields to C<undef>)
would close this gap.

=back

=head3 C<write_table>

=head4 Behavior change

=over

=item * B<< C<undef> cells now write as an empty field, not an empty string. >> A missing
or C<undef> value renders as nothing between separators (C<a,,c>) rather than a
quoted empty string (C<a,'',c> / C<a,"",c>). Supplying C<< 'undef.val' =E<gt> 'NA' >>
(or any other token) still overrides this, exactly as before. This is the
only change that can alter the bytes of an existing output file; if you relied
on the previous default, pass C<< 'undef.val' =E<gt> '' >> to keep an explicit empty
field, or your chosen placeholder.

=back

=head4 Bug fixes

=over

=item * B<Wide-character / UTF-8 column names and row keys now round-trip.>
Previously, cells were looked up with the raw bytes of the column name
(C<hv_fetch(..., SvPV_nolen(name), strlen(name), ...)>), which fails to match a
UTF-8-flagged hash key: the column header printed correctly but every cell
under it came back empty. All lookups now fetch by SV (C<hv_fetch_ent>), header
lists are gathered and sorted as SVs (C<sortsv> + C<sv_cmp>, preserving the
flag) instead of being round-tripped through C<char *>, and the C<row.names>
column is matched with C<sv_eq> rather than C<strcmp>. Embedded NUL bytes in
keys are handled correctly as a side effect.

=item * B<< C<< col.names =E<gt> [] >> no longer loops forever. >> An empty C<col.names> array made
C<av_len()> return C<-1>, which — compared against an unsigned C<size_t> loop
index — wrapped to C<SIZE_MAX> and ran effectively without end. This was fixed
for flat hashes previously; it was still present for hash-of-hashes,
hash-of-arrays, and array-of-hashes, plus both C<row.names> header-filtering
loops. All such loops now use a signed index.

=item * B<Tables wider than 65,535 columns no longer hang.> One header loop used an
C<unsigned short> index that silently wrapped past 65,535 and never terminated.
It now uses C<size_t> like the rest of the code.

=item * B<Flat-hash cells holding a reference now croak.> Every other input shape
rejects a nested reference with
I<"Cannot write nested reference types to table">; a flat hash instead
stringified it (e.g. C<ARRAY(0x55...)>) into the file. It now croaks
consistently.

=item * B<< C<< 'undef.val' =E<gt> undef >> is handled cleanly. >> It previously called
C<SvPV_nolen> on C<undef>, raising an I<"uninitialized value"> warning and
yielding an empty string by accident. It is now treated explicitly as an empty
field, with no warning.

=back

=head4 Memory-leak fixes (exception paths)

=over

=item * The row-key list gathered for hash-of-hashes input was leaked when the output
file could not be opened.

=item * The I<"Could not get headers"> croak on hash-of-arrays input leaked both the
already-open filehandle and the headers array.

=back

=head4 Internal / non-behavioral

=over

=item * Numeric row labels are now formatted into a reused stack buffer instead of a
per-row C<savepv()> / C<safefree()> allocation (no functional change; removes a
cast-away-C<const> and one allocation per row).

=item * Several signed/unsigned index types were made consistent (C<SSize_t> vs
C<size_t>) to match C<av_len()> and silence the conditions behind the loop bugs
above.

=back

=head4 Tests

=over

=item * C<t/write_table.t> expanded from 17 to 69 assertions. New coverage targets each
fix above: the empty-field default and C<< undef.val =E<gt> undef >> (no warning),
C<< col.names =E<gt> [] >> termination across all four input shapes, the
 >65,535-column header loop (gated behind C<EXTENDED_TESTING=1>), in-sequence
numeric row labels, nested-reference rejection, CSV quoting corners
(carriage return, separators inside column names, multi-character separators),
empty input writing no file, and UTF-8 column names and row keys. Two leak
assertions cover the exception paths above.

=back

=head2 0.14

C<filter> function added for rows

C<read_table> reads undefined values to C<undef> instead of C<NA>, which makes calculations easier

C<write_table> writes undef by default as an empty string C<''>

C<hoh2hoa> transforms a hash of hashes into an hash of arrays

C<quantile> uses C<NV> instead of C<double> to allow for high-precision 128-bit floats to be used on quadmath machines when available: https://www.cpantesters.org/cpan/report/296f4868-631f-11f1-abba-ff15558d240b

Numerous switches from C<double> to C<NV> for local precision, like above

numerous changes to C<col2col> for ease of use and working with datasets with numerous undefined values

dist.ini now links to math library when compiling: https://www.cpantesters.org/cpan/report/785e26d8-6397-11f1-89c0-dc066e8775ea

C<fisher_test> now should be complete, errors with confidence intervals fixed

=head2 0.13

C<read_table>: speed improvements; commented headers are now allowed

C<write_table>: fix for 

 Attempt to free temp prematurely: SV 0x56417a2ae610 at t/write_table.t line 182.
     main::wrote_ok(",age\x{a}Alice,30\x{a}Bob,25\x{a}", "row.names => 'name' uses that column as labels", HASH(0x56417a272250), "row.names", "name") called at t/write_table.t line 203
 Attempt to free unreferenced scalar: SV 0x56417a2ae610 at t/write_table.t line 183.
     main::wrote_ok(",age\x{a}Alice,30\x{a}Bob,25\x{a}", "row.names => 'name' uses that column as labels", HASH(0x56417a272250), "row.names", "name") called at t/write_table.t line 203

C<write_table> gives better warnings for incorrect types of data given

Numerous changes to dist.ini to improve CPAN testing, especially for Win32

=head2 0.12

C<add_data> can also take hash of arrays, and various mixes of data types

C<ljoin>: Addition of C<restrict> keywords in many places; should improve CPU performance

Better POD formatting, correction of output hash for README's C<add_data>

C<chisq_test> can now accept hash of hashes as input

new C<transpose> function for switching 2D hash keys and 2D array indices, and C<col2col> for comparing columns against columns

removed unused function from C helpers

C<value_counts>: addition of restrict keywords in preinit, should improve CPU performance

MANIFEST.skip changed to MANIFEST.SKIP to improve CPAN testing

using C<is_deeply> for tests of C<transpose>, which may or may not work with CPAN testers (experimental)

Added function name to warnings, so I actually know which function is producing the error

C<write_table> can also take C<file> and C<data> as args, in addition to positions

fixed C<write_table> as it could hang if given empty C<col.names> or C<row.names>

Added C<__EXTENSIONS__> to source XS file for better CPAN testing

=head2 0.11

better POD formatting for tables

addition of MANIFEST.skip to get better testing results on CPAN

C<glm>: bugfix for when there is no intercept in the formula, new test cases in t/glm.t

C<write_table> now accepts simple hashes as input, in addition to hash of arrays, hash of hashes, and arrays of hashes

Better documentation for t-test

=head2 0.10

changes to compilation for CPAN, trying to get this work on Windows

Addition of C<prcomp> and C<value_counts>

C<matrix> will work without key names, just like in R.  Testing for C<matrix> has improved.

=head2 0.09

context changes in XS C<dTHX>, C<pTHX_>, and C<aTHX_> to get better CPAN testing results

C<restrict> keywords added to C<lm> to increase speed

=head2 0.08

Speed improvement in C<summary> of hashes.

Addition of C<add_data>, C<dnorm>, C<group_by>, C<ljoin>, and C<mode> functions

Chi-squared function no longer has Perl wrapper, and all code is in XS, which should result in a minor speed increase with 1 less function call.

Compiler changes for GNU source and inclusion of C<strings.h>, to ensure more CPAN testing works better.

C<read_table> now returns hash-of-hash in {row}{column}

=head2 0.07

Addition of C<summary> function.

Formulas can now be omitted from C<aov>, resulting in a stacked calculation as R would think.

Addition of C<oneway_test> for multi-group comparisons that does not assume normality like C<aov> does.

C<read_table> and C<write_table> now automatically set separators for C<.csv> files as C<,> and C<.tsv> files as C<"\t">, respectively, so these values no longer need to be specified separately from the file name.

=head2 0.06

Changed compiler options so that Solaris will work

signed integers changed to unsigned in C<glm>

Added restrict keywords to C<power_t_test>, and made C<int> to C<unsigned int>

=head2 0.05

Leak testing for C<sample>

removal of Data::Printer dependency for easier CPAN testing

switched several C<unsigned int> variable to C<I32> so that clang doesn't complain

added restrict keyword for C<sample>

=head2 0.04 2026-5-17 CDT

addition of C<sample> function

GNU source, to maximize compatibility and ease installation

removal of JSON dependency to ease installation

=head2 0.03 2026-5-13 CDT

Compatibility back to Perl 5.10

=head2 0.02 2026-5-7 CDT

back-compatible to Perl 5.10, instead of original 5.40, ensuring more people can use it

added var_test

mean, min, sum, median, var, and max die with undefined values, and print the offending indices

"group_stats" added to aov, for TukeyHSD in the future

"cor" dies when given data with standard deviation of 0

C<write_table> now has C<undef.val> option, which shows how undefined values are printed to tables, which is C<NA> by default.

=head1 COPYRIGHT AND LICENSE

This software is free.  It is licensed under the same terms as Perl itself

=head1 AUTHOR

David E. Condon <dec986@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026-present by David E. Condon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
