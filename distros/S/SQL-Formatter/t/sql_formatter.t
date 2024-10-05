use Test2::V0 -no_srand => 1;
use SQL::Formatter;

my $f = SQL::Formatter->new;

my @ret;
is(
  [@ret=$f->format("select x, y, z from foo join bar where x = 1 and y = 2")],
  [D()],
  'does something at least'
);

is(
  [$f->format(undef)],
  [D()],
  'doing something silly like passing in NULL does not crash'
);

note @ret;

note $f->format('select foo.a, foo.b, bar.c from foo join bar on foo.a = bar.c where foo.b = 2');

done_testing;


