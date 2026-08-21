use strict;
use warnings;
use Test::More;
use Poker::Game::Holdem;

my $game = Poker::Game::Holdem->new( iterations => 50 );

# Specific hole cards + full board
my $hero = $game->deal_hole( ['As', 'Kd'] );
is( scalar @{ $hero->cards }, 2, 'deal_hole specific: 2 cards' );
is( $hero->cards_flat, 'AsKd', 'hole cards flat' );

$game->flop( ['Ah', 'Kc', '2d'] );
is( scalar @{ $game->board }, 3, 'flop: 3 board cards' );

$game->turn('9s');
is( scalar @{ $game->board }, 4, 'turn: 4 board cards' );

$game->river('3c');
is( scalar @{ $game->board }, 5, 'river: 5 board cards' );
is( $game->board_string, 'AhKc2d9s3c', 'board_string' );

$game->evaluate($hero);
ok( $hero->score > 0, 'evaluate sets score' );
ok( $hero->name,      'evaluate sets name' );
# As Kd on Ah Kc 2d 9s 3c → two pair aces and kings
like( $hero->name, qr/Two Pair/i, 'two pair aces and kings' );

# runout guard
$game->reset;
ok( $game->can_runout, 'can_runout on empty board' );
$game->flop( ['2c', '3d', '4h'] );
ok( $game->can_runout, 'can_runout after flop' );
$game->runout( ['5s', '6c'] );
is( scalar @{ $game->board }, 5, 'runout completes board' );
ok( !$game->can_runout, 'can_runout false when board full' );

# equity smoke (does not assert exact %)
$game->reset;
my $h1 = $game->deal_hole( ['As', 'Ad'] );
my $h2 = $game->deal_hole( ['7h', '2c'] );
$game->equity( [ $h1, $h2 ] );
ok( $h1->ev >= $h2->ev, 'pocket aces equity >= 72o' );
ok( $h1->ev + $h2->ev > 0, 'equities assigned' );

# calc_ev alias
$game->reset;
$h1 = $game->deal_hole( ['Ks', 'Kd'] );
$h2 = $game->deal_hole( ['2h', '3c'] );
$game->calc_ev( [ $h1, $h2 ] );
ok( $h1->ev >= $h2->ev, 'calc_ev alias works' );

done_testing();
