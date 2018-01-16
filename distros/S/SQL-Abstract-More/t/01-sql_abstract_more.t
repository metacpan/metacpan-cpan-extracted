use strict;
use warnings;
no warnings 'qw';

use SQL::Abstract::More;

use Test::More;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

use constant N_DBI_MOCK_TESTS =>  2;
use constant N_BASIC_TESTS    => 68;
plan tests => (N_BASIC_TESTS + N_DBI_MOCK_TESTS);

diag( "Testing SQL::Abstract::More $SQL::Abstract::More::VERSION, Perl $], $^X" );


my $sqla = SQL::Abstract::More->new;
my ($sql, @bind, $join);


#----------------------------------------------------------------------
# various forms of select()
#----------------------------------------------------------------------

# old API transmitted to parent
($sql, @bind) = $sqla->select('Foo', 'bar', {bar => {">" => 123}}, ['bar']);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT bar FROM Foo WHERE bar > ? ORDER BY bar", [123],
);

# idem, new API
($sql, @bind) = $sqla->select(
  -columns  => [qw/bar/],
  -from     => 'Foo',
  -where    => {bar => {">" => 123}}, 
  -order_by => ['bar']
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT bar FROM Foo WHERE bar > ? ORDER BY bar", [123],
);

# -distinct
($sql, @bind) = $sqla->select(
  -columns  => [-DISTINCT => qw/foo bar/],
  -from     => 'Foo',
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT DISTINCT foo, bar FROM Foo", [],
);

# other minus signs
($sql, @bind) = $sqla->select(
  -columns  => [-DISTINCT => -STRAIGHT_JOIN => qw/foo bar/],
  -from     => 'Foo',
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT DISTINCT STRAIGHT_JOIN foo, bar FROM Foo", [],
);

($sql, @bind) = $sqla->select(
  -columns  => [-SQL_SMALL_RESULT => qw/foo bar/],
  -from     => 'Foo',
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT SQL_SMALL_RESULT foo, bar FROM Foo", [],
);

($sql, @bind) = $sqla->select(
  -columns  => ["-/*+ FIRST_ROWS (100) */" => qw/foo bar/],
  -from     => 'Foo',
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT /*+ FIRST_ROWS (100) */ foo, bar FROM Foo", [],
);


# -join
($sql, @bind) = $sqla->select(
  -from => [-join => qw/Foo fk=pk Bar/]
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM Foo INNER JOIN Bar ON Foo.fk=Bar.pk", [],
);

# set operators
($sql, @bind) = $sqla->select(
  -columns => [qw/col1 col2/],
  -from    => 'Foo',
  -where   => {col1 => 123},
  -intersect => [ -columns => [qw/col3 col4/],
                  -from    => 'Bar',
                  -where   => {col3 => 456},
                 ],
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT col1, col2 FROM Foo WHERE col1 = ? "
  ." INTERSECT SELECT col3, col4 FROM Bar WHERE col3 = ?",
  [123, 456],
);

($sql, @bind) = $sqla->select(
  -columns => [qw/col1 col2/],
  -from    => 'Foo',
  -where   => {col1 => 123},
  -union_all => [ -where => {col2 => 456},
                  -union_all => [-columns => [qw/col1 col3/],
                                 -where   => {col3 => 789}, ],
                 ],
  -order_by => [qw/col1 col2/],
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT col1, col2 FROM Foo WHERE col1 = ? "
  ." UNION ALL SELECT col1, col2 FROM Foo WHERE col2 = ?"
  ." UNION ALL SELECT col1, col3 FROM Foo WHERE col3 = ?"
  ." ORDER BY col1, col2",
  [123, 456, 789],
);



#-order_by
($sql, @bind) = $sqla->select(
  -from     => 'Foo',
  -order_by => [qw/-foo +bar buz/],
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM Foo ORDER BY foo DESC, bar ASC, buz", [],
);

