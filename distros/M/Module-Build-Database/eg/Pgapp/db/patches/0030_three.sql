
create table three (
    foo int,
    bar int,
    baz varchar
);

comment on table three is 'this is the THREE table';
comment on column three.bar is 'this is the three.bar field';
comment on column three.baz is 'this is the bas field';

