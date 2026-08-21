package Poker::Game::FiveCardDrawDeucesWild;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Wild;
use Poker::Score::High;

=head1 NAME

Poker::Game::FiveCardDrawDeucesWild - Five-card draw, deuces wild

=head1 VERSION

Version 0.11

=cut


=head1 SYNOPSIS

    use Poker::Game::FiveCardDrawDeucesWild;

    my $game = Poker::Game::FiveCardDrawDeucesWild->new;
    my $hero = $game->deal_hole(['As','2d','2c','Kh','9s']);
    # deuces are marked wild automatically after deal_hole
    $game->evaluate($hero);

=head1 DESCRIPTION

Five-card draw with all 2s wild. Uses C<Poker::Eval::Wild>.

=cut

extends 'Poker::Game';

has '+hole_count'      => ( default => sub { 5 } );
has '+board_size'      => ( default => sub { 0 } );
has '+max_draw_rounds' => ( default => sub { 1 } );

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args = {} unless ref $args eq 'HASH';
  $args->{scorer} //= Poker::Score::High->new;
  $args->{eval_engine} //= Poker::Eval::Wild->new(
    scorer => $args->{scorer},
  );
  return $args;
};

around deal_hole => sub {
  my ( $orig, $self, @args ) = @_;
  my $hand = $self->$orig(@args);
  for my $card ( @{ $hand->cards } ) {
    $card->wild_flag(1) if $card->rank eq '2';
  }
  return $hand;
};

around draw => sub {
  my ( $orig, $self, $hand, @rest ) = @_;
  my $result = $self->$orig( $hand, @rest );
  for my $card ( @{ $hand->cards } ) {
    $card->wild_flag(1) if $card->rank eq '2';
  }
  return $result;
};

1;
