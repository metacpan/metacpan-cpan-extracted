#!/usr/bin/env perl
#
# read_table's filter, run by the parser (S_filter_row() in LikeR.xs) and by
# the perl row closure, must be the same filter.
#
# Up to 0.3212 every row of a filtered read went through read_table's perl
# closure, which built %line_hash and called the subs; since 0.3213 the parser
# calls them itself, for every row after the one that fixes the header, and
# only that row and any before it still go through the closure.  The closure
# is therefore kept as the reference: the private '_closure' argument keeps
# every row in it, and each case below is read both ways and must come back
# the same -- result, the values each filter saw, and the warnings.  Each case
# also pins its answer outright, so that the two cannot agree on a wrong one.
#
# What is held to, in the closure's own terms:
#   - %line_hash: the row by name, a repeated name's value from its last field,
#     an empty field or an na_strings token undef;
#   - per filter, in key order: local *_ = \%line_hash; local $_ = the field's
#     value (the row's arrayref for key 0); $sub->(\@row, \%line_hash) in
#     scalar context; then $row[$fld - 1] = $_ and, when the field is the one
#     its name resolves to, the same into %line_hash;
#   - $_[0] holds '' for an empty field;
#   - a row, a %line_hash or a value a filter keeps a reference to is its own.
#
# No R or Python reference applies: this is read_table's own option, and the
# closure is its specification.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec;
use Scalar::Util qw(refaddr);
use Stats::LikeR qw(read_table write_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub fixture {
	my ($name, $text) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, '>', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot write $path: $!";
	return $path;
}

# "name" is repeated: field 2 and field 4, the second of which %line_hash keeps.
# read_table warns about that on every read of this file; nothing else may warn.
$SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^read_table: duplicate column name\(s\)/ };
my $csv = fixture('f.csv', join '', map { "$_\n" }
	'id,name,age,name,note',
	'1,ann,30,A1,',
	'2,,45,B2,NA',
	'3,cat,,C3,x',
	'4,dan,50,,y');

# Read $file both ways with the same options; $mk builds a fresh filter hash
# and the probe it records into, so the two reads do not share state.
sub both {
	my ($file, $mk, %opt) = @_;
	my %got;
	for my $way ('parser', 'closure') {
		my (@seen, @warn);
		local $SIG{__WARN__} = sub { push @warn, $_[0] };
		my $r = eval { read_table($file, %opt, filter => $mk->(\@seen),
			($way eq 'closure' ? (_closure => 1) : ())) };
		$got{$way} = { r => $r, err => $@, seen => \@seen, warn => \@warn };
	}
	return \%got;
}

sub same_both_ways {
	my ($g, $name) = @_;
	is_deeply($g->{parser}{r},    $g->{closure}{r},    "$name: same result both ways");
	is_deeply($g->{parser}{seen}, $g->{closure}{seen}, "$name: the filters saw the same both ways");
	is_deeply($g->{parser}{warn}, $g->{closure}{warn}, "$name: same warnings both ways");
	is($g->{parser}{err}, $g->{closure}{err}, "$name: same error both ways");
	is($g->{parser}{err}, '', "$name: no error") unless $g->{expect_err};
}

my @shapes = (aoh => [], hoa => [], hoh => [], aoa => []);
my %ids = (
	aoh => sub { [ map { $_->{id} } @{ $_[0] } ] },
	hoa => sub { $_[0]{id} },
	hoh => sub { [ sort keys %{ $_[0] } ] },
	aoa => sub { my @r = @{ $_[0] }; shift @r; [ map { $_->[0] } @r ] },
);

# --- which rows are kept, and what $_ is --------------------------------------
for my $shape (qw(aoh hoa hoh aoa)) {
	my $g = both($csv, sub { my $s = shift;
		{ age => sub { push @$s, $_; defined $_ && $_ > 35 } } },
		'output_type' => $shape);
	same_both_ways($g, "$shape, age > 35");
	is_deeply($ids{$shape}->($g->{parser}{r}), [2, 4], "$shape, age > 35: rows 2 and 4");
	is_deeply($g->{parser}{seen}, [30, 45, undef, 50], "$shape: an empty field is undef as \$_");
}