#-group_by / -having
($sql, @bind) = $sqla->select(
  -columns  => [qw/foo SUM(bar)|sum_bar/],
  -from     => 'Foo',
  -group_by => [qw/foo/],
  -having   => {sum_bar => {">" => 10}},
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT foo, SUM(bar) AS sum_bar FROM Foo GROUP BY foo HAVING sum_bar > ?", [10],
);
# NOTE : this test used to be -group_by => [qw/-foo/], generating "GROUP BY foo DESC";
# but this made no sense as SQL.


#-limit alone
($sql, @bind) = $sqla->select(
  -from     => 'Foo',
  -limit    => 100
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM Foo LIMIT ? OFFSET ?", [100, 0],
);


($sql, @bind) = $sqla->select(
  -from     => 'Foo',
  -limit    => 0,
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM Foo LIMIT ? OFFSET ?", [0, 0],
  "limit 0",
);



#-limit / -offset
($sql, @bind) = $sqla->select(
  -from     => 'Foo',
  -limit    => 100,
  -offset   => 300,
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM Foo LIMIT ? OFFSET ?", [100, 300],
);


#-page_size / page_index
($sql, @bind) = $sqla->select(
  -from       => 'Foo',
  -page_size  => 50,
  -page_index => 2,
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM Foo LIMIT ? OFFSET ?", [50, 50],
);


# -for
($sql, @bind) = $sqla->select(
  -from   => 'Foo',
  -for    => "UPDATE",
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM Foo FOR UPDATE", [],
);

# -want_details
my $details = $sqla->select(
  -columns      => [         qw/f.col1|c1           b.col2|c2 /],
  -from         => [-join => qw/Foo|f       fk=pk   Bar|b     /],
  -want_details => 1,
);
is_same_sql_bind(
  $details->{sql}, $details->{bind},
  "SELECT f.col1 AS c1, b.col2 AS c2 FROM Foo AS f INNER JOIN Bar AS b ON f.fk=b.pk", [],
);
is_deeply($details->{aliased_tables}, {f => 'Foo', b => 'Bar'}, 
          "aliased tables");
is_deeply($details->{aliased_columns}, {c1 => 'f.col1', c2 => 'b.col2'},
          "aliased columns");


# aliasing, do not conflict with "||" operator
($sql, @bind) = $sqla->select(
  -columns  => [qw/A||B C||D|cd (E||F||G)|efg true|false|bool/],
  -from     => 'Foo',
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT A||B, C||D AS cd, (E||F||G) AS efg, true|false AS bool FROM Foo", [],
  "aliased cols with '|'"
);

($sql, @bind) = $sqla->select(
  -columns  => [qw/NULL|a1 2|a2 x|a3/],
  -from     => 'Foo',
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT NULL AS a1, 2 AS a2, x AS a3 FROM Foo", [],
  "aliased cols with '|', single char on left-hand side"
);



# bind_params with SQL types
($sql, @bind) = $sqla->select(
  -from   => 'Foo',
  -where  => {foo => [{dbd_attrs => {ora_type => 'TEST'}}, 123]},
 );
is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM Foo WHERE foo = ?",
  [ [{dbd_attrs => {ora_type => 'TEST'}}, 123] ],
  "SQL type with implicit = operator",
);

($sql, @bind) = $sqla->select(
  -from   => 'Foo',
  -where  => {bar => {"<" => [{dbd_attrs => {pg_type  => 999}}, 456]}},
 );
is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM Foo WHERE bar < ?",
  [ [{dbd_attrs => {pg_type  => 999}}, 456] ],
  "SQL type with explicit operator",
);


# should not be interpreted as bind_params with SQL types
($sql, @bind) = $sqla->select(
  -from   => 'Foo',
  -where  => {bar => [{"=" => undef}, {"<" => 'foo'}]}
 );
is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM Foo WHERE bar IS NULL OR bar < ?",
  [ 'foo' ],
  "OR arrayref pair which is not a value/type pair",
);



#----------------------------------------------------------------------
# auxiliary methods : test an instance with standard parameters
#----------------------------------------------------------------------

($sql, @bind) = $sqla->column_alias(qw/Foo f/);
is_same_sql_bind(
  $$sql, \@bind,
  "Foo AS f", [],
  "column alias",
);

