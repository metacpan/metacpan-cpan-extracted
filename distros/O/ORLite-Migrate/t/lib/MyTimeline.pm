package t::lib::MyTimeline;

use strict;
use warnings;
use ORLite::Migrate::Timeline ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.09';
	@ISA     = 'ORLite::Migrate::Timeline';
}

sub upgrade1 {
	$_[0]->do($_) foreach split /;\s+/, <<'END_SQL';

create table foo (
	id integer not null primary key,
	name varchar(32) not null
);

insert into foo values ( 1, 'foo' )

END_SQL
	return 1;
}

sub upgrade2 {
	shift->do("insert into foo values ( 2, 'bar' )");
}

sub upgrade3 {
	shift->do("insert into foo values ( 3, 'baz' )");
}

1;
