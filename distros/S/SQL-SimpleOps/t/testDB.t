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

	our $VERSION = "2023.302.1";

	BEGIN{ use_ok('SQL::SimpleOps'); };

	my $dir = ($0 =~ /^(.*)\/(.*)/) ? $1 : "";
	$dir = getcwd()."/".$dir if (!($dir =~ /^\//));
	unshift(@INC,$dir);

################################################################################
## enable this option to abort on first error

	#$ENV{EXIT_ON_FIRT_ERROR} = 1;

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
		diag("See text README before doing any test");
		done_testing();
		exit(0);
	}
	if ($test != 1)
	{
		diag("Multiple test found, there can be only one");
		diag("See text README before doing any test");
		done_testing();
		exit(0);
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

	&DONE();
	exit(0);

################################################################################

sub testGeneric()
{
	my $dbh = shift;
	my $contents = shift;

	## removing previous data test
	&testInitialize($dbh,$contents);

	## all tests, Autoincrement cursor singlkeys
	&test_all_Standard_Insert($dbh,$contents);
	&test_all_Standard_Select($dbh,$contents);

	## Autoincrement
	&test_Autoincrement_Cursor_Insert($dbh,$contents);
	&test_Autoincrement_ScanSingleKey_Select($dbh,$contents);
	&test_Autoincrement_Standard_Update($dbh,$contents);
	&test_Autoincrement_Standard_Delete($dbh,$contents);

	## Master/Slave
	&test_Master_Insert($dbh,$contents);
	&test_Master_Generic_Select($dbh,$contents);
	&test_Master_Merges_Select($dbh,$contents);
	&test_Master_ScanMultiKeys_Select($dbh,$contents);
	&test_Master_ScanOrderedEnforced($dbh,$contents);
	#&test_Master_Singles($dbh,$contents);
	#&test_Master_Buffering_Select($dbh,$contents);

	$dbh->Close();
}

################################################################################

sub testInitialize()
{
	my $dbh = shift;
	my $contents = shift;
	my @tables = sort(keys(%{$contents}));

	&myDIAG("Initializations");

	## show environments if required

	if ($ENV{SQL_SIMPLE_DB_SHOW_CONTENTS})
	{
		&myDIAG("Contents and Tables");

		require Data::Dumper;
		print Data::Dumper->Dumper(\@tables,$contents);
	}

	my $er=0;
	my $no=0;
	foreach my $table (@tables)
	{
		$no++;
		$dbh->Delete ( table=>$table, force => 1, notfound => 1 );
		$er++ if (&testRC($dbh,"0111",$table));
	}
	&myOK(!$er,"0111","Removing previous data, tables: ".$no.", errors: ".$er);
}

################################################################################

sub test_Master_Merges_Select()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer;

	&myDIAG("Merge");

	$dbh->Select
	(
		table => "my_master",
		fields => [ {"my_master.my_s_m_code"=>"ms"}, ],
		buffer => \@buffer,
	);
	&testRC($dbh,"0210","my_master");
	&myOK($dbh->getRows()==10,"0220","Aliases select-1, expected 10, found ".$dbh->getRows());

	$dbh->Select
	(
		table => [ "my_master","my_slave" ],
		fields => [ {"my_master.my_s_m_code"=>"ms"}, {"my_slave.my_s_s_code"=>"ss"}, ],
		buffer => \@buffer,
	);
	&testRC($dbh,"0230","my_master/my_slave");
	&myOK($dbh->getRows()==1000,"0240","Aliases select-2, expected 1000, found ".$dbh->getRows());
}

################################################################################

sub test_Master_Buffering_Select()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer_array;
	my %buffer_hash;
	my @buffer_hashindex;
	my @keys = ("master_0000","master_0001","master_0002","master_0003","master_0004");

	&myDIAG("Buffering");

	## test hashref and hashindex

	diag("Select using buffer_hashkey and buffer_hashindex, loading single value");
	$dbh->Select
	(
		table => ["my_master"],
		fields => [ "i_m_id", "s_m_code" ],
		cursor_key => [ "i_m_id", ],
		buffer => \%buffer_hash,
		buffer_hashkey => [ "i_m_id", ],
		buffer_hashindex => \@buffer_hashindex,
	);
	return 0 if (&testRC($dbh,"0300","my_master"));
	diag("Expected: Buffer_hash with 10 rows, buffer_hashindex with 10 keys and each buffer with one value");
	foreach my $k(@buffer_hashindex)
	{
		if (&myOK(defined($buffer_hash{$k}),"0301","Key ".$k." is mapped"))
		{
			&myOK(ref($buffer_hash{$k}) eq "","0302","Buffer_hash key ".$k." is a single value, ref: ".ref($buffer_hash{$k}));
		}
	}

	## test hashref and hashindex

	diag("Select using buffer_hashkey and buffer_hashindex, loading multiple values");
	$dbh->Select
	(
		table => ["my_master"],
		fields => [ "i_m_id", "s_m_code", "s_m_desc" ],
		cursor_key => [ "i_m_id", ],
		buffer => \%buffer_hash,
		buffer_hashkey => [ "i_m_id", ],
		buffer_hashindex => \@buffer_hashindex,
	);
	return 0 if (&testRC($dbh,"0300","my_master"));

	diag("Expected: Buffer_hash with 10 rows, buffer_hashindex with 10 keys and each buffer with two values");
	foreach my $k(@buffer_hashindex)
	{
		if (!&myOK(defined($buffer_hash{$k}),"0305","Key ".$k." is mapped")){}
		elsif (!&myOK(ref($buffer_hash{$k}) eq "HASH","0306","Buffer_hash key ".$k." is hash multi value, ref: ".ref($buffer_hash{$k}))){}
		else
		{
			&myOK(keys(%{$buffer_hash{$k}}) == 2,"0307","Buffer_hash key ".$k." have two values, values: ".keys(%{$buffer_hash{$k}}));
		}
	}

	## test buffer_arrayref

	diag("Expected: Buffer_array simple with buffer_arrayref disabled");
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
	&testRC($dbh,"0310","my_master");
	&myOK($dbh->getRows()==5,"0311","Buffer_arrayref, expected 5, found ".$dbh->getRows());
	&myOK(join(" ",@keys) eq join(" ",@buffer_array),"0312","Buffer_arrayref, test match retrieved data");

	diag("Expected: Buffer_hash with buffer_arrayref=0 and without buffer_hashindex");
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
	&testRC($dbh,"0320","my_master");
	&myOK($dbh->getRows()==5,"0321","Buffer_hashkey, expected 5, found ".$dbh->getRows());

	&myDIAG("Buffering");

	my $ok1=1;
	foreach my $id(@keys)
	{
		if (!&myOK(defined($buffer_hash{$id}),"0331","Buffer_hash key ".$id." is mapped"))
		{
			&myOK(%{$buffer_hash{$id}}+0 == 2,"0332","Buffer_hashkey key ".$id.", expected 2 fields, found ".(%{$buffer_hash{$id}}+0));
		}
	}

	diag("Expected: master/slave data merged into buffer_hash");
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
		where => [ "my_master.my_s_m_code" => \@keys, "my_master.my_s_m_code" => "\\my_slave.my_s_m_code" ],
		buffer => \%buffer_hash,
		buffer_hashkey => ["ms","ss"],
		notfound => 1,
	);
	&testRC($dbh,"0340","my_master/my_slave");

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
						fail("Buffer_hashkey key1 '$key1 with key2 '$key2', expected 2, found $d");
						$ok2=0;
						last LOOP;
					}
				}
			}
			else
			{
				fail("Buffer_hashkey key1 '$key1', expected 10, found $c");
				$ok2=0;
				last LOOP;
			}
		}
	}
	else
	{
		fail("Buffer_hashkey, expected $a, found $b");
		$ok2=0;
	}
	pass("Buffer_hashkey indexed by array successful") if ($ok2);
}

