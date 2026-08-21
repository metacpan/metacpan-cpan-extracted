package Poker::Game::Stud;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Hand;

=head1 NAME

Poker::Game::Stud - Base class for stud-style games

=head1 VERSION

Version 0.11

=cut


=head1 DESCRIPTION

Stud games have no community board. Each player is dealt their own
cards across streets. Final hand size defaults to 7 (seven-card stud);
best five are scored via the eval engine.

Street helpers enforce typical seven-card stud structure:

    third_street  -- deal 3 (start)
    fourth_street -- deal 1 (hand size 4)
    fifth_street  -- deal 1 (hand size 5)
    sixth_street  -- deal 1 (hand size 6)
    seventh_street / river -- deal 1 (hand size 7)

=cut

extends 'Poker::Game';

has '+hole_count' => ( default => sub { 7 } );
has '+board_size' => ( default => sub { 0 } );

=head2 deal_to

    $game->deal_to($hand, 3);
    $game->deal_to($hand, 1, ['As']);

Append cards to an existing hand.

=cut

sub deal_to {
  my ( $self, $hand, $count, $specific ) = @_;
  die "deal_to requires a Poker::Hand"
    unless $hand && $hand->isa('Poker::Hand');
  $count //= 1;

  my $new;
  if ( defined $specific ) {
    my $cards = $self->_normalize_cards( $count, $specific );
    die "expected $count cards" unless @$cards == $count;
    $new = $self->deal_cards($cards);
  }
  else {
    $new = $self->dealer->deal($count);
  }
  push @{ $hand->cards }, @$new;
  return $hand;
}

sub _assert_hand_size {
  my ( $self, $hand, $expect ) = @_;
  my $n = scalar @{ $hand->cards };
  die "expected hand size $expect, got $n" unless $n == $expect;
}

=head2 third_street

Deal the first three cards to an empty hand.

=cut

sub third_street {
  my ( $self, $hand, $specific ) = @_;
  $self->_assert_hand_size( $hand, 0 );
  return $self->deal_to( $hand, 3, $specific );
}

=head2 fourth_street / fifth_street / sixth_street / seventh_street

Deal one additional card at each street.

=cut

sub fourth_street {
  my ( $self, $hand, $specific ) = @_;
  $self->_assert_hand_size( $hand, 3 );
  return $self->deal_to( $hand, 1, $specific );
}

sub fifth_street {
  my ( $self, $hand, $specific ) = @_;
  $self->_assert_hand_size( $hand, 4 );
  return $self->deal_to( $hand, 1, $specific );
}

sub sixth_street {
  my ( $self, $hand, $specific ) = @_;
  $self->_assert_hand_size( $hand, 5 );
  return $self->deal_to( $hand, 1, $specific );
}

sub seventh_street {
  my ( $self, $hand, $specific ) = @_;
  $self->_assert_hand_size( $hand, 6 );
  return $self->deal_to( $hand, 1, $specific );
}

sub river { shift->seventh_street(@_) }

=head2 deal_hole

For stud, C<deal_hole> starts an empty hand and deals third street
(3 cards), or accepts a specific list of up to 7 cards.

=cut

around deal_hole => sub {
  my ( $orig, $self, $arg ) = @_;
  if ( ref $arg eq 'ARRAY' ) {
    return $self->$orig($arg);
  }
  my $hand = Poker::Hand->new( cards => [] );
  my $n = defined $arg ? $arg : 3;
  return $self->deal_to( $hand, $n );
};

1;
