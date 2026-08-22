package Poker::Game::Omaha5HiLo;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;

=head1 NAME

Poker::Game::Omaha5HiLo - Five-card Omaha high/low 8-or-better

=head1 VERSION

Version 0.12

=cut


=head1 SYNOPSIS

    use Poker::Game::Omaha5HiLo;

    my $game = Poker::Game::Omaha5HiLo->new;
    my $hero = $game->deal_hole(['As','2d','3c','Kd','9h']);
    $game->runout(['4h','5c','6s','Jh','Kc']);
    $game->evaluate($hero);
    say $hero->name;
    say $hero->low_name if $hero->low_score;

=head1 DESCRIPTION

Five-card Omaha Hi-Lo: five hole cards, five community cards. Exactly
two hole and three community for each direction. High uses highball;
low uses 8-or-better.

=cut

extends 'Poker::Game::OmahaHiLo';

has '+hole_count' => ( default => sub { 5 } );

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2026 Nathaniel Graham.

=cut

1;
