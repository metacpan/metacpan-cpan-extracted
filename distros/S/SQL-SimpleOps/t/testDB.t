#!/usr/bin/perl
#
## LICENSE AND COPYRIGHT
# 
## Copyright (C) 2022 Carlos Celso
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

	BEGIN{ use_ok('SQL::SimpleOps'); };

	my $dir = ($0 =~ /^(.*)\/(.*)/) ? $1 : "";
	$dir = getcwd()."/".$dir if (!($dir =~ /^\//));
	unshift(@INC,$dir);

################################################################################

	$ENV{SQL_SIMPLE_DB_CREATE_ALLOWED} = "" if (!defined$ENV{SQL_SIMPLE_DB_CREATE_ALLOWED});
	$ENV{SQL_SIMPLE_DB_SKIP_CREATE} = "" if (!defined$ENV{SQL_SIMPLE_DB_SKIP_CREATE});
	$ENV{SQL_SIMPLE_DB_SHOW_CREATE} = "" if (!defined$ENV{SQL_SIMPLE_DB_SHOW_CREATE});

	my $test=0;
	$test++ if ($ENV{SQL_SIMPLE_DB_CREATE_ALLOWED} eq "1");
	$test++ if ($ENV{SQL_SIMPLE_DB_SKIP_CREATE} eq "1");
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

	require "$dir/testDB_sqlite.pm";
	require "$dir/testDB_mysql.pm";
	require "$dir/testDB_postgres.pm";

	diag("");

	&SQLite_do($dir);

	&MySQL_do($dir);

	&PG_do($dir);

	done_testing();
	exit;

################################################################################

sub testGeneric()
{
	my $dbh = shift;
	my $contents = shift;

	diag("INI000 Removing previous data");

	my @tables = sort(keys(%{$contents}));

	## removing previous data
	if ($ENV{SQL_SIMPLE_DB_SHOW_CONTENTS})
	{
		require Data::Dumper;
		print Data::Dumper->Dumper(\@tables,$contents);
	}
	foreach my $table (@tables)
	{
		$dbh->Delete ( table=>$table, force => 1, notfound => 1 );
		return if ($dbh->getRC());
	}

	&testGenericStandardInsert($dbh,$contents);
	&testGenericAutoincrementInsert($dbh,$contents);
	&testGenericMasterSlaveInsert($dbh,$contents);
	&testGenericStandardSelect($dbh,$contents);
	&testGenericAutoincrementSelect($dbh,$contents);
	&testGenericAutoincrementUpdate($dbh,$contents);
	&testGenericAutoincrementDelete($dbh,$contents);
	&testGenericMasterSlaveSelect($dbh,$contents);

	$dbh->Close();
}

################################################################################

sub testGenericMasterSlaveSelect()
{
	my $dbh = shift;
	my $contents = shift;
	my @buffer;

	note("MSS010 Merge");

	$dbh->Select
	(
		table => "my_master",
		buffer => \@buffer,
		order_by => "my_i_m_id",
	);
	&testRC($dbh,"MSS010",$dbh);
	ok($dbh->getRows()==10,"Master select, expected 10, found ".$dbh->getRows());

	$dbh->Select
	(
		table => "my_slave",
		buffer => \@buffer,
		order_by => "my_i_s_id",
	);
	&testRC($dbh,"MSS020",$dbh);
	ok($dbh->getRows()==100,"Slave select, expected 100, found ".$dbh->getRows());

	$dbh->Select
	(
		table => [ "my_master","my_slave" ],
		buffer => \@buffer,
		fields => [ "my_master.my_s_m_code", "my_slave.my_s_s_code" ],
	);
	&testRC($dbh,"MSS030",$dbh);
	ok($dbh->getRows()==1000,"Master/Slave merge-1, expected 1000, found ".$dbh->getRows());

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
	&testRC($dbh,"MSS040",$dbh);
	ok($dbh->getRows()==100,"Master/Slave merge-2, expected 100, found ".$dbh->getRows());

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
	&testRC($dbh,"MSS050",$dbh);
	ok($dbh->getRows()==900,"Master/Slave merge-3, expected 900, found ".$dbh->getRows());

	diag("MSS100 Grouped");

	$dbh->Select
	(
		table => [ "my_slave" ],
		fields => [ "my_s_m_code", "count(my_s_s_code)" ],
		group_by => "my_s_m_code",
		buffer => \@buffer,
	);
	&testRC($dbh,"MSS110",$dbh);
	ok($dbh->getRows()==10,"Slave grouped-1, expected 10 masters, found ".$dbh->getRows());

	foreach my $ref(@buffer)
	{
		ok($ref->{my_s_s_code} == 10,"Slave grouped-2, expected 10 slaves, found ".$ref->{my_s_s_code});
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
	&testRC($dbh,"DEL010",$dbh);
	$dbh->Select
	(
		table => "my_autoincrement_1",
		buffer => \@buffer,
	);
	&testRC($dbh,"DEL020",$dbh);
	ok($dbh->getRows() == 10,"Delete expected 10, found ".$dbh->getRows());
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
	&testRC($dbh,"UPD010",$dbh);
	$dbh->Select
	(
		table => "my_autoincrement_1",
		where=>
		[
			my_i_no_2 => 9999
		],
		buffer => \@buffer,
	);
	&testRC($dbh,"UPD020",$dbh);
	ok($dbh->getRows() == 10,"Update expected 10, found ".$dbh->getRows());
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
	return 0 if (&testRC($dbh,"CUR010",$dbh));
	ok($cursor{lines}==10 && $cursor{first}==1 && $cursor{last}==10,"SelectCursor first-page, expected first(1) last(10) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");

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
	return 0 if (&testRC($dbh,"CUR020",$dbh));
	ok($cursor{lines}==10 && $cursor{first}==11 && $cursor{last}==20,"SelectCursor goto-page2, expected first(11) last(20) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");

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
	return 0 if (&testRC($dbh,"CUR030",$dbh));
	ok($cursor{lines}==10 && $cursor{first}==1 && $cursor{last}==10,"SelectCursor return-first, expected first(1) last(10) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");

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
	return 0 if (&testRC($dbh,"CUR040",$dbh));
	ok($cursor{lines}==10 && $cursor{first}==11 && $cursor{last}==20,"SelectCursor return-page2, expected first(11) last(20) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");

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
	return 0 if (&testRC($dbh,"CUR050",$dbh));
	ok($cursor{lines}==10 && $cursor{first}==21 && $cursor{last}==30,"SelectCursor goto-page3, expected first(21) last(30) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");

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
	return 0 if (&testRC($dbh,"CUR060",$dbh));
	ok($cursor{lines}==10 && $cursor{first}==100 && $cursor{last}==91,"SelectCursor goto-last-page, expected first(100) last(91) lines(10), first($cursor{first}) last($cursor{last}) lines($cursor{lines})");
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
		if (&testRC($dbh,"SEL010",$dbh))
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
				if (&testRC($dbh,"SEL020",$dbh))
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
		pass("table ".$table.", ".$ok1." step1 sucessful") if ($ok1);
		pass("table ".$table.", ".$ok2." step2 sucessful") if ($ok2);
		fail("table ".$table.", ".$er1." step1 failure") if ($er1);
		fail("table ".$table.", ".$er2." step2 failure") if ($er2);
		fail("table ".$table.", ".$er3." step3 failure") if ($er3);
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
		(&testRC($dbh,"AUT010",$dbh)) ? $er++ : $ok++;
	}
	fail($er." inserted errors") if ($er);
	pass($ok." inserted successful") if ($ok);
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
		(&testRC($dbh,"IMS010",$dbh)) ? $er++ : $ok++;

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
			(&testRC($dbh,"IMS020",$dbh)) ? $er++ : $ok++;
		}
		fail("Number of ".$er." errors (master+slave), Code ".$code) if ($er);
		pass("Number of ".$ok." successful (master+slave), Code ".$code) if ($ok);
	}

	note("IMS100 Insert Master with duplicate state");

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
		if (&testRC($dbh,"IMS110",$dbh))
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
		if (&testRC($dbh,"IMS120",$dbh))
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
		if (&testRC($dbh,"IMS130",$dbh))
		{
			$no++;
			next;
		}
		ok($mydesc eq $update,"insert with conflict/duplicate for ".$code);
	}
	fail("Number of ".$no." notkey") if ($no);
	fail("Number of ".$er." errors") if ($er);
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
				fail("Field Invalid Type ".$contents->{$table}{info}{$field}{T});
			}
		}

		$dbh->Insert( table=>$table, fields=>\%fields );
		if (&testRC($dbh,"STD010",$dbh))
		{
			print STDERR $dbh->getLastSQL(),"\n";
			fail("Insert-1, ".$table.", ".$dbh->getMessage());
		}
		else { pass("Insert-1, ".$table); }

		$dbh->Insert( table=>$table, fields=>\@fields, values=>[ \@values ] );
		if (&testRC($dbh,"STD020",$dbh))
		{
			print STDERR $dbh->getLastSQL(),"\n";
			fail("Insert-2, ".$table.", ".$dbh->getMessage());
		}
		else { pass("Insert-2, ".$table); }

		if (@fields==1)
		{
			$dbh->Insert( table=>$table, fields=>\@fields, values=>\@values2 );
			if (&testRC($dbh,"STD030",$dbh))
			{
				print STDERR $dbh->getLastSQL(),"\n";
				fail("Insert-3, ".$table.", ".$dbh->getMessage());
			}
			else { pass("Insert-3, ".$table); }
		}
		else
		{
			$dbh->Insert( table=>$table, fields=>\@fields, values=>\@values1 );
			if (&testRC($dbh,"STD040",$dbh))
			{
				print STDERR $dbh->getLastSQL(),"\n";
				fail("Insert-4, ".$table.", ".$dbh->getMessage());
			}
			else { pass("Insert-4, ".$table); }
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

	diag($dbh->getLastSQL()) if (defined($ENV{SQL_SIMPLE_DB_SHOW_SQL}) && $ENV{SQL_SIMPLE_DB_SHOW_SQL} eq "1");
	if ($dbh->getRC())
	{
		fail($msg.", ".$dbh->getMessage());
		return 1;
	}
	return 0;
}

__END__
