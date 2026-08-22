package Poker::Game::Badacey;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Badugi;
use Poker::Eval::Community;
use Poker::Score::Badugi;
use Poker::Score::LowA5;

=head1 NAME

Poker::Game::Badacey - Badacey (Badugi + A-5 low split)

=head1 VERSION

Version 0.12

=cut


=head1 DESCRIPTION

Badacey: five hole cards, triple draw. Split between Badugi (best 1-4
card badugi from the five) and A-5 five-card low.

C<evaluate> sets high-side Badugi on C<score>/C<name>/C<best_combo> and
A-5 low on C<low_score>/C<low_name>/C<low_combo>.

=cut

extends 'Poker::Game';

has '+hole_count'      => ( default => sub { 5 } );
has '+board_size'      => ( default => sub { 0 } );
has '+max_draw_rounds' => ( default => sub { 3 } );

has 'low_scorer' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub { Poker::Score::LowA5->new },
);

has 'low_eval' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub {
    my $self = shift;
    Poker::Eval::Community->new( scorer => $self->low_scorer );
  },
);

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

around evaluate => sub {
  my ( $orig, $self, $arg ) = @_;
  my $hand = $self->$orig($arg);

  my $hole =
    ref $arg eq 'ARRAY' ? $arg
    : $arg->isa('Poker::Hand') ? $arg->cards
    : $hand->cards;

  $self->low_eval->community_cards( [] );
  my $low = $self->low_eval->best_hand($hole);

  my $target = ( ref $arg && $arg->isa('Poker::Hand') ) ? $arg : $hand;
  $target->low_score( $low->score );
  $target->low_name( $low->name );
  $target->low_combo( $low->best_combo );
  return $target;
};

1;
