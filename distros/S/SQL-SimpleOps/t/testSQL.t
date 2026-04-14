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
## message module code
#
## callWithout			S01~S05
## callInsertWith		S06
## callDeleteWith		S07
## callUpdateWith		S08
## callSelectSimplesWith	S09
## callSelectCursorWith		S10
## callselectHavingWith		S11
## callSelectGroupByWith	S14
## callSelectOrderByWith	S15
## callSelectSubQueryWith	S16
## callWhereWith		S20
#
	use strict;
	use warnings;
	use Test::More;

	our $VERSION = "2026.101.1";

	BEGIN{ use_ok('SQL::SimpleOps'); }

###############################################################################
## enable this option to abort on first error

	#$ENV{EXIT_ON_FIRT_ERROR} = 1;

###############################################################################
## global environments

	diag("################################################################");
	diag("STAGE0 - STAGE0 - STAGE0");

	our $myStage;
	our $savedir = &testRWfolder($ENV{'TEMP'}) || &testRWfolder("/tmp") || &testRWfolder("/usr/tmp") || &testRWfolder("/var/tmp") || &testRWfolder("/home");
	
	our $mymod;
	our @er;
	our $ok;
	our $show_ok = (defined($ENV{SQL_SIMPLE_SQL_SHOW_OK}) && $ENV{SQL_SIMPLE_SQL_SHOW_OK} ne "");

	diag("temporary R/W folder: ".($savedir || "undefined"));

	&testWithContents();
	&testWithoutContents();

	diag("################################################################");
	fail((@er+0)." error, tests: ".join(", ",@er)) if (@er);
	pass($ok." successful") if ($ok);

	if (!defined($ENV{SQL_SIMPLE_WHERE_SHOW_OK}) || $ENV{SQL_SIMPLE_WHERE_SHOW_OK} eq "")
	{
		diag("");
		diag("To see the input options used to create the 'where' clause, rerun the test with:");
		diag("");
		diag("export SQL_SIMPLE_SQL_SHOW_OK=1");
	}
	&DONE();
	exit(0);

#######################################################################
## Test r/w folder

sub testRWfolder()
{
	my $fd = shift;

	return undef if (!defined($fd) || $fd eq "");
	stat($fd) || return undef;

	my $fn = $fd."/simpleops_dummy_file.txt";
	open(my $fh, ">", $fn) || return undef;

	close($fh);
	undef($fh);
	unlink($fn);
	return $fd;
}

#######################################################################
## STAGE1 - Tests using CONTENTS TABLES (see STAGE2

sub testWithContents()
{
	diag("################################################################");
	diag("STAGE1 - STAGE1 - STAGE1");

	$myStage = 1;

	$mymod = new SQL::SimpleOps
	(
		db => "teste",			# you can use any database name
		driver => "sqlite",		# you can use any database engine
		dbfile => ":memory:",		# use ram memory
		connect => 0,			# do not open database
		sql_save_dir => $savedir,	# savedir test
		sql_save_bydate => 1,		# split logfile by date folders
		tables =>
		{
			tab_alias1 =>
			{
				name => 'tab_real1',
				cols =>
				{
					fld_alias1 => 'fld_real1',
					fld_alias2 => 'fld_real2',
					fld_aliasX => 'fld_realX',
				},
			},
			tab_alias2 =>
			{
				name => 'tab_real2',
				cols =>
				{
					fld_alias1 => 'fld_real1',
					fld_alias2 => 'fld_real2',
					fld_aliasY => 'fld_realY',
				},
			},
			tab_alias3 =>
			{
				name => 'tab_real3',
			},
		},
		message_log => 0,		# disable stdout
	);
	if (!$mymod->getRC())
	{
		&callDeleteWith();
		&callInsertWith();
		&callUpdateWith();
		&callSelectSimplesWith();
		&callSelectGroupByWith();
		&callSelectHavingWith();
		&callSelectOrderByWith();
		&callSelectCursorWith();
		&callSelectSubqueryWith();
		&callWhereWith();
	}
	$mymod->Close();
}

#######################################################################
## STAGE2 - Testes without CONTENTS TABLES

sub testWithoutContents()
{
	diag("################################################################");
	diag("STAGE2 - STAGE2 - STAGE2");

	$myStage = 2;
	$mymod = new SQL::SimpleOps
	(
		db => "teste",			# you can use any database name
		driver => "sqlite",		# you can use any database engine
		dbfile => ":memory:",		# use ram memory
		connect => 0,			# do not open database
		sql_save_dir => $savedir,	# savedir test
		sql_save_bydate => 1,		# split logfile by date folders
		message_log => 0,		# disable stdout
	);
	if (!$mymod->getRC())
	{
		&callWithout();
	}
	$mymod->Close();
}

#######################################################################
## my tests

sub callDeleteWith()
{
	&my_cmd
	(
		f=> "0700",
		s=> sub
	       	{
	       		$mymod->Delete( table => "tab_noalias", force => 1,
		      		make_only=>1)
		},
		t=> 'Delete( table => "tab_noalias", force => 1 )',
		r=> "DELETE FROM tab_noalias",
	);
	&my_cmd
	(
		f=> "0701",
		s=> sub
	       	{
	       		$mymod->Delete( table => "tab_alias1", force => 1,
		      		make_only=>1)
		},
		t=> 'Delete( table => "tab_alias1", force => 1 )',
		r=> "DELETE FROM tab_real1",
	);
	&my_cmd
	(
		f=> "0702",
		s=> sub
	       	{
	       		$mymod->Delete( table => "tab_real1", force => 1,
		      		make_only=>1)
		},
		t=> 'Delete( table => "tab_real1", force => 1 )',
		r=> "DELETE FROM tab_real1",
	);
	&my_cmd
	(
		f=> "0710",
		s=> sub
	       	{
	       		$mymod->Delete( table => "tab_noalias1", force => 1,
		      		make_only=>1)
		},
		t=> 'Delete( table => "tab_alias1", force => 1 )',
		r=> "DELETE FROM tab_noalias1",
	);
	&my_cmd
	(
		f=> "0711",
		s=> sub
	       	{
	       		$mymod->Delete( table => "tab_alias1", force => 1,
		      		make_only=>1)
		},
		t=> 'Delete( table => "tab_alias1", force => 1 )',
		r=> "DELETE FROM tab_real1",
	);
}

################################################################################

sub callInsertWith()
{
	&my_cmd
	(
		f=> "0600",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_noalias", fields => { "fld_alias1" => "value1" },
			make_only=>1)
		},
		t=> 'Insert( table => "tab_noalias", fields => { "fld_alias1" => "value1" } )',
		r=> "INSERT INTO tab_noalias (fld_alias1) VALUES ('value1')",
	);
	&my_cmd
	(
		f=> "0601",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_noalias", fields => [ "fld_alias1" ], values => [ "value1" ],
				make_only=>1)
		},
		t=> 'Insert( table => "tab_noalias", fields => [ "fld_alias1" ], values => [ "value1" ]',
		r=> "INSERT INTO tab_noalias (fld_alias1) VALUES ('value1')",
	);
	&my_cmd
	(
		f=> "0602",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_noalias", fields => { "fld_alias1" => "value1", "fld_alias2" => "value2" },
				make_only=>1)
		},
		t=> 'Insert( table => "tab_noalias", fields => { "fld_alias1" => "value1", "fld_alias2" => "value2" } )',
		r=> "INSERT INTO tab_noalias (fld_alias1,fld_alias2) VALUES ('value1','value2')",
	);
	&my_cmd
	(
		f=> "0603",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_noalias", fields => [ "fld_alias1","fld_alias2" ], values => [ "value1","value2" ],
				make_only=>1)
		},
		t=> 'Insert( table => "tab_noalias", fields => [ "fld_alias1","fld_alias2" ], values => [ "value1","value2" ] )',
		r=> "INSERT INTO tab_noalias (fld_alias1,fld_alias2) VALUES ('value1','value2')",
	);
	&my_cmd
	(
		f=> "0604",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_noalias", fields => [ "fld_alias1" ], values => [ "value1","value2" ],
		      		make_only=>1)
		},
		t=> 'Insert( table => "tab_noalias", fields => [ "fld_alias1" ], values => [ "value1","value2" ] )',
		r=> "INSERT INTO tab_noalias (fld_alias1) VALUES ('value1'),('value2')",
	);
	&my_cmd
	(
		f=> "0605",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_noalias", fields => [ "tab_noalias.fld_alias1" ], values => [ "value1" ],
		      		make_only=>1)
		},
		t=> 'Insert( table => "tab_noalias", fields => [ "tab_noalias.fld_alias1" ], values => [ "value1" ] )',
		r=> "INSERT INTO tab_noalias (fld_alias1) VALUES ('value1')",
	);
	&my_cmd
	(
		f=> "0607",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_noalias", fields => [ "bad_table.fld_alias1" ], values => [ "value1" ],
		      		make_only=>1)
		},
		t=> 'Insert( table => "tab_noalias", fields => [ "bad_table.fld_alias1" ], values => [ "value1" ] )',
		r=> "INSERT INTO tab_noalias (bad_table.fld_alias1) VALUES ('value1')",
	);
	&my_cmd
	(
		f=> "0608",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_alias1", fields => { "fld_alias1" => "value1" },
				make_only=>1)
		},
		t=> 'Insert( table => "tab_alias1", fields => { "fld_alias1" => "value1" } )',
		r=> "INSERT INTO tab_real1 (fld_real1) VALUES ('value1')",
	);
	&my_cmd
	(
		f=> "0609",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_real1", fields => { "fld_alias1" => "value1" },
		      		make_only=>1)
		},
		t=> 'Insert( table => "tab_real1", fields => { "fld_alias1" => "value1" } )',
		r=> "INSERT INTO tab_real1 (fld_real1) VALUES ('value1')",
	);
	&my_cmd
	(
		f=> "0610",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_alias1", fields => { "tab_alias1.fld_alias1" => "value1" },
		      		make_only=>1)
		},
		t=> 'Insert( table => "tab_alias1", fields => { "tab_alias1.fld_alias1" => "value1" } )',
		r=> "INSERT INTO tab_real1 (fld_real1) VALUES ('value1')",
	);
	&my_cmd
	(
		f=> "0611",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_real1", fields => { "tab_real1.fld_alias1" => "value1" },
		      		make_only=>1)
		},
		t=> 'Insert( table => "tab_real1", fields => { "tab_real1.fld_alias1" => "value1" } )',
		r=> "INSERT INTO tab_real1 (fld_real1) VALUES ('value1')",
	);
	&my_cmd
	(
		f=> "0612",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_alias1", fields => { "tab_alias1.fld_real1" => "value1" },
		      		make_only=>1)
		},
		t=> 'Insert( table => "tab_alias1", fields => { "tab_alias1.fld_real1" => "value1" } )',
		r=> "INSERT INTO tab_real1 (fld_real1) VALUES ('value1')",
	);
	&my_cmd
	(
		f=> "0613",
		s=> sub
	       	{
	       		$mymod->Insert( table => "tab_real1", fields => { "tab_real1.fld_real1" => "value1" },
		      		make_only=>1)
		},
		t=> 'Insert( table => "tab_real1", fields => { "tab_real1.fld_alias1" => "value1" } )',
		r=> "INSERT INTO tab_real1 (fld_real1) VALUES ('value1')",
	);
}

