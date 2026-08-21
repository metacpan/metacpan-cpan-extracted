use strict;
use warnings;
use Test::More;
use Poker::Game::Omaha5;
use Poker::Game::Omaha5HiLo;

{
  my $game = Poker::Game::Omaha5->new;
  is( $game->hole_count, 5, 'Omaha5 hole_count' );

  my $hero = $game->deal_hole( ['As', 'Kd', '7c', '2h', '9s'] );
  is( scalar @{ $hero->cards }, 5, '5 hole cards' );

  $game->flop( ['Ah', 'Kc', '3d'] );
  $game->turn('8s');
  $game->river('4c');
  $game->evaluate($hero);
  like( $hero->name, qr/Two Pair/i, 'Omaha5 two pair' );
}

{
  my $game = Poker::Game::Omaha5HiLo->new;
  is( $game->hole_count, 5, 'Omaha5HiLo hole_count' );

  my $hero = $game->deal_hole( ['As', '2d', '3c', 'Kd', '9h'] );
  $game->flop( ['4h', '5c', '6s'] );
  $game->turn('Jh');
  $game->river('Kc');
  $game->evaluate($hero);

  ok( $hero->score > 0, 'Omaha5HiLo high score' );
  ok( defined $hero->low_score && $hero->low_score > 0,
    'Omaha5HiLo low qualifies' );
}

done_testing();
