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

{ ### Testing FETCHSIZE
  my $desc = "array interpretation";
  my $set = $default_set->();

  is($set->size, scalar(@$set), "$desc: sizing is correct");
}

{ ### Testing pop
  my $desc = "pop";
  my $set = $default_set->();

  my $last = $set->last;
  my $popped = pop(@$set);

  is($popped, $last, "$desc: popped == last");
}

{ ### Testing push
  my $desc = "push";
  my $set = $default_set->();

  my $last     = $set->last;
  my $pushed   = push @$set, "foo";
  my $new_last = $set->last;

  isnt($last, $new_last, "$desc: last changes after push");
  is($pushed,         7, "$desc: correct number of pushed reported");
  is($new_last,   'foo', "$desc: last is correct");
}

{ ### Testing shift
  my $desc = "shift";
  my $set = $default_set->();

  my $first = $set->first;
  my $shifted = shift(@$set);

  is($shifted, $first, "$desc: shifted == first");
}

{ ### Testing unshift
  my $desc = "unshift";
  my $set = $default_set->();

  my $first      = $set->first;
  my $unshifted = unshift @$set, "foo";
  my $new_first  = $set->first;

  isnt($first,   $new_first, "$desc: first changes after unshift");
  is($unshifted,          7, "$desc: correct number of unshifted reported");
  is($new_first,      'foo', "$desc: first is correct");

  ### unshift the same value again.
  $unshifted  = unshift @$set, "foo";
  $new_first  = $set->first;
  
  is($unshifted,          7, "$desc: correct number of unshifted reported");
  is($new_first,      'foo', "$desc: first is correct");
}

{ ### Testing splice
  my $desc = "splice";
  my $set = $default_set->();

  { ### Sub-testing: Find good and bad elements (baseline test)
    my $b = $set->find('b');
    my $x = $set->find('x');

    is($b,   'b', "$desc: found initial 'b'");
    is($x, undef, "$desc: didn't find initial 'x'");
  }

  { ### Sub-testing: Replace 'b' with 'x'.
    splice(@$set, 1, 1, 'x');

    my $b = $set->find('b');
    my $x = $set->find('x');

    is($b, undef, "$desc: element removed");
    is($x,   'x', "$desc: new element inserted");

    my $pos_x = $set->[1];
    is($pos_x, 'x', "$desc: found spliced 'x' in the right place");
  }
  
  { ### Sub-testing: Multi-insert after 'x'
    splice(@$set, 1, 0, qw(x y z));

    my $pos_x = $set->[1];
    my $pos_y = $set->[2];
    my $pos_z = $set->[3];

    is($pos_x, 'x', "$desc: found spliced 'x' in the right place");
    is($pos_y, 'y', "$desc: found spliced 'y' in the right place");
    is($pos_z, 'z', "$desc: found spliced 'z' in the right place");
  }

}














