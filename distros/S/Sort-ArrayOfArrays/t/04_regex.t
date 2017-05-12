#!/usr/bin/perl -w
use strict;
use Test;

BEGIN { plan tests => 2}

use Sort::ArrayOfArrays;

my $sort = Sort::ArrayOfArrays->new({
  results     => [
    ['<!--ignore start-->a<!--end ignore-->', '<!--ignore start-->b<!--end ignore-->', '<!--ignore start-->c<!--end ignore-->'],
    ['<!--ignore start-->d<!--end ignore-->', '<!--ignore start-->e<!--end ignore-->', '<!--ignore start-->f<!--end ignore-->'],
    ['<!--ignore start-->g<!--end ignore-->', '<!--ignore start-->h<!--end ignore-->', '<!--ignore start-->i<!--end ignore-->'],
  ],
  sort_method => ['', 'ra'],
  sort_column => '-1',
  sort_method_regex => {
    1 => '<!--.+?>(.+?)<!--.+?>',
  },
});
my $results = $sort->sort_it;
ok($results && ref $results eq 'ARRAY' && $results->[0] && ref $results->[0] eq 'ARRAY');
ok(
  $results->[0][0] eq '<!--ignore start-->g<!--end ignore-->' && $results->[0][1] eq '<!--ignore start-->h<!--end ignore-->' && $results->[0][2] eq '<!--ignore start-->i<!--end ignore-->' &&
  $results->[1][0] eq '<!--ignore start-->d<!--end ignore-->' && $results->[1][1] eq '<!--ignore start-->e<!--end ignore-->' && $results->[1][2] eq '<!--ignore start-->f<!--end ignore-->' &&
  $results->[2][0] eq '<!--ignore start-->a<!--end ignore-->' && $results->[2][1] eq '<!--ignore start-->b<!--end ignore-->' && $results->[2][2] eq '<!--ignore start-->c<!--end ignore-->'
);
__END__
$results = [
      [
        "<!--ignore start-->g<!--end ignore-->",
        "<!--ignore start-->h<!--end ignore-->",
        "<!--ignore start-->i<!--end ignore-->"
      ],
      [
        "<!--ignore start-->d<!--end ignore-->",
        "<!--ignore start-->e<!--end ignore-->",
        "<!--ignore start-->f<!--end ignore-->"
      ],
      [
        "<!--ignore start-->a<!--end ignore-->",
        "<!--ignore start-->b<!--end ignore-->",
        "<!--ignore start-->c<!--end ignore-->"
      ]
    ];
