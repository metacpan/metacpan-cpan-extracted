package Poker::Game::FiveCardDraw;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Community;
use Poker::Score::High;

=head1 NAME

Poker::Game::FiveCardDraw - Five-card draw (high)

=head1 VERSION

Version 0.11

=cut


=head1 SYNOPSIS

    use Poker::Game::FiveCardDraw;

    my $game = Poker::Game::FiveCardDraw->new;
    my $hero = $game->deal_hole(['As','Kd','7c','2h','9s']);
    $game->discard($hero, ['7c','2h']);
    $game->draw($hero);   # refill to 5
    $game->evaluate($hero);

=head1 DESCRIPTION

Five-card draw highball. One discard/draw round. No community cards.

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
  $args->{eval_engine} //= Poker::Eval::Community->new(
    scorer => $args->{scorer},
  );
  return $args;
};

1;
