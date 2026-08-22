package Poker::Game;
our $VERSION = '0.12';


use strict;
use warnings FATAL => 'all';
use Moo;
use Poker::Dealer;
use Poker::Hand;

=head1 NAME

Poker::Game - Base class for named poker variants

=head1 SYNOPSIS

    use Poker::Game::Holdem;
    use feature qw(say);

    # choose a game
    my $game = Poker::Game::Holdem->new( iterations => 1000 );

    # deal hole cards
    my $hero    = $game->deal_hole(['As', 'Kd']);
    my $villain = $game->deal_hole(['7h', '7c']);
    # or $game->deal_hole() for random cards;

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
    say $game->board_string;    # AsKdAhKc9d
    say $hero->name;            # Two Pair
    say $hero->score;           # numerical strength
    say $hero->best_combo_flat; # show cards in human readable form

    # reset board and shuffle deck for the next game
    $game->reset;

=head1 DESCRIPTION

For a full list of games, eval engines, and scorers, see
L<Poker::Eval/AVAILABLE COMPONENTS>.

=head1 EQUITY

B<Equity> is the estimated share of the pot a hand wins if the remaining
board is completed many times at random from the undealt cards.

Each simulation awards 1.0 pot unit in total:

=over 4

=item * Sole winner: that hand receives 1.0

=item * N hands tied for best: each receives 1/N

=back

=head1 ATTRIBUTES

=over 4

=item hole_count

How many hole cards each player is dealt (set by the subclass).

=item board_size

Number of community cards (0 for draw/stud/Badugi).

=item iterations

Monte Carlo sample size for C<equity> (default 1000).

=item max_draw_rounds / draws_left

Draw-game discard rounds allowed / remaining.

=item pending_discards / pending_draws

Phase flags. Crazy Pineapple sets C<pending_discards> after the flop
until each player discards; draw games set C<pending_draws> after
C<discard> until C<draw>.

=back

=cut

has 'hole_count' => (
  is      => 'ro',
  default => sub { 2 },
);

has 'board_size' => (
  is      => 'ro',
  default => sub { 5 },
);

has 'iterations' => (
  is      => 'rw',
  default => sub { 1000 },
);

has 'max_draw_rounds' => (
  is      => 'ro',
  default => sub { 0 },
);

has 'draws_left' => (
  is      => 'rw',
  default => sub { 0 },
);

has 'eval_engine' => (
  is       => 'ro',
  required => 1,
  isa      => sub {
    die "eval_engine must be a Poker::Eval"
      unless $_[0]->isa('Poker::Eval');
  },
);

has 'scorer' => (
  is       => 'ro',
  required => 1,
  isa      => sub {
    die "scorer must be a Poker::Score"
      unless $_[0]->isa('Poker::Score');
  },
);

has 'dealer' => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_dealer',
  isa     => sub {
    die "Not a Poker::Dealer" unless $_[0]->isa('Poker::Dealer');
  },
);

sub _build_dealer {
  my $self = shift;
  return $self->eval_engine->dealer;
}

has 'board' => (
  is      => 'rw',
  default => sub { [] },
  isa     => sub { die "Not an array ref" unless ref( $_[0] ) eq 'ARRAY' },
);

has 'pending_discards' => (
  is      => 'rw',
  default => sub { 0 },
);

has 'pending_draws' => (
  is      => 'rw',
  default => sub { 0 },
);

sub BUILD {
  my $self = shift;
  $self->eval_engine->scorer( $self->scorer )
    unless $self->eval_engine->scorer;
  $self->eval_engine->community_cards( $self->board );
  $self->draws_left( $self->max_draw_rounds );
  $self->dealer->shuffle_deck;
}

sub _assert_no_pending_actions {
  my $self = shift;
  die "cannot deal board while discards are pending"
    if $self->pending_discards;
  die "cannot deal board while draws are pending"
    if $self->pending_draws;
}

=head1 METHODS

=head2 deal_hole

    my $hand = $game->deal_hole;              # random hole_count cards
    my $hand = $game->deal_hole(2);           # random N cards
    my $hand = $game->deal_hole(['As','Kd']); # specific cards

Returns a C<Poker::Hand>.

=cut

