#!/usr/bin/perl -w
use strict;
use warnings;
use lib qw(t);

use Test::More;
use TestLib qw(connect prove_reqs show_reqs test_dir default_recommended);

use Clone qw(clone);
use Params::Util qw(_CODE _ARRAY);

my ( $required, $recommended ) = prove_reqs( { default_recommended(), ( MLDBM => 0 ) } );
show_reqs( $required, $recommended );
my @test_dbds = ( 'SQL::Statement', grep { /^dbd:/i } keys %{$recommended} );
my $testdir = test_dir();

my @massValues = map { [ $_, ( "a" .. "f" )[ int rand 6 ], int rand 10 ] } ( 1 .. 3999 );

SKIP:
foreach my $test_dbd (@test_dbds)
{
    my $dbh;
    note("Running tests for $test_dbd");
    my $temp = "";
    # XXX
    # my $test_dbd_tbl = "${test_dbd}::Table";
    # $test_dbd_tbl->can("fetch") or $temp = "$temp";
    $test_dbd eq "DBD::File"      and $temp = "TEMP";
    $test_dbd eq "SQL::Statement" and $temp = "TEMP";

    my %extra_args;
    if ( $test_dbd eq "DBD::DBM" )
    {
        if ( $recommended->{MLDBM} )
        {
            $extra_args{dbm_mldbm} = "Storable";
        }
        else
        {
            skip( 'DBD::DBM test runs without MLDBM', 1 );
        }
    }
    elsif( $test_dbd eq "DBD::CSV" )
    {
	$extra_args{csv_null} = 1;
    }

    $dbh = connect(
                    $test_dbd,
                    {
                       PrintError => 0,
                       RaiseError => 0,
                       f_dir      => $testdir,
                       %extra_args,
                    }
                  );

    my $vsql = "SELECT * FROM multi_fruit ORDER BY dKey DESC";
    my $vsth = $dbh->prepare($vsql);
    ok($vsth, "prepare <$vsql> using '$test_dbd'") or diag($dbh->errstr || 'unknown error');

    # evil hack to avoid full dbi emulating in TestLib
    my %store;
    defined $dbh->{stmt} and $store{stmt} = $dbh->{stmt};
    defined $dbh->{sth} and $store{sth} = $dbh->{sth};

    # basic tests taken from DBD::DBM simple tests - should work overall
    my @tests = (
    	"DROP TABLE IF EXISTS multi_fruit", -1,
	"CREATE $temp TABLE multi_fruit (dKey INT, dVal VARCHAR(10), qux INT)", '0E0',
	"INSERT INTO  multi_fruit VALUES (1,'oranges'  , 11 )", 1,
	"INSERT INTO  multi_fruit VALUES (2,'to_change',  0 )", 1,
	"INSERT INTO  multi_fruit VALUES (3, NULL      , 13 )", 1,
	"INSERT INTO  multi_fruit VALUES (4,'to_delete', 14 )", 1,
	undef, [
	    [ 4, 'to_delete', 14 ],
	    [ 3, undef, 13 ],
	    [ 2, 'to_change', 0 ],
	    [ 1, 'oranges', 11 ],
	],
	"INSERT INTO  multi_fruit VALUES (?,?,?); #5,via placeholders,15", 1,
	undef, [
	    [ 5, 'via placeholders', 15 ],
	    [ 4, 'to_delete', 14 ],
	    [ 3, undef, 13 ],
	    [ 2, 'to_change', 0 ],
	    [ 1, 'oranges', 11 ],
	],
	"INSERT INTO  multi_fruit VALUES (6,'to_delete', 16 )", 1,
	"INSERT INTO  multi_fruit VALUES (7,'to delete', 17 )", 1,
	"INSERT INTO  multi_fruit VALUES (8,'to remove', 18 )", 1,
	"UPDATE multi_fruit SET dVal='apples', qux='12' WHERE dKey=2", 1,
	undef, [
	    [ 8, 'to remove', 18 ],
	    [ 7, 'to delete', 17 ],
	    [ 6, 'to_delete', 16 ],
	    [ 5, 'via placeholders', 15 ],
	    [ 4, 'to_delete', 14 ],
	    [ 3, undef, 13 ],
	    [ 2, 'apples', 12 ],
	    [ 1, 'oranges', 11 ],
	],
	"DELETE FROM  multi_fruit WHERE dVal='to_delete'", 2,
	"DELETE FROM  multi_fruit WHERE qux=17", 1,
	"DELETE FROM  multi_fruit WHERE dKey=8", 1,
	undef, [
	    [ 5, 'via placeholders', 15 ],
	    [ 3, undef, 13 ],
	    [ 2, 'apples', 12 ],
	    [ 1, 'oranges', 11 ],
	],
	"DELETE FROM multi_fruit", 4,
	"SELECT COUNT(*) FROM multi_fruit", [ [ 0 ] ],
	"DROP TABLE multi_fruit", -1,
    );

    SKIP:
    for my $idx ( 0 .. $#tests ) {
	$idx % 2 and next;
	my $sql = $tests[$idx];
	my $result = $tests[$idx+1];
	my ($comment, $sth, @bind);

        if( defined $sql )
	{
	    $sql =~ s/;$//;
	    $sql =~ s/\s*;\s*(?:#(.*))//;
	    $comment = $1;
	    $comment and @bind = split /,/, $comment;

	    $sth = $dbh->prepare($sql);
	    ok($sth, "prepare <$sql> using '$test_dbd'") or diag($dbh->errstr || 'unknown error');
	}
	else
	{
	    $sql = $vsql;
	    $sth = $vsth;
	    $comment = undef;
	    # evil hack to avoid full dbi emulating in TestLib
	    defined $store{stmt} and $dbh->{stmt} = $store{stmt};
	    defined $store{sth} and $dbh->{sth} = $store{sth};
	}

        # if execute errors we will handle it, not PrintError:
        my $n = $sth->execute(@bind);
        ok($n, "execute <$sql> using '$test_dbd'") or diag($sth->errstr || 'unknown error');
        next if (!defined($n));

	is( $n, $result, "execute($sql) == $result using '$test_dbd'") unless( 'ARRAY' eq ref $result );
	TODO: {
	    local $TODO = "AUTOPROXY drivers might throw away sth->rows()" if($ENV{DBI_AUTOPROXY});
	    is( $n, $sth->rows(), "\$sth->execute($sql) == \$sth->rows using $test_dbd") if( $sql =~ m/^(?:UPDATE|DELETE)/ );
	}
        next unless $sql =~ /SELECT/;
	my $allrows = $sth->fetch_rows();
	my $expected_rows = $result;
	is( $sth->rows, scalar( @{$expected_rows} ), "execute <$sql> == " . scalar( @{$expected_rows} ) . " using '$test_dbd'" );
	is_deeply( $allrows, $expected_rows, "SELECT results for $sql using $test_dbd" );

	# run SELECT 2nd time to test bug from RT#81523
	$sth->finish();
        $n = $sth->execute(@bind);
        ok($n, "execute <$sql> using '$test_dbd' 2nd time") or diag($sth->errstr || 'unknown error');

	is( $n, $result, "execute($sql) == $result using '$test_dbd'") unless( 'ARRAY' eq ref $result );
	$allrows = $sth->fetch_rows();
	$expected_rows = $result;
	is( $sth->rows, scalar( @{$expected_rows} ), "execute <$sql> == " . scalar( @{$expected_rows} ) . " using '$test_dbd'" );
	is_deeply( $allrows, $expected_rows, "SELECT results for $sql using '$test_dbd' 2nd time" );
    }

    my $i_sql = "INSERT INTO  test_tbl VALUES (?,?)";
    my $s_sql = "SELECT dKey, dVal FROM test_tbl WHERE dKey=?";

    my @rows = (
	[ 1, "Perl" ],
	[ 2, "DBI" ],
	[ 3, "SQL::Statement" ],
	[ 4, "DBD::File" ],
	[ 5, "DBD::CSV" ],
	[ 6, "DBD::DBM" ],
	[ 7, "DBD::ODBC" ],
	[ 8, "DBD::SQLite" ],
    );

    my @sqls = (
    	"DROP TABLE IF EXISTS test_tbl", -1,
	"CREATE $temp TABLE test_tbl (dKey INT, dVal VARCHAR(23))", '0E0',
	( $i_sql, 1,
	  $s_sql, 1, ) x scalar(@rows),
	"DROP TABLE test_tbl", -1,
    );

    my %prepared;
    foreach my $sql ($i_sql, $s_sql)
    {
	my $sth = $dbh->prepare($sql);
	ok($sth, "prepare <$sql> using '$test_dbd'") or diag($dbh->errstr || 'unknown error');

	# evil hack to avoid full dbi emulating in TestLib
	my %store;
	defined $dbh->{stmt} and $store{stmt} = $dbh->{stmt};
	defined $dbh->{sth} and $store{sth} = $dbh->{sth};

	$prepared{$sql} = \%store;
    }

    my $row_idx = 0;

    SKIP:
    for my $idx ( 0 .. $#sqls ) {
	$idx % 2 and next;
	my $sql = $sqls[$idx];
	my $result = $sqls[$idx+1];
	my ($sth, @bind);

        if( defined $prepared{$sql} )
	{
	    $sth = $dbh; # evil hack in TestLib - $sth == $dbh (wrapper classes!)
	    # evil hack to avoid full dbi emulating in TestLib
	    defined $prepared{$sql}{stmt} and $dbh->{stmt} = $prepared{$sql}{stmt};
	    defined $prepared{$sql}{sth} and $dbh->{sth} = $prepared{$sql}{sth};

	    $sth->command() eq "SELECT" and $result = [$rows[$row_idx++]] and @bind = ($result->[0][0]);
	    $sth->command() eq "INSERT" and $result = 1 and @bind = @{$rows[$row_idx]};

	    $sql .= " [" . join(", ", @bind) . "]";
	}
	else
	{
	    $sql =~ s/;$//;
	    $sql =~ s/\s*;\s*(?:#(.*))//;
	    my $comment = $1;
	    $comment and @bind = split /,/, $comment;

	    $sth = $dbh->prepare($sql);
	    ok($sth, "prepare <$sql> using '$test_dbd'") or diag($dbh->errstr || 'unknown error');
	}

        # if execute errors we will handle it, not PrintError:
        my $n = $sth->execute(@bind);
        ok($n, "execute <$sql> using '$test_dbd'") or diag($sth->errstr || 'unknown error');
        next if (!defined($n));

	is( $n, $result, "execute($sql) == $result using '$test_dbd'") unless( 'ARRAY' eq ref $result );
        next unless $sql =~ /SELECT/;
	my $allrows = $sth->fetch_rows();
	my $expected_rows = $result;
	is( $sth->rows, scalar( @{$expected_rows} ), "execute <$sql> == " . scalar( @{$expected_rows} ) . " using '$test_dbd'" );
	is_deeply( $allrows, $expected_rows, "SELECT results for $sql using $test_dbd" );

	# run SELECT 2nd time to test bug from RT#81523
	$sth->finish();
        $n = $sth->execute(@bind);
        ok($n, "execute <$sql> using '$test_dbd' 2nd time") or diag($sth->errstr || 'unknown error');

	is( $n, $result, "execute($sql) == $result using '$test_dbd'") unless( 'ARRAY' eq ref $result );
	$allrows = $sth->fetch_rows();
	$expected_rows = $result;
	is( $sth->rows, scalar( @{$expected_rows} ), "execute <$sql> == " . scalar( @{$expected_rows} ) . " using '$test_dbd'" );
	is_deeply( $allrows, $expected_rows, "SELECT results for $sql using '$test_dbd' 2nd time" );
    }
}

done_testing();