################################################################################

sub test_Master_Singles()
{
	my $dbh = shift;
	my $contents = shift;

	&test_Master_SinglesTABLES_Select($dbh,$contents);
	&test_Master_SinglesFIELDS_Select($dbh,$contents);
	&test_Master_SinglesWHERE_Select($dbh,$contents);
	&test_Master_SinglesORDERBY_Select($dbh,$contents);
	&test_Master_SinglesGROUPBY_Select($dbh,$contents);
}

################################################################################

sub test_Master_SinglesGROUPBY_Select()
{
	my $dbh = shift;
	my $contents = shift;

	my @buffer_array;
	my @groupby_array;
	my $groupby_arrayref;
	my @orderby_array;
	my $orderby_arrayref;

	&myDIAG("GroupBy, group_by => 'value'");

	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
		group_by => "s_m_code",
	);
	&testRC($dbh,"0401","my_master");
	&myOK($dbh->getRows()==1,"0402","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0403","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("GroupBy, group_by => \$group_by, \$group_by => [ 'value' ]");

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
	&testRC($dbh,"0411","my_master");
	&myOK($dbh->getRows()==1,"0412","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0413","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("GroupBy, group_by => \@group_by, \@group_by => [ 'value' ]");

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
	&testRC($dbh,"0421","my_master");
	&myOK($dbh->getRows()==1,"0422","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0423","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("GroupBy, group_by => \@group_by, \@group_by => ( 'value' )");

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
	&testRC($dbh,"0431","my_master");
	&myOK($dbh->getRows()==1,"0432","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0433","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});
}

################################################################################

sub test_Master_SinglesORDERBY_Select()
{
	my $dbh = shift;
	my $contents = shift;

	my @buffer_array;
	my @orderby_array;
	my $orderby_arrayref;

	&myDIAG("OrderBy, order_by => [ 'value' ]");

	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => [ "master_0000","master_0001" ] ],
		buffer => \@buffer_array,
		notfound => 1,
		order_by => [ {"my_s_m_code"=>"asc"}, ],
	);
	&testRC($dbh,"0501","my_master");
	&myOK($dbh->getRows()==2,"0502","Buffer expected 2, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000" && $buffer_array[1]->{s_m_code} eq "master_0001","0503","Buffer code expected 'master_0000' and 'master_0001', found 0:".$buffer_array[0]->{s_m_code}." 1:".$buffer_array[1]->{s_m_code});

	&myDIAG("OrderBy, order_by => \$order_by, \$order_by => [ 'value' ]");

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
	&testRC($dbh,"0511","my_master");
	&myOK($dbh->getRows()==2,"0512","Buffer expected 2, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000" && $buffer_array[1]->{s_m_code} eq "master_0001","0513","Buffer code expected 'master_0000' and 'master_0001', found 0:".$buffer_array[0]->{s_m_code}." 1:".$buffer_array[1]->{s_m_code});

	&myDIAG("OrderBy, order_by => \@order_by, \@order_by => [ 'value' ]");

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
	&testRC($dbh,"0521","my_master");
	&myOK($dbh->getRows()==2,"0522","Buffer expected 2, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000" && $buffer_array[1]->{s_m_code} eq "master_0001","0523","Buffer code expected 'master_0000', found 0:".$buffer_array[0]->{s_m_code}." 1:".$buffer_array[1]->{s_m_code});

	&myDIAG("OrderBy, order_by => \@order_by, \@order_by => ( 'value' )");

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
	&testRC($dbh,"0531","my_master");
	&myOK($dbh->getRows()==2,"0532","Buffer expected 2, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000" && $buffer_array[1]->{s_m_code} eq "master_0001","0533","Buffer code expected 'master_0000', found 0:".$buffer_array[0]->{s_m_code}." 1:".$buffer_array[1]->{s_m_code});
}

################################################################################

sub test_Master_SinglesWHERE_Select()
{
	my $dbh = shift;
	my $contents = shift;

	my @buffer_array;
	my @where_array;
	my $where_arrayref;

	&myDIAG("Where, where => [ 'value' ]");

	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0601","my_master");
	&myOK($dbh->getRows()==1,"0602","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0603","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Where, where => \$where, \$where => [ 'value' ]");

	$where_arrayref = [ "my_s_m_code" => "master_0000" ];
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => $where_arrayref,
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0611","my_master");
	&myOK($dbh->getRows()==1,"0612","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0613","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Where, where => \@where, \@where => [ 'value' ]");

	@where_array = [ "my_s_m_code" => "master_0000" ];
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => @where_array,
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0621","my_master");
	&myOK($dbh->getRows()==1,"0622","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0623","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Where, where => \@where, \@where => ( 'value' )");

	@where_array = ( "my_s_m_code" => "master_0000" );
	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => \@where_array,
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0641","my_master");
	&myOK($dbh->getRows()==1,"0642","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0643","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});
}

################################################################################

sub test_Master_SinglesFIELDS_Select()
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

	&myDIAG("Fields, fields => 'fieldname'");

	$dbh->Select
	(
		table => "my_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0701","my_master");
	&myOK($dbh->getRows()==1,"0702","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0703","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Fields, fields => [ 'fieldname' ]");

	$dbh->Select
	(
		table => "my_master",
		fields => [ "s_m_code" ],
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0711","my_master");
	&myOK($dbh->getRows()==1,"0712","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0713","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Fields, fields => \$fieldvar, \$fieldvar => 'fieldname'");

	$dbh->Select
	(
		table => "my_master",
		fields => $fields_code,
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0721","my_master");
	&myOK($dbh->getRows()==1,"0722","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0723","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Fields, fields => \$fieldvar, \$fieldvar => [ \$fieldvar ]");

	$fields_scalar = [ $fields_code,$fields_name ];
	$dbh->Select
	(
		table => "my_master",
		fields => $fields_scalar,
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0731","my_master");
	&myOK($dbh->getRows()==1,"0732","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0733","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Fields, fields => \@field_array, \@fields_array => [ \$fieldvar ]");

	@fields_array = [ $fields_code,$fields_name ];
	$dbh->Select
	(
		table => "my_master",
		fields => @fields_array,
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0741","my_master");
	&myOK($dbh->getRows()==1,"0742","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0744","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Fields, fields => \@field_array, \@fields_array => ( \$fieldvar )");

	@fields_array = ( $fields_code,$fields_name,$fields_desc );
	$dbh->Select
	(
		table => 'my_master',
		fields => \@fields_array,
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0751","my_master");
	&myOK($dbh->getRows()==1,"0752","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0753","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});
}

################################################################################

sub test_Master_SinglesTABLES_Select()
{
	my $dbh = shift;
	my $contents = shift;

	my $table_master = "my_master";
	my $table_slave = "my_slave";
	my @table_array;
	my $table_scalar;

	my @buffer_array;

	&myDIAG("Tables, table=>'mytable'");

	$dbh->Select
	(
		table => "$table_master",
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0801","my_master");
	&myOK($dbh->getRows()==1,"0802","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0804","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Tables, table=> [ 'mytable' ]");

	$dbh->Select
	(
		table => [ $table_master ],
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0811","my_master");
	&myOK($dbh->getRows()==1,"0812","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0813","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Tables, table=>\$mytable, \$table => 'mytable'");

	$dbh->Select
	(
		table => $table_master,
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0821","my_master");
	&myOK($dbh->getRows()==1,"0822","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0823","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Tables, table=>\$mytable, \$table => [ 'mytable' ]");

	$table_scalar = [ $table_master ];
	$dbh->Select
	(
		table => $table_scalar,
		fields => "s_m_code",
		where => [ "my_s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0831","my_master");
	&myOK($dbh->getRows()==1,"0832","Buffer expected 1, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0833","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Tables, table=>[\$mytable]");

	@table_array = [ $table_master,$table_slave ];
	$dbh->Select
	(
		table => @table_array,
		fields => "my_master.s_m_code",
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0841","my_master");
	&myOK($dbh->getRows()==100,"0842","Buffer expected 100, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0843","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});

	&myDIAG("Tables, table=>[\$mytable]");

	@table_array = ( $table_master,$table_slave );
	$dbh->Select
	(
		table => \@table_array,
		fields => "my_master.s_m_code",
		where => [ "my_master.s_m_code" => "master_0000" ],
		buffer => \@buffer_array,
		notfound => 1,
	);
	&testRC($dbh,"0851","my_master");
	&myOK($dbh->getRows()==100,"0852","Buffer expected 100, found ".$dbh->getRows());
	&myOK($buffer_array[0]->{s_m_code} eq "master_0000","0853","Buffer code expected 'master_0000', found ".$buffer_array[0]->{s_m_code});
}

################################################################################

sub test_Master_Generic_Select()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer;

	&myDIAG("Master and Slave merges");

	$dbh->Select
	(
		table => "my_master",
		buffer => \@buffer,
		order_by => "my_i_m_id",
	);
	&testRC($dbh,"0901","my_master");
	&myOK($dbh->getRows()==10,"0902","Master select, expected 10, found ".$dbh->getRows());

	$dbh->Select
	(
		table => "my_slave",
		buffer => \@buffer,
		order_by => "my_i_s_id",
	);
	&testRC($dbh,"0910","my_slave");
	&myOK($dbh->getRows()==100,"0911","Slave select, expected 100, found ".$dbh->getRows());

	$dbh->Select
	(
		table => [ "my_master","my_slave" ],
		buffer => \@buffer,
		fields => [ "my_master.my_s_m_code", "my_slave.my_s_s_code" ],
	);
	&testRC($dbh,"0920","my_master/my_slave");
	&myOK($dbh->getRows()==1000,"0921","Master/Slave merge-1, expected 1000, found ".$dbh->getRows());

	$dbh->Select
	(
		table => [ "my_master","my_slave" ],
		buffer => \@buffer,
		fields => [ "my_master.my_s_m_code", "my_slave.my_s_s_code" ],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		]
	);
	&testRC($dbh,"0930","my_master/my_slave");
	&myOK($dbh->getRows()==100,"0931","Master/Slave merge-2, expected 100, found ".$dbh->getRows());

	$dbh->Select
	(
		table => [ "my_master","my_slave" ],
		buffer => \@buffer,
		fields => [ "my_master.my_s_m_code", "my_slave.my_s_s_code" ],
		where =>
		[
			"my_master.my_s_m_code" => [ "!", "\\my_slave.my_s_m_code" ],
		]
	);
	&testRC($dbh,"0940","my_master/m_slave");
	&myOK($dbh->getRows()==900,"0941","Master/Slave merge-3, expected 900, found ".$dbh->getRows());

	$dbh->Select
	(
		table => [ "my_slave" ],
		fields => [ "my_s_m_code", "count(my_s_s_code)" ],
		group_by => "my_s_m_code",
		buffer => \@buffer,
	);
	&testRC($dbh,"0950","my_slave");
	&myOK($dbh->getRows()==10,"0951","Slave grouped-1, expected 10 masters, found ".$dbh->getRows());

	foreach my $ref(@buffer)
	{
		&myOK($ref->{my_s_s_code} == 10,"0960","Slave grouped-2, expected 10 slaves, found ".$ref->{my_s_s_code});
	}
}

################################################################################

sub test_Autoincrement_Standard_Delete()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer;

	&myDIAG("Delete");

	$dbh->Delete
	(
		table => "my_autoincrement_1",
		where =>
		[
			my_i_no_2 => [ "<", 9999 ],
		],
	);
	&testRC($dbh,"1010","my_autoincrement_1");

	$dbh->Select
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
	);
	&testRC($dbh,"1020","my_autoincrement_1");

	&myOK($dbh->getRows() == 10,"1030","Delete expected 10, found ".$dbh->getRows());
}

################################################################################

sub test_Autoincrement_Standard_Update()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer;

	&myDIAG("Update");

	$dbh->Update
	(
		table => "my_autoincrement_1",
		fields =>
		{
			my_i_no_2 => 9999,
		},
		where =>
		[
			my_i_id => [ ">", 90 ],
		],
	);

	&testRC($dbh,"1110","my_autoincrement_1");
	$dbh->Select
	(
		table => "my_autoincrement_1",
		where =>
		[
			my_i_no_2 => 9999
		],
		buffer => \@buffer,
	);
	&testRC($dbh,"1120","my_autoincrement_1");

	&myOK($dbh->getRows() == 10,"1130","Update expected 10, found ".$dbh->getRows());
}

################################################################################

sub test_Autoincrement_ScanSingleKey_Select()
{
	my $dbh = shift;
	my $contents = shift;

	my %cursor;
	my @buffer;
	my %buffer_hash;
	my $cursor_scalar;
	my $cursor_hash;
	my @cursor_array;
	my @cursor_split;

	&myDIAG("SelectCursor Single Key");

	##my test my first buffer

	diag("SelectCursor on top of page, command TOP, page #1, using cursor_info hash and buffer as hash");
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		fields => "*",
		cursor_key => "i_id",
		cursor_command => SQL_SIMPLE_CURSOR_TOP,
		cursor_info => \%cursor,
		buffer => \%buffer_hash,
		buffer_hashkey => 'i_id',
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1200","my_autoincrement_1"));
	&myOK($cursor{lines}==10 && $cursor{first}==1 && $cursor{last}==10,"1201","Cursor expected (first/last/lines) (1), (10) and (10), found ($cursor{first}), ($cursor{last}) and ($cursor{lines})");
	&myOK($buffer_hash{$cursor{first}}{i_no_1}==2 && $buffer_hash{$cursor{last}}{i_no_1}==20,"1202","Buffer expected first field i_no_1=2 and last field i_no_1=20, found ".$buffer_hash{$cursor{first}}{i_no_1}." and ".$buffer_hash{$cursor{last}}{i_no_1});

	##my test my first buffer

	diag("SelectCursor on top of page, command TOP, page #1, using cursor_info as scalar and buffer hash");
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		fields => "*",
		cursor_key => "i_id",
		cursor_command => SQL_SIMPLE_CURSOR_TOP,
		cursor_info => \$cursor_scalar,
		buffer => \%buffer_hash,
		buffer_hashkey => 'i_id',
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1205","my_autoincrement_1"));
	@cursor_split = split(" ",$cursor_scalar);
	&myOK($cursor_split[1]==10 && $cursor_split[2]==1 && $cursor_split[3]==10,"1206","Cursor expected (first/last/lines) (1), (10) and (10), found ($cursor{first}), array: ".join(" ",@cursor_split));
	&myOK($buffer_hash{$cursor_split[2]}{i_no_1}==2 && $buffer_hash{$cursor_split[3]}{i_no_1}==20,"1207","Buffer expected first field i_no_1=2 and last field i_no_1=20, found ".$buffer_hash{ $cursor_split[2] }{i_no_1}." and ".$buffer_hash{ $cursor_split[3] }{i_no_1});

	##my page-1

	diag("SelectCursor on top of page, command TOP, page #1, using cursor_info as hash and buffer array");
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		cursor_key => "my_i_id",
		cursor_command => SQL_SIMPLE_CURSOR_TOP,
		cursor_info => \%cursor,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1210","my_autoincrement_1"));
	&myOK($cursor{lines}==10 && $cursor{first}==1 && $cursor{last}==10,"1211","Cursor expected (first/last/lines) (1), (10) and (10), found ($cursor{first}), ($cursor{last}) and ($cursor{lines})");
	&myOK($cursor{first}==$buffer[0]->{my_i_id} && $cursor{last}==$buffer[$cursor{lines}-1]->{my_i_id},"1212","Buffer expected (first/last) as ".$cursor{first}." and ".$cursor{last}.", found ".$buffer[0]->{my_i_id}." and ".$buffer[$cursor{lines}-1]->{my_i_id});

	## my page-2

	diag("SelectCursor on forward page, command NEXT, page #2");
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
		cursor_info => \%cursor,
		cursor_key => "my_i_id",
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1220","my_autoincrement_1"));
	&myOK($cursor{lines}==10 && $cursor{first}==11 && $cursor{last}==20,"1221","Cursor expected (first/last/lines) (11), (20) and (10), found ($cursor{first}), ($cursor{last}) and ($cursor{lines})");
	&myOK($cursor{first}==$buffer[0]->{my_i_id} && $cursor{last}==$buffer[$cursor{lines}-1]->{my_i_id},"1222","Buffer expected (first/last) as ".$cursor{first}." and ".$cursor{last}.", found ".$buffer[0]->{my_i_id}." and ".$buffer[$cursor{lines}-1]->{my_i_id});

	## my return page-1

	diag("SelectCursor on backward page, command BACK, page #1");
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
		cursor_command => SQL_SIMPLE_CURSOR_BACK,
		cursor_info => \%cursor,
		cursor_key => "my_i_id",
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1230","my_autoincrement_1"));
	&myOK($cursor{lines}==10 && $cursor{first}==1 && $cursor{last}==10,"1231","Cursor expected (first/last/lines) (1), (10) and (10), found ($cursor{first}), ($cursor{last}) and ($cursor{lines})");
	&myOK($cursor{last}==$buffer[0]->{my_i_id} && $cursor{first}==$buffer[$cursor{lines}-1]->{my_i_id},"1232","Buffer expected (first/last) as ".$cursor{last}." and ".$cursor{first}.", found ".$buffer[0]->{my_i_id}." and ".$buffer[$cursor{lines}-1]->{my_i_id});

	## my return page2

	diag("SelectCursor on forward page, command NEXT, page #2");
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
		cursor_info => \%cursor,
		cursor_key => "my_i_id",
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1240","my_autoincrement_1"));
	&myOK($cursor{lines}==10 && $cursor{first}==11 && $cursor{last}==20,"1241","Cursor expected (first/last/lines) (11), (20) and (10), found ($cursor{first}), ($cursor{last}) and ($cursor{lines})");
	&myOK($cursor{first}==$buffer[0]->{my_i_id} && $cursor{last}==$buffer[$cursor{lines}-1]->{my_i_id},"1242","Buffer expected (first/last) as ".$cursor{first}." and ".$cursor{last}.", found ".$buffer[0]->{my_i_id}." and ".$buffer[$cursor{lines}-1]->{my_i_id});

	## my page-3

	diag("SelectCursor on forward page, command NEXT, page #3");
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
		cursor_info => \%cursor,
		cursor_key => "my_i_id",
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1250","my_autoincrement_1"));
	&myOK($cursor{lines}==10 && $cursor{first}==21 && $cursor{last}==30,"1251","Cursor expected (first/last/lines) (21), (30) and (10), found ($cursor{first}), ($cursor{last}) and ($cursor{lines})");
	&myOK($cursor{first}==$buffer[0]->{my_i_id} && $cursor{last}==$buffer[$cursor{lines}-1]->{my_i_id},"1252","Buffer expected (first/last) as ".$cursor{first}." and ".$cursor{last}.", found ".$buffer[0]->{my_i_id}." and ".$buffer[$cursor{lines}-1]->{my_i_id});

	## my bottom

	diag("SelectCursor on last page, command LAST");
	$dbh->SelectCursor
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
		cursor_command => SQL_SIMPLE_CURSOR_LAST,
		cursor_info => \%cursor,
		cursor_key => "my_i_id",
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1260","my_autoincrement_1"));
	&myOK($cursor{lines}==10 && $cursor{first}==91 && $cursor{last}==100,"1261","Cursor expected (first/last/lines) (91), (100) and (10), found ($cursor{first}), ($cursor{last}) and ($cursor{lines})");
	&myOK($cursor{last}==$buffer[0]->{my_i_id} && $cursor{first}==$buffer[$cursor{lines}-1]->{my_i_id},"1262","Buffer expected (first/last) as ".$cursor{first}." and ".$cursor{last}.", found ".$buffer[$cursor{lines}-1]->{my_i_id}." and ".$buffer[0]->{my_i_id});
	return 1;
}

################################################################################

sub test_Master_ScanMultiKeys_Select()
{
	my $dbh = shift;
	my $contents = shift;

	&myDIAG("SelectCursor Multiple Keys");

	my %cursor;
	my @buffer;
	my $first;
	my $ended;

	##my page-1

	diag("SelectCursor on top of page, command TOP, page-1");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_info => \%cursor,
		buffer => \@buffer,
		limit => 10,
		cursor_command => SQL_SIMPLE_CURSOR_TOP,
	);
	return 0 if (&testRC($dbh,"1301","my_autoincrement_1"));
	diag("Expected: master_0000.slave_0010, master_0000.slave_0019");
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Buffer..: ".$first.", ".$ended);
	diag("Keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && join(".",@{$cursor{first}}) eq "master_0000.slave_0010" && join(".",@{$cursor{last}}) eq "master_0000.slave_0019","1302","Cursor expected page-1");

	## my page-2

	diag("SelectCursor on forward page, command NEXT, page-2");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_info => \%cursor,
		buffer => \@buffer,
		limit => 10,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
	);
	return 0 if (&testRC($dbh,"1310","my_autoincrement_1"));
	diag("Expected: master_0001.slave_0010, master_0001.slave_0019");
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Buffer..: ".$first.", ".$ended);
	diag("Keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && join(".",@{$cursor{first}}) eq "master_0001.slave_0010" && join(".",@{$cursor{last}}) eq "master_0001.slave_0019","1301","Cursor expected page-2");

	## my page-1

	diag("SelectCursor on forward page, command BACK, page-1");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_info => \%cursor,
		buffer => \@buffer,
		limit => 10,
		cursor_command => SQL_SIMPLE_CURSOR_BACK,
	);
	return 0 if (&testRC($dbh,"1320","my_autoincrement_1"));
	diag("Expected: master_0000.slave_0010, master_0000.slave_0019");
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Buffer..: ".$first.", ".$ended);
	diag("Keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && join(".",@{$cursor{first}}) eq "master_0000.slave_0010" && join(".",@{$cursor{last}}) eq "master_0000.slave_0019","1321","Cursor expected page-1");

	## my page-2

	diag("SelectCursor on forward page, command NEXT, page-2");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_info => \%cursor,
		buffer => \@buffer,
		limit => 10,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
	);
	return 0 if (&testRC($dbh,"1330","my_autoincrement_1"));
	diag("Expected: master_0001.slave_0010, master_0001.slave_0019");
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Buffer..: ".$first.", ".$ended);
	diag("Keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && join(".",@{$cursor{first}}) eq "master_0001.slave_0010" && join(".",@{$cursor{last}}) eq "master_0001.slave_0019","1331","Cursor expected page-2");

	## my page-reload

	diag("SelectCursor on forward page, command RELOAD, page-2");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_info => \%cursor,
		buffer => \@buffer,
		limit => 10,
		cursor_command => SQL_SIMPLE_CURSOR_RELOAD,
	);
	return 0 if (&testRC($dbh,"1340","my_autoincrement_1"));
	diag("Expected: master_0001.slave_0010, master_0001.slave_0019");
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Buffer..: ".$first.", ".$ended);
	diag("Keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && join(".",@{$cursor{first}}) eq "master_0001.slave_0010" && join(".",@{$cursor{last}}) eq "master_0001.slave_0019","1341","Cursor expected page-2");

	## my page-last

	diag("SelectCursor on forward page, command LAST, page-LAST");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_info => \%cursor,
		buffer => \@buffer,
		limit => 10,
		cursor_command => SQL_SIMPLE_CURSOR_LAST,
	);
	return 0 if (&testRC($dbh,"1350","my_autoincrement_1"));
	diag("Expected: master_0009.slave_0010, master_0009.slave_0019");
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Buffer..: ".$first.", ".$ended);
	diag("Keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && join(".",@{$cursor{first}}) eq "master_0009.slave_0010" && join(".",@{$cursor{last}}) eq "master_0009.slave_0019","1351","Cursor expected page-LAST");
}

################################################################################

sub test_Master_ScanOrderedEnforced()
{
	my $dbh = shift;
	my $contents = shift;

	&myDIAG("SelectCursor Order Enforced");

	my %cursor;
	my @buffer;
	my $first;
	my $ended;

	##my page-1

	diag("SelectCursor on top of page, ordered ASC, command TOP, page-1");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_ASC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_TOP,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1801","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0000.slave_0010, master_0000.slave_0019");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0000.slave_0010" && $ended eq "master_0000.slave_0019","1802","Cursor expected page-1");

	## my page-2

	diag("SelectCursor on forward page, ordered ASC, command NEXT, page-2");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_ASC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1810","my_autoincrement_1"));
	diag("Expected: master_0001.slave_0010, master_0001.slave_0019");
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0001.slave_0010" && $ended eq "master_0001.slave_0019","1811","Cursor expected page-2");

	## my page-1

	diag("SelectCursor on forward page, ordered ASC, command BACK, page-1");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_ASC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_BACK,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1820","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0000.slave_0010, master_0000.slave_0019");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0000.slave_0010" && $ended eq "master_0000.slave_0019","1821","Cursor expected page-1");

	## my page-reload, page1

	diag("SelectCursor on forward page, ordered ASC, command RELOAD, page-1");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_ASC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_RELOAD,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1825","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0000.slave_0010, master_0000.slave_0019");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0000.slave_0010" && $ended eq "master_0000.slave_0019","1826","Cursor expected page-2");
	## my page-2

	diag("SelectCursor on forward page, ordered ASC, command NEXT, page-2");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_ASC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1830","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0001.slave_0010, master_0001.slave_0019");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0001.slave_0010" && $ended eq "master_0001.slave_0019","1831","Cursor expected page-2");

	## my page-reload

	diag("SelectCursor on forward page, ordered ASC, command RELOAD, page-2");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_ASC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_RELOAD,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1840","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0001.slave_0010, master_0001.slave_0019");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0001.slave_0010" && $ended eq "master_0001.slave_0019","1841","Cursor expected page-2");

	## my page-last

	diag("SelectCursor on forward page, ordered ASC, command LAST, page-LAST");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_ASC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_LAST,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1850","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0009.slave_0010, master_0009.slave_0019");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0009.slave_0010" && $ended eq "master_0009.slave_0019","1851","Cursor expected page-LAST");

	##my page-1, desc

	diag("SelectCursor on top of page, ordered DESC, command TOP, page-1");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_DESC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_TOP,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1861","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0000.slave_0019, master_0000.slave_0010");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0000.slave_0019" && $ended eq "master_0000.slave_0010","1862","Cursor expected page-1");

	## my page-2

	diag("SelectCursor on forward page, ordered DESC, command NEXT, page-2");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_DESC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1870","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0001.slave_0019, master_0001.slave_0010");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0001.slave_0019" && $ended eq "master_0001.slave_0010","1871","Cursor expected page-2");

	## my page-1

	diag("SelectCursor on forward page, ordered DESC, command BACK, page-1");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_DESC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_BACK,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1880","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0000.slave_0019, master_0000.slave_0010");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0000.slave_0019" && $ended eq "master_0000.slave_0010","1881","Cursor expected page-1");

	## my page-2

	diag("SelectCursor on forward page, ordered DESC, command NEXT, page-2");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_DESC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_NEXT,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1890","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0001.slave_0019, master_0001.slave_0010");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0001.slave_0019" && $ended eq "master_0001.slave_0010","1891","Cursor expected page-2");

	## my page-reload

	diag("SelectCursor on forward page, ordered DESC, command RELOAD, page-2");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_DESC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_RELOAD,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1892","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0001.slave_0019, master_0001.slave_0010");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0001.slave_0019" && $ended eq "master_0001.slave_0010","1893","Cursor expected page-2");

	## my page-last

	diag("SelectCursor on forward page, ordered DESC, command LAST, page-LAST");
	$dbh->SelectCursor
	(
		table => ["my_master","my_slave"],
		fields =>
		[
			{"my_master.my_i_m_id"=>"mi"},
			{"my_slave.my_i_s_id"=>"si"},
			{"my_master.my_s_m_code"=>"ms"},
			{"my_slave.my_s_s_code"=>"ss"},
	       	],
		where =>
		[
			"my_master.my_s_m_code" => "\\my_slave.my_s_m_code"
		],
		cursor_key =>
		[
			"ms",
			"ss",
		],
		cursor_order => SQL_SIMPLE_ORDER_DESC,
		cursor_info => \%cursor,
		cursor_command => SQL_SIMPLE_CURSOR_LAST,
		buffer => \@buffer,
		limit => 10,
	);
	return 0 if (&testRC($dbh,"1894","my_autoincrement_1"));
	$first = $buffer[0]->{ms}.".".$buffer[0]->{ss};
	$ended = $buffer[9]->{ms}.".".$buffer[9]->{ss};
	diag("Expected: master_0009.slave_0019, master_0009.slave_0010");
	diag("Buffer..: ".$first.", ".$ended);
	diag("keys....: ".join(".",@{$cursor{first}}).", ".join(".",@{$cursor{last}}));
	&myOK($cursor{lines}==10 && $first eq "master_0009.slave_0019" && $ended eq "master_0009.slave_0010","1895","Cursor expected page-LAST");
}

