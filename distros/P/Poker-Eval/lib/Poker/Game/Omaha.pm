package Poker::Game::Omaha;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Eval::Omaha;
use Poker::Score::High;

=head1 NAME

Poker::Game::Omaha - Omaha Hold'em (high only)

=head1 VERSION

Version 0.12

=cut


=head1 SYNOPSIS

    use Poker::Game::Omaha;

    my $game = Poker::Game::Omaha->new;
    my $hero = $game->deal_hole(['As', 'Kd', '7c', '2h']);  # 4 hole
    $game->flop(['Ah', 'Kc', '2d']);
    $game->turn('9s');
    $game->river('3c');
    $game->evaluate($hero);
    say $hero->name;

=head1 DESCRIPTION

Omaha: four hole cards, five community cards. Best hand uses
B<exactly two> hole cards and B<exactly three> community cards.
Standard highball ranking.

See C<Poker::Game::OmahaHiLo> for the split-pot variant.

=cut

extends 'Poker::Game';

has '+hole_count' => ( default => sub { 4 } );
has '+board_size' => ( default => sub { 5 } );

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

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2026 Nathaniel Graham.

=cut

1;
