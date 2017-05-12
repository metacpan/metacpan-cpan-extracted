#!/usr/bin/perl

use strict;
use Test;
use DBI;
BEGIN { 
	plan tests => 12, todo => [3,4]
}
use MySQL::TableInfo;

ok(1); # success

my ($dbh, $db_name, $table, $login, $password);


print "Testing begins...\n\n"; sleep (1);
print "Test: your mysql login: [''] ";						chomp ( $login = <STDIN> );
print "Test: your mysql password: [''] ";					chomp ( $password = <STDIN> );
print "Test: insert a database name to work with: [test] "; chomp ( $db_name = <STDIN> );
$db_name ||= 'test';
print "Test: table to create: [table_info] ";				chomp ( $table = <STDIN> );
$table ||= 'table_info';

print "connecting to $db_name...";
$dbh = DBI->connect("DBI:mysql:$db_name", $login || undef, $password || undef, {RaiseError=>1, PrintError=>1});
ok(1);

print "createing table $table...";
$dbh->do("DROP TABLE IF EXISTS $table");
$dbh->do(qq/
    CREATE TABLE  $table (
        id INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
        set_col set('one', 'two', 'three') NOT NULL DEFAULT 'one',
        val VARCHAR(30) NULL)/);
ok(1);

print "Inserting rows...";
$dbh->do(qq/
	INSERT INTO $table 
		VALUES(NULL, 'one,two', NULL), (NULL, 'one', 'foo')/);
ok(1);

print "creating MySQL::TableInfo object...";

my $tbl = new MySQL::TableInfo($dbh, $table) or die ok(0);

ok(1);

ok($tbl->type('id'), 'int');
ok($tbl->size('val'), 30);
ok($tbl->type('set_col'), 'set');
ok($tbl->is_null('val'), 1);
ok($tbl->default('set_col'), 'one');
ok($tbl->set('set_col'), 3);
ok(($tbl->set('set_col'))[0], 'one');