($sql, @bind) = $sqla->column_alias(qw/Foo/);
is_same_sql_bind(
  $sql, \@bind,
  "Foo", [],
  "column alias without alias",
);


($sql, @bind) = $sqla->table_alias(qw/Foo f/);
is_same_sql_bind(
  $sql, \@bind,
  "Foo AS f", [],
  "table alias",
);

($sql, @bind) = $sqla->limit_offset(123, 456);
is_same_sql_bind(
  $sql, \@bind,
  "LIMIT ? OFFSET ?", [123, 456],
  "limit offset",
);


$join = $sqla->join(qw[Foo|f =>{fk_A=pk_A,fk_B=pk_B} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo AS f LEFT OUTER JOIN Bar ON f.fk_A = Bar.pk_A AND f.fk_B = Bar.pk_B", [],
  "join syntax",
);

$join = $sqla->join(qw[Foo <=>[A<B,C<D] Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo INNER JOIN Bar ON Foo.A < Bar.B OR Foo.C < Bar.D", [],
  "join syntax with OR",
);


$join = $sqla->join(qw[Foo == Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo NATURAL JOIN Bar", [],
  "natural join",
);


# try most syntactic constructs
$join = $sqla->join(qw[Table1|t1       ab=cd         Table2|t2
                                   <=>{ef>gh,ij<kl}  Table3
                                    =>{t1.mn=op}     Table4]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Table1 AS t1 INNER JOIN      Table2 AS t2 ON t1.ab=t2.cd
                INNER JOIN      Table3       ON t2.ef>Table3.gh 
                                            AND t2.ij<Table3.kl
                LEFT OUTER JOIN Table4       ON t1.mn=Table4.op",
  [],
);


# full outer join
$join = $sqla->join(qw[Foo >=<{a=b} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo FULL OUTER JOIN Bar ON Foo.a=Bar.b", [],
  "full outer join",
);



# explicit tables in join condition
$join = $sqla->join(qw[Table1|t1  t1.ab=t2.cd Table2|t2]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Table1 AS t1 INNER JOIN  Table2 AS t2 ON t1.ab=t2.cd",
  [],
  "explicit tables in join condition"
 );



my $merged = $sqla->merge_conditions(
    {a => 12, b => {">" => 34}}, 
    {b => {"<" => 56}, c => 78},
  );
is_deeply($merged,
          {a => 12, b => [-and => {">" => 34}, {"<" => 56}], c => 78});


#----------------------------------------------------------------------
# test a customized instance
#----------------------------------------------------------------------

$sqla = SQL::Abstract::More->new(table_alias  => '%1$s %2$s',
                                 limit_offset => "LimitXY",
                                 sql_dialect  => "MsAccess");

$join = $sqla->join(qw[Foo|f  =>{fk_A=pk_A,fk_B=pk_B} Bar]);
is_same_sql_bind(
  $join->{sql}, $join->{bind},
  "Foo f LEFT OUTER JOIN (Bar) ON f.fk_A = Bar.pk_A AND f.fk_B = Bar.pk_B", [],
);


($sql, @bind) = $sqla->limit_offset(123, 456);
is_same_sql_bind(
  $sql, \@bind,
  "LIMIT ?, ?", [456, 123]
);


ok($sqla->join_assoc_right,
   "join_assoc_right is true");


$sqla = SQL::Abstract::More->new(sql_dialect => 'Oracle');
($sql, @bind) = $sqla->select(
  -columns => [qw/col1|c1 col2|c2/],
  -from    => [-join => qw/Foo|f fk=pk Bar|b/],
);
is_same_sql_bind(
  $sql, \@bind,
  "SELECT col1 c1, col2 c2 FROM Foo f INNER JOIN Bar b ON f.fk=b.pk",
  []
);

($sql, @bind) = $sqla->select(
  -from    => 'Foo',
  -limit   => 10,
  -offset  => 5,
);

is_same_sql_bind(
  $sql, \@bind,
  "SELECT * FROM (SELECT subq_A.*, ROWNUM rownum__index FROM (SELECT * FROM Foo) subq_A WHERE ROWNUM <= ?) subq_B WHERE rownum__index >= ?",
  [15, 6],
);




#----------------------------------------------------------------------
# method redefinition
#----------------------------------------------------------------------

$sqla = SQL::Abstract::More->new(
    limit_offset => sub {
      my ($self, $limit, $offset) = @_;
      defined $limit or die "NO LIMIT!";
      $offset ||= 0;
      my $last = $offset + $limit;
      return ("ROWS ? TO ?", $offset, $last); # ($sql, @bind)
     });


($sql, @bind) = $sqla->limit_offset(123, 456);
is_same_sql_bind(
  $sql, \@bind,
  "ROWS ? TO ?", [456, 579]
);


#----------------------------------------------------------------------
# max_members_IN
#----------------------------------------------------------------------

$sqla = SQL::Abstract::More->new(
  max_members_IN => 10
 );

my @vals = (1 .. 35);
($sql, @bind) = $sqla->where({foo => {-in => \@vals}});

is_same_sql_bind(
  $sql, \@bind,
  ' WHERE ( ( foo IN ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ) '
       . ' OR foo IN ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ) '
       . ' OR foo IN ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ) '
       . ' OR foo IN ( ?, ?, ?, ?, ?) ) )',
  [1 .. 35]
);


($sql, @bind) = $sqla->where({foo => {-not_in => \@vals}});
is_same_sql_bind(
  $sql, \@bind,
  ' WHERE ( ( foo NOT IN ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ) '
      . ' AND foo NOT IN ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ) '
      . ' AND foo NOT IN ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ? ) '
      . ' AND foo NOT IN ( ?, ?, ?, ?, ?) ) )',
  [1 .. 35]
);

$sqla = SQL::Abstract::More->new(
  max_members_IN => 3
 );

($sql, @bind) = $sqla->where({foo => {-in     => [1 .. 5]},
                              bar => {-not_in => [6 .. 10]}});
is_same_sql_bind(
  $sql, \@bind,
  ' WHERE (     ( bar NOT IN ( ?, ?, ? ) AND bar NOT IN ( ?, ? ) )'
        . ' AND ( foo IN ( ?, ?, ? ) OR foo IN ( ?, ? ) )  )',
  [6 .. 10, 1 .. 5]
);

# test old API : passing a plain scalar value to -in
($sql, @bind) = $sqla->where({foo => {-in => 123}});
is_same_sql_bind(
  $sql, \@bind,
  ' WHERE ( foo IN (?) )',
  [123],
);


#----------------------------------------------------------------------
# -in with objects
#----------------------------------------------------------------------

my $vals = bless [1, 2], 'Array::PseudoScalar'; # doesn't matter if not loaded

($sql, @bind) = $sqla->where({foo => {-in     => $vals},
                              bar => {-not_in => $vals}});

is_same_sql_bind(
  $sql, \@bind,
  ' WHERE ( bar NOT IN ( ?, ? ) AND foo IN ( ?, ? ) )',
  [1, 2, 1, 2],
);


#----------------------------------------------------------------------
# select_implicitly_for
#----------------------------------------------------------------------

$sqla = SQL::Abstract::More->new(
  select_implicitly_for => 'READ ONLY',
 );

($sql, @bind) = $sqla->select(-from => 'Foo');
is_same_sql_bind(
  $sql, \@bind,
  'SELECT * FROM FOO FOR READ ONLY',  [],
  "select_implicitly_for - basic",
);

($sql, @bind) = $sqla->select(-from => 'Foo', -for => 'UPDATE');
is_same_sql_bind(
  $sql, \@bind,
  'SELECT * FROM FOO FOR UPDATE',  [],
  "select_implicitly_for - override",
);

($sql, @bind) = $sqla->select(-from => 'Foo', -for => undef);
is_same_sql_bind(
  $sql, \@bind,
  'SELECT * FROM FOO',  [],
  "select_implicitly_for - disable",
);


#----------------------------------------------------------------------
# insert
#----------------------------------------------------------------------

# usual, hashref syntax
($sql, @bind) = $sqla->insert(
  -into => 'Foo',
  -values => {foo => 1, bar => 2},
);
is_same_sql_bind(
  $sql, \@bind,
  'INSERT INTO Foo(bar, foo) VALUES (?, ?)',
  [2, 1],
);

# arrayref syntax
($sql, @bind) = $sqla->insert(
  -into => 'Foo',
  -values => [1, 2],
);
is_same_sql_bind(
  $sql, \@bind,
  'INSERT INTO Foo VALUES (?, ?)',
  [1, 2],
);

# old API
($sql, @bind) = $sqla->insert('Foo', {foo => 1, bar => 2}); 
is_same_sql_bind(
  $sql, \@bind,
  'INSERT INTO Foo(bar, foo) VALUES (?, ?)',
  [2, 1],
);

($sql, @bind) = eval {$sqla->insert(-foo => 3); };
ok($@, 'unknown arg to insert()');


# returning
($sql, @bind) = $sqla->insert(
  -into       => 'Foo',
  -values     => {foo => 1, bar => 2},
  -returning  => 'key',
);
is_same_sql_bind(
  $sql, \@bind,
  'INSERT INTO Foo(bar, foo) VALUES (?, ?) RETURNING key',
  [2, 1],
);

($sql, @bind) = $sqla->insert(
  -into       => 'Foo',
  -values     => {foo => 1, bar => 2},
  -returning  => [qw/k1 k2/],
);
is_same_sql_bind(
  $sql, \@bind,
  'INSERT INTO Foo(bar, foo) VALUES (?, ?) RETURNING k1, k2',
  [2, 1],
);

($sql, @bind) = $sqla->insert(
  -into       => 'Foo',
  -values     => {foo => 1, bar => 2},
  -returning  => {k1 => \my $k1, k2 => \my $k2},
);
is_same_sql_bind(
  $sql, \@bind,
  'INSERT INTO Foo(bar, foo) VALUES (?, ?) RETURNING k1, k2 INTO ?, ?',
  [2, 1, \$k2, \$k1],
);




# bind_params

SKIP: {
  eval "use DBD::Mock; 1"
    or skip "DBD::Mock does not seem to be installed", N_DBI_MOCK_TESTS;
  {
    # DIRTY HACK: remote surgery into DBD::Mock::st to compensate for the
    # missing support for ternary form of bind_param().
    require DBD::Mock::st;
    no warnings 'redefine';
    my $orig = \&DBD::Mock::st::bind_param;
    *DBD::Mock::st::bind_param = sub {
      my ( $sth, $param_num, $val, $attr ) = @_;
      $val = [$val, $attr] if $attr;
      return $sth->$orig($param_num, $val);
    };
  }

  my $dbh = DBI->connect('DBI:Mock:', '', '', {RaiseError => 1});
  my $sth = $dbh->prepare($sql);
  $sqla->bind_params($sth, @bind);
  my $mock_params = $sth->{mock_params};
  is_deeply($sth->{mock_params}, [2, 1, \$k2, \$k1], "bind_param_inout");

  # test 3-args form of bind_param
  $sth = $dbh->prepare('INSERT INTO Foo(bar, foo) VALUES (?, ?)');
  @bind= ([123, {pg_type => 99}],
          [456, {ora_type => 88}]);
  $sqla->bind_params($sth, @bind);
  $mock_params = $sth->{mock_params};
  is_deeply($mock_params, \@bind, 'bind_param($val, \%type)');
}


#----------------------------------------------------------------------
# update
#----------------------------------------------------------------------

# complete syntax
($sql, @bind) = $sqla->update(
  -table => 'Foo',
  -set => {foo => 1, bar => 2},
  -where => {buz => 3},
);
is_same_sql_bind(
  $sql, \@bind,
  'UPDATE Foo SET bar = ?, foo = ? WHERE buz = ?',
  [2, 1, 3],
);

# without where
($sql, @bind) = $sqla->update(
  -table => 'Foo',
  -set => {foo => 1, bar => 2},
);
is_same_sql_bind(
  $sql, \@bind,
  'UPDATE Foo SET bar = ?, foo = ?',
  [2, 1],
);

# old API
($sql, @bind) = $sqla->update('Foo', {foo => 1, bar => 2}, {buz => 3});
is_same_sql_bind(
  $sql, \@bind,
  'UPDATE Foo SET bar = ?, foo = ? WHERE buz = ?',
  [2, 1, 3],
);


# MySQL supports -limit and -order_by in updates !
# see http://dev.mysql.com/doc/refman/5.6/en/update.html
($sql, @bind) = $sqla->update(
  -table => 'Foo',
  -set => {foo => 1, bar => 2},
  -where => {buz => 3},
  -order_by => 'baz',
  -limit => 10,
);
is_same_sql_bind(
  $sql, \@bind,
  'UPDATE Foo SET bar = ?, foo = ? WHERE buz = ? ORDER BY baz LIMIT ?',
  [2, 1, 3, 10],
  "update with -order_by/-limit",
);

($sql, @bind) = $sqla->update(
  -table => [-join => qw/Foo fk=pk Bar/],
  -set => {foo => 1, bar => 2},
);
is_same_sql_bind(
  $sql, \@bind,
  'UPDATE Foo INNER JOIN Bar ON Foo.fk=Bar.pk SET bar = ?, foo = ?',
  [2, 1],
);




# returning
($sql, @bind) = $sqla->update(
  -table      => 'Foo',
  -set        => {foo => 1},
  -returning  => 'key',
);
is_same_sql_bind(
  $sql, \@bind,
  'UPDATE Foo SET foo = ? RETURNING key',
  [1],
  'update returning (scalar)',
);

($sql, @bind) = $sqla->update(
  -table      => 'Foo',
  -set        => {foo => 1},
  -returning  => [qw/k1 k2/],
);
is_same_sql_bind(
  $sql, \@bind,
  'UPDATE Foo SET foo = ? RETURNING k1, k2',
  [1],
  'update returning (arrayref)',
);

($sql, @bind) = $sqla->update(
  -table      => 'Foo',
  -set        => {foo => 1},
  -returning  => {k1 => \my $kupd1, k2 => \my $kupd2},
);
is_same_sql_bind(
  $sql, \@bind,
  'UPDATE Foo SET foo = ? RETURNING k1, k2 INTO ?, ?',
  [1, \$kupd1, \$kupd2],
  'update returning (hashref)',
);



#----------------------------------------------------------------------
# delete
#----------------------------------------------------------------------

# complete syntax
($sql, @bind) = $sqla->delete(
  -from => 'Foo',
  -where => {buz => 3},
);
is_same_sql_bind(
  $sql, \@bind,
  'DELETE FROM Foo WHERE buz = ?',
  [3],
);

# old API
($sql, @bind) = $sqla->delete('Foo', {buz => 3});
is_same_sql_bind(
  $sql, \@bind,
  'DELETE FROM Foo WHERE buz = ?',
  [3],
);

# MySQL supports -limit and -order_by in deletes !
# see http://dev.mysql.com/doc/refman/5.6/en/delete.html
($sql, @bind) = $sqla->delete(
  -from => 'Foo',
  -where => {buz => 3},
  -order_by => 'baz',
  -limit => 10,
);
is_same_sql_bind(
  $sql, \@bind,
  'DELETE FROM Foo WHERE buz = ? ORDER BY baz LIMIT ?',
  [3, 10],
  "delete with -order_by/-limit",
);



#----------------------------------------------------------------------
# quote
#----------------------------------------------------------------------

$sqla = SQL::Abstract::More->new({ quote_char => q{"}, name_sep => q{.} });

($sql, @bind) = $sqla->select(
    -from => [
      -join => qw(
        t1|left
          id=t1_id
        t2|link
          =>{t3_id=id}
        t3|right
      )
    ],
    -columns => [ qw(
      left.id|left_id
      max("right"."id")|max_right_id
    ) ]
   );

is_same_sql_bind(
  $sql, \@bind,
  'SELECT "left"."id" AS "left_id", max("right"."id") AS "max_right_id" '
    . 'FROM "t1" AS "left" '
    . 'INNER JOIN "t2" AS "link" ON ("left"."id" = "link"."t1_id")'
    . 'LEFT OUTER JOIN "t3" AS "right" ON ("link"."t3_id" = "right"."id")',

  [],
);
