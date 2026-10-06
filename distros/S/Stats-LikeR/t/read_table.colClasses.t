#!/usr/bin/env perl
#
# read_table's colClasses: the perl-side surface, hand-written.  The cases R and
# pandas pin are in t/read_table.colClasses.R.pandas.t.
#
# A declared column is converted as the parser cuts each field
# (S_push_cell() in LikeR.xs), or, with a filter, once the filters have run
# (S_filter_row()); and by the perl row closure for any row it stores, through
# the same C converter (_cell_class).  Every case is read through the parser
# and, with the private '_closure' argument, through the closure, and the two
# must agree.  No R or Python reference applies to the call forms, messages
# and option checks, which are read_table's own.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Config;
use B ();
use File::Temp ();
use File::Spec;
use Stats::LikeR qw(read_table write_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
sub fixture {
	my ($text, $ext) = @_;
	my $path = File::Spec->catfile($dir, 'c' . $n++ . ($ext // '.csv'));
	open my $fh, '>', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot write $path: $!";
	return $path;
}
sub kind {
	my ($ref) = @_;
	my $f = B::svref_2object($ref)->FLAGS;
	return $f & B::SVf_POK ? 'PV' : $f & B::SVf_NOK ? 'NV' : $f & B::SVf_IOK ? 'IV' : 'undef';
}
# a table's every cell as [value, kind], so the two paths can be compared on
# what each cell is as well as on what it holds
sub typed {
	my ($t) = @_;
	my $r = ref $t;
	return [ map { typed($_) } @$t ] if $r eq 'ARRAY' && grep { ref } @$t;
	return { map { $_ => (ref $t->{$_} ? typed($t->{$_}) : [ $t->{$_}, kind(\$t->{$_}) ]) } keys %$t } if $r eq 'HASH';
	return [ map { [ $t->[$_], kind(\$t->[$_]) ] } 0 .. $#$t ] if $r eq 'ARRAY';
	return $t;
}
sub both {
	my ($file, %opt) = @_;
	my %got;
	for my $way ('parser', 'closure') {
		my @w;
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		my $r = eval { read_table($file, %opt, ($way eq 'closure' ? (_closure => 1) : ())) };
		$got{$way} = { r => $r, err => $@, warn => \@w };
	}
	return \%got;
}
sub same {
	my ($g, $name) = @_;
	is_deeply(typed($g->{parser}{r}), typed($g->{closure}{r}), "$name: same cells, of the same kind, both ways");
	is($g->{parser}{err}, $g->{closure}{err}, "$name: same error both ways");
	is_deeply($g->{parser}{warn}, $g->{closure}{warn}, "$name: same warnings both ways");
}

my $csv = fixture(join "\n", 'id,x,n,s', '004,1.5,7,a', '2, -2e3 ,-8,b', '3,,9,', '5,Inf,+10,"q,r"', '');

# --- every shape, both paths --------------------------------------------------
my %want = (
	id => [ [4, 'IV'], [2, 'IV'], [3, 'IV'], [5, 'IV'] ],
	x  => [ [1.5, 'NV'], [-2000, 'NV'], [undef, 'undef'], [9**9**9, 'NV'] ],
	n  => [ [7, 'IV'], [-8, 'IV'], [9, 'IV'], [10, 'IV'] ],
	s  => [ ['a', 'PV'], ['b', 'PV'], [undef, 'undef'], ['q,r', 'PV'] ],
);
for my $shape (qw(aoh hoa hoh aoa)) {
	my $g = both($csv, 'output_type' => $shape, colClasses => { id => 'integer', x => 'numeric', n => 'integer' });
	same($g, $shape);
	my $r = $g->{parser}{r};
	for my $c (qw(id x n s)) {
		next if $shape eq 'hoh' && $c eq 'id';
		my $j = { id => 0, x => 1, n => 2, s => 3 }->{$c};
		my @cells = $shape eq 'aoh' ? map { \$_->{$c} } @$r
		          : $shape eq 'hoa' ? map { \$_ } @{ $r->{$c} }
		          : $shape eq 'hoh' ? map { \$r->{$_}{$c} } 4, 2, 3, 5	# file order
		          : map { \$_->[$j] } @{$r}[1 .. $#$r];
		is_deeply([ map { [ $$_, kind($_) ] } @cells ], $want{$c}, "$shape: column $c");
	}
	is_deeply([ sort keys %$r ], [2, 3, 4, 5], 'hoh: a declared row name keys the row as its number ("004" is 4)')
		if $shape eq 'hoh';
}

# --- the spellings ---------------------------------------------------------------
{
	my $f = fixture("a,b,c\n1,2,3\n");
	is_deeply(typed(read_table($f, colClasses => 'numeric')),
	          [ { a => [1, 'NV'], b => [2, 'NV'], c => [3, 'NV'] } ], 'one class for every column');
	is_deeply(typed(read_table($f, colClasses => ['integer', undef])),
	          [ { a => [1, 'IV'], b => [2, 'PV'], c => [3, 'IV'] } ], 'a short list is recycled, undef leaving a column as read');
	is_deeply(typed(read_table($f, colClasses => [qw(double real character)])),
	          [ { a => [1, 'NV'], b => [2, 'NV'], c => [3, 'PV'] } ], "'double' and 'real' are 'numeric', as R maps them");
	eval { read_table($f, colClasses => [qw(numeric numeric numeric numeric)]) };
	like($@, qr/^read_table: 'colClasses' has 4 entries for the 3 columns of \S+$/, 'a list longer than the columns is refused');
	eval { read_table($f, colClasses => []) };
	is($@, "read_table: 'colClasses' is an empty list\n", 'an empty list is refused');
	eval { read_table($f, colClasses => \'numeric') };
	is($@, "read_table: 'colClasses' must be a string, an ARRAY reference or a HASH reference\n", 'a scalar reference is refused');
	eval { read_table($f, colClasses => { a => 'logical' }) };
	is($@, "read_table: colClasses 'logical' is not one read_table reads: it takes 'numeric' (or 'double' or 'real'), 'integer', 'character' or undef\n",
	   'a class R has and read_table does not is refused, by name');
	eval { read_table($f, colClasses => [undef, 'factor']) };
	like($@, qr/^read_table: colClasses 'factor'/, 'a bad class anywhere in the list is refused');
	my $u = fixture("\xd0\xb6\n1\n");
	is(kind(\read_table($u, colClasses => { "\x{436}" => 'integer' })->[0]{"\xd0\xb6"}), 'IV',
	   'a name given as characters matches the header\'s UTF-8 bytes, as a filter key does');
}

# --- what is a number --------------------------------------------------------------
{
	my @ok = (
		['1.', 1], ['.5', 0.5], ['-0.5e-3', -0.0005], ['1E5', 100000], [' 7 ', 7], ['+3', 3],
		['00012', 12], ['1e+2', 100],
		['Inf', 9**9**9], ['-inf', -9**9**9], ['+INFINITY', 9**9**9], [' Infinity ', 9**9**9],
	);
	for my $c (@ok) {
		my $r = read_table(fixture("x\n\"$c->[0]\"\n"), colClasses => 'numeric');
		is($r->[0]{x}, $c->[1], "numeric: '$c->[0]'");
	}
	for my $t ('nan', ' NaN', '-NaN') {
		my $v = read_table(fixture("x\n\"$t\"\n"), colClasses => 'numeric')->[0]{x};
		ok($v != $v, "numeric: '$t' is NaN");
	}
	for my $t ('abc', '1.5.2', '1,5', '--1', 'Infinit', 'nanx', '1e5x', '.', '+', 'e5', '1 2', "1\t2") {
		my $g = both(fixture("x\n\"$t\"\n"), colClasses => 'numeric');
		same($g, "numeric '$t'");
		like($g->{parser}{err}, qr/^read_table: colClasses makes column 'x' \(field 1\) numeric, but data row 1 of \S+ has '\Q$t\E' there$/,
		     "numeric: '$t' is refused, saying where");
	}
	my @iok = (['0', 0], ['-0', 0], ['+12', 12], [' 3', 3], ['0042', 42]);
	for my $c (@iok) {
		my $r = read_table(fixture("x\n\"$c->[0]\"\n"), colClasses => 'integer');
		is($r->[0]{x}, $c->[1], "integer: '$c->[0]'");
		is(kind(\$r->[0]{x}), 'IV', "integer: '$c->[0]' is an IV");
	}
	for my $t ('1.0', '1e3', '0x10', ' ', '3 ', 'Inf', 'NaN', '1_000') {
		my $g = both(fixture("x,y\n1,\"$t\"\n"), colClasses => [undef, 'integer']);
		same($g, "integer '$t'");
		if ($t eq ' ') {	# a blank is not empty: R's isNAstring() only takes ""
			like($g->{parser}{err}, qr/has ' ' there/, 'integer: a lone blank is refused, not missing');
			next;
		}
		like($g->{parser}{err}, qr/^read_table: colClasses makes column 'y' \(field 2\) integer, but data row 1 of \S+ has '\Q$t\E' there$/,
		     "integer: '$t' is refused");
	}
	my ($max, $min) = $Config{ivsize} >= 8
		? ('9223372036854775807', '-9223372036854775808') : ('2147483647', '-2147483648');
	my $r = read_table(fixture("x\n$max\n$min\n"), 'output_type' => 'hoa', colClasses => 'integer');
	is_deeply([ map { "$_" } @{ $r->{x} } ], [$max, $min], "integer: IV_MAX and IV_MIN ($Config{ivsize}-byte IV)");
	(my $over = $max) =~ s/7$/8/;
	eval { read_table(fixture("x\n$over\n"), colClasses => 'integer') };
	like($@, qr/has '$over' there/, 'integer: one past IV_MAX is refused');
	(my $under = $min) =~ s/8$/9/;
	eval { read_table(fixture("x\n$under\n"), colClasses => 'integer') };
	like($@, qr/has '$under' there/, 'integer: one past IV_MIN is refused');
}

# --- a separator that could continue the number -----------------------------------
# A field the parser cuts from the line is converted in place, and up to 0.3213
# Atof() read on past its end into the separator and the next field: with sep
# '.' the field "1" of "1.2" became 1.2, with sep 'E' the "1" of "1E2" became
# 100. The closure converts the field as an SV of its own, which is what the
# parser must agree with; R's read.table refuses a sep that is its dec, so
# there is no reference beyond that. The long number takes the copy past the
# 64-byte stack buffer onto the heap.
{
	my $long = '1.' . ('0' x 100) . '1';
	for my $c (['.', "1.2\n3.25\n", [1, 3]], ['E', "1E2\n-7E0\n", [1, -7]], ['e', "1e3\n2e+4\n", [1, 2]],
	           ['5', "152\n-0.25\n", [1, -0.2]], ['E', "${long}E9\n", [$long + 0]]) {
		my ($sep, $data, $want) = @$c;
		my $g = both(fixture("a${sep}b\n$data"), sep => $sep, 'output_type' => 'hoa', colClasses => { a => 'numeric' });
		same($g, "sep '$sep': $data");
		is_deeply($g->{parser}{r}{a}, $want, "sep '$sep': the number stops where its field does");
	}
}

# --- missing values ---------------------------------------------------------------
{
	my $f = fixture("x,y\n,NA\nNA,\n.,1\n");
	my $g = both($f, 'na_strings' => ['NA', '.'], colClasses => 'integer', 'output_type' => 'hoa');
	same($g, 'na_strings');
	is_deeply($g->{parser}{r}, { x => [undef, undef, undef], y => [undef, undef, 1] },
	          'an empty field and an na_strings token are undef in a declared column');
}

# --- the row the error is on, across quoted and multi-line fields -------------------
{
	my $f = fixture(qq{x,y\n1,"2"\n3,"multi\nline"\n});
	my $g = both($f, colClasses => [undef, 'integer']);
	same($g, 'a quoted, multi-line bad field');
	like($g->{parser}{err}, qr/data row 2 of \S+ has 'multi\nline' there$/, 'the bad field is reported as assembled, on its data row');
}

# --- with a filter: filters see the text, the stored row is converted --------------
{
	my $f = fixture("id,v\n007,1.50\n8,2\n");
	my @seen;
	my $g = both($f, colClasses => 'numeric',
		filter => { id => sub { push @seen, $_; $_ eq '007' || $_ == 8 } });
	same($g, 'filter');
	is_deeply([ @seen[0, 1] ], ['007', '8'], 'a filter sees the field\'s text, as it does without colClasses');
	is_deeply(typed($g->{parser}{r}), [ { id => [7, 'NV'], v => [1.5, 'NV'] }, { id => [8, 'NV'], v => [2, 'NV'] } ],
	          'the rows it keeps are stored converted');
	$g = both($f, colClasses => { v => 'integer' }, filter => { v => sub { $_ = $_ * 2; 1 } });
	same($g, 'filter writes a number back');
	is_deeply(typed($g->{parser}{r}), [ { id => ['007', 'PV'], v => [3, 'IV'] }, { id => ['8', 'PV'], v => [4, 'IV'] } ],
	          'a number a filter writes back is stored as the class asks, when it is one');
	$g = both($f, colClasses => { v => 'numeric' }, filter => { v => sub { $_ = 'none' if $_ == 2; 1 } });
	same($g, 'filter writes text back');
	like($g->{parser}{err}, qr/^read_table: colClasses makes column 'v' \(field 2\) numeric, but data row 2 of \S+ has 'none' there$/,
	     'text a filter writes back into a declared column is refused like text read');
	for my $shape (qw(hoa hoh aoa)) {
		$g = both($f, 'output_type' => $shape, colClasses => 'integer', filter => { 0 => sub { 1 } });
		same($g, "filter, $shape");
	}
}

# --- an .xlsx ------------------------------------------------------------------------
{
	my $x = File::Spec->catfile($dir, 'c.xlsx');
	{
		local *STDOUT;
		open STDOUT, '>', File::Spec->devnull or die;
		write_table([ { k => 'a', v => '1.25' }, { k => 'b', v => '' }, { k => 'c', v => '-3' } ], $x);
	}
	for my $shape (qw(aoh hoa hoh aoa)) {
		my $g = both($x, 'output_type' => $shape, colClasses => { v => 'numeric' });
		same($g, "xlsx $shape");
	}
	is_deeply(typed(read_table($x, 'output_type' => 'hoa', colClasses => { v => 'numeric' })->{v}),
	          [ [1.25, 'NV'], [undef, 'undef'], [-3, 'NV'] ], 'xlsx: a declared column is converted');
}

# --- no leaks -----------------------------------------------------------------------
SKIP: {
	skip 'Test::LeakTrace is not installed', 8 unless eval { require Test::LeakTrace; 1 };
	skip 'under Devel::Cover', 8 if $INC{'Devel/Cover.pm'};
	my $bad = fixture("a,b\n1,2\n3,x\n");
	for my $shape (qw(aoh hoa hoh aoa)) {
		Test::LeakTrace::no_leaks_ok(sub {
			read_table($csv, 'output_type' => $shape, colClasses => { id => 'integer', x => 'numeric' });
			eval { read_table($bad, 'output_type' => $shape, colClasses => 'integer') };
			eval { read_table($bad, 'output_type' => $shape, colClasses => 'integer', filter => { a => sub { 1 } }) };
		}, "$shape: a read with colClasses, and one that croaks on a bad cell, leak nothing");
	}
	# An .xlsx's cells are converted by S_fast_row(), where a CSV's are
	# converted as they are cut; up to 0.3213 an aoh's row hash was made before
	# that conversion and leaked when it croaked.
	my $xbad = File::Spec->catfile($dir, 'bad.xlsx');
	{
		local *STDOUT;
		open STDOUT, '>', File::Spec->devnull or die;
		write_table([ { a => '1', b => 'x' }, { a => 'zz', b => 'y' } ], $xbad);
	}
	for my $shape (qw(aoh hoa hoh aoa)) {
		Test::LeakTrace::no_leaks_ok(sub {
			eval { read_table($xbad, 'output_type' => $shape, colClasses => { a => 'integer' },
			                  ($shape eq 'hoh' ? ('row_names' => 'b') : ())) };
		}, "xlsx $shape: a read that croaks on a bad cell leaks nothing");
	}
}

done_testing();
