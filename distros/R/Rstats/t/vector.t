use Test::More 'no_plan';
use strict;
use warnings;

use Rstats;

my $r = Rstats->new;

# names
{
  my $v1 = $r->c([1, 2, 3, 4]);
  $r->names($v1 => $r->c(['a', 'b', 'c', 'd']));
  my $v2 = $v1->get($r->c(['b', 'd'])->as_character);
  is_deeply($v2->values, [2, 4]);
}

# to_string
{
  my $v = $r->c([1, 2, 3]);
  $r->names($v => ['a', 'b', 'c']);
  is("$v", "a b c\n[1] 1 2 3\n");
}
