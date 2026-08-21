package Poker::Game::LowA5TripleDraw;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Community;
use Poker::Score::LowA5;

=head1 NAME

Poker::Game::LowA5TripleDraw - A-5 triple draw

=head1 VERSION

Version 0.11

=cut


extends 'Poker::Game';

has '+hole_count'      => ( default => sub { 5 } );
has '+board_size'      => ( default => sub { 0 } );
has '+max_draw_rounds' => ( default => sub { 3 } );

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
