use strict;
use ORLite::Migrate::Patch;

# We need an extra column with information that doesn't currently exist.
# So first, drop the old cpan_file table.
do('DROP TABLE cpan_file');

# Create the new cpan file list
do(<<'END_SQL');
create table cpan_file (
	id        integer not null primary key,
	release   text    not null,
	file      text    not null,
	md5       text    not null,
	indexable integer not null
)
END_SQL

# Index the hell out of the cpan file list
do( 'create index cpan_file__release   on cpan_file ( release   )' );
do( 'create index cpan_file__file      on cpan_file ( file      )' );
do( 'create index cpan_file__md5       on cpan_file ( md5       )' );
do( 'create index cpan_file__indexable on cpan_file ( indexable )' );
