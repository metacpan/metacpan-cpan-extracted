package Poker::Eval;

our $VERSION = '0.11';
use strict;
use Moo;
use Poker::Hand;
use Poker::Dealer;
use Algorithm::Combinatorics qw(combinations);
use Storable qw(dclone);

=head1 NAME

Poker::Eval - Deal, score, and evaluate poker hands

=head1 VERSION

0.11

=cut


=head1 SYNOPSIS

Preferred interface -- named games:

    use Poker::Game::Holdem;
    use feature qw(say);

    my $game = Poker::Game::Holdem->new( iterations => 1000 );
    my $hero    = $game->deal_hole(['As', 'Kd']);
    my $villain = $game->deal_hole(['7h', '7c']);

    $game->flop(['Ah', 'Kc', '2d']);
    $game->turn('9s');
    $game->river('3c');

    $game->evaluate($hero);
    say $hero->name;          # Two Pair
    say $hero->score;         # numerical strength
    say $hero->best_combo_flat;

    $game->reset;
    $hero    = $game->deal_hole(['As', 'Kd']);
    $villain = $game->deal_hole(['7h', '7c']);
    $game->equity([ $hero, $villain ]);
    say $hero->ev;

Advanced -- compose rules and scoring yourself:

    use Poker::Eval::Omaha;
    use Poker::Score::High;

    my $ev = Poker::Eval::Omaha->new(
      scorer => Poker::Score::High->new,
      community_remaining => 2,
    );

=head1 DESCRIPTION

B<Poker::Game::*> modules are the primary API (Hold'em, Omaha, draw,
stud, Badugi, etc.). They wire hole/board counts to the correct
C<Poker::Eval> and C<Poker::Score> engines.

C<Poker::Eval> remains the rules engine base class (how hole and
community cards combine). C<Poker::Score> defines ranking systems
(highball, lowball, Badugi, ...).

Only this module defines C<$VERSION> for the distribution; other
packages intentionally omit it so PAUSE indexes a single release.

=head1 SEE ALSO

Poker::Game::Holdem, Poker::Game::Omaha, Poker::Game::FiveCardDraw,
Poker::Game::SevenCardStud, Poker::Game::Badugi, Poker::Score,
Poker::Dealer

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
score, each receives C<1/N>. Equity is reported as a percentage of
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
