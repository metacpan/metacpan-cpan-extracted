create table table_one (
	col1 integer not null primary key,
	col2 string
);

create table table_two (
	col1 integer not null primary key,
	col2 integer not null CONSTRAINT fk_table_two_col2 REFERENCES table_one(col1) ON DELETE CASCADE
);

insert into table_one ( col1, col2 ) values ( 1, 2 );

insert into table_two ( col1, col2 ) values ( 1, 1 )
