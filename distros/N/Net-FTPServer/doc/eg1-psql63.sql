-- Database schema which goes with the DBeg1 backend.
-- By Richard W.M. Jones.

-- Create an example SQL database. This database supports hierarchical
-- file storage and multiple users. It currently lacks quotas, permissions,
-- timestamps and other high-end features (all of these features and more
-- have, however, been implemented in the schoolmaster.net database, so
-- they are possible with a little work).

-- To run:
--
--  createdb ftp
--  psql ftp < eg1.sql
--
-- This will DELETE any existing data in your FTP database file store!!

-- This version should work with Postgres 6.3.

-- Remove any old tables, indexes, sequences, etc.

drop sequence files_id_seq;
drop index files_id_key;

drop index files_name_idx;

drop sequence directories_id_seq;
drop index directories_id_key;

drop index directories_name_idx;

drop sequence users_id_seq;
drop index users_id_key;

drop index users_username_idx;

drop table files;
drop table directories;
drop table users;

-- Create new tables.

create sequence files_id_seq;

create table files
(
	-- id serial,
	id int4 default nextval ('files_id_seq'),
	dir_id int4 not null,   -- references directories ( id ),
	name text not null,
	content oid
);

create unique index files_id_key on files ( id );

create unique index files_name_idx on files ( dir_id, name );

create sequence directories_id_seq;

create table directories
(
	-- id serial,
	id int4 default nextval ('directories_id_seq'),
	parent_id int4,	-- references directories ( id ),
	name text not null
);

create unique index directories_id_key on directories ( id );

create unique index directories_name_idx on directories ( parent_id, name );

create sequence users_id_seq;

create table users
(
	-- id serial,
	id int4 default nextval ('users_id_seq'),
	username text not null,
	password text		-- crypted password
);

create unique index users_id_key on users ( id );

create unique index users_username_idx on users ( username );

-- Insert some test data.

-- My password is '123456'.
insert into users ( username, password ) values ( 'rich', 'MpU8yRWrKoWKc' );
insert into users ( username, password ) values ( 'dan', 'MpU8yRWrKoWKc' );

-- Root directory.
insert into directories ( name ) values ( '' );

-- Top level directories.
insert into directories ( name, parent_id ) values ( 'Home', 1 );
insert into directories ( name, parent_id ) values ( 'Website', 1 );
insert into directories ( name, parent_id ) values ( 'Private', 1 );
insert into directories ( name, parent_id ) values ( 'Test', 1 );
