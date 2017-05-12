use strict;
use warnings;

use Test::More tests => 1;
use Pod::Eventual::Simple;

my $output = Pod::Eventual::Simple->read_file('eg/non-empty-blank.pod');
my @events = grep { $_->{type} ne 'nonpod' and $_->{type} ne 'blank' }
             @$output;

my $want = [
  {
    type    => 'command',
    command => 'pod',
    content => "\n",
    start_line => 1,
  },
  {
    type    => 'text',
    content => "The line after this contains whitespace only.\n",
    start_line => 3,
  },
  {
    type    => 'text',
    content => "...but that doesn't prevent this from being a new paragraph.\n",
    start_line => 5,
  },
  {
    type    => 'command',
    command => 'cut',
    content => "\n",
    start_line => 7,
  },
];

is_deeply(\@events, $want, 'we got the events we expected');
