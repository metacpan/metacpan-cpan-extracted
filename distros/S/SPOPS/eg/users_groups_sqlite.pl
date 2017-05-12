#!/usr/bin/perl

use strict;
use DBI;
use Log::Log4perl;
Log::Log4perl::init( 'log4perl.conf' );

my $DB_FILE = 'sqlite_test.db';
if ( -f $DB_FILE ) {
    warn "Removing old database file...\n";
    unlink( $DB_FILE );
}

my $dbh = DBI->connect( "DBI:SQLite:dbname=$DB_FILE",
                        '', '', { AutoCommit => 1 } )
                    || die "Cannot connect: $DBI::errstr";
$dbh->{RaiseError} = 1;
my $user = <<USER;
CREATE TABLE spops_user (
 user_id       integer not null,
 login_name    varchar(25) not null,
 password      varchar(30) not null,
 first_name    varchar(50),
 last_name     varchar(50),
 email         varchar(100) not null,
 notes         text,
 primary key   ( user_id ),
 unique        ( login_name )
)
USER

my $group = <<GROUP;
CREATE TABLE spops_group (
 group_id      integer not null,
 name          varchar(30) not null,
 notes         text,
 primary key   ( group_id )
)
GROUP

my $groupuser = <<GROUPUSER;
CREATE TABLE spops_group_user (
 group_id      int not null,
 user_id       int not null,
 primary key   ( group_id, user_id )
)
GROUPUSER


my $security = <<SECURITY;
CREATE TABLE spops_security (
 sid            integer not null,
 class          varchar(60) not null,
 object_id      varchar(150) default '0',
 scope          char(1) not null,
 scope_id       varchar(20) default 'world',
 security_level char(1) not null,
 unique         ( object_id, class, scope, scope_id ),
 primary key    ( sid )
)
SECURITY


my $doodad = <<DOODAD;
CREATE TABLE spops_doodad (
 doodad_id      integer not null,
 name           varchar(100) not null,
 description    text,
 unit_cost      numeric(10,2) default 0,
 factory        varchar(50) not null,
 created_by     int not null,
 unique         ( name ),
 primary key    ( doodad_id )
)
DOODAD

$dbh->do( $user );
$dbh->do( $group );
$dbh->do( $groupuser );
$dbh->do( $security );
$dbh->do( $doodad );
$dbh->disconnect();
