-- 1 up
create table if not exists posts (
  id    integer primary key autoincrement,
  title text,
  body  text
);

-- 1 down
drop table if exists posts;

-- 2 up

create table if not exists groups (
  id    integer primary key autoincrement,
  name varchar(30),
  description  varchar(200)
);

create table if not exists users (
  id    integer primary key autoincrement,
  group_id int(11) NOT NULL references groups(id),
  username varchar(20),
  name varchar(30),
  about TEXT NOT NULL
);

-- 2 down
drop table if exists groups;
drop table if exists users;

