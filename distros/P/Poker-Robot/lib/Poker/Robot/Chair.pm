package Poker::Robot::Chair;
use Moo;

=encoding utf8

=head1 NAME

Poker::Robot::Chair - Simple class to represent a poker chair. Used internally by Poker::Robot 

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

has 'table_id' => (
  is  => 'rw',
);

has 'login_id' => (
  is  => 'rw',
);

has 'user_id' => (
  is  => 'rw',
);

has 'chips' => (
  is  => 'rw',
);

has 'chair' => (
  is  => 'rw',
);

has 'valid_act' => (
  is  => 'rw',
  isa => sub { die "Not an array_ref!" unless ref( $_[0] ) eq 'ARRAY' },
);

has 'cards' => (
  is  => 'rw',
  isa => sub { die "Not an array_ref!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has 'posted' => (
  is      => 'rw',
  default => sub { return 0 },
);

has 'auto_muck' => (
  is      => 'rw',
  default => sub { return 1 },
);

has 'payout' => (
  is      => 'rw',
  clearer => 1,
);

has 'index' => ( is => 'rw', );

has 'hi_hand' => ( 
  is => 'rw', 
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  clearer => 1,
);

has 'low_hand' => ( 
  is => 'rw', 
  isa     => sub { die "Not a hash.\n" unless ref( $_[0] ) eq 'HASH' },
  clearer => 1,
);

has 'is_in_hand' => (
  is      => 'rw',
  default => sub { return 0; },
);

has 'in_pot' => (
  is      => 'rw',
  default => sub { return 0; },
);

has 'in_pot_this_round' => (
  is      => 'rw',
  default => sub { return 0; },
);

sub reset {
  my $self = shift;
  $self->is_in_hand(0);
  $self->in_pot(0);
  $self->in_pot_this_round(0);
  $self->clear_low_hand;
  $self->clear_hi_hand;
  $self->clear_payout;
}

=head1 AUTHOR

Nathaniel Graham, C<ngraham@cpan.org> 

=head1 BUGS

Please report any bugs or feature requests directly to C<ngraham@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT license.

=cut

1;
