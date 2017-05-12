# Tests of DBIx::Interp

use strict;
use lib 't/lib';
use DBD::Mock;
use Test::More 'no_plan';
use Data::Dumper;
use DBIx::Interp qw(:all);
use DBI qw(:sql_types);

my $dbh = DBI->connect('DBI:Mock:', '', '')
    or die "Cannot create handle: $DBI::errstr\n";
my $dbx = DBIx::Interp->new($dbh);

my @data1   = (['a', 'b'], ['c', 'd']);
my @result1 = (['color', 'size'], @data1);

my $x = 5;
my $y = 6;

# test of use parameter inheritance
BEGIN {
    use_ok('DBIx::Interp',
        'dbi_interp', 'sql_interp' ); # 0.3
}

# selectall_arrayref
$dbh->{mock_add_resultset} = \@result1;
is_deeply(
    $dbx->selectall_arrayref_i("SELECT * FROM mytable WHERE x IN", [1,2]),
    \@data1,
    'selectall_arrayref'
);
is($dbh->{mock_all_history}->[0]{statement},
   'SELECT * FROM mytable WHERE x IN (?, ?)');
is_deeply($dbh->{mock_all_history}->[0]{bound_params}, [1, 2]);

# prepare
my $stx = $dbx->prepare_i();
is(ref($stx), 'DBIx::Interp::STX');

# max_sths
$stx->max_sths(2);
is($stx->max_sths(), 2);

# execute
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = \@result1;
$stx->execute_i('SELECT * FROM mytable WHERE y IN', [2,3]);
is_deeply(
    $stx->fetchall_arrayref(),
    \@data1,
    'fetchall_arrayref'
);
is($dbh->{mock_all_history}->[0]{statement},
   'SELECT * FROM mytable WHERE y IN (?, ?)');
is_deeply($dbh->{mock_all_history}->[0]{bound_params}, [2, 3]);

# execute (same SQL)
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = \@result1;
$stx->execute_i('SELECT * FROM mytable WHERE y IN', [4,5]);
is_deeply(
    $stx->fetchall_arrayref(),
    \@data1,
    'fetchall_arrayref'
);
is($stx->sth()->{mock_statement},
   'SELECT * FROM mytable WHERE y IN (?, ?)');
is_deeply($stx->sth()->{mock_params}, [4, 5]);

# execute (new SQL)
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = \@result1;
$stx->execute_i('SELECT * FROM mytable WHERE y IN', [4,5,6]);
is_deeply(
    $stx->fetchall_arrayref(),
    \@data1,
    'fetchall_arrayref'
);
is($stx->sth()->{mock_statement},
   'SELECT * FROM mytable WHERE y IN (?, ?, ?)');
is_deeply($stx->sth()->{mock_params}, [4, 5, 6]);

is(scalar(keys %{$stx->sths()}), 2, 'two sths in stx');

# execute (new SQL)
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = \@result1;
$stx->execute_i('SELECT * FROM mytable WHERE y IN', [4,5,6,7]);
is_deeply(
    $stx->fetchall_arrayref(),
    \@data1,
    'fetchall_arrayref'
);
is($stx->sth()->{mock_statement},
   'SELECT * FROM mytable WHERE y IN (?, ?, ?, ?)');
is_deeply($stx->sth()->{mock_params}, [4, 5, 6, 7]);

is(scalar(keys %{$stx->sths()}), 2, 'two sths in stx still');

my $h2 = {a => 1, b => 2};
my $h2_keys = [sort keys %$h2];
my $h2_values = [map {$h2->{$_}} sort keys %$h2];

# bind_param
$dbh->{mock_clear_history} = 1;
$dbh->{mock_add_resultset} = \@result1;
$dbx->selectall_arrayref_i("SELECT * FROM mytable WHERE x=", \$x,
    "AND y=", sql_type(\$y, type => SQL_INTEGER),
    "AND", sql_type($h2, type => SQL_DATETIME),
    "AND x IN", sql_type([4, 5], type => SQL_VARCHAR)
);
is_deeply(
    $dbh->{mock_all_history}->[0]{statement},
    "SELECT * FROM mytable WHERE x= ? AND y= ? AND "."($h2_keys->[0]=? AND $h2_keys->[1]=?) AND x IN (?, ?)"
);
# note: DBD::Mock doesn't save bind param type to test?


