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

-- This works with Postgres 6.4. Not tested on other platforms.

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

create table files
(
	id serial,
	dir_id int4 not null references directories ( id ),
	name text not null,
	content oid
);

create unique index files_name_idx on files ( dir_id, name );

create table directories
(
	id serial,
	parent_id int4 references directories ( id ),
	name text not null
);

create unique index directories_name_idx on directories ( parent_id, name );

create table users
(
	id serial,
	username text not null,
	password text		-- crypted password
);

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
