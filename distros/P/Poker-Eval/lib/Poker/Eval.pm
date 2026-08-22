package Poker::Eval;
our $VERSION = '0.12';

use strict;
use Moo;
use Poker::Hand;
use Poker::Dealer;
use Algorithm::Combinatorics qw(combinations);
use Storable qw(dclone);

=head1 NAME

Poker::Eval - Deal, score, and evaluate poker hands

=head1 VERSION

0.12

=cut

=head1 SYNOPSIS

    use Poker::Game::Holdem;
    use feature qw(say);

    # choose a game
    my $game = Poker::Game::Holdem->new( iterations => 1000 );

    # deal hole cards
    my $hero    = $game->deal_hole(['As', 'Kd']);
    my $villain = $game->deal_hole(['7h', '7c']);
    # OR $game->deal_hole() for random cards;

    # calculate equity for each player
    $game->equity([ $hero, $villain ]);

    # hero has ~45 percent equity 
    say $hero->ev;

    # villain has ~55 percent equity
    say $villain->ev;

    # here comes the flop
    $game->flop(['Ah', 'Kc', '2d']);
    # or $game->flop() for random cards;

    # calculate equity again after the flop
    $game->equity([ $hero, $villain ]);

    # hero now has ~93 percent equity after making two pair
    say $hero->ev;

    # turn and river
    $game->turn('9s'); # deal specific card
    $game->river();    # deal random card

    # see who won and why
    $game->evaluate($hero);
    say $game->board_string;    # Community Cards
    say $hero->name;            # Two Pair
    say $hero->score;           # numerical strength
    say $hero->best_combo_flat; # show cards in human readable form

    # reset board and shuffle deck for the next game
    $game->reset;

=head1 AVAILABLE COMPONENTS

=head2 Games (C<Poker::Game::*>)

   Community  Poker::Game::Holdem
              Poker::Game::HoldemJokersWild
              Poker::Game::Pineapple
              Poker::Game::CrazyPineapple
              Poker::Game::Omaha
              Poker::Game::OmahaHiLo
              Poker::Game::Omaha5
              Poker::Game::Omaha5HiLo
              Poker::Game::Courcheval
              Poker::Game::CourchevalHiLo

   Draw       Poker::Game::FiveCardDraw
              Poker::Game::FiveCardDrawDeucesWild
              Poker::Game::FiveCardDrawJokersWild
              Poker::Game::Low27SingleDraw
              Poker::Game::Low27TripleDraw
              Poker::Game::LowA5SingleDraw
              Poker::Game::LowA5TripleDraw

   Stud       Poker::Game::SevenCardStud
              Poker::Game::SevenCardStudHiLo
              Poker::Game::Razz
              Poker::Game::Stud          (base class)

   Badugi     Poker::Game::Badugi
              Poker::Game::Badacey
              Poker::Game::Badeucy

