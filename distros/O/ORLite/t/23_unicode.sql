create table foo (
    foo_id integer not null primary key,
    one integer not null,
    two real not null,
    name text not null unique,
    text text not null
);

insert into foo (one, two, name, text) values ( 1, 1.23, 'smiley', '☺');
