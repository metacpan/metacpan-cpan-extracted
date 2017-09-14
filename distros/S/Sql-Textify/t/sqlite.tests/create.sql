/*
  conn="dbi:SQLite:dbname=tmp/samples.db"
*/
drop table if exists mytable;

create table mytable (
  id int,
  description text
);

insert into mytable values
(1, 'first row'),
(2, 'second row'),
(3, 'third row');