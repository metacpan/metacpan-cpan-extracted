BEGIN;

CREATE TABLE bar (
    id serial primary key,
    name text not null default '',
    rank text not null default '',
    sn   text not null default ''
);

COMMIT;