################################################################################

sub callUpdateWith()
{
	&my_cmd
	(
		f=> "0800",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_noalias", fields => { "fld_alias1" => "value1" }, force => 1,
				make_only=>1)
		},
		t=> 'Update( table => "tab_noalias", fields => { "fld_alias1" => "value1" }, force => 1',
		r=> "UPDATE tab_noalias SET fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "0802",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_noalias", fields => { "fld_alias1" => "value1", "fld_alias2" => "value2" }, force => 1,
				make_only=>1)
		},
		t=> 'Update( table => "tab_noalias", fields => { "fld_alias1" => "value1", "fld_alias2" => "value2" }, force => 1 )',
		r=> "UPDATE tab_noalias SET fld_alias1 = 'value1', fld_alias2 = 'value2'",
	);
	&my_cmd
	(
		f=> "0803",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_alias1", fields => { "fld_alias1" => "value1" }, force => 1,
				make_only=>1)
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_alias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "0804",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_real1", fields => { "fld_alias1" => "value1" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => "tab_real1", fields => { "fld_alias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "0805",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_alias1", fields => { "fld_alias1" => "value1", "fld_alias2" => "value2", }, force => 1,
				make_only=>1)
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_alias1" => "value1", "fld_alias2" => "value2", }, force => 1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value1', fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "0806",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_real1", fields => { "fld_alias1" => "value1", "fld_alias2" => "value2", }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => "tab_real1", fields => { "fld_alias1" => "value1", "fld_alias2" => "value2", }, force => 1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value1', fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "0810",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_alias1", fields => { "fld_noalias" => "value1" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_noalias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 SET fld_noalias = 'value1'",
	);
	&my_cmd
	(
		f=> "0811",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_real1", fields => { "fld_noalias" => "value1" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => "tab_real1", fields => { "fld_noalias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 SET fld_noalias = 'value1'",
	);
	&my_cmd
	(
		f=> "0812",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_noalias", fields => { "tab_noalias.fld_alias1" => "value1" }, force => 1,
				make_only=>1)
		},
		t=> 'Update( table => "tab_noalias", fields => { "tab_noalias.fld_alias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_noalias SET fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "0813",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_noalias", fields => { "tab_noalias.fld_alias1" => "value1", "tab_noalias.fld_alias2" => "value2" }, force => 1,
				make_only=>1)
		},
		t=> 'Update( table => "tab_noalias", fields => { "tab_noalias.fld_alias1" => "value1", "tab_noalias.fld_alias2" => "value2" }, force => 1 )',
		r=> "UPDATE tab_noalias SET fld_alias1 = 'value1', fld_alias2 = 'value2'",
	);
	&my_cmd
	(
		f=> "0814",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_alias1", fields => { "tab_alias1.fld_alias1" => "value1" }, force => 1,
				make_only=>1)
		},
		t=> 'Update( table => "tab_alias1", fields => { "tab_alias1.fld_alias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "0815",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => "value1" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "0816",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_alias1", fields => { "tab_alias1.fld_noalias" => "value1" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => "tab_alias1", fields => { "tab_alias1.fld_noalias" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 SET fld_noalias = 'value1'",
	);
	&my_cmd
	(
		f=> "0817",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_real1", fields => { "tab_real1.fld_noalias" => "value1" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => "tab_real1", fields => { "tab_real1.fld_noalias" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 SET fld_noalias = 'value1'",
	);
	&my_cmd
	(
		f=> "0818",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_alias1", fields => { "bad_alias1.fld_alias1" => "value1" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => "tab_alias1", fields => { "bad_alias1.fld_alias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 tab_alias1 SET bad_alias1.fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "0819",
		s=> sub
	       	{
	       		$mymod->Update( table => "tab_real1", fields => { "bad_alias1.fld_alias1" => "value1" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => "tab_real1", fields => { "bad_alias1.fld_alias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 tab_alias1 SET bad_alias1.fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "0820",
		s=> sub
	       	{
	       		$mymod->Update( table => ["tab_noalias1","tab_noalias2"], fields => { "tab_noalias1.fld_alias1" => "value1", "tab_noalias2.fld_alias2" => "value2", }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => ["tab_noalias1","tab_noalias2"], fields => { "tab_noalias1.fld_alias1" => "value1", "tab_noalias2.fld_alias2" => "value2", }, force => 1 )',
		r=> "UPDATE tab_noalias1, tab_noalias2 SET tab_noalias1.fld_alias1 = 'value1', tab_noalias2.fld_alias2 = 'value2'",
	);
	&my_cmd
	(
		f=> "0821",
		s=> sub
	       	{
	       		$mymod->Update( table => ["tab_alias1","tab_noalias2"], fields => { "bad_alias1.fld_alias1" => "value1" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => ["tab_alias1","tab_noalias2"], fields => { "bad_alias1.fld_alias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 tab_alias1, tab_noalias2 SET bad_alias1.fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "0822",
		s=> sub
	       	{
	       		$mymod->Update( table => ["tab_alias1","tab_alias2"], fields => { "tab_alias1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => ["tab_alias1","tab_alias2"], fields => { "tab_alias1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" }, force => 1 )',
		r=> "UPDATE tab_real1 tab_alias1, tab_real2 tab_alias2 SET tab_alias1.fld_real1 = 'value1', tab_alias2.fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "0823",
		s=> sub
	       	{
	       		$mymod->Update( table => ["tab_alias1","tab_real2"], fields => { "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => ["tab_alias1","tab_real2"], fields => { "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" }, force => 1 )',
		r=> "UPDATE tab_real1 tab_alias1, tab_real2 tab_alias2 SET tab_alias1.fld_real1 = 'value1', tab_alias2.fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "0824",
		s=> sub
	       	{
	       		$mymod->Update( table => ["tab_alias1","tab_alias2"], fields => { "tab_alias1.fld_alias1" => "value1", "tab_real2.fld_noalias" => "value2" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => ["tab_alias1","tab_alias2"], fields => { "tab_alias1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" }, force => 1 )',
		r=> "UPDATE tab_real1 tab_alias1, tab_real2 tab_alias2 SET tab_alias1.fld_real1 = 'value1', tab_alias2.fld_noalias = 'value2'",
	);
	&my_cmd
	(
		f=> "0825",
		s=> sub
	       	{
	       		$mymod->Update( table => ["tab_alias1","tab_real2"], fields => { "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_noalias" => "value2" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => ["tab_alias1","tab_real2"], fields => { "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" }, force => 1 )',
		r=> "UPDATE tab_real1 tab_alias1, tab_real2 tab_alias2 SET tab_alias1.fld_real1 = 'value1', tab_alias2.fld_noalias = 'value2'",
	);
	&my_cmd
	(
		f=> "0826",
		s=> sub
	       	{
	       		$mymod->Update( table => ["tab_alias1","tab_real2"], fields => { "bad_alias.fld_alias1" => "value1" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => ["tab_alias1","tab_real2"], fields => { "bad_alias.fld_alias1" => "value1" }, force => 1 )',
		r=> "UPDATE tab_real1 tab_alias1, tab_real2 tab_alias2 SET bad_alias.fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "0827",
		s=> sub
	       	{
	       		$mymod->Update( table => ["tab_alias1","tab_real2"], fields => { "bad_alias.fld_alias1" => "value1", "tab_alias1.fld_alias1" => "value2" }, force => 1,
		      		make_only=>1)
		},
		t=> 'Update( table => ["tab_alias1","tab_real2"], fields => { "bad_alias.fld_alias1" => "value1", "tab_alias1.fld_alias1" => "value2" }, force => 1 )',
		r=> "UPDATE tab_real1 tab_alias1, tab_real2 tab_alias2 SET bad_alias.fld_alias1 = 'value1', tab_alias1.fld_real1 = 'value2'",
	);
}

################################################################################

sub callSelectSimplesWith()
{
	&my_cmd
	(
		f=> "0900",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_noalias", fields => "fld_alias1",
				make_only=>1)
		},
		t=> 'Select( table => "tab_noalias", fields => "fld_alias1" )',
		r=> "SELECT fld_alias1 FROM tab_noalias",
	);
	&my_cmd
	(
		f=> "0901",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_noalias", fields => [ "fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_noalias", fields => [ "fld_alias1" ] )',
		r=> "SELECT fld_alias1 FROM tab_noalias",
	);
	&my_cmd
	(
		f=> "0902",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => "fld_alias1",
				make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => "fld_alias1" )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0903",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0904",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => "fld_alias1",
				make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => "fld_alias1" )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0905",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ "fld_alias1" ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0906",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => [ "fld_real1" ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_real1" ] )',
		r=> "SELECT fld_real1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0907",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ "fld_real1" ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ "fld_real1" ] )',
		r=> "SELECT fld_real1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0908",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => [ "fld_noalias" ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_noalias" ] )',
		r=> "SELECT fld_noalias FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0909",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ "fld_noalias" ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ "fld_noalias" ] )',
		r=> "SELECT fld_noalias FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0910",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_noalias", fields => "tab_noalias.fld_alias1",
				make_only=>1)
		},
		t=> 'Select( table => "tab_noalias", fields => "tab_noalias.fld_alias1" )',
		r=> "SELECT tab_noalias.fld_alias1 FROM tab_noalias",
	);
	&my_cmd
	(
		f=> "0911",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => [ "tab_alias1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ "tab_alias1.fld_alias1" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0912",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => [ "tab_real1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ "tab_real1.fld_alias1" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0913",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ "tab_alias1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ "tab_alias1.fld_alias1" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0914",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ "tab_real1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ "tab_real1.fld_alias1" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "0915",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ "bad_alias1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ "bad_alias1.fld_alias1" ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "0916",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ "bad_real1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ "bad_real1.fld_alias1" ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "0917",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_noalias", fields => [ "bad_alias1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_noalias", fields => [ "bad_alias1.fld_alias1" ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "0918",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_noalias", fields => [ "bad_real1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_noalias", fields => [ "bad_real1.fld_alias1" ] )',
		r=> "",
		syntax=>1,
	);

	&my_cmd
	(
		f=> "0919",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_noalias1","tab_noalias2"], fields => "fld_alias1",
				make_only=>1)
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"], fields => "fld_alias1"',
		r=> "SELECT fld_alias1 FROM tab_noalias1, tab_noalias2"
	);
	&my_cmd
	(
		f=> "0920",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_noalias1","tab_noalias2"], fields => [ "fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"], fields => [ "fld_alias1" ] )',
		r=> "SELECT fld_alias1 FROM tab_noalias1, tab_noalias2",
	);
	&my_cmd
	(
		f=> "0921",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => "fld_alias1",
				make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => "fld_alias1" )',
		r=> "SELECT fld_alias1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
		n=> "The fld_alias1 defined in both tables, cannot translate, use: [table].[field]",
	);
	&my_cmd
	(
		f=> "0922",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "fld_real1" ],
		      		make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "fld_real1" ] )',
		r=> "SELECT fld_real1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "0923",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => "fld_alias1",
				make_only=>1)
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => "fld_alias1" )',
		r=> "SELECT fld_alias1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
		n=> "The fld_alias1 defined in both tables, cannot translate, use: [table].[field]",
	);
	&my_cmd
	(
		f=> "0924",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ "fld_real1" ],
		      		make_only=>1)
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => [ "fld_real1" ] )',
		r=> "SELECT fld_real1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "0925",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "fld_noalias" ],
		      		make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "fld_noalias" ] )',
		r=> "SELECT fld_noalias FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "0926",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ "fld_noalias" ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ "fld_noalias" ] )',
		r=> "SELECT fld_noalias FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "0927",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_noalias1","tab_noalias2"], fields => "tab_noalias.fld_alias1",
				make_only=>1)
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"], fields => "tab_noalias.fld_alias1 )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "0928",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "0929",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_real1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_real1.fld_alias1" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "0930",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "0931",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ "tab_real1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => [ "tab_real1.fld_alias1" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "0932",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ "bad_alias1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => [ "bad_alias1.fld_alias1" ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "0933",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ "bad_real1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => [ "bad_real1.fld_alias1" ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "0934",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_noalias1","tab_noalias2"], fields => [ "bad_alias1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"], fields => [ "bad_alias1.fld_alias1" ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "0935",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_noalias1","tab_noalias2"], fields => [ "bad_real1.fld_alias1" ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"], fields => [ "bad_real1.fld_alias1" ] )',
		r=> "",
		syntax=>1,
	);

	##############################################################################
	## contents tests for SELECT and Alias on fields

	&my_cmd
	(
		f=> "1000",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_noalias", fields => [ {"fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_noalias", fields => [ {"fld_alias1"=>"my1"} ] )',
		r=> "SELECT fld_alias1 my1 FROM tab_noalias",
	);
	&my_cmd
	(
		f=> "1001",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1002",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ {"fld_alias1"=>"my1"} ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ {"fld_alias1"=>"my1"} ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1003",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => [ {"fld_real1"=>"my1"} ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_real1"=>"my1"} ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1004",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ {"fld_real1"=>"my1"} ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ {"fld_real1"=>"my1"} ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1005",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => [ {"fld_noalias"=>"my1"} ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_noalias"=>"my1} ] )',
		r=> "SELECT fld_noalias my1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1006",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ {"fld_noalias"=>"my1"} ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ {"fld_noalias"=>"my1"} ] )',
		r=> "SELECT fld_noalias my1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1007",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => [ {"tab_alias1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"tab_alias1.fld_alias1"=>"my1"} ] )',
		r=> "SELECT tab_alias1.fld_real1 my1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1008",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => [ {"tab_real1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"tab_real1.fld_alias1"=>"my1"} ] )',
		r=> "SELECT tab_alias1.fld_real1 my1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1009",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ {"tab_alias1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ {"tab_alias1.fld_alias1"=>"my1"} ] )',
		r=> "SELECT tab_alias1.fld_real1 my1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1010",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ {"tab_real1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ {"tab_real1.fld_alias1"=>"my1"} ] )',
		r=> "SELECT tab_alias1.fld_real1 my1 FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1011",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ {"bad_alias1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ {"bad_alias1.fld_alias1"=>"my1"} ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "1012",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1", fields => [ {"bad_real1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ {"bad_real1.fld_alias1"=>"my1"} ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "1013",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_noalias", fields => [ {"bad_alias1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_noalias", fields => [ {"bad_alias1.fld_alias1"=>"my1"} ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "1014",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_noalias", fields => [ {"bad_real1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => "tab_noalias", fields => [ {"bad_real1.fld_alias1"=>"my1"} ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "1015",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_noalias1","tab_noalias2"], fields => [ {"fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"], fields => [ {"fld_alias1"=>"my1"} ] )',
		r=> "SELECT fld_alias1 my1 FROM tab_noalias1, tab_noalias2",
	);
	&my_cmd
	(
		f=> "1016",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"fld_real1"=>"my1"} ],
		      		make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"fld_real1"=>"my1"} ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "1017",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ {"fld_real1"=>"my1"} ],
		      		make_only=>1)
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => [ {"fld_real1"=>"my1"} ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "1018",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"fld_noalias"=>"my1"} ],
		      		make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"fld_noalias"=>"my1"} ] )',
		r=> "SELECT fld_noalias my1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "1019",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ {"fld_noalias"=>"my1"} ],
		      		make_only=>1)
		},
		t=> 'Select( table => "tab_real1", fields => [ {"fld_noalias"=>"my1"} ] )',
		r=> "SELECT fld_noalias my1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "1020",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"} ] )',
		r=> "SELECT tab_alias1.fld_real1 my1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "1021",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_real1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_real1.fld_alias1"=>"my1"} ] )',
		r=> "SELECT tab_alias1.fld_real1 my1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "1022",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"} ] )',
		r=> "SELECT tab_alias1.fld_real1 my1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "1023",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ {"tab_real1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => [ {"tab_real1.fld_alias1"=>"my1"} ] )',
		r=> "SELECT tab_alias1.fld_real1 my1 FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "1024",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ {"bad_alias1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => [ {"bad_alias1.fld_alias1"=>"my1"} ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "1025",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ {"bad_real1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => [ {"bad_real1.fld_alias1"=>"my1"} ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "1026",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_noalias1","tab_noalias2"], fields => [ {"bad_alias1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"], fields => [ {"bad_alias1.fld_alias1"=>"my1"} ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "1027",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_noalias1","tab_noalias2"], fields => [ {"bad_real1.fld_alias1"=>"my1"} ],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"], fields => [ {"bad_real1.fld_alias1"=>"my1"} ] )',
		r=> "",
		syntax=>1,
	);
	&my_cmd
	(
		f=> "1028",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_noalias1",
				make_only=>1)
		},
		t=> 'Select( table => "tab_noalias1" )',
		r=> "SELECT * FROM tab_noalias1",
	);
	&my_cmd
	(
		f=> "1029",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1",
				make_only=>1)
		},
		t=> 'Select( table => "tab_alias1" )',
		r=> "SELECT fld_real1 fld_alias1, fld_real2 fld_alias2, fld_realX fld_aliasX FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1030",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_real1",
				make_only=>1)
		},
		t=> 'Select( table => "tab_real1" )',
		r=> "SELECT fld_real1 fld_alias1, fld_real2 fld_alias2, fld_realX fld_aliasX FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1031",
		s=> sub
	       	{
	       		$mymod->Select( table => "tab_alias1", fields => "*",
				make_only=>1)
		},
		t=> 'Select( table => "tab_alias1", fields => "*" )',
		r=> "SELECT * FROM tab_real1 tab_alias1",
	);
	&my_cmd
	(
		f=> "1032",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => "*",
				make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => "*" )',
		r=> "SELECT * FROM tab_real1 tab_alias1, tab_real2 tab_alias2",
	);
	&my_cmd
	(
		f=> "1032",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_alias1","tab_noalias"], fields => "*",
				make_only=>1)
		},
		t=> 'Select( table => ["tab_alias1","tab_noalias"], fields => "*" )',
		r=> "SELECT * FROM tab_real1 tab_alias1, tab_noalias",
	);
	&my_cmd
	(
		f=> "1033",
		s=> sub
	       	{
	       		$mymod->Select( table => ["tab_noalias1","tab_noalias2"],
				make_only=>1)
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"] )',
		r=> "SELECT * FROM tab_noalias1, tab_noalias2",
	);

}

