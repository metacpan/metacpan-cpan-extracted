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
  my $desc = 'as string';
  my $set = Set::Toolkit->new();

  { ### Sub-testing explicit stringification on an empty set
    my $str = $set->as_string;
    is($str, 'Set::Toolkit()', "$desc (explicit): empty set produces Set::Toolkit()");
  }
  
  { ### Sub-testing explicit stringification on an empty set
    my $str = "$set";
    is($str, 'Set::Toolkit()', "$desc (implicit): empty set produces Set::Toolkit()");
  }
  
  { ### Sub-testing implicit stringification on a stocked set.
    $set->insert(qw(a b c d e f));
    my $str = "$set";
    if ($str =~ /Set::Toolkit\(([a-f] ?){6}\)/) {
      pass("$desc (implicit): stocked set produces correct output");
    } else {
      fail("$desc (implicit): stocked set produces wrong output");
    }
  }

  { ### Sub-testing a ref in the mix.
    $set->insert({a=>1});
    my $str = "$set";
    if ($str =~ /Set::Toolkit\((([a-f]|HASH\(.{9}\)) ?){7}\)/) {
      pass("$desc (implicit): stocked set produces correct output");
    } else {
      fail("$str--$desc (implicit): stocked set produces wrong output");
    }
  }
}














