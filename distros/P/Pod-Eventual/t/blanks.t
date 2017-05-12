use strict;
use warnings;

use Test::More tests => 1;
use Pod::Eventual::Simple;

my $output = Pod::Eventual::Simple->read_file('eg/blanks.pod');
my @events = grep { $_->{type} ne 'nonpod' } @$output;

sub blank_at { 
  my ($line, $num) = @_;
  $num ||= 1;

  return { type => 'blank', content => "\n" x $num, start_line => $line };
}

my $want = [
  {
    type       => 'command',
    command    => 'head1',
    start_line => '2',
    content    => "ABOUT\n",
  },
  blank_at(3),
  {
    type       => 'text',
    start_line => '4',
    content    =>
    'This document includes typed regions with data paragraphs with blank lines as
well as verbatim paragraphs with blank lines.  We want either to have one event
per block-with-blank or to have sufficient information to reconstruct the
block.
',
  },
  blank_at(8),


  # We want to be able to reconstruct these to one verbatim paragraph with the
  # correct amount of blank vertical space. -- rjbs, 2009-05-23
  {
    content    => '  For example I have now begin a verbatim paragraph
',
    type       => 'text',
    start_line => '9'
  },
  blank_at(10),
  {
    content    => '  and despite the intervening blank I am still in it, and
',
    type       => 'text',
    start_line => '11'
  },
  blank_at(12, 2),
  {
    content    =>
      '  even several blank lines are included -- without loss -- in the final
  verbatim paragraph.
',
    type       => 'text',
    start_line => '14'
  },

  blank_at(16),

  {
    type       => 'command',
    command    => 'begin',
    start_line => '17',
    content    => "data\n",
  },

  blank_at(18),

  # The same thing goes for here... we want to be able to have all the blanks.
  # -- rjbs, 2009-05-23
  {
    type       => 'text',
    start_line => '19',
    content    => "Similarly, this paragraph\n",
  },
  blank_at(20),
  {
    type       => 'text',
    start_line => '21',
    content    => "is actually one data para\n",
  },
  blank_at(22, 2),
  {
    type       => 'text',
    start_line => '24',
    content    => "with blank lines within.\n",
  },

  blank_at(25),

  {
    type       => 'command',
    command    => 'end',
    start_line => '26',
    content    => "data\n",
  },

  blank_at(27),
];

is_deeply(\@events, $want, 'we got the events we expected');
