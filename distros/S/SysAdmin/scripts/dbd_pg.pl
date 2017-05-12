#!/usr/local/bin/perl
use strict;

use lib "/Users/migrivera/scripts/packages/SysAdmin-0.07/lib";

use SysAdmin::DB;

my $db = "dbd_test";
my $username = "dbd_test";
my $password = "dbd_test";
my $host = "localhost";
my $port = '5432';
my $driver = "Pg";

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

my $insert_table = qq(insert into status (description) values (?));

my $last_id = $dbd_object->insertData("$insert_table",["First"]);

print "Last ID $last_id\n";

my $fetch_last_insert = qq(select description 
	                   from status 
	                   where description = 'First');

my $insert_results = $dbd_object->fetchRow("$fetch_last_insert");

print "Last Insert: $insert_results\n";

my $update_table = qq(update status set description = ? where description = ?);

$dbd_object->updateData("$update_table",["Second","First"]);

my $fetch_last_update = qq(select description 
	                   from status 
	                   where description = 'Second');

my $update_results = $dbd_object->fetchRow("$fetch_last_update");

print "Last Update: $update_results\n";