=head2 Evaluation engines (C<Poker::Eval::*>)

   Poker::Eval::Community   any hole + community (Hold'em-style)
   Poker::Eval::Omaha       exactly 2 hole + 3 community
   Poker::Eval::Wild        wild cards (jokers / deuces, etc.)
   Poker::Eval::Badugi      Badugi selection
   Poker::Eval::Badugi27    Badugi with aces high / 2-7 flavor
   Poker::Eval::HighSuit    high-suit style
   Poker::Eval::BlackMariah Black Mariah

=head2 Scoring systems (C<Poker::Score::*>)

   Poker::Score::High       standard highball
   Poker::Score::Low8       8-or-better low
   Poker::Score::Low27      deuce-to-seven low
   Poker::Score::LowA5      ace-to-five low
   Poker::Score::Badugi     Badugi rank
   Poker::Score::Badugi27   Badugi 2-7 variant
   Poker::Score::HighSuit   high suit

   Poker::Score::Bring::*   bring-in helpers (High, Low, Wild)

C<Poker::Game::*> subclasses wire a specific Eval + Scorer for you.
Advanced use: pair an Eval engine with a Score object yourself.

=head1 SEE ALSO

Poker::Game, Poker::Score 

=head1 ATTRIBUTES

=head2 community_cards

Array ref of Poker::Card objects representing community cards

=cut

has 'community_cards' => (
  is      => 'rw',
  isa     => sub { die "Not an array ref!" unless ref( $_[0] ) eq 'ARRAY' },
  builder => '_build_community_cards',
);

sub _build_community_cards {
  return [];
}

=head2 scorer

Required attribute that identifies the scoring system. Must be a Poker::Score
object.

=cut

has 'scorer' => (
  is  => 'rw',
  isa => sub { die "Not an Score object!" unless $_[0]->isa('Poker::Score') },
);

=head2 dealer

Standard Poker::Dealer (52-card deck by default; pass joker_count for jokers).

=cut

has 'dealer' => (
  is  => 'rw',
  isa => sub { die "Not a Poker::Dealer" unless $_[0]->isa('Poker::Dealer') },
  builder => '_build_dealer',
);

=head2 simulations

Number of simulations for expected win rate (default 100).

=cut

has 'simulations' => (
  is      => 'rw',
  default => sub { 100 },
);

has 'hole_remaining' => (
  is      => 'rw',
  default => sub { 0 },
);

has 'community_remaining' => (
  is      => 'rw',
  default => sub { 0 },
);

sub _build_dealer {
  return Poker::Dealer->new;
}

=head1 METHODS

=head2 best_hand

Returns the best Poker::Hand for the given hole cards under this eval's rules.

=cut

sub best_hand { }

sub flatten {
  my ( $self, $cards ) = @_;
  return join( '', map { $_->rank . $_->suit } @{$cards} );
}

sub community_flat {
  my $self = shift;
  return $self->flatten( $self->community_cards );
}

sub deal {
  my ( $self, $count ) = @_;
  return $self->dealer->deal($count);
}

sub deal_named {
  my ( $self, $cards ) = @_;
  return $self->dealer->deal_named($cards);
}

=head2 calc_ev

Monte-Carlo expected win rate for an array ref of hands. Prefer
C<Poker::Game>'s C<equity> method for the named-game API.

Each simulation awards 1.0 pot unit total. If N hands tie for the best
score, each receives 1/N. Equity is reported as a percentage of
simulations (so the C<ev> values across hands sum to approximately 100).

The dealer's current deck (already missing dealt hole and board cards)
is cloned once; each simulation re-clones and shuffles that residual
pack, then deals C<community_remaining> / C<hole_remaining> from it.

=cut

sub calc_ev {
  my ( $self, $hands ) = @_;
  my $community_orig = dclone( $self->community_cards );

  # Snapshot undealt cards (hole + board already removed via deal_*)
  my $residual = dclone( $self->dealer->deck );

  for ( 1 .. $self->simulations ) {
    $self->dealer->deck( dclone($residual) );
    $self->dealer->shuffle_cards( $self->dealer->deck );

    if ( $self->community_remaining ) {
      $self->community_cards(
        [ @$community_orig, @{ $self->deal( $self->community_remaining ) } ] );
    }
    else {
      $self->community_cards( [@$community_orig] );
    }

    for my $hand (@$hands) {
      my $combo = [ @{ $hand->cards } ];
      if ( $self->hole_remaining ) {
        push @$combo, @{ $self->deal( $self->hole_remaining ) };
      }
      my $best_hand = $self->best_hand($combo);
      $hand->temp_score( $best_hand->score );
    }

    my $top_score = 0;
    for my $hand (@$hands) {
      $top_score = $hand->temp_score if $hand->temp_score > $top_score;
    }
    my @winners = grep { $_->temp_score == $top_score } @$hands;
    my $share   = 1 / scalar @winners;
    for my $hand (@winners) {
      $hand->wins( $hand->wins + $share );
    }
  }

  $self->community_cards($community_orig);

  # Restore undealt pack
  $self->dealer->deck( dclone($residual) );

  my $sims = $self->simulations || 1;
  for my $hand (@$hands) {
    $hand->ev( int( $hand->wins / $sims * 100 + 0.5 ) );
  }
}

sub BUILD {
  my $self = shift;
  $self->dealer->shuffle_deck;
}

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2026 Nathaniel Graham.

=cut

1;
