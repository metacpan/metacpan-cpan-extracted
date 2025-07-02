package Poker::Hand;
use Moo;

=head1 NAME

Poker::Hand - Simple class to represent a poker hand. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

This class is used internally by Poker::Eval.  You probably don't want to use it directly. 

=cut

=head1 ATTRIBUTES

=head2 cards

Array ref of Poker::Card objects. 

=cut

has 'cards' => (
  is      => 'rw',
  isa     => sub { die "Not an array ref" unless ref( $_[0] ) eq 'ARRAY' },
  builder => '_build_cards',
);

sub _build_cards {
  return [];
}

=head2 best_combo

Best combination of cards (hole + community) according to rules of game. 

=cut

has 'best_combo' => (
  is      => 'rw',
  isa     => sub { die "Not an array ref" unless ref( $_[0] ) eq 'ARRAY' },
  builder => '_build_best_combo',
);

sub _build_best_combo {
  return [];
}

has 'wins' => (
  is      => 'rw',
  default => sub { 0 },
);

=head2 score

Numerical score of best combination 

=cut

has 'score' => (
  is      => 'rw',
  default => sub { 0 },
);

has 'temp_score' => (
  is      => 'rw',
  default => sub { 0 },
);

=head2 name

english name of best combination 

=cut

has 'name' => ( is => 'rw', );

=head2 ev

Expected win rate of hand in given situation 

=cut

has 'ev' => (
  is      => 'rw',
  default => sub { 0 },
);

sub flatten {
  my ( $self, $cards ) = @_;
  return join( '', map { $_->rank . $_->suit } @{$cards} );
}

=head2 cards_flat

hole cards in human-readable form 

=cut

sub cards_flat {
  my $self = shift;
  return $self->flatten( $self->cards );
}

=head2 best_combo_flat

best combination of cards in human-readable form

=cut

sub best_combo_flat {
  my $self = shift;
  return $self->flatten( $self->best_combo );
}

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
