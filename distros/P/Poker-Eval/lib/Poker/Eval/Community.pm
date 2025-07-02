package Poker::Eval::Community;
use Algorithm::Combinatorics qw(combinations);
use Moo;

=head1 NAME

Poker::Eval::Community - Evaluate and score hand using any combination of hole and community cards. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 SYNOPSIS

See Poker::Eval for example code.

=cut

extends 'Poker::Eval';

has 'card_count' => (
  is      => 'rw',
  builder => '_build_card_count',
);

sub _build_card_count {
  return 5;
}

sub best_hand {
  my ( $self, $hole ) = @_;
  my $hand = Poker::Hand->new(cards => $hole);
  return $hand
    if $self->card_count >
      ( scalar @$hole + scalar @{ $self->community_cards } );
  my $iter = $self->make_iter($hole);
  while ( my $combo = $iter->next ) {
    my $score = $self->scorer->score($combo);
    if ( defined $score && $score >= $hand->score ) {
      $hand->score($score);
      $hand->best_combo($combo);
    }
  }
  $hand->name($self->scorer->hand_name( $hand->score ));
  return $hand;
}

sub make_iter {
  my ( $self, $hole ) = @_;
  my $iter =
    combinations( [ @$hole, @{ $self->community_cards } ], $self->card_count );
  return $iter;
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
