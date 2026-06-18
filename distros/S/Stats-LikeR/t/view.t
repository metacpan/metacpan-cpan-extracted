use strict;
use warnings;
use Test::More;
use Scalar::Util qw(looks_like_number);

# ---------------------------------------------------------------------------
# view() is inlined here so this test is self-contained (no external files).
# Keep it in sync with the copy shipped in the module.
# ---------------------------------------------------------------------------
sub view {
	my $data = shift;
	my %args = @_;

	# --- reject unknown arguments (mirrors read_table/write_table) ---
	my %allowed = map { $_ => 1 } qw(
		n rows na max_width ellipsis gap cols columns
		to return_only row.names row_names
	);
	my @bad = sort grep { !$allowed{$_} } keys %args;
	die "view: unknown argument(s): @bad\n" if @bad;

	# --- n / rows (synonyms); reject conflicting or non-integer values ---
	die "view: pass either 'n' or 'rows', not both\n"
		if exists $args{n} && exists $args{rows};
	my $n = exists $args{rows} ? $args{rows}
		  : exists $args{n}    ? $args{n}
		  :                       6;
	die "view: 'n'/'rows' must be a non-negative integer\n"
		unless defined $n && $n =~ /^\d+$/;

	my $na    = exists $args{na}        ? $args{na}        : 'NA';
	my $maxw  = exists $args{max_width} ? $args{max_width} : 80;
	my $ell   = exists $args{ellipsis}  ? $args{ellipsis}  : '...';
	my $gap   = exists $args{gap}       ? (' ' x $args{gap}) : '  ';
	my $ucols = $args{cols} || $args{columns};
	my $fh    = $args{to};
	my $quiet = $args{return_only};

	# 'row.names' takes precedence over the row_names alias (both accepted)
	my $label_col = exists $args{'row.names'} ? $args{'row.names'}
		          : exists $args{row_names}   ? $args{row_names}
		          : undef;

	my $rt = ref $data;
	die "view: expected an ARRAY (AoH) or HASH (HoA/HoH) reference, got "
	  . ($rt || 'a non-reference') . "\n"
	  unless $rt eq 'ARRAY' or $rt eq 'HASH';

	my ($kind, @cols, @labels, @raw, $total, $lab_header);
	if ($rt eq 'ARRAY') { # ---- AoH ----
		$kind  = 'AoH';
		$total = scalar @$data;
		my $show = $n < $total ? $n : $total;

		if ($ucols) {
			@cols = @$ucols;
		} else {
			# BUG FIX: scan at least one row when data exists, so the header
			# still lists columns even when showing 0 rows (n => 0). PERF:
			# collect unique keys once, then sort once -- not sort-per-row.
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
			push @labels, defined $lc ? $row->{$lc} : ($i + 1);
			push @raw, [ map { $row->{$_} } @cols ];
		}
		$lab_header = '' unless defined $lab_header;
	} elsif ($rt eq 'HASH') {
		my @keys = keys %$data;
		my $sample;
		for my $k (@keys) { $sample = $data->{$k}; last if defined $sample; }
		my $vt = ref $sample;

		if (!@keys) {                                       # ---- empty ----
			# BUG FIX: an empty hash used to die ("neither ARRAY nor HASH");
			# treat it as an empty table, mirroring an empty AoH.
			$kind = 'Hash';
			$total = 0;
			$lab_header = '';
		} elsif ($vt eq 'ARRAY') {                          # ---- HoA ----
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
					: ($i + 1);
				push @raw, [ map {
					ref $data->{$_} eq 'ARRAY' ? $data->{$_}[$i] : undef
				} @cols ];
			}
		} elsif ($vt eq 'HASH') {                           # ---- HoH ----
			$kind = 'HoH';
			$total = scalar @keys;
			my @rk = sort @keys;
			my $show = $n < $total ? $n : $total;
			my @shown = $show > 0 ? @rk[0 .. $show - 1] : ();
			if ($ucols) {
				@cols = @$ucols;
			} else {
				# PERF: gather unique inner keys, sort once.
				my %seen;
				for my $rkk (@shown) {
					next unless ref $data->{$rkk} eq 'HASH';
					$seen{$_} = 1 for keys %{ $data->{$rkk} };
				}
				@cols = sort keys %seen;
			}
			@cols = grep { $_ ne $label_col } @cols if defined $label_col;
			# BUG FIX: honour the row_names alias here too (was 'row.names'
			# only, so row_names => 'x' showed a 'row_name' header).
			$lab_header = defined $label_col ? $label_col : 'row_name';
			for my $rkk (@shown) {
				push @labels, $rkk;
				my $inner = ref $data->{$rkk} eq 'HASH' ? $data->{$rkk} : {};
				push @raw, [ map { $inner->{$_} } @cols ];
			}
		} else {                                            # ---- flat hash ----
			# BUG/FEATURE: a hash whose values are plain scalars
			# ({ a => 1, b => 2, ... }) used to die ("neither ARRAY nor
			# HASH"). Render it like write_table's flat hash: one row, keys
			# as columns, a numeric '1' row label.
			$kind = 'Hash';
			$total = 1;
			my $show = $n < $total ? $n : $total;
			if ($ucols) {
				@cols = @$ucols;
			} else {
				@cols = sort @keys;
			}
			my $lc = defined $label_col ? $label_col
				   : (grep { $_ eq 'row_name' } @cols) ? 'row_name' : undef;
			if (defined $lc) {
				@cols = grep { $_ ne $lc } @cols;
				$lab_header = $lc;
			}
			$lab_header = '' unless defined $lab_header;
			for my $i (0 .. $show - 1) {
				push @labels, defined $lc ? $data->{$lc} : ($i + 1);
				push @raw, [ map { $data->{$_} } @cols ];
			}
		}
	}

	# numeric detection per column (drives right/left alignment)
	my @numeric = (1) x scalar @cols;
	for my $r (@raw) {
		for my $j (0 .. $#cols) {
			my $v = $r->[$j];
			next unless defined $v;
			$numeric[$j] = 0 unless looks_like_number($v);
		}
	}
	my $lab_numeric = @labels ? 1 : 0;
	for my $l (@labels) {
		$lab_numeric = 0, last unless defined $l && looks_like_number($l);
	}

	# stringify + sanitize + truncate cells (column names left intact)
	my $ell_len = length $ell;
	my $clean = sub {
		my $v = shift;
		return $na unless defined $v;
		$v = "$v";
		$v =~ s/\t/\\t/g; $v =~ s/\r/\\r/g; $v =~ s/\n/\\n/g;
		if ($maxw && length($v) > $maxw) {
			my $keep = $maxw - $ell_len;
			$keep = 0 if $keep < 0;
			$v = substr($v, 0, $keep) . $ell;
		}
		return $v;
	};
	my @lab_s  = map { $clean->($_) } @labels;
	my @rows_s = map { [ map { $clean->($_) } @$_ ] } @raw;
	my @head_s = @cols;

	# column widths
	my $lab_w = length $lab_header;
	for my $s (@lab_s) { my $l = length $s; $lab_w = $l if $l > $lab_w; }
	my @w = map { length $_ } @head_s;
	for my $r (@rows_s) {
		for my $j (0 .. $#cols) {
			my $l = length $r->[$j];
			$w[$j] = $l if $l > $w[$j];
		}
	}

	my $pad = sub {
		my ($s, $width, $right) = @_;
		my $g = $width - length $s; $g = 0 if $g < 0;
		return $right ? (' ' x $g) . $s : $s . (' ' x $g);
	};

	my @out;
	my $shown = scalar @rows_s;
	push @out, sprintf("# %s: %d row%s x %d col%s  (showing %d)",
		$kind, $total, ($total == 1 ? '' : 's'),
		scalar(@cols), (@cols == 1 ? '' : 's'), $shown);

	my @hcells = ( $pad->($lab_header, $lab_w, 0) );
	push @hcells, $pad->($head_s[$_], $w[$_], $numeric[$_]) for 0 .. $#cols;
	push @out, join($gap, @hcells);

	for my $ri (0 .. $#rows_s) {
		my @cells = ( $pad->($lab_s[$ri], $lab_w, $lab_numeric) );
		push @cells, $pad->($rows_s[$ri][$_], $w[$_], $numeric[$_]) for 0 .. $#cols;
		push @out, join($gap, @cells);
	}
	push @out, sprintf("# ... %d more row%s", $total - $shown,
		($total - $shown == 1 ? '' : 's')) if $shown < $total;

	my $str = join("\n", @out) . "\n";
	unless ($quiet) { defined $fh ? print {$fh} $str : print $str; }
	return $str;
}


