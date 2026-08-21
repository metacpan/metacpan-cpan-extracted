package Poker::Deck;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Card;
use Tie::IxHash;

=head1 NAME

Poker::Deck - Simple class to represent a deck of poker cards. 

=head1 VERSION

Version 0.11

=cut


=head1 SYNOPSIS

This class is used internally by Poker::Dealer. Attributes include
cards, discards, card_type, and joker_count.

    my $deck = Poker::Deck->new( joker_count => 2 );  # 54 cards

=cut

has 'joker_count' => (
  is      => 'ro',
  default => sub { 0 },
);

has 'card_type' => (
  is      => 'rw',
  builder => '_build_card_type',
);

sub _build_card_type {
  return 'Poker::Card';
}

has 'cards' => (
  is      => 'rw',
  lazy    => 1,
  isa     => sub { die "Not a Tie::IxHash!" unless $_[0]->isa('Tie::IxHash') },
  builder => '_build_cards',
);

has 'discards' => (
  is      => 'rw',
  isa     => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

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
  my $jokers = $self->joker_count // 0;
  for my $i ( 1 .. $jokers ) {
    my $name = "Jo$i";
    $cards->Push(
      $name => $self->card_type->new(
        id        => $cards->Length,
        rank      => 'Joker',
        suit      => $i,
        wild_flag => 1,
      )
    );
  }
  return $cards;
}

sub BUILD { }

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham.

=cut

1;
