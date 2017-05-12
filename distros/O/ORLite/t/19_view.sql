create table table_one (
	col1 integer not null primary key,
	col2 string
);

create view view_one as
select * from table_one;
