#!/usr/bin/perl -w

use strict;
use Test::More;

# these tests only work on perl 5.8.0
BEGIN
{
  if( $] < 5.007 ) {
    plan skip_all => 'need perl 5.8 for utf8 hacks'
  }
  else {
    plan tests => 2;
  }
}

use utf8;
use Test::DatabaseRow;
use Test::Builder::Tester;

# stderr needs to be utf8 so I can read these errors
binmode STDERR, ":utf8";

$Test::DatabaseRow::dbh = FakeDBI->new(results => 2);

test_out("ok 1 - foo");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => [ name => "Napol\x{e9}on" ],
       label => "foo",
       force_utf8 => 1);
test_test("napoleon");

$Test::DatabaseRow::force_utf8 = 1;

test_out("ok 1 - foo");
row_ok(table => "dummy",
       where => [ dummy => "dummy" ],
       tests => [ beast => "m\x{f8}\x{f8}se" ],
       label => "foo",
       force_utf8 => 1);
test_test("moose");

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

  # we're creating utf8 strings by directly writing in the
  # utf8 bytes.  This gives us utf8 strings we're testing
  # against, but without the utf8 flag set
  no utf8;

  if ($this->{returned} == 1)
    { return { name => "Napol\x{c3}\x{a9}on",
	       beast => "m\x{c3}\x{b8}\x{c3}\x{b8}se" } }

  # oops, someone wanted more results than we prepared
  return;
}
