use strict;
use warnings;
use utf8;
use Test::More;
use PLON;

my $plon = PLON->new->pretty(1)->encode([
    {a => [ qw(x y z)]},
]);
is $plon, n(<<'...');
[
  {
    "a" => [
      "x",
      "y",
      "z",
    ],
  },
]
...

{
my $plon = PLON->new->pretty(1)->encode({
    x => [a => [ qw(x y z)]],
});
is $plon, n(<<'...');
{
  "x" => [
    "a",
    [
      "x",
      "y",
      "z",
    ],
  ],
}
...
}

done_testing;

# normalize
sub n {
    my $n = shift;
    $n =~ s/\n\z//;
    $n;
}