################################################################################

sub test_all_Standard_Select()
{
	my $dbh = shift;
	my $contents = shift;

	&myDIAG("Select");

	foreach my $table(sort(keys(%{$contents})))
	{
		next if (!($table =~ /^my_standard_/));

		my $er1=0;
		my $er2=0;
		my $warn=0;
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
					next;
				}
				if ($dbh->getRows()==0)
				{
					$warn++;
					diag("WARNING: table $table is empty, where $field => [ $ref->{$field} ] ");
				}
				$ok2++;
			}
		}
		&myOK($er1==0 && $er2==0,"1401","Standard Select Test completed, table: ".$table.", ok: ".$ok1."/".$ok2.", errors: ".$er1."/".$er2.", warning(s): ".$warn);
	}
}

################################################################################

sub test_Autoincrement_Cursor_Insert()
{
	my $dbh = shift;
	my $contents = shift;

	&myDIAG("Insert Autoincrement");

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
		(&testRC($dbh,"1501","my_autoincrement_1")) ? $er++ : $ok++;
	}
	&myOK($er==0,"1502","Insert Autoincrement completed, ok: ".$ok.", errors: ".$er);
}

################################################################################

sub test_Master_Insert()
{
	my $dbh = shift;
	my $contents = shift;

	&myDIAG("Insert Master/Slave");

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
		(&testRC($dbh,"1601","my_master")) ? $er++ : $ok++;

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
			(&testRC($dbh,"1602","my_slave")) ? $er++ : $ok++;
		}
		&myOK($er==0,"1603","Insert Master/Slave completed, ok: ".$ok.", errors: ".$er);
	}

	&myDIAG("Insert Master with duplicate state");

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
		if (&testRC($dbh,"1611","my_master"))
		{
			$er++;
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
		if (&testRC($dbh,"1612","my_master"))
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
		if (&testRC($dbh,"1613","my_master"))
		{
			$er++;
			next;
		}
		&myOK($mydesc eq $update,"1614","code ".$code);
	}
	&myOK($er==0,"1615","Insert Master with duplicate state, errors: ".$er);
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

