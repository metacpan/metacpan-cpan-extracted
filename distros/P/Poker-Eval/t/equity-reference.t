use strict;
use warnings;
use Test::More;
use Poker::Game::Holdem;

# Reference equities are approximate published Hold'em values (ProPokerTools /
# Equilab / common poker literature). Monte Carlo with a few thousand trials
# should land within a few points.

sub within {
  my ( $got, $expect, $tol, $label ) = @_;
  ok( abs( $got - $expect ) <= $tol,
    sprintf( '%s: got %s, expected %s +/- %s', $label, $got, $expect, $tol ) );
}

sub sum_ok {
  my ( $a, $b, $label ) = @_;
  my $sum = $a + $b;
  ok( $sum >= 99 && $sum <= 101, "$label sum ~100 (got $sum)" );
}

# AA vs KK preflop ~ 81.9% / 18.1%
{
  my $game = Poker::Game::Holdem->new( iterations => 3000 );
  my $aa = $game->deal_hole( [ 'As', 'Ad' ] );
  my $kk = $game->deal_hole( [ 'Ks', 'Kd' ] );
  $game->equity( [ $aa, $kk ] );
  sum_ok( $aa->ev, $kk->ev, 'AA vs KK' );
  within( $aa->ev, 82, 4, 'AA vs KK (AA)' );
  within( $kk->ev, 18, 4, 'AA vs KK (KK)' );
}

# AA vs 72o preflop ~ 87% / 13%
{
  my $game = Poker::Game::Holdem->new( iterations => 2500 );
  my $aa = $game->deal_hole( [ 'As', 'Ad' ] );
  my $x  = $game->deal_hole( [ '7h', '2c' ] );
  $game->equity( [ $aa, $x ] );
  sum_ok( $aa->ev, $x->ev, 'AA vs 72o' );
  within( $aa->ev, 87, 4, 'AA vs 72o (AA)' );
  within( $x->ev,  13, 4, 'AA vs 72o (72o)' );
}

# QQ vs AKs preflop ~ 55% / 45% (pair vs overcards)
{
  my $game = Poker::Game::Holdem->new( iterations => 3000 );
  my $qq = $game->deal_hole( [ 'Qs', 'Qd' ] );
  my $ak = $game->deal_hole( [ 'As', 'Ks' ] );
  $game->equity( [ $qq, $ak ] );
  sum_ok( $qq->ev, $ak->ev, 'QQ vs AKs' );
  within( $qq->ev, 55, 4, 'QQ vs AKs (QQ)' );
  within( $ak->ev, 45, 4, 'QQ vs AKs (AKs)' );
}

# JJ vs 99 preflop ~ 81% / 19%
{
  my $game = Poker::Game::Holdem->new( iterations => 2500 );
  my $jj = $game->deal_hole( [ 'Js', 'Jd' ] );
  my $nn = $game->deal_hole( [ '9s', '9d' ] );
  $game->equity( [ $jj, $nn ] );
  sum_ok( $jj->ev, $nn->ev, 'JJ vs 99' );
  within( $jj->ev, 81, 4, 'JJ vs 99 (JJ)' );
  within( $nn->ev, 19, 4, 'JJ vs 99 (99)' );
}

# Postflop: AA vs KK on dry A-high flop -- AA nearly locked
# Board Ah 7c 2d: AA has top set, KK needs running kings or exact miracle
{
  my $game = Poker::Game::Holdem->new( iterations => 2000 );
  my $aa = $game->deal_hole( [ 'As', 'Ad' ] );
  my $kk = $game->deal_hole( [ 'Ks', 'Kd' ] );
  $game->flop( [ 'Ah', '7c', '2d' ] );
  $game->equity( [ $aa, $kk ] );
  sum_ok( $aa->ev, $kk->ev, 'AA vs KK on A72' );
  ok( $aa->ev >= 95, 'AA set vs KK on A72 is >= 95%' );
  ok( $kk->ev <= 5,  'KK <= 5% on A72 vs AA' );
}

done_testing();
