use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use File::Temp 'tempdir';
use Stats::LikeR;

my $dir = tempdir( CLEANUP => 1 );
my $n = 0;
sub spit {
	my ($content, $name) = @_;
	my $f = $name ? "$dir/$name" : sprintf( "$dir/t%02d.csv", ++$n );
	open my $fh, '>', $f or die "open $f: $!";
	print {$fh} $content;
	close $fh;
	return $f;
}

# ----------------------------------------------------------------------------
# basic parsing through read_table
# ----------------------------------------------------------------------------
{
	my $f = spit("a,b,c\n1,2,3\n4,5,6\n");
	my $aoh = read_table($f);
	is_deeply( $aoh,
		[ { a=>1, b=>2, c=>3 }, { a=>4, b=>5, c=>6 } ],
		'basic CSV -> aoh' );

	my $hoa = read_table($f, 'output.type' => 'hoa');
	is_deeply( $hoa, { a=>[1,4], b=>[2,5], c=>[3,6] }, 'basic CSV -> hoa' );

	my $hoh = read_table($f, 'output.type' => 'hoh', 'row.names' => 'a');
	is_deeply( $hoh, { 1 => { b=>2, c=>3 }, 4 => { b=>5, c=>6 } },
		'basic CSV -> hoh with explicit row.names' );
}

# .tsv extension selects tab
{
	my $f = spit("x\ty\n7\t8\n", 'auto.tsv');
	is_deeply( read_table($f), [ { x=>7, y=>8 } ], '.tsv auto-selects tab separator' );
}

# comments, blank lines, leading-comment header
{
	my $f = spit("#id,val\n\n   \n# a full comment line\n1,10\n2,20\n");
	my $aoh = read_table($f);
	is_deeply( $aoh, [ { id=>1, val=>10 }, { id=>2, val=>20 } ],
		'comment stripped from header; comment lines and blank lines skipped' );
}

# empty cells -> undef
{
	my $f = spit("a,b\n1,\n,2\n");
	is_deeply( read_table($f),
		[ { a=>1, b=>undef }, { a=>undef, b=>2 } ],
		'empty cells become undef' );
}

# ----------------------------------------------------------------------------
# quoting: embedded sep, escaped quotes, multiline, \r preservation
# ----------------------------------------------------------------------------
{
	my $f = spit(qq{a,b\n"x,y","p""q"\n});
	is_deeply( read_table($f),
		[ { a=>'x,y', b=>'p"q' } ],
		'quoted separator and doubled quote' );
}
{
	my $f = spit(qq{a,b\n"line1\nline2",2\n});
	is_deeply( read_table($f),
		[ { a=>"line1\nline2", b=>2 } ],
		'multiline quoted field' );
}
{
	# FIX under test: \r inside a quoted field must be preserved
	my $f = spit(qq{a,b\n"x\ry",2\n});
	is_deeply( read_table($f),
		[ { a=>"x\ry", b=>2 } ],
		'carriage return inside quotes is preserved' );
}
{
	# CRLF line endings outside quotes are still chomped
	my $f = spit("a,b\r\n1,2\r\n");
	is_deeply( read_table($f), [ { a=>1, b=>2 } ], 'CRLF endings chomped' );
}
{
	# a comment-looking line INSIDE a quoted field is content, not a comment
	my $f = spit(qq{a,b\n"start\n# not a comment\nend",2\n});
	is_deeply( read_table($f),
		[ { a=>"start\n# not a comment\nend", b=>2 } ],
		'comment chars inside a quoted multiline field are content' );
}

# round-trip with write_table (exercises both halves of the module)
{
	my $aoh = [
		{ s=>'plain', q=>'has"quote', m=>"two\nlines", c=>'a,b', r=>"x\ry", e=>undef },
	];
	my $f = "$dir/round.csv";
	write_table($aoh, $f, 'row.names' => 0);
	my $back = read_table($f);
	is_deeply( $back, $aoh, 'write_table -> read_table round-trip (quote, newline, sep, \r, undef)' );
}

# ----------------------------------------------------------------------------
# header edge cases
# ----------------------------------------------------------------------------
{
	my $f = spit(",a,b\nr1,1,2\n");
	my $hoh = read_table($f, 'output.type' => 'hoh');
	is_deeply( $hoh, { r1 => { a=>1, b=>2 } },
		'leading blank header -> row_name; hoh defaults row.names to it' );
}
{
	# duplicate column names: warn once; hoa columns stay rectangular (FIX)
	my $f = spit("a,b,a\n1,2,3\n4,5,6\n");
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	my $hoa = read_table($f, 'output.type' => 'hoa');
	is( scalar @w, 1, 'duplicate column warns once' );
	like( $w[0], qr/duplicate column name/, 'warning mentions duplicate columns' );
	is_deeply( $hoa, { a=>[3,6], b=>[2,5] },
		'hoa with duplicate header: later wins, columns equal length' );
}

