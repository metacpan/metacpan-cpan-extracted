package Queue::Leaky::Driver;

use Moose::Role;

requires qw(next fetch insert clear);

no Moose;

1;

__END__

=head1 NAME

Queue::Leaky::Driver - Queue Interface Role

=head1 SYNOPSIS

  package MyQueue;
  use Moose;

  with 'Queue::Leaky::Driver';

  no Moose;

  sub next   { ... }
  sub fetch  { ... }
  sub insert { ... }
  sub clear  { ... }

=cut
