use strict;
use warnings;

use Test::More tests => 1;
use Pod::Eventual::Simple;

my $output = Pod::Eventual::Simple->read_file('eg/test.pod');
my @events = grep { $_->{type} ne 'nonpod' and $_->{type} ne 'blank' }
             @$output;

my $want = [
  {
    type    => 'command',
    command => 'pod',
    content => "\nsay 3;\n",
    start_line => 4,
  },
  {
    type    => 'command',
    command => 'cut',
    content => "\n",
    start_line => 6,
  },
  {
    type    => 'command',
    command => 'head1',
    content => "NAME\n",
    start_line => 10,
  },
  {
    type    => 'text',
    content => "This is a test of the NAME header.\n",
    start_line => 12,
  },
  {
    type    => 'command',
    command => 'head2',
    content => "Extended\n"
      . "This is all part of the head2 para, whether you believe it or not.\n",
    start_line => 14,
  },
  {
    type    => 'text',
    content => "Then we're in a normal text paragraph.\n",
    start_line => 17,
  },
  {
    type    => 'text',
    content => "Still normal!\n",
    start_line => 19,
  },
  {
    type    => 'text',
    content => "  This one is verbatim.\n",
    start_line => 21,
  },
  {
    type    => 'text',
    content => "Then back to normal.\n",
    start_line => 23,
  },
  {
    type    => 'text',
    content => "  And then verbatim\n"
      . "Including a secondary unindented line.  Oops!  Should still work.\n",
    start_line => 25,
  },
  {
    type    => 'command',
    command => 'cut',
    content => "\n",
    start_line => 27,
  },
];

is_deeply(\@events, $want, 'we got the events we expected');
