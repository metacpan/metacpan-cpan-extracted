#!/usr/local/bin/perl
use strict;

use SysAdmin::DB;

my $db = "testdb";
my $username = "test_user";
my $password = "test_pass";
my $host = "localhost";
my $port = '1521';
my $driver = "Oracle";

=pod

create table status(
id serial primary key,
description varchar(25) not null);

=cut

my $dbd_object = new SysAdmin::DB(db          => $db,
                                  db_username => $username,
                                  db_password => $password,
                                  db_host     => $host,
                                  db_port     => $port,
                                  db_driver   => $driver);


my $select_table = qq(select id,description from status);

my $table_results = $dbd_object->fetchTable("$select_table");

foreach my $row (@$table_results) {

	my ($db_id,$db_description) = @$row;
	
	print "DB_ID $db_id, DB_DESCRIPTION $db_description\n";
	
}
