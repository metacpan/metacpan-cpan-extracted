use strict;
use warnings;

use Test::More;
use Parse::SQL;

my @case_list = (
	q{select 1} => [ [ 'select', [1] ] ],
	q{select 23} => [ [ 'select', [23] ] ],
	q{select 23 from tbl} => [ [ 'select', [23], 'from', 'tbl' ] ],
	q{select 23 from tbl t} => [ [ 'select', [23], 'from', 'tbl', 't' ] ],
	q{select idauthor from tbl} => [ [ 'select', ['idauthor'], 'from', 'tbl' ] ],
	q{select idauthor, title from tbl} => [ [ 'select', ['idauthor', 'title'], 'from', 'tbl' ] ],
	q{select idauthor, title from tbl where name like 'something'} => [ [ 'select', ['idauthor', 'title'], 'from', 'tbl', 'where', [ [ 'name', 'like', 'something' ] ] ] ],
	q{
select		idauthor,
		title
from		some_table
where		name
like		'something%'
} => [ [ 'select', ['idauthor', 'title'], 'from', 'some_table', 'where', [ [ 'name', 'like', 'something%' ] ] ] ],
	q{
select		idauthor,
		title
from		some_table st
inner join	other_table ot
on		st.idauthor = ot.idauthor
where		name
like		'something%'
} => [ [
	select => ['idauthor', 'title'],
	from => 'some_table', 'st', [
		qw(inner join) => qw(other_table ot),
		on => [ 'st.idauthor', '=', 'ot.idauthor' ]
	],
	where => [
		[ 'name', 'like', 'something%' ]
	]
]
],
q{
select		idauthor,
		title
from		some_table st
inner join	other_table ot
on		st.idauthor = ot.idauthor
left join	left_table lt
on		st.idx = lt.idx
full outer join fo_table fot
on		st.idx = fot.idx
cross join	cross_table ct
where		name
like		'something%'
} => [ [
	select => ['idauthor', 'title'],
	from => 'some_table', 'st', [
		qw(inner join) => qw(other_table ot),
		on => [ 'st.idauthor', '=', 'ot.idauthor' ]
	], [
		qw(left join) => qw(left_table lt),
		on => [ 'st.idx', '=', 'lt.idx' ]
	], [
		qw(full outer join) => qw(fo_table fot),
		on => [ 'st.idx', '=', 'fot.idx' ]
	], [
		qw(cross join) => qw(cross_table ct),
	],
	where => [
		[ 'name', 'like', 'something%' ]
	]
]
],q{
select		idauthor,
		title
from		some_table st
inner join	other_table ot
on		st.idauthor = ot.idauthor
left join	left_table lt
on		st.idx = lt.idx
full outer join fo_table fot
on		st.idx = fot.idx
cross join	cross_table ct
where		name
like		'something%'
} => [ [
	select => ['idauthor', 'title'],
	from => 'some_table', 'st', [
		qw(inner join) => qw(other_table ot),
		on => [ 'st.idauthor', '=', 'ot.idauthor' ]
	], [
		qw(left join) => qw(left_table lt),
		on => [ 'st.idx', '=', 'lt.idx' ]
	], [
		qw(full outer join) => qw(fo_table fot),
		on => [ 'st.idx', '=', 'fot.idx' ]
	], [
		qw(cross join) => qw(cross_table ct),
	],
	where => [
		[ 'name', 'like', 'something%' ]
	]
]
]
);
plan tests => scalar(@case_list)/2;

my $parser = Parse::SQL->new;
while(@case_list) {
	my ($sql, $expected) = splice @case_list, 0, 2;
	my $tree = $parser->from_string($sql);
	$sql =~ s/^\s+//g;
	$sql =~ s/\s+$//g;
	$sql =~ s/\s+/ /g;
	is_deeply($tree, $expected, 'tree matches for ' . $sql) or note explain $tree;
}