sub test_all_Standard_Insert()
{
	my $dbh = shift;
	my $contents = shift;

	&myDIAG("Insert Standard");

	my $no=0;
	my $ok=0;
	foreach my $table(sort(keys(%{$contents})))
	{
		next if (!($table =~ /^my_standard_/));

		$no++;

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
				&myOK(0,"1701","Field Invalid Type ".$contents->{$table}{info}{$field}{T});
			}
		}

		$dbh->Insert( table=>$table, fields=>\%fields );
		next if (&testRC($dbh,"1702",$table));

		$dbh->Insert( table=>$table, fields=>\@fields, values=>\@values );
		next if (&testRC($dbh,"1703",$table));

		if (@fields==1)
		{
			$dbh->Insert( table=>$table, fields=>\@fields, values=>\@values2 );
			return 1 if (&testRC($dbh,"1704",$table));
		}
		else
		{
			$dbh->Insert( table=>$table, fields=>\@fields, values=>\@values1 );
			return 1 if (&testRC($dbh,"1705",$table));
		}
		$ok++;
	}
	&myOK($ok==$no,"1710","Insert Standard completed, tables: ".$no.", errors ".($no-$ok));
}

################################################################################

sub testOPEN()
{
	my $options = {@_};

	my $dbh = SQL::SimpleOps->new ( %{$options}, message_log => 0 );
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
	my $cod = shift;
	my $tbl = shift;

	my $cmd = $dbh->getLastSQL();
	my ($hdr) = split(" ",$cmd);
	my $rc = $dbh->getRC();

	if ($rc)
	{
		fail("test-D".$cod." ".$hdr." ".$tbl);
		diag("Code...: ".$rc);
		diag("Message: ".$dbh->getMessage());
		diag("Command: ".$cmd);
		&DONE() if ($ENV{EXIT_ON_FIRT_ERROR});
		return 1;
	}
	else
	{
#		diag("test-D".$cod." ".$hdr." ".$tbl." successful");
	}
	diag($dbh->getLastSQL()) if (defined($ENV{SQL_SIMPLE_DB_SHOW_SQL}) && $ENV{SQL_SIMPLE_DB_SHOW_SQL} eq "1");
	return $rc;
}

################################################################################

sub myDIAG()
{
	diag("################################################################################");

	foreach my $msg(@_)
	{
		diag($msg);
	}
}

################################################################################

sub myOK()
{
	my $chk = shift;
	my $cod = shift;
	my $msg = shift;

	my $rc = ok($chk,"test-D".$cod.": ".$msg);

	&DONE() if (!$chk && $ENV{EXIT_ON_FIRT_ERROR});

	return $rc;
}

################################################################################

sub DONE()
{
	diag("");

	if ($ENV{EXIT_ON_FIRT_ERROR})
	{
		diag("##########################################");
		diag("##  ENV{EXIT_ON_FIRT_ERROR} is enabled  ##");
		diag("##########################################");
	}

	done_testing();
	exit(0);
}

__END__
