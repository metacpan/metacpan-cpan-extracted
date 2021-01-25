use strict;
use warnings;
no warnings 'qw';

use SQL::Abstract::More;

use Test::More;
use SQL::Abstract::Test import => [qw/is_same_sql_bind/];

my $sqla = SQL::Abstract::More->new;
my ($sql, @bind, $join);


# NOTE: test cases below are inspired from the SQLite documentation for WITH clauses :
# https://sqlite.org/lang_with.html


# simple graph retrieval
($sql, @bind) = $sqla->with_recursive(
  -table     => 'nodes',
  -columns   => [qw/x/],
  -as_select => {-from      => 'DUAL',
                 -columns   => [qw/59/],
                 -union_all => [-from    => [-join => qw/edge {bb=x} nodes/],
                                -columns => [qw/aa/],
                              ],
                },
 )->select(
   -columns => 'x',
   -from    => 'nodes',
  );
is_same_sql_bind(
  $sql, \@bind,
  q{WITH RECURSIVE nodes(x) AS (          SELECT 59 FROM DUAL
                                UNION ALL SELECT aa FROM edge INNER JOIN nodes ON edge.bb=nodes.x)
    SELECT x FROM nodes},
  [],
  "1-branch graph retrieval",
  );



# graph retrieval with 2 branches
($sql, @bind) = $sqla->with_recursive(
  -table     => 'nodes',
  -columns   => [qw/x/],
  -as_select => {-from      => 'DUAL',
                 -columns   => [qw/59/],
                 -union_all => [-from    => [-join => qw/edge {bb=x} nodes/],
                                -columns => [qw/aa/],
                                -union_all => [-from  => [-join => qw/edge {aa=x} nodes/],
                                               -columns => [qw/bb/]],
                              ],
                },
 )->select(
   -columns => 'x',
   -from    => 'nodes',
  );
is_same_sql_bind(
  $sql, \@bind,
  q{WITH RECURSIVE nodes(x) AS (          SELECT 59 FROM DUAL
                                UNION ALL SELECT aa FROM edge INNER JOIN nodes ON edge.bb=nodes.x
                                UNION ALL SELECT bb FROM edge INNER JOIN nodes ON edge.aa=nodes.x)
    SELECT x FROM nodes},
  [],
  "2-branch graph retrieval",
  );


# several table expressions in the same WITH statement
($sql, @bind) = $sqla->with_recursive(
  [ -table     => 'parent_of',
    -columns   => [qw/name parent/],
    -as_select => {-columns => [qw/name mom/],
                   -from    => 'family',
                   -where   => {age => {'>' => 16.1}},
                   -union   => [-columns => [qw/name dad/],
                                -where   => {age => {'>' => 16.2}},
                                -from    => 'family']},
   ],
  [ -table     => 'ancestor_of_alice',
    -columns   => [qw/name/],
    -as_select => {-columns => [qw/parent/],
                   -from    => 'parent_of',
                   -where   => {name => 'Alice'},
                   -union_all => [-columns => [qw/parent/],
                                    -from => [qw/-join parent_of {name} ancestor_of_alice/]],
               },
   ],
  )->select(
   -columns => 'family.name',
   -from    => [qw/-join ancestor_of_alice {name} family/],
   -where   => {died                     => undef},
   -order_by => 'born',
  );

is_same_sql_bind(
  $sql, \@bind,
  q{WITH RECURSIVE
     parent_of(name, parent) AS
       (SELECT name, mom FROM family WHERE age > ?
        UNION SELECT name, dad FROM family WHERE age > ?),
     ancestor_of_alice(name) AS
       (SELECT parent FROM parent_of WHERE name = ?
        UNION ALL
        SELECT parent FROM parent_of INNER JOIN ancestor_of_alice USING(name))
    SELECT family.name FROM ancestor_of_alice INNER JOIN family USING(name)
      WHERE died IS NULL
      ORDER BY born},
  [16.1, 16.2, 'Alice'],
  "several CTEs in the same WITH clause",
  );

# auxiliary data for insert / update / delete
my $sqla2 = $sqla->with_recursive(
  -table     => 'nodes',
  -columns   => [qw/x/],
  -as_select => {-from      => 'DUAL',
                 -columns   => [qw/59/],
                 -union_all => [-from    => [-join => qw/edge {bb=x} nodes/],
                                -columns => [qw/aa/],
                              ],
                },
 );




