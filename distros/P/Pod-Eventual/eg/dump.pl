#!perl
use strict;
use warnings;

our @events;

{
  package Pod::Gather;
  use base 'Pod::Eventual';
  sub handle_event { push @events, $_[1] }
}

use String::Truncate qw(elide);

Pod::Gather->read_file($ARGV[0]);

for my $event (@events) {
  my $content = defined $event->{content} ? $event->{content} : '';
  $content =~ s/\n.*//s;

  printf "%4u: %-10s %-10s %s\n",
    $event->{start_line},
    $event->{type},
    (defined $event->{command} ? $event->{command} : '(n/a)'),
    elide($content, 60);
}
