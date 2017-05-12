# Tests of DBIx::Interpolate

use strict;
use Test::More 'no_plan';
use Data::Dumper;
use DBIx::Interpolate qw(:all);

my $fake_dbh = bless {Driver => {Name => 'mysql'}}, 'DBI::db';


my $dbx = new DBIx::Interpolate($fake_dbh);
my $dbx2 = new DBIx::Interpolate();
my $dbi_interp = $dbx->make_dbi_interp();
my $dbi_interp2 = make_dbi_interp();
my $sql_interp = $dbx->make_sql_interp();
my $sql_interp2 = make_sql_interp();

my $x = 5;

# dbh()
is(ref($dbx->dbh()), 'DBI::db', 'dbh');

# connect()
# no tests currently

# sql_interp()
&sql_interp_test(['SELECT * FROM mytable WHERE', {x => $x}],
                 ['SELECT * FROM mytable WHERE x=?', $x],
                 'sql_interp');


# dbi_interp() with attr() and key_field()
&interp_test(['SELECT * FROM mytable', attr(x => 1)],
             ['SELECT * FROM mytable', {x => 1}],
             'attr');
&interp_test(['SELECT * FROM mytable', key_field('id1')],
             ['SELECT * FROM mytable', 'id1', undef],
             'key_field');
&interp_test(['SELECT * FROM mytable WHERE x=', \$x,
                 key_field('id1'), attr(x => 1)],
             ['SELECT * FROM mytable WHERE x= ?', 'id1', {x=>1}, $x],
             'key_field + attr + bind');

#IMPROVE: add tests on $dbx
# do, selectall... prepare...

sub interp_test
{
    my($snips, $expect, $name) = @_;
    is_deeply([dbi_interp @$snips], $expect, $name);
    is_deeply([$dbx->dbi_interp(@$snips)], $expect, "$name OO");
    is_deeply([$dbi_interp->(@$snips)], $expect, "$name closure");
    is_deeply([$dbi_interp2->(@$snips)], $expect, "$name closure2");
}

sub sql_interp_test
{
    my($snips, $expect, $name) = @_;
    is_deeply([sql_interp @$snips], $expect, $name);
    is_deeply([$dbx->sql_interp(@$snips)], $expect, "$name OO");
    is_deeply([$sql_interp->(@$snips)], $expect, "$name closure");
    is_deeply([$sql_interp2->(@$snips)], $expect, "$name closure2");
}

END {
    # prevent DBI from destroying fake handle.
    bless $fake_dbh, 'SQL::Interpolate::UNBLESS';
}
