use strict;
use warnings;

### Make sure we're testing against a local version if it's there.
BEGIN { unshift @INC, '.' }

use Test::More qw(no_plan);
use Set::Toolkit 0.11;

sub set {Set::Toolkit->new(@_)};

my $default_set = sub {
  my $set = set();
  ### Insert some scalars and some hashrefs.
  $set->insert(qw(a b c));
  $set->insert(
    {a => 123, b => 'abc'},
    {a => 123, b => 'def'},
    {a => 456, b => 'hij'},
  );
  return $set;
};

{ ### Test the array in a boolean context (implicit and explicit).
  my $desc = 'boolean';
  my $set = Set::Toolkit->new();

  if ($set) {
    fail("$desc: implicit bool on empty set should be false");
  } else {
    pass("$desc: implicit bool on empty set is false");
  }

  $set->insert('a');

  if ($set) {
    pass("$desc: implicit bool on full set is true");
  } else {
    fail("$desc: implicit bool on full set should be false");
  }
}














