
create table status (
  id   integer     not null primary key,
  name varchar(32) not null
);

alter table status
  add constraint name_unique unique (name);

insert into status (id, name) values
  (1, 'NEW'),
  (2, 'ENABLED'),
  (3, 'DISABLED')
;

create table account (
  id       serial       not null primary key,
  login    varchar(32)  not null unique,
  password varchar(32)  not null,
  status   integer      default 2
);

