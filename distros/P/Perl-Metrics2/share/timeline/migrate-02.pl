use strict;
use ORLite::Migrate::Patch;

# Create the cpan file list
do(<<'END_SQL');
create table cpan_file (
	id   integer not null primary key,
	dist text    not null,
	file text    not null,
	md5  text    not null
)
END_SQL

# Index the hell out of the cpan file list
do( 'create index cpan_file__dist on cpan_file ( dist )' );
do( 'create index cpan_file__file on cpan_file ( file )' );
do( 'create index cpan_file__md5  on cpan_file ( md5  )' );
