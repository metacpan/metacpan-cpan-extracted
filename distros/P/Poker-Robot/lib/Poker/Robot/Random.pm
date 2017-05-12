package Poker::Robot::Random;
use feature qw(say);
use Moo;
use EV;

extends 'Poker::Robot';

=encoding utf8

=head1 NAME

Poker::Robot::Random

=head1 INTRODUCTION

This is a demo robot that essentially makes random moves. 

=cut

sub move {
  my ( $self, $table ) = @_;
  my @actions = @{ $table->valid_act };
  my $move    = $actions[ int( rand( scalar @actions ) ) ];

  # size bet 
  if ( $move eq 'bet' ) {
    $self->size_bet($table);
  }

  # select game 
  elsif ( $move eq 'choice' ) {
    $self->game_choice($table);
  }
  elsif ( $move eq 'bring' ) {
    $self->size_bring($table);
  }

  # select cards if drawing or discarding
  elsif ( $move eq 'draw' ) {
    $self->select_card( $table, $table->min_draws, $table->max_draws );
  }
  elsif ( $move eq 'discard' ) {
    $self->select_card( $table, $table->min_discards, $table->max_discards );
  }

  delete $self->move_timer->{ $table->table_id };
  $self->move_timer->{ $table->table_id } = EV::timer 1, 0, sub {
    $self->valid_actions->{$move}( $self, $table );
  };
}

sub game_choice {
  my ( $self, $table ) = @_;
  my @choices = @{ $table->dealer_choices };
  $table->game_choice( $choices[ int( rand( scalar @choices ) ) ] );
}

sub size_bet {
  my ( $self, $table ) = @_;
  my $seed = int( rand(3) );
  if ( $seed == 0 ) {
    $table->bet_size( $table->call_amt || $table->small_bet );
  }
  elsif ( $seed == 1 ) {
    $table->bet_size( $table->max_bet );
  }
  else {
    my $bet = int( $table->pot * ( rand(4) + 1 ) );
    $bet -= $bet % $table->small_bet;
    if ( $bet < $table->small_bet ) {
      $bet = $table->small_bet;
    }
    elsif ( $bet > $table->max_bet ) {
      $bet = $table->max_bet;
    }
    $table->bet_size($bet);
  }
}

sub size_bring {
  my ( $self, $table ) = @_;
  my @bets = ( $table->bring, $table->max_bet );
  $table->bet_size( $bets[ int( rand( scalar @bets ) ) ] );
}

sub select_card {
  my ( $self, $table, $min, $max ) = @_;
  my @i = map { $_ } ( 0 .. $#{ $table->chairs->[ $table->action ]->cards } );
  my $count = scalar @i;
  if ( $count == 0 ) {
    $table->card_select( [] );
    return;
  }
  $min = $count if $count < $min;
  $max = $count if $count < $max;

  my @selected;

  for ( 1 .. int( rand( $max - $min + 1 ) ) + $min ) {
    push( @selected, splice( @i, int( rand( scalar @i ) ), 1 ) );
  }
  $table->card_select( [@selected] );
}

=head1 AUTHOR

Nathaniel Graham, C<ngraham@cpan.org> 

=head1 BUGS

Please report any bugs or feature requests directly to C<ngraham@cpan.org>

=head1 SEE ALSO

L<Poker::Robot>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT license.


=cut

1;   
