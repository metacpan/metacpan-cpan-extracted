#!/usr/bin/perl

use Class::Easy;

#BEGIN {
#	use Class::Easy;
#	$Class::Easy::DEBUG = 'immediately';
#}

use Test::More qw(no_plan);
use DBI;

use Project::Easy::Helper;
use IO::Easy::File;

my $schema_file = IO::Easy::File->new ("schema.sql");

unlink 'db.sqlite';

my $dbh = DBI->connect ("dbi:SQLite:db.sqlite");

$schema_file->store ("some shit--- 2009-10-29
create table var (var_name text, var_value text);
create table test (test_id int, test_text text);

--- 2009-10-30
create table test2 (test2_id int, test2_text text);

--- 2009-10-30.1
drop table test2;
create table test2 (test2_id int, test2_text text);

");

ok ! eval {Project::Easy::Helper::update_schema (
	schema_file => $schema_file,
	dbh => $dbh,
	mode => 'install'
);};

$schema_file->store ("--- 2009-10-29
create table var (var_name text, var_value text);
create table test (test_id int, test_text text);

--- 2009-10-30
some shit;
create table test2 (test2_id int, test2_text text);

--- 2009-10-30.1
drop table test2;
create table test2 (test2_id int, test2_text text);

");

ok ! Project::Easy::Helper::update_schema (
	schema_file => $schema_file,
	dbh => $dbh,
	mode => 'install'
);

my $sth = $dbh->prepare ('select var_value from var where var_name = ?');
ok $sth->execute ('db_schema_version');
my $schema_version = $sth->fetchrow_arrayref->[0];

ok $schema_version eq '2009-10-29', 'check for commit after each successful stage';

eval {$sth->finish};
$dbh->disconnect;

ok unlink 'db.sqlite';



$dbh = DBI->connect ("dbi:SQLite:db.sqlite");

$schema_file->store ("--- 2009-10-29
create table var (var_name text, var_value text);
create table test (test_id int, test_text text);

--- 2009-10-30
create table test2 (test2_id int, test2_text text);

--- 2009-10-30.1
drop table test2;
create table test2 (test2_id int, test2_text text);

");

ok Project::Easy::Helper::update_schema (
	schema_file => $schema_file,
	dbh => $dbh,
	mode => 'install'
);

# we can't install database two times (in most cases)
ok !Project::Easy::Helper::update_schema (
	schema_file => $schema_file,
	dbh => $dbh,
	mode => 'install'
);


$schema_file->store ("--- 2009-10-29
create table var (var_name text, var_value text);
create table test (test_id int, test_text text);

--- 2009-10-30
create table test2 (test2_id int, test2_text text);

--- 2009-10-30.1
drop table test2;
create table test2 (test2_id int, test2_text text);

--- 2009-10-30.2
drop table test2;
create table test3 (test3_id int, test3_text text);

");

ok Project::Easy::Helper::update_schema (
	schema_file => $schema_file,
	dbh => $dbh
);

unlink $schema_file;

unlink 'db.sqlite';

1;
