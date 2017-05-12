#! /usr/bin/perl -w
#*********************************************************************
#*** t/50Command_Execute.t
#*** Copyright (c) 2003-2004 by Markus Winand <mws@fatalmind.com>
#*** $Id: 60Command_connected.t,v 1.2 2004/05/02 07:49:00 mws Exp $
#*********************************************************************
use strict;

use Test;
use ResourcePool;
use ResourcePool::Factory::DBI;
use ResourcePool::Command::DBI::Execute;
use ResourcePool::Command::DBI::Select;
use ResourcePool::Command::DBI::SelectRow;
use DBI qw(:sql_types);

BEGIN {
	plan tests => 73;
}

sub dbi($$$@) {
		my ($ds, $dbiok, $no) = @_;
		$no = 1 unless defined $no;
		my $i;

		if (! defined $ds) {
				for ($i = 0; $i < $no; $i++) {
						skip("skip no Database server configured for testing", 0);
				}
				return 0;
		} elsif (! $dbiok) {
				for ($i = 0; $i < $no; $i++) {
						skip("skip the supplied Database configuration seems to be faulty", 0);
				}
				return 0;
		} 
		return 1;
}

my ($user, $ds, $pass, $dbiok);
$ds   = $ENV{RESOURCEPOOL_DBI_DS};
$user = $ENV{RESOURCEPOOL_DBI_USER};
$pass = $ENV{RESOURCEPOOL_DBI_PASS};

# there shall be silence
$SIG{'__WARN__'} = sub {};

if (dbi($ds, 1, 1)) {
	my $dbh = DBI->connect($ds, $user, $pass);
	$dbiok = defined $dbh;	
	ok ($dbiok);
	if ($dbiok) {
		$dbh->disconnect();
	} else {
		print $DBI::errstr . "\n";
	}
} 

sub dotest($) {
	my ($p) = @_;

	sub check($) {
		my ($code) = @_;
		eval {
			&$code();
		};
		ok (! $@);
		if ($@) {
			print "#rootException: " . $@->rootException();
		}
	}

my $cmd = ResourcePool::Command::DBI::Execute->new();
if (dbi($ds, $dbiok, 1)) {
	check(sub {
			$p->execute($cmd, q{
				create table resourcepool_test (
					id	numeric(11) not null,
					x	varchar(50),
					y	varchar(50)
				)
			});
	});
}

if (dbi($ds, $dbiok, 1)) {
	check(sub {
		$p->execute($cmd, "insert into resourcepool_test values (1, 'x', 'y')");
	});
}

if (dbi($ds, $dbiok, 1)) {
	check(sub {
		$p->execute($cmd, 'insert into resourcepool_test values (?, ?, ?)', 2, 'x2', 'y2');
	});
}

my $insert = ResourcePool::Command::DBI::Execute->new('insert into resourcepool_test values (?, ?, ?)');

if (dbi($ds, $dbiok, 1)) {
	check(sub { $p->execute($insert, 3, 'x3', 'y3'); });
}

if (dbi($ds, $dbiok, 2)) {
	# will fail with NoFailoverException
	eval {
		$p->execute($insert, undef, 'x3', 'y3');
	};
	ok ($@);
	if ($@) {
		ok ($@->getExecutions() == 1);
	} else {
		skip "skip follow up", 0;
	}
}

if (dbi($ds, $dbiok, 1)) {
	check(sub {$p->execute($insert, {1 => 4, 2 => 'x4', 3 => 'y3'});});
}

my $insert2 = ResourcePool::Command::DBI::Execute->new(
	'insert into resourcepool_test values (?, ?, ?)'
	, {
		  1 => {type => SQL_INTEGER}
		, 3 => {type => SQL_VARCHAR}
	}
	, prepare_cached => 1
);

if (dbi($ds, $dbiok, 1)) {
	check(sub { $p->execute($insert2, 5, 'x5', 'y3'); });
}

my $insert3 = ResourcePool::Command::DBI::Execute->new(
	'insert into resourcepool_test values (?, ?, ?)'
	, prepare_cached => 1
);

if (dbi($ds, $dbiok, 1)) {
	check(sub { $p->execute($insert3, 6, 'x3', 'y3'); });
}

#### this tests needs oracle...

if (dbi($ds, $dbiok, 2)) {
		if ($ds =~ m/^DBI:Oracle/) {
			my $output = ResourcePool::Command::DBI::Execute->new(
				"insert into resourcepool_test values (7, UPPER(:x), :y) " 
					. "returning x into :out"
				, {':out' => {max_len => 50}}
			);		
			my $out = '';
			check(sub {$p->execute($output, {':out' => \$out
				, ':x' => 'hirsch'
				, ':y' => 'elch'});}
			);
			ok ($out eq 'HIRSCH');	
			
		} else {
			skip "skip this test needs an oracle DB (bind_param_inout)", 0;
			skip "skip this test needs an oracle DB (bind_param_inout)", 0;
		}
}

###
# till here, we tested Execute
# now Select starts
###

my $select = ResourcePool::Command::DBI::Select->new(
	'select id, x, y from resourcepool_test where id = ?'
);

if (dbi($ds, $dbiok, 4)) {
	my $sth;
	eval {
		$sth = $p->execute($select, 5);
	};
	ok (! $@);
	if (!$@) {
		my $i = 0;
		my $cont;
		$cont = $sth->fetchrow_arrayref();
		ok (defined $cont);
		ok($cont->[1] eq 'x5');
		$cont = $sth->fetchrow_arrayref();
		ok (! defined $cont);
		$sth->finish();
	} else {
		skip "skip follow up", 0;
		skip "skip follow up", 0;
		skip "skip follow up", 0;
	}
}

my $selectrow = ResourcePool::Command::DBI::SelectRow->new(
	'select id, x, y from resourcepool_test where id = ?'
);

if (dbi($ds, $dbiok, 2)) {
	my @ret;
	check(sub {
		@ret = $p->execute($selectrow, 1);
	});
	ok (scalar(@ret) == 3);	
}

if (dbi($ds, $dbiok, 1)) {
	check(sub {
		$p->execute($cmd, q{
			drop table resourcepool_test
		});
	});
}

} # end sub dotest

my $f = ResourcePool::Factory::DBI->new($ds, $user, $pass);
my $p = ResourcePool->new($f);
print "# first run, using defaults\n";
dotest($p);

$f = ResourcePool::Factory::DBI->new($ds, $user, $pass, {RaiseError => 1});
$p = ResourcePool->new($f);
print "# second run, RaiseError => 1\n";
dotest($p);

$f = ResourcePool::Factory::DBI->new($ds, $user, $pass, {AutoCommit => 1});
$p = ResourcePool->new($f);
print "# third run, AutoCommit => 1\n";
dotest($p);

$f = ResourcePool::Factory::DBI->new($ds, $user, $pass, {AutoCommit => 1, RaiseError => 1});
$p = ResourcePool->new($f);
print "# forth run, AutoCommit => 1, RaiseError => 1\n";
dotest($p);

