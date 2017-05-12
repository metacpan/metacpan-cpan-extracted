# Tests of SQL::Interp

use strict;
use warnings;
use Test::More 'no_plan';
use SQL::Interp ':all';
use Data::Dumper;
BEGIN {require 't/lib.pl';}

# test of use parameters
BEGIN {
    use_ok('SQL::Interp',
        ':all' ); # 0.3
}

my $interp = SQL::Interp->new;

my $x = 5;
my $y = 6;
my $v0 = [];
my $v = ['one', 'two'];
my $v2 = ['one', sql('two')];
my $h0 = {};

my $h = {one => 1, two => 2};
my $hi = make_hash_info($h);

my $var1 = sql_type(\$x);
my $var2 = sql_type(\$x, type => 1);

my $h2i = make_hash_info(
    { one => 1, two => $var2, three => sql('3') },
    { one => '?', two => '?', three => '3' },
    { one => [[1, sql_type(\1)]], two => [[${$var2->{value}}, $var2]] }
);

# Returns structure containing info on the hash.
# This info is useful in the sql_interp tests.
# Note: Perl does not define an ordering on hash keys, so these tests
# take care not to assume a particular order.
sub make_hash_info {
    my ($hashref, $place_of, $bind_of) = @_;
    my $info = {
        hashref => $hashref,
        keys    => [ sort keys %$hashref ],
        values  => [ map { $hashref->{$_} } sort keys %$hashref ],
        places  => [ @$place_of{sort keys %$hashref} ],
        binds   => [ map {defined $_ ? @$_ : ()}
                         @$bind_of{ grep { exists $bind_of->{$_} } sort keys %$hashref} ]
    };
    return $info;
}

# returns the values in the given hash ordered by the given keys.
# Helper function for the sql_interp tests. 
sub order_keyed_values {
    my ($ordered_keys, %value_for) = @_;
    my @values = @value_for{@$ordered_keys};
    return @values;
}

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
interp_test([SQL::Interp::SQL->new(\$x)],
            [' ?', $x],
            'SQL::Interp::SQL->new(scalarref)');

# improve: call with with macros disabled

# test with sql()
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
interp_test(['REPLACE INTO mytable', \$x],
            ['REPLACE INTO mytable VALUES(?)', $x],
            'REPLACE INTO');
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
            ["INSERT INTO mytable ($hi->{keys}[0], $hi->{keys}[1]) VALUES(?, ?)",
                 @{$hi->{values}}],
            'INSERT hashref of size > 0');
interp_test(['INSERT INTO mytable', $h2i->{hashref}],
            ["INSERT INTO mytable ($h2i->{keys}[0], $h2i->{keys}[1], $h2i->{keys}[2]) " .
             "VALUES($h2i->{places}->[0], $h2i->{places}->[1],  $h2i->{places}->[2])",
             @{$h2i->{binds}}],
            'INSERT hashref of sql_type + sql()');
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

my $maybe_array = [1,2];
interp_test(['WHERE field IN', \$maybe_array],
            ['WHERE field IN (?, ?)', @$maybe_array],
            'IN maybe_array turns out to be an array');

interp_test(['WHERE field IN', sql($x)],
            ["WHERE field IN $x"], # invalid
            'IN sql()');
interp_test(['WHERE field IN', $v0],
            ['WHERE 1=0'],
            'IN arrayref of size = 0');

interp_test(['WHERE field NOT IN', $v0],
            ['WHERE 1=1'],
            'NOT IN arrayref of size = 0');


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
            ["UPDATE mytable SET $hi->{keys}[0]=?, $hi->{keys}[1]=?", @{$hi->{values}}],
            'SET hashref');
interp_test(['UPDATE mytable SET',
                {one => 1, two => $var2, three => sql('3')}],
            ['UPDATE mytable SET one=?, three=3, two= ?',
                [1, sql_type(\1)], [${$var2->{value}}, $var2]],
            'SET hashref of sql_type types, sql()');
#FIX--what if size of hash is zero? error?

# WHERE hashref
interp_test(['WHERE', $h0],
            ['WHERE 1=1'],
            'WHERE hashref of size = 0');
interp_test(['WHERE', $h],
            ["WHERE ($hi->{keys}[0]=? AND $hi->{keys}[1]=?)", @{$hi->{values}}],
            'WHERE hashref of size > 0');
my $h2bi = make_hash_info(
    {x => 1, y => sql('2')},
    {x => 'x=?', y => 'y=2'},
    {x => [1]}
);
interp_test(['WHERE', $h2bi->{hashref}],
            ["WHERE ($h2bi->{places}[0] AND $h2bi->{places}[1])", @{$h2bi->{binds}}],
            'WHERE hashref sql()');
my $h2ci = make_hash_info(
    {x => 1, y => undef},
    {x => 'x=?', y => 'y IS NULL'},
    {x => [1]}
);
interp_test(['WHERE', $h2ci->{hashref}],
            ["WHERE ($h2ci->{places}[0] AND $h2ci->{places}[1])", @{$h2ci->{binds}}],
            'WHERE hashref of NULL');

# WHERE x=
interp_test(['WHERE x=', \$x],
            ['WHERE x= ?', $x],
            'WHERE x=scalarref');

# sql_type
interp_test(['WHERE x=', \$x, 'AND', 'y=', sql_type(\$y)],
            ['WHERE x= ? AND y= ?', $x, $y],
            'WHERE \$x, sql_type');
