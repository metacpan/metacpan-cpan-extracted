#!/usr/bin/perl
#
## LICENSE AND COPYRIGHT
# 
## Copyright (C) Carlos Celso
# 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
# 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
#
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see L<http://www.gnu.org/licenses/>.
#

	use strict;
	use warnings;

	use Cwd;
	use File::Basename;
	use IO::File;
	use Test::More;

	our $VERSION = "2023.274.1";

	BEGIN{ use_ok('SQL::SimpleOps'); };

	my $dir = ($0 =~ /^(.*)\/(.*)/) ? $1 : "";
	$dir = getcwd()."/".$dir if (!($dir =~ /^\//));
	unshift(@INC,$dir);

################################################################################

	$ENV{SQL_SIMPLE_DB_TEST_CREATE_ALLOWED} = "" if (!defined$ENV{SQL_SIMPLE_DB_TEST_CREATE_ALLOWED});
	$ENV{SQL_SIMPLE_DB_TEST_SKIP_CREATE} = "" if (!defined$ENV{SQL_SIMPLE_DB_TEST_SKIP_CREATE});
	$ENV{SQL_SIMPLE_DB_SHOW_CREATE} = "" if (!defined$ENV{SQL_SIMPLE_DB_SHOW_CREATE});

	my $test=0;
	$test++ if ($ENV{SQL_SIMPLE_DB_TEST_CREATE_ALLOWED} eq "1");
	$test++ if ($ENV{SQL_SIMPLE_DB_TEST_SKIP_CREATE} eq "1");
	$test++ if ($ENV{SQL_SIMPLE_DB_SHOW_CREATE} eq "1");
	if ($test == 0)
	{
		diag("No type of test found");
		diag("See README.txt before doing any test");
		done_testing();
		exit;
	}
	if ($test != 1)
	{
		diag("Multiple test found, there can be only one");
		diag("See README.txt before doing any test");
		done_testing();
		exit;
	}

################################################################################

	## test sqlite if avail
	
	eval { require DBD::SQLite; };
	if (!$@)
	{
		require "$dir/testDB_sqlite.pm";
		&SQLite_do($dir);
	}
	else
	{
		diag($@);
		diag("DBD::SQLite not found, SQLite test skipped");
	}
	
	# test mysql/mariadb if avail
	
	eval { require DBD::mysql; };
	if (!$@)
	{
		require "$dir/testDB_mysql.pm";
		&MySQL_do($dir);
	}
	else
	{
		diag($@);
		diag("DBD::mysql not found, MySQL/MariaDB test skipped");
	}
	
	# test postgresql if avail
	
	eval { require DBD::Pg; };
	if (!$@)
	{
		require "$dir/testDB_postgres.pm";
		&PG_do($dir);
	}
	else
	{
		diag($@);
		diag("DBD::Pg not found, Postegres test skipped");
	}
	done_testing();
	exit;

################################################################################

sub testGeneric()
{
	my $dbh = shift;
	my $contents = shift;

	&testInitialize($dbh,$contents);

	&testGenericStandardInsert($dbh,$contents);
	&testGenericStandardSelect($dbh,$contents);

	&testGenericAutoincrementInsert($dbh,$contents);
	&testGenericAutoincrementSelect($dbh,$contents);
	&testGenericAutoincrementUpdate($dbh,$contents);
	&testGenericAutoincrementDelete($dbh,$contents);

	&testGenericMasterSlaveInsert($dbh,$contents);
	&testGenericMasterSlaveSelect($dbh,$contents);
	&testGenericMasterSlaveMerges($dbh,$contents);

	&testGenericBuffering($dbh,$contents);
	&testGenericSingles($dbh,$contents);

	$dbh->Close();
}

################################################################################

sub testInitialize()
{
	my $dbh = shift;
	my $contents = shift;
	my @tables = sort(keys(%{$contents}));

	## show environments if required

	if ($ENV{SQL_SIMPLE_DB_SHOW_CONTENTS})
	{
		diag("INI000 Contents and Tables");

		require Data::Dumper;
		print Data::Dumper->Dumper(\@tables,$contents);
	}

	diag("INI001 Removing previous data");

	foreach my $table (@tables)
	{
		$dbh->Delete ( table=>$table, force => 1, notfound => 1 );
		&testRC($dbh,"INI001",$table);
	}
}

################################################################################

sub testGenericMasterSlaveMerges()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer;

	note("MSM000 Merge");

	$dbh->Select
	(
		table => "my_master",
		fields => [ {"my_master.my_s_m_code"=>"ms"}, ],
		buffer => \@buffer,
	);
	&testRC($dbh,"MSM001","my_master");
	ok($dbh->getRows()==10,"MSM002 Aliases select-1, expected 10, found ".$dbh->getRows());

	$dbh->Select
	(
		table => [ "my_master","my_slave" ],
		fields => [ {"my_master.my_s_m_code"=>"ms"}, {"my_slave.my_s_s_code"=>"ss"}, ],
		buffer => \@buffer,
	);
	&testRC($dbh,"MSM003","my_master/my_slave");
	ok($dbh->getRows()==1000,"MSM004 Aliases select-2, expected 1000, found ".$dbh->getRows());
}

################################################################################

sub testGenericBuffering()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer_array;
	my %buffer_hash;
	my @keys = ("master_0000","master_0001","master_0002","master_0003","master_0004");

	note("BFF000 Buffering");

	## test buffer_arrayref

	$dbh->Select
	(
		table => "my_master",
		fields =>
		[
			{"s_m_code" => "code"}, 
		],
		where => [ "my_s_m_code" => \@keys ],
		buffer => \@buffer_array,
		buffer_arrayref => 0,
		notfound => 1,
		order_by => [ {"s_m_code" => "asc"} ],
	);
	&testRC($dbh,"BFF001","my_master");
	ok($dbh->getRows()==5,"BFF002 Buffer_arrayref, expected 5, found ".$dbh->getRows());
	(join(" ",@keys) eq join(" ",@buffer_array)) ? 
		pass("BFF003 Buffer_arrayref matched values") :
		fail("BFF004 Buffer_arrayref mismatch values");

	$dbh->Select
	(
		table => "my_master",
		fields =>
		[
			{"i_m_id" => "id"}, 
			{"s_m_code" => "code"}, 
			{"s_m_name" => "name"}, 
		],
		where => [ "my_s_m_code" => \@keys ],
		buffer => \%buffer_hash,
		buffer_hashkey => "code",
		notfound => 1,
	);
	&testRC($dbh,"BFF010","my_master");
	ok($dbh->getRows()==5,"BFF011 Buffer_hashkey, expected 5, found ".$dbh->getRows());

	note("BFF100 Buffering");

	my $ok1=1;
	foreach my $id(@keys)
	{
		if(!defined($buffer_hash{$id}))
		{
			fail("BFF101 buffer_hashkey 'code=$id' missing");
			$ok1=0;
			last;
		}
		my $no =%{$buffer_hash{$id}}+0;
		if ($no!=2)
		{
			fail("BFF102 Buffer_hashkey 'code=$id', expected 2 fields, found ".$no);
			$ok1=0;
			last;
		}
	}
	pass("BFF103 Buffer_hashkey indexed by single successful") if ($ok1);

	$dbh->Select
	(
		table => [ "my_master","my_slave" ],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where => [ "my_master.my_s_m_code" => \@keys, "my_master.my_s_m_code" => "my_slave.my_s_m_code" ],
		buffer => \%buffer_hash,
		buffer_hashkey => ["ms","ss"],
		notfound => 1,
	);
	&testRC($dbh,"BFF110","my_master/my_slave");

	my $a = @keys;
	my $b = %buffer_hash+0;
	my $ok2=1;
	if ($a==$b)
	{
LOOP1:		foreach my $key1(sort(keys(%buffer_hash)))
		{
			my $c = %{$buffer_hash{$key1}}+0;
			if ($c == 10)
			{
				foreach my $key2(sort(keys(%{$buffer_hash{$key1}})))
				{
					my $d = %{$buffer_hash{$key1}{$key2}}+0;
					if ($d!=2)
					{
						fail("BFF111 Buffer_hashkey key1 '$key1 with key2 '$key2', expected 2, found $d");
						$ok2=0;
						last LOOP;
					}
				}
			}
			else
			{
				fail("BFF112 Buffer_hashkey key1 '$key1', expected 10, found $c");
				$ok2=0;
				last LOOP;
			}
		}
	}
	else
	{
		fail("BFF113 Buffer_hashkey, expected $a, found $b");
		$ok2=0;
	}
	pass("BFF114 Buffer_hashkey indexed by array successful") if ($ok2);
}

