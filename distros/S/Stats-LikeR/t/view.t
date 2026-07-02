require 5.010;
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Stats::LikeR;

# Column chunking depends on the terminal width (explicit 'width' arg, then
# $ENV{COLUMNS}, then 80). Pin COLUMNS wide so every single-block layout test
# below is deterministic regardless of the caller's terminal; the chunking
# tests pass an explicit 'width' that overrides it.
dies_ok {
	view( undef );
} 'view: dies when given undefined data';
$ENV{COLUMNS} = 1000;

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

# ---- rows is a synonym for n ----
is( view($aoh, n => 3, return_only => 1),
    view($aoh, rows => 3, return_only => 1),
    'rows is a synonym for n' );
like( view($aoh, rows => 2, return_only => 1), qr/\(showing 2\)/, 'rows controls the count' );

# ---- reject unknown args ----
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
# known good args still accepted (now including 'width')
eval { view($aoh, na => '.', max_width => 10, ellipsis => '~', gap => 1,
             cols => ['age'], width => 200, return_only => 1) };
is( $@, '', 'all documented args accepted' );

# ---- n => 0 still lists column headers (AoH) ----
{
	my @lines = split /\n/, view($aoh, n => 0, return_only => 1);
	is( scalar @lines, 3, 'n=0: banner + header + footer' );
	like( $lines[1], qr/row_name\s+age\s+sex\s+tt/, 'n=0 still shows the column header row' );
	like( $lines[-1], qr/7 more rows/, 'n=0 footer reports all rows hidden' );
}

