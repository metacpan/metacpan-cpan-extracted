create table table_one (
	col1 integer not null primary key,
	col2 string
);

insert into table_one ( col1, col2 ) values ( 1, 'a' );
insert into table_one ( col1, col2 ) values ( 2, 'b' );
insert into table_one ( col1, col2 ) values ( 3, null );
