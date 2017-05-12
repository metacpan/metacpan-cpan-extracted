create table foo (
    fookey integer primary key,
    stuff varchar
);

create table foo_params (
    fookey integer references foo(fookey),
    name varchar,
    value varchar,
    primary key (fookey, name)
);