# insert
($sql, @bind) = $sqla2->insert(
  -into    => "edge",
  -columns => ['aa'],
  -select  => {-columns => 'x', -from => "nodes"},
 );
is_same_sql_bind(
  $sql, \@bind,
  q{WITH RECURSIVE nodes(x) AS (          SELECT 59 FROM DUAL
                                UNION ALL SELECT aa FROM edge INNER JOIN nodes ON edge.bb=nodes.x)
    INSERT INTO edge(aa) SELECT x FROM nodes},
  [],
  "insert",
  );


# update
my @subquery = $sqla->select(-columns => 'x', -from => "nodes");
($sql, @bind) = $sqla2->update(
  -table  => "edge",
  -set    => {foo => "bar"},
  -where  => {aa => {-in => \\@subquery}}
 );
is_same_sql_bind(
  $sql, \@bind,
  q{WITH RECURSIVE nodes(x) AS (          SELECT 59 FROM DUAL
                                UNION ALL SELECT aa FROM edge INNER JOIN nodes ON edge.bb=nodes.x)
    UPDATE edge SET foo = ? 
    WHERE aa IN (SELECT x FROM nodes)},
  ["bar"],
  "update",
  );


# delete
($sql, @bind) = $sqla2->delete(
  -from  => "edge",
  -where  => {aa => {-in => \\@subquery}}
 );
is_same_sql_bind(
  $sql, \@bind,
  q{WITH RECURSIVE nodes(x) AS (          SELECT 59 FROM DUAL
                                UNION ALL SELECT aa FROM edge INNER JOIN nodes ON edge.bb=nodes.x)
    DELETE FROM edge
    WHERE aa IN (SELECT x FROM nodes)},
  [],
  "delete",
  );



# -final_clause -- example with an Oracle CYCLE clause
($sql, @bind) = $sqla->with_recursive(
  -table     => 'nodes',
  -columns   => [qw/x/],
  -as_select => {-from      => 'DUAL',
                 -columns   => [qw/59/],
                 -union_all => [-from    => [-join => qw/edge {bb=x} nodes/],
                                -columns => [qw/aa/],
                              ],
                },
  -final_clause => "CYCLE x SET is_cycle TO '1' DEFAULT '0'",
 )->select(
   -columns => 'x',
   -from    => 'nodes',
  );
is_same_sql_bind(
  $sql, \@bind,
  q{WITH RECURSIVE nodes(x) AS (          SELECT 59 FROM DUAL
                                UNION ALL SELECT aa FROM edge INNER JOIN nodes ON edge.bb=nodes.x)
                            CYCLE x SET is_cycle TO '1' DEFAULT '0'
    SELECT x FROM nodes},
  [],
  "-final_clause",
  );


# disable WITH in subqueries -- UNION
($sql, @bind) = $sqla2->select(
  -columns => [qw/a b/],
  -from    => "Foo",
  -union   => [-columns => [qw/c d/],
               -from    => 'Bar']
 );
is_same_sql_bind(
  $sql, \@bind,
  q{WITH RECURSIVE nodes(x) AS (          SELECT 59 FROM DUAL
                                UNION ALL SELECT aa FROM edge INNER JOIN nodes ON edge.bb=nodes.x)
    SELECT a, b FROM Foo UNION SELECT c, d FROM Bar},
  [],
  "subquery - union"
);


# disable WITH in subqueries -- GROUP BY
($sql, @bind) = $sqla2->select(
  -columns => [qw/a count(*)/],
  -from     => "Foo",
  -group_by => "a",
  -having   => {"count(*)" => {">" => 1}},
 );
is_same_sql_bind(
  $sql, \@bind,
  q{WITH RECURSIVE nodes(x) AS (          SELECT 59 FROM DUAL
                                UNION ALL SELECT aa FROM edge INNER JOIN nodes ON edge.bb=nodes.x)
    SELECT a, count(*) FROM Foo GROUP BY a HAVING count(*) > ?},
  [1],
  "subquery - group by"
);


done_testing();


