create table one (
	firstname varchar2(255) not null,
	lastname varchar2(255) not null,
	age integer not null
);

create table two (
	two_id integer not null primary key,
	firstname varchar2(255) not null,
	lastname varchar2(255) not null,
	age integer not null
);

create table three (
	firstname varchar2(255) not null,
	lastname varchar2(255) not null,
	age integer not null,
	primary key ( firstname, lastname )
);

create view four as select * from one;

create view five as select * from two;

create view six as select * from three;

create table seven (
	name varchar2(255) not null primary key,
	age integer not null
);
