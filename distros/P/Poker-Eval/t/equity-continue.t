use strict;
use warnings;
use Test::More;
use Poker::Game::Holdem;

my $game = Poker::Game::Holdem->new( iterations => 50 );
my $hero    = $game->deal_hole( [ 'As', 'Kd' ] );
my $villain = $game->deal_hole( [ '7c', '7h' ] );
$game->equity( [ $hero, $villain ] );
ok( defined $hero->ev, 'preflop equity ran' );
ok( eval { $game->flop( [ 'Ah', 'Kc', '2d' ] ); 1 }, 'flop after equity' ) or diag $@;
ok( eval { $game->turn('9s'); 1 }, 'turn after equity' ) or diag $@;
ok( eval { $game->river('3c'); 1 }, 'river after equity' ) or diag $@;
$game->evaluate($hero);
ok( $hero->name, 'evaluate after full board' );
done_testing();