##############################################################################
## contents tests for HAVING

sub callSelectHavingWith()
{
	&my_cmd
	(
		f=> "1101",
		s=> sub
		{
			$mymod->Select( table => "tab_noalias", having => [ "count(fld_alias1)" => 1 ], make_only=>1 )
		},
		t=> 'Select( table => "tab_noalias", having => [ "count(fld_alias1)" => 1 ] )',
		r=> "SELECT * FROM tab_noalias HAVING count(fld_alias1) = '1'",
	);
	&my_cmd
	(
		f=> "1102",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], having => [ "count(fld_alias1)" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], having => [ "count(fld_alias1)" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 HAVING count(fld_real1) = 'value1'",
	);
	&my_cmd
	(
		f=> "1103",
		s=> sub
		{
			$mymod->Select( table => "tab_real1", fields => [ "fld_alias1" ], having => [ "count(fld_alias1)" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_real1", fields => [ "fld_alias1" ], having => [ "fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 HAVING count(fld_real1) = 'value1'",
	);
	&my_cmd
	(
		f=> "1104",
		s=> sub
		{
			$mymod->Select( table => "tab_real1", fields => [ "fld_alias1" ], having =>
				[
					"count(fld_alias1)" => [ '>', "value1" ], 
					"count(fld_alias1)" => [ '<', "value2" ]
				], make_only=>1 )
		},
		t=> 'Select( table => "tab_real1", fields => [ "fld_alias1" ], having => [ "fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 HAVING count(fld_real1) > 'value1' AND count(fld_real1) < 'value2'",
	);
}

##############################################################################
## contents tests for WHERE

sub callWhereWith()
{
	&my_cmd
	(
		f=> "2001",
		s=> sub
		{
			$mymod->Delete( table => "tab_noalias", where => [ "fld_alias1" => 1 ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_noalias", where => [ "fld_alias1" => 1 ], make_only=>1 )',
		r=> "DELETE FROM tab_noalias WHERE fld_alias1 = '1'",
	);
	&my_cmd
	(
		f=> "2002",
		s=> sub
		{
			$mymod->Delete( table => "tab_alias1", where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_alias1", where => [ "fld_alias1" => "value1" ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2003",
		s=> sub
		{
			$mymod->Delete( table => "tab_real1", where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_real1", where => [ "fld_alias1" => "value1" ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2004",
		s=> sub
		{
			$mymod->Delete( table => "tab_alias1", where => [ "fld_noalias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_alias1", where => [ "fld_noalias1" => 1 ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_noalias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2005",
		s=> sub
		{
			$mymod->Delete( table => "tab_alias1", where => [ "fld_real1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_alias1", where => [ "fld_real1" => 1 ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2006",
		s=> sub
		{
			$mymod->Delete( table => "tab_noalias", where => [ "tab_noalias.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_noalias", where => [ "tab_noalias.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "DELETE FROM tab_noalias WHERE fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2007",
		s=> sub
		{
			$mymod->Delete( table => "tab_alias1", where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_alias1", where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2008",
		s=> sub
		{
			$mymod->Delete( table => "tab_real1", where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_real1", where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2009",
		s=> sub
		{
			$mymod->Delete( table => "tab_real1", where => [ "tab_alias1.fld_alias1" => "xx'xx" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_real1", where => [ "tab_alias1.fld_alias1" => "xx\'xx" ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'xx\\'xx'",
	);
	&my_cmd
	(
		f=> "2020",
		s=> sub
		{
			$mymod->Update( table => "tab_noalias", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_noalias", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ], make_only=>1 )',
		r=> "UPDATE tab_noalias SET fld_alias1 = 'value2' WHERE fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2021",
		s=> sub
		{
			$mymod->Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ] )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2022",
		s=> sub
		{
			$mymod->Update( table => "tab_real1", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_real1", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ] )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2023",
		s=> sub
		{
			$mymod->Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_noalias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_noalias1" => "value1" ] )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_noalias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2024",
		s=> sub
		{
			$mymod->Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_real1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_real1" => 1 ], make_only=>1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2025",
		s=> sub
		{
			$mymod->Update( table => "tab_noalias", fields => { "fld_alias1" => "value2" }, where => [ "tab_noalias.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_noalias", fields => { "fld_alias1" => "value2" }, where => [ "tab_noalias.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "UPDATE tab_noalias SET fld_alias1 = 'value2' WHERE fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2026",
		s=> sub
		{
			$mymod->Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2027",
		s=> sub
		{
			$mymod->Update( table => "tab_real1", fields => { "fld_alias1" => "value2" }, where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_real1", fields => { "fld_alias1" => "value2" }, where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2028",
		s=> sub
		{
			$mymod->Update( table => ["tab_noalias1","tab_noalias2"], fields => { "tab_noalias1.fld_alias1" => "value2", "tab_noalias2.fld_alias2" => "value1" }, where => [ "tab_noalias1.fld_alias1" => "value1", "tab_noalias2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Update( table => ["tab_noalias1","tab_noalias2"], fields => { "tab_noalias1.fld_alias1" => "value2", "tab_noalias2.fld_alias2" => "value1" }, where => [ "tab_noalias1.fld_alias1" => "value1", "tab_noalias2.fld_alias2" => "value2" ] )',
		r=> "UPDATE tab_noalias1, tab_noalias2 SET tab_noalias1.fld_alias1 = 'value2', tab_noalias2.fld_alias2 = 'value1' WHERE tab_noalias1.fld_alias1 = 'value1' AND tab_noalias2.fld_alias2 = 'value2'",
	);
	&my_cmd
	(
		f=> "2029",
		s=> sub
		{
			$mymod->Update( table => ["tab_alias1","tab_alias2"], fields => { "tab_alias1.fld_alias1" => "value2", "tab_alias2.fld_alias2" => "value1" }, where => [ "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Update( table => ["tab_alias1","tab_alias2"], fields => { "tab_alias1.fld_alias1" => "value2", "tab_alias2.fld_alias2" => "value1" }, where => [ "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" ] )',
		r=> "UPDATE tab_real1 tab_alias1, tab_real2 tab_alias2 SET tab_alias1.fld_real1 = 'value2', tab_alias2.fld_real2 = 'value1' WHERE tab_alias1.fld_real1 = 'value1' AND tab_alias2.fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "2030",
		s=> sub
		{
			$mymod->Update( table => ["tab_real1","tab_real2"], fields => { "tab_real1.fld_alias1" => "value2", "tab_real2.fld_alias2" => "value1" }, where => [ "tab_real1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Update( table => ["tab_real1","tab_real2"], fields => { "tab_real1.fld_alias1" => "value2", "tab_real2.fld_alias2" => "value1" }, where => [ "tab_real1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" ] )',
		r=> "UPDATE tab_real1 tab_alias1, tab_real2 tab_alias2 SET tab_alias1.fld_real1 = 'value2', tab_alias2.fld_real2 = 'value1' WHERE tab_alias1.fld_real1 = 'value1' AND tab_alias2.fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "2031",
		s=> sub
		{
			$mymod->Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => undef }, where => [ "tab_real1.fld_alias1" => undef ], make_only=>1 )
		},
		t=> 'Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => undef }, where => [ "tab_real1.fld_alias1" => undef ]',
		r=> "UPDATE tab_real1 SET fld_real1 = NULL WHERE fld_real1 IS NULL",
	);
	&my_cmd
	(
		f=> "2032",
		s=> sub
		{
			$mymod->Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => undef }, where => [ "tab_real1.fld_alias1" => [ "!", undef ] ], make_only=>1 )
		},
		t=> 'Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => undef }, where => [ "tab_real1.fld_alias1" => [ "!", undef ] ]',
		r=> "UPDATE tab_real1 SET fld_real1 = NULL WHERE fld_real1 IS NOT NULL",
	);
	&my_cmd
	(
		f=> "2033",
		s=> sub
		{
			$mymod->Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => "xx'xx" }, where => [ "tab_real1.fld_alias1" => "yy'yy" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => \'xx\\\'xx\' }, where => [ "tab_real1.fld_alias1" => \'yy\\\'yy\' ]',
		r=> "UPDATE tab_real1 SET fld_real1 = 'xx\\'xx' WHERE fld_real1 = 'yy\\'yy'",
	);
	&my_cmd
	(
		f=> "2050",
		s=> sub
		{
			$mymod->Select( table => "tab_noalias", where => [ "fld_alias1" => 1 ], make_only=>1 )
		},
		t=> 'Select( table => "tab_noalias", where => [ "fld_alias1" => 1 ], make_only=>1 )',
		r=> "SELECT * FROM tab_noalias WHERE fld_alias1 = '1'",
	);
	&my_cmd
	(
		f=> "2051",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2052",
		s=> sub
		{
			$mymod->Select( table => "tab_real1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_real1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2053",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_noalias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_noalias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_noalias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2054",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_real1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_real1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2055",
		s=> sub
		{
			$mymod->Select( table => "tab_noalias", fields => [ "fld_alias1" ], where => [ "tab_noalias.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_noalias", fields => [ "fld_alias1" ], where => [ "tab_noalias.fld_alias1" => "value1" ] )',
		r=> "SELECT fld_alias1 FROM tab_noalias WHERE fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2056",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "tab_alias1.fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2057",
		s=> sub
		{
			$mymod->Select( table => "tab_real1", fields => [ "fld_alias1" ], where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_real1", fields => [ "fld_alias1" ], where => [ "tab_alias1.fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2058",
		s=> sub
		{
			$mymod->Select( table => ["tab_noalias1","tab_noalias2"], fields => [ "tab_noalias1.fld_alias1", "tab_noalias2.fld_alias2" ], where => [ "tab_noalias1.fld_alias1" => "value1", "tab_noalias2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"], fields => [ "tab_noalias1.fld_alias1", "tab_noalias2.fld_alias2" ], where => [ "tab_noalias1.fld_alias1" => "value1", "tab_noalias2.fld_alias2" => "value2" ] )',
		r=> "SELECT tab_noalias1.fld_alias1, tab_noalias2.fld_alias2 FROM tab_noalias1, tab_noalias2 WHERE tab_noalias1.fld_alias1 = 'value1' AND tab_noalias2.fld_alias2 = 'value2'",
	);
	&my_cmd
	(
		f=> "2059",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = 'value1' AND tab_alias2.fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "2060",
		s=> sub
		{
			$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ "tab_real1.fld_alias1", "tab_real2.fld_alias2" ], where => [ "tab_real1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => [ "tab_real1.fld_alias1", "tab_real2.fld_alias2" ], where => [ "tab_real1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = 'value1' AND tab_alias2.fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "2061",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_alias1.fld_alias1" => "\\tab_alias2.fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias1"], fields => [ "tab_real1.fld_alias1", "tab_real2.fld_alias2" ], where => [ "tab_alias1.fld_alias1" => "\\tab_alias2.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2062",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_alias1.fld_real1" => "\\tab_alias2.fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias1"], fields => [ "tab_real1.fld_alias1", "tab_real2.fld_alias2" ], where => [ "tab_alias1.fld_alias1" => "\\tab_alias2.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2063",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_real1.fld_alias1" => "\\tab_real2.fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias1"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_real1.fld_alias1" => "tab_real1.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2064",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_real1.fld_real1" => "\\tab_real2.fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias1"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_real1.fld_real1" => "\\tab_real1.fld_real2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2065",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2066",
		s=> sub
		{
			$mymod->Select( table => "tab_real1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_real1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2067",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_noalias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_noalias1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_noalias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2068",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2069",
		s=> sub
		{
			$mymod->Select( table => "tab_real1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_real1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2070",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_real1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_real1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2071",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_real1.fld_real1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_real1.fld_real1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "2071",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.fld_alias1" => "\\tab_alias2.fld_alias2" ], make_only=>1 ),
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.fld_alias1" => "tab_alias2.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2072",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.fld_real1" => "\\tab_alias2.fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.fld_real1" => "tab_alias2.fld_real2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2073",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.fld_alias1" => "\\tab_real2.fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.fld_alias1" => "tab_real2.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2074",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.fld_real1" => "\\tab_real2.fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.fld_real1" => "tab_real2.fld_real2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2075",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "my1" => "\\my2" ], make_only=>1 )
		},
		e=> 'SQL command error --  matched [table].[field] is required',
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "my1" => "\\my2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2076",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.my1" => "\\tab_alias2.my2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.my1" => "\\tab_alias2.my2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2077",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.my1" => "\\tab_real2.my2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.my1" => "\\tab_real2.my2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2078",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_noalias1.my1" => "\\tab_alias2.my2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_noalias1.my1" => "\\tab_alias2.my2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_noalias1.my1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "2079",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.my1" => "\\tab_noalias2.my2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alas1.my1" => "\\tab_noalias2.my2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_noalias2.my2",
	);
}

################################################################################

sub callWithout()
{
	&my_cmd
	(
		f=> "0110",
		s=> sub { $mymod->Delete( table=>"t1", where => [ fld => 123 ], make_only=>1 ) },
		t=> 'Delete( table=>"t1", where => [ fld => 123 ] )',
		r=> "DELETE FROM t1 WHERE fld = '123'",
	);
	&my_cmd
	(
		f=> "0120",
		s=> sub { $mymod->Insert( table=>"t1", fields => { a => 1, b => 2, c => 3 }, make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => { a => 1, b => 2, c => 3 } )',
		r=> "INSERT INTO t1 (a,b,c) VALUES ('1','2','3')",
	);
	&my_cmd
	(
		f=> "0121",
		s=> sub { $mymod->Insert( table=>"t1", fields => { a => undef, b => undef, c => undef }, make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => { a => undef, b => undef, c => undef } )',
		r=> "INSERT INTO t1 (a,b,c) VALUES (NULL,NULL,NULL)",
	);
	&my_cmd
	(
		f=> "0122",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a","b","c" ], values => [ 1,2,3 ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a","b","c" ], values => [ 1,2,3 ] )',
		r=> "INSERT INTO t1 (a,b,c) VALUES ('1','2','3')",
	);
	&my_cmd
	(
		f=> "0123",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a","b","c" ], values => [ undef,undef,undef ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a","b","c" ], values => [ undef,undef,undef ] )',
		r=> "INSERT INTO t1 (a,b,c) VALUES (NULL,NULL,NULL)",
	);
	&my_cmd
	(
		f=> "0124",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a" ], values => [ 1,2,3 ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a","b","c" ], values => [ 1,2,3 ] )',
		r=> "INSERT INTO t1 (a) VALUES ('1'),('2'),('3')",
	);
	&my_cmd
	(
		f=> "0125",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a" ], values => [ undef,undef,undef ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a","b","c" ], values => [ undef,undef,undef ] )',
		r=> "INSERT INTO t1 (a) VALUES (NULL),(NULL),(NULL)",
	);
	&my_cmd
	(
		f=> "0126",
		s=> sub { $mymod->Insert( table=>"t1", fields => { a => "xx'xx" }, make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => { a => "xx\'xx" )',
		r=> "INSERT INTO t1 (a) VALUES ('xx\\\'xx')",
	);
	&my_cmd
	(
		f=> "0127",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a" ], values => [ "xx'xx" ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a" ], values => [ "xx\'xx" ] )',
		r=> "INSERT INTO t1 (a) VALUES ('xx\\\'xx')",
	);
	&my_cmd
	(
		f=> "0128",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a" ], values => [ "xx'xx","yy'yy" ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a" ], values => [ "xx\'xx","yy\'yy" ] )',
		r=> "INSERT INTO t1 (a) VALUES ('xx\\\'xx'),('yy\\\'yy')",
	);
	&my_cmd
	(
		f=> "0130",
		s=> sub { $mymod->Update( table=>"t1", fields => { a => 1, b => 2 }, where => [ c => [ "!", 3 ] ], make_only=>1 ) },
		t=> 'Update( table=>"t1", fields => { a => 1, b => 2 }, where => [ c => [ "!", 3 ] ] )',
		r=> "UPDATE t1 SET b = '2', a = '1' WHERE c != '3'",
		r2=>"UPDATE t1 SET a = '1', b = '2' WHERE c != '3'",
	);
	&my_cmd
	(
		f=> "0140",
		s=> sub { $mymod->Update( table=>"t1", fields => { a => '\\concat(a,"xxxx")' }, force => 1, make_only=>1 ) },
		t=> 'Update( table=>"t1", fields => { a => \'\\concat(a,"xxxx")\' }, force => 1 )',
		r=> "UPDATE t1 SET a = concat(a,\"xxxx\")",
	);
	&my_cmd
	(
		f=> "0150",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"] )',
		r=> "SELECT a, b, c FROM t1",
	);
	&my_cmd
	(
		f=> "0160",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4 ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4 ] )',
		r=> "SELECT a, b, c FROM t1 WHERE d = '4'",
	);
	&my_cmd
	(
		f=> "0170",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4, e=>5 ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4, e=>5 ] )',
		r=> "SELECT a, b, c FROM t1 WHERE d = '4' AND e = '5'",
	);
	&my_cmd
	(
		f=> "0180",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>'\substr(e,1,8)' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>\'\\substr(e,1,8)\' ] )',
		r=> "SELECT a, b, c FROM t1 WHERE d = substr(e,1,8)",
	);
	&my_cmd
	(
		f=> "0190",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ 't1.a' => '\t2.b' ], make_only=>1) },
		t=> 'Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ "t1.a" => "\\t2.b" ] )',
		r=> "SELECT t1.a, t2.b FROM t1, t2 WHERE t1.a = t2.b",
	);
	&my_cmd
	(
		f=> "0200",
		s=> sub { $mymod->Select( table=>"t1", fields => [ {"a"=>"aa"} ], where => [ 'a' => '0' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ {"a"=>"aa"} ], where => [ \'a\' => \'0\' ] )',
		r=> "SELECT a aa FROM t1 WHERE a = '0'",
	);
	&my_cmd
	(
		f=> "0210",
		s=> sub { $mymod->Select( table=>"t1", fields => [ {"t1.a"=>"aa"} ], where => [ 't1.a' => '0' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ {"t1.a"=>"aa"} ], where => [ \'t1.a\' => \'0\' ] )',
		r=> "SELECT t1.a aa FROM t1 WHERE a = '0'",
	);
	&my_cmd
	(
		f=> "0220",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [ {"t1.a"=>"aa"} , {"t2.b"=>"bb"} ], where => [ 't1.a' => '\\t2.b' ], make_only=>1) },
		t=> 'Select( table=>["t1","t2"], fields => [ {"t1.a"=>"aa"}, {"t2.b"=>"bb"} ], where => [ "t1.a" => "\\t2.b" ] )',
		r=> "SELECT t1.a aa, t2.b bb FROM t1, t2 WHERE t1.a = t2.b",
	);
	&my_cmd
	(
		f=> "0230",
		s=> sub { $mymod->Select( table=>"t1", fields => [ {"sum(a)"=>"a1"}, {"sum(t1.a)"=>"a2"}, {"\\sum(a)"=>"a3"} ], where => [ 'a' => '0' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ {"sum(a)"=>"a1"}, {"sum(t1.a)"=>"a2"}, {"\\sum(a)"=>"a3"} ], where => [ \'a\' => \'0\' ] )',
		r=> "SELECT sum(a) a1, sum(t1.a) a2, sum(a) a3 FROM t1 WHERE a = '0'",
	);
	&my_cmd
	(
		f=> "0320",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "distinct","a" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "distinct", "a" ] )', 
		r=> "SELECT DISTINCT a FROM t1",
		n=> 'Select with DISTINCT array sequence',
	);
	&my_cmd
	(
		f=> "0330",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "distinct" => "a" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "distinct" => "a" ] )', 
		r=> "SELECT DISTINCT a FROM t1",
		n=> 'Select with DISTINCT based hash',
	);
	&my_cmd
	(
		f=> "0340",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "count(*)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "count(*)" ] )', 
		r=> "SELECT count(*) FROM t1",
	);
	&my_cmd
	(
		f=> "0350",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "max(t1.a)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "max(t1.a)" ] )', 
		r=> "SELECT max(t1.a) FROM t1",
	);
	&my_cmd
	(
		f=> "0360",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "max(a)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "max(a)" ] )', 
		r=> "SELECT max(a) FROM t1",
	);
	&my_cmd
	(
		f=> "0370",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "substr(a,1,8)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "substr(a,1,8)" ] )', 
		r=> "SELECT substr(a,1,8) FROM t1",
	);
	&my_cmd
	(
		f=> "0380",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "\\aaa.bbb.ccc" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "\\aaa.bbb.ccc" ] )', 
		r=> "SELECT aaa.bbb.ccc FROM t1",
	);
	&my_cmd
	(
		f=> "0390",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "distinct","\\aaa.bbb.ccc" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "distinct","\\aaa.bbb.ccc" ] )', 
		r=> "SELECT DISTINCT aaa.bbb.ccc FROM t1",
	);
	&my_cmd
	(
		f=> "0400",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ 't1.a' => 't2.b' ], make_only=>1, sql_save=>1 ) },
		t=> 'Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ \'t1.a\' => \'t2.b\' ], sql_save=>1 )',
		r=> "SELECT t1.a, t2.b FROM t1, t2 WHERE t1.a = t2.b",
		n=> "SQL_SAVE enabled",
		w=> 1,
	);
	&my_cmd
	(
		f=> "0410",
		s=> sub { $mymod->Select( table=>"t1", order_by => "t1.a",  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => "t1.a" )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a",
	);
	&my_cmd
	(
		f=> "0420",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ {"t1.a" => "asc"} ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ {"t1.a" => "asc"} ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a ASC",
	);
	&my_cmd
	(
		f=> "0430",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ {"t1.a" => "desc"} ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ {"t1.a" => "desc"} ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a DESC",
	);
	&my_cmd
	(
		f=> "0440",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ "t1.a", "t1.b" ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ "t1.a", "t1.b" ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a, t1.b",
	);
	&my_cmd
	(
		f=> "0450",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ {"t1.a" => "asc"}, "t1.b" ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ {"t1.a" => "asc"}, "t1.b" ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a ASC, t1.b",
	);
	&my_cmd
	(
		f=> "0460",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ "t1.a",{"t1.b"=>"desc"} ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ "t1.a", {"t1.b"=>"desc"} ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a, t1.b DESC",
	);
	&my_cmd
	(
		f=> "0470",
		s=> sub { $mymod->Select( table=>"t1", order_by => {"t1.b"=>"desc"},  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => {"t1.b"=>"desc"} )', 
		r=> "SELECT * FROM t1 ORDER BY t1.b DESC",
	);
	&my_cmd
	(
		f=> "0480",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t1.fgh"=>"_fgh"}], where => [ "_abc" => 123 ],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t1.fgh"=>"_fgh"}], where => [ "_abc" => 123 ] )', 
		r=> "SELECT t1.abc _abc, t1.cde, t1.fgh _fgh FROM t1 WHERE abc = '123'",
	);
	&my_cmd
	(
		f=> "0481",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t1.fgh"=>"_fgh"}], where => [ "_abc" => 123, "cde" => 234, "t1.abc" => 345],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t1.fgh"=>"_fgh"}], where => [ "_abc" => 123, "cde" => 234, "t1.abc" => 345] )', 
		r=> "SELECT t1.abc _abc, t1.cde, t1.fgh _fgh FROM t1 WHERE abc = '123' AND cde = '234' AND abc = '345'",
	);
	&my_cmd
	(
		f=> "0490",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t2.fgh"=>"_fgh"},"t2.ijk"], where => [ "_abc" => 123, "cde" => 234, "t1.abc" => 345, "ijk" => 456],  make_only=>1) },
		t=> 'Select( table=>["t1","t2"], fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t2.fgh"=>"_fgh"},"t2.ijk"], where => [ "_abc" => 123, "cde" => 234, "t1.abc" => 345, "ijk" => 456] )',
		r=> "SELECT t1.abc _abc, t1.cde, t2.fgh _fgh, t2.ijk FROM t1, t2 WHERE t1.abc = '123' AND cde = '234' AND t1.abc = '345' AND ijk = '456'",
	);
	&my_cmd
	(
		f=> "0500",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "substr(_a,1,4)" => 1234 ],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "substr(_a,1,4)" => 1234 ] )',
		r=> "SELECT t1.abc _a FROM t1 WHERE substr(abc,1,4) = '1234'",
	);
	&my_cmd
	(
		f=> "0510",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "concat(substr(_a,1,4),1)" => 1231 ],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "concat(substr(_a,1,3),1)" => 1231 ] )',
		r=> "SELECT t1.abc _a FROM t1 WHERE concat(substr(abc,1,4),1) = '1231'",
	);
	&my_cmd
	(
		f=> "0520",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "func1(func2(_a))" => 1231 ],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "func1(func2(_a))" => 1231 ] )',
		r=> "SELECT t1.abc _a FROM t1 WHERE func1(func2(abc)) = '1231'",
	);
	&my_cmd
	(
		f=> "0530",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "func1(_a)" => 123, "func1(t1.abc)" => 456 ],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "func1(_a)" => 123, "func1(t1.abc)" => 456 ] )',
		r=> "SELECT t1.abc _a FROM t1 WHERE func1(abc) = '123' AND func1(t1.abc) = '456'",
	);
	&my_cmd
	(
		f=> "0540",
		s=> sub { $mymod->Select( table=>"t1", fields => ["count(t1.abc)"],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [count(t1.abc)] )',
		r=> "SELECT count(t1.abc) FROM t1",
	);
   &my_cmd
	(
			f=> "0541",
			s=> sub { $mymod->Select( table=>"t1", fields => [{"count(t1.abc)"=>"a"}],  make_only=>1) },
			t=> 'Select( table=>"t1", fields => [{count(t1.abc)=>"a"}] )',
			r=> "SELECT count(t1.abc) a FROM t1",
	);
   &my_cmd
	(
			f=> "0542",
			s=> sub { $mymod->Select( table=>"t1", fields => [{"count(*)"=>"a"}],  make_only=>1) },
			t=> 'Select( table=>"t1", fields => [{count(*)=>"a"}] )',
			r=> "SELECT count(*) a FROM t1",
	);
   &my_cmd
	(
			f=> "0543",
			s=> sub { $mymod->Select( table=>"t1", fields => [{"count()"=>"a"}],  make_only=>1) },
			t=> 'Select( table=>"t1", fields => [{count()=>"a"}] )',
			r=> "SELECT count() a FROM t1",
	);
	&my_cmd
	(
		f=> "0550",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => ["count(t1.abc)"],  make_only=>1) },
		t=> 'Select( table=>["t1","t2"], fields => [count(t1.abc)] )',
		r=> "SELECT count(t1.abc) FROM t1, t2",
	);
   &my_cmd
	(
			f=> "0551",
			s=> sub { $mymod->Select( table=>["t1","t2"], fields => [{"count(t1.abc)"=>"a"}],  make_only=>1) },
			t=> 'Select( table=>["t1","t2"], fields => [{count(t1.abc)=>"a"}] )',
			r=> "SELECT count(t1.abc) a FROM t1, t2",
	);
   &my_cmd
	(
			f=> "0552",
			s=> sub { $mymod->Select( table=>["t1","t2"], fields => [{"count(*)"=>"a"}],  make_only=>1) },
			t=> 'Select( table=>["t1","t2"], fields => [{count(*)=>"a"}] )',
			r=> "SELECT count(*) a FROM t1, t2",
	);
   &my_cmd
	(
			f=> "0553",
			s=> sub { $mymod->Select( table=>["t1","t2"], fields => [{"count()"=>"a"}],  make_only=>1) },
			t=> 'Select( table=>["t1","t2"], fields => [{count()=>"a"}] )',
			r=> "SELECT count() a FROM t1, t2",
	);
   &my_cmd
	(
			f=> "0560",
			s=> sub { $mymod->Select( table=>["t1","t2"], fields => ["func1()","func2(f1)",{"func3(f2)"=>"aa"},"func4(t1.f1)",{"func5(t2.f2)"=>"bb"}],  make_only=>1) },
			t=> 'Select( table=>["t1","t2"], fields => ["func1()","func2(f1)",{"func3(f2)"=>"aa"},"func4(t1.f1)",{"func5(t2.f2)"=>"bb"}] )',
			r=> "SELECT func1(), func2(f1), func3(f2) aa, func4(t1.f1), func5(t2.f2) bb FROM t1, t2",
	);
}

################################################################################

sub callSelectCursorWith()
{
	my %cursor;
	$cursor{first} = 1;
	$cursor{last} = 100;
	&my_cmd
	(
		f=> "1010",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_NEXT, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_NEXT, limit=>100 )', 
		n=> 'Command=NEXT, Cursor is first(1) and last(100)',
		r=> "SELECT a, b, c FROM t1 WHERE a > '100' ORDER BY a ASC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = 101;
	$cursor{last} = 200;
	&my_cmd
	(
		f=> "1011",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_BACK, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_BACK, limit=>100 )', 
		n=> 'Command=BACK, Cursor is first(101) and last(200)',
		r=> "SELECT a, b, c FROM t1 WHERE a < '101' ORDER BY a DESC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = 1;
	$cursor{last} = 100;
	&my_cmd
	(
		f=> "1012",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_RELOAD, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_RELOAD, limit=>100 )', 
		n=> 'Command=RELOAD, Cursor is first(1) and last(100)',
		r=> "SELECT a, b, c FROM t1 WHERE a >= '1' ORDER BY a ASC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = 1;
	$cursor{last} = 100;
	&my_cmd
	(
		f=> "1013",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_LAST, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_LAST, limit=>100 )', 
		n=> 'Command=LAST, Cursor is first(1) and last(100)',
		r=> "SELECT a, b, c FROM t1 ORDER BY a DESC LIMIT 100",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "1014",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_TOP, limit=>0, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_TOP, limit=>0 )', 
		r=> "SELECT a, b, c FROM t1 ORDER BY a ASC",
		n=> 'Command=TOP, Limit is ZERO',
		c=> \%cursor,
	);
	$cursor{first} = ['a',1];
	$cursor{last} = ['a',100];
	&my_cmd
	(
		f=> "1015",
		s=> sub { $mymod->SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100 )',
		n=> 'Option cursor_command is omited, curso_info was ignored',
		r=> "SELECT t1.a, t1.b, t2.c FROM t1, t2 ORDER BY t1.a ASC, t2.c ASC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = ['a',1];
	$cursor{last} = ['a',100];
	&my_cmd
	(
		f=> "1016",
		s=> sub { $mymod->SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, cursor_command=>SQL_SIMPLE_CURSOR_TOP, make_only=>1) },
		t=> 'SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, cursor_command=>SQL_SIMPLE_CURSOR_TOP )',
		n=> 'The cursor_info was ignored',
		r=> "SELECT t1.a, t1.b, t2.c FROM t1, t2 ORDER BY t1.a ASC, t2.c ASC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = ['a',1];
	$cursor{last} = ['a',100];
	&my_cmd
	(
		f=> "1017",
		s=> sub { $mymod->SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, cursor_command=>SQL_SIMPLE_CURSOR_NEXT, make_only=>1) },
		t=> 'SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, cursor_command=>SQL_SIMPLE_CURSOR_NEXT )',
		n=> '',
		r=> "SELECT t1.a, t1.b, t2.c FROM t1, t2 WHERE (t1.a > 'a' OR (t1.a = 'a' AND t2.c > '100')) ORDER BY t1.a ASC, t2.c ASC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = ['a',1];
	$cursor{last} = ['a',100];
	&my_cmd
	(
		f=> "1018",
		s=> sub { $mymod->SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, cursor_command=>SQL_SIMPLE_CURSOR_BACK, make_only=>1) },
		t=> 'SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, cursor_command=>SQL_SIMPLE_CURSOR_BACK ',
		n=> '',
		r=> "SELECT t1.a, t1.b, t2.c FROM t1, t2 WHERE (t1.a < 'a' OR (t1.a = 'a' AND t2.c < '1')) ORDER BY t1.a DESC, t2.c DESC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = ['a',1];
	$cursor{last} = ['a',100];
	&my_cmd
	(
		f=> "1019",
		s=> sub { $mymod->SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, cursor_command=>SQL_SIMPLE_CURSOR_LAST, make_only=>1) },
		t=> 'SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, cursor_command=>SQL_SIMPLE_CURSOR_LAST )',
		n=> '',
		r=> "SELECT t1.a, t1.b, t2.c FROM t1, t2 ORDER BY t1.a DESC, t2.c DESC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = ['a',1];
	$cursor{last} = ['a',100];
	&my_cmd
	(
		f=> "1020",
		s=> sub { $mymod->SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, cursor_command=>SQL_SIMPLE_CURSOR_RELOAD, make_only=>1) },
		t=> 'SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, cursor_command=>SQL_SIMPLE_CURSOR_RELOAD',
		n=> '',
		r=> "SELECT t1.a, t1.b, t2.c FROM t1, t2 WHERE (t1.a >= 'a' OR (t1.a = 'a' AND t2.c >= '1')) ORDER BY t1.a ASC, t2.c ASC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = ['a',1];
	$cursor{last} = ['a',100];
	&my_cmd
	(
		f=> "1021",
		s=> sub { $mymod->SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], where => ["t1.a" => "\\t2.a"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], where => ["t1.a" => "\\t2.a"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], limit=>100 )',
		n=> 'Cursor command is omitted, cursor_info was ignored',
		r=> "SELECT t1.a, t1.b, t2.c FROM t1, t2 WHERE t1.a = t2.a ORDER BY t1.a ASC, t2.c ASC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = ['a',1];
	$cursor{last} = ['a',100];
	&my_cmd
	(
		f=> "1022",
		s=> sub { $mymod->SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], where => ["t1.a" => "\\t2.a"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], cursor_command=>SQL_SIMPLE_CURSOR_RELOAD, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], where => ["t1.a" => "\\t2.a"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], cursor_command=>SQL_SIMPLE_CURSOR_RELOAD, limit=>100 )',
		n=> '',
		r=> "SELECT t1.a, t1.b, t2.c FROM t1, t2 WHERE t1.a = t2.a AND (t1.a >= 'a' OR (t1.a = 'a' AND t2.c >= '1')) ORDER BY t1.a ASC, t2.c ASC LIMIT 100",
		c=> \%cursor,
	);
	%cursor = {};
	&my_cmd
	(
		f=> "1023",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_TOP, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_TOP, limit=>100 )', 
		r=> "SELECT a, b, c FROM t1 ORDER BY a ASC LIMIT 100",
		n=> 'Command=TOP, Cursor is empty',
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "1024",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", limit=>100 )', 
		r=> "SELECT a, b, c FROM t1 ORDER BY a ASC LIMIT 100",
		n=> 'Command=TOP, Cursor is empty',
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "1025",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_NEXT, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_NEXT, limit=>100 )', 
		n=> 'Command=NEXT, Cursor is empty',
		r=> "SELECT a, b, c FROM t1 ORDER BY a ASC LIMIT 100",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "1026",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_BACK, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_BACK, limit=>100 )', 
		n=> 'Command=BACK, Cursor is empty',
		r=> "SELECT a, b, c FROM t1 ORDER BY a DESC LIMIT 100",
		c=> \%cursor,
	);
}

################################################################################

sub callSelectGroupByWith()
{
	&my_cmd
	(
		f=> "1400",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_alias1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_alias1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_real1",
	);
	&my_cmd
	(
		f=> "1401",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_real1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_real1" ], group_by => [ "fld_real1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_real1",
	);
	&my_cmd
	(
		f=> "1402",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_noalias" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_real1" ], group_by => [ "fld_noalias" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_noalias",
	);
	&my_cmd
	(
		f=> "1403",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_alias1","fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_alias1","fld_alias2" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_real1, fld_real2",
	);
	&my_cmd
	(
		f=> "1404",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_real1","fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_real1" ], group_by => [ "fld_real1","fld_real2" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_real1, fld_real2",
	);
	&my_cmd
	(
		f=> "1405",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_noalias1","fld_noalias2" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_real1" ], group_by => [ "fld_noalias1","fld_noalias2" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_noalias1, fld_noalias2",
	);
	&my_cmd
	(
		f=> "1406",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_alias1.fld_alias1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_alias1.fld_alias1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY tab_alias1.fld_real1",
	);
	&my_cmd
	(
		f=> "1407",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_alias1.fld_real1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_alias1.fld_real1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY tab_alias1.fld_real1",
	);
	&my_cmd
	(
		f=> "1408",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_alias1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_alias1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY tab_alias1.fld_real1",
	);
	&my_cmd
	(
		f=> "1409",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_real1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_real1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY tab_alias1.fld_real1",
	);
	&my_cmd
	(
		f=> "1410",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_noalias1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_noalias1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY tab_alias1.fld_noalias1",
	);
	&my_cmd
	(
		f=> "1411",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "fld_alias1","fld_alias2" ], group_by => [ "tab_real1.fld_alias1","tab_real2.fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "fld_alias1","fld_alias2" ], group_by => [ "tab_real1.fld_alias1","tab_real2.fld_alias2" ] )',
		r=> "SELECT fld_alias1, fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 GROUP BY tab_alias1.fld_real1, tab_alias2.fld_real2",
		n=> "The fld_alias1 & fld_alias2 defined in both tables, cannot translate, use: [table].[field]",
	);
	&my_cmd
	(
		f=> "1412",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "fld_alias1","fld_alias2" ], group_by => [ "tab_real1.fld_real1","tab_real2.fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "fld_alias1","fld_alias2" ], group_by => [ "tab_real1.fld_real1","tab_real2.fld_real2" ] )',
		r=> "SELECT fld_alias1, fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 GROUP BY tab_alias1.fld_real1, tab_alias2.fld_real2",
		n=> "The fld_alias1 & fld_alias2 defined in both tables, cannot translate, use: [table].[field]",
	);
	&my_cmd
	(
		f=> "1413",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "fld_alias1","fld_alias2" ], group_by => [ "tab_real1.fld_noalias1","tab_real2.fld_noalias2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "fld_alias1","fld_alias2" ], group_by => [ "tab_real1.fld_noalias1","tab_real2.fld_noalias2" ] )',
		r=> "SELECT fld_alias1, fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 GROUP BY tab_alias1.fld_noalias1, tab_alias2.fld_noalias2",
		n=> "The fld_alias1 & fld_alias2 defined in both tables, cannot translate, use: [table].[field]",
	);
	&my_cmd
	(
		f=> "1414",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"fld_alias1"=>"my1"},{"fld_alias2"=>"my2"} ], group_by => [ "tab_alias1.my1","tab_real1.my2" ], make_only=>1 )
		},
		e=> "translate the table name 'tab_real1' but 'my2' is not assigned in same table",
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"fld_alias1"=>"my1"},{"fld_alias2"->"my2"} ], group_by => [ "tab_alias1.my1","tab_alias1.my2" ] )',
		r=> "SELECT fld_alias1 my1, fld_alias2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 GROUP BY tab_alias1.my1, tab_alias1.my2",
	);

}

################################################################################

sub callSelectOrderByWith()
{
	&my_cmd
	(
		f=> "1500",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_alias1"=>"asc"} ], make_only=>1 )
		},
		n=> "lower case is supported",
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_alias1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY fld_real1 ASC",
	);
	&my_cmd
	(
		f=> "1501",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_alias1"=>"ASC"} ], make_only=>1 )
		},
		n=> "upper case is supported",
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_alias1"=>"ASC"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY fld_real1 ASC",
	);
	&my_cmd
	(
		f=> "1502",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_alias1"=>"AsC"} ], make_only=>1 )
		},
		n=> "mixed case is supported",
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_alias1"=>"AsC"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY fld_real1 ASC",
	);
	&my_cmd
	(
		f=> "1503",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_real1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_real1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY fld_real1 ASC",
	);
	&my_cmd
	(
		f=> "1504",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_noalias1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_noalias1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY fld_noalias1 ASC",
	);
	&my_cmd
	(
		f=> "1505",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_alias1"=>"desc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_alias1"=>"desc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY fld_real1 DESC",
	);
	&my_cmd
	(
		f=> "1506",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_alias1.fld_alias1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_alias1.fld_real1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_alias1.fld_real1 ASC",
	);
	&my_cmd
	(
		f=> "1507",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_real1.fld_real1"=>"desc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_real1.fld_real1"=>"desc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_alias1.fld_real1 DESC",
	);
	&my_cmd
	(
		f=> "1508",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_alias1.fld_real1"=>"desc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_alias1.fld_real1"=>"desc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_alias1.fld_real1 DESC",
	);
	&my_cmd
	(
		f=> "1509",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_real1.fld_alias1"=>"desc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_real1.fld_alias1"=>"desc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_alias1.fld_real1 DESC",
	);
	&my_cmd
	(
		f=> "1510",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_noalias1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_noalias1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_noalias.fld_noalias1 ASC",
	);
	&my_cmd
	(
		f=> "1511",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_alias1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_alias1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_noalias.fld_alias1 ASC",
	);
	&my_cmd
	(
		f=> "1512",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_real1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_real1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_noalias.fld_real1 ASC",
	);
	&my_cmd
	(
		f=> "1513",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ {"tab_alias1.fld_alias1"=>"asc"},{"tab_alias2.fld_alias2"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ {"tab_alias1.fld_alias1"=>"asc"},{"tab_alias2.fld_alias2"=>"asc"} ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 ORDER BY tab_alias1.fld_real1 ASC, tab_alias2.fld_real2 ASC",
	);
	&my_cmd
	(
		f=> "1514",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ {"tab_real1.fld_alias1"=>"asc"},{"tab_real2.fld_alias2"=>"asc"} ],make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ {"tab_real1.fld_alias1"=>"asc"},{"tab_real2.fld_alias2"=>"asc"} ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 ORDER BY tab_alias1.fld_real1 ASC, tab_alias2.fld_real2 ASC",
	);
	&my_cmd
	(
		f=> "1515",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ "tab_real1.fld_alias1","tab_real2.fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ "tab_real1.fld_alias1","tab_real2.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 ORDER BY tab_alias1.fld_real1, tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "1516",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => "tab_real1.fld_alias1", make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => "tab_real1.fld_alias1" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 ORDER BY tab_alias1.fld_real1",
	);
	&my_cmd
	(
		f=> "1517",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => {"tab_real1.fld_alias1"=>"desc"}, make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => {"tab_real1.fld_alias1"=>"desc"} )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 ORDER BY tab_alias1.fld_real1 DESC",
	);

}

################################################################################

sub callSelectSubqueryWith()
{
	&my_cmd
	(
		f=> "1600",
		s=> sub
		{
			$mymod->Select
			(
		       		table => "tab_alias1",
				fields => [ "fld_alias1" ],
				where =>
				[
					"fld_alias1" => $mymod->SelectSubQuery
					(
						table => "tab_alias2",
						fields => [ "fld_alias2" ],
						where => [ "fld_alias2" => "value2" ],
					),
				],
				make_only=>1
			);
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => \$mymod->SelectSubQuery( table => "ta_alias2", fields => [ "fld_alias2" ], where => [ "fld_alias2" => "value2" ] ) } )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 IN (SELECT fld_real2 fld_alias2 FROM tab_real2 tab_alias2 WHERE fld_real2 = 'value2')",
	);
	&my_cmd
	(
		f=> "1601",
		s=> sub
		{
			$mymod->Select
			(
		       		table => "tab_alias1",
				fields => [ "fld_alias1" ],
				where =>
				[
					"fld_alias1" => [ "!", $mymod->SelectSubQuery
					(
						table => "tab_alias2",
						fields => [ "fld_alias2" ],
						where => [ "fld_alias2" => "value2" ],
					)],
				],
				make_only=>1
			);
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => [ "!", \$mymod->SelectSubQuery( table => "taib_alias2", fields => [ "fld_alias2" ], where => [ "fld_alias2" => "value2" ] ) ] } )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 NOT IN (SELECT fld_real2 fld_alias2 FROM tab_real2 tab_alias2 WHERE fld_real2 = 'value2')",
	);
	&my_cmd
	(
		f=> "1602",
		s=> sub
		{
			$mymod->Select
			(
		       		table => "tab_alias1",
				fields => [ "fld_alias1" ],
				where =>
				[
					'fld_alias1' => 1,
					"fld_alias1" => [ "!", $mymod->SelectSubQuery
					(
						table => "tab_alias2",
						fields => [ "fld_alias2" ],
						where => [ "fld_alias2" => "value2" ],
					)],
				],
				make_only=>1
			);
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => [ "!", \$mymod->SelectSubQuery( table => "ta_alias2", fields => [ "fld_alias2" ], where => [ "fld_alias2" => "value2" ] ) ] } )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = '1' AND fld_real1 NOT IN (SELECT fld_real2 fld_alias2 FROM tab_real2 tab_alias2 WHERE fld_real2 = 'value2')",
	);
	&my_cmd
	(
		f=> "1603",
		s=> sub
		{
			$mymod->Select
			(
		       		table => "tab_alias1",
				fields => [ "fld_alias1" ],
				where =>
				[
					'fld_alias1' => 1,
					'or',
					"fld_alias1" => [ "!", $mymod->SelectSubQuery
					(
						table => "tab_alias2",
						fields => [ "fld_alias2" ],
						where => [ "fld_alias2" => "value2" ],
					)],
				],
				make_only=>1
			);
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => [ "!", \$mymod->SelectSubQuery( table => "ta_alias2", fields => [ "fld_alias2" ], where => [ "fld_alias2" => "value2" ] ) ] } )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = '1' OR fld_real1 NOT IN (SELECT fld_real2 fld_alias2 FROM tab_real2 tab_alias2 WHERE fld_real2 = 'value2')",
	);
	&my_cmd
	(
		f=> "1604",
		s=> sub
		{
			$mymod->Select
			(
		       		table => "tab_alias1",
				fields => [ "fld_alias1" ],
				where =>
				[
					"fld_alias1" => $mymod->Select
					(
						table => "tab_alias2",
						fields => [ "fld_alias2" ],
						where => [ "fld_alias2" => "value2" ],
						subquery => 1,
					),
				],
				make_only=>1
			);
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => \$mymod->Select( table => "ta_alias2", fields => [ "fld_alias2" ], where => [ "fld_alias2" => "value2" ], subquery => 1 ) } )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 IN (SELECT fld_real2 fld_alias2 FROM tab_real2 tab_alias2 WHERE fld_real2 = 'value2')",
	);
	&my_cmd
	(
		f=> "1605",
		s=> sub
		{
			$mymod->Select
			(
		       		table => "tab_alias1",
				fields => [ "fld_alias1" ],
				where =>
				[
					"fld_alias1" => [ "!", $mymod->Select
					(
						table => "tab_alias2",
						fields => [ "fld_alias2" ],
						where => [ "fld_alias2" => "value2" ],
						subquery => 1,
					)],
				],
				make_only=>1
			);
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => [ "!", \$mymod->SelectSubQuery( table => "ta_alias2", fields => [ "fld_alias2" ], where => [ "fld_alias2" => "value2" ] ) ] } )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 NOT IN (SELECT fld_real2 fld_alias2 FROM tab_real2 tab_alias2 WHERE fld_real2 = 'value2')",
	);
	&my_cmd
	(
		f=> "1606",
		s=> sub
		{
			$mymod->Select
			(
		       		table => "tab_alias1",
				fields => [ "fld_alias1" ],
				where =>
				[
					"fld_alias1" =>
					[
						$mymod->Select
						(
							table => "tab_alias2",
							fields => [ "fld_alias2" ],
							where => [ "fld_alias2" => "value2" ],
							subquery => 1,
						),
						"..",
						$mymod->Select
						(
							table => "tab_alias2",
							fields => [ "fld_alias2" ],
							where => [ "fld_alias2" => "value3" ],
							subquery => 1,
						),
					],
					"fld_noalias1" => "value1"
				],
				make_only=>1
			);
		},
		n=> "The option 'subquery=1' is mandatory for Select option, the SQL command results is string as return",
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => [ \$mymod->Select( table => "tab_alias2", fields => [ "fld_alias2" ], where => [ "fld_alias2" => "value2" ], subquery => 1 ), "..", \$mymod->Select( table => "tab_alias2", fields => [ "fld_alias2" ], where => [ "fld_alias2" => "value3" ], subquery => 1,), ], "fld_noalias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 BETWEEN ((SELECT fld_real2 fld_alias2 FROM tab_real2 tab_alias2 WHERE fld_real2 = 'value2'),(SELECT fld_real2 fld_alias2 FROM tab_real2 tab_alias2 WHERE fld_real2 = 'value3')) AND fld_noalias1 = 'value1'",
	);
}

