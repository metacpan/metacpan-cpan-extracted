use strict;

use Test::More tests => 6;

use Protect::Unwind;


my $i = 0;

is($i++, 0, 'start');

func(sub {
  is($i++, 3, 'callback called from func');
  goto ESCAPE;
});

ESCAPE:
is($i++, 5, 'all done');

exit;


sub func {
  my $cb = shift;
  is($i++, 1, 'inside func');
  protect {
    is($i++, 2, 'inside protected sub');
    $cb->();
    die "shouldn't happen: skipped with goto";
  } unwind {
    is($i++, 4, 'inside unwinding sub');
  };
}
