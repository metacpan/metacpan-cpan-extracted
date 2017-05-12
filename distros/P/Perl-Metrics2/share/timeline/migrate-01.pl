use strict;
use ORLite::Migrate::Patch;

# Create the file metric table
do(<<'END_SQL');
create table file_metric (
	id      integer not null primary key,
	md5     text    not null,
	package text    not null,
	version numeric,
	name    text    not null,
	value   text
)
END_SQL

# Index the hell out of the metric table
do( 'create index file_metric__md5     on file_metric ( md5     )' );
do( 'create index file_metric__package on file_metric ( package )' );
do( 'create index file_metric__version on file_metric ( version )' );
do( 'create index file_metric__name    on file_metric ( name    )' );
do( 'create index file_metric__value   on file_metric ( value   )' );
