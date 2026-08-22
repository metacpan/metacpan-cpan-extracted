package Poker::Game::Courcheval;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;

=head1 NAME

Poker::Game::Courcheval - Courchevel (5-card Omaha high)

=head1 VERSION

Version 0.12

=cut


=head1 SYNOPSIS

    use Poker::Game::Courcheval;

    my $game = Poker::Game::Courcheval->new;
    my $hero = $game->deal_hole(['As','Kd','7c','2h','9s']);
    $game->door('Ah');           # first board card (preflop)
    $game->flop(['Kc','2d']);    # two more -> 3 board cards
    $game->turn('9c');
    $game->river('3s');
    $game->evaluate($hero);

=head1 DESCRIPTION

Courchevel: five hole cards, five community cards dealt as 1 + 2 + 1 + 1.
Hand construction is standard Omaha (exactly two hole + three board).

=cut

extends 'Poker::Game::Omaha5';

=head2 door

Deal the first community card (exposed preflop).

=cut

sub door {
  my ( $self, $card ) = @_;
  die "door requires an empty board" if @{ $self->board };
  return $self->_deal_street( 1, $card );
}

=head2 flop

In Courchevel the "flop" adds two cards after the door card
(board becomes three cards).

=cut

around flop => sub {
  my ( $orig, $self, $cards ) = @_;
  die "Courchevel flop requires exactly 1 door card on board"
    unless @{ $self->board } == 1;
  return $self->_deal_street( 2, $cards );
};

1;
