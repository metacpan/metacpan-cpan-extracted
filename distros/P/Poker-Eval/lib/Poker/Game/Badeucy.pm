package Poker::Game::Badeucy;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Badugi27;
use Poker::Eval::Community;
use Poker::Score::Badugi27;
use Poker::Score::Low27;

=head1 NAME

Poker::Game::Badeucy - Badeucy (Badugi27 + 2-7 low split)

=head1 VERSION

Version 0.12

=cut


=head1 DESCRIPTION

Badeucy: five hole cards, triple draw. Split between Badugi with aces
high (best Badugi is 2-3-4-5) and 2-7 five-card low.

C<evaluate> sets Badugi27 on C<score>/C<name> and 2-7 low on
C<low_score>/C<low_name>.

=cut

extends 'Poker::Game';

has '+hole_count'      => ( default => sub { 5 } );
has '+board_size'      => ( default => sub { 0 } );
has '+max_draw_rounds' => ( default => sub { 3 } );

has 'low_scorer' => (
  is      => 'ro',
  lazy    => 1,
  builder => sub { Poker::Score::Low27->new },
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
  $args->{scorer} //= Poker::Score::Badugi27->new;
  $args->{eval_engine} //= Poker::Eval::Badugi27->new(
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
