#!/usr/bin/perl

########################################################################
# this test checks to see if the handling of sql_and_bind works, and if
# sql_and_bind is automatically created from table and where if needed
########################################################################

use strict;
use warnings;

use Test::More tests => 12;

########################################################################
# load the module / setup
########################################################################

BEGIN { use_ok "Test::DatabaseRow::Object" }

# create a fake dbh connection.  The quote function in this class
# just marks the text up with "qtd<text>" so we can see what would
# have been really quoted if it was a real dbh connection
my $dbh = FakeDBI->new();

########################################################################
# coercian
########################################################################


{
  my $tbr = Test::DatabaseRow::Object->new(
    dbh => $dbh,
    sql_and_bind => q{SELECT * FROM foo WHERE fooid = 123},
  );

  is($tbr->sql_and_bind->[0],
     q{SELECT * FROM foo WHERE fooid = 123},
     "simple test"
  );
}

########################################################################

{
  my $tbr = Test::DatabaseRow::Object->new(
    dbh => $dbh,
    sql_and_bind => [ q{SELECT * FROM foo WHERE fooid = 123} ],
  );

  is_deeply($tbr->sql_and_bind,
    [ q{SELECT * FROM foo WHERE fooid = 123} ],
    "simple test sql arrayref no bind"
  );
}

########################################################################

{
  my $array = [ q{SELECT * FROM foo WHERE fooid = ? AND bar = ?}, 123, 456 ];

  my $tbr = Test::DatabaseRow::Object->new(
    dbh => $dbh,
    sql_and_bind => $array,
  );

  is_deeply(
    $array,
    [ q{SELECT * FROM foo WHERE fooid = ? AND bar = ?}, 123, 456 ],
    "array passed in unaltered",
  );

  is_deeply(
    $tbr->sql_and_bind,
    [ q{SELECT * FROM foo WHERE fooid = ? AND bar = ?}, 123, 456 ],
    "simple test sql arrayref with bind"
  );
}

########################################################################
# from where and table
########################################################################

{
  my $where = { '=' => { fooid => 123, bar => "abc" } };

  my $tdr = Test::DatabaseRow::Object->new(
    dbh   => $dbh,
    table => "foo",
    where => $where
  );

  is_deeply(
    $where,
    { '=' => { fooid => 123, bar => "abc" } },
    "where datastructure unaltered"
  );

  is_deeply(
    $tdr->sql_and_bind,
    [ q{SELECT * FROM foo WHERE bar = qtd<abc> AND fooid = qtd<123>} ],
    "simple equals test"
  );
}

########################################################################

{
  my $where = [ fooid => 123, bar => "abc" ];

  my $tbr = Test::DatabaseRow::Object->new(
    dbh   => $dbh,
    table => "foo",
    where => $where
  );

  is_deeply(
    $where,
    [ fooid => 123, bar => "abc" ],
    "where datastructure unaltered"
  );

  is_deeply( $tbr->sql_and_bind,
    [ q{SELECT * FROM foo WHERE bar = qtd<abc> AND fooid = qtd<123>} ],
    "simple equals test with shortcut"
  );
}

########################################################################
# nulls
########################################################################

is_deeply(
  Test::DatabaseRow::Object->new(
     dbh   => $dbh,
     table => "foo",
     where => [ fooid => undef ]
  )->sql_and_bind,
  [q{SELECT * FROM foo WHERE fooid IS NULL}],
  "auto null test"
);

is_deeply(
  Test::DatabaseRow::Object->new(
     dbh   => $dbh,
     table => "foo",
     where => { "=" => { fooid => undef } }
  )->sql_and_bind,
  [q{SELECT * FROM foo WHERE fooid IS NULL}],
  "auto null test2"
);

is_deeply(
  Test::DatabaseRow::Object->new(
     dbh   => $dbh,
     table => "foo",
     where => { "IS NOT" => { fooid => undef } }
  )->sql_and_bind,
  [q{SELECT * FROM foo WHERE fooid IS NOT NULL}],
  "auto null test3"
);

########################################################################

# fake database package
package FakeDBI;
sub new { return bless {}, shift };
sub quote { return "qtd<$_[1]>" };
