#!/usr/bin/perl -w

use strict;

# check if we can run Test::Warn
BEGIN
{
  eval { require Test::Warn; Test::Warn->import };
  if ($@)
  {
    print "1..0 # Skipped: no Test::Warn\n";
    exit;
  }
}

$Test::DatabaseRow::dbh = FakeDBI->new();

use Test::More tests => 2;
use Test::DatabaseRow;

# eek, how confusing is this?  This should produce two
# oks, one for the row_ok and one for not finding any
# warnings in it

warning_is { row_ok(sql   => "foo\nbar\nbaz",
		    tests => [ "fooid" => 123,
			       "wibble" => undef,],
		     label => "inside test",);
} "", "no warnings when dealing with undef/NULL";

# fake database package
package FakeDBI;
sub new { my $class = shift; return bless { @_, Name => "bob" }, $class };
sub quote { return "qtd<$_[1]>" };

sub prepare
{
  my $this = shift;

  # die if we need to
  if ($this->fallover)
    { die "Khaaaaaaaaaaaaan!" }

  return FakeSTH->new($this);
}

sub nomatch  { return $_[0]->{nomatch} }
sub fallover { return $_[0]->{fallover} }

package FakeSTH;
sub new { return bless { parent => $_[1] }, $_[0] };
sub execute { return 1 };
sub fetchrow_hashref
{
  my $this = shift;
  my $parent = $this->{parent};

  # return undef after the first call)
  if ($this->{called})
    { return }
  else
    { $this->{called} = 1 }

  return
    ($parent->nomatch)
     ?  undef
     : { fooid => 123, name => "fred", wibble => undef}
}