# --- an na_strings token is undef as $_, and $_[0] holds '' for an empty field
{
	my $g = both($csv, sub { my $s = shift;
		{ 0 => sub { push @$s, [ @{ $_[0] } ]; 1 }, note => sub { push @$s, $_; 1 } } },
		'na_strings' => 'NA');
	same_both_ways($g, 'row and note');
	is_deeply($g->{parser}{seen}[0], ['1', 'ann', '30', 'A1', ''], '$_[0] holds an empty field as ""');
	is_deeply([ @{ $g->{parser}{seen} }[1, 3] ], [undef, undef], 'an empty note and an "NA" note are both undef as $_');
	is_deeply($g->{parser}{seen}[2], ['2', '', '45', 'B2', 'NA'], '$_[0] holds the na_strings token as it is');
}

# --- writing $_ back ------------------------------------------------------------
for my $shape (qw(aoh hoa hoh aoa)) {
	my $g = both($csv, sub {
		{ note => sub { $_ = uc($_ // 'none'); 1 }, age => sub { $_ = '' if defined $_ && $_ == 45; 1 } } },
		'output_type' => $shape, 'na_strings' => 'NA');
	same_both_ways($g, "$shape, write-back");
	my $r = $g->{parser}{r};
	my @note = $shape eq 'aoh' ? map { $_->{note} } @$r
	         : $shape eq 'hoa' ? @{ $r->{note} }
	         : $shape eq 'hoh' ? map { $r->{$_}{note} } sort keys %$r
	         : map { $_->[4] } @{$r}[1 .. $#$r];
	is_deeply(\@note, ['NONE', 'NONE', 'X', 'Y'], "$shape: \$_ written back is what is stored");
	my @age = $shape eq 'aoh' ? map { $_->{age} } @$r
	        : $shape eq 'hoa' ? @{ $r->{age} }
	        : $shape eq 'hoh' ? map { $r->{$_}{age} } sort keys %$r
	        : map { $_->[2] } @{$r}[1 .. $#$r];
	is_deeply(\@age, [30, undef, undef, 50], "$shape: '' written back is stored as undef");
}

# --- two filters on one field: key order, and the second sees the first's $_
{
	my $g = both($csv, sub { my $s = shift;
		{ 3 => sub { $_ = ($_ // 0) + 1; 1 }, age => sub { push @$s, $_; $_ *= 2; 1 } } });
	same_both_ways($g, 'two filters on age');
	is_deeply($g->{parser}{seen}, [31, 46, 1, 51], 'filter "3" runs before filter "age", which sees its $_');
	is_deeply([ map { $_->{age} } @{ $g->{parser}{r} } ], [62, 92, 2, 102], 'and both write back');
}

# --- a repeated name: the earlier field has its own $_ and its own write-back
for my $shape (qw(aoh aoa)) {
	my $g = both($csv, sub { my $s = shift;
		{ 2 => sub { push @$s, [2, $_]; $_ = 'zz'; 1 }, name => sub { push @$s, [4, $_]; 1 } } },
		'output_type' => $shape);
	same_both_ways($g, "$shape, repeated name");
	is_deeply($g->{parser}{seen}[0], [2, 'ann'], "$shape: field 2's filter sees field 2");
	is_deeply($g->{parser}{seen}[1], [4, 'A1'],  "$shape: the name's filter sees field 4, the one the name keeps");
	my $r = $g->{parser}{r};
	if ($shape eq 'aoh') {
		is_deeply([ map { $_->{name} } @$r ], ['A1', 'B2', 'C3', undef],
		          'aoh: writing field 2 back leaves the name with field 4');
	} else {
		is_deeply([ map { $_->[1] } @{$r}[1 .. 4] ], [('zz') x 4], 'aoa: field 2 is written back');
	}
}

# --- %_ and $_[1] are %line_hash, and what a filter does to it is kept --------
for my $shape (qw(aoh hoa hoh aoa)) {
	my $g = both($csv, sub {
		{ id => sub { $_[1]{age} = 99 if $_ == 3; $_{note} = "n$_"; 1 } } },
		'output_type' => $shape);
	same_both_ways($g, "$shape, %_ and \$_[1]");
	next if $shape eq 'aoa';	# built from the row, not from %line_hash
	my $r = $g->{parser}{r};
	my $row3 = $shape eq 'aoh' ? $r->[2] : $shape eq 'hoh' ? $r->{3}
	         : { map { $_ => $r->{$_}[2] } keys %$r };
	is($row3->{age}, 99, "$shape: a change through \$_[1] is stored");
	is($row3->{note}, 'n3', "$shape: a change through %_ is stored");
}

# --- references a filter keeps are its own -----------------------------------
for my $shape (qw(aoh aoa)) {
	my (@rows, @hashes);
	my $r = read_table($csv, 'output_type' => $shape,
		filter => { 0 => sub { push @rows, $_[0]; push @hashes, $_[1]; 1 } });
	is_deeply([ map { [ @$_ ] } @rows ],
	          [ [1, 'ann', 30, 'A1', ''], [2, '', 45, 'B2', 'NA'], [3, 'cat', '', 'C3', 'x'], [4, 'dan', 50, '', 'y'] ],
	          "$shape: every kept \$_[0] is its own row, as it was cut");
	is_deeply([ map { $_->{id} } @hashes ], [1 .. 4], "$shape: every kept \$_[1] is its own hash");
	if ($shape eq 'aoh') {
		is(refaddr($hashes[1]), refaddr($r->[1]), 'aoh: the stored row is %line_hash itself, as in the closure');
	}
	if ($shape eq 'aoa') {
		$rows[0][0] = 'changed';
		is($r->[1][0], 1, 'aoa: a row a filter kept is not the stored row');
	}
}
{
	my @vals;
	my $r = read_table($csv, 'output_type' => 'hoa',
		filter => { id => sub { push @vals, \$_[1]{age}; 1 } });
	${ $vals[0] } = 'changed';
	is($r->{age}[0], 30, 'hoa: a %line_hash value a filter took a reference to is copied, not shared');
}

# --- what a filter returns -----------------------------------------------------
{
	my $g = both($csv, sub { { id => sub { return if $_ == 2; return () if $_ == 3; (0, 1) } } });
	same_both_ways($g, 'return values');
	is_deeply([ map { $_->{id} } @{ $g->{parser}{r} } ], [1, 4],
	          'an empty return drops the row, and a list is taken in scalar context');
}

# --- a filter that dies --------------------------------------------------------
{
	for my $way ([], [_closure => 1]) {
		eval { read_table($csv, @$way, filter => { id => sub { die "stop at $_\n" if $_ == 3; 1 } }) };
		is($@, "stop at 3\n", 'a filter\'s die comes through' . (@$way ? ' (closure)' : ''));
	}
}

# --- $_ and %_ are the caller's again afterwards -------------------------------
{
	local $_ = 'outer';
	local %_ = (k => 1);
	my $seen_inner;
	read_table($csv, filter => { id => sub { $seen_inner //= $_{name}; 1 } });
	is($_, 'outer', '$_ is the caller\'s after a filtered read');
	is_deeply(\%_, { k => 1 }, '%_ is the caller\'s after a filtered read');
	is($seen_inner, 'A1', 'and inside a filter %_ was the row');
}

# --- a filter that gives *_ a new glob -----------------------------------------
{
	our %other = (z => 1);
	my $r = read_table($csv, filter => { id => sub { no warnings 'once'; *_ = *other if $_ == 2; 1 } });
	is(scalar @$r, 4, 'a filter that replaces *_ does not take the read down');
}

# --- a filter that is not code -------------------------------------------------
{
	eval { read_table($csv, filter => { age => 'x' }) };
	is($@, "read_table: filter 'age' must be a CODE reference\n", 'a filter that is not code is refused up front');
}

# --- a hoh's row names come from %line_hash after the filters ------------------
{
	my $g = both($csv, sub { { id => sub { $_ = "r$_"; 1 } } }, 'output_type' => 'hoh');
	same_both_ways($g, 'hoh row names written back');
	is_deeply([ sort keys %{ $g->{parser}{r} } ], [qw(r1 r2 r3 r4)], 'hoh: a written-back row name keys the row');
	$g = both($csv, sub { { id => sub { $_ = 'same'; 1 } } }, 'output_type' => 'hoh');
	same_both_ways($g, 'hoh row names made the same');
	is_deeply([ keys %{ $g->{parser}{r} } ], ['same'], 'hoh: one row under a repeated name');
	is($g->{parser}{r}{same}{age}, 50, 'hoh: the last row wins, as in the closure');
	is(scalar(grep { /row name|row's name/ } @{ $g->{parser}{warn} }), 1, 'hoh: one warning for the repeats');
	$g = both($csv, sub { { id => sub { $_ = undef if $_ == 2; 1 } } }, 'output_type' => 'hoh');
	$g->{expect_err} = 1;
	same_both_ways($g, 'hoh row name written back as undef');
	like($g->{parser}{err}, qr/^read_table: undefined row name \(column 'id'\) in \S+ data row 2$/,
	     'hoh: an undef row name dies, naming the row');
}

# --- rows the closure reads itself: auto_row_names, a commented header ---------
{
	my $rn = fixture('rn.csv', "a,b\nx,1,2\ny,3,4\nz,5,6\n");
	my $g = both($rn, sub { my $s = shift; { b => sub { push @$s, $_; $_ > 2 } } }, 'auto_row_names' => 1);
	same_both_ways($g, 'auto_row_names');
	is_deeply($g->{parser}{seen}, [2, 4, 6], 'auto_row_names: the first data row is filtered too');
	my $ch = fixture('ch.csv', "# a,b\n1,2\n3,4\n");
	$g = both($ch, sub { { a => sub { $_ > 1 } } });
	same_both_ways($g, 'commented header');
	is_deeply($g->{parser}{r}, [{ a => 3, b => 4 }], 'commented header: filtered');
}

# --- an .xlsx -----------------------------------------------------------------
{
	my $x = File::Spec->catfile($dir, 'f.xlsx');
	{
		local $SIG{__WARN__} = sub { };
		local *STDOUT;
		open STDOUT, '>', File::Spec->devnull or die;
		write_table([ { id => 1, v => 'p' }, { id => 2, v => '' }, { id => 3, v => 'q' } ], $x);
	}
	for my $shape (qw(aoh hoa hoh aoa)) {
		my $g = both($x, sub { my $s = shift;
			{ 0 => sub { push @$s, [ @{ $_[0] } ]; 1 }, v => sub { push @$s, $_; defined $_ } } },
			'output_type' => $shape);
		same_both_ways($g, "xlsx $shape");
		is_deeply($ids{$shape}->($g->{parser}{r}), [1, 3], "xlsx $shape: the empty cell's row is dropped");
	}
}

# --- no leaks ------------------------------------------------------------------
SKIP: {
	skip 'Test::LeakTrace is not installed', 4 unless eval { require Test::LeakTrace; 1 };
	skip 'under Devel::Cover', 4 if $INC{'Devel/Cover.pm'};
	for my $shape (qw(aoh hoa hoh aoa)) {
		Test::LeakTrace::no_leaks_ok(sub {
			read_table($csv, 'output_type' => $shape,
				filter => { 0 => sub { 1 }, age => sub { $_ = ($_ // 0) + 1; $_[1]{x} = 1; $_ > 40 } });
			eval { read_table($csv, 'output_type' => $shape, filter => { id => sub { die "x\n" if $_ == 2; 1 } }) };
		}, "$shape: a filtered read, and one whose filter dies, leak nothing");
	}
}

done_testing();
