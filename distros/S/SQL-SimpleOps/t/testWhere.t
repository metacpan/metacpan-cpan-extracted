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

	our $VERSION = "2023.362.1";

	BEGIN{ use_ok('SQL::SimpleOps'); }

###############################################################################
## enable this option to abort on first error

	#$ENV{EXIT_ON_FIRT_ERROR} = 1;

###############################################################################
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
	my @er;
	my $ok;

	&my_where
	(
		f=> "0101",
		t=> "t1",
		w=> [ "id"=> "info" ],
		r=> "id = 'info'"
	);
	&my_where
	(
		f=> "0102",
		t=> "t1",
		w=> [ "id"=> [ "=", "info" ] ],
		r=> "id = 'info'"
	);
	&my_where
	(
		f=> "0103",
		t=> "t1",
		w=> [ "id"=> [ "!", "info" ] ],
		r=> "id != 'info'"
	);
	&my_where
	(
		f=> "0104",
		t=> "t1",
		w=> [ "id"=> [ "<", "info" ] ],
		r=> "id < 'info'"
	);
	&my_where
	(
		f=> "0105",
		t=> "t1",
		w=> [ "id"=> [ ">", "info" ] ],
		r=> "id > 'info'"
	);
	&my_where
	(
		f=> "0106",
		t=> "t1",
		w=> [ "id"=> [ "^%", "info" ] ],
		r=> "id LIKE 'info%'"
	);
	&my_where
	(
		f=> "0107",
		t=> "t1",
		w=> [ "id"=> [ "%%", "info" ] ],
		r=> "id LIKE '%info%'"
	);
	&my_where
	(
		f=> "0108",
		t=> "t1",
		w=> [ "id"=> [ "%^", "info" ] ],
		r=> "id LIKE '%info'"
	);
	&my_where
	(
		f=> "0109",
		t=> "t1",
		w=> [ "id"=> [ "^^", "info" ] ],
		r=> "id LIKE 'info'"
	);
	&my_where
	(
		f=> "0110",
		t=> "t1",
		w=> [ "id"=> undef ],
		r=> "id IS NULL"
	);
	&my_where
	(
		f=> "0111",
		t=> "t1",
		w=> [ "id"=> [ "!", undef ] ],
		r=> "id NOT NULL"
	);
	&my_where
	(
		f=> "0112",
		t=> "t1",
		w=> [ "id"=> [ "info1", "info2" ] ],
		r=> "id IN ('info1','info2')"
	);
	&my_where
	(
		f=> "0113",
		t=> "t1",
		w=> [ "id"=> [ "!", "info1",
				"info2" ] ],
		r=> "id NOT IN ('info1','info2')"
	);
	&my_where
	(
		f=> "0114",
		t=> "t1",
		w=> [ "id"=> [ "info1", "..", "info2" ] ],
		r=> "id BETWEEN ('info1','info2')"
	);
	&my_where
	(
		f=> "0115",
		t=> "t1",
		w=> [ "id"=> [ "!", "info1", "..", "info2" ] ],
		r=> "id NOT BETWEEN ('info1','info2')"
	);
	&my_where
	(
		f=> "0120",
		t=> "t1",
		w=> [ "id"=> "info", "id" => "info2", "no" => "no1", no => "no2" ],
		r=> "id = 'info' AND id = 'info2' AND no = 'no1' AND no = 'no2'"
	);
	&my_where
	(
		f=> "0121",
		t=> "t1",
		w=> [ "id"=> "info", "id" => "info2", "or", "no" => "no1", no => "no2" ],
		r=> "id = 'info' AND id = 'info2' OR no = 'no1' AND no = 'no2'"
	);
	&my_where
	(
		f=> "0200",
		t=> ["t1","t2"],
		w=> [ "t1.id" => "\\t2.id" ],
		r=> "t1.id = t2.id"
	);
	&my_where
	(
		f=> "0201",
		t=> ["t1","t2"],
		w=> [ "t1.id" => [ "=", "\\t2.id" ] ],
		r=> "t1.id = t2.id"
	);
	&my_where
	(
		f=> "0202",
		t=> ["t1","t2"],
		w=> [ "t1.id" => [ "!", "\\t2.id" ] ],
		r=> "t1.id != t2.id"
	);
	&my_where
	(
		f=> "0210",
		t=> ["t1","t2","t3"],
		w=> [ "t1.id" => "\\t2.id", "t1.id" => "\\t3.id" ],
		r=> "t1.id = t2.id AND t1.id = t3.id"
	);
	&my_where
	(
		f=> "0211",
		t=> ["t1","t2","t3"],
		w=> [ "t1.id" => [ "=", "\\t2.id" ], "t1.id" => [ "=", "\\t3.id" ] ],
		r=> "t1.id = t2.id AND t1.id = t3.id"
	);
	&my_where
	(
		f=> "0212",
		t=> ["t1","t2","t3"],
		w=> [ "t1.id" => [ "!", "\\t2.id" ], "t1.id" => [ "!", "\\t3.id" ] ],
		r=> "t1.id != t2.id AND t1.id != t3.id"
	);
	&my_where
	(
		f=> "0213",
		t=> ["t1","t2","t3"],
		w=> [ "t1.id" => "\\t2.id", "or", "t1.id" => "\\t3.id" ],
		r=> "t1.id = t2.id OR t1.id = t3.id"
	);
	&my_where
	(
		f=> "0214",
		t=> ["t1","t2"],
		w=> [ 't1.id' => '\\t2.id', 't1.id' => [ '1234','..','5678' ], [ 't1.id' => [ '!', 0 ], 'or', 't2.id' => [ '!', 0 ] ] ],
		r=> "t1.id = t2.id AND t1.id BETWEEN ('1234','5678') AND (t1.id != '0' OR t2.id != '0')"
	);
	&my_where
	(
		f=> "0220",
		w=> [ [ "id" => 1, id => 2 ], [ no => 3, no => 4 ] ],
		t=> "t1",
		r=> "(id = '1' AND id = '2') AND (no = '3' AND no = '4')",
	);
	&my_where
	(
		f=> "0221",
		w=> [ "id" => [ "^%", 1, 2 ], no => [ "%^", 3, 4 ] ],
		t=> "t1",
		r=> "(id LIKE '1%' OR id LIKE '2%') AND (no LIKE '%3' OR no LIKE '%4')",
	);
	&my_where
	(
		f=> "0222",
		w=> [ "id" => [ "!^%", 1, 2 ], no => [ "!%^", 3, 4 ] ],
		t=> "t1",
		r=> "(id NOT LIKE '1%' AND id NOT LIKE '2%') AND (no NOT LIKE '%3' AND no NOT LIKE '%4')",
	);
	&my_where
	(
		f=> "0223",
		w=> [ "id" => [ "!^%", 1, 2 ], "or", no => [ "!%^", 3, 4 ] ],
		t=> "t1",
		r=> "(id NOT LIKE '1%' AND id NOT LIKE '2%') OR (no NOT LIKE '%3' AND no NOT LIKE '%4')",
	);
	&my_where
	(
		f=> "0224",
		w=> [ "id" => [ "!", undef ], "or", no => undef ],
		t=> "t1",
		r=> "id NOT NULL OR no IS NULL",
	);
	&my_where
	(
		f=> "0225",
		t=> "t1",
		w=> [ [ [ a=>1, b=>2 ], "or", [ c=>3, d=>4 ] ], e=>5 ],
		r=> "((a = '1' AND b = '2') OR (c = '3' AND d = '4')) AND e = '5'"
	);

	&my_where
	(
		f=> "0230",
		t=> "t1",
		w=> [ a => "\\concat(a,'abc')" ],
		r=> "a = concat(a,'abc')"
	);
	&my_where
	(
		f=> "0231",
		t=> "t1",
		w=> [ a => [ "!", "\\concat(a,'abc')" ] ],
		r=> "a != concat(a,'abc')"
	);
	&my_where
	(
		f=> "0232",
		t=> "t1",
		w=> [ a => "xx'xx" ],
		r=> "a = 'xx\\'xx'",
	);
	&my_where
	(
		f=> "0233",
		t=> "t1",
		w=> [ a => [ "!", "xx'xx" ] ],
		r=> "a != 'xx\\'xx'",
	);
	&my_where
	(
		f=> "0234",
		t=> "t1",
		w=> [ a => [ "xx'xx", "yy'yy" ] ],
		r=> "a IN ('xx\\'xx','yy\\'yy')",
	);
	&my_where
	(
		f=> "0235",
		t=> "t1",
		w=> [ a => [ "xx'xx", "..", "yy'yy" ] ],
		r=> "a BETWEEN ('xx\\'xx','yy\\'yy')",
	);
	&my_where
	(
		f=> "0240",
		t=> "t1",
		w=> [ a => 1, [ [ b => [], "or", c => 2 ] ] ],
		r=> "a = '1' AND c = '2'",
	);
	&my_where
	(
		f=> "0241",
		t=> "t1",
		w=> [ a => 1, [ [ b => [] ], "or", [ c => 2 ] ] ],
		r=> "a = '1' AND c = '2'",
	);

	diag("################################################################");
	fail((@er+0)." error, tests: ".join(", ",@er)) if (@er);
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
	exit(0);

################################################################################

sub my_where()
{
	my $argv = {@_};

	my $w = join(" ",Dumper($argv->{w}));
	$w =~ s/[\n\r]//g;
	$w =~ tr/\t/ /;
	while (1)
	{
		my $_w = $w;
		$_w =~ s/  / /g;
		last if ($_w eq $w);
		$w = $_w;
	}

	diag("################################################################");
	diag("test-W".$argv->{f}.": where => ".$w);

	my $buffer;
	$mymod->getWhere
	(
		table => $argv->{t},
		where => $argv->{w},
		buffer => \$buffer
	);
	if ($argv->{r} ne $buffer)
	{
		diag("expected: ".$argv->{r});
		diag("message.: ".$mymod->getMessage()) if ($mymod->getRC());
		diag("returns.: ".$buffer);
		diag("status..: ERROR");
		push(@er,$argv->{f});
	}
	else
	{
		if ($show_ok)
		{
			diag("test: ".$argv->{f});
		}
		diag("returns.: ".$buffer);
		diag("status..: SUCCESSFUL");
		$ok++;
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
