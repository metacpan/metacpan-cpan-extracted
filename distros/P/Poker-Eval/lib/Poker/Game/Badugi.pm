package Poker::Game::Badugi;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Badugi;
use Poker::Score::Badugi;

=head1 NAME

Poker::Game::Badugi - Badugi

=head1 VERSION

Version 0.11

=cut


=head1 SYNOPSIS

    use Poker::Game::Badugi;

    my $game = Poker::Game::Badugi->new;
    my $hero = $game->deal_hole(['As','2d','3c','4h']);
    $game->evaluate($hero);
    # optional draws:
    $game->discard($hero, 'As');
    $game->draw($hero, ['5s']);

=head1 DESCRIPTION

Badugi: four hole cards, triple draw, Badugi ranking (unique ranks and
suits; aces low; fewer cards can still make a hand).

=cut

extends 'Poker::Game';

has '+hole_count'      => ( default => sub { 4 } );
has '+board_size'      => ( default => sub { 0 } );
has '+max_draw_rounds' => ( default => sub { 3 } );

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args = {} unless ref $args eq 'HASH';
  $args->{scorer} //= Poker::Score::Badugi->new;
  $args->{eval_engine} //= Poker::Eval::Badugi->new(
    scorer => $args->{scorer},
  );
  return $args;
};

1;
