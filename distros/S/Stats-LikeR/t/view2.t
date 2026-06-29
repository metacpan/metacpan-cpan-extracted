#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use Scalar::Util 'looks_like_number';
use Test::Exception; # die_ok
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
		diag("		   got: $got\n	  expected: $expected; diff = $diff");
		return 0;
	}
}

#---------------------------------------------------------------------------
# view() is inlined below pending integration into Stats::LikeR.
# After integrating, delete the inlined copy and add:  use Stats::LikeR;
#---------------------------------------------------------------------------
sub view {
	my $data = shift;
	my %args = @_;
	# --- reject unknown arguments (mirrors read_table/write_table) ---
	my %allowed = map { $_ => 1 } qw(
		n rows na max_width ellipsis gap cols columns
		to return_only row.names row_names color colors
	);
	my @bad = sort grep { !$allowed{$_} } keys %args;
	die "view: unknown argument(s): @bad\n" if @bad;
	# --- n / rows (synonyms); reject conflicting or non-integer values ---
	die "view: pass either 'n' or 'rows', not both\n"
		if exists $args{n} && exists $args{rows};
	my $n = exists $args{rows} ? $args{rows}
		  : exists $args{n}	   ? $args{n}
		  :						  6;
	die "view: 'n'/'rows' must be a non-negative integer\n"
		unless defined $n && $n =~ /^\d+$/;
	my $na	  = exists $args{na}		? $args{na}		   : 'undef';
	my $maxw  = exists $args{max_width} ? $args{max_width} : 80;
	my $ell	  = exists $args{ellipsis}	? $args{ellipsis}  : '...';
	my $gap	  = exists $args{gap}		? (' ' x $args{gap}) : '  ';
	my $ucols = $args{cols} || $args{columns};
	my $fh	  = $args{to};
	my $quiet = $args{return_only};
	# 'row.names' takes precedence over the row_names alias (both accepted)
	my $label_col = exists $args{'row.names'} ? $args{'row.names'}
				  : exists $args{row_names}	  ? $args{row_names}
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
					: ($i + 1);
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
				push @labels, defined $lc ? $data->{$lc} : ($i + 1);
				push @raw, [ map { $data->{$_} } @cols ];
			}
		}
	}

	# ---- display helpers (UTF-8 / wide-char aware) ----
	my $RESET = "\e[0m";
	my $decode = sub {
		my $s = shift;
		return ($s, 0) if utf8::is_utf8($s);
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
	my %color = (%default_colors, %{ $args{colors} || {} });
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
	if (!defined $args{color} || (!ref $args{color} && $args{color} eq 'auto')) {
		my $target = defined $fh ? $fh : \*STDOUT;
		$want_color = (!$quiet && -t $target) ? 1 : 0;
	} else {
		$want_color = $args{color} ? 1 : 0;
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

	my @out;
	my $shown = scalar @row_cell;
	push @out, $paint->(
		sprintf("# %s: %d row%s x %d col%s	(showing %d)",
			$kind, $total, ($total == 1 ? '' : 's'),
			scalar(@cols), (@cols == 1 ? '' : 's'), $shown),
		'caller_info');
	my @hcells = ( $field->($lh_b, $lh_w, $lab_w, 0, 'hash') );
	push @hcells, $field->($head_cell[$_][0], $head_cell[$_][1], $w[$_], $numeric[$_], 'hash') for 0 .. $#cols;
	push @out, join($gap, @hcells);
	for my $ri (0 .. $#row_cell) {
		my @cells = ( $field->($lab_cell[$ri][0], $lab_cell[$ri][1], $lab_w, $lab_numeric, $lab_cell[$ri][2]) );
		push @cells, $field->($row_cell[$ri][$_][0], $row_cell[$ri][$_][1], $w[$_], $numeric[$_], $row_cell[$ri][$_][2]) for 0 .. $#cols;
		push @out, join($gap, @cells);
	}
	push @out, $paint->(
		sprintf("# ... %d more row%s", $total - $shown, ($total - $shown == 1 ? '' : 's')),
		'caller_info') if $shown < $total;

	my $str = join("\n", @out) . "\n";
	unless ($quiet) { defined $fh ? print {$fh} $str : print $str; }
	return $str;
}

#--------
# helpers
#--------
sub _strip { my $s = shift; $s =~ s/\e\[[0-9;]*m//g; return $s; }
sub _lines { return split /\n/, _strip($_[0]); }
sub _dwidth { my $s = _strip(shift); utf8::decode($s); return length $s; }

#--------
# undefined values render as "undef" (Data::Printer style)
#--------
{
	my $d = [ { a => 1, b => undef }, { a => undef, b => 2 } ];
	my $out = view($d, return_only => 1, color => 0);
	like($out,	 qr/\bundef\b/, 'undefined values render as the bareword "undef"');
	unlike($out, qr/\bNA\b/,	'undefined values are not shown as "NA" by default');
	my $over = view($d, return_only => 1, color => 0, na => 'NA');
	like($over,	  qr/\bNA\b/,	 "na => 'NA' overrides the placeholder");
	unlike($over, qr/\bundef\b/, "na override replaces 'undef' entirely");
	# undef also covers a missing key (HoH/AoH sparse rows)
	my $sparse = [ { a => 1 }, { a => 2, b => 9 } ];
	like(view($sparse, return_only=>1, color=>0), qr/\bundef\b/, 'missing key shows as undef');
}

#--------
# AoH structure
#--------
{
	my $aoh = [
		{ id => 1,	name => 'Alice', score => 9.5	},
		{ id => 2,	name => 'Bob',	 score => 12.25 },
		{ id => 30, name => 'Cara',	 score => 100	},
	];
	my @L = _lines(view($aoh, return_only => 1, color => 0));
	is(scalar @L, 5, 'AoH: summary + header + 3 data rows');
	like($L[0], qr/^# AoH: 3 rows x 3 cols	\(showing 3\)$/, 'AoH summary line');
	like($L[1], qr/id.*name.*score/, 'header lists columns in sorted order');
	like($L[2], qr/^1\b/,	 'row 1 labelled 1');
	like($L[2], qr/Alice/,	 'row 1 carries its data');
	like($L[4], qr/^3\b/,	 'row 3 labelled 3');
}

#--------
# HoA structure
#--------
{
	my $hoa = { id => [1, 2, 30], name => ['Alice', 'Bob', 'Cara'] };
	my @L = _lines(view($hoa, return_only => 1, color => 0));
	like($L[0], qr/^# HoA: 3 rows x 2 cols/, 'HoA summary line');
	like($L[2], qr/^1\b.*Alice/, 'HoA row 1');
}

#--------
# HoH structure (row labels are the outer keys, sorted)
#--------
{
	my $hoh = { beta => { x => 2, y => 'q' }, alpha => { x => 1, y => 'p' } };
	my @L = _lines(view($hoh, return_only => 1, color => 0));
	like($L[0], qr/^# HoH: 2 rows x 2 cols/, 'HoH summary line');
	like($L[1], qr/^row_name/, 'HoH label header is row_name');
	like($L[2], qr/^alpha\b/,  'HoH rows sorted by key (alpha first)');
	like($L[3], qr/^beta\b/,   'HoH second row beta');
}

#--------
# flat hash (single row)
#--------
{
	my @L = _lines(view({ alpha => 1, beta => 'two', gamma => 3.5 }, return_only => 1, color => 0));
	like($L[0], qr/^# Hash: 1 row x 3 cols/, 'flat hash single-row summary');
	is(scalar @L, 3, 'flat hash: summary + header + 1 row');
	like($L[2], qr/^1\b/, 'flat hash row labelled 1');
}

#--------
# empty inputs
#--------
{
	like( (_lines(view({}, return_only=>1, color=>0)))[0], qr/^# Hash: 0 rows x 0 cols/, 'empty hash');
	like( (_lines(view([], return_only=>1, color=>0)))[0], qr/^# AoH: 0 rows x 0 cols/,	 'empty AoH');
}

#--------
# every header and row shares one display width (alignment invariant)
#--------
{
	my $aoh = [ { a => 1, b => 'xx', c => 3 }, { a => 22, b => 'y', c => 444 } ];
	my @L = _lines(view($aoh, return_only => 1, color => 0));
	my %w; $w{ _dwidth($_) }++ for @L[1 .. $#L];
	is(scalar keys %w, 1, 'header and all rows share one display width');
}

#--------
# multibyte UTF-8 does not break alignment (the bug this version fixes)
#--------
{
	my $oe = "J\xC3\xB8rgensen";   # o-slash as 2 UTF-8 bytes
	my $d  = [ { n => 1, who => $oe, z => 'x' }, { n => 22, who => 'Bo', z => 'y' } ];
	my @L  = _lines(view($d, return_only => 1, color => 0));
	my %w; $w{ _dwidth($_) }++ for @L[1 .. $#L];
	is(scalar keys %w, 1, 'a multibyte cell keeps columns aligned');
	my ($oe_line) = grep { /gensen/ } @L;
	isnt(length $oe_line, _dwidth($oe_line), 'the UTF-8 row is wider in bytes than in display columns');
}

#--------
# numeric columns right-align, string columns left-align
#--------
{
	my @N = _lines(view({ x => [1, 100] },	   return_only => 1, color => 0));
	ok($N[2] =~ /\s\s+1$/, 'numeric column right-aligned (short value padded on the left)');
	my @S = _lines(view({ x => ['a', 'ccc'] }, return_only => 1, color => 0));
	ok($S[2] =~ /a\s\s+$/, 'string column left-aligned (short value padded on the right)');
}

#--------
# n / rows, footer, and their validation
#--------
{
	my $aoh = [ map { { i => $_ } } 1 .. 5 ];
	my @L = _lines(view($aoh, n => 2, return_only => 1, color => 0));
	like($L[0],	 qr/showing 2/,			   'n => 2 shows two rows');
	like($L[-1], qr/^# \.\.\. 3 more rows$/, 'footer reports remaining rows');
	is(scalar(grep { /^\d/ } @L), 2, 'exactly two data rows shown');

	my @R = _lines(view($aoh, rows => 2, return_only => 1, color => 0));
	is_deeply(\@R, \@L, "'rows' is a synonym for 'n'");

	throws_ok { view($aoh, n => 1, rows => 1, return_only => 1) }
		qr/either 'n' or 'rows', not both/, 'n + rows together dies';
	throws_ok { view($aoh, n => 'x', return_only => 1) }
		qr/non-negative integer/, 'a non-integer n dies';

	my @Z = _lines(view($aoh, n => 0, return_only => 1, color => 0));
	is(scalar(grep { /^\d/ } @Z), 0, 'n => 0 shows no data rows');
	like($Z[0],	 qr/showing 0/,	   'n => 0 summary says showing 0');
	like($Z[-1], qr/5 more rows/,  'n => 0 still reports all rows in the footer');
	like($Z[1],	 qr/\bi\b/,		   'header still lists columns when showing 0 rows');
}

#--------
# column selection (cols / columns) preserves order and drops the rest
#--------
{
	my $aoh = [ { a => 1, b => 2, c => 3 } ];
	my @L = _lines(view($aoh, cols => ['c', 'a'], return_only => 1, color => 0));
	like($L[0],	  qr/2 cols/,	'cols limits the column count');
	like($L[1],	  qr/c.*a/,		'cols preserves the given order');
	unlike($L[1], qr/\bb\b/,	'an unlisted column is omitted');
	my @L2 = _lines(view($aoh, columns => ['c', 'a'], return_only => 1, color => 0));
	is_deeply(\@L2, \@L, "'columns' is an alias for 'cols'");
}

#--------
# row labels: auto row_name, explicit row.names, and precedence
#--------
{
	my $aoh = [ { row_name => 'r1', v => 10 }, { row_name => 'r2', v => 20 } ];
	my @L = _lines(view($aoh, return_only => 1, color => 0));
	like($L[1], qr/^row_name/, 'a row_name column becomes the label header');
	like($L[2], qr/^r1\b/,	   'first label is r1');
	like($L[2], qr/\b10\b/,	   'the row_name column is not also shown as data twice');

	my $aoh2 = [ { k => 'A', v => 1 } ];
	my @L2 = _lines(view($aoh2, 'row.names' => 'k', return_only => 1, color => 0));
	like($L2[1], qr/^k\b/, "row.names => 'k' uses k as the label column");
	like($L2[2], qr/^A\b/, 'label value taken from k');

	my @L3 = _lines(view($aoh2, 'row.names' => 'k', row_names => 'v', return_only => 1, color => 0));
	is_deeply(\@L3, \@L2, 'row.names takes precedence over row_names');
}

#--------
# max_width truncation is char-aware, with a configurable ellipsis
#--------
{
	my @L = _lines(view({ s => ['abcdefghij'] }, max_width => 5, return_only => 1, color => 0));
	like($L[2], qr/ab\.\.\.$/, 'cell truncated to max_width with the default ellipsis');
	my @E = _lines(view({ s => ['abcdefghij'] }, max_width => 5, ellipsis => '~', return_only => 1, color => 0));
	like($E[2], qr/abcd~$/, 'a custom ellipsis is honoured');
}

#--------
# gap widens the inter-column spacing
#--------
{
	my $aoh = [ { a => 1, b => 2 } ];
	my $g0 = view($aoh, gap => 0, return_only => 1, color => 0);
	my $g3 = view($aoh, gap => 3, return_only => 1, color => 0);
	ok(length($g3) > length($g0), 'a larger gap produces wider output');
}

#--------
# argument and type errors
#--------
{
	my $aoh = [ { a => 1 } ];
	throws_ok { view($aoh, bogus => 1, return_only => 1) } qr/unknown argument/,			'an unknown argument dies';
	throws_ok { view('scalar') }						   qr/expected an ARRAY.*or HASH/,	'a non-reference dies';
	throws_ok { view(\my $x) }							   qr/expected an ARRAY.*or HASH/,	'a scalar reference dies';
}

#--------
# colour: opt-in ANSI that never disturbs alignment
#--------
{
	my $aoh	  = [ { a => 1, b => undef } ];
	my $plain = view($aoh, return_only => 1, color => 0);
	my $col	  = view($aoh, return_only => 1, color => 1);
	unlike($plain, qr/\e\[/, 'color => 0 emits no ANSI');
	like($col,	   qr/\e\[/, 'color => 1 emits ANSI');
	(my $stripped = $col) =~ s/\e\[[0-9;]*m//g;
	is($stripped, $plain, 'stripping ANSI reproduces the plain layout exactly');
	like($col, qr/\e\[91mundef\e\[0m/, 'undef painted with the undef colour');
	like($col, qr/\e\[94m/,			   'numbers painted with the number colour');
	like($col, qr/\e\[35m/,			   'headers painted with the hash colour');
	like($col, qr/\e\[96m# AoH/,	   'the caller-info line is painted');
}

#--------
# custom Data::Printer-style colours (hex truecolor)
#--------
{
	my $col = view([ { n => 5 } ], return_only => 1, color => 1, colors => { number => '#87afff' });
	like($col, qr/\e\[38;2;135;175;255m/, 'a #rrggbb colour becomes a truecolor escape');
}

#--------
# 'to' filehandle and return_only
#--------
{
	my $aoh = [ { a => 1 } ];
	open my $fh, '>', \my $buf or die "open: $!";
	my $ret = view($aoh, to => $fh, color => 0);
	close $fh;
	is($buf, $ret, "output sent to a 'to' filehandle equals the returned string");
	ok(length(view($aoh, return_only => 1, color => 0)), 'return_only returns the rendered string');
}

#--------
# memory
#--------
no_leaks_ok {
	my $s = view([ { a => 1, b => 'x', c => undef } ], return_only => 1, color => 0);
} 'view: no memory leaks on a plain render' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $s = view({ id => [1, 2], name => ["J\xC3\xB8rgensen", 'Bo'] }, return_only => 1, color => 1);
} 'view: no memory leaks on a coloured UTF-8 render' unless $INC{'Devel/Cover.pm'};

done_testing;
