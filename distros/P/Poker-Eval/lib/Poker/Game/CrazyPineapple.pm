package Poker::Game::CrazyPineapple;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Community;
use Poker::Score::High;

=head1 NAME

Poker::Game::CrazyPineapple - Crazy Pineapple

=head1 VERSION

Version 0.11

=cut


=head1 SYNOPSIS

    use Poker::Game::CrazyPineapple;

    my $game = Poker::Game::CrazyPineapple->new;
    my $hero = $game->deal_hole(['As', 'Kd', '7c']);

    $game->flop(['Ah', 'Kc', '2d']);
    # Must discard one hole card before turn/runout
    $game->discard($hero, '7c');

    $game->turn('9s');
    $game->river('3c');
    $game->evaluate($hero);

=head1 DESCRIPTION

Crazy Pineapple: three hole cards, five community cards. After the flop
each player discards one hole card. C<runout>, C<turn>, and C<river> are
blocked until C<discard> has been called (via C<pending_discards>).

=cut

extends 'Poker::Game';

has '+hole_count' => ( default => sub { 3 } );
has '+board_size' => ( default => sub { 5 } );

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args = {} unless ref $args eq 'HASH';

  $args->{scorer} //= Poker::Score::High->new;
  $args->{eval_engine} //= Poker::Eval::Community->new(
    scorer => $args->{scorer},
  );

  return $args;
};

=head2 flop

Deals the flop and sets C<pending_discards> so further board cards are
blocked until C<discard> is called.

=cut

around flop => sub {
  my ( $orig, $self, @args ) = @_;
  my $board = $self->$orig(@args);
  $self->pending_discards(1);
  return $board;
};

=head2 discard

    $game->discard($hand, '7c');       # by card name
    $game->discard($hand, $card_obj); # by Poker::Card

Remove one hole card from C<$hand> and clear the pending-discard flag.

=cut

sub discard {
  my ( $self, $hand, $which ) = @_;
  die "discard requires a Poker::Hand"
    unless $hand && $hand->isa('Poker::Hand');
  die "no pending discard" unless $self->pending_discards;
  die "discard requires a card" unless defined $which;

  my @keep;
  my $removed = 0;
  for my $card ( @{ $hand->cards } ) {
    my $name = $card->rank . $card->suit;
    my $match =
      ref $which
      ? ( $card == $which || $name eq ( $which->rank . $which->suit ) )
      : ( $name eq $which );
    if ( $match && !$removed ) {
      $removed = 1;
      next;
    }
    push @keep, $card;
  }
  die "card not found in hand: $which" unless $removed;
  die "Crazy Pineapple discard must leave 2 hole cards"
    unless @keep == 2;

  $hand->cards( \@keep );
  $self->pending_discards(0);
  return $hand;
}

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2026 Nathaniel Graham.

=cut

1;
