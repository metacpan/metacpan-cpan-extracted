
alter table account
  add column email varchar(64);

create index i__login on account (login);

alter table account
  alter column status drop default,
  alter column status drop not null
;
