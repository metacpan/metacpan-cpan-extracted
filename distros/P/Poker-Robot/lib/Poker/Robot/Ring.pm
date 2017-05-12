package Poker::Robot::Ring;
use Moo;

=encoding utf8

=head1 NAME

Poker::Robot::Ring - Simple class to represent a poker table. Used internally by Poker::Robot.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

has 'table_min' => ( is => 'rw', );
has 'table_max' => ( is => 'rw', );
has 'bring' => ( is => 'rw', );

has 'class' => ( is => 'rw', );
has 'min_draws' => ( is => 'rw', );
has 'max_draws' => ( is => 'rw', );
has 'min_discards' => ( is => 'rw', );
has 'max_discards' => ( is => 'rw', );

has 'table_id' => (
  is      => 'rw',
);

has 'director_id' => (
  is      => 'rw',
);

has 'time_bank' => (
  is      => 'rw',
);

has 'chair_count' => (
  is => 'rw',
);

has 'player_count' => (
  is => 'rw',
);

has 'pot_cap' => ( 
  is => 'rw', 
);

has 'limit' => (
  is      => 'rw',
);

has 'fix_limit' => (
  is => 'rw',
);

has 'max_raise' => (
  is => 'rw',
);

has 'small_bet' => (
  is => 'rw',
);

has 'max_bet' => (
  is => 'rw',
);

has 'turn_clock' => (
  is      => 'rw',
);

has 'game_choice' => (
  is      => 'rw',
);

has 'dealer_choices' => (
  is      => 'rw',
  isa     => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has 'valid_act' => (
  is      => 'rw',
  isa     => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has 'community_cards' => (
  is      => 'rw',
  isa     => sub { die "Not an array!" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has 'chairs' => (
  is  => 'rw',
  isa => sub { die "Not an array.\n" unless ref( $_[0] ) eq 'ARRAY' },
  default => sub { [] },
);

has 'round' => (
  is      => 'rw',
);

has 'pot' => (
  is      => 'rw',
  default => sub { return 0 },
);

has 'last_bet' => (
  is      => 'rw',
  default => sub { return 0 },
);

has 'game_count' => (    # Bool
  is      => 'rw',
  default => sub { return 0 },
);

has 'action' => (
  is      => 'rw',
);

has 'button' => (
  is      => 'rw',
);

has 'ante' => (
  is      => 'rw',
);

has 'big_blind' => (
  is      => 'rw',
);

has 'small_blind' => (
  is      => 'rw',
);

has 'last_act' => ( is => 'rw', );

has 'game_over' => (    # Bool
  is      => 'rw',
);

has 'call_amt' => (
  is => 'rw',
);

has 'bet_size' => (
  is => 'rw',
);

has 'card_select' => (
  is => 'rw',
  isa => sub { die "Not an array.\n" unless ref( $_[0] ) eq 'ARRAY' },
);

sub total_pot {
  my $self = shift;
  my $total = $self->pot;
  for my $chair ( grep { defined $_ } @{ $self->chairs } ) {
    $total += $chair->in_pot_this_round;
  }
  return $total;
}

sub pot_odds {
  my $self = shift;
  return $self->call_amt ? ($self->total_pot / $self->call_amt) : 0;
}

sub reset {
  my $self = shift;
  #$self->game_over(0);
  $self->pot(0);
  $self->last_bet(0);
  $self->round(1);
  $self->community_cards( [] );
  $self->game_count( $self->game_count + 1 );
  for my $chair ( grep { defined $_ } @{ $self->chairs } ) {
    $chair->reset;
  }
}

sub table_detail {
  my $self = shift;
  return {
    table_id     => $self->table_id,
    game_count   => $self->game_count,
    chair_count  => $self->chair_count,
    player_count => $self->player_count,
    round        => $self->round,
    action       => $self->action,
    pot          => $self->pot,
    total_pot    => $self->total_pot,
    pot_odds     => $self->pot_odds,
    class        => $self->class,
    game_over    => $self->game_over,
    auto_start   => $self->auto_start,
    time_bank    => $self->time_bank,
    last_bet     => $self->last_bet,
    last_act     => $self->last_act,
    turn_clock   => $self->turn_clock,
    community    => $self->community,
    limit        => $self->limit,
    max_raise    => $self->max_raise,
    small_bet    => $self->small_bet,
    pot_cap      => $self->pot_cap,
    call_amt     => $self->call_amt,
    director_id  => $self->director_id,
    big_blind    => $self->big_blind,
    small_blind  => $self->small_blind,
    ante         => $self->ante,
  };
}

=head1 AUTHOR

Nathaniel Graham, C<ngraham@cpan.org> 

=head1 BUGS

Please report any bugs or feature requests directly to C<ngraham@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT license.

=cut

1;
