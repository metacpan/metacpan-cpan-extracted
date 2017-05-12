#!/usr/bin/perl -w

use strict;

use Test::More tests => 13;

use Test::DatabaseRow;
use Test::Builder::Tester;

$Test::DatabaseRow::dbh = FakeDBI->new(results => 2);

test_out("ok 1 - matches");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => [ fooid => 123,
                  name  => "fred",
                  name  => qr/re/  ],
       label => "matches");
test_test("basic");

test_out("ok 1 - matches");
row_ok(table   => "dummy",
       where   => [ dummy => "dummy" ],
       results => 2,
       label   => "matches");
test_test("right number");

test_out("ok 1 - matches");
row_ok(table       => "dummy",
       where       => [ dummy => "dummy" ],
       min_results => 2,
       label       => "matches");
test_test("right number, min");

test_out("ok 1 - matches");
row_ok(table       => "dummy",
       where       => [ dummy => "dummy" ],
       max_results => 2,
       label       => "matches");
test_test("right number, max");

test_out("not ok 1 - matches");
test_fail(+4);
test_diag("Got the wrong number of rows back from the database.");
test_diag("  got:      2 rows back");
test_diag("  expected: 3 rows back");
row_ok(table   => "dummy",
       where   => [ dummy => "dummy" ],
       results => 3,
       label   => "matches");
test_test("wrong number");

test_out("not ok 1 - matches");
test_fail(+4);
test_diag("Got too few rows back from the database.");
test_diag("  got:      2 rows back");
test_diag("  expected: 3 rows or more back");
row_ok(table   => "dummy",
       where   => [ dummy => "dummy" ],
       min_results => 3,
       label   => "matches");
test_test("wrong number, min");

test_out("not ok 1 - matches");
test_fail(+4);
test_diag("Got too many rows back from the database.");
test_diag("  got:      2 rows back");
test_diag("  expected: 1 rows or fewer back");
row_ok(table   => "dummy",
       where   => [ dummy => "dummy" ],
       max_results => 1,
       label   => "matches");
test_test("wrong number, max");

$Test::DatabaseRow::dbh = FakeDBI->new(results => 0);

test_out("ok 1 - matches");
not_row_ok(table   => "dummy",
           where   => [ dummy => "dummy" ],
           label   => "matches");
test_test("not_row");

$Test::DatabaseRow::dbh = FakeDBI->new(results => 3);

test_out("ok 1 - matches");
all_row_ok(table   => "dummy",
           where   => [ dummy => "dummy" ],
           tests   => [ name => qr/e/ ],
           label   => "matches");
test_test("all_row_ok pass");

test_out("not ok 1 - matches");
test_fail(+4);           
test_diag("While checking column 'name' on 2nd row");
test_diag("         got: 'bert'");
test_diag("    expected: 'fred'");
all_row_ok(table   => "dummy",
           where   => [ dummy => "dummy" ],
           tests   => [ name => "fred" ],
           label   => "matches");
test_test("all_row_ok fail");

test_out("not ok 1 - matches");
test_fail(+2);           
test_diag("No 4th row");
Test::DatabaseRow::Object->new(
  dbh          => FakeDBI->new(results => 2),
  sql_and_bind => "dummy",
)->row_at_index_ok(3)->pass_to_test_builder("matches");
test_test("missing row");

test_out("ok 1 - matches");
Test::DatabaseRow::Object->new(
  dbh          => FakeDBI->new(results => 2),
  sql_and_bind => "dummy",
)->row_at_index_ok(1)->pass_to_test_builder("matches");
test_test("row_at_index_ok with no tests");

$Test::DatabaseRow::dbh = FakeDBI->new(results => 4);

# note the following test also checks undef <-> NULL handing
test_out("not ok 1 - matches");
test_fail(+10);           
test_diag("While checking column 'gender' on 4th row");
test_diag("         got: NULL");
test_diag("    expected: 'm'");
test_diag("The SQL executed was:");
test_diag("  dummy sql");
test_diag("The bound parameters were:");
test_diag("  '7'");
test_diag("  undef");
test_diag("on database 'fakename'");
all_row_ok(
  sql     => ["dummy sql",7,undef],
  tests   => [ gender => "m" ],
  label   => "matches",
  verbose => 1,
);
test_test("verbose");

# fake database package
package FakeDBI;
sub new { my $class = shift; return bless { @_, Name => "fakename" }, $class };
sub quote { return "qtd<$_[1]>" };

sub prepare
{
  my $this = shift;

  # die if we need to
  if ($this->fallover)
    { die "Khaaaaaaaaaaaaan!" }

  return FakeSTH->new($this);
}

sub results  { return $_[0]->{results}  }
sub nomatch  { return $_[0]->{nomatch}  }
sub fallover { return $_[0]->{fallover} }

package FakeSTH;
sub new { return bless { parent => $_[1] }, $_[0] };
sub execute { return 1 };

sub fetchrow_hashref
{
  my $this = shift;
  my $parent = $this->{parent};

  $this->{returned}++;

  return if $parent->nomatch;
  return if $this->{returned} > $parent->results;

  if ($this->{returned} == 1)
    { return { fooid => 123, name => "fred", gender => 'm'} }

  if ($this->{returned} == 2)
    { return { fooid => 124, name => "bert", gender => 'm'} }

  if ($this->{returned} == 3)
    { return { fooid => 125, name => "ernie", gender => 'm'} }

  if ($this->{returned} == 4)
    { return { fooid => 125, name => undef, gender => undef } }

  # oops, someone wanted more results than we prepared
  return;
}
