use strict;
use warnings;
use Test::More;
use Poker::Game::FiveCardDraw;
use Poker::Game::FiveCardDrawDeucesWild;
use Poker::Game::Low27SingleDraw;
use Poker::Game::Low27TripleDraw;
use Poker::Game::LowA5SingleDraw;
use Poker::Game::Courcheval;

# Five-card draw: discard + draw
{
  my $game = Poker::Game::FiveCardDraw->new;
  is( $game->hole_count, 5, 'draw hole_count' );
  is( $game->board_size, 0, 'draw no board' );
  is( $game->draws_left, 1, 'single draw starts with 1' );

  my $hero = $game->deal_hole( ['As', 'Kd', '7c', '2h', '9s'] );
  $game->discard( $hero, [ '7c', '2h' ] );
  is( scalar @{ $hero->cards }, 3, '3 cards after discard' );
  ok( $game->pending_draws, 'draw pending' );

  $game->draw( $hero, [ 'Ah', 'Kc' ] );
  is( scalar @{ $hero->cards }, 5, '5 cards after draw' );
  is( $game->draws_left, 0, 'no draws left' );

  $game->evaluate($hero);
  like( $hero->name, qr/Two Pair/i, 'draw two pair' );
}

# Triple draw has 3 rounds
{
  my $game = Poker::Game::Low27TripleDraw->new;
  is( $game->draws_left, 3, 'triple draw starts with 3' );
  my $hero = $game->deal_hole( ['7s', '5d', '4c', '3h', '2c'] );
  $game->discard( $hero, '7s' );
  $game->draw( $hero, ['8d'] );
  is( $game->draws_left, 2, '2 draws left after first round' );
  $game->evaluate($hero);
  ok( $hero->score > 0, '27 low scores' );
}

# Deuces wild marks 2s
{
  my $game = Poker::Game::FiveCardDrawDeucesWild->new;
  my $hero = $game->deal_hole( ['As', '2d', '2c', 'Kh', 'Ks'] );
  my $wilds = grep { $_->is_wild } @{ $hero->cards };
  is( $wilds, 2, 'two deuces marked wild' );
  $game->evaluate($hero);
  ok( $hero->score > 0, 'deuces wild scores' );
}

# A-5 single draw loads
{
  my $game = Poker::Game::LowA5SingleDraw->new;
  my $hero = $game->deal_hole( ['As', '2d', '3c', '4h', '5s'] );
  $game->evaluate($hero);
  ok( $hero->score > 0, 'A5 low scores' );
}

# Courcheval street order
{
  my $game = Poker::Game::Courcheval->new;
  is( $game->hole_count, 5, 'Courcheval 5 hole' );
  my $hero = $game->deal_hole( ['As', 'Kd', '7c', '2h', '9s'] );
  $game->door('Ah');
  is( scalar @{ $game->board }, 1, 'door: 1 board card' );
  $game->flop( [ 'Kc', '2d' ] );
  is( scalar @{ $game->board }, 3, 'flop adds 2' );
  $game->turn('9c');
  $game->river('3s');
  is( scalar @{ $game->board }, 5, 'full board' );
  $game->evaluate($hero);
  like( $hero->name, qr/Two Pair/i, 'Courcheval two pair' );
}

done_testing();
