use strict;
use warnings;
use Test::More;

use String::SQLColumnName;

$\ = "\n"; $, = "\t"; 

my @col_defs = (
		"Some name",  'some_name',
		"1st date",   'first_date',
		"2nd field",  'second_field',
		'group',  'group_01',
		'sum',  'sum_',
		'count',  'count_',
		'distinct',  'distinct_',
		'one : two',  'one_two_01',
		'one, two, three',  'one_two_three_01',
		'one, two, three.',  'one_two_three_02',
		'one; two; three;;',  'one_two_three_03',
		'44 wives',  'forty_four_wives',
		'33ist', 'thirty_threeist',
		'33rd', 'thirty_third',
		'53rd and 1st', 'fifty_third_and_first',
		'one || two', 'one_two_02',
		'price * units * (1 - discount)', 'price_times_units_times_1_minus_discount',
		'group',  'group_02',
		'12 months',  'twelve_months',
		'52 weeks total',  'fifty_two_weeks_total',
		'1st unit', "first_unit",
		'2nd unit', "second_unit",
		'repeated', "repeated_01",
		'repeated', "repeated_02"
	       );

my (@cols_in, @cols_out);

while (@col_defs) {
    my ($in, $out) = splice @col_defs, 0, 2;
    push @cols_in, $in;
    push @cols_out, $out
}

is_deeply([ sql_column_names(@cols_in) ], \@cols_out, "all columns together");

use DBI;

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:','','');

for (@cols_out) {
    $dbh->do(sprintf "create table foo (%s varchar(12));", $_);

    my $sth = $dbh->column_info( undef, undef, 'foo', undef );
    $sth->execute;
    ok($sth->fetchall_arrayref->[0]->[3] eq $_, sprintf 'create col from %s => %s', shift @cols_in, $_);
    $dbh->do("drop table foo;");
}

my @all_cols = map { sprintf '%s varchar(12)', $_ } @cols_out;
my $ddl = sprintf sprintf "create table foo (%s);", (join ",\n", @all_cols);
$dbh->do($ddl);

my $sth = $dbh->column_info( undef, undef, 'foo', undef );
$sth->execute;
my @ddl_cols = map { $_->[3] } @{$sth->fetchall_arrayref};

is_deeply(\@cols_out, \@ddl_cols, "create table from all cols");

done_testing();
