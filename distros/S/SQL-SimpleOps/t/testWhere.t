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
	use Test::More;
	use Data::Dumper;

	$Data::Dumper::Varname = '';
	$Data::Dumper::Terse = 1;
	$Data::Dumper::Pad = "";

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

	&my_where ( f=>"001", t=> "t1", w=> [ "id"=> "info" ], r=> "id = 'info'" );
	&my_where ( f=>"002", t=> "t1", w=> [ "id"=> [ "=", "info" ] ], r=> "id = 'info'" );
	&my_where ( f=>"003", t=> "t1", w=> [ "id"=> [ "!", "info" ] ], r=> "id != 'info'" );
	&my_where ( f=>"004", t=> "t1", w=> [ "id"=> [ "<", "info" ] ], r=> "id < 'info'" );
	&my_where ( f=>"005", t=> "t1", w=> [ "id"=> [ ">", "info" ] ], r=> "id > 'info'" );
	&my_where ( f=>"006", t=> "t1", w=> [ "id"=> [ "^%", "info" ] ], r=> "id LIKE 'info%'" );
	&my_where ( f=>"007", t=> "t1", w=> [ "id"=> [ "%%", "info" ] ], r=> "id LIKE '%info%'" );
	&my_where ( f=>"008", t=> "t1", w=> [ "id"=> [ "%^", "info" ] ], r=> "id LIKE '%info'" );
	&my_where ( f=>"009", t=> "t1", w=> [ "id"=> [ "^^", "info" ] ], r=> "id LIKE 'info'" );
	&my_where ( f=>"010", t=> "t1", w=> [ "id"=> undef ], r=> "id IS NULL" );
	&my_where ( f=>"011", t=> "t1", w=> [ "id"=> [ "!", undef ] ], r=> "id NOT NULL" );
	&my_where ( f=>"012", t=> "t1", w=> [ "id"=> [ "info1", "info2" ] ], r=> "id IN ('info1','info2')" );
	&my_where ( f=>"013", t=> "t1", w=> [ "id"=> [ "!", "info1", "info2" ] ], r=> "id NOT IN ('info1','info2')" );
	&my_where ( f=>"014", t=> "t1", w=> [ "id"=> [ "info1", "..", "info2" ] ], r=> "id BETWEEN ('info1','info2')" );
	&my_where ( f=>"015", t=> "t1", w=> [ "id"=> [ "!", "info1", "..", "info2" ] ], r=> "id NOT BETWEEN ('info1','info2')" );

	&my_where ( f=>"020", t=> "t1", w=> [ "id"=> "info", "id" => "info2",       "no" => "no1", no => "no2" ], r=> "id = 'info' AND id = 'info2' AND no = 'no1' AND no = 'no2'" );
	&my_where ( f=>"021", t=> "t1", w=> [ "id"=> "info", "id" => "info2", "or", "no" => "no1", no => "no2" ], r=> "id = 'info' AND id = 'info2' OR no = 'no1' AND no = 'no2'" );

	&my_where ( f=>"100", t=> ["t1","t2"], w=> [ "t1.id" => "t2.id" ], r=> "t1.id = t2.id" );
	&my_where ( f=>"101", t=> ["t1","t2"], w=> [ "t1.id" => [ "=", "t2.id" ] ], r=> "t1.id = t2.id" );
	&my_where ( f=>"102", t=> ["t1","t2"], w=> [ "t1.id" => [ "!", "t2.id" ] ], r=> "t1.id != t2.id" );

	&my_where ( f=>"110", t=> ["t1","t2","t3"], w=> [ "t1.id" => "t2.id", "t1.id" => "t3.id" ], r=> "t1.id = t2.id AND t1.id = t3.id" );
	&my_where ( f=>"111", t=> ["t1","t2","t3"], w=> [ "t1.id" => [ "=", "t2.id" ], "t1.id" => [ "=", "t3.id" ] ], r=> "t1.id = t2.id AND t1.id = t3.id" );
	&my_where ( f=>"112", t=> ["t1","t2","t3"], w=> [ "t1.id" => [ "!", "t2.id" ], "t1.id" => [ "!", "t3.id" ] ], r=> "t1.id != t2.id AND t1.id != t3.id" );
	&my_where ( f=>"113", t=> ["t1","t2","t3"], w=> [ "t1.id" => "t2.id", "or", "t1.id" => "t3.id" ], r=> "t1.id = t2.id OR t1.id = t3.id");

	&my_where
	(
		f=> "200",
		w=> [ [ "id" => 1, id => 2 ], [ no => 3, no => 4 ] ],
		t=> "t1",
		r=> "(id = '1' AND id = '2') AND (no = '3' AND no = '4')",
	);
	&my_where
	(
		f=> "201",
		w=> [ "id" => [ "^%", 1, 2 ], no => [ "%^", 3, 4 ] ],
		t=> "t1",
		r=> "(id LIKE '1%' OR id LIKE '2%') AND (no LIKE '%3' OR no LIKE '%4')",
	);
	&my_where
	(
		f=> "202",
		w=> [ "id" => [ "!^%", 1, 2 ], no => [ "!%^", 3, 4 ] ],
		t=> "t1",
		r=> "(id NOT LIKE '1%' AND id NOT LIKE '2%') AND (no NOT LIKE '%3' AND no NOT LIKE '%4')",
	);
	&my_where
	(
		f=> "203",
		w=> [ "id" => [ "!^%", 1, 2 ], "or", no => [ "!%^", 3, 4 ] ],
		t=> "t1",
		r=> "(id NOT LIKE '1%' AND id NOT LIKE '2%') OR (no NOT LIKE '%3' AND no NOT LIKE '%4')",
	);
	&my_where
	(
		f=> "204",
		w=> [ "id" => [ "!", undef ], "or", no => undef ],
		t=> "t1",
		r=> "id NOT NULL OR no IS NULL",
	);
	&my_where ( f=>"205", t=> "t1", w=> [ [ [ a=>1, b=>2 ], "or", [ c=>3, d=>4 ] ], e=>5 ], r=>"((a = '1' AND b = '2') OR (c = '3' AND d = '4')) AND e = '5'" );

	&my_where ( f=>"300", t=> "t1", w=> [ a => "\\concat(a,'abc')" ], r=>"a = concat(a,'abc')" );
	&my_where ( f=>"301", t=> "t1", w=> [ a => [ "!", "\\concat(a,'abc')" ] ], r=>"a != concat(a,'abc')" );

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
