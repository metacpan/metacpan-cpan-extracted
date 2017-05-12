# Tests of SQL::Interpolate
#
# Note: Perl does not define an ordering on hash keys, so these tests
# take care not to assume a particular order (e.g. see $h_keys and $h_values)

use strict;
use Test::More 'no_plan';
use Data::Dumper;
use SQL::Interpolate qw(:all);
use SQL::Interpolate::Macro qw(:all);
BEGIN {require 't/lib.pl';}

# test of use parameters
BEGIN {
    use_ok('SQL::Interpolate',
        ':all', TRACE_SQL => 0, TRACE_FILTER => 0, FILTER => 0); # 0.3
}

my $interp = new SQL::Interpolate;
my $sql_interp = $interp->make_sql_interp();
my $sql_interp2 = make_sql_interp();

my $x = 5;
my $y = 6;
my $v0 = [];
my $v = ['one', 'two'];
my $v2 = ['one', sql('two')];
my $h0 = {};

my $h = {one => 1, two => 2};
my $h_keys   = [keys %$h];
my $h_values = [values %$h];

my $var1 = sql_var(\$x);
my $var2 = sql_var(\$x, type => 1);

my $h2 = {one => 1, two => $var2, three => sql('3')};
my $h2_keys   = [keys %$h2];
my $h2_values = [values %$h2];
my $h2_places = [map {$_ eq 'three' ? '3' : '?'} @$h2_keys];
my $h2_values2 = [map {
    $_ eq 'one' ? [1, sql_var(\1)] :
    $_ eq 'two' ? [${$var2->{value}}, $var2] : die
} grep {$_ ne 'three'} @$h2_keys];

#== trivial cases
interp_test([],
            [''],
            'empty');
interp_test(['SELECT * FROM mytable'],
            ['SELECT * FROM mytable'],
            'string');
interp_test([\$x],
            [' ?', $x],
            'scalarref');
interp_test([sql()],
            [''],
            'sql()');

# improve: call with with macros disabled
interp_test([SQL::Interpolate::SQL->new(\$x)],
            [' ?', $x],
            'SQL::Interpolate::SQL->new(scalarref)');

interp_test([sql('test')],
            ['test'],
            'sql(string))');
interp_test([sql(sql(\$x))],
            [' ?', $x],
            'sql(sql(scalarref))');
interp_test([sql(sql(),sql())],
            [''],
            'sql(sql(),sql())');

#== INSERT
interp_test(['INSERT INTO mytable', \$x],
            ['INSERT INTO mytable VALUES(?)', $x],
            'INSERT scalarref');
interp_test(['INSERT INTO mytable', sql($x)],
            ["INSERT INTO mytable $x"], # invalid
            'INSERT sql(...)');
# OK in mysql
interp_test(['INSERT INTO mytable', $v0],
            ['INSERT INTO mytable VALUES()'],
            'INSERT arrayref of size = 0');
interp_test(['INSERT INTO mytable', $v],
            ['INSERT INTO mytable VALUES(?, ?)', @$v],
            'INSERT arrayref of size > 0');
interp_test(['INSERT INTO mytable', $v2],
            ['INSERT INTO mytable VALUES(?, two)', 'one'],
            'INSERT arrayref of size > 0 with sql()');
interp_test(['INSERT INTO mytable', [1, sql(\$x, '*', \$x)]],
            ['INSERT INTO mytable VALUES(?,  ? * ?)', 1, $x, $x],
            'INSERT arrayref of size > 0 with macro');
# OK in mysql
interp_test(['INSERT INTO mytable', $h0],
            ['INSERT INTO mytable () VALUES()'],
            'INSERT hashref of size = 0');
interp_test(['INSERT INTO mytable', $h],
            ["INSERT INTO mytable ($h_keys->[0], $h_keys->[1]) VALUES(?, ?)", @$h_values],
            'INSERT hashref of size > 0');
interp_test(['INSERT INTO mytable', $h2],
            ["INSERT INTO mytable ($h2_keys->[0], $h2_keys->[1], $h2_keys->[2]) " .
             "VALUES($h2_places->[0], $h2_places->[1],  $h2_places->[2])",
             @$h2_values2],
            'INSERT hashref of sql_var + sql()');
interp_test(['INSERT INTO mytable', {one => 1, two => sql(\$x, '*', \$x)}],
            ['INSERT INTO mytable (one, two) VALUES(?,  ? * ?)', 1, $x, $x],
            'INSERT hashref with macro');
# mysql
interp_test(['INSERT HIGH_PRIORITY IGNORE INTO mytable', $v],
            ['INSERT HIGH_PRIORITY IGNORE INTO mytable VALUES(?, ?)', @$v],
            'INSERT [mod] arrayref of size > 0');

# IN
# note: 'WHERE field in ()' NOT OK in mysql.
interp_test(['WHERE field IN', \$x],
            ['WHERE field IN (?)', $x],
            'IN scalarref');
interp_test(['WHERE field IN', sql($x)],
            ["WHERE field IN $x"], # invalid
            'IN sql()');