interp_test(['WHERE x=', \$x, 'AND', 'y=', $var2],
            ['WHERE x= ? AND y= ?', [$x, sql_type(\$x)], [${$var2->{value}}, $var2]],
            'WHERE \$x, sql_type typed');
interp_test(['WHERE', {x => $x, y => $var2}, 'AND z=', \$x],
            ['WHERE (x=? AND y= ?) AND z= ?',
                [$x, sql_type(\$x)], [${$var2->{value}}, $var2], [$x, sql_type(\$x)]],
            'WHERE hashref of \$x, sql_type typed');
my $h5i = make_hash_info(
    {x => $x, y => [3, $var2]},
    {x => 'x=?', y => 'y IN (?,  ?)'},
    {x => [[$x, sql_type(\$x)]], y => [[3, sql_type(\3)], [${$var2->{value}}, $var2]]}
);
interp_test(['WHERE', $h5i->{hashref}],
            ["WHERE ($h5i->{places}[0] AND $h5i->{places}[1])", @{$h5i->{binds}}[0,1,2]],
            'WHERE hashref of arrayref of sql_type typed');
interp_test(['WHERE', {x => $x, y => sql('z')}],
            ['WHERE (x=? AND y=z)', $x],
            'WHERE hashref of \$x, sql()');

# table references
error_test(['FROM', []], qr/table reference has zero rows/, 'v 0');
error_test(['FROM', [[]]], qr/table reference has zero columns/, 'vv 1 0');
error_test(['',     [[]]], qr/table reference has zero columns/, 'vv 1 0 (resultset)');
error_test(['FROM', [{}]], qr/table reference has zero columns/, 'vh 1 0');
error_test(['',     [{}]], qr/table reference has zero columns/, 'vh 1 0 (resultset)');
interp_test(['FROM', [[1]]], ['FROM (SELECT ?) AS tbl0', 1], 'vv 1 1');
interp_test(['',     [[1]]], ['(SELECT ?)', 1], 'vv 1 1 (resultset)');
interp_test(['FROM', [{a => 1}]], ['FROM (SELECT ? AS a) AS tbl0', 1], 'vh 1 1');
interp_test(['',     [{a => 1}]], ['(SELECT ? AS a)', 1], 'vh 1 1 (resultset)');
interp_test(['FROM', [[1,2]]], ['FROM (SELECT ?, ?) AS tbl0', 1, 2], 'vv 1 2');
interp_test(['FROM', [$h]], ["FROM (SELECT ? AS $hi->{keys}[0], ? AS $hi->{keys}[1]) AS tbl0",
    @{$hi->{values}}], 'vh 1 2');
interp_test(['',     [$h]], ["(SELECT ? AS $hi->{keys}[0], ? AS $hi->{keys}[1])",
    @{$hi->{values}}], 'vh 1 2 (resultset)');
interp_test(['FROM', [[1,2],[3,4]]],
    ['FROM (SELECT ?, ? UNION ALL SELECT ?, ?) AS tbl0', 1, 2, 3, 4], 'vv 2 2');
interp_test(['', [[1,2],[3,4]]],
    ['(SELECT ?, ? UNION ALL SELECT ?, ?)', 1, 2, 3, 4], 'vv 2 2 (resultset)');
interp_test(['FROM', [$h,$h]],
    ["FROM (SELECT ? AS $hi->{keys}[0], ? AS $hi->{keys}[1] UNION ALL SELECT ?, ?) AS tbl0",
    @{$hi->{values}}, @{$hi->{values}}], 'vh 2 2');
interp_test(['', [$h,$h]],
    ["(SELECT ? AS $hi->{keys}[0], ? AS $hi->{keys}[1] UNION ALL SELECT ?, ?)",
    @{$hi->{values}}, @{$hi->{values}}], 'vh 2 2 (resultset)');
interp_test(['FROM', [[1]], 'JOIN', [[2]]],
    ['FROM (SELECT ?) AS tbl0 JOIN (SELECT ?) AS tbl1', 1, 2], 'vv 1 1 join vv 1 1');
interp_test(['FROM', [[sql(1)]]], ['FROM (SELECT 1) AS tbl0'], 'vv 1 1 of sql(1)');
interp_test(['', [[sql(1)]]], ['(SELECT 1)'], 'vv 1 1 of sql(1) (resultset)');
interp_test(['FROM', [{a => sql(1)}]], ['FROM (SELECT 1 AS a) AS tbl0'], 'vh 1 1 of sql(1)');
interp_test(['FROM', [[sql(\1)]]], ['FROM (SELECT  ?) AS tbl0', 1], 'vv 1 1 of sql(\1)');
interp_test(['FROM', [[sql('1=', \1)]]],
    ['FROM (SELECT 1= ?) AS tbl0', 1], 'vv 1 1 of sql(s,\1)');
interp_test(['FROM', [[1]], ' AS mytable'],
    ['FROM (SELECT ?) AS mytable', 1], 'vv 1 1 with alias');
interp_test(['FROM', [[undef]]],
    ['FROM (SELECT ?) AS tbl0', undef], 'vv 1 1 of undef');
interp_test(['FROM', [{a => undef}]],
    ['FROM (SELECT ? AS a) AS tbl0', undef], 'vh 1 1 of undef');

# error handling
#OLD: error_test(['SELECT', []], qr/unrecognized.*array.*select/i, 'err1');
#OLD: error_test(['IN', {}], qr/unrecognized.*hash.*in/i, 'err2');

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
}

sub error_test
{
    my($list, $re, $name) = @_;
    eval {
        sql_interp @$list;
    };
    like($@, $re, $name);
}
