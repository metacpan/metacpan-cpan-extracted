#!/usr/bin/env perl 
use 5.8.0;
use strict;
use warnings;

use NetSDS::DBI;
use NetSDS::DBI::Table;

use Data::Dumper;

my $db = NetSDS::DBI->new(
	dsn    => 'dbi:Pg:dbname=test_netsds;host=192.168.1.50;port=5432',
	login  => 'netsds',
	passwd => '',
);

#print Dumper($db);

#print Dumper($db->dbh->selectrow_hashref("select md5('sdasd')"));
#print $db->call("select md5(?)", 'zuka')->fetchrow_hashref->{md5};

#print Dumper($db->call('select * from auth.groups where $1 @> array[id]', [2,6])->fetchall_hashref("id"));

my $tbl = NetSDS::DBI::Table->new(
	dsn    => 'dbi:Pg:dbname=test_netsds;host=192.168.1.50;port=5432',
	login  => 'netsds',
	passwd => '',
	table  => 'auth.users',
);

#print $tbl->insert_row(
#	login => 'vasya',
#	password => 'zzz',
#);

#my @uids =  $tbl->insert(
#	{ login => 'masha', password => 'zzz', },
#	{ login => 'lena', password => 'zzz', active => 'false' },
#);
#
#print "Inserted: " . join (', ', @uids) . "\n";

$tbl->update(
	filter => ["login = 'misha'"],
	set => {
		active => 'false',
	}
);

$tbl->update_row(2, active => 'true');

my @res = $tbl->fetch(
	fields => [ 'login', 'id',         'active as act' ],
	#filter => [ 'active = true', 'expire > now()' ],
	order  => ['login'],
);

warn Dumper( \@res );

1;
