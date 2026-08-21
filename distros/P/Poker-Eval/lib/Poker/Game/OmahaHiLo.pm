package Poker::Game::OmahaHiLo;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Omaha;
use Poker::Score::High;
use Poker::Score::Low8;

=head1 NAME

Poker::Game::OmahaHiLo - Omaha Hold'em high/low 8-or-better

=head1 VERSION

Version 0.11

=cut


=head1 SYNOPSIS

    use Poker::Game::OmahaHiLo;

    my $game = Poker::Game::OmahaHiLo->new;
    my $hero = $game->deal_hole(['As', '2d', '3c', 'Kd']);
    $game->runout(['4h', '5c', '9s', 'Jh', 'Kc']);
    $game->evaluate($hero);

    say $hero->name;       # high hand name
    say $hero->low_name;   # low hand name (if qualifies), or undef

=head1 DESCRIPTION

Omaha Hi-Lo: four hole cards, five community cards. Exactly two hole
and three community cards for each direction. High uses standard
highball; low uses 8-or-better. A hand that does not qualify for low
leaves C<low_score> / C<low_name> undefined.

=cut

extends 'Poker::Game';

has '+hole_count' => ( default => sub { 4 } );
has '+board_size' => ( default => sub { 5 } );

has 'low_scorer' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub { Poker::Score::Low8->new },
);

has 'low_eval' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub {
    my $self = shift;
    Poker::Eval::Omaha->new( scorer => $self->low_scorer );
  },
);

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args = {} unless ref $args eq 'HASH';

  $args->{scorer} //= Poker::Score::High->new;
  $args->{eval_engine} //= Poker::Eval::Omaha->new(
    scorer => $args->{scorer},
  );

  return $args;
};

=head2 evaluate

Sets high result on C<score>/C<name>/C<best_combo>, and low result on
C<low_score>/C<low_name>/C<low_combo> when the hand qualifies for low.

=cut

around evaluate => sub {
  my ( $orig, $self, $arg ) = @_;
  my $hand = $self->$orig($arg);

  my $hole =
    ref $arg eq 'ARRAY' ? $arg
    : $arg->isa('Poker::Hand') ? $arg->cards
    : $hand->cards;

  $self->low_eval->community_cards( $self->board );
  my $low = $self->low_eval->best_hand($hole);

  # Low8 returns undef/0 score when no qualifying low
  my $qualified = defined $low->score && $low->score > 0;

  if ( ref $arg && $arg->isa('Poker::Hand') ) {
    if ($qualified) {
      $arg->low_score( $low->score );
      $arg->low_name( $low->name );
      $arg->low_combo( $low->best_combo );
    }
    else {
      $arg->low_score(undef);
      $arg->low_name(undef);
      $arg->low_combo([]);
    }
    return $arg;
  }

  if ($qualified) {
    $hand->low_score( $low->score );
    $hand->low_name( $low->name );
    $hand->low_combo( $low->best_combo );
  }
  return $hand;
};

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2026 Nathaniel Graham.

=cut

1;