my $aoh = [
	{ row_name => 'p1', age => 41, sex => 'M', tt => 18.2 },
	{ row_name => 'p2', age =>  7, sex => 'F', tt => undef },
	{ row_name => 'p3', age => 33, sex => 'F', tt => 1.05 },
	{ row_name => 'p4', age => 55, sex => 'M', tt => 22.9 },
	{ row_name => 'p5', age => 29, sex => 'M', tt => 14.0 },
	{ row_name => 'p6', age => 62, sex => 'F', tt => undef },
	{ row_name => 'p7', age => 19, sex => 'M', tt => 9.4 },
];
my $hoa = {
	row_name => [ map { "g$_" } 1 .. 7 ],
	gene     => [ qw(BRCA1 TP53 EGFR KRAS MYC PTEN RB1) ],
	logfc    => [ -2.31, 0.04, 3.882901, undef, 1.2, -0.7, undef ],
};
my $hoh = {
	chrX => { start => 1000, end => 2000, strand => '+' },
	chrY => { start =>  500, end => 1500, strand => '-' },
	chr1 => { start =>   10, end =>  9999, strand => '+' },
};

# ---- NEW: rows is a synonym for n ----
is( view($aoh, n => 3, return_only => 1),
    view($aoh, rows => 3, return_only => 1),
    'rows is a synonym for n' );
