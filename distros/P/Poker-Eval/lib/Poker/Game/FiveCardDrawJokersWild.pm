package Poker::Game::FiveCardDrawJokersWild;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Dealer;
use Poker::Eval::Wild;
use Poker::Score::High;

=head1 NAME

Poker::Game::FiveCardDrawJokersWild - Five-card draw with jokers wild

=head1 VERSION

Version 0.11

=cut


=head1 SYNOPSIS

    use Poker::Game::FiveCardDrawJokersWild;

    my $game = Poker::Game::FiveCardDrawJokersWild->new;
    my $hero = $game->deal_hole(['As', 'Kd', 'Jo1', '2h', '9s']);
    $game->evaluate($hero);

=head1 DESCRIPTION

Five-card draw using a 54-card deck (two jokers). Jokers are always
wild. Deal jokers by name as C<Jo1> / C<Jo2>.

=cut

extends 'Poker::Game';

has '+hole_count'      => ( default => sub { 5 } );
has '+board_size'      => ( default => sub { 0 } );
has '+max_draw_rounds' => ( default => sub { 1 } );

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
