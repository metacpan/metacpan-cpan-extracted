use strict;
use warnings;
use Test::More;
use Poker::Deck;
use Poker::Dealer;
use Poker::Game::FiveCardDrawJokersWild;
use Poker::Game::HoldemJokersWild;

# Deck size
{
  my $d0 = Poker::Deck->new;
  is( $d0->cards->Length, 52, 'default deck 52' );

  my $d2 = Poker::Deck->new( joker_count => 2 );
  is( $d2->cards->Length, 54, 'deck with 2 jokers is 54' );
  ok( $d2->cards->FETCH('Jo1')->is_wild, 'Jo1 is wild' );
  ok( $d2->cards->FETCH('Jo2')->is_wild, 'Jo2 is wild' );
}

# Dealer can deal named jokers
{
  my $dealer = Poker::Dealer->new( joker_count => 2 );
  $dealer->shuffle_deck;
  my $cards = $dealer->deal_named( ['Jo1', 'As'] );
  is( scalar @$cards, 2, 'dealt joker + ace' );
  ok( $cards->[0]->is_wild, 'dealt joker is wild' );
}

# Five-card draw jokers wild
{
  my $game = Poker::Game::FiveCardDrawJokersWild->new;
  my $hero = $game->deal_hole( [ 'As', 'Ad', 'Ah', 'Jo1', '2c' ] );
  my $wilds = grep { $_->is_wild } @{ $hero->cards };
  is( $wilds, 1, 'one joker in hand' );
  $game->evaluate($hero);
  ok( $hero->score > 0, 'jokers wild draw scores' );
  # Four aces via joker as fourth ace — should be four of a kind or better
  like( $hero->name // '', qr/Four|Five/i, 'joker promotes to quads+' );
}

# Holdem jokers wild
{
  my $game = Poker::Game::HoldemJokersWild->new;
  my $hero = $game->deal_hole( [ 'As', 'Jo1' ] );
  $game->flop( [ 'Ah', 'Kc', '2d' ] );
  $game->turn('9s');
  $game->river('3c');
  $game->evaluate($hero);
  ok( $hero->score > 0, 'holdem jokers wild scores' );
  like( $hero->name // '', qr/Pair|Three|Two/i, 'has a made hand with joker' );
}

done_testing();
