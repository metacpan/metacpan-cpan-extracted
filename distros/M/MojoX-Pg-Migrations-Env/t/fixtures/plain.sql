-- Text before the first marker is not part of any migration
-- 1 up
create table a (id serial primary key, price text default '$5', note text default '$WHO ${1} ${} ${WHO');
-- 1 down
drop table a;

-- 2 up
create function add_tax(numeric) returns numeric as $$
  select $1 * 1.25;
$$ language sql;
create function label(text) returns text as $body$
begin
  return '$' || $1 || '$$';
end;
$body$ language plpgsql;
-- 2 down
drop function label(text);
drop function add_tax(numeric);

-- 10 up
insert into a (note) values ('ten comes after two');
