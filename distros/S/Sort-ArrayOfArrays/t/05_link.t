#!/usr/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 2}

use Sort::ArrayOfArrays;

my $sort = Sort::ArrayOfArrays->new({
  results     => [
    ['<a href="http://www.a.com>a.com</a>', '<a href="http://www.b.com>b.com</a>', '<a href="http://www.c.com>c.com</a>'],
    ['<a href="http://www.d.com>d.com</a>', '<a href="http://www.e.com>e.com</a>', '<a href="http://www.f.com>f.com</a>'],
    ['<a href="http://www.g.com>g.com</a>', '<a href="http://www.h.com>h.com</a>', '<a href="http://www.i.com>i.com</a>'],
  ],
  sort_method => ['', 'la'],
  sort_column => '-1',
});
my $results = $sort->sort_it;
ok($results && ref $results eq 'ARRAY' && $results->[0] && ref $results->[0] eq 'ARRAY');
ok(
  $results->[0][0] eq '<a href="http://www.g.com>g.com</a>' && $results->[0][1] eq '<a href="http://www.h.com>h.com</a>' && $results->[0][2] eq '<a href="http://www.i.com>i.com</a>' &&
  $results->[1][0] eq '<a href="http://www.d.com>d.com</a>' && $results->[1][1] eq '<a href="http://www.e.com>e.com</a>' && $results->[1][2] eq '<a href="http://www.f.com>f.com</a>' &&
  $results->[2][0] eq '<a href="http://www.a.com>a.com</a>' && $results->[2][1] eq '<a href="http://www.b.com>b.com</a>' && $results->[2][2] eq '<a href="http://www.c.com>c.com</a>'
);
__END__
$results = [
  [
    "<a href=\"http://www.g.com>g.com</a>",
    "<a href=\"http://www.h.com>h.com</a>",
    "<a href=\"http://www.i.com>i.com</a>"
  ],
  [
    "<a href=\"http://www.d.com>d.com</a>",
    "<a href=\"http://www.e.com>e.com</a>",
    "<a href=\"http://www.f.com>f.com</a>"
  ],
  [
    "<a href=\"http://www.a.com>a.com</a>",
    "<a href=\"http://www.b.com>b.com</a>",
    "<a href=\"http://www.c.com>c.com</a>"
  ]
];
