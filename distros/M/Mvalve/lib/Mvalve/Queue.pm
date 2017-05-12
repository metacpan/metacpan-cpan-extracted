# $Id$

package Mvalve::Queue;
use Moose::Role;

requires qw(next fetch insert clear);

no Moose;

1;

__END__

=head1 NAME

Mvalve::Queue - Queue Interface Role

=head1 SYNOPSIS

  package MyQueue;
  use Moose;

  with 'Mvalve::Queue';

  no Mooose;

  sub next   { ... }
  sub fetch  { ... }
  sub insert { ... }
  sub clear  { ... }

=cut