
use strict;
use warnings;
use Cwd qw(realpath);
use Test::More;
use DBI;

# test we can connect to a postgres on localhost
# test we can use the plperlu language
# if so, create and execute the test SP

(my $sqlfile = __FILE__) =~ s/\.t/.sql/;
(my $dir = realpath($sqlfile)) =~ s:/t/[^/]+$::;

# create test db
use Test::PostgreSQL;
my $dbname = "plperl_call_test".$$;
my $pgsql = eval { Test::PostgreSQL->new }
	or plan skip_all => $@;

my $dbh = eval { DBI->connect($pgsql->dsn, undef, undef, {}) }
	or plan skip_all => "Can't connect to local database: $@";

$dbh->{pg_server_version} >= 90000
	or plan skip_all => "Requires PostgreSQL 9.0 or later";

# set @INC - also checks plperlu works
$dbh->do(qq{
        create extension if not exists plperl;
        CREATE or REPLACE language plperlu;
	DO '
		warn "Using directory $dir\n";
		# for normal testing via dzil test
		require blib;
		require  lib;
		eval { blib->import("$dir/blib") }
			or eval {  lib->import("$dir/lib") };
	' language plperlu;
})
	or plan skip_all => "Need to use plperlu for test";

plan tests => 1;

my $func = 'call_test10';

my $sql = do { # slurp!
	open my $fh, $sqlfile or die "Can't open $sqlfile: $!";
	local $/;
	<$fh>
};
$dbh->do($sql);

my ($status) = $dbh->selectrow_array("select $func()");
is $status, 'PASS', 'all tests are go!';