################################################################################

sub testGenericSingles()
{
	my $dbh = shift;
	my $contents = shift;

	&testGenericSinglesTABLES($dbh,$contents);
	&testGneericSinglesFIELDS($dbh,$contents);
	&testGneericSinglesWHERE($dbh,$contents);
	&testGneericSinglesORDERBY($dbh,$contents);
	&testGneericSinglesGROUPBY($dbh,$contents);
}

################################################################################

sub testGneericSinglesGROUPBY()
{
	my $dbh = shift;
	my $contents = shift;

	my @buffer_array;
	my @groupby_array;
	my $groupby_arrayref;
my @orderby_array;
my $orderby_arrayref;
	note("SIG400 GroupBy, group_by => 'value'");
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
		group_by => "s_m_code",
	);
	&testRC($dbh,"SIG401","my_master");
	ok($dbh->getRows()==1,"SIG402 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG403 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG410 GroupBy, group_by => \$group_by, \$group_by => [ 'value' ]");
	$groupby_arrayref = [ "s_m_code" ];
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
		group_by => $groupby_arrayref,
	);
	&testRC($dbh,"SIG411","my_master");
	ok($dbh->getRows()==1,"SIG412 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG413 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG420 GroupBy, group_by => \@group_by, \@group_by => [ 'value' ]");
	@groupby_array = [ "s_m_code" ];
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
		group_by => @groupby_array,
	);
	&testRC($dbh,"SIG421","my_master");
	ok($dbh->getRows()==1,"SIG422 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG423 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG430 GroupBy, group_by => \@group_by, \@group_by => ( 'value' )");
	@groupby_array = ( "s_m_code" );
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
		group_by => \@groupby_array,
	);
	&testRC($dbh,"SIG431","my_master");
	ok($dbh->getRows()==1,"SIG432 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG433 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});
}

