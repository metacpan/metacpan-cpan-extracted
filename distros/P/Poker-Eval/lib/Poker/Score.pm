package Poker::Score;
use strict;
use warnings FATAL => 'all';
use Moo;

=head1 NAME

Poker::Score - Identify and score specific poker hands. Base class for specific scoring systems. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS
 
    # This is just a base class. Poker::Score::High shows a real example.

    use Poker::Score::High; #standard highball
    use Poker::Dealer;
    use feature qw(say);

    # Create highball score object
    my $scorer = Poker::Score::High->new;

    # Create dealer, shuffle deck and deal out five cards
    my $dealer = Poker::Dealer->new;
    $dealer->shuffle_deck;
    my $cards = $dealer->deal_up(5);

    # Numerical score of five card poker hand
    my $score = $scorer->score($cards);
    say $score;

    # English name of hand (e.g. 'Two Pair')
    say $scorer->hand_name($score);

=cut


has 'hands' => (
  is  => 'rw',
  isa => sub { die "Not an array_ref!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has '_hand_lookup' => (
  is       => 'rw',
  isa      => sub { die "Not an hash_ref!" unless ref( $_[0] ) eq 'HASH' },
  init_arg => undef,
);

has '_hand_map' => (
  is  => 'rw',
  isa => sub { die "Not an hash_ref!" unless ref( $_[0] ) eq 'HASH' },
  default => sub { {} },
);

has '_rank_map' => (
  is  => 'rw',
  isa => sub { die "Not an hash_ref!" unless ref( $_[0] ) eq 'HASH' },
);

sub _build_rank_map {
  my $self = shift;
  $self->_rank_map(
    {
      '2' => '02',
      '3' => '03',
      '4' => '04',
      '5' => '05',
      '6' => '06',
      '7' => '07',
      '8' => '08',
      '9' => '09',
      'T' => '10',
      'J' => '11',
      'Q' => '12',
      'K' => '13',
      'A' => '14',
    }
  );
}

has '_suit_map' => (
  is  => 'rw',
  isa => sub { die "Not an hash_ref!" unless ref( $_[0] ) eq 'HASH' },
);

sub _build_suit_map {
  my $self = shift;
  $self->_suit_map(
    {
      'c' => '01',
      'd' => '02',
      'h' => '03',
      's' => '04',
    }
  );
}

=head1 METHODS

=head2 hand_name

English name of given hand (e.g., 'Two Pair')

=cut

sub hand_name {
  my ( $self, $score ) = @_;
  for my $key ( sort { $b <=> $a } keys %{ $self->_hand_map } ) {
    if ( $score > $key ) {
      return $self->_hand_map->{$key};
    }
  }
}

sub rank_val {
  my ( $self, $rank ) = @_;
  return $self->_rank_map->{$rank};
}

sub suit_val {
  my ( $self, $suit ) = @_;
  return $self->_suit_map->{$suit};
}

sub hand_score {
  my ( $self, $hand ) = @_;
  return $self->_hand_lookup->{$hand};
}

=head2 score

Numercal score of given hand (higher is better)

=cut

sub score {
  my ( $self, $cards ) = @_;
  return $self->hand_score( $self->stringify_cards($cards) );
}

sub stringify_cards {
  my ( $self, $cards ) = @_;
  my %suit;
  for my $card (@$cards) {
    $suit{ $card->suit }++;
  }
  my $flat = join( '',
    sort { $b <=> $a }
    map { sprintf( "%02d", $self->rank_val( $_->rank ) ) } @$cards );
  $flat .= 's' if scalar keys %suit == 1;
  return $flat;
}

sub _build_hand_lookup {
  my $self = shift;
  my %look;
  for my $i ( 0 .. $#{ $self->hands } ) {
    $look{ $self->hands->[$i] } = $i;
  }
  $self->_hand_lookup( \%look );
}

sub _build_hands { }

sub BUILD {
  my $self = shift;
  $self->_build_hands;
  $self->_build_hand_lookup;
  $self->_build_rank_map;
  $self->_build_suit_map;
}

=head1 SEE ALSO

Poker::Score::High, Poker::Score::Low8, Poker::Score::Low27, Poker::Score::LowA5, Poker::Score::Badugi, Poker::Score::Badugi27, Poker::Score::Chinese, Poker::Score::HighSuit, Poker::Score::Bring::High, Poker::Score::Bring::Low, Poker::Score::Bring::Wild

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
