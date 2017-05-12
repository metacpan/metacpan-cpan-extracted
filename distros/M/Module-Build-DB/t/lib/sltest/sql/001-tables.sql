BEGIN;

CREATE TABLE foo (
    id integer primary key,
    name text not null,
    rank text not null,
    sn   text not null
);

COMMIT;
