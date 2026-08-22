package Poker::Game::CourchevalHiLo;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;

=head1 NAME

Poker::Game::CourchevalHiLo - Courchevel high/low 8-or-better

=head1 VERSION

Version 0.12

=cut


=head1 DESCRIPTION

Courchevel Hi-Lo: five hole cards, board dealt 1 + 2 + 1 + 1.
Omaha construction rules with high and low 8-or-better.

=cut

extends 'Poker::Game::Omaha5HiLo';

sub door {
  my ( $self, $card ) = @_;
  die "door requires an empty board" if @{ $self->board };
  return $self->_deal_street( 1, $card );
}

around flop => sub {
  my ( $orig, $self, $cards ) = @_;
  die "Courchevel flop requires exactly 1 door card on board"
    unless @{ $self->board } == 1;
  return $self->_deal_street( 2, $cards );
};

1;