# ---- empty hash does not die ----
{
	my $s = eval { view({}, return_only => 1) };
	is( $@, '', 'empty hash does not die' );
	like( $s, qr/^# \w+: 0 rows x 0 cols/, 'empty hash -> 0x0 banner' );
}

# ---- row_names alias drives the HoH label header ----
{
	my $hoh2 = { a => { v => 1 }, b => { v => 2 } };
	my @lines = split /\n/, view($hoh2, row_names => 'id', return_only => 1);
	like( $lines[1], qr/^id\b/, 'HoH: row_names alias sets the label header' );
}

# ---- core behavior preserved (banner uses a TAB before "(showing ...)") ----
{
	my $s = view($aoh, return_only => 1);
	my @lines = split /\n/, $s;
	like( $lines[0], qr/^# AoH: 7 rows x 3 cols\t\(showing 6\)$/, 'AoH banner' );
	like( $lines[1], qr/^row_name\s+age\s+sex\s+tt/, 'AoH header order' );
	like( $lines[-1], qr/^# \.\.\. 1 more row$/, 'AoH footer' );
}
{
	my @lines = split /\n/, view($hoa, return_only => 1);
	like( $lines[0], qr/^# HoA: 7 rows x 2 cols\t\(showing 6\)$/, 'HoA banner' );
	like( $lines[1], qr/^row_name\s+gene\s+logfc/, 'HoA header' );
}
{
	my @lines = split /\n/, view($hoh, return_only => 1);
	like( $lines[0], qr/^# HoH: 3 rows x 3 cols\t\(showing 3\)$/, 'HoH banner' );
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

# ---- flat (scalar-valued) hash renders as a single row ----
{
	my @lines = split /\n/, view({ a => 1, b => 2, c => 3 }, return_only => 1);
	like( $lines[0], qr/^# Hash: 1 row x 3 cols\t\(showing 1\)$/, 'flat hash banner' );
	like( $lines[1], qr/^\s+a\s+b\s+c$/, 'flat hash header: sorted keys, leading label column' );
	like( $lines[2], qr/^1\s+1\s+2\s+3$/, 'flat hash row: numeric label then values' );

	# undef renders as the "undef" placeholder by default; na overrides it
	my $s = view({ a => 1, b => undef }, return_only => 1);
	like( $s, qr/\bundef\b/, 'flat hash: undef value -> "undef" placeholder' );
	unlike( $s, qr/\bNA\b/,  'flat hash: not shown as NA by default' );
	like( view({ a => 1, b => undef }, na => 'NA', return_only => 1),
		qr/\bNA\b/, "na => 'NA' overrides the placeholder" );

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

# ---- NEW: 'width' argument + R-style column chunking ----
# A table wider than the terminal is split into successive column blocks, each
# led by a repeated copy of the row-label column (as R does when a data frame
# exceeds getOption("width")).
{
	# 8 data columns (each 2 wide) + a row_name label column (8 wide), gap = 2.
	my $wide = [
		{ row_name => 'r1', c1=>11, c2=>12, c3=>13, c4=>14, c5=>15, c6=>16, c7=>17, c8=>18 },
		{ row_name => 'r2', c1=>21, c2=>22, c3=>23, c4=>24, c5=>25, c6=>26, c7=>27, c8=>28 },
	];

	# 'width' is an accepted argument
	eval { view($wide, width => 80, return_only => 1) };
	is( $@, '', "'width' is an accepted argument" );

	# a wide-enough width keeps everything in one block
	my @one = split /\n/, view($wide, width => 1000, return_only => 1);
	is( scalar(grep { /^row_name/ } @one), 1, 'width=1000: a single column block' );
	like( $one[0], qr/x 8 cols/, 'banner reports the full column count' );

	# a narrow width splits the columns into repeated blocks
	my @narrow = split /\n/, view($wide, width => 20, return_only => 1);
	my @hdr = grep { /^row_name/ } @narrow;
	cmp_ok( scalar @hdr, '>', 1, 'a narrow width splits into multiple blocks' );
	is( scalar(grep { /^r1\b/ } @narrow), scalar @hdr, 'the label column repeats in every block' );
	is( scalar(grep { /^# AoH:/ } @narrow), 1, 'the banner is printed exactly once' );
	like( $narrow[0], qr/x 8 cols/, 'the banner still reports every column, not just one block' );

	# every column appears once, in its original order, across the blocks
	my @order;
	for my $h (@hdr) { my @t = split ' ', $h; shift @t; push @order, @t; }
	is_deeply( \@order, [qw(c1 c2 c3 c4 c5 c6 c7 c8)],
		'columns are distributed across blocks in their original order' );

	# no blank line is inserted between blocks (matches R): every non-banner,
	# non-footer line is either a header or a data row -- none are empty
	is( scalar(grep { $_ eq '' } @narrow), 0, 'no blank separator lines between blocks' );

	# the row-truncation footer is printed once, not once per block
	my @foot = split /\n/, view($wide, n => 1, width => 20, return_only => 1);
	is( scalar(grep { /^# \.\.\. / } @foot), 1, 'the footer is printed once regardless of block count' );

	# a single column wider than the width still renders (overflow, no infinite loop)
	my @big = split /\n/, view([ { row_name => 'r1', huge => ('X' x 30) } ], width => 10, return_only => 1);
	is( scalar(grep { /^row_name/ } @big), 1, 'an over-wide single column stays in one block' );
	like( $big[1], qr/\bhuge\b/, 'the over-wide column header still shows' );
	like( $big[2], qr/X{30}/, 'the over-wide value is rendered in full' );

	# width validation
	eval { view($wide, width => 0,   return_only => 1) }; like( $@, qr/width.*positive integer/, 'width => 0 rejected' );
	eval { view($wide, width => -5,  return_only => 1) }; like( $@, qr/width.*positive integer/, 'negative width rejected' );
	eval { view($wide, width => 'x', return_only => 1) }; like( $@, qr/width.*positive integer/, 'non-numeric width rejected' );
	eval { view($wide, width => 3.5, return_only => 1) }; like( $@, qr/width.*positive integer/, 'non-integer width rejected' );

	# $ENV{COLUMNS} is honoured when no width is given, but an explicit width wins
	{
		local $ENV{COLUMNS} = 18;
		my @byenv = split /\n/, view($wide, return_only => 1);
		cmp_ok( scalar(grep { /^row_name/ } @byenv), '>', 1, 'COLUMNS env drives chunking' );
		my @byarg = split /\n/, view($wide, width => 1000, return_only => 1);
		is( scalar(grep { /^row_name/ } @byarg), 1, 'an explicit width overrides COLUMNS' );
	}
	{
		local $ENV{COLUMNS} = 'not-a-number';
		my $s = eval { view($wide, return_only => 1) };
		is( $@, '', 'an invalid COLUMNS is ignored rather than fatal' );
	}
}

done_testing();
