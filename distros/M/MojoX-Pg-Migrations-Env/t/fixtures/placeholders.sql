-- 1 up
create table notes (id serial primary key, note text);
insert into notes (note) values ('up 1 as ${ENV_TEST_WHO:-nobody}');
-- 1 down
drop table notes;

-- 2 up
create function greet(text) returns text as $$
  select '${ENV_TEST_GREETING:-hello} ' || $1;
$$ language sql;
insert into notes (note) values ('up 2 for ${ENV_TEST_WHO}');
-- 2 down
drop function greet(text);
insert into notes (note) values ('down 2 for ${ENV_TEST_WHO}, literally $${ENV_TEST_WHO}');