interp_test(['WHERE field IN', $v0],
            ['WHERE 1=0'],
            'IN arrayref of size = 0');
interp_test(['WHERE field IN', $v],
            ['WHERE field IN (?, ?)', @$v],
            'IN arrayref of size > 0');
interp_test(['WHERE field IN', $v2],
            ['WHERE field IN (?, two)', 'one'],
            'IN arrayref with sql()');
interp_test(['WHERE field IN', [1, sql(\$x, '*', \$x)]],
            ['WHERE field IN (?,  ? * ?)', 1, $x, $x],
            'IN arrayref with macro');
interp_test(['WHERE', {field => $v}],
            ['WHERE field IN (?, ?)', 'one', 'two'],
            'hashref with arrayref');
interp_test(['WHERE', {field => $v0}],
            ['WHERE 1=0'],
            'hashref with arrayref of size = 0');
interp_test(['WHERE', {field => [1, sql(\$x, '*', \$x)]}],
            ['WHERE field IN (?,  ? * ?)', 1, $x, $x],
            'hashref with arrayref with macro');
interp_test(['WHERE field in', $v0],
            ['WHERE 1=0'],
            'IN lowercase');  # fails in 0.31

# SET
interp_test(['UPDATE mytable SET', $h],
            ["UPDATE mytable SET $h_keys->[0]=?, $h_keys->[1]=?", @$h_values],
            'SET hashref');
interp_test(['UPDATE mytable SET',
                {one => 1, two => $var2, three => sql('3')}],
            ['UPDATE mytable SET three=3, one=?, two= ?',
                [1, sql_var(\1)], [${$var2->{value}}, $var2]],
            'SET hashref of sql_var types, sql()');
#FIX--what if size of hash is zero? error?

# WHERE hashref
interp_test(['WHERE', $h0],
            ['WHERE 1=1'],
            'WHERE hashref of size = 0');
interp_test(['WHERE', $h],
            ["WHERE ($h_keys->[0]=? AND $h_keys->[1]=?)", @$h_values],
            'WHERE hashref of size > 0');
interp_test(['WHERE', {x => 1, y=>sql('2')}],
            ['WHERE (y=2 AND x=?)', 1],
            'WHERE hashref sql()');
interp_test(['WHERE', \$x],
            ['WHERE ?', $x],
            'WHERE scalarref');

# WHERE x=
interp_test(['WHERE x=', \$x],
            ['WHERE x= ?', $x],
            'WHERE x=scalarref');

# sql_var
interp_test(['WHERE x=', \$x, 'AND', 'y=', sql_var(\$y)],
            ['WHERE x= ? AND y= ?', $x, $y],
            'WHERE \$x, sql_var');
interp_test(['WHERE x=', \$x, 'AND', 'y=', $var2],
            ['WHERE x= ? AND y= ?', [$x, sql_var(\$x)], [${$var2->{value}}, $var2]],
            'WHERE \$x, sql_var typed');
interp_test(['WHERE', {x => $x, y => $var2}, 'AND z=', \$x],
            ['WHERE (y= ? AND x=?) AND z= ?',
                [${$var2->{value}}, $var2], [$x, sql_var(\$x)], [$x, sql_var(\$x)]],
            'WHERE hashref of \$x, sql_var typed');
my $h5 = {x => $x, y => [3, $var2]};
my $h5_keys = [keys %$h5];
my $h5_places = [map {$_ eq 'x' ? 'x=?' : 'y IN (?,  ?)'} @$h5_keys];
my $h5_values = [map {$_ eq 'x' ? [$x, sql_var(\$x)] : ([3, sql_var(\3)], [${$var2->{value}}, $var2])} @$h5_keys];
interp_test(['WHERE', $h5],
            ["WHERE ($h5_places->[0] AND $h5_places->[1])", @$h5_values],
            'WHERE hashref of arrayref of sql_var typed');
interp_test(['WHERE', {x => $x, y => sql('z')}],
            ['WHERE (y=z AND x=?)', $x],
            'WHERE hashref of \$x, sql()');

# error handling
error_test(['SELECT', []], qr/unrecognized.*array.*select/i, 'err1');
error_test(['IN', {}], qr/unrecognized.*hash.*in/i, 'err2');

sub interp_test
{
    my($snips, $expect, $name) = @_;
#    print Dumper([sql_interp @$snips], $expect);

    # custom filter
    my $func = sub { return [@_]; };
    my $test = \&my_deeply;
    if(ref($expect) eq 'ARRAY' && @$expect > 0 && ref($expect->[0]) eq 'CODE') {
        $func = shift @$expect;
        $expect = $expect->[0];
        $test = \&like;
    }

    $test->($func->(sql_interp @$snips), $expect, $name);
    $test->($func->($interp->sql_interp(@$snips)), $expect, "$name OO");
    $test->($func->($sql_interp->(@$snips)), $expect, "$name closure");
    $test->($func->($sql_interp2->(@$snips)), $expect, "$name closure2");
}

sub error_test
{
    my($list, $re, $name) = @_;
    eval {
        sql_interp @$list;
    };
    like($@, $re, $name);
}
