package Poker::Eval::BlackMariah;
use Moo;

=head1 NAME

Poker::Eval::BlackMariah - Evaluate and score hole cards in the game of Black Mariah. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 INTRODUCTION

"BlackMariah" typically refers to the Queen of Spades. Half the pot goes to the player holding black mariah at the end of the game. 

=head1 SYNOPSIS

See Poker::Eval for example code. 

=cut

extends 'Poker::Eval';

has 'bitch_card' => (
  is      => 'rw',
  builder => '_build_bitch_card',
);

sub _build_bitch_card { # The Bitch
  return 'Qs';
}

sub best_hand {
  my ( $self, $hole ) = @_;
  my $hand = Poker::Hand->new(cards => $hole);
  for my $card (@$hole) {
    if ($card->rank . $card->suit eq $self->bitch_card) {
      $hand->score(100);
      return $hand;
    }
  }
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
