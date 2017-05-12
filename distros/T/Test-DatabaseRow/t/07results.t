#!/usr/bin/perl

########################################################################
# this tesst checks that store_XXX in Test::DatabaseRow's row_ok
# functions works
########################################################################

use strict;
use warnings;

use Test::More tests => 10;

use Test::DatabaseRow;
use Test::Builder::Tester;

use Data::Dumper;

$Test::DatabaseRow::dbh = FakeDBI->new(results => 2);

########################################################################

my @rows;
test_out("ok 1 - matches");
row_ok(table   => "dummy",
       where   => [ dummy => "dummy" ],
       results => 2,
       label   => "matches",
       store_rows => \@rows);
test_test("array");

is_deeply(\@rows, [
  { fooid => 123, name => "fred"  },
  { fooid => 124, name => "bert"  },
]);

########################################################################

my $row;
test_out("ok 1 - matches");
row_ok(table   => "dummy",
       where   => [ dummy => "dummy" ],
       results => 2,
       label   => "matches",
       store_row => \$row);
test_test("scalar");
is_deeply($row, { fooid => 123, name => "fred"  });

test_out("ok 1 - matches");
row_ok(table   => "dummy",
       where   => [ dummy => "dummy" ],
       results => 2,
       label   => "matches",
       store_row => \$row);
test_test("scalar");
is_deeply($row, { fooid => 123, name => "fred"  });

my %row;
test_out("ok 1 - matches");
row_ok(table   => "dummy",
       where   => [ dummy => "dummy" ],
       results => 2,
       label   => "matches",
       store_row => \%row);
test_test("hash");
is_deeply(\%row, { fooid => 123, name => "fred"  });

$row = {};
test_out("ok 1 - matches");
row_ok(table   => "dummy",
       where   => [ dummy => "dummy" ],
       results => 2,
       label   => "matches",
       store_row => \$row);
test_test("ref");
is_deeply($row, { fooid => 123, name => "fred"  });

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
