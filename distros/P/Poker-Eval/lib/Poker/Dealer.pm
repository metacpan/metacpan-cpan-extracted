package Poker::Dealer;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;
use List::Util qw(shuffle);
use Poker::Deck;
use Storable qw(dclone);

=head1 NAME

Poker::Dealer - Simple class to represent a poker dealer 

=head1 VERSION

Version 0.12

=cut


=head1 SYNOPSIS

    use Poker::Dealer;

    my $dealer = Poker::Dealer->new;
    my $dealer = Poker::Dealer->new( joker_count => 2 );

    $dealer->shuffle_deck;
    my $cards = $dealer->deal_up(4);
    my $cards = $dealer->deal_named(['As', 'Ah']);
    my $joker = $dealer->deal_named(['Jo1']);

=cut

has 'id' => (
  is  => 'rw',
);

has 'joker_count' => (
  is      => 'ro',
  default => sub { 0 },
);

has 'master_deck' => (
  is  => 'rw',
  isa => sub { die "Not a Poker::Deck!" unless $_[0]->isa('Poker::Deck') },
  builder => '_build_master_deck',
);

sub _build_master_deck {
  my $self = shift;
  return Poker::Deck->new( joker_count => $self->joker_count );
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
    my $key = $card->rank eq 'Joker'
      ? 'Jo' . $card->suit
      : $card->rank . $card->suit;
    $self->deck->cards->Push( $key => $card );
  }
  $self->shuffle_cards( $self->deck );
}

=head2 deal_down

=cut

sub deal_down {
  my ($self, $count)  = @_;
  return [ map { $_->up_flag(0); $_ } @{ $self->deal($count) } ];
}

=head2 deal_up

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

=cut

1;
