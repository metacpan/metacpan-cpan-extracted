CREATE GENERATOR sp_user_seq;

CREATE TABLE spops_user (
 user_id       int not null,
 login_name    varchar(25) not null,
 user_password varchar(30) not null,
 first_name    varchar(50),
 last_name     varchar(50),
 email         varchar(100) not null,
 notes         blob,
 primary key   ( user_id ),
 unique        ( login_name )
);


CREATE GENERATOR sp_group_seq;

CREATE TABLE spops_group (
 group_id      int not null,
 name          varchar(30) not null,
 notes         blob,
 primary key   ( group_id )
);


CREATE TABLE spops_group_user (
 group_id      int not null,
 user_id       int not null,
 primary key   ( group_id, user_id )
);

CREATE GENERATOR sp_security_seq;

CREATE TABLE spops_security (
 sid            int not null,
 class          varchar(60) not null,
 object_id      varchar(150) default '0' not null,
 scope          char(1) not null,
 scope_id       varchar(20) default 'world' not null,
 security_level char(1) not null,
 primary key    ( sid )
);

CREATE GENERATOR sp_doodad_seq;

CREATE TABLE spops_doodad (
 doodad_id      int not null,
 name           varchar(100) not null,
 description    blob,
 unit_cost      numeric(10,2) default 0,
 factory        varchar(50) not null,
 created_by     int not null,
 primary key    ( doodad_id ),
 unique         ( name )
);
COMMIT;
