package Poker::Eval::HighSuit;
use Moo;

=head1 NAME

Poker::Eval::HighSuit - Calculate the highest card of a specific suit.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 INTRODUCTION

Useful in split-pot games like High Chicago where half the pot goes to the player with the highest Spade.

=cut

extends 'Poker::Eval';

has 'high_suit' => (
  is      => 'rw',
  builder => '_build_high_suit',
);

sub _build_high_suit {    # High Chicago
  return 's';
}

sub best_hand {
  my ( $self, $hole ) = @_;
  my $hand = Poker::Hand->new(cards => $hole);
  $hand->score($self->scorer->score($hole, $self->high_suit));
  return $hand;
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
