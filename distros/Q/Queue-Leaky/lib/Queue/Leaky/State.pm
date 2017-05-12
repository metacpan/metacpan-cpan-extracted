package Queue::Leaky::State;

use Moose::Role;

requires qw(get set remove incr decr);

no Moose;

1;

__END__

=head1 NAME

Queue::Leaky::State - Role For Keeping Global State 

=head1 SYNOPSIS

  package MyState;
  use Moose;

  with 'Queue::Leaky::State';

  no Moose;

  sub get    { ... }
  sub set    { ... }
  sub remove { ... }
  sub incr   { ... }
  sub decr   { ... }

=cut
