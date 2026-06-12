use strict;
use warnings;
use Test::More;
use Scalar::Util 'looks_like_number';

sub view {
	my $data = shift;
	my %args = @_;

	my $n     = exists $args{n}         ? $args{n}         : 6;
	my $na    = exists $args{na}        ? $args{na}        : 'NA';
	my $maxw  = exists $args{max_width} ? $args{max_width} : 50;
	my $ell   = exists $args{ellipsis}  ? $args{ellipsis}  : '...';
	my $gap   = exists $args{gap}       ? (' ' x $args{gap}) : '  ';
	my $ucols = $args{cols} || $args{columns};
	my $fh    = $args{to};
	my $quiet = $args{return_only};

	my $label_col = exists $args{'row.names'} ? $args{'row.names'}
		         : exists $args{row_names}   ? $args{row_names}
		         : undef;

	my $rt = ref $data;
	die "view: expected an ARRAY (AoH) or HASH (HoA/HoH) reference, got "
	  . ($rt || 'a non-reference') . "\n"
	  unless $rt eq 'ARRAY' or $rt eq 'HASH';

	my ($kind, @cols, @labels, @raw, $total, $lab_header);

	if ($rt eq 'ARRAY') {                                   # ---- AoH ----
	  $kind  = 'AoH';
	  $total = scalar @$data;
	  my $show = $n < $total ? $n : $total;
	  $show = 0 if $show < 0;

	  if ($ucols) {
		   @cols = @$ucols;
	  } else {
		   my %seen;
		   for my $i (0 .. $show - 1) {
		       my $row = $data->[$i];
		       next unless ref $row eq 'HASH';
		       push @cols, grep { !$seen{$_}++ } sort keys %$row;
		   }
	  }
	  my $lc = defined $label_col ? $label_col
		      : (grep { $_ eq 'row_name' } @cols) ? 'row_name' : undef;
	  if (defined $lc) {
		   @cols = grep { $_ ne $lc } @cols;
		   $lab_header = $lc;
	  }
	  for my $i (0 .. $show - 1) {
		   my $row = $data->[$i] || {};
		   push @labels, defined $lc ? $row->{$lc} : ($i + 1);
		   push @raw, [ map { $row->{$_} } @cols ];
	  }
	  $lab_header = '' unless defined $lab_header;
	}
	elsif ($rt eq 'HASH') {
	  my @keys = keys %$data;
	  my $sample;
	  for my $k (@keys) { $sample = $data->{$k}; last if defined $sample; }
	  my $vt = ref $sample;

	  if (!@keys) {                                       # ---- empty ----
		   $kind = 'Hash';
		   $total = 0;
		   $lab_header = '';
		   # @cols, @labels, @raw stay empty
	  }
	  elsif ($vt eq 'ARRAY') {                            # ---- HoA ----
		   $kind = 'HoA';
		   my @allcols = $ucols ? @$ucols : sort @keys;
		   $total = 0;
		   for my $k (@keys) {
		       my $l = ref $data->{$k} eq 'ARRAY' ? scalar @{ $data->{$k} } : 0;
		       $total = $l if $l > $total;
		   }
		   my $show = $n < $total ? $n : $total;
		   $show = 0 if $show < 0;
		   my $lc = defined $label_col ? $label_col
		          : (grep { $_ eq 'row_name' } @allcols) ? 'row_name' : undef;
		   @cols = grep { !defined $lc || $_ ne $lc } @allcols;
		   $lab_header = defined $lc ? $lc : '';
		   for my $i (0 .. $show - 1) {
		       push @labels, defined $lc ? $data->{$lc}[$i] : ($i + 1);
		       push @raw, [ map { $data->{$_}[$i] } @cols ];
		   }
	  }
	  elsif ($vt eq 'HASH') {                             # ---- HoH ----
		   $kind = 'HoH';
		   $total = scalar @keys;
		   my @rk = sort @keys;
		   my $show = $n < $total ? $n : $total;
		   $show = 0 if $show < 0;
		   my @shown = $show > 0 ? @rk[0 .. $show - 1] : ();
		   if ($ucols) {
		       @cols = @$ucols;
		   } else {
		       my %seen;
		       for my $rkk (@shown) {
		           push @cols, grep { !$seen{$_}++ } sort keys %{ $data->{$rkk} };
		       }
		   }
		   @cols = grep { $_ ne $label_col } @cols if defined $label_col;
		   $lab_header = exists $args{'row.names'} ? $args{'row.names'} : 'row_name';
		   for my $rkk (@shown) {
		       push @labels, $rkk;
		       push @raw, [ map { $data->{$rkk}{$_} } @cols ];
		   }
	  }
	  else {
		   die "view: HASH values are neither ARRAY (HoA) nor HASH (HoH) refs; "
		     . "cannot interpret as a table\n";
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
	for my $l (@labels) { $lab_numeric = 0, last unless defined $l && looks_like_number($l); }

	# stringify + sanitize + truncate cells (column names left intact)
	my $clean = sub {
	  my $v = shift;
	  return $na unless defined $v;
	  $v = "$v";
	  $v =~ s/\t/\\t/g; $v =~ s/\r/\\r/g; $v =~ s/\n/\\n/g;
	  if ($maxw && length($v) > $maxw) {
		   my $keep = $maxw - length($ell);
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
	$lab_w = length $_ > $lab_w ? length $_ : $lab_w for @lab_s;
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

# ----------------------------------------------------------------------------
# fixtures
# ----------------------------------------------------------------------------
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

# capture STDOUT produced by a block
sub capture (&) {
 my $code = shift;
 my $buf  = '';
 open my $fh, '>', \$buf or die "capture open: $!";
 my $old = select $fh;
 $code->();
 select $old;
 close $fh;
 return $buf;
}

# ---
# AoH
# ---
{
 my $s = view($aoh, return_only => 1);
 my @lines = split /\n/, $s;

 like   $lines[0], qr/^# AoH: 7 rows x 3 cols  \(showing 6\)$/, 'AoH banner: dims + showing';
 is     scalar(@lines), 1 + 1 + 6 + 1, 'AoH default: banner + header + 6 rows + footer';
 like   $lines[-1], qr/^# \.\.\. 1 more row$/, 'AoH footer: singular "1 more row"';
 like   $s, qr/\bNA\b/, 'AoH: undef rendered as NA';
 like   $lines[1], qr/^row_name/, 'AoH: row_name promoted to leftmost label column';
 unlike $lines[1], qr/\brow_name\b.*\brow_name\b/, 'AoH: row_name not also a data column';

 # header order is sorted by name (age, sex, tt) after the label column
 like $lines[1], qr/row_name\s+age\s+sex\s+tt/, 'AoH: data columns sorted by name';
}

# alignment: numeric right-justified, string left-justified (controlled fixture)
{
 my $align = [ { row_name => 'r', num => 5, str => 'x' } ];
 my $s = view($align, return_only => 1);
 my @lines = split /\n/, $s;
 # widths: num -> max(len 'num'=3, '5'=1)=3 ; str -> max(len 'str'=3,'x'=1)=3
 like $lines[2], qr/  5  x  $/, 'align: numeric right-padded ("  5"), string left-padded ("x  ")';
}

{
 my $s = view($aoh, n => 100, return_only => 1);
 my @lines = split /\n/, $s;
 is   scalar(@lines), 1 + 1 + 7, 'AoH n>total: all rows, no footer';
 unlike $s, qr/more row/, 'AoH n>total: no footer line';
 like $lines[0], qr/\(showing 7\)$/, 'AoH n>total: showing == total';
}

{
 my $s = view($aoh, n => 0, return_only => 1);
 my @lines = split /\n/, $s;
 is   scalar(@lines), 1 + 1 + 1, 'AoH n=0: banner + header + footer only';
 like $lines[-1], qr/^# \.\.\. 7 more rows$/, 'AoH n=0: plural footer';
}

# ----
# HoA
# ----
{
 my $s = view($hoa, return_only => 1);
 my @lines = split /\n/, $s;
 like $lines[0], qr/^# HoA: 7 rows x 2 cols  \(showing 6\)$/, 'HoA banner';
 like $lines[1], qr/^row_name\s+gene\s+logfc/, 'HoA: row_name as label, data cols sorted';
 like $s, qr/\bg1\b/ && qr/\bBRCA1\b/, 'HoA: values pulled column-wise by row index';
 like $s, qr/\bNA\b/, 'HoA: undef in array rendered as NA';
}

# ---
# HoH
# ---
{
 my $s = view($hoh, return_only => 1);
 my @lines = split /\n/, $s;
 like $lines[0], qr/^# HoH: 3 rows x 3 cols  \(showing 3\)$/, 'HoH banner';
 like $lines[1], qr/^row_name\s+end\s+start\s+strand/, 'HoH: top keys -> row_name label';
 # rows are the sorted top-level keys
 like $lines[2], qr/^chr1\b/, 'HoH: row labels are sorted keys (chr1 first)';
 like $lines[3], qr/^chrX\b/, 'HoH: chrX second';
 like $lines[4], qr/^chrY\b/, 'HoH: chrY third';
}

# ---------------------
# explicit column order
# ---------------------
{
 my $s = view($aoh, cols => [qw(sex tt age)], n => 1, return_only => 1);
 my @lines = split /\n/, $s;
 # no label column among cols => a blank-header numeric row-id column leads
 like $lines[1], qr/sex\s+tt\s+age\s*$/, 'cols: explicit order honored (sex, tt, age)';
 like $lines[2], qr/^\s*1\s/, 'cols: leading numeric row-id label when no label column given';
}

# ------------------
# row.names override
# ------------------
{
 my $aoh2 = [ { id => 'x', a => 1, b => 2 }, { id => 'y', a => 3, b => 4 } ];
 my $s = view($aoh2, 'row.names' => 'id', return_only => 1);
 my @lines = split /\n/, $s;
 like $lines[1], qr/^id\s+a\s+b\s*$/, 'row.names: chosen column becomes label header';
 like $lines[2], qr/^x\s+1\s+2\s*$/, 'row.names: first label is x';
}

# ----------------
# na customization
# ----------------
{
 my $s = view($aoh, na => '.', n => 2, return_only => 1);
 like   $s, qr/\s\.\s/, 'na: custom token "." used';
 unlike $s, qr/\bNA\b/, 'na: default NA not present';
}

# ---------------------
# truncation + ellipsis
# ---------------------
{
 my $wide = [ { row_name => 'r1', note => 'abcdefghijklmnop' } ];
 my $s = view($wide, max_width => 6, return_only => 1);
 like $s, qr/abc\.\.\./, 'max_width: long cell truncated with default ellipsis';

 my $s2 = view($wide, max_width => 6, ellipsis => '~', return_only => 1);
 like $s2, qr/abcde~/, 'ellipsis: custom marker honored';
}

# ----------------------------------------------------------------------------
# sanitization of embedded control chars
# ----------------------------------------------------------------------------
{
 my $d = [ { row_name => 'r', val => "a\tb\nc\rd" } ];
 my $s = view($d, return_only => 1);
 like   $s, qr/a\\tb\\nc\\rd/, 'sanitize: tab/newline/cr escaped, single display line';
 is     scalar(split /\n/, $s), 1 + 1 + 1, 'sanitize: cell newline did not add a line';
}

# ----------------------------------------------------------------------------
# return_only suppresses printing; default path prints
# ----------------------------------------------------------------------------
{
 my $printed = capture { view($aoh, return_only => 1) };
 is $printed, '', 'return_only: nothing printed to STDOUT';

 my $printed2 = capture { view($aoh, n => 1) };
 like $printed2, qr/^# AoH:/, 'default: prints to STDOUT';
}

# ----------------
# to => filehandle
# ----------------
{
 my $buf = '';
 open my $fh, '>', \$buf or die;
 view($aoh, n => 1, to => $fh);
 close $fh;
 like $buf, qr/^# AoH:/, 'to: output goes to the supplied filehandle';
}

# -----------------
# empty structures
# -----------------
{
 my $s = view([], return_only => 1);
 like $s, qr/^# AoH: 0 rows x 0 cols  \(showing 0\)/, 'empty AoH: clean banner';

 my $s2 = view({}, return_only => 1);
 like $s2, qr/^# \w+: 0 rows x 0 cols  \(showing 0\)/, 'empty HASH: graceful banner, no crash';
}

# ------
# errors
# ------
{
 eval { view("not a ref", return_only => 1) };
 like $@, qr/expected an ARRAY .* or HASH/, 'error: scalar input dies with clear message';

 eval { view({ a => 1, b => 2 }, return_only => 1) };
 like $@, qr/neither ARRAY .* nor HASH/, 'error: HASH of scalars rejected';
}

done_testing();