# ----------------------------------------------------------------------------
# filters
# ----------------------------------------------------------------------------
{
	my $f = spit("name,age\nann,41\nbob,\ncat,33\n");
	# named-column filter, $_ is the normalized (undef-for-empty) value
	my $r = read_table($f, filter => { age => sub { defined $_ } });
	is_deeply( $r, [ { name=>'ann', age=>41 }, { name=>'cat', age=>33 } ],
		'named filter sees normalized $_ (undef row removed)' );

	# numeric key (1-based)
	$r = read_table($f, filter => { 2 => sub { defined $_ && $_ > 35 } });
	is_deeply( $r, [ { name=>'ann', age=>41 } ], 'numeric filter key (1-based column)' );

	# bare CODE ref == whole-row filter; gets $line_ref in $_ and as arg
	$r = read_table($f, filter => sub {
		ref $_ eq 'ARRAY' && ref $_[0] eq 'ARRAY' && ref $_[1] eq 'HASH'
			&& defined $_[1]{age} && $_[1]{age} < 40
	});
	is_deeply( $r, [ { name=>'cat', age=>33 } ],
		'whole-row filter: $_ is the row aref; args are ($line_ref, \%line_hash)' );

	# %_ aliases the row hash (FIX: no per-row copy)
	$r = read_table($f, filter => { name => sub { defined $_{age} } });
	is_deeply( $r, [ { name=>'ann', age=>41 }, { name=>'cat', age=>33 } ],
		'%_ gives filters the whole row by column name' );

	# $_ mutation writes back, and a later filter sees it via %_
	$r = read_table($f, filter => {
		name => sub { $_ = uc $_; 1 },
		age  => sub { $_{name} eq uc $_{name} },   # proves write-back visible in %_
	});
	is_deeply( $r,
		[ { name=>'ANN', age=>41 }, { name=>'BOB', age=>undef }, { name=>'CAT', age=>33 } ],
		'$_ mutation written back and visible to later filters through %_' );
}

# ----------------------------------------------------------------------------
# error paths (messages + behavior)
# ----------------------------------------------------------------------------
{
	my $good = spit("a,b\n1,2\n");
	throws_ok { read_table("$dir/definitely-missing.csv") } qr/is not a file/,
		'missing file dies in the wrapper';
	throws_ok { read_table($good, 'output.type' => 'xxx') } qr/isn't allowed/,
		'bad output.type dies';
	throws_ok { read_table($good, bogus => 1) } qr/\bbogus\b/,
		'unknown argument dies and names the argument';
	throws_ok { read_table($good, sep => ',', delim => ',') } qr/not both/,
		'sep + delim together die';
	throws_ok { read_table($good, filter => \'x') } qr/CODE or HASH/,
		'bad filter type dies';
	throws_ok { read_table($good, filter => { ghost => sub { 1 } }) }
		qr/Filter column 'ghost' not found/, 'unknown filter column dies';
	throws_ok { read_table($good, filter => { 5 => sub { 1 } }) }
		qr/exceeds the 2 columns/, 'numeric filter key past last column dies';
	throws_ok { read_table($good, 'output.type' => 'hoh', 'row.names' => 'zz') }
		qr/isn't in the header/, 'row.names not in header dies';

	my $ragged = spit("a,b\n1,2\n1,2,3\n");
	throws_ok { read_table($ragged) } qr/Alignment error .* data row 2 \(3 fields vs 2 headers\)/,
		'alignment error reports the offending data row';

	my $undefrn = spit("id,v\n,9\n");
	throws_ok { read_table($undefrn, 'output.type' => 'hoh') }
		qr/undefined row name .* data row 1/,
		'hoh with an undef row-name cell dies instead of keying on ""';

	throws_ok { Stats::LikeR::_parse_csv_file($good, ',', '#', 'not a code ref') }
		qr/must be a CODE reference/,
		'XS: defined non-CODE callback croaks instead of silently slurping';
}

# ----------------------------------------------------------------------------
# direct XS slurp mode
# ----------------------------------------------------------------------------
{
	my $f = spit("a,b\n1,2\n");
	my $rows = Stats::LikeR::_parse_csv_file($f, ',', '#');
	is_deeply( $rows, [ ['a','b'], ['1','2'] ], 'slurp mode returns AoA of raw fields' );
}

# ----------------------------------------------------------------------------
# leaks: the headline fixes
# ----------------------------------------------------------------------------
SKIP: {
	skip 'leak tests skipped under Devel::Cover', 5 if $INC{'Devel/Cover.pm'};
	my $good   = spit("a,b\n1,2\n3,4\n");
	my $ragged = spit("a,b\n1,2\n1,2,3\n");

	no_leaks_ok { my $r = read_table($good); }
		'no leaks: normal read_table';
	no_leaks_ok { my $r = Stats::LikeR::_parse_csv_file($good, ',', '#'); }
		'no leaks: XS slurp mode';
	no_leaks_ok {
		eval { read_table($ragged) };
	} 'no leaks when the callback dies mid-file (alignment error)';
	no_leaks_ok {
		eval { Stats::LikeR::_parse_csv_file("$dir/nope.csv", ',', '#') };
	} 'no leaks when the open fails';
	no_leaks_ok {
		eval { read_table($good, filter => { a => sub { die "boom\n" } }) };
	} 'no leaks when a filter dies';
}

done_testing();
