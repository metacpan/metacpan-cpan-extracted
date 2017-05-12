use strict;
use warnings;
use Test::More tests => 5;

{
    package Paper;    use Moose;
    package Scissors; use Moose;
    package Rock;     use Moose;
    package Lizard;   use Moose;
    package Spock;    use Moose;

    package Game;
    use Moose;
    use MooseX::MultiMethods;

    multi method play (Paper    $x, Rock     $y) { 1 }
    multi method play (Scissors $x, Paper    $y) { 1 }
    multi method play (Rock     $x, Scissors $y) { 1 }
    multi method play (Any      $x, Any      $y) { 0 }

    package Game::Extended;
    use Moose;
    use MooseX::MultiMethods;
    extends 'Game';

    multi method play (Paper    $x, Spock    $y) { 1 }
    multi method play (Scissors $x, Lizard   $y) { 1 }
    multi method play (Rock     $x, Lizard   $y) { 1 }
    multi method play (Lizard   $x, Paper    $y) { 1 }
    multi method play (Lizard   $x, Spock    $y) { 1 }
    multi method play (Spock    $x, Rock     $y) { 1 }
    multi method play (Spock    $x, Scissors $y) { 1 }
}

my $game = Game->new;
ok($game->play(Scissors->new, Paper->new), 'Scissors cuts Paper');

my $egame = Game::Extended->new;
ok($egame->play(Scissors->new, Paper->new), 'Scissors cuts Paper');

ok($egame->play(Spock->new, Scissors->new), 'Spock smashes Scissors');
ok(!$egame->play(Lizard->new, Rock->new), 'Rock crushes Lizard');
ok(!$egame->play(Spock->new, Paper->new), 'Paper disproves Spock');

1;

