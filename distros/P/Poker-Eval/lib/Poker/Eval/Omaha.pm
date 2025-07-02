package Poker::Eval::Omaha;
use Algorithm::Combinatorics qw(combinations);
use Moo;

=head1 NAME

Poker::Eval::Omaha - Evaluate and score Omaha poker hands. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

See Poker::Eval for code example.

=head1 INTRODUCTION

In Omaha style games, the best hand is made using EXACTLY two hole cards and EXACTLY three community cards.

=cut

extends 'Poker::Eval';

has '_combos' => (
  is      => 'rw',
  isa => sub { die "Not an array ref!" unless ref($_[0]) eq 'ARRAY' },
  predicate => 'has_combos',
);

sub _build_combos {
  my $self = shift;
  return unless $self->community_cards && scalar @{ $self->community_cards } >= 3;
  my @combos = combinations( $self->community_cards, 3 );
  $self->_combos([ @combos ]);
}

after 'community_cards' => sub {
  my ($self, $cards) = @_;
  return unless $cards && scalar @$cards >= 3;
  $self->_build_combos;
};

sub best_hand {
  my ( $self, $hole ) = @_;
  my $hand = Poker::Hand->new(cards => $hole);

  return $hand
    if 5 >
      ( scalar @$hole + scalar @{ $self->community_cards } );

  my $iter = combinations( $hole, 2 );
  while ( my $hole_combo = $iter->next ) {
    for my $combo (@{$self->_combos}) {
      my $combo = [ @$hole_combo, @$combo ];
      my $score = $self->scorer->score($combo);
      if (defined $score && $score >= $hand->score) {
        $hand->score($score);
        $hand->best_combo($combo);
      }
    }
  }
  $hand->name($self->scorer->hand_name($hand->score));
  return $hand;

}

after 'BUILD' => sub {
  my $self = shift;
  $self->_build_combos;
};

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
