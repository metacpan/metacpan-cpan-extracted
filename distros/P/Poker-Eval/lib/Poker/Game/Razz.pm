package Poker::Game::Razz;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Community;
use Poker::Score::LowA5;

=head1 NAME

Poker::Game::Razz - Razz (seven-card stud low A-5)

=head1 VERSION

Version 0.11

=cut


=head1 SYNOPSIS

    use Poker::Game::Razz;

    my $game = Poker::Game::Razz->new;
    my $hero = $game->deal_hole(['As','2d','3c','4h','5s','9c','Kd']);
    $game->evaluate($hero);

=head1 DESCRIPTION

Razz: seven-card stud with A-5 lowball ranking (aces low; straights and
flushes do not count against the hand).

=cut

extends 'Poker::Game::Stud';

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args = {} unless ref $args eq 'HASH';
  $args->{scorer} //= Poker::Score::LowA5->new;
  $args->{eval_engine} //= Poker::Eval::Community->new(
    scorer => $args->{scorer},
  );
  return $args;
};

1;
