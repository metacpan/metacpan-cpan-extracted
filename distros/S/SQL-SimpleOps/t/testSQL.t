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
	use Data::Dumper;

	$Data::Dumper::Varname = '';
	$Data::Dumper::Terse = 1;
	$Data::Dumper::Pad = "";

	our $VERSION = "2023.274.1";

	BEGIN{ use_ok('SQL::SimpleOps'); }

	## create dbh entry point (is required)

	my $savedir = "/tmp" if (($^O =~ /win/i) || stat("/tmp"));
	our $mymod = new SQL::SimpleOps
	(
		db => "teste",			# you can use any database name
		driver => "sqlite",		# you can use any database engine
		dbfile => ":memory:",		# use ram memory
		connect => 0,			# do not open database
		sql_save_dir => $savedir,	# savedir test
		sql_save_bydate => 1,		# split logfile by date folders
	);

	diag("");

	## sql command tests

	my $show_ok = (defined($ENV{SQL_SIMPLE_SQL_SHOW_OK}) && $ENV{SQL_SIMPLE_SQL_SHOW_OK} ne "");
	my @er;
	my $ok;

	&my_cmd
	(
		f=> "010",
		s=> sub { $mymod->Delete( table=>"t1", force=>1, make_only=>1 ) },
		t=> 'Delete( table=>"t1", force=>1 )',
		r=> "DELETE FROM t1",
	);
	&my_cmd
	(
		f=> "011",
		s=> sub { $mymod->Delete( table=>"t1", where => [ fld => 123 ], make_only=>1 ) },
		t=> 'Delete( table=>"t1", where => [ fld => 123 ] )',
		r=> "DELETE FROM t1 WHERE fld = '123'",
	);
	&my_cmd
	(
		f=> "020",
		s=> sub { $mymod->Insert( table=>"t1", fields => { a => 1, b => 2, c => 3 }, make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => { a => 1, b => 2, c => 3 } )',
		r=> "INSERT INTO t1 (a,b,c) VALUES ('1','2','3')",
	);
	&my_cmd
	(
		f=> "021",
		s=> sub { $mymod->Insert( table=>"t1", fields => [ "a","b","c" ], values => [ 1,2,3 ], make_only=>1 ) },
		t=> 'Insert( table=>"t1", fields => [ "a","b","c" ], values => [ 1,2,3 ] )',
		r=> "INSERT INTO t1 (a,b,c) VALUES ('1','2','3')",
	);
	&my_cmd
	(
		f=> "030",
		s=> sub { $mymod->Update( table=>"t1", fields => { a => 1, b => 2 }, where => [ c => [ "!", 3 ] ], make_only=>1 ) },
		t=> 'Update( table=>"t1", fields => { a => 1, b => 2 }, where => [ c => [ "!", 3 ] ] )',
		r=> "UPDATE t1 SET b = '2', a = '1' WHERE c != '3'",
		r2=>"UPDATE t1 SET a = '1', b = '2' WHERE c != '3'",
	);
	&my_cmd
	(
		f=> "031",
		s=> sub { $mymod->Update( table=>"t1", fields => { a => '\\concat(a,"xxxx")' }, force => 1, make_only=>1 ) },
		t=> 'Update( table=>"t1", fields => { a => \'\\concat(a,"xxxx")\' }, force => 1 )',
		r=> "UPDATE t1 SET a = concat(a,\"xxxx\")",
	);
	&my_cmd
	(
		f=> "040",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"] )',
		r=> "SELECT a, b, c FROM t1",
	);
	&my_cmd
	(
		f=> "041",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4 ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4 ] )',
		r=> "SELECT a, b, c FROM t1 WHERE d = '4'",
	);
	&my_cmd
	(
		f=> "043",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4, e=>5 ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>4, e=>5 ] )',
		r=> "SELECT a, b, c FROM t1 WHERE d = '4' AND e = '5'",
	);
	&my_cmd
	(
		f=> "044",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>'\substr(e,1,8)' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "a","b","c"], where => [ d=>\'\\substr(e,1,8)\' ] )',
		r=> "SELECT a, b, c FROM t1 WHERE d = substr(e,1,8)",
	);
	&my_cmd
	(
		f=> "045",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ 't1.a' => 't2.b' ], make_only=>1) },
		t=> 'Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ \'t1.a\' => \'t2.b\' ] )',
		r=> "SELECT t1.a, t2.b FROM t1, t2 WHERE t1.a = t2.b",
	);
	&my_cmd
	(
		f=> "046",
		s=> sub { $mymod->Select( table=>"t1", fields => [ {"a"=>"aa"} ], where => [ 'a' => '0' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ {"a"=>"aa"} ], where => [ \'a\' => \'0\' ] )',
		r=> "SELECT a aa FROM t1 WHERE a = '0'",
	);
	&my_cmd
	(
		f=> "047",
		s=> sub { $mymod->Select( table=>"t1", fields => [ {"t1.a"=>"aa"} ], where => [ 't1.a' => '0' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ {"t1.a"=>"aa"} ], where => [ \'t1.a\' => \'0\' ] )',
		r=> "SELECT t1.a aa FROM t1 WHERE t1.a = '0'",
	);
	&my_cmd
	(
		f=> "048",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [ {"t1.a"=>"aa"} , {"t2.b"=>"bb"} ], where => [ 't1.a' => 't2.b' ], make_only=>1) },
		t=> 'Select( table=>["t1","t2"], fields => [ {"t1.a"=>"aa"}, {"t2.b"=>"bb"} ], where => [ \'t1.a\' => \'t2.b\' ] )',
		r=> "SELECT t1.a aa, t2.b bb FROM t1, t2 WHERE t1.a = t2.b",
	);
	&my_cmd
	(
		f=> "049",
		s=> sub { $mymod->Select( table=>"t1", fields => [ {"sum(a)"=>"a1"}, {"sum(t1.a)"=>"a2"}, {"\\sum(a)"=>"a3"} ], where => [ 'a' => '0' ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ {"sum(a)"=>"a1"}, {"sum(t1.a)"=>"a2"}, {"\\sum(a)"=>"a3"} ], where => [ \'a\' => \'0\' ] )',
		r=> "SELECT sum(a) a1, sum(t1.a) a2, sum(a) a3 FROM t1 WHERE a = '0'",
	);
	my %cursor;

	&my_cmd
	(
		f=> "050",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_TOP, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_TOP, limit=>100 )', 
		r=> "SELECT a, b, c FROM t1 ORDER BY a ASC LIMIT 100",
		n=> 'Command=TOP, Cursor is empty',
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "051",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_NEXT, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_NEXT, limit=>100 )', 
		n=> 'Command=NEXT, Cursor is empty',
		r=> "SELECT a, b, c FROM t1 ORDER BY a ASC LIMIT 100",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "052",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_BACK, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_BACK, limit=>100 )', 
		n=> 'Command=BACK, Cursor is empty',
		r=> "SELECT a, b, c FROM t1 ORDER BY a DESC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = 1;
	$cursor{last} = 100;
	&my_cmd
	(
		f=> "053",
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
		f=> "054",
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
		f=> "055",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_RELOAD, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_RELOAD, limit=>100 )', 
		n=> 'Command=RELOAD, Cursor is first(1) and last(100)',
		r=> "SELECT a, b, c FROM t1 WHERE a > '1' ORDER BY a ASC LIMIT 100",
		c=> \%cursor,
	);
	$cursor{first} = 1;
	$cursor{last} = 100;
	&my_cmd
	(
		f=> "056",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_LAST, limit=>100, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_LAST, limit=>100 )', 
		n=> 'Command=LAST, Cursor is first(1) and last(100)',
		r=> "SELECT a, b, c FROM t1 ORDER BY a DESC LIMIT 100",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "057",
		s=> sub { $mymod->SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \%cursor, cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_TOP, limit=>0, make_only=>1) },
		t=> 'SelectCursor( table=>"t1", fields => [ "a","b","c"], cursor_info => \\%cursor , cursor_key=>"a", cursor_command=>SQL_SIMPLE_CURSOR_TOP, limit=>0 )', 
		r=> "SELECT a, b, c FROM t1 ORDER BY a ASC",
		n=> 'Command=TOP, Limit is ZERO',
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "060",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "distinct","a" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "distinct", "a" ] )', 
		r=> "SELECT DISTINCT a FROM t1",
		n=> 'Select with DISTINCT array sequence',
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "061",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "distinct" => "a" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "distinct" => "a" ] )', 
		r=> "SELECT DISTINCT a FROM t1",
		n=> 'Select with DISTINCT based hash',
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "062",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "count(*)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "count(*)" ] )', 
		r=> "SELECT count(*) FROM t1",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "063",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "max(t1.a)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "max(t1.a)" ] )', 
		r=> "SELECT max(t1.a) FROM t1",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "064",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "max(a)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "max(a)" ] )', 
		r=> "SELECT max(a) FROM t1",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "065",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "substr(a,1,8)" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "substr(a,1,8)" ] )', 
		r=> "SELECT substr(a,1,8) FROM t1",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "066",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "\\aaa.bbb.ccc" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "\\aaa.bbb.ccc" ] )', 
		r=> "SELECT aaa.bbb.ccc FROM t1",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "067",
		s=> sub { $mymod->Select( table=>"t1", fields => [ "distinct","\\aaa.bbb.ccc" ], make_only=>1) },
		t=> 'Select( table=>"t1", fields => [ "distinct","\\aaa.bbb.ccc" ] )', 
		r=> "SELECT DISTINCT aaa.bbb.ccc FROM t1",
		c=> \%cursor,
	);
	&my_cmd
	(
		f=> "070",
		s=> sub { $mymod->Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ 't1.a' => 't2.b' ], make_only=>1, sql_save=>1 ) },
		t=> 'Select( table=>["t1","t2"], fields => [ "t1.a","t2.b" ], where => [ \'t1.a\' => \'t2.b\' ], sql_save=>1 )',
		r=> "SELECT t1.a, t2.b FROM t1, t2 WHERE t1.a = t2.b",
		n=> "SQL_SAVE enabled",
		w=> 1,
	);
	&my_cmd
	(
		f=> "071",
		s=> sub { $mymod->Select( table=>"t1", order_by => "t1.a",  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => "t1.a" )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a",
	);
	&my_cmd
	(
		f=> "072",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ {"t1.a" => "asc"} ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ {"t1.a" => "asc"} ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a ASC",
	);
	&my_cmd
	(
		f=> "073",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ {"t1.a" => "desc"} ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ {"t1.a" => "desc"} ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a DESC",
	);
	&my_cmd
	(
		f=> "074",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ "t1.a", "t1.b" ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ "t1.a", "t1.b" ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a, t1.b",
	);
	&my_cmd
	(
		f=> "075",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ {"t1.a" => "asc"}, "t1.b" ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ {"t1.a" => "asc"}, "t1.b" ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a ASC, t1.b",
	);
	&my_cmd
	(
		f=> "076",
		s=> sub { $mymod->Select( table=>"t1", order_by => [ "t1.a",{"t1.b"=>"desc"} ] ,  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => [ "t1.a", {"t1.b"=>"desc"} ] )', 
		r=> "SELECT * FROM t1 ORDER BY t1.a, t1.b DESC",
	);
	&my_cmd
	(
		f=> "077",
		s=> sub { $mymod->Select( table=>"t1", order_by => {"t1.b"=>"desc"},  make_only=>1) },
		t=> 'Select( table=>"t1", order_by => {"t1.b"=>"desc"} )', 
		r=> "SELECT * FROM t1 ORDER BY t1.b DESC",
	);

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
	diag("");
	done_testing();
	exit;

################################################################################

sub my_cmd()
{
	my $argv = {@_};

	diag("################################################################");
	diag("test: ".$argv->{f});
	diag("format: ".$argv->{t});

	&{$argv->{s}};
	my $buffer = $mymod->getLastSQL();
	my $myrc = $mymod->getRC();

	diag("rc: ".$myrc);
	diag("msg: ".$mymod->getMessage()) if ($myrc);
	diag("note: ".$argv->{n}) if (defined($argv->{n}));

	if ($argv->{w})
	{
		my $savefile = $mymod->getLastSave();
		diag("result: ".$buffer);
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
				push(@er,$argv->{f});
			}
		}
		else
		{
			diag("status: ERROR, ".$!);
			push(@er,$argv->{f});
		}
		return;
	}
	if ($buffer eq $argv->{r} || (defined($argv->{r2}) && $buffer eq $argv->{r2}))
	{
		if ($show_ok)
		{
			diag("tester: ".$argv->{r});
			diag("        ".$argv->{r2}) if (defined($argv->{r2}));
		}
		diag("result: ".$buffer);
		diag("status: SUCCESSFUL");
		$ok++;
	}
	else
	{
		diag("tester: ".$argv->{r});
		diag("tester: ".$argv->{r2}) if (defined($argv->{r2}));
		diag("result: ".$buffer);
		diag("status: ERROR");
		push(@er,$argv->{f});
	}
}

__END__
