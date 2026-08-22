package Poker::Game::HoldemJokersWild;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Dealer;
use Poker::Eval::Wild;
use Poker::Score::High;

=head1 NAME

Poker::Game::HoldemJokersWild - Texas Hold'em with jokers wild

=head1 VERSION

Version 0.12

=cut


=head1 SYNOPSIS

    use Poker::Game::HoldemJokersWild;

    my $game = Poker::Game::HoldemJokersWild->new;
    my $hero = $game->deal_hole(['As', 'Jo1']);
    $game->flop(['Ah', 'Kc', '2d']);
    $game->turn('9s');
    $game->river('3c');
    $game->evaluate($hero);

=head1 DESCRIPTION

Texas Hold'em with a 54-card deck (two jokers). Jokers are always wild
and may appear in the hole or on the board. Uses C<Poker::Eval::Wild>
so any combination of hole + community is allowed (Hold'em rules),
with wild substitution.

=cut

extends 'Poker::Game';

has '+hole_count' => ( default => sub { 2 } );
has '+board_size' => ( default => sub { 5 } );

has 'joker_count' => (
  is      => 'ro',
  default => sub { 2 },
);

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args = {} unless ref $args eq 'HASH';

  my $jokers = $args->{joker_count} // 2;
  $args->{scorer} //= Poker::Score::High->new;
  $args->{eval_engine} //= Poker::Eval::Wild->new(
    scorer => $args->{scorer},
    dealer => Poker::Dealer->new( joker_count => $jokers ),
  );

  return $args;
};

1;
