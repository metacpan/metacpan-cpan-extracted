#!/usr/bin/perl

########################################################################
# this test checks that verbose_data works
########################################################################

use strict;
use warnings;

use Test::More;
BEGIN {
  if (Test::Builder->new->can("explain")) {
    plan tests => 1;
  } else {
    plan skip_all => "Older version of Test::Builder without 'explain'"
  }
}

use Test::DatabaseRow;
use Test::Builder::Tester;

use Data::Dumper;

$Test::DatabaseRow::dbh = FakeDBI->new(results => 2);

########################################################################

my ($string) = explain([
  {
    'fooid' => 123,
    'name' => 'fred'
  },
  {
    'fooid' => 124,
    'name' => 'bert'
  }
]);
my @expected = split /\n/, $string;

test_out("not ok 1 - matches");
test_fail(+6);
test_diag("While checking column 'name' on 1st row");
test_diag("         got: 'fred'");
test_diag("    expected: 'bar'");
test_diag("Data returned from the database:");
test_diag(@expected);
row_ok(table   => "dummy",
       where   => [ dummy => "dummy" ],
       results => 2,
       tests => [ "name" => "bar" ],
       label   => "matches",
       verbose_data => 1,
);
test_test("scalar");

########################################################################
# fake database package

package FakeDBI;
sub new { my $class = shift; return bless { @_ }, $class };
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
    { return { fooid => 123, name => "fred" } }

  if ($this->{returned} == 2)
    { return { fooid => 124, name => "bert" } }

  if ($this->{returned} == 3)
    { return { fooid => 125, name => "ernie" } }

  # oops, someone wanted more results than we prepared
  return;
}
