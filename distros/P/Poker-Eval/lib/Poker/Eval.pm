package Poker::Eval;
use strict;
use Moo;
use Poker::Hand;
use Poker::Dealer;
use Algorithm::Combinatorics qw(combinations);
use Storable qw(dclone);

=head1 NAME

Poker::Eval - Deal, score, and calculate expected win rates of poker hands. Base class for specific game types. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

    This is just a base class. Poker::Eval::Omaha shows a real example.

    use Poker::Eval::Omaha; # Omaha style rules
    use Poker::Score::High; # Highball scoring system
    use feature qw(say);

    # Object to represent a typical post flop situation
    my $ev = Poker::Eval::Omaha->new(
      scorer => Poker::Score::High->new,
      hole_remaining => 0, # hole cards already dealt
      community_remaining => 2, # turn and river yet to come
    );

    # shuffle deck
    $ev->dealer->shuffle_deck;

    # deal three community cards (post flop) 
    $ev->community_cards( $ev->deal_named(['5c','9h','Ks']));

    # deal and score three separate hands 
    my $hand1 = $ev->best_hand($ev->deal_named(['Ts','Js','3d','4d']));
    my $hand2 = $ev->best_hand($ev->deal_named(['5h','5s','6s','7s']));
    my $hand3 = $ev->best_hand($ev->deal(4)); # random cards

    # best combination (hole + community) in human-readable form
    say $hand1->best_combo_flat;

    # english name of best combination (e.g. 'Two Pair')
    say $hand1->name;

    # numerical score of best combination
    say $hand1->score;

    # hole cards in human-readable form
    say $hand1->cards_flat;

    # calculate expected win rate of each hand
    $ev->calc_ev([$hand1, $hand2, $hand3]);

    # expected win rate of each hand (as percent)
    say $hand1->ev; say $hand2->ev; say $hand3->ev;

    # hands 1, 2 and 3 win 13, 76, and 11 percent of the time respectively.

=head1 INTRODUCTION

Poker::Eval defines rules for evaluating poker hands. In Holdem for example, any combination of hole and community cards can be used to make the best hand, so Poker::Eval::Community is the correct subclass. But in Omaha, your best hand is made using EXACTLY two hole cards and EXACTLY three community cards, so Poker::Eval::Omaha is what you want. Other subclasses include Badugi, Chinese, and Wild.

Poker::Eval also provides methods for calculating expected win rates in specific situations.   
Poker::Score defines the scoring systme itself (e.g.,  highball, lowball 8 or better, lowball 2-7, lowball A-5, badugi, etc) See Poker::Score for a complete list.   

=head1 SEE ALSO

Poker::Eval::Community, Poker::Eval::Omaha, Poker::Eval::Wild, Poker::Eval::Badugi, Poker::Eval::Chinese, Poker::Eval::BlackMariah, Poker::Eval::Badugi27, Poker::Score, Poker::Dealer

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
object.  See Poker::Score for available options.

=cut

has 'scorer' => (
  is  => 'rw',
  isa => sub { die "Not an Score object!" unless $_[0]->isa('Poker::Score') },
);

=head2 dealer

Standard Poker::Dealer created by default (52 card deck with no wildcards). See Poker::Dealer for options.

=cut

has 'dealer' => (
  is  => 'rw',
  isa => sub { die "Not a Poker::Dealer" unless $_[0]->isa('Poker::Dealer') },
  builder => '_build_dealer',
);

=head2 simulations

Number of simulations to run when calculating expected win rate. A high number gives you a better estimate, but also take longer. 100 is the default.

=cut

has 'simulations' => (
  is      => 'rw',
  default => sub { 100 },
);

=head2 hole_remaining

Number of hole cards remaining to be dealt in the game.

=cut

has 'hole_remaining' => (
  is      => 'rw',
  default => sub { 0 },
);

=head2 community_remaining

Number of community cards remaining to be dealt in the game.

=cut

has 'community_remaining' => (
  is      => 'rw',
  default => sub { 0 },
);

sub _build_dealer {
  return Poker::Dealer->new;
}

=head1 METHODS

=head2 best_hand

Returns the best Poker::Hand you can make. See Poker::Hand

=cut

sub best_hand { }

sub flatten {
  my ( $self, $cards ) = @_;
  return join( '', map { $_->rank . $_->suit } @{$cards} );
}

=head2 community_flat

Community cards in human-readable form.

=cut

sub community_flat {
  my $self = shift;
  return $self->flatten( $self->community_cards );
}

=head2 deal

Alias for dealer->deal. See Poker::Dealer

=cut


sub deal {
  my ( $self, $count ) = @_;
  return $self->dealer->deal($count);
}

=head2 deal_named

Alias for dealer->deal_named. See Poker::Dealer

=cut

sub deal_named {
  my ( $self, $cards ) = @_;
  return $self->dealer->deal_named($cards);
}

=head2 calc_ev

Takes an array ref of Poker::Hands and calculates the expected win rate for each.

=cut

sub calc_ev {
  my ( $self, $hands ) = @_;
  my $community_orig = dclone( $self->community_cards );
  for ( 1 .. $self->simulations ) {
    $self->dealer->shuffle_deck;
    if ( $self->community_remaining ) {
      $self->community_cards(
        [ @$community_orig, @{ $self->deal( $self->community_remaining ) } ] );
    }
    for my $hand (@$hands) {
      my $combo =
        [ @{ $hand->cards }, @{ $self->deal( $self->hole_remaining ) } ];

      my $best_hand = $self->best_hand($combo);
      $hand->temp_score( $best_hand->score );
    }

    my @scores =
      map { $_->temp_score } sort { $a->temp_score <=> $b->temp_score } @$hands;
    my $top_score = pop @scores;
    for my $hand (@$hands) {
      $hand->wins( $hand->wins + 1 ) if $hand->temp_score == $top_score;
    }
  }
  my $total_wins = 0;
  for my $hand (@$hands) {
    $total_wins += $hand->wins;
  }
  for my $hand (@$hands) {
    $hand->ev( int( $hand->wins / $total_wins * 100 ) );
  }
}

sub BUILD {
  my $self = shift;
  $self->dealer->shuffle_deck;
}

=head1 BUGS

Probably.  Only developer tested so far.

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
