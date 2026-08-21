use strict;
use warnings;
use Test::More;
use Poker::Game::Pineapple;
use Poker::Game::CrazyPineapple;

# --- Pineapple: 3 hole, full board, evaluate ---
{
  my $game = Poker::Game::Pineapple->new;
  is( $game->hole_count, 3, 'Pineapple hole_count' );

  my $hero = $game->deal_hole( ['As', 'Kd', '7c'] );
  is( scalar @{ $hero->cards }, 3, '3 hole cards' );

  $game->flop( ['Ah', 'Kc', '2d'] );
  $game->turn('9s');
  $game->river('3c');
  $game->evaluate($hero);
  like( $hero->name, qr/Two Pair/i, 'Pineapple two pair' );
}

# --- Crazy Pineapple: discard required before turn/runout ---
{
  my $game = Poker::Game::CrazyPineapple->new;
  my $hero = $game->deal_hole( ['As', 'Kd', '7c'] );
  $game->flop( ['Ah', 'Kc', '2d'] );

  ok( $game->pending_discards, 'pending discard after flop' );
  ok( !$game->can_runout,      'runout blocked until discard' );

  eval { $game->turn('9s') };
  ok( $@, 'turn dies while discard pending' );

  $game->discard( $hero, '7c' );
  is( scalar @{ $hero->cards }, 2, '2 hole cards after discard' );
  is( $hero->cards_flat, 'AsKd', 'kept AsKd' );
  ok( !$game->pending_discards, 'pending_discards cleared' );
  ok( $game->can_runout, 'can_runout true after discard' );

  $game->turn('9s');
  $game->river('3c');
  $game->evaluate($hero);
  like( $hero->name, qr/Two Pair/i, 'Crazy Pineapple two pair after discard' );
}

# discard of missing card dies
{
  my $game = Poker::Game::CrazyPineapple->new;
  my $hero = $game->deal_hole( ['As', 'Kd', '7c'] );
  $game->flop( ['Ah', 'Kc', '2d'] );
  eval { $game->discard( $hero, '2h' ) };
  ok( $@, 'discard unknown card dies' );
}

done_testing();
