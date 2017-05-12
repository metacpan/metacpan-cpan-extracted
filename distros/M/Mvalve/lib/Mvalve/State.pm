# $Id$

package Mvalve::State;
use Moose::Role;

requires qw(get set remove incr decr);

no Moose;

1;

__END__

=head1 NAME

Mvalve::State - Role For Keeping Global Mvalve State 

=head1 SYNOPSIS

  package MyState;
  use Moose;

  with 'Mvalve::State';

  no Moose;

  sub get    { ... }
  sub set    { ... }
  sub remove { ... }
  sub incr   { ... }
  sub decr   { ... }

=cut