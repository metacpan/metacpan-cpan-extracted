use strict;
use warnings;

use Test::More tests => 1;
use Test::Deep;
use Pod::Eventual::Simple;

my $output = Pod::Eventual::Simple->read_file('eg/non-pod.pl');
my @events = @$output;

my $want = [
  {
    type       => 'nonpod',
    content    => re(qr{\A#!perl.+tion';\n\n\z}s),
    start_line => 1
  },
  { type => 'command', content => "\n", start_line =>  8, command => 'head1' },
  { type => 'blank',   content => "\n", start_line =>  9 },
  {
    type       => 'text',
    content    => re(qr{\AWe're.+stuff\.\n}s),
    start_line => 10,
  },
  { type => 'blank',   content => "\n", start_line => 11 },
  {
    type       => 'text',
    content    => re(qr{\AIt.+awesome\.\n}s),
    start_line => 12,
  },
  { type => 'blank',   content => "\n", start_line => 13 },
  { type => 'command', content => "\n", start_line => 14, command => 'cut' },
  {
    type       => 'nonpod',
    content    => "\n# ...and now we're done!\n\n",
    start_line => 15
  },
];

cmp_deeply(\@events, $want, 'we got the events we expected');
