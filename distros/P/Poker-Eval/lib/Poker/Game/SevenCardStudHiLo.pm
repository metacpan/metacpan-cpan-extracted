package Poker::Game::SevenCardStudHiLo;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Community;
use Poker::Score::High;
use Poker::Score::Low8;

=head1 NAME

Poker::Game::SevenCardStudHiLo - Seven-card stud high/low 8-or-better

=head1 VERSION

Version 0.12

=cut


=head1 DESCRIPTION

Seven-card stud hi-lo. High uses highball; low uses 8-or-better.
Sets C<low_score> / C<low_name> / C<low_combo> when the hand qualifies.

=cut

extends 'Poker::Game::Stud';

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
    Poker::Eval::Community->new( scorer => $self->low_scorer );
  },
);

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

around evaluate => sub {
  my ( $orig, $self, $arg ) = @_;
  my $hand = $self->$orig($arg);

  my $hole =
    ref $arg eq 'ARRAY' ? $arg
    : $arg->isa('Poker::Hand') ? $arg->cards
    : $hand->cards;

  $self->low_eval->community_cards( [] );
  my $low = $self->low_eval->best_hand($hole);
  my $qualified = defined $low->score && $low->score > 0;

  my $target = ( ref $arg && $arg->isa('Poker::Hand') ) ? $arg : $hand;
  if ($qualified) {
    $target->low_score( $low->score );
    $target->low_name( $low->name );
    $target->low_combo( $low->best_combo );
  }
  else {
    $target->low_score(undef);
    $target->low_name(undef);
    $target->low_combo([]);
  }
  return $target;
};

1;