like( view($aoh, rows => 2, return_only => 1), qr/\(showing 2\)/, 'rows controls the count' );

# ---- NEW: reject unknown args ----
eval { view($aoh, bogus => 1, return_only => 1) };
like( $@, qr/unknown argument\(s\): bogus/, 'unknown arg rejected' );
eval { view($aoh, n => 2, rows => 2, return_only => 1) };
like( $@, qr/either 'n' or 'rows'/, 'n + rows together rejected' );
eval { view($aoh, n => -1, return_only => 1) };
like( $@, qr/non-negative integer/, 'negative n rejected' );
eval { view($aoh, n => 'x', return_only => 1) };
like( $@, qr/non-negative integer/, 'non-numeric n rejected' );
eval { view($aoh, n => undef, return_only => 1) };
like( $@, qr/non-negative integer/, 'undef n rejected' );
# known good args still accepted
eval { view($aoh, na => '.', max_width => 10, ellipsis => '~', gap => 1,
             cols => ['age'], return_only => 1) };
is( $@, '', 'all documented args accepted' );

# ---- BUG FIX: n => 0 still lists column headers (AoH) ----
{
	my @lines = split /\n/, view($aoh, n => 0, return_only => 1);
	is( scalar @lines, 3, 'n=0: banner + header + footer' );
	like( $lines[1], qr/row_name\s+age\s+sex\s+tt/, 'n=0 still shows the column header row' );
	like( $lines[-1], qr/7 more rows/, 'n=0 footer reports all rows hidden' );
}

