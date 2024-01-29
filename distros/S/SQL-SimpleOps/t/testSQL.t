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
	use Test::More;

	our $VERSION = "2023.362.1";

	BEGIN{ use_ok('SQL::SimpleOps'); }

###############################################################################
## enable this option to abort on first error

	#$ENV{EXIT_ON_FIRT_ERROR} = 1;

###############################################################################
## global environments

	our $myStage;
	our $savedir = "/tmp" if (($^O =~ /win/i) || stat("/tmp"));
	our $mymod;
	our @er;
	our $ok;
	our $show_ok = (defined($ENV{SQL_SIMPLE_SQL_SHOW_OK}) && $ENV{SQL_SIMPLE_SQL_SHOW_OK} ne "");

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
## STAGE1 - Testes using CONTENTS TABLES (see STAGE2

sub testWithContents()
{
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
		f=> "S0700",
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
		f=> "S0701",
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
		f=> "S0702",
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
		f=> "S0710",
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
		f=> "S0711",
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
		f=> "S0600",
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
		f=> "S0601",
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
		f=> "S0602",
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
		f=> "S0603",
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
		f=> "S0604",
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
		f=> "S0605",
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
		f=> "S0607",
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
		f=> "S0608",
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
		f=> "S0609",
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
		f=> "S0610",
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
		f=> "S0611",
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
		f=> "S0612",
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
		f=> "S0613",
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
		f=> "S0800",
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
		f=> "S0802",
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
		f=> "S0803",
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
		f=> "S0804",
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
		f=> "S0805",
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
		f=> "S0806",
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
		f=> "S0810",
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
		f=> "S0811",
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
		f=> "S0812",
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
		f=> "S0813",
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
		f=> "S0814",
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
		f=> "S0815",
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
		f=> "S0816",
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
		f=> "S0817",
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
		f=> "S0818",
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
		f=> "S0819",
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
		f=> "S0820",
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
		f=> "S0821",
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
		f=> "S0822",
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
		f=> "S0823",
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
		f=> "S0824",
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
		f=> "S0825",
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
		f=> "S0826",
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
		f=> "S0827",
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
		f=> "S0900",
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
		f=> "S0901",
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
		f=> "S0902",
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
		f=> "S0903",
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
		f=> "S0904",
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
		f=> "S0905",
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
		f=> "S0906",
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
		f=> "S0907",
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
		f=> "S0908",
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
		f=> "S0909",
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
		f=> "S0910",
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
		f=> "S0911",
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
		f=> "S0912",
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
		f=> "S0913",
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
		f=> "S0914",
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
		f=> "S0915",
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
		f=> "S0916",
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
		f=> "S0917",
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
		f=> "S0918",
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
		f=> "S0919",
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
		f=> "S0920",
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
		f=> "S0921",
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
		f=> "S0922",
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
		f=> "S0923",
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
		f=> "S0924",
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
		f=> "S0925",
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
		f=> "S0926",
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
		f=> "S0927",
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
		f=> "S0928",
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
		f=> "S0929",
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
		f=> "S0930",
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
		f=> "S0931",
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
		f=> "S0932",
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
		f=> "S0933",
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
		f=> "S0934",
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
		f=> "S0935",
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
		f=> "S1000",
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
		f=> "S1001",
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
		f=> "S1002",
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
		f=> "S1003",
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
		f=> "S1004",
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
		f=> "S1005",
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
		f=> "S1006",
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
		f=> "S1007",
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
		f=> "S1008",
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
		f=> "S1009",
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
		f=> "S1010",
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
		f=> "S1011",
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
		f=> "S1012",
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
		f=> "S1013",
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
		f=> "S1014",
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
		f=> "S1015",
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
		f=> "S1016",
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
		f=> "S1017",
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
		f=> "S1018",
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
		f=> "S1019",
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
		f=> "S1020",
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
		f=> "S1021",
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
		f=> "S1022",
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
		f=> "S1023",
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
		f=> "S1024",
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
		f=> "S1025",
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
		f=> "S1026",
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
		f=> "S1027",
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
		f=> "S1028",
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
		f=> "S1029",
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
		f=> "S1030",
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
		f=> "S1031",
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
		f=> "S1032",
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
		f=> "S1032",
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
		f=> "S1033",
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
## contents tests for WHERE

sub callWhereWith()
{
	&my_cmd
	(
		f=> "S1100",
		s=> sub
		{
			$mymod->Delete( table => "tab_noalias", where => [ "fld_alias1" => 1 ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_noalias", where => [ "fld_alias1" => 1 ], make_only=>1 )',
		r=> "DELETE FROM tab_noalias WHERE fld_alias1 = '1'",
	);
	&my_cmd
	(
		f=> "S1101",
		s=> sub
		{
			$mymod->Delete( table => "tab_alias1", where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_alias1", where => [ "fld_alias1" => "value1" ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1102",
		s=> sub
		{
			$mymod->Delete( table => "tab_real1", where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_real1", where => [ "fld_alias1" => "value1" ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1103",
		s=> sub
		{
			$mymod->Delete( table => "tab_alias1", where => [ "fld_noalias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_alias1", where => [ "fld_noalias1" => 1 ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_noalias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1104",
		s=> sub
		{
			$mymod->Delete( table => "tab_alias1", where => [ "fld_real1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_alias1", where => [ "fld_real1" => 1 ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1105",
		s=> sub
		{
			$mymod->Delete( table => "tab_noalias", where => [ "tab_noalias.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_noalias", where => [ "tab_noalias.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "DELETE FROM tab_noalias WHERE fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1106",
		s=> sub
		{
			$mymod->Delete( table => "tab_alias1", where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_alias1", where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1107",
		s=> sub
		{
			$mymod->Delete( table => "tab_real1", where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_real1", where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1108",
		s=> sub
		{
			$mymod->Delete( table => "tab_real1", where => [ "tab_alias1.fld_alias1" => "xx'xx" ], make_only=>1 )
		},
		t=> 'Delete( table => "tab_real1", where => [ "tab_alias1.fld_alias1" => "xx\'xx" ], make_only=>1 )',
		r=> "DELETE FROM tab_real1 WHERE fld_real1 = 'xx\\'xx'",
	);
	&my_cmd
	(
		f=> "S1200",
		s=> sub
		{
			$mymod->Update( table => "tab_noalias", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_noalias", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ], make_only=>1 )',
		r=> "UPDATE tab_noalias SET fld_alias1 = 'value2' WHERE fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1201",
		s=> sub
		{
			$mymod->Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ] )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1202",
		s=> sub
		{
			$mymod->Update( table => "tab_real1", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_real1", fields => { "fld_alias1" => "value2" }, where => [ "fld_alias1" => "value1" ] )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1203",
		s=> sub
		{
			$mymod->Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_noalias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_noalias1" => "value1" ] )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_noalias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1204",
		s=> sub
		{
			$mymod->Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_real1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "fld_real1" => 1 ], make_only=>1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1205",
		s=> sub
		{
			$mymod->Update( table => "tab_noalias", fields => { "fld_alias1" => "value2" }, where => [ "tab_noalias.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_noalias", fields => { "fld_alias1" => "value2" }, where => [ "tab_noalias.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "UPDATE tab_noalias SET fld_alias1 = 'value2' WHERE fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1206",
		s=> sub
		{
			$mymod->Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_alias1", fields => { "fld_alias1" => "value2" }, where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1207",
		s=> sub
		{
			$mymod->Update( table => "tab_real1", fields => { "fld_alias1" => "value2" }, where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_real1", fields => { "fld_alias1" => "value2" }, where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )',
		r=> "UPDATE tab_real1 SET fld_real1 = 'value2' WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1210",
		s=> sub
		{
			$mymod->Update( table => ["tab_noalias1","tab_noalias2"], fields => { "tab_noalias1.fld_alias1" => "value2", "tab_noalias2.fld_alias2" => "value1" }, where => [ "tab_noalias1.fld_alias1" => "value1", "tab_noalias2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Update( table => ["tab_noalias1","tab_noalias2"], fields => { "tab_noalias1.fld_alias1" => "value2", "tab_noalias2.fld_alias2" => "value1" }, where => [ "tab_noalias1.fld_alias1" => "value1", "tab_noalias2.fld_alias2" => "value2" ] )',
		r=> "UPDATE tab_noalias1, tab_noalias2 SET tab_noalias1.fld_alias1 = 'value2', tab_noalias2.fld_alias2 = 'value1' WHERE tab_noalias1.fld_alias1 = 'value1' AND tab_noalias2.fld_alias2 = 'value2'",
	);
	&my_cmd
	(
		f=> "S1211",
		s=> sub
		{
			$mymod->Update( table => ["tab_alias1","tab_alias2"], fields => { "tab_alias1.fld_alias1" => "value2", "tab_alias2.fld_alias2" => "value1" }, where => [ "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Update( table => ["tab_alias1","tab_alias2"], fields => { "tab_alias1.fld_alias1" => "value2", "tab_alias2.fld_alias2" => "value1" }, where => [ "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" ] )',
		r=> "UPDATE tab_real1 tab_alias1, tab_real2 tab_alias2 SET tab_alias1.fld_real1 = 'value2', tab_alias2.fld_real2 = 'value1' WHERE tab_alias1.fld_real1 = 'value1' AND tab_alias2.fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "S1212",
		s=> sub
		{
			$mymod->Update( table => ["tab_real1","tab_real2"], fields => { "tab_real1.fld_alias1" => "value2", "tab_real2.fld_alias2" => "value1" }, where => [ "tab_real1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Update( table => ["tab_real1","tab_real2"], fields => { "tab_real1.fld_alias1" => "value2", "tab_real2.fld_alias2" => "value1" }, where => [ "tab_real1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" ] )',
		r=> "UPDATE tab_real1 tab_alias1, tab_real2 tab_alias2 SET tab_alias1.fld_real1 = 'value2', tab_alias2.fld_real2 = 'value1' WHERE tab_alias1.fld_real1 = 'value1' AND tab_alias2.fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "S1213",
		s=> sub
		{
			$mymod->Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => undef }, where => [ "tab_real1.fld_alias1" => undef ], make_only=>1 )
		},
		t=> 'Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => undef }, where => [ "tab_real1.fld_alias1" => undef ]',
		r=> "UPDATE tab_real1 SET fld_real1 = NULL WHERE fld_real1 IS NULL",
	);
	&my_cmd
	(
		f=> "S1214",
		s=> sub
		{
			$mymod->Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => undef }, where => [ "tab_real1.fld_alias1" => [ "!", undef ] ], make_only=>1 )
		},
		t=> 'Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => undef }, where => [ "tab_real1.fld_alias1" => [ "!", undef ] ]',
		r=> "UPDATE tab_real1 SET fld_real1 = NULL WHERE fld_real1 NOT NULL",
	);
	&my_cmd
	(
		f=> "S1215",
		s=> sub
		{
			$mymod->Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => "xx'xx" }, where => [ "tab_real1.fld_alias1" => "yy'yy" ], make_only=>1 )
		},
		t=> 'Update( table => "tab_real1", fields => { "tab_real1.fld_alias1" => \'xx\\\'xx\' }, where => [ "tab_real1.fld_alias1" => \'yy\\\'yy\' ]',
		r=> "UPDATE tab_real1 SET fld_real1 = 'xx\\'xx' WHERE fld_real1 = 'yy\\'yy'",
	);
	&my_cmd
	(
		f=> "S1300",
		s=> sub
		{
			$mymod->Select( table => "tab_noalias", where => [ "fld_alias1" => 1 ], make_only=>1 )
		},
		t=> 'Select( table => "tab_noalias", where => [ "fld_alias1" => 1 ], make_only=>1 )',
		r=> "SELECT * FROM tab_noalias WHERE fld_alias1 = '1'",
	);
	&my_cmd
	(
		f=> "S1301",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1302",
		s=> sub
		{
			$mymod->Select( table => "tab_real1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_real1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1303",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_noalias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_noalias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_noalias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1304",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_real1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_real1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1305",
		s=> sub
		{
			$mymod->Select( table => "tab_noalias", fields => [ "fld_alias1" ], where => [ "tab_noalias.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_noalias", fields => [ "fld_alias1" ], where => [ "tab_noalias.fld_alias1" => "value1" ] )',
		r=> "SELECT fld_alias1 FROM tab_noalias WHERE fld_alias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1306",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "tab_alias1.fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1307",
		s=> sub
		{
			$mymod->Select( table => "tab_real1", fields => [ "fld_alias1" ], where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_real1", fields => [ "fld_alias1" ], where => [ "tab_alias1.fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1310",
		s=> sub
		{
			$mymod->Select( table => ["tab_noalias1","tab_noalias2"], fields => [ "tab_noalias1.fld_alias1", "tab_noalias2.fld_alias2" ], where => [ "tab_noalias1.fld_alias1" => "value1", "tab_noalias2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_noalias1","tab_noalias2"], fields => [ "tab_noalias1.fld_alias1", "tab_noalias2.fld_alias2" ], where => [ "tab_noalias1.fld_alias1" => "value1", "tab_noalias2.fld_alias2" => "value2" ] )',
		r=> "SELECT tab_noalias1.fld_alias1, tab_noalias2.fld_alias2 FROM tab_noalias1, tab_noalias2 WHERE tab_noalias1.fld_alias1 = 'value1' AND tab_noalias2.fld_alias2 = 'value2'",
	);
	&my_cmd
	(
		f=> "S1311",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_alias1.fld_alias1" => "value1", "tab_alias2.fld_alias2" => "value2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = 'value1' AND tab_alias2.fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "S1312",
		s=> sub
		{
			$mymod->Select( table => ["tab_real1","tab_real2"], fields => [ "tab_real1.fld_alias1", "tab_real2.fld_alias2" ], where => [ "tab_real1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_real1","tab_real2"], fields => [ "tab_real1.fld_alias1", "tab_real2.fld_alias2" ], where => [ "tab_real1.fld_alias1" => "value1", "tab_real2.fld_alias2" => "value2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = 'value1' AND tab_alias2.fld_real2 = 'value2'",
	);
	&my_cmd
	(
		f=> "S1313",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_alias1.fld_alias1" => "\\tab_alias2.fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias1"], fields => [ "tab_real1.fld_alias1", "tab_real2.fld_alias2" ], where => [ "tab_alias1.fld_alias1" => "\\tab_alias2.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1314",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_alias1.fld_real1" => "\\tab_alias2.fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias1"], fields => [ "tab_real1.fld_alias1", "tab_real2.fld_alias2" ], where => [ "tab_alias1.fld_alias1" => "\\tab_alias2.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1315",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_real1.fld_alias1" => "\\tab_real2.fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias1"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_real1.fld_alias1" => "tab_real1.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1316",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_real1.fld_real1" => "\\tab_real2.fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias1"], fields => [ "tab_alias1.fld_alias1", "tab_alias2.fld_alias2" ], where => [ "tab_real1.fld_real1" => "\\tab_real1.fld_real2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1320",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1321",
		s=> sub
		{
			$mymod->Select( table => "tab_real1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_real1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1321",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_noalias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "fld_noalias1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_noalias1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1322",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1323",
		s=> sub
		{
			$mymod->Select( table => "tab_real1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_alias1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_real1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_alias1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1324",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_real1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_alias1.fld_real1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1325",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_real1.fld_real1" => "value1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ {"fld_alias1"=>"my1"} ], where => [ "tab_real1.fld_real1" => "value1" ] )',
		r=> "SELECT fld_real1 my1 FROM tab_real1 tab_alias1 WHERE fld_real1 = 'value1'",
	);
	&my_cmd
	(
		f=> "S1326",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.fld_alias1" => "\\tab_alias2.fld_alias2" ], make_only=>1 ),
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.fld_alias1" => "tab_alias2.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1327",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.fld_real1" => "\\tab_alias2.fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.fld_real1" => "tab_alias2.fld_real2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1328",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.fld_alias1" => "\\tab_real2.fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.fld_alias1" => "tab_real2.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1329",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.fld_real1" => "\\tab_real2.fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.fld_real1" => "tab_real2.fld_real2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1330",
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
		f=> "S1331",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.my1" => "\\tab_alias2.my2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_alias1.my1" => "\\tab_alias2.my2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1332",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.my1" => "\\tab_real2.my2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_real1.my1" => "\\tab_real2.my2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_alias1.fld_real1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1333",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_noalias1.my1" => "\\tab_alias2.my2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ {"tab_alias1.fld_alias1"=>"my1"}, {"tab_alias2.fld_alias2"=>"my2"} ], where => [ "tab_noalias1.my1" => "\\tab_alias2.my2" ] )',
		r=> "SELECT tab_alias1.fld_real1 my1, tab_alias2.fld_real2 my2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 WHERE tab_noalias1.my1 = tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1334",
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
		f=> "S0110",
		s=> sub { $mymod->Delete( table=>"t1", where => [ fld => 123 ], make_only=>1 ) },
		t=> 'Delete( table=>"t1", where => [ fld => 123 ] )',
		r=> "DELETE FROM t1 WHERE fld = '123'",
	);
	&my_cmd
	(
		f=> "S0120",
		s=> sub { $mymod->Insert( table=>"t1", fields => { a => 1, b => 2, c => 3 }, make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => { a => 1, b => 2, c => 3 } )',
		r=> "INSERT INTO t1 (a,b,c) VALUES ('1','2','3')",
	);
	&my_cmd
	(
		f=> "S0121",
		s=> sub { $mymod->Insert( table=>"t1", fields => { a => undef, b => undef, c => undef }, make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => { a => undef, b => undef, c => undef } )',
		r=> "INSERT INTO t1 (a,b,c) VALUES (NULL,NULL,NULL)",
	);
	&my_cmd
	(
		f=> "S0122",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a","b","c" ], values => [ 1,2,3 ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a","b","c" ], values => [ 1,2,3 ] )',
		r=> "INSERT INTO t1 (a,b,c) VALUES ('1','2','3')",
	);
	&my_cmd
	(
		f=> "S0123",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a","b","c" ], values => [ undef,undef,undef ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a","b","c" ], values => [ undef,undef,undef ] )',
		r=> "INSERT INTO t1 (a,b,c) VALUES (NULL,NULL,NULL)",
	);
	&my_cmd
	(
		f=> "S0124",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a" ], values => [ 1,2,3 ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a","b","c" ], values => [ 1,2,3 ] )',
		r=> "INSERT INTO t1 (a) VALUES ('1'),('2'),('3')",
	);
	&my_cmd
	(
		f=> "S0125",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a" ], values => [ undef,undef,undef ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a","b","c" ], values => [ undef,undef,undef ] )',
		r=> "INSERT INTO t1 (a) VALUES (NULL),(NULL),(NULL)",
	);
	&my_cmd
	(
		f=> "S0126",
		s=> sub { $mymod->Insert( table=>"t1", fields => { a => "xx'xx" }, make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => { a => "xx\'xx" )',
		r=> "INSERT INTO t1 (a) VALUES ('xx\\\'xx')",
	);
	&my_cmd
	(
		f=> "S0127",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a" ], values => [ "xx'xx" ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a" ], values => [ "xx\'xx" ] )',
		r=> "INSERT INTO t1 (a) VALUES ('xx\\\'xx')",
	);
	&my_cmd
	(
		f=> "S0128",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a" ], values => [ "xx'xx","yy'yy" ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a" ], values => [ "xx\'xx","yy\'yy" ] )',
		r=> "INSERT INTO t1 (a) VALUES ('xx\\\'xx'),('yy\\\'yy')",
	);
	&my_cmd
	(
		f=> "S0130",
		s=> sub { $mymod->Update( table=>"t1", fields => { a => 1, b => 2 }, where => [ c => [ "!", 3 ] ], make_only=>1 ) },
		t=> 'Update( table=>"t1", fields => { a => 1, b => 2 }, where => [ c => [ "!", 3 ] ] )',
		r=> "UPDATE t1 SET b = '2', a = '1' WHERE c != '3'",
		r2=>"UPDATE t1 SET a = '1', b = '2' WHERE c != '3'",
	);
	&my_cmd
	(
		f=> "S0140",
		s=> sub { $mymod->Update( table=>"t1", fields => { a => '\\concat(a,"xxxx")' }, force => 1, make_only=>1 ) },
		t=> 'Update( table=>"t1", fields => { a => \'\\concat(a,"xxxx")\' }, force => 1 )',
		r=> "UPDATE t1 SET a = concat(a,\"xxxx\")",
	);
	&my_cmd
	(
		f=> "S0150",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"] )',
		r=> "SELECT a, b, c FROM t1",
	);
	&my_cmd
	(
		f=> "S0160",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4 ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4 ] )',
		r=> "SELECT a, b, c FROM t1 WHERE d = '4'",
	);
	&my_cmd
	(
		f=> "S0170",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4, e=>5 ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4, e=>5 ] )',
		r=> "SELECT a, b, c FROM t1 WHERE d = '4' AND e = '5'",
	);
	&my_cmd
	(
		f=> "S0180",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>'\substr(e,1,8)' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>\'\\substr(e,1,8)\' ] )',
		r=> "SELECT a, b, c FROM t1 WHERE d = substr(e,1,8)",
	);
	&my_cmd
	(
		f=> "S0190",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ 't1.a' => '\t2.b' ], make_only=>1) },
		t=> 'Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ "t1.a" => "\\t2.b" ] )',
		r=> "SELECT t1.a, t2.b FROM t1, t2 WHERE t1.a = t2.b",
	);
	&my_cmd
	(
		f=> "S0200",
		s=> sub { $mymod->Select( table=>"t1", fields => [ {"a"=>"aa"} ], where => [ 'a' => '0' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ {"a"=>"aa"} ], where => [ \'a\' => \'0\' ] )',
		r=> "SELECT a aa FROM t1 WHERE a = '0'",
	);
	&my_cmd
	(
		f=> "S0210",
		s=> sub { $mymod->Select( table=>"t1", fields => [ {"t1.a"=>"aa"} ], where => [ 't1.a' => '0' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ {"t1.a"=>"aa"} ], where => [ \'t1.a\' => \'0\' ] )',
		r=> "SELECT t1.a aa FROM t1 WHERE a = '0'",
	);
	&my_cmd
	(
		f=> "S0220",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [ {"t1.a"=>"aa"} , {"t2.b"=>"bb"} ], where => [ 't1.a' => '\\t2.b' ], make_only=>1) },
		t=> 'Select( table=>["t1","t2"], fields => [ {"t1.a"=>"aa"}, {"t2.b"=>"bb"} ], where => [ "t1.a" => "\\t2.b" ] )',
		r=> "SELECT t1.a aa, t2.b bb FROM t1, t2 WHERE t1.a = t2.b",
	);
	&my_cmd
	(
		f=> "S0230",
		s=> sub { $mymod->Select( table=>"t1", fields => [ {"sum(a)"=>"a1"}, {"sum(t1.a)"=>"a2"}, {"\\sum(a)"=>"a3"} ], where => [ 'a' => '0' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ {"sum(a)"=>"a1"}, {"sum(t1.a)"=>"a2"}, {"\\sum(a)"=>"a3"} ], where => [ \'a\' => \'0\' ] )',
		r=> "SELECT sum(a) a1, sum(t1.a) a2, sum(a) a3 FROM t1 WHERE a = '0'",
	);
	&my_cmd
	(
		f=> "S0320",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "distinct","a" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "distinct", "a" ] )', 
		r=> "SELECT DISTINCT a FROM t1",
		n=> 'Select with DISTINCT array sequence',
	);
	&my_cmd
	(
		f=> "S0330",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "distinct" => "a" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "distinct" => "a" ] )', 
		r=> "SELECT DISTINCT a FROM t1",
		n=> 'Select with DISTINCT based hash',
	);
	&my_cmd
	(
		f=> "S0340",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "count(*)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "count(*)" ] )', 
		r=> "SELECT count(*) FROM t1",
	);
	&my_cmd
	(
		f=> "S0350",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "max(t1.a)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "max(t1.a)" ] )', 
		r=> "SELECT max(t1.a) FROM t1",
	);
	&my_cmd
	(
		f=> "S0360",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "max(a)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "max(a)" ] )', 
		r=> "SELECT max(a) FROM t1",
	);
	&my_cmd
	(
		f=> "S0370",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "substr(a,1,8)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "substr(a,1,8)" ] )', 
		r=> "SELECT substr(a,1,8) FROM t1",
	);
	&my_cmd
	(
		f=> "S0380",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "\\aaa.bbb.ccc" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "\\aaa.bbb.ccc" ] )', 
		r=> "SELECT aaa.bbb.ccc FROM t1",
	);
	&my_cmd
	(
		f=> "S0390",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "distinct","\\aaa.bbb.ccc" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "distinct","\\aaa.bbb.ccc" ] )', 
		r=> "SELECT DISTINCT aaa.bbb.ccc FROM t1",
	);
	&my_cmd
	(
		f=> "S0400",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ 't1.a' => 't2.b' ], make_only=>1, sql_save=>1 ) },
		t=> 'Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ \'t1.a\' => \'t2.b\' ], sql_save=>1 )',
		r=> "SELECT t1.a, t2.b FROM t1, t2 WHERE t1.a = t2.b",
		n=> "SQL_SAVE enabled",
		w=> 1,
	);
	&my_cmd
	(
		f=> "S0410",
		s=> sub { $mymod->Select( table=>"t1", order_by => "t1.a",  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => "t1.a" )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a",
	);
	&my_cmd
	(
		f=> "S0420",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ {"t1.a" => "asc"} ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ {"t1.a" => "asc"} ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a ASC",
	);
	&my_cmd
	(
		f=> "S0430",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ {"t1.a" => "desc"} ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ {"t1.a" => "desc"} ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a DESC",
	);
	&my_cmd
	(
		f=> "S0440",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ "t1.a", "t1.b" ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ "t1.a", "t1.b" ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a, t1.b",
	);
	&my_cmd
	(
		f=> "S0450",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ {"t1.a" => "asc"}, "t1.b" ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ {"t1.a" => "asc"}, "t1.b" ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a ASC, t1.b",
	);
	&my_cmd
	(
		f=> "S0460",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ "t1.a",{"t1.b"=>"desc"} ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ "t1.a", {"t1.b"=>"desc"} ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a, t1.b DESC",
	);
	&my_cmd
	(
		f=> "S0470",
		s=> sub { $mymod->Select( table=>"t1", order_by => {"t1.b"=>"desc"},  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => {"t1.b"=>"desc"} )', 
		r=> "SELECT * FROM t1 ORDER BY t1.b DESC",
	);
	&my_cmd
	(
		f=> "S0480",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t1.fgh"=>"_fgh"}], where => [ "_abc" => 123 ],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t1.fgh"=>"_fgh"}], where => [ "_abc" => 123 ] )', 
		r=> "SELECT t1.abc _abc, t1.cde, t1.fgh _fgh FROM t1 WHERE abc = '123'",
	);
	&my_cmd
	(
		f=> "S0481",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t1.fgh"=>"_fgh"}], where => [ "_abc" => 123, "cde" => 234, "t1.abc" => 345],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t1.fgh"=>"_fgh"}], where => [ "_abc" => 123, "cde" => 234, "t1.abc" => 345] )', 
		r=> "SELECT t1.abc _abc, t1.cde, t1.fgh _fgh FROM t1 WHERE abc = '123' AND cde = '234' AND abc = '345'",
	);
	&my_cmd
	(
		f=> "S0490",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t2.fgh"=>"_fgh"},"t2.ijk"], where => [ "_abc" => 123, "cde" => 234, "t1.abc" => 345, "ijk" => 456],  make_only=>1) },
		t=> 'Select( table=>["t1","t2"], fields => [{"t1.abc"=>"_abc"},"t1.cde",{"t2.fgh"=>"_fgh"},"t2.ijk"], where => [ "_abc" => 123, "cde" => 234, "t1.abc" => 345, "ijk" => 456] )',
		r=> "SELECT t1.abc _abc, t1.cde, t2.fgh _fgh, t2.ijk FROM t1, t2 WHERE t1.abc = '123' AND cde = '234' AND t1.abc = '345' AND ijk = '456'",
	);
	&my_cmd
	(
		f=> "S0500",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "substr(_a,1,4)" => 1234 ],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "substr(_a,1,4)" => 1234 ] )',
		r=> "SELECT t1.abc _a FROM t1 WHERE substr(abc,1,4) = '1234'",
	);
	&my_cmd
	(
		f=> "S0510",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "concat(substr(_a,1,4),1)" => 1231 ],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "concat(substr(_a,1,3),1)" => 1231 ] )',
		r=> "SELECT t1.abc _a FROM t1 WHERE concat(substr(abc,1,4),1) = '1231'",
	);
	&my_cmd
	(
		f=> "S0520",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "func1(func2(_a))" => 1231 ],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "func1(func2(_a))" => 1231 ] )',
		r=> "SELECT t1.abc _a FROM t1 WHERE func1(func2(abc)) = '1231'",
	);
	&my_cmd
	(
		f=> "S0530",
		s=> sub { $mymod->Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "func1(_a)" => 123, "func1(t1.abc)" => 456 ],  make_only=>1) },
		t=> 'Select( table=>"t1", fields => [{"t1.abc"=>"_a"}], where => [ "func1(_a)" => 123, "func1(t1.abc)" => 456 ] )',
		r=> "SELECT t1.abc _a FROM t1 WHERE func1(abc) = '123' AND func1(t1.abc) = '456'",
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
		f=> "S0270",
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
		f=> "S0280",
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
		f=> "S0290",
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
		f=> "S0300",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_LAST, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_LAST, limit=>100 )', 
		n=> 'Command=LAST, Cursor is first(1) and last(100)',
		r=> "SELECT a, b, c FROM t1 ORDER BY a DESC LIMIT 100",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "S0310",
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
		f=> "S0311",
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
		f=> "S0312",
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
		f=> "S0313",
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
		f=> "S0314",
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
		f=> "S0315",
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
		f=> "S0316",
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
		f=> "S0317",
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
		f=> "S0318",
		s=> sub { $mymod->SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], where => ["t1.a" => "\\t2.a"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], cursor_command=>SQL_SIMPLE_CURSOR_RELOAD, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>["t1","t2"], fields => [ "t1.a","t1.b","t2.c"], where => ["t1.a" => "\\t2.a"], cursor_info => \%cursor, cursor_key=>["t1.a","t2.c"], cursor_command=>SQL_SIMPLE_CURSOR_RELOAD, limit=>100 )',
		n=> '',
		r=> "SELECT t1.a, t1.b, t2.c FROM t1, t2 WHERE t1.a = t2.a AND (t1.a >= 'a' OR (t1.a = 'a' AND t2.c >= '1')) ORDER BY t1.a ASC, t2.c ASC LIMIT 100",
		c=> \%cursor,
	);
	%cursor = {};
	&my_cmd
	(
		f=> "S0330",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_TOP, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_TOP, limit=>100 )', 
		r=> "SELECT a, b, c FROM t1 ORDER BY a ASC LIMIT 100",
		n=> 'Command=TOP, Cursor is empty',
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "S0331",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", limit=>100 )', 
		r=> "SELECT a, b, c FROM t1 ORDER BY a ASC LIMIT 100",
		n=> 'Command=TOP, Cursor is empty',
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "S0332",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_NEXT, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_NEXT, limit=>100 )', 
		n=> 'Command=NEXT, Cursor is empty',
		r=> "SELECT a, b, c FROM t1 ORDER BY a ASC LIMIT 100",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "S0333",
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
		f=> "S1400",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_alias1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_alias1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_real1",
	);
	&my_cmd
	(
		f=> "S1401",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_real1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_real1" ], group_by => [ "fld_real1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_real1",
	);
	&my_cmd
	(
		f=> "S1402",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_noalias" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_real1" ], group_by => [ "fld_noalias" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_noalias",
	);
	&my_cmd
	(
		f=> "S1403",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_alias1","fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_alias1","fld_alias2" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_real1, fld_real2",
	);
	&my_cmd
	(
		f=> "S1404",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_real1","fld_real2" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_real1" ], group_by => [ "fld_real1","fld_real2" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_real1, fld_real2",
	);
	&my_cmd
	(
		f=> "S1405",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "fld_noalias1","fld_noalias2" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_real1" ], group_by => [ "fld_noalias1","fld_noalias2" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY fld_noalias1, fld_noalias2",
	);
	&my_cmd
	(
		f=> "S1406",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_alias1.fld_alias1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_alias1.fld_alias1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY tab_alias1.fld_real1",
	);
	&my_cmd
	(
		f=> "S1407",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_alias1.fld_real1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_alias1.fld_real1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY tab_alias1.fld_real1",
	);
	&my_cmd
	(
		f=> "S1408",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_alias1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_alias1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY tab_alias1.fld_real1",
	);
	&my_cmd
	(
		f=> "S1409",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_real1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_real1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY tab_alias1.fld_real1",
	);
	&my_cmd
	(
		f=> "S1410",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_noalias1" ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], group_by => [ "tab_real1.fld_noalias1" ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 GROUP BY tab_alias1.fld_noalias1",
	);
	&my_cmd
	(
		f=> "S1411",
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
		f=> "S1412",
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
		f=> "S1413",
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
		f=> "S1414",
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
		f=> "S1500",
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
		f=> "S1501",
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
		f=> "S1502",
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
		f=> "S1503",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_real1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_real1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY fld_real1 ASC",
	);
	&my_cmd
	(
		f=> "S1504",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_noalias1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_noalias1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY fld_noalias1 ASC",
	);
	&my_cmd
	(
		f=> "S1505",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_alias1"=>"desc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"fld_alias1"=>"desc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY fld_real1 DESC",
	);
	&my_cmd
	(
		f=> "S1506",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_alias1.fld_alias1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_alias1.fld_real1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_alias1.fld_real1 ASC",
	);
	&my_cmd
	(
		f=> "S1507",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_real1.fld_real1"=>"desc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_real1.fld_real1"=>"desc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_alias1.fld_real1 DESC",
	);
	&my_cmd
	(
		f=> "S1508",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_alias1.fld_real1"=>"desc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_alias1.fld_real1"=>"desc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_alias1.fld_real1 DESC",
	);
	&my_cmd
	(
		f=> "S1509",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_real1.fld_alias1"=>"desc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_real1.fld_alias1"=>"desc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_alias1.fld_real1 DESC",
	);
	&my_cmd
	(
		f=> "S1510",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_noalias1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_noalias1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_noalias.fld_noalias1 ASC",
	);
	&my_cmd
	(
		f=> "S1511",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_alias1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_alias1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_noalias.fld_alias1 ASC",
	);
	&my_cmd
	(
		f=> "S1512",
		s=> sub
		{
			$mymod->Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_real1"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], order_by => [ {"tab_noalias.fld_real1"=>"asc"} ] )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 ORDER BY tab_noalias.fld_real1 ASC",
	);
	&my_cmd
	(
		f=> "S1513",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ {"tab_alias1.fld_alias1"=>"asc"},{"tab_alias2.fld_alias2"=>"asc"} ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ {"tab_alias1.fld_alias1"=>"asc"},{"tab_alias2.fld_alias2"=>"asc"} ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 ORDER BY tab_alias1.fld_real1 ASC, tab_alias2.fld_real2 ASC",
	);
	&my_cmd
	(
		f=> "S1514",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ {"tab_real1.fld_alias1"=>"asc"},{"tab_real2.fld_alias2"=>"asc"} ],make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ {"tab_real1.fld_alias1"=>"asc"},{"tab_real2.fld_alias2"=>"asc"} ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 ORDER BY tab_alias1.fld_real1 ASC, tab_alias2.fld_real2 ASC",
	);
	&my_cmd
	(
		f=> "S1515",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ "tab_real1.fld_alias1","tab_real2.fld_alias2" ], make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => [ "tab_real1.fld_alias1","tab_real2.fld_alias2" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 ORDER BY tab_alias1.fld_real1, tab_alias2.fld_real2",
	);
	&my_cmd
	(
		f=> "S1516",
		s=> sub
		{
			$mymod->Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => "tab_real1.fld_alias1", make_only=>1 )
		},
		t=> 'Select( table => ["tab_alias1","tab_alias2"], fields => [ "tab_alias1.fld_alias1","tab_alias2.fld_alias2" ], order_by => "tab_real1.fld_alias1" ] )',
		r=> "SELECT tab_alias1.fld_real1 fld_alias1, tab_alias2.fld_real2 fld_alias2 FROM tab_real1 tab_alias1, tab_real2 tab_alias2 ORDER BY tab_alias1.fld_real1",
	);
	&my_cmd
	(
		f=> "S1517",
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
		f=> "S1600",
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
		f=> "S1601",
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
		t=> 'Select( table => "tab_alias1", fields => [ "fld_alias1" ], where => [ "fld_alias1" => [ "!", \$mymod->SelectSubQuery( table => "ta_alias2", fields => [ "fld_alias2" ], where => [ "fld_alias2" => "value2" ] ) ] } )',
		r=> "SELECT fld_real1 fld_alias1 FROM tab_real1 tab_alias1 WHERE fld_real1 NOT IN (SELECT fld_real2 fld_alias2 FROM tab_real2 tab_alias2 WHERE fld_real2 = 'value2')",
	);
	&my_cmd
	(
		f=> "S1603",
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
		f=> "S1604",
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
		f=> "S1605",
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

	my $tid = $argv->{f}."-".$myStage;

	diag("################################################################");
	diag("test-".$tid.": ".$argv->{t});

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
				diag("status: SUCCESSFUL");
				$ok++;
			}
			else
			{
				diag("savelog: ".$st);
				diag("status: ERROR, mismatch");
				push(@er,$tid);
			}
		}
		else
		{
			diag("status.: ERROR, ".$!);
			push(@er,$tid);
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
