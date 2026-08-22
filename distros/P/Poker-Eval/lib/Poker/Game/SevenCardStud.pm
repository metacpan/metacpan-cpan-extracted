package Poker::Game::SevenCardStud;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Community;
use Poker::Score::High;

=head1 NAME

Poker::Game::SevenCardStud - Seven-card stud (high)

=head1 VERSION

Version 0.12

=cut


=head1 SYNOPSIS

    use Poker::Game::SevenCardStud;

    my $game = Poker::Game::SevenCardStud->new;
    my $hero = Poker::Hand->new( cards => [] );
    $game->third_street( $hero, ['As','Kd','7c'] );
    $game->fourth_street( $hero, 'Ah' );
    $game->fifth_street(  $hero, 'Kc' );
    $game->sixth_street(  $hero, '2d' );
    $game->seventh_street($hero, '9s' );
    $game->evaluate($hero);

=head1 DESCRIPTION

Seven-card stud highball. Best five of seven; no community cards.

=cut

extends 'Poker::Game::Stud';

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
