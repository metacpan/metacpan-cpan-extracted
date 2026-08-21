use strict;
use warnings;
use Test::More;
use Poker::Game::Badugi;
use Poker::Game::Badacey;
use Poker::Game::Badeucy;

# Perfect Badugi A-2-3-4 rainbow
{
  my $game = Poker::Game::Badugi->new;
  is( $game->hole_count, 4, 'Badugi 4 hole' );
  is( $game->draws_left, 3, 'Badugi triple draw' );

  my $hero = $game->deal_hole( [ 'As', '2d', '3c', '4h' ] );
  $game->evaluate($hero);
  ok( $hero->score > 0, 'Badugi scores' );
  like( $hero->name // '', qr/4 card/i, '4 card Badugi' );
}

# Discard/draw still works
{
  my $game = Poker::Game::Badugi->new;
  my $hero = $game->deal_hole( [ 'As', '2d', '3c', '3h' ] );
  $game->discard( $hero, '3h' );
  $game->draw( $hero, ['4h'] );
  is( scalar @{ $hero->cards }, 4, '4 cards after draw' );
  $game->evaluate($hero);
  like( $hero->name // '', qr/4 card/i, 'made 4-card after draw' );
}

# Badacey: badugi + A5 low
{
  my $game = Poker::Game::Badacey->new;
  is( $game->hole_count, 5, 'Badacey 5 hole' );
  my $hero = $game->deal_hole( [ 'As', '2d', '3c', '4h', '5s' ] );
  $game->evaluate($hero);
  ok( $hero->score > 0, 'Badacey badugi score' );
  ok( defined $hero->low_score && $hero->low_score > 0,
    'Badacey A5 low score' );
}

# Badeucy: badugi27 + 27 low
{
  my $game = Poker::Game::Badeucy->new;
  my $hero = $game->deal_hole( [ '2s', '3d', '4c', '5h', '7c' ] );
  $game->evaluate($hero);
  ok( $hero->score > 0, 'Badeucy badugi27 score' );
  ok( defined $hero->low_score && $hero->low_score > 0,
    'Badeucy 27 low score' );
}

done_testing();
