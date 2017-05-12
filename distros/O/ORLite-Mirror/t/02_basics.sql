create table table_one (
	col1 integer not null primary key,
	col2 string
);

insert into table_one ( col1, col2 ) values ( 1, 'foo' );

insert into table_one ( col2 ) values ( 'bar' );

insert into table_one ( col2 ) values ( 'bar' );

pragma user_version = 7;