################################################################################

sub testGneericSinglesORDERBY()
{
	my $dbh = shift;
	my $contents = shift;

	my @buffer_array;
	my @orderby_array;
	my $orderby_arrayref;

	note("SIG300 OrderBy, order_by => [ 'value' ]");
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => [ "master_0000","master_0001" ] ],
		buffer => \@buffer_array,
		notfound => 1,
		order_by => [ {"my_s_m_code"=>"asc"}, ],
	);
	&testRC($dbh,"SIG201","my_master");
	ok($dbh->getRows()==2,"SIG202 Buffer expected 2, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000" && $buffer_array[1]->{s_m_code} eq "master_0001","SIG203 Buffer code expected 'master_0000', found 0:".$buffer_array[0]->{s_m_code}." 1:".$buffer_array[1]->{s_m_code});

	note("SIG310 OrderBy, order_by => \$order_by, \$order_by => [ 'value' ]");
	$orderby_arrayref = [ {"my_s_m_code" => "asc"} ];
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => [ "master_0000","master_0001" ] ],
		buffer => \@buffer_array,
		notfound => 1,
		order_by => $orderby_arrayref,
	);
	&testRC($dbh,"SIG311","my_master");
	ok($dbh->getRows()==2,"SIG312 Buffer expected 2, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000" && $buffer_array[1]->{s_m_code} eq "master_0001","SIG313 Buffer code expected 'master_0000', found 0:".$buffer_array[0]->{s_m_code}." 1:".$buffer_array[1]->{s_m_code});

	note("SIG320 OrderBy, order_by => \@order_by, \@order_by => [ 'value' ]");
	@orderby_array = [ {"my_s_m_code" => "asc"} ];
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => [ "master_0000","master_0001" ] ],
		buffer => \@buffer_array,
		notfound => 1,
		order_by => @orderby_array,
	);
	&testRC($dbh,"SIG321","my_master");
	ok($dbh->getRows()==2,"SIG322 Buffer expected 2, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000" && $buffer_array[1]->{s_m_code} eq "master_0001","SIG323 Buffer code expected 'master_0000', found 0:".$buffer_array[0]->{s_m_code}." 1:".$buffer_array[1]->{s_m_code});

	note("SIG330 OrderBy, order_by => \@order_by, \@order_by => ( 'value' )");
	@orderby_array = ( {"my_s_m_code" => "asc"} );
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => [ "master_0000","master_0001" ] ],
		buffer => \@buffer_array,
		notfound => 1,
		order_by => \@orderby_array,
	);
	&testRC($dbh,"SIG331","my_master");
	ok($dbh->getRows()==2,"SIG332 Buffer expected 2, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000" && $buffer_array[1]->{s_m_code} eq "master_0001","SIG333 Buffer code expected 'master_0000', found 0:".$buffer_array[0]->{s_m_code}." 1:".$buffer_array[1]->{s_m_code});
}

################################################################################