sub deal_hole {
  my ( $self, $arg ) = @_;
  my $cards;
  if ( ref $arg eq 'ARRAY' ) {
    $cards = $self->deal_cards($arg);
  }
  else {
    my $n = defined $arg ? $arg : $self->hole_count;
    $cards = $self->dealer->deal($n);
  }
  return Poker::Hand->new( cards => $cards );
}

=head2 deal_cards

    my $cards = $game->deal_cards(['As', 'Kd']);

Remove specific cards from the deck by name. Jokers are C<Jo1>, C<Jo2>, ...

=cut

sub deal_cards {
  my ( $self, $names ) = @_;
  return $self->dealer->deal_named($names);
}

=head2 board_string

Community cards as a flat string (e.g. C<Ah7c2d>).

=cut

sub board_string {
  my $self = shift;
  return join '', map { $_->rank . $_->suit } @{ $self->board };
}

=head2 flop / turn / river

    $game->flop(['Ah','7c','2d']);  # or random if omitted
    $game->turn('9s');
    $game->river('3c');

Deal the next community street. C<turn> and C<river> die if discards or
draws are still pending (e.g. Crazy Pineapple before the mandatory discard).

=cut

sub flop {
  my ( $self, $cards ) = @_;
  die "flop requires an empty board" if @{ $self->board };
  return $self->_deal_street( 3, $cards );
}

sub turn {
  my ( $self, $cards ) = @_;
  $self->_assert_no_pending_actions;
  die "turn requires exactly 3 board cards"
    unless @{ $self->board } == 3;
  return $self->_deal_street( 1, $cards );
}

sub river {
  my ( $self, $cards ) = @_;
  $self->_assert_no_pending_actions;
  die "river requires exactly 4 board cards"
    unless @{ $self->board } == 4;
  return $self->_deal_street( 1, $cards );
}

sub _normalize_cards {
  my ( $self, $count, $specific ) = @_;
  return undef unless defined $specific;
  if ( ref $specific eq 'ARRAY' ) {
    return $specific;
  }
  return [$specific];
}

sub _deal_street {
  my ( $self, $count, $specific ) = @_;
  my $cards = $self->_normalize_cards( $count, $specific );
  my $new;
  if ($cards) {
    die "expected $count cards" unless @$cards == $count;
    $new = $self->deal_cards($cards);
  }
  else {
    $new = $self->dealer->deal($count);
  }
  push @{ $self->board }, @$new;
  $self->eval_engine->community_cards( $self->board );
  return $self->board;
}

=head2 can_runout

True when the game uses community cards, the board is incomplete, and no
discards/draws are pending.

=cut

sub can_runout {
  my $self = shift;
  return 0 unless $self->board_size > 0;
  return 0 if @{ $self->board } >= $self->board_size;
  return 0 if $self->pending_discards;
  return 0 if $self->pending_draws;
  return 1;
}

=head2 runout

    $game->runout;                    # random remaining board
    $game->runout(['9s','3c']);       # specific cards

Deal all remaining community cards. Dies unless C<can_runout> is true.

=cut

sub runout {
  my ( $self, $specific ) = @_;
  die "runout not legal in current state" unless $self->can_runout;
  my $need = $self->board_size - @{ $self->board };
  my $cards = $self->_normalize_cards( $need, $specific );
  if ($cards) {
    die "expected $need cards" unless @$cards == $need;
    push @{ $self->board }, @{ $self->deal_cards($cards) };
  }
  else {
    push @{ $self->board }, @{ $self->dealer->deal($need) };
  }
  $self->eval_engine->community_cards( $self->board );
  return $self->board;
}

=head2 discard

    $game->discard($hand, '7c');
    $game->discard($hand, ['7c', '2h']);

Remove one or more hole cards from C<$hand>.

B<Draw games:> sets C<pending_draws> so C<draw> is expected next, and
decrements toward C<max_draw_rounds>.

B<Crazy Pineapple:> after the flop each player must discard exactly one
hole card (clearing C<pending_discards>) before C<turn> / C<river> are
allowed. That path does not use C<draw>.

=cut

