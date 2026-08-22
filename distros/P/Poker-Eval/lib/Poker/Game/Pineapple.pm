package Poker::Game::Pineapple;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Community;
use Poker::Score::High;

=head1 NAME

Poker::Game::Pineapple - Pineapple Hold'em

=head1 VERSION

Version 0.12

=cut


=head1 SYNOPSIS

    use Poker::Game::Pineapple;

    my $game = Poker::Game::Pineapple->new;
    my $hero = $game->deal_hole(['As', 'Kd', '7c']);  # 3 hole cards
    $game->flop(['Ah', 'Kc', '2d']);
    $game->turn('9s');
    $game->river('3c');
    $game->evaluate($hero);

=head1 DESCRIPTION

Pineapple: three hole cards, five community cards. Any combination of
hole and community cards may be used (same as Hold'em). Players typically
discard down to two hole cards before the flop in live play; this module
models the card math only -- discard timing is left to the caller (or use
C<Poker::Game::CrazyPineapple> for post-flop discard).

=cut

extends 'Poker::Game';

has '+hole_count' => ( default => sub { 3 } );
has '+board_size' => ( default => sub { 5 } );

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

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2026 Nathaniel Graham.

=cut

1;
