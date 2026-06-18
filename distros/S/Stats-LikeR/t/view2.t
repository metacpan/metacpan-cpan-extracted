#!/usr/bin/env perl
# Coverage for Stats::LikeR::view -- the R-style head() printer.
# Exercises every structural branch (AoH / HoA / HoH / flat hash / empty),
# the n/rows handling, label-column detection, formatting options, cell
# sanitising/truncation, alignment, the to=>FH and return_only paths, and
# every documented error.
use strict;
use warnings;
use Test::More;
use Stats::LikeR qw(view);

# view() always returns the formatted string; grab its non-comment ("body")
# lines, which are the header + data rows of the table.
sub body_lines {
    my $s = shift;
    return grep { length $_ && $_ !~ /^#/ } split /\n/, $s;
}

# ---------------------------------------------------------------------------
# Array of hashes (AoH)
# ---------------------------------------------------------------------------
{
    my $aoh = [ { a => 1, b => 2 }, { a => 3, b => 4 }, { a => 5, b => 6 } ];

    my $s = view($aoh, return_only => 1);
    like $s, qr/^# AoH: 3 rows x 2 cols  \(showing 3\)/, 'AoH banner';
    my @b = body_lines($s);
    is scalar(@b), 4, 'AoH: header + 3 data rows';
    like $b[0], qr/\ba\b.*\bb\b/, 'AoH header lists sorted columns a,b';
    like $b[1], qr/\b1\b.*\b2\b/, 'AoH first data row';
    like $b[3], qr/\b5\b.*\b6\b/, 'AoH last data row';

    # default n is 6: fewer rows than n shows all, no footer
    unlike $s, qr/more row/, 'no footer when all rows fit';

    # n smaller than total -> footer reports the remainder
    my $s2 = view($aoh, n => 2, return_only => 1);
    like $s2, qr/showing 2/,            'n=2 shows 2';
    like $s2, qr/# \.\.\. 1 more row\b/, 'footer: 1 more row (singular)';

    # n larger than total is clamped
    like view($aoh, n => 99, return_only => 1), qr/showing 3/, 'n>total clamps';

    # rows is a synonym for n
    is_deeply [ body_lines(view($aoh, rows => 2, return_only => 1)) ],
              [ body_lines(view($aoh, n    => 2, return_only => 1)) ],
              'rows is a synonym for n';
}

# n => 0 still lists the columns in the header (the documented bug fix)
{
    my $aoh = [ { x => 1, y => 2 } ];
    my $s = view($aoh, n => 0, return_only => 1);
    like $s, qr/showing 0/, 'n=0 shows zero rows';
    my @b = body_lines($s);
    is scalar(@b), 1, 'n=0: header only';
    like $b[0], qr/\bx\b.*\by\b/, 'n=0 header still lists columns';
}

# explicit column selection / ordering, and the "columns" alias
{
    my $aoh = [ { a => 1, b => 2, c => 3 } ];
    my $s = view($aoh, cols => [qw(c a)], return_only => 1);
    like $s, qr/# AoH: 1 row x 2 cols/, 'cols restricts to 2 columns (singular row)';
    my ($hdr) = body_lines($s);
    like $hdr, qr/c .* a/x, 'cols pins order c then a';
    unlike $hdr, qr/\bb\b/, 'unselected column b omitted';

    is_deeply [ body_lines(view($aoh, columns => [qw(c a)], return_only => 1)) ],
              [ body_lines(view($aoh, cols    => [qw(c a)], return_only => 1)) ],
              'columns is a synonym for cols';
}

# label column: explicit row.names, the row_names alias, and auto row_name
{
    my $aoh = [ { id => 'p1', v => 10 }, { id => 'p2', v => 20 } ];

    my $s = view($aoh, 'row.names' => 'id', return_only => 1);
    my @b = body_lines($s);
    like $b[0], qr/^id\b/,  'row.names: label header is the chosen column';
    unlike $b[0], qr/\bv\b.*\bid\b/, 'label column not repeated among data cols';
    like $b[1], qr/^p1\b/,  'first row labelled by id value';
    like $b[2], qr/^p2\b/,  'second row labelled by id value';

    # row_names alias yields the same layout
    is_deeply [ body_lines(view($aoh, row_names => 'id', return_only => 1)) ],
              [ @b ], 'row_names alias matches row.names';

    # a column literally named row_name is auto-detected as the label
    my $rn = [ { row_name => 'r1', v => 1 } ];
    like view($rn, return_only => 1), qr/^row_name\b/m,
        'auto-detects row_name as the label column';
}

# undef cells render as the na token (default and custom)
{
    my $aoh = [ { a => 1, b => undef } ];
    like view($aoh, return_only => 1),            qr/\bNA\b/, 'default na token';
    like view($aoh, na => '.', return_only => 1), qr/(?:^|\s)\.(?:\s|$)/m,
        'custom na token';
}

# truncation: cells wider than max_width are clipped to width with ellipsis
{
    my $aoh = [ { a => 'abcdefghij' } ];           # 10 chars
    my $s = view($aoh, max_width => 5, return_only => 1);
    like $s, qr/ab\.\.\./, 'max_width truncates with default ellipsis (2 kept + ...)';

    my $s2 = view($aoh, max_width => 6, ellipsis => '~', return_only => 1);
    like $s2, qr/abcde~/, 'custom ellipsis honoured';
}

# control characters inside a cell are escaped so a record stays on one line
{
    my $aoh = [ { a => "x\ty\nz\r" } ];
    my $s = view($aoh, return_only => 1);
    like $s, qr/x\\ty\\nz\\r/, 'tab/newline/CR escaped';
    is scalar(body_lines($s)), 2, 'escaped record stays a single line';
}

# alignment: numeric columns right-justified, string columns left-justified,
# which means every body line ends up the same width.
{
    my $aoh = [ { num => 5, str => 'x' }, { num => 1000, str => 'yyy' } ];
    my $s = view($aoh, return_only => 1);
    my @b = body_lines($s);
    my %len = map { length($_) => 1 } @b;
    is scalar(keys %len), 1, 'all body lines share one fixed width';
    like $s, qr/\s5\b/,    'short numeric value is right-padded (leading space)';
    like $s, qr/\bx\s/,    'short string value is left-padded (trailing space)';
}

# a non-hash element in an AoH is treated as an empty row (defensive)
{
    my $aoh = [ { a => 1 }, 'not-a-hash' ];
    my $s = view($aoh, return_only => 1);
    like $s, qr/showing 2/, 'bad row counted';
    my @b = body_lines($s);
    like $b[2], qr/NA/, 'bad row rendered as all-NA';
}

# to => FILEHANDLE prints there and still returns the string;
# return_only prints nothing.
{
    my $aoh = [ { a => 1 } ];

    my $captured = '';
    open my $fh, '>', \$captured or die $!;
    my $ret = view($aoh, to => $fh);
    close $fh;
    ok length($captured),       'to => FH writes to the handle';
    is $ret, $captured,         'returned string equals what was printed';

    # return_only suppresses printing; capture STDOUT to prove it.
    my $out = '';
    {
        open my $old, '>&', \*STDOUT or die $!;
        close STDOUT;
        open STDOUT, '>', \$out or die $!;
        my $r = view($aoh, return_only => 1);
        open STDOUT, '>&', $old or die $!;
        ok length($r),  'return_only still returns the string';
    }
    is $out, '', 'return_only prints nothing to STDOUT';
}

# ---------------------------------------------------------------------------
# Hash of arrays (HoA)
# ---------------------------------------------------------------------------
{
    my $hoa = { a => [1, 2, 3], b => [4, 5, 6] };
    my $s = view($hoa, return_only => 1);
    like $s, qr/^# HoA: 3 rows x 2 cols/, 'HoA banner';
    my @b = body_lines($s);
    is scalar(@b), 4, 'HoA header + 3 rows';
    like $b[1], qr/\b1\b.*\b4\b/, 'HoA gathers columns by row index';

    # ragged columns: total = longest, missing cells become NA
    my $rag = { a => [1, 2, 3], b => [9] };
    my $rs = view($rag, return_only => 1);
    like $rs, qr/3 rows/, 'HoA total is the longest column';
    like $rs, qr/NA/,     'short column padded with NA';

    # a value that is not an array ref contributes nothing / renders NA.
    # Use undef (skipped when sampling the kind) so the table stays HoA.
    my $mixed = { a => [1, 2], b => undef };
    my $ms = view($mixed, return_only => 1);
    like $ms, qr/2 rows/, 'non-array column ignored for length';
    like $ms, qr/NA/,     'non-array column cells are NA';

    # label column for HoA
    my $lab = { id => ['r1', 'r2'], v => [10, 20] };
    like view($lab, 'row.names' => 'id', return_only => 1),
         qr/^id\b/m, 'HoA row.names label header';

    # cols subset
    like view($hoa, cols => ['b'], return_only => 1),
         qr/x 1 col\b/, 'HoA cols restricts (singular col)';
}

# ---------------------------------------------------------------------------
# Hash of hashes (HoH)
# ---------------------------------------------------------------------------
{
    my $hoh = {
        alice => { score => 97, grade => 'A' },
        bob   => { score => 84, grade => 'B' },
    };
    my $s = view($hoh, return_only => 1);
    like $s, qr/^# HoH: 2 rows x 2 cols/, 'HoH banner';
    my @b = body_lines($s);
    like $b[0], qr/^row_name\b/, 'HoH default label header is row_name';
    like $s, qr/\balice\b/, 'outer key alice is a row label';
    like $s, qr/\bbob\b/,   'outer key bob is a row label';
    like $b[0], qr/grade.*score/, 'HoH inner keys sorted as columns';

    # explicit row.names changes the label header text
    like view($hoh, 'row.names' => 'name', return_only => 1),
         qr/^name\b/m, 'HoH row.names sets label header';

    # row_names alias must also set the header (documented bug fix)
    like view($hoh, row_names => 'name', return_only => 1),
         qr/^name\b/m, 'HoH row_names alias sets label header';

    # n limiting + footer (HoH rows are sorted by key)
    my $lim = view($hoh, n => 1, return_only => 1);
    like $lim, qr/showing 1/,             'HoH n limits rows';
    like $lim, qr/# \.\.\. 1 more row\b/, 'HoH footer';
    like $lim, qr/\balice\b/, 'HoH shows the first key by sort order';

    # an inner row that is not a hash ref is treated as empty. The undef
    # value is skipped when sampling the kind, so the table stays HoH (a
    # defined hashref decides it) and the undef row falls back to {} -> NA.
    my $bad = { real => { x => 1 }, ghost => undef };
    my $bs = view($bad, return_only => 1);
    like $bs, qr/2 rows/, 'HoH counts the non-hash row';
    like $bs, qr/NA/,     'HoH non-hash inner row rendered NA';

    # cols subset
    like view($hoh, cols => ['score'], return_only => 1),
         qr/x 1 col\b/, 'HoH cols restricts';
}

# ---------------------------------------------------------------------------
# Empty + flat-hash special cases
# ---------------------------------------------------------------------------
{
    like view([], return_only => 1), qr/^# AoH: 0 rows x 0 cols  \(showing 0\)/,
        'empty AoH banner';
    like view({}, return_only => 1), qr/^# Hash: 0 rows x 0 cols/,
        'empty hash banner (no longer dies)';

    # flat hash: one row, keys as columns, numeric "1" row label
    my $flat = { a => 1, b => 2, c => 3 };
    my $s = view($flat, return_only => 1);
    like $s, qr/^# Hash: 1 row x 3 cols/, 'flat hash: single row, keys as cols';
    my @b = body_lines($s);
    like $b[0], qr/a .* b .* c/x, 'flat hash header lists sorted keys';
    like $b[1], qr/\b1\b.*\b2\b.*\b3\b/, 'flat hash values in one row';
}

# ---------------------------------------------------------------------------
# Error handling
# ---------------------------------------------------------------------------
{
    eval { view([{a=>1}], n => 1, rows => 1) };
    like $@, qr/either 'n' or 'rows'/, 'die: n and rows together';

    eval { view([{a=>1}], n => -1) };
    like $@, qr/non-negative integer/, 'die: negative n';

    eval { view([{a=>1}], n => 'two') };
    like $@, qr/non-negative integer/, 'die: non-integer n';

    eval { view([{a=>1}], bogus => 1) };
    like $@, qr/unknown argument\(s\): bogus/, 'die: unknown argument';

    eval { view('scalar') };
    like $@, qr/expected an ARRAY .* or HASH/, 'die: non-reference';

    eval { view(\my $x) };
    like $@, qr/expected an ARRAY .* or HASH/, 'die: wrong reference type';
}

done_testing;
