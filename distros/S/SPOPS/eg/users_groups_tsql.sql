CREATE TABLE spops_user (
 user_id       numeric(10,0) identity not null,
 login_name    varchar(25) not null,
 password      varchar(30) not null,
 first_name    varchar(50) null,
 last_name     varchar(50) null,
 email         varchar(100) not null,
 notes         text null,
 primary key   ( user_id ),
 unique        ( login_name )
);


CREATE TABLE spops_group (
 group_id      numeric(10,0) identity not null,
 name          varchar(30) not null,
 notes         text null,
 primary key   ( group_id )
);


CREATE TABLE spops_group_user (
 group_id      numeric(10,0) not null,
 user_id       numeric(10,0) not null,
 primary key   ( group_id, user_id )
);


CREATE TABLE spops_security (
 sid            numeric(10,0) identity not null,
 class          varchar(60) not null,
 object_id      varchar(150) default '0',
 scope          char(1) not null,
 scope_id       varchar(20) default 'world',
 security_level char(1) not null,
 primary key    ( sid ),
 unique         ( object_id, class, scope, scope_id )
);


CREATE TABLE spops_doodad (
 doodad_id      numeric(10,0) identity not null,
 name           varchar(100) not null,
 description    text null,
 unit_cost      numeric(10,2) default 0,
 factory        varchar(50) not null,
 created_by     int not null,
 primary key    ( doodad_id ),
 unique         ( name )
);