#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use File::Temp;
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
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

# write $content to a fresh temp file and return its path
sub tmp_csv {
	my ($content, $suffix) = @_;
	my $fh = File::Temp->new(SUFFIX => $suffix // '.csv', UNLINK => 1);
	print {$fh} $content;
	close $fh;
	return $fh->filename, $fh;	 # keep the object alive in the caller
}

#--------
# a comment line before the header is skipped (the reported bug)
#--------
{
	my ($f, $keep) = tmp_csv(<<'CSV');
# This is a comment
id,name,val
1,Alice,10.5
2,Bob,
3,Charlie,15.2
CSV
	my $r = read_table($f);
	is(scalar @$r, 3, 'three data rows parsed (comment not mistaken for a row)');
	is_deeply([sort keys %{ $r->[0] }], [qw(id name val)], 'header is id,name,val');
	is($r->[0]{name}, 'Alice', 'row 1 name');
	ok(!defined $r->[1]{val}, "row 2 (Bob) has undef for the empty val cell");
	is($r->[2]{val}, '15.2', 'row 3 val');
}

#--------
# a commented header (marker hugging content) is used as the header
#--------
{
	my ($f, $keep) = tmp_csv("#id,val\n\n   \n# a full comment line\n1,10\n2,20\n");
	is_deeply( read_table($f), [ { id => 1, val => 10 }, { id => 2, val => 20 } ],
		"a #-prefixed header has its marker stripped; blank/whitespace/comment lines skipped" );
}

#--------
# multiple leading comments, and a comment interspersed in the data
#--------
{
	my ($f, $keep) = tmp_csv(<<'CSV');
# comment one
# comment two
id,name,val
1,Alice,10.5
# mid-file comment
2,Bob,20
CSV
	my $r = read_table($f);
	is(scalar @$r, 2, 'leading and mid-file comments are all skipped');
	is($r->[1]{name}, 'Bob', 'data after a mid-file comment still parses');
}

#--------
# a file with no comment line still uses line 1 as the header
#--------
{
	my ($f, $keep) = tmp_csv("id,name\n1,Alice\n");
	my $r = read_table($f);
	is_deeply([sort keys %{ $r->[0] }], [qw(id name)], 'no-comment file: line 1 is the header');
	is($r->[0]{id}, '1', 'no-comment file: first row parsed');
}

#--------
# a comment marker INSIDE a quoted field is preserved (not treated as a comment)
#--------
{
	my ($f, $keep) = tmp_csv(<<'CSV');
id,name
1,"Charlie #3"
CSV
	my $r = read_table($f);
	is($r->[0]{name}, 'Charlie #3', 'a # inside a quoted field is kept verbatim');
}

#--------
# undef propagates through hoa and hoh outputs too
#--------
{
	my ($f, $keep) = tmp_csv(<<'CSV');
# header below
id,name,val
1,Alice,10.5
2,Bob,
CSV
	my $hoa = read_table($f, 'output.type' => 'hoa');
	ok(!defined $hoa->{val}[1], 'hoa: empty cell becomes undef');
	is($hoa->{name}[0], 'Alice', 'hoa: values intact');

	my $hoh = read_table($f, 'output.type' => 'hoh');
	ok(!defined $hoh->{'2'}{val}, 'hoh: empty cell becomes undef');
	is($hoh->{'1'}{name}, 'Alice', 'hoh: keyed by first column');
}

#--------
# a custom comment marker is honoured before the header
#--------
{
	my ($f, $keep) = tmp_csv("// note\nid,name\n1,Alice\n");
	my $r = read_table($f, comment => '//');
	is_deeply([sort keys %{ $r->[0] }], [qw(id name)], 'custom comment marker skipped before header');
}

#--------
# memory
#--------
my ($lf, $lkeep) = tmp_csv(<<'CSV');
# c
id,name,val
1,Alice,10.5
2,Bob,
CSV
no_leaks_ok {
	my $r = read_table($lf);
} 'read_table: no memory leaks parsing a commented file' unless $INC{'Devel/Cover.pm'};

done_testing;