# ---- BUG FIX: empty hash does not die ----
{
	my $s = eval { view({}, return_only => 1) };
	is( $@, '', 'empty hash does not die' );
	like( $s, qr/^# \w+: 0 rows x 0 cols/, 'empty hash -> 0x0 banner' );
}

# ---- BUG FIX: row_names alias drives the HoH label header ----
{
	my $hoh2 = { a => { v => 1 }, b => { v => 2 } };
	my @lines = split /\n/, view($hoh2, row_names => 'id', return_only => 1);
	like( $lines[1], qr/^id\b/, 'HoH: row_names alias sets the label header' );
}

# ---- core behavior preserved ----
{
	my $s = view($aoh, return_only => 1);
	my @lines = split /\n/, $s;
	like( $lines[0], qr/^# AoH: 7 rows x 3 cols  \(showing 6\)$/, 'AoH banner' );
	like( $lines[1], qr/^row_name\s+age\s+sex\s+tt/, 'AoH header order' );
	like( $lines[-1], qr/^# \.\.\. 1 more row$/, 'AoH footer' );
	like( $s, qr/\bNA\b/, 'undef -> NA' );
}
{
	my @lines = split /\n/, view($hoa, return_only => 1);
	like( $lines[0], qr/^# HoA: 7 rows x 2 cols  \(showing 6\)$/, 'HoA banner' );
	like( $lines[1], qr/^row_name\s+gene\s+logfc/, 'HoA header' );
}
{
	my @lines = split /\n/, view($hoh, return_only => 1);
	like( $lines[0], qr/^# HoH: 3 rows x 3 cols  \(showing 3\)$/, 'HoH banner' );
	like( $lines[2], qr/^chr1\b/, 'HoH sorted row labels' );
}

# alignment: numeric right, string left
{
	my @lines = split /\n/, view([ { row_name => 'r', num => 5, str => 'x' } ], return_only => 1);
	like( $lines[2], qr/  5  x  $/, 'numeric right-padded, string left-padded' );
}

# truncation + sanitization
{
	my $s = view([ { row_name => 'r', note => 'abcdefghijklmnop' } ], max_width => 6, return_only => 1);
	like( $s, qr/abc\.\.\./, 'truncation with ellipsis' );
	my $d = view([ { row_name => 'r', val => "a\tb\nc" } ], return_only => 1);
	like( $d, qr/a\\tb\\nc/, 'tab/newline escaped' );
}

# return_only suppresses print; errors
{
	my $cap = '';
	open my $mem, '>', \$cap or die;
	my $old = select $mem; view($aoh, return_only => 1); select $old; close $mem;
	is( $cap, '', 'return_only prints nothing' );
	eval { view("scalar", return_only => 1) };
	like( $@, qr/expected an ARRAY .* or HASH/, 'non-ref input dies' );
}

# ---- FEATURE: flat (scalar-valued) hash renders as a single row ----
{
	my @lines = split /\n/, view({ a => 1, b => 2, c => 3 }, return_only => 1);
	like( $lines[0], qr/^# Hash: 1 row x 3 cols  \(showing 1\)$/, 'flat hash banner' );
	like( $lines[1], qr/^\s+a\s+b\s+c$/, 'flat hash header: sorted keys, leading label column' );
	like( $lines[2], qr/^1\s+1\s+2\s+3$/, 'flat hash row: numeric label then values' );

	# undef values become NA
	my $s = view({ a => 1, b => undef }, return_only => 1);
	like( $s, qr/\bNA\b/, 'flat hash: undef value -> NA' );

	# cols selects/orders
	@lines = split /\n/, view({ a => 1, b => 2, c => 3 }, cols => ['c','a'], return_only => 1);
	like( $lines[1], qr/c\s+a$/, 'flat hash: cols selects and orders columns' );

	# n => 0 still shows the header
	@lines = split /\n/, view({ a => 1, b => 2 }, n => 0, return_only => 1);
	is( scalar @lines, 3, 'flat hash n=0: banner + header + footer' );
	like( $lines[1], qr/a\s+b$/, 'flat hash n=0: header still lists columns' );

	# row.names names a key to use as the label
	@lines = split /\n/, view({ id => 'x', v => 9 }, 'row.names' => 'id', return_only => 1);
	like( $lines[1], qr/^id\s+v$/, 'flat hash: row.names header' );
	like( $lines[2], qr/^x\s+9$/, 'flat hash: row.names value becomes the label' );
}

done_testing();
