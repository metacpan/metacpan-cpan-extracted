package Poker::Score::Bring::Wild;
use Moo;
use Algorithm::Combinatorics qw(combinations combinations_with_repetition);
use List::Util qw(max);

=head1 NAME

Poker::Score::Bring::Wild - Scoring system used in highball Stud with wildcards to decide which player starts the action.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

See Poker::Score for code example.

=cut


extends 'Poker::Score::Bring::High';

sub score {
  my ( $self, $hole ) = @_;
  my $score = 0;
  my ( @wild, @normal );
  for my $card (@$hole) {
    if ( $card->is_wild ) {
      push @wild, $card;
    }
    else {
      push @normal, $card;
    }
  }
  my $wild_count = scalar @wild;
  my $norm_count = scalar @normal;
  my @wild_combos;
  
  if ( $norm_count == 0 ) {
    my $flat_hand = '14' x $wild_count;
    $score = $self->hand_score($flat_hand);
  }

  elsif ( $wild_count == 3 ) {
    my @ranks = sort { $a <=> $b }
      map { $self->rank_val( $_->rank ) } @normal;
    my $high_rank = sprintf( "%02d", pop @ranks );
    my $flat_hand = join '', ($high_rank) x 4;
    $score = $self->hand_score($flat_hand);
  }

  else {
    @wild_combos =
      combinations_with_repetition( [ map { sprintf( "%02d", $_ ) } 2 .. 14 ],
      $wild_count );
    my $norm_iter = combinations( [@normal], $norm_count );
    while ( my $norm_combo = $norm_iter->next ) {

      my @norm_ranks = map { $self->rank_val( $_->rank ) } @$norm_combo;
      for my $wild_combo (@wild_combos) {
        my $flat_combo =
          join( '', sort { $b <=> $a } ( @$wild_combo, @norm_ranks ) );

        my $temp_score = $self->hand_score($flat_combo);

        if ( defined $temp_score && $temp_score >= $score ) {
          $score = $temp_score;
        }
      }
    }
  }
  return $score . '.05';
}

sub _build_hands {    # generates all possible bring hands
  my $self = shift;

  # one card
  my @hands = @{ $self->unpaired1 };

  # two cards
  push( @hands, @{ $self->unpaired2 } );
  push( @hands, @{ $self->one_pair2 } );

  # three cards
  push( @hands, @{ $self->unpaired3 } );
  push( @hands, @{ $self->one_pair3 } );
  push( @hands, @{ $self->threes3 } );

  # four cards
  push( @hands, @{ $self->unpaired4 } );
  push( @hands, @{ $self->one_pair4 } );
  push( @hands, @{ $self->two_pair4 } );
  push( @hands, @{ $self->threes4 } );
  push( @hands, @{ $self->fours4 } );

  $self->hands( [@hands] );
}

############
# one card #
############

# unpaired

sub unpaired1 {
  my @temp;
  for my $card ( 2 .. 14 ) {
    push @temp, join( '', sprintf( "%02d", $card ) );
  }
  return [@temp];
}

#############
# two cards #
#############

# unpaired

sub unpaired2 {
  my $self = shift;
  my @scores;
  my $iter = combinations( [ reverse( 2 .. 14 ) ], 2 );
  while ( my $c = $iter->next ) {
    push( @scores,
      join( "", map { sprintf( "%02d", $_ ) } sort { $b <=> $a } @$c ) );
  }
  return [ sort { $a <=> $b } @scores ];
}

# one pair
sub one_pair2 {
  my @temp;
  for my $card ( 2 .. 14 ) {
    push @temp,
      join( '',
      map { sprintf( "%02d", $_ ) }
      sort { $b <=> $a } ( ($card) x 2 ) );
  }
  return [@temp];
}

###############
# three cards #
###############

# unpaired

sub unpaired3 {
  my $self = shift;
  my @scores;
  my $iter = combinations( [ reverse( 2 .. 14 ) ], 3 );
  while ( my $c = $iter->next ) {
    push( @scores,
      join( "", map { sprintf( "%02d", $_ ) } sort { $b <=> $a } @$c ) );
  }
  return [ sort { $a <=> $b } @scores ];
}

# one pair
sub one_pair3 {
  my @temp;
  for my $card1 ( 2 .. 14 ) {
    for my $card2 ( grep { $_ != $card1 } ( 2 .. 14 ) ) {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ($card1) x 2, $card2 ) );
    }
  }
  return [@temp];
}

# three-of-a-kind
sub threes3 {
  my @temp;
  for my $card1 ( 2 .. 14 ) {
    push @temp,
      join(
      '', map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ($card1) x 3
      );
  }
  return [@temp];
}

##############
# four cards #
##############

# unpaired
sub unpaired4 {
  my $self = shift;
  my @scores;
  my $iter = combinations( [ reverse( 2 .. 14 ) ], 4 );
  while ( my $c = $iter->next ) {
    push( @scores,
      join( "", map { sprintf( "%02d", $_ ) } sort { $b <=> $a } @$c ) );
  }
  return [ sort { $a <=> $b } @scores ];
}

# one pair
sub one_pair4 {
  my @temp;
  for my $card1 ( 2 .. 14 ) {
    for my $card2 (
      reverse combinations( [ reverse grep { $_ != $card1 } ( 2 .. 14 ) ], 2 ) )
    {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ($card1) x 2, @$card2 ) );
    }
  }
  return [@temp];
}

# two pair
sub two_pair4 {
  my @temp;
  for my $card1 ( reverse combinations( [ reverse( 2 .. 14 ) ], 2 ) ) {
    push @temp,
      join( '',
      map { sprintf( "%02d", $_ ) }
      sort { $b <=> $a } ( ( $card1->[0] ) x 2, ( $card1->[1] ) x 2 ) );
  }
  return [@temp];
}

# three-of-a-kind
sub threes4 {
  my @temp;
  for my $card1 ( 2 .. 14 ) {
    for my $card2 ( grep { $_ != $card1 } ( 2 .. 14 ) ) {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ($card1) x 3, ($card2) );
    }
  }
  return [@temp];
}

# four-of-a-kind
sub fours4 {
  my @temp;
  for my $card ( 2 .. 14 ) {

    #for my $suit ( qw(c d h s) ) {
    push @temp, join( '', map { sprintf( "%02d", $_ ) } ($card) x 4 );

    #($card) x 4 ) . $suit;
    #}
  }
  return [@temp];
}

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
