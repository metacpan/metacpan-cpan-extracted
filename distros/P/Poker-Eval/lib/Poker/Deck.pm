package Poker::Deck;
use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Card;
use Tie::IxHash;

=head1 NAME

Poker::Deck - Simple class to represent a deck of poker cards. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 SYNOPSIS

This class is used internally by Poker::Dealer.  You probably don't want to use it directly. Attributes include cards, discards, and card_type.

=cut;

has 'cards' => (
  is => 'rw',
  isa =>
    sub { die "Not a Tie::IxHash!" unless $_[0]->isa( 'Tie::IxHash') },
  builder => '_build_cards',
);

has 'discards' => (
  is => 'rw',
  isa =>
    sub { die "Not an array!" unless ref($_[0]) eq 'ARRAY' },
  default => sub { [] },
);

has 'card_type' => (
  is      => 'rw',
  builder => '_build_card_type',
);

sub _build_card_type {
  return 'Poker::Card';
}

sub _build_cards {
  my $self  = shift;
  my $cards = Tie::IxHash->new;
  for my $rank (qw(2 3 4 5 6 7 8 9 T J Q K A)) {
    for my $suit (qw(c d h s)) {
      $cards->Push(
        $rank
          . $suit => $self->card_type->new(
          id   => $cards->Length,
          suit => $suit,
          rank => $rank
          )
      );
    }
  }
  return $cards;
}

sub BUILD { }

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
