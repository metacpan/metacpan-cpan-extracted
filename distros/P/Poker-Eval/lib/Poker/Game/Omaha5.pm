package Poker::Game::Omaha5;

our $VERSION = '0.11';

use strict;
use warnings FATAL => 'all';
use Moo;

=head1 NAME

Poker::Game::Omaha5 - Five-card Omaha (high only)

=head1 VERSION

Version 0.11

=cut


=head1 SYNOPSIS

    use Poker::Game::Omaha5;

    my $game = Poker::Game::Omaha5->new;
    my $hero = $game->deal_hole(['As','Kd','7c','2h','9s']);  # 5 hole
    $game->flop(['Ah','Kc','2d']);
    $game->turn('3s');
    $game->river('8c');
    $game->evaluate($hero);

=head1 DESCRIPTION

Five-card Omaha: five hole cards, five community cards. Best hand still
uses B<exactly two> hole cards and B<exactly three> community cards
(same as four-card Omaha). Standard highball ranking.

=cut

extends 'Poker::Game::Omaha';

has '+hole_count' => ( default => sub { 5 } );

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2026 Nathaniel Graham.

=cut

1;
