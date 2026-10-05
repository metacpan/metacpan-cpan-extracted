#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use File::Temp;
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# 1. Multi-character separators (the memcmp branch)
my $content = "col1||col2||col3\nval1||val2||val3";
my $fh = File::Temp->new(UNLINK => 1);
print $fh $content;
close $fh;
my $res = read_table($fh->filename, sep => '||');
is(scalar @$res, 1, 'Multi-char sep: correctly parsed 1 data row');
is($res->[0]{col2}, 'val2', 'Multi-char sep: correctly isolated middle column');

#
# 2. Mid-file comments
#
$content = <<'EOF';
# Header comment
a,b
1,2
# This comment occurs mid-file
3,4
EOF
$fh = File::Temp->new(UNLINK => 1);
print $fh $content;
close $fh;
$res = read_table($fh->filename, sep => ',');
is(scalar @$res, 2, 'Mid-file comment: parsed exactly 2 data rows');
is($res->[1]{a}, 3, 'Mid-file comment: skipped comment line and read next row');

#
# 3. Multi-line quoted field (NOT a bug -- the quotes are balanced).
#    "colA,colB" / "val1,\"val2" / "val3,\"unterminated_val" has TWO double
#    quotes, so colB is one RFC-4180 field spanning two physical lines. The
#    whole value lands in row 0; there is no row 1 and nothing is dropped.
#
$content = "colA,colB\nval1,\"val2\nval3,\"unterminated_val";
$fh = File::Temp->new(UNLINK => 1);
print $fh $content;
close $fh;
$res = read_table($fh->filename, sep => ',');
is(scalar @$res, 1, 'Multi-line quote: two physical lines form ONE record');
is($res->[0]{colA}, 'val1', 'Multi-line quote: first field intact');
is($res->[0]{colB}, "val2\nval3,unterminated_val",
	'Multi-line quote: embedded newline + post-quote text retained (no field dropped)');

#
# 4. A genuinely unterminated quote at EOF (ODD number of quotes): the trailing
#    record is flushed, so the final field is still emitted -- never dropped.
#    (The value picks up a trailing "\n" because the open quote ran to EOF; that
#    is a property of the malformed input, not a lost field.)
#
$content = "colA,colB\nval1,\"val2\nstill inside";   # one quote, never closed
$fh = File::Temp->new(UNLINK => 1);
print $fh $content;
close $fh;
$res = read_table($fh->filename, sep => ',');
is(scalar @$res, 1, 'Unterminated quote: trailing record flushed at EOF');
is($res->[0]{colA}, 'val1', 'Unterminated quote: first field intact');
like($res->[0]{colB}, qr/\Aval2\nstill inside/,
	'Unterminated quote: final field retained, not dropped');

#
# 5. Stray \r outside quotes is dropped (the parser's lenient design choice:
#    a lone \r is field-internal noise, not a record terminator).
#
my $stray = "colA,colB\nval1\r_stray,val2";
my $fh1 = File::Temp->new(UNLINK => 1);
binmode $fh1;
print $fh1 $stray;
close $fh1;
my $res1 = read_table($fh1->filename, sep => ',');
is($res1->[0]{colA}, 'val1_stray', 'Stray \r outside quotes is dropped (lenient)');

#
# 6. Classic-Mac (\r-only) line endings. Up to 0.3213 they were unsupported:
#    sv_gets() split on \n only, so the file was one line with its \r's dropped
#    as in test 5, and came back with no data rows. read_table now looks at the
#    start of the file, and one with a \r and no \n at all is split on \r
#    (_eol_is_cr() in LikeR.pm), as R's scan() and pandas' C tokenizer split it.
#    Test 5 is unaffected: a \r in a file that has \n line ends is still noise.
#    The reference cases are in t/read_table.cr_eol.R.pandas.t.
#
my $mac = "colA,colB\rval1,val2\rval3,val4";
my $fh2 = File::Temp->new(UNLINK => 1);
binmode $fh2;
print $fh2 $mac;
close $fh2;
my $res2 = read_table($fh2->filename, sep => ',');
is_deeply($res2, [ { colA => 'val1', colB => 'val2' }, { colA => 'val3', colB => 'val4' } ],
	'Classic-Mac \r-only file: split on \r');

done_testing();
