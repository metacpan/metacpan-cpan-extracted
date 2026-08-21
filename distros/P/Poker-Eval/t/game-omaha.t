use strict;
use warnings;
use Test::More;
use Poker::Game::Omaha;
use Poker::Game::OmahaHiLo;

# --- Omaha high: must use exactly 2 hole + 3 board ---
{
  my $game = Poker::Game::Omaha->new;
  is( $game->hole_count, 4, 'Omaha hole_count' );

  # Four aces in hole would be quads in Hold'em, but Omaha can only
  # use two hole cards — so with board 2c 3d 4h 5s 7c this is just a pair.
  my $hero = $game->deal_hole( ['As', 'Ad', 'Ah', 'Ac'] );
  is( scalar @{ $hero->cards }, 4, '4 hole cards' );

  $game->flop( ['2c', '3d', '4h'] );
  $game->turn('5s');
  $game->river('7c');
  $game->evaluate($hero);

  # Best is pair of aces (2 hole aces + 3 board), not quads
  unlike( $hero->name // '', qr/Four/i, 'Omaha cannot use 4 hole aces as quads' );
  ok( $hero->score > 0, 'Omaha high score set' );
  ok( $hero->name, 'Omaha high name set' );
}

# Strong Omaha high hand: two pair using 2 hole + 3 board
{
  my $game = Poker::Game::Omaha->new;
  my $hero = $game->deal_hole( ['As', 'Kd', '7c', '2h'] );
  $game->flop( ['Ah', 'Kc', '9d'] );
  $game->turn('3s');
  $game->river('8c');
  $game->evaluate($hero);
  like( $hero->name, qr/Two Pair/i, 'Omaha two pair Aces and Kings' );
}

# --- Omaha Hi-Lo: nut-ish low qualifies ---
# Omaha low needs exactly 2 hole + 3 board, all ranks ≤ 8, unpaired.
# Hole A-2 + board 4-5-6 → A-2-4-5-6 qualifies.
{
  my $game = Poker::Game::OmahaHiLo->new;
  my $hero = $game->deal_hole( ['As', '2d', '3c', 'Kd'] );
  $game->flop( ['4h', '5c', '6s'] );
  $game->turn('Jh');
  $game->river('Kc');
  $game->evaluate($hero);

  ok( $hero->score > 0, 'hi-lo high score set' );
  ok( defined $hero->low_score && $hero->low_score > 0, 'hi-lo low qualifies' );
}

# No low when board is all high cards
{
  my $game = Poker::Game::OmahaHiLo->new;
  my $hero = $game->deal_hole( ['As', '2d', '3c', '4h'] );
  $game->flop( ['Ks', 'Qd', 'Jh'] );
  $game->turn('Tc');
  $game->river('9s');
  $game->evaluate($hero);

  ok( $hero->score > 0, 'high still scores without low' );
  ok( !defined $hero->low_score || $hero->low_score == 0,
    'no qualifying low on high board' );
}

done_testing();
