use strict;
use warnings;

BEGIN { unshift @INC, '.' }
use Test::More tests => 18;
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

{ ### Testing first
  my $desc = 'first/last';
  my $set = Set::Toolkit->new();
  $set->insert(qw(a b c d e f));

  ### Grab the first and last in the set.
  my $first = $set->first;
  my $last  = $set->last;

  ### Make sure they're right.
  is($first, 'a', "$desc: scalar first found correctly");
  is($last,  'f', "$desc: scalar last  found correctly");

  ### Try a different one for testing refs.
  $set = Set::Toolkit->new();
  my @els = (
    {a=>123,b=>456},
    {a=>456,b=>789},
  );

  $set->insert(@els);

  $first = $set->first;
  $last  = $set->last;

  ### Make sure they're right.
  is($first, $els[0], "$desc: ref first found correctly");
  is($last,  $els[1], "$desc: ref last  found correctly");

  ### Single-element sets should return the same for first and last.
  $set = Set::Toolkit->new();
  $set->insert('a');

  $first = $set->first;
  $last  = $set->last;

  is($first, $last, "$desc: single-element sets; first == last");

  ### Empty sets should return undef.
  $set = Set::Toolkit->new();

  $first = $set->first;
  $last  = $set->last;

  ok(!defined($first), "$desc: first is undef in empty sets");
  ok(!defined($last),  "$desc: last  is undef in empty sets");
}


{ ### Testing find
  my $desc = 'find';
  my $set = $default_set->();

  ### We can find scalars in the list by value
  my $b = $set->find('b');
  is($b, 'b', "$desc: we can find scalars in the set");
  
  ### We can't find scalars not in the list.
  my $x = $set->find('x');
  is($x, undef, "$desc: we get undef when searching for scalars not in the set");

  my $hashref = $set->find(a=>'456');
  ok(ref($hashref) eq 'HASH', "$desc: find returned a hashref");
  is($hashref->{a}, 456,   "$desc: found the correct search param");
  is($hashref->{b}, 'hij', "$desc: secondary properties present");
}

{ ### Testing search
  my $desc = "search";
  my $set = $default_set->();

  ### Searching should return a Set::Toolkit object.
  my $resultset = $set->search('a');
  isa_ok($resultset, 'Set::Toolkit', "$desc: searching for a scalar returns a resultset");
  is($resultset->size, 1, "$desc: the resultset has the right number of items");

  ### Search by hash key=>value pairs.
  $resultset = $set->search(a=>123);
  isa_ok($resultset, 'Set::Toolkit', "$desc: searching for a hashref pair returns a resultset");
  is($resultset->size, 2, "$desc: the resultset has the right number of items");

  ### Chaining searches
  $resultset = $set->search(a=>123)->search(b=>'def');
  is($resultset->size, 1, "$desc: chained searches return sets with the right number of items");
}

{ ### Testing removal
  my $desc = "removal";
  my $set = $default_set->();

  ### Initialize the set and make sure it's good for testing.
  $set->remove('b');
  is($set->size, 5, "$desc: removing a scalar decrements size");

}









