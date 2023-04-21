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

	our $VERSION = "2023.106.1";

	BEGIN{ use_ok('SQL::SimpleOps'); }

	## create dbh entry point (is required)

	my $mymod = new SQL::SimpleOps
	(
		driver => "sqlite",	# you can use any database engine
		db => "teste",		# you can use any database name
		dbfile => ":memory:",	# use ram memory
		connect => 0,		# do not open database
	);

	diag("");

	## where tests

	my $show_ok = (defined($ENV{SQL_SIMPLE_WHERE_SHOW_OK}) && $ENV{SQL_SIMPLE_WHERE_SHOW_OK} ne "");
	my $er;
	my $ok;

	&my_where ( f=>"101", t=> "t1", w=> [ "id"=> "info" ], r=> "id = 'info'" );
	&my_where ( f=>"102", t=> "t1", w=> [ "id"=> [ "=", "info" ] ], r=> "id = 'info'" );
	&my_where ( f=>"103", t=> "t1", w=> [ "id"=> [ "!", "info" ] ], r=> "id != 'info'" );
	&my_where ( f=>"104", t=> "t1", w=> [ "id"=> [ "<", "info" ] ], r=> "id < 'info'" );
	&my_where ( f=>"105", t=> "t1", w=> [ "id"=> [ ">", "info" ] ], r=> "id > 'info'" );
	&my_where ( f=>"106", t=> "t1", w=> [ "id"=> [ "^%", "info" ] ], r=> "id LIKE 'info%'" );
	&my_where ( f=>"107", t=> "t1", w=> [ "id"=> [ "%%", "info" ] ], r=> "id LIKE '%info%'" );
	&my_where ( f=>"108", t=> "t1", w=> [ "id"=> [ "%^", "info" ] ], r=> "id LIKE '%info'" );
	&my_where ( f=>"109", t=> "t1", w=> [ "id"=> [ "^^", "info" ] ], r=> "id LIKE 'info'" );
	&my_where ( f=>"110", t=> "t1", w=> [ "id"=> undef ], r=> "id IS NULL" );
	&my_where ( f=>"111", t=> "t1", w=> [ "id"=> [ "!", undef ] ], r=> "id NOT NULL" );
	&my_where ( f=>"112", t=> "t1", w=> [ "id"=> [ "info1", "info2" ] ], r=> "id IN ('info1','info2')" );
	&my_where ( f=>"113", t=> "t1", w=> [ "id"=> [ "!", "info1", "info2" ] ], r=> "id NOT IN ('info1','info2')" );
	&my_where ( f=>"114", t=> "t1", w=> [ "id"=> [ "info1", "..", "info2" ] ], r=> "id BETWEEN ('info1','info2')" );
	&my_where ( f=>"115", t=> "t1", w=> [ "id"=> [ "!", "info1", "..", "info2" ] ], r=> "id NOT BETWEEN ('info1','info2')" );

	&my_where ( f=>"120", t=> "t1", w=> [ "id"=> "info", "id" => "info2",       "no" => "no1", no => "no2" ], r=> "id = 'info' AND id = 'info2' AND no = 'no1' AND no = 'no2'" );
	&my_where ( f=>"121", t=> "t1", w=> [ "id"=> "info", "id" => "info2", "or", "no" => "no1", no => "no2" ], r=> "id = 'info' AND id = 'info2' OR no = 'no1' AND no = 'no2'" );

	&my_where ( f=>"200", t=> ["t1","t2"], w=> [ "t1.id" => "t2.id" ], r=> "t1.id = t2.id" );
	&my_where ( f=>"201", t=> ["t1","t2"], w=> [ "t1.id" => [ "=", "t2.id" ] ], r=> "t1.id = t2.id" );
	&my_where ( f=>"202", t=> ["t1","t2"], w=> [ "t1.id" => [ "!", "t2.id" ] ], r=> "t1.id != t2.id" );

	&my_where ( f=>"210", t=> ["t1","t2","t3"], w=> [ "t1.id" => "t2.id", "t1.id" => "t3.id" ], r=> "t1.id = t2.id AND t1.id = t3.id" );
	&my_where ( f=>"211", t=> ["t1","t2","t3"], w=> [ "t1.id" => [ "=", "t2.id" ], "t1.id" => [ "=", "t3.id" ] ], r=> "t1.id = t2.id AND t1.id = t3.id" );
	&my_where ( f=>"212", t=> ["t1","t2","t3"], w=> [ "t1.id" => [ "!", "t2.id" ], "t1.id" => [ "!", "t3.id" ] ], r=> "t1.id != t2.id AND t1.id != t3.id" );
	&my_where ( f=>"213", t=> ["t1","t2","t3"], w=> [ "t1.id" => "t2.id", "or", "t1.id" => "t3.id" ], r=> "t1.id = t2.id OR t1.id = t3.id");
	&my_where ( f=>"214", t=> ["t1","t2"], w=> [ 't1.id' => 't2.id', 't1.id' => [ '1234','..','5678' ], [ 't1.id' => [ '!', 0 ], 'or', 't2.id' => [ '!', 0 ] ] ], r=> "t1.id = t2.id AND t1.id BETWEEN ('1234','5678') AND (t1.id != '0' OR t2.id != '0')");

	&my_where
	(
		f=> "220",
		w=> [ [ "id" => 1, id => 2 ], [ no => 3, no => 4 ] ],
		t=> "t1",
		r=> "(id = '1' AND id = '2') AND (no = '3' AND no = '4')",
	);
	&my_where
	(
		f=> "221",
		w=> [ "id" => [ "^%", 1, 2 ], no => [ "%^", 3, 4 ] ],
		t=> "t1",
		r=> "(id LIKE '1%' OR id LIKE '2%') AND (no LIKE '%3' OR no LIKE '%4')",
	);
	&my_where
	(
		f=> "222",
		w=> [ "id" => [ "!^%", 1, 2 ], no => [ "!%^", 3, 4 ] ],
		t=> "t1",
		r=> "(id NOT LIKE '1%' AND id NOT LIKE '2%') AND (no NOT LIKE '%3' AND no NOT LIKE '%4')",
	);
	&my_where
	(
		f=> "223",
		w=> [ "id" => [ "!^%", 1, 2 ], "or", no => [ "!%^", 3, 4 ] ],
		t=> "t1",
		r=> "(id NOT LIKE '1%' AND id NOT LIKE '2%') OR (no NOT LIKE '%3' AND no NOT LIKE '%4')",
	);
	&my_where
	(
		f=> "224",
		w=> [ "id" => [ "!", undef ], "or", no => undef ],
		t=> "t1",
		r=> "id NOT NULL OR no IS NULL",
	);
	&my_where ( f=>"225", t=> "t1", w=> [ [ [ a=>1, b=>2 ], "or", [ c=>3, d=>4 ] ], e=>5 ], r=>"((a = '1' AND b = '2') OR (c = '3' AND d = '4')) AND e = '5'" );

	&my_where ( f=>"230", t=> "t1", w=> [ a => "\\concat(a,'abc')" ], r=>"a = concat(a,'abc')" );
	&my_where ( f=>"231", t=> "t1", w=> [ a => [ "!", "\\concat(a,'abc')" ] ], r=>"a != concat(a,'abc')" );

	fail($er." error") if ($er);
	pass($ok." successful") if ($ok);

	if (!defined($ENV{SQL_SIMPLE_WHERE_SHOW_OK}) || $ENV{SQL_SIMPLE_WHERE_SHOW_OK} eq "")
	{
		diag("");
		diag("To see the input options used to create the 'where' clause, rerun the test with:");
		diag("");
		diag("export SQL_SIMPLE_WHERE_SHOW_OK=1");
	}
	diag("");
	done_testing();
	exit;

################################################################################

sub my_where()
{
	my $argv = {@_};

	diag("################################################################");

	my @input = Dumper($argv->{w});
	my $buffer;

	$mymod->getWhere
	(
		table => $argv->{t},
		where => $argv->{w},
		buffer => \$buffer
	);
	if ($argv->{r} ne $buffer)
	{
		diag("test: ".$argv->{f});
		foreach my $i(@input) { diag($i); }
		diag("tester: ".$argv->{r});
		diag("result: ".$buffer);
		if ($mymod->getRC())
		{
			diag("msg: ".$mymod->getMessage());
			diag("rc: ".$mymod->getRC());
		}
		diag("test: ".$argv->{f}.", ERROR");
		$er++;
	}
	else
	{
		if ($show_ok)
		{
			diag("test: ".$argv->{f});
			foreach my $i(@input) { diag($i); }
		}
		diag("result: ".$buffer);
		diag("test: ".$argv->{f}.", SUCCESSFUL");
		$ok++;
	}
}

__END__
