package Poker::Dealer;
use strict;
use warnings FATAL => 'all';
use Moo;
use List::Util qw(shuffle);
use Poker::Deck;
use Storable qw(dclone);

=head1 NAME

Poker::Dealer - Simple class to represent a poker dealer 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 SYNOPSIS

    use Poker::Dealer;

    my $dealer = Poker::Dealer->new;

    $dealer->shuffle_deck;

    # Returns an array_ref of face-up card objects
    my $cards = $dealer->deal_up(4);

    # Returns an array_ref of face-down card objects
    my $cards = $dealer->deal_down(5);

    # Deal yourself two aces:
    my $cards = $dealer->deal_named(['As', 'Ah']);

=cut

has 'id' => (
  is  => 'rw',
);

has 'master_deck' => (
  is  => 'rw',
  isa => sub { die "Not a Poker::Deck!" unless $_[0]->isa('Poker::Deck') },
  builder => '_build_master_deck',
);

sub _build_master_deck {
  return Poker::Deck->new;
}

has 'deck' => (
  is      => 'rw',
  isa     => sub { die "Not a Poker::Deck!" unless $_[0]->isa('Poker::Deck') },
  lazy    => 1,
  builder => '_build_deck',
);

sub _build_deck {
  my $self = shift;
  return dclone $self->master_deck;
}

sub shuffle_cards {
  my ( $self, $cards ) = @_;
  $cards->cards->Reorder( shuffle $cards->cards->Keys );
}

=head1 SUBROUTINES/METHODS

=head2 shuffle_deck

Creates a new deck and randomizes the cards. 
=cut

sub shuffle_deck {
  my $self = shift;
  $self->deck( $self->_build_deck );
  $self->shuffle_cards( $self->deck );
}

sub deal {
  my ($self, $count)  = @_;
  $count = 1 if !defined $count;
  $self->reshuffle if $count > $self->deck->cards->Length;
  my %cards = $self->deck->cards->Splice( 0, $count );
  return [ values %cards ];
}

=head2 reshuffle

Shuffles cards in the discard pile and adds them to the existing deck. 
=cut

sub reshuffle {
  my $self = shift;
  while (my $card = shift @{ $self->deck->discards }) {
    $self->deck->cards->Push( $card->rank . $card->suit => $card )
  }
  $self->shuffle_cards( $self->deck );
}

=head2 deal_down

Returns an array_ref of Poker::Card objects face down 
=cut


sub deal_down {
  my ($self, $count)  = @_;
  return [ map { $_->up_flag(0); $_ } @{ $self->deal($count) } ];
}

=head2 deal_up

Returns an array_ref of Poker::Card objects face up 
=cut

sub deal_up {
  my ($self, $count)  = @_;
  return [ map { $_->up_flag(1); $_ } @{ $self->deal($count) } ];
}

=head2 deal_named

Fetch a specific set of cards from the deck.

=cut 

sub deal_named {
  my ( $self, $cards ) = @_;
  my @hand;
  for my $card (@$cards) {
    my $val = $self->deck->cards->FETCH($card) or die "No such card: $card";
    push @hand, $val;
    $self->deck->cards->Delete($card);
  }
  return [@hand];
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