sub testGneericSinglesWHERE()
{
	my $dbh = shift;
	my $contents = shift;

	my @buffer_array;
	my @where_array;
	my $where_arrayref;

	note("SIG200 Where, where => [ 'value' ]");
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG201","my_master");
	ok($dbh->getRows()==1,"SIG202 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG203 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG210 Where, where => \$where, \$where => [ 'value' ]");
	$where_arrayref = [ "my_s_m_code" => "master_0000" ];
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => $where_arrayref,
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG211","my_master");
	ok($dbh->getRows()==1,"SIG212 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG213 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG220 Where, where => \@where, \@where => [ 'value' ]");
	@where_array = [ "my_s_m_code" => "master_0000" ];
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => @where_array,
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG221","my_master");
	ok($dbh->getRows()==1,"SIG222 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG223 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG230 Where, where => \@where, \@where => ( 'value' )");
	@where_array = ( "my_s_m_code" => "master_0000" );
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => \@where_array,
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG231","my_master");
	ok($dbh->getRows()==1,"SIG232 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG233 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});
}

################################################################################

sub testGneericSinglesFIELDS()
{
	my $dbh = shift;
	my $contents = shift;

	my @buffer_array;
	my $fields_code = "my_master.s_m_code";
	my $fields_name = "my_master.s_m_name";
	my $fields_desc = "my_master.s_m_desc";
	my @fields_array;
	my $fields_arrayref;
	my $fields_scalar;

	note("SIG100 Fields, fields => 'fieldname'");
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG101","my_master");
	ok($dbh->getRows()==1,"SIG102 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG103 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG110 Fields, fields => [ 'fieldname' ]");
	$dbh->Select
	(
		table => "my_master",
		fields => [ "s_m_code" ],
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG111","my_master");
	ok($dbh->getRows()==1,"SIG112 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG113 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG120 Fields, fields => \$fieldvar, \$fieldvar => 'fieldname'");
	$dbh->Select
	(
		table => "my_master",
		fields => $fields_code,
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG121","my_master");
	ok($dbh->getRows()==1,"SIG122 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG123 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG130 Fields, fields => \$fieldvar, \$fieldvar => [ \$fieldvar ]");
	$fields_scalar = [ $fields_code,$fields_name ];
	$dbh->Select
	(
		table => "my_master",
		fields => $fields_scalar,
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG131","my_master");
	ok($dbh->getRows()==1,"SIG132 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG133 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG140 Fields, fields => \@field_array, \@fields_array => [ \$fieldvar ]");
	@fields_array = [ $fields_code,$fields_name ];
	$dbh->Select
	(
		table => "my_master",
		fields => @fields_array,
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG141","my_master");
	ok($dbh->getRows()==1,"SIG142 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG143 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG150 Fields, fields => \@field_array, \@fields_array => ( \$fieldvar )");
	@fields_array = ( $fields_code,$fields_name,$fields_desc );
	$dbh->Select
	(
		table => 'my_master',
		fields => \@fields_array,
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG151","my_master");
	ok($dbh->getRows()==1,"SIG152 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG153 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});
}

################################################################################

sub testGenericSinglesTABLES()
{
	my $dbh = shift;
	my $contents = shift;

	my $table_master = "my_master";
	my $table_slave = "my_slave";
	my @table_array;
	my $table_scalar;

	my @buffer_array;

	note("SIG000 Tables, table=>'mytable'");
	$dbh->Select
	(
		table => "$table_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG001","my_master");
	ok($dbh->getRows()==1,"SIG002 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG003 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG010 Tables, table=> [ 'mytable' ]");
	$dbh->Select
	(
		table => [ $table_master ],
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG011","my_master");
	ok($dbh->getRows()==1,"SIG012 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG013 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG020 Tables, table=>\$mytable, \$table => 'mytable'");
	$dbh->Select
	(
		table => $table_master,
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG021","my_master");
	ok($dbh->getRows()==1,"SIG022 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG023 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG030 Tables, table=>\$mytable, \$table => [ 'mytable' ]");
	$table_scalar = [ $table_master ];
	$dbh->Select
	(
		table => $table_scalar,
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG031","my_master");
	ok($dbh->getRows()==1,"SIG032 Buffer expected 1, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG033 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG040 Tables, table=>[\$mytable]");
	@table_array = [ $table_master,$table_slave ];
	$dbh->Select
	(
		table => @table_array,
		fields => "my_master.s_m_code",
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG041","my_master");
	ok($dbh->getRows()==100,"SIG042 Buffer expected 100, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG043 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	note("SIG050 Tables, table=>[\$mytable]");
	@table_array = ( $table_master,$table_slave );
	$dbh->Select
	(
		table => \@table_array,
		fields => "my_master.s_m_code",
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"SIG051","my_master");
	ok($dbh->getRows()==100,"SIG052 Buffer expected 100, found ".$dbh->getRows());
	ok($buffer_array[0]->{s_m_code} eq "master_0000","SIG053 Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});
}

################################################################################

sub testGenericMasterSlaveSelect()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer;

	note("MSS000 Master and Slave merges");

	$dbh->Select
	(
		table => "my_master",
		buffer => \@buffer,
		order_by => "my_i_m_id",
	);
	&testRC($dbh,"MSS001","my_master");
	ok($dbh->getRows()==10,"MSS002 Master select, expected 10, found ".$dbh->getRows());

	$dbh->Select
	(
		table => "my_slave",
		buffer => \@buffer,
		order_by => "my_i_s_id",
	);
	&testRC($dbh,"MSS003","my_slave");
	ok($dbh->getRows()==100,"MSS004 Slave select, expected 100, found ".$dbh->getRows());

	$dbh->Select
	(
		table => [ "my_master","my_slave" ],
		buffer => \@buffer,
		fields => [ "my_master.my_s_m_code", "my_slave.my_s_s_code" ],
	);
	&testRC($dbh,"MSS004","my_master/my_slave");
	ok($dbh->getRows()==1000,"MSS005 Master/Slave merge-1, expected 1000, found ".$dbh->getRows());

	$dbh->Select
	(
		table => [ "my_master","my_slave" ],
		buffer => \@buffer,
		fields => [ "my_master.my_s_m_code", "my_slave.my_s_s_code" ],
		where =>
		[
			"my_master.my_s_m_code" => "my_slave.my_s_m_code"
		]
	);
	&testRC($dbh,"MSS006","my_master/my_slave");
	ok($dbh->getRows()==100,"MSS007 Master/Slave merge-2, expected 100, found ".$dbh->getRows());

	$dbh->Select
	(
		table => [ "my_master","my_slave" ],
		buffer => \@buffer,
		fields => [ "my_master.my_s_m_code", "my_slave.my_s_s_code" ],
		where =>
		[
			"my_master.my_s_m_code" => [ "!", "my_slave.my_s_m_code" ],
		]
	);
	&testRC($dbh,"MSS008","my_master/m_slave");
	ok($dbh->getRows()==900,"MSS009 Master/Slave merge-3, expected 900, found ".$dbh->getRows());

	diag("MSS100 Grouped");

	$dbh->Select
	(
		table => [ "my_slave" ],
		fields => [ "my_s_m_code", "count(my_s_s_code)" ],
		group_by => "my_s_m_code",
		buffer => \@buffer,
	);
	&testRC($dbh,"MSS111","my_slave");
	ok($dbh->getRows()==10,"MSS112 Slave grouped-1, expected 10 masters, found ".$dbh->getRows());

	foreach my $ref(@buffer)
	{
		ok($ref->{my_s_s_code} == 10,"MSS113 Slave grouped-2, expected 10 slaves, found ".$ref->{my_s_s_code});
	}
}

################################################################################

sub testGenericAutoincrementDelete()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer;

	note("DEL000 Delete");

	$dbh->Delete
	(
		table => "my_autoincrement_1",
		where=>
		[
			my_i_no_2 => [ "<", 9999 ],
		],
	);
	&testRC($dbh,"DEL001","my_autoincrement_1");
	$dbh->Select
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
	);
	&testRC($dbh,"DEL002","my_autoincrement_1");
	ok($dbh->getRows() == 10,"DEL003 Delete expected 10, found ".$dbh->getRows());
}

################################################################################

sub testGenericAutoincrementUpdate()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer;

	note("UPD000 Update");

	$dbh->Update
	(
		table => "my_autoincrement_1",
		fields =>
		{
			my_i_no_2 => 9999,
		},
		where=>
		[
			my_i_id => [ ">", 90 ],
		],
	);
	&testRC($dbh,"UPD001","my_autoincrement_1");
	$dbh->Select
	(
		table => "my_autoincrement_1",
		where=>
		[
			my_i_no_2 => 9999
		],
		buffer => \@buffer,
	);
	&testRC($dbh,"UPD002","my_autoincrement_1");
	ok($dbh->getRows() == 10,"UPD003 Update expected 10, found ".$dbh->getRows());
}

################################################################################

sub testGenericAutoincrementSelect()
{
	my $dbh = shift;
	my $contents = shift;

	note("CUR000 SelectCursor");

	my %cursor;
	my @buffer;

	##my page-1
	#
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		cursor_key => "my_i_id",
		cursor_command => SQL_SIMPLE_CURSOR_TOP,
		cursor_info => \%cursor,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"CUR001","my_autoincrement_1"));
	ok($cursor{lines}==10 && $cursor{first}==1 && $cursor{last}==10,"CUR002 SelectCursor first-page, expected first(1) last(10) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");

	## my page-2
	#
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
		cursor_info => \%cursor,
		cursor_key => "my_i_id",
		limit => 10,
	);
	return 0 if (&testRC($dbh,"CUR003","my_autoincrement_1"));
	ok($cursor{lines}==10 && $cursor{first}==11 && $cursor{last}==20,"CUR004 SelectCursor goto-page2, expected first(11) last(20) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");

	## my return page-1
	#
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
		cursor_command => SQL_SIMPLE_CURSOR_BACK,
		cursor_info => \%cursor,
		cursor_key => "my_i_id",
		limit => 10,
	);
	return 0 if (&testRC($dbh,"CUR005","my_autoincrement_1"));
	ok($cursor{lines}==10 && $cursor{first}==1 && $cursor{last}==10,"CUR006 SelectCursor return-first, expected first(1) last(10) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");

	## my return page2
	#
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
		cursor_info => \%cursor,
		cursor_key => "my_i_id",
		limit => 10,
	);
	return 0 if (&testRC($dbh,"CUR007","my_autoincrement_1"));
	ok($cursor{lines}==10 && $cursor{first}==11 && $cursor{last}==20,"CUR008 SelectCursor return-page2, expected first(11) last(20) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");

	## my page-3
	#
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
		cursor_info => \%cursor,
		cursor_key => "my_i_id",
		limit => 10,
	);
	return 0 if (&testRC($dbh,"CUR009","my_autoincrement_1"));
	ok($cursor{lines}==10 && $cursor{first}==21 && $cursor{last}==30,"CUR010 SelectCursor goto-page3, expected first(21) last(30) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");

	## my bottom
	#
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
		cursor_command => SQL_SIMPLE_CURSOR_LAST,
		cursor_info => \%cursor,
		cursor_key => "my_i_id",
		limit => 10,
	);
	return 0 if (&testRC($dbh,"CUR011","my_autoincrement_1"));
	ok($cursor{lines}==10 && $cursor{first}==100 && $cursor{last}==91,"CUR012 SelectCursor goto-last-page, expected first(100) last(91) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");
	return 1;
}

################################################################################

sub testGenericStandardSelect()
{
	my $dbh = shift;
	my $contents = shift;

	note("SEL000 Select");

	foreach my $table(sort(keys(%{$contents})))
	{
		next if (!($table =~ /^my_standard_/));

		my $er1=0;
		my $er2=0;
		my $er3=0;
		my $ok1=0;
		my $ok2=0;
		my @buffer;
		$dbh->Select
		(
			table => $table,
			buffer => \@buffer,
			log_message => 0,
			notfound => 1,
		);
		if (&testRC($dbh,"SEL001",$table))
		{
			$er1++;
			next;
		}
		$ok1++;
		foreach my $ref(@buffer)
		{
			foreach my $field(sort(keys(%{$ref})))
			{
				my %line;
				$dbh->Select
				(
					table => $table,
					fields => [ $field ],
					where => [ $field => $ref->{$field} ],
					buffer => \%line,
					log_message => 0,
					notfound => 1,
				);
				if (&testRC($dbh,"SEL002",$table))
				{
					$er2++;
					diag($dbh->getLastSQL());
					diag("ERROR: table $table, field $field, value $ref->{$field}");
					next;
				}
				if ($dbh->getRows()==0)
				{
					$er3++;
					diag($dbh->getLastSQL());
					diag("ERROR: table $table, field $field, value $ref->{$field}");
				}
				$ok2++;
			}
		}
		pass("SEL003 table ".$table.", ".$ok1." step1 successful") if ($ok1);
		pass("SEL005 table ".$table.", ".$ok2." step2 successful") if ($ok2);
		fail("SEL006 table ".$table.", ".$er1." step1 failure") if ($er1);
		fail("SEL007 table ".$table.", ".$er2." step2 failure") if ($er2);
		fail("SEL008 table ".$table.", ".$er3." step3 failure") if ($er3);
	}
}

################################################################################

sub testGenericAutoincrementInsert()
{
	my $dbh = shift;
	my $contents = shift;

	note("AUT000 Insert Autoincrement");

	my $er=0;
	my $ok=0;
	foreach my $ix(1..100)
	{
		$dbh->Insert
		(
			table=>"my_autoincrement_1",
			fields=>
			{
				my_i_id => $ix,
				my_i_no_1 => $ix+$ix,
			    my_i_no_2 => $ix*$ix,
			}
	    );
		(&testRC($dbh,"AUT001","my_autoincrement_1")) ? $er++ : $ok++;
	}
	fail("AUT002 ".$er." inserted errors") if ($er);
	pass("AUT003 ".$ok." inserted successful") if ($ok);
}

################################################################################

sub testGenericMasterSlaveInsert()
{
	my $dbh = shift;
	my $contents = shift;

	note("IMS000 Insert Master/Slave");

	foreach my $code(0..9)
	{
		my $er=0;
		my $ok=0;
		$code = sprintf("%04i",$code);
		$dbh->Insert
		(
			table=>"my_master",
			fields=>
			{
				my_s_m_code => "master_".$code,
				my_s_m_name => "name_".$code,
				my_s_m_desc => "description_".$code,
			}
	       	);
		(&testRC($dbh,"IMS001","my_master")) ? $er++ : $ok++;

		foreach my $subcode(10..19)
		{
			$subcode = sprintf("%04i",$subcode);
			$dbh->Insert
			(
				table=>"my_slave",
				fields=>
				{
					my_s_m_code => "master_".$code,
					my_s_s_code => "slave_".$subcode,
					my_s_s_name => "name_".$subcode,
					my_s_s_desc => "description_".$subcode,
				}
		       	);
			(&testRC($dbh,"IMS002","my_slave")) ? $er++ : $ok++;
		}
		fail("IMS003 Number of ".$er." errors (master+slave), Code ".$code) if ($er);
		pass("IMS004 Number of ".$ok." successful (master+slave), Code ".$code) if ($ok);
	}

	note("IMS010 Insert Master with duplicate state");

	my $er=0;
	my $ok=0;
	my $no=0;
	foreach my $code(0..9)
	{
		my $mykey;
		$code = sprintf("%04i",$code);
		$dbh->Select
		(
			table => "my_master",
			fields => [ "my_i_m_id" ],
			where => [ my_s_m_code => "master_".$code ],
			buffer => \$mykey
		);
		if (&testRC($dbh,"IMS010","my_master"))
		{
			$no++;
			next;
		}
		my $update = "DESCRIPTION_".$code."_DUP";
		$dbh->Insert
		(
			table=>"my_master",
			fields=>
			{
				my_i_m_id => $mykey,
				my_s_m_code => "master_".$code,
				my_s_m_name => "name_".$code,
				my_s_m_desc => "description_".$code,
			},
			conflict =>
			{
				my_s_m_desc => $update,
			},
			conflict_key => "my_i_m_id",
	       	);
		if (&testRC($dbh,"IMS011","my_master"))
	       	{
			$er++;
			next;
		}
		my $mydesc;
		$dbh->Select
		(
			table => "my_master",
			fields => [ "my_s_m_desc" ],
			where => [ my_s_m_code => "master_".$code ],
			buffer => \$mydesc
		);
		if (&testRC($dbh,"IMS012","my_master"))
		{
			$no++;
			next;
		}
		ok($mydesc eq $update,"IMS013 insert with conflict/duplicate for ".$code);
	}
	fail("IMS014 Number of ".$no." notkey") if ($no);
	fail("IMS015 Number of ".$er." errors") if ($er);
}

################################################################################
#'my_table_indexed_fields_2' => {
#	'opts' => {
#		'my_i_fld_1' => {
#			'Key' => 'MUL',
#			'Field' => 'i_fld_1',
#			'Null' => 'YES',
#			'Type' => 'int(11)',
#			'Default' => undef,
#			'Extra' => ''
#	},
#

sub testGenericStandardInsert()
{
	my $dbh = shift;
	my $contents = shift;

	note("STD000 Insert Standard");

	foreach my $table(sort(keys(%{$contents})))
	{
		next if (!($table =~ /^my_standard_/));

		my %fields;
		my @fields;
		my @values;
		my @values1;
		my @values2;
		my $col=0;
		my $int=0;
		my $dec=0.0;

		foreach my $field(sort(keys(%{$contents->{$table}{cols}})))
		{
			next if ($contents->{$table}{info}{$field}{I});

			$col++;
			my $type = substr($contents->{$table}{cols}{$field},0,1);

			if	($type eq "b")
			{
				$fields{$field} = 0;
				push(@fields,$field);
				push(@values,1);
				push(@values1,0);
				push(@values2,0,1);
			}
			elsif	($type eq "f")
			{
				$fields{$field} = ($dec+=0.1);
				push(@fields,$field);
				push(@values,($dec+=0.1));
				push(@values1,($dec+=0.1));
				push(@values2,($dec+=0.1),($dec+=0.1));
			}
			elsif	($type eq "i")
			{
				$fields{$field} = ++$int;
				push(@fields,$field);
				push(@values,++$int);
				push(@values1,++$int);
				push(@values2,++$int,++$int);
			}
			elsif	($type eq "s")
			{
				$fields{$field} = "a".$col;
				push(@fields,$field);
				push(@values,"b".$col);
				push(@values1,"c".$col);
				push(@values2,"d".$col,"e".$col);
			}
			elsif	($type eq "t")
			{
				my $info = '1970-01-01 00:00:00';
				if	($contents->{$table}{info}{$field}{T} =~ /timestamp/){}
				elsif	($contents->{$table}{info}{$field}{T} =~ /datetime/){}
				elsif	($contents->{$table}{info}{$field}{T} =~ /^date/) { $info = substr($info,0,10); }
				elsif	($contents->{$table}{info}{$field}{T} =~ /^time/) { $info = substr($info,12); }
				elsif	($contents->{$table}{info}{$field}{T} =~ /^year/) { $info = substr($info,0,4); }
				elsif	($contents->{$table}{info}{$field}{T} =~ /^interval/) { $info = 0; }

				$fields{$field} = $info;
				push(@fields,$field);
				push(@values, $info);
				push(@values1,$info);
				push(@values2,$info,$info);
			}
			else
			{
				fail("STD001 Field Invalid Type ".$contents->{$table}{info}{$field}{T});
			}
		}

		$dbh->Insert( table=>$table, fields=>\%fields );
		if (&testRC($dbh,"STD002",$table))
		{
			print STDERR $dbh->getLastSQL(),"\n";
			fail("STD003 Insert-1, ".$table.", ".$dbh->getMessage());
		}
		else { pass("STD004 Insert-1, ".$table); }

		$dbh->Insert( table=>$table, fields=>\@fields, values=>[ \@values ] );
		if (&testRC($dbh,"STD010",$table))
		{
			print STDERR $dbh->getLastSQL(),"\n";
			fail("STD011 Insert-2, ".$table.", ".$dbh->getMessage());
		}
		else { pass("SID012 Insert-2, ".$table); }

		if (@fields==1)
		{
			$dbh->Insert( table=>$table, fields=>\@fields, values=>\@values2 );
			if (&testRC($dbh,"STD020",$table))
			{
				print STDERR $dbh->getLastSQL(),"\n";
				fail("STD021 Insert-3, ".$table.", ".$dbh->getMessage());
			}
			else { pass("STD022 Insert-3, ".$table); }
		}
		else
		{
			$dbh->Insert( table=>$table, fields=>\@fields, values=>\@values1 );
			if (&testRC($dbh,"STD030",$table))
			{
				print STDERR $dbh->getLastSQL(),"\n";
				fail("STD031 Insert-4, ".$table.", ".$dbh->getMessage());
			}
			else { pass("STD032 Insert-4, ".$table); }
		}
	}
}

################################################################################

sub testOPEN()
{
	my $options = {@_};

	my $dbh = SQL::SimpleOps->new ( %{$options} );
	if (!defined($dbh))
	{
		print STDERR $SQL::SimpleOps::errstr."\n";
		return undef;
	}
	return $dbh;
}

################################################################################

sub testRC()
{
	my $dbh = shift;
	my $msg = shift;
	my $tbl = shift;

	diag($dbh->getLastSQL()) if (defined($ENV{SQL_SIMPLE_DB_SHOW_SQL}) && $ENV{SQL_SIMPLE_DB_SHOW_SQL} eq "1");
	my $cmd = $dbh->getLastSQL();
	if ($dbh->getRC())
	{
		diag("Command: ".$cmd);
		fail($msg." Code: ".$dbh->getRC().", Message: ".$dbh->getMessage());
		return 1;
	}
	else
	{
		($cmd) = split(" ",$cmd);
		pass($msg." ".$cmd."[".$tbl."] successful");
	}
	return 0;
}

__END__
