use strict;
use warnings;
use Test::More tests => 3;

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
    multi method play (Paper    $x, Spock    $y) { 1 }
    multi method play (Scissors $x, Paper    $y) { 1 }
    multi method play (Scissors $x, Lizard   $y) { 1 }
    multi method play (Rock     $x, Scissors $y) { 1 }
    multi method play (Rock     $x, Lizard   $y) { 1 }
    multi method play (Lizard   $x, Paper    $y) { 1 }
    multi method play (Lizard   $x, Spock    $y) { 1 }
    multi method play (Spock    $x, Rock     $y) { 1 }
    multi method play (Spock    $x, Scissors $y) { 1 }
    multi method play (Any      $x, Any      $y) { 0 }
}

my $game = Game->new;
ok($game->play(Spock->new, Scissors->new), 'Spock smashes Scissors');
ok(!$game->play(Lizard->new, Rock->new), 'Rock crushes Lizard');
ok(!$game->play(Spock->new, Paper->new), 'Paper disproves Spock');

1;
