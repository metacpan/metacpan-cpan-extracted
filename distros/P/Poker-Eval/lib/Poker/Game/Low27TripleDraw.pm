package Poker::Game::Low27TripleDraw;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Community;
use Poker::Score::Low27;

=head1 NAME

Poker::Game::Low27TripleDraw - 2-7 triple draw

=head1 VERSION

Version 0.12

=cut


extends 'Poker::Game';

has '+hole_count'      => ( default => sub { 5 } );
has '+board_size'      => ( default => sub { 0 } );
has '+max_draw_rounds' => ( default => sub { 3 } );

around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $args = $class->$orig(@args);
  $args = {} unless ref $args eq 'HASH';
  $args->{scorer} //= Poker::Score::Low27->new;
  $args->{eval_engine} //= Poker::Eval::Community->new(
    scorer => $args->{scorer},
  );
  return $args;
};

1;
