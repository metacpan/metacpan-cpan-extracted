use strict;
use warnings;
use Test::More;
use Poker::Hand;
use Poker::Game::SevenCardStud;
use Poker::Game::SevenCardStudHiLo;
use Poker::Game::Razz;

# Seven-card stud high — street by street
{
  my $game = Poker::Game::SevenCardStud->new;
  is( $game->board_size, 0, 'stud has no board' );
  is( $game->hole_count, 7, 'stud hole_count 7' );

  my $hero = Poker::Hand->new( cards => [] );
  $game->third_street( $hero, [ 'As', 'Kd', '7c' ] );
  is( scalar @{ $hero->cards }, 3, 'third street: 3 cards' );

  $game->fourth_street( $hero, 'Ah' );
  $game->fifth_street( $hero,  'Kc' );
  $game->sixth_street( $hero,  '2d' );
  $game->seventh_street( $hero, '9s' );
  is( scalar @{ $hero->cards }, 7, 'seven cards' );

  $game->evaluate($hero);
  like( $hero->name, qr/Two Pair/i, 'stud two pair' );
}

# deal_hole with full 7 cards
{
  my $game = Poker::Game::SevenCardStud->new;
  my $hero = $game->deal_hole(
    [ 'As', 'Ad', 'Ah', 'Kc', 'Kd', '2c', '3d' ] );
  is( scalar @{ $hero->cards }, 7, 'deal_hole 7' );
  $game->evaluate($hero);
  like( $hero->name, qr/Three|Full/i, 'trips or full house' );
}

# Stud hi-lo with qualifying low
{
  my $game = Poker::Game::SevenCardStudHiLo->new;
  my $hero = $game->deal_hole(
    [ 'As', '2d', '3c', '4h', '5s', 'Kc', 'Kd' ] );
  $game->evaluate($hero);
  ok( $hero->score > 0, 'stud hi-lo high score' );
  ok( defined $hero->low_score && $hero->low_score > 0,
    'stud hi-lo low qualifies' );
}

# Razz
{
  my $game = Poker::Game::Razz->new;
  my $hero = $game->deal_hole(
    [ 'As', '2d', '3c', '4h', '5s', '9c', 'Kd' ] );
  $game->evaluate($hero);
  ok( $hero->score > 0, 'razz scores' );
  ok( $hero->name, 'razz has name' );
}

# Street size guard
{
  my $game = Poker::Game::SevenCardStud->new;
  my $hero = Poker::Hand->new( cards => [] );
  $game->third_street( $hero, [ 'As', 'Kd', '7c' ] );
  eval { $game->fifth_street( $hero, 'Ah' ) };
  ok( $@, 'fifth street dies out of order' );
}

done_testing();