################################################################################

sub my_cmd()
{
	my $argv = {@_};
	my $tid = "S".$argv->{f}."-".$myStage;

	## check if specific test by ARGV
	return if (@ARGV && grep(/^$tid$/i,@ARGV)==0);

	## make tests

	diag("################################################################");
	diag("test[".$tid."] ".$argv->{t});

	$mymod->setDumper(1) if ($ENV{DEBUG});
	&{$argv->{s}};
	$mymod->setDumper(0);

	my $buffer = $mymod->getLastSQL();
	my $myrc = $mymod->getRC();

	diag("msg.....: ".$mymod->getMessage()) if ($mymod->getRC());
	diag("note....: ".$argv->{n}) if (defined($argv->{n}));
	diag("warning.: ".$argv->{e}." -- DOT NOT USE") if (defined($argv->{e}));

	## any syntax error?
	if ($myrc)
	{
		if ($argv->{syntax})
		{
			diag("note....: *** no SQL command returns -- invalid arguments ***");
			diag("status..: SUCCESSFUL");
			$ok++;
		}
		else
		{
			diag("note....: *** no SQL command returns -- invalid arguments ***");
			diag("status..: ERROR");
			push(@er,$tid);
		}
	}

	## savefile requested?
	elsif ($argv->{w})
	{
		if ($savedir)
		{
			my $savefile = $mymod->getLastSave();
			diag("returns.: ".$buffer);
			diag("savefile: ".$savefile);
			my $fh = new IO::File($savefile);
			if (defined($fh))
			{
				my $st;
				foreach my $buf(<$fh>) { $st .= $buf; }
				close($fh);
				undef($fh);

				(unlink($savefile)) ? diag("savefile: removed") : diag("savefile: not removed, $!");

				$st =~ s/[\n\r]//g;
				if ($st eq $buffer)
				{
					diag("status..: SUCCESSFUL");
					$ok++;
				}
				else
				{
					diag("savelog.: ".$st);
					diag("status..: ERROR, mismatch");
					push(@er,$tid);
				}
			}
			else
			{
				diag("savefile: ".$savefile);
				diag("status..: ERROR, ".$!);
				push(@er,$tid);
			}
		}
		else
		{
			diag("savefile: undefined");
			diag("status..: SKIPPED");
		}
	}

	## standard test
	elsif ($buffer eq $argv->{r} || (defined($argv->{r2}) && $buffer eq $argv->{r2}))
	{
		if ($show_ok)
		{
			diag("expected: ".$argv->{r});
			diag("	".$argv->{r2}) if (defined($argv->{r2}));
		}
		diag("returns.: ".$buffer);
		diag("status..: SUCCESSFUL");
		$ok++;
	}
	else
	{
		diag("expected: ".$argv->{r});
		diag("expected: ".$argv->{r2}) if (defined($argv->{r2}));
		diag("returns.: ".$buffer);
		diag("status..: ERROR");
		push(@er,$tid);
	}
	&DONE() if ($ENV{EXIT_ON_FIRT_ERROR} && @er);
}

###############################################################################

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
