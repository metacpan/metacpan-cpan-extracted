create table table_one (
	col1 integer not null,
	col2 integer not null,
	col3 string,
	primary key ('col1', 'col2')
);

insert into table_one ( col1, col2, col3 ) values ( 1, 1, 'a' );
insert into table_one ( col1, col2, col3 ) values ( 1, 2, 'b' );
insert into table_one ( col1, col2, col3 ) values ( 1, 3, 'c' );
insert into table_one ( col1, col2, col3 ) values ( 2, 1, 'd' );
insert into table_one ( col1, col2, col3 ) values ( 2, 2, 'e' );
insert into table_one ( col1, col2, col3 ) values ( 2, 3, 'f' );
insert into table_one ( col1, col2, col3 ) values ( 3, 1, 'g' );
insert into table_one ( col1, col2, col3 ) values ( 3, 2, 'h' );
insert into table_one ( col1, col2, col3 ) values ( 3, 3, 'i' );