sub discard {
  my ( $self, $hand, $which ) = @_;
  die "discard requires a Poker::Hand"
    unless $hand && $hand->isa('Poker::Hand');
  die "no draws left" if $self->max_draw_rounds && $self->draws_left <= 0;

  my @names =
      ref $which eq 'ARRAY' ? @$which
    : defined $which        ? ($which)
    :                         die "discard requires a card or list";

  my %want = map { $_ => 1 } @names;
  my @keep;
  my @removed;
  for my $card ( @{ $hand->cards } ) {
    my $name = $card->rank . $card->suit;
    if ( $want{$name} ) {
      push @removed, $card;
      delete $want{$name};
    }
    else {
      push @keep, $card;
    }
  }
  die "card(s) not found in hand: " . join( ',', keys %want ) if keys %want;

  $hand->cards( \@keep );
  $self->pending_draws(1) if $self->max_draw_rounds;
  return \@removed;
}

=head2 draw

    $game->draw($hand);              # random refill to hole_count
    $game->draw($hand, ['As','Kd']); # specific replacements

Replace discarded cards up to C<hole_count>. Decrements C<draws_left>.
Used by five-card draw and lowball draw games, not by Crazy Pineapple.

=cut

sub draw {
  my ( $self, $hand, $specific ) = @_;
  die "draw requires a Poker::Hand"
    unless $hand && $hand->isa('Poker::Hand');
  die "draw not pending" unless $self->pending_draws || !$self->max_draw_rounds;
  die "no draws left" if $self->max_draw_rounds && $self->draws_left <= 0;

  my $need = $self->hole_count - @{ $hand->cards };
  die "hand already has hole_count cards" if $need <= 0;

  my $new;
  if ( defined $specific ) {
    my $cards = $self->_normalize_cards( $need, $specific );
    die "expected $need cards" unless @$cards == $need;
    $new = $self->deal_cards($cards);
  }
  else {
    $new = $self->dealer->deal($need);
  }
  push @{ $hand->cards }, @$new;
  $self->pending_draws(0);
  $self->draws_left( $self->draws_left - 1 ) if $self->max_draw_rounds;
  return $hand;
}

=head2 evaluate

    $game->evaluate($hand);
    my $result = $game->evaluate(['As','Kd']);  # or raw card list

Score the best hand under this game's rules. On a C<Poker::Hand>, sets:

=over 4

=item * C<score> -- numerical strength for this ranking system (higher is better within that system)

=item * C<name> -- English label (e.g. C<Two Pair>)

=item * C<best_combo> -- cards used

=item * C<low_score>, C<low_name>, C<low_combo> -- hi-lo games only, when the hand qualifies for low

=back

=cut

sub evaluate {
  my ( $self, $arg ) = @_;
  my $hole =
    ref $arg eq 'ARRAY' ? $arg
    : $arg->isa('Poker::Hand') ? $arg->cards
    : die "evaluate requires a Poker::Hand or array ref of cards";

  $self->eval_engine->community_cards( $self->board );
  my $result = $self->eval_engine->best_hand($hole);

  if ( ref $arg && $arg->isa('Poker::Hand') ) {
    $arg->score( $result->score );
    $arg->name( $result->name );
    $arg->best_combo( $result->best_combo );
    return $arg;
  }
  return $result;
}

=head2 equity

    $game->equity([ $hand1, $hand2, ... ]);

Monte Carlo equity from the current board state. Sets C<< $hand->ev >>
on each hand (see L</EQUITY>). Alias: C<calc_ev>.

=cut

sub equity {
  my ( $self, $hands ) = @_;
  die "equity requires an array ref of hands"
    unless ref $hands eq 'ARRAY';

  my $engine = $self->eval_engine;
  $engine->community_cards( $self->board );
  $engine->community_remaining(
    $self->board_size > 0
    ? $self->board_size - @{ $self->board }
    : 0
  );
  $engine->hole_remaining(0);
  $engine->simulations( $self->iterations );

  for my $h (@$hands) {
    $h->wins(0);
    $h->ev(0);
  }

  $engine->calc_ev($hands);
  return $hands;
}

sub calc_ev { shift->equity(@_) }

=head2 reset

Reset board and shuffle a fresh deck

=cut

sub reset {
  my $self = shift;
  $self->board( [] );
  $self->pending_discards(0);
  $self->pending_draws(0);
  $self->draws_left( $self->max_draw_rounds );
  $self->eval_engine->community_cards( [] );
  $self->dealer->shuffle_deck;
  return $self;
}

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016-2026 Nathaniel Graham.

=cut

1;
