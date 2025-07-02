package Poker::Score::Bring::High;
use Moo;
use Algorithm::Combinatorics qw(combinations);
use List::Util qw(max);

=head1 NAME

Poker::Score::Bring::High - Scoring system used in highball Stud to decide which player starts the action.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

See Poker::Score for code example.

=cut

extends 'Poker::Score';

sub stringify_cards {
  my ( $self, $cards ) = @_;
  return join( '',
    sort { $b <=> $a }
    map { sprintf( "%02d", $self->rank_val( $_->rank ) ) } @$cards );
}

sub score {
  my ( $self, $cards ) = @_;
  my (%rank, %suit, @top);
  my $score = $self->hand_score( $self->stringify_cards($cards) );
  return 0 unless $score;

  for my $card (@$cards) {
    $rank{ $card->rank }++; 
  }

  my $max = max(values %rank);

  for my $k (keys %rank) {
    if ($rank{$k} == $max) {
      push @top, $k;
    }
  }
  my ($suit_rank) = sort { $self->rank_val($b) <=> $self->rank_val($a) } @top;

  for my $card (@$cards) {
    if ($self->rank_val($card->rank) == $self->rank_val($suit_rank)) {
      $suit{ $card->suit } = 1;
    }
  }
  my ($suit_val) = sort { $b <=> $a } map { $self->suit_val($_) } keys %suit;
  return $score . '.' . $suit_val;
}

sub _build_hands {  # generates all possible bring hands
  my $self = shift;
  # one card
  my @hands = @{ $self->unpaired1 };

  # two cards
  push(@hands, @{ $self->unpaired2 });
  push(@hands, @{ $self->one_pair2 });

  # three cards
  push(@hands, @{ $self->unpaired3 });
  push(@hands, @{ $self->one_pair3 });
  push(@hands, @{ $self->threes3 });

  # four cards
  push(@hands, @{ $self->unpaired4 });
  push(@hands, @{ $self->one_pair4 });
  push(@hands, @{ $self->two_pair4 });
  push(@hands, @{ $self->threes4 });
  push(@hands, @{ $self->fours4 });

  $self->hands( [ @hands ] );
}

############
# one card #
############

# unpaired

sub unpaired1 {
  my @temp;
  for my $card ( 2 .. 14 ) {
    push @temp,
      join( '', sprintf( "%02d", $card ));
  }
  return [ @temp ];
}

#############
# two cards #
#############

# unpaired

sub unpaired2 {
  my $self = shift;
  my @scores;
  my $iter = combinations([ reverse (2..14) ], 2);
  while (my $c = $iter->next) {
    push( @scores, join( "", map { sprintf("%02d", $_) } sort { $b <=> $a } @$c ) );
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
      sort { $b <=> $a } ( ($card) x 2 )
    );
  }
  return [ @temp ];
}

###############
# three cards #
###############

# unpaired

sub unpaired3 {
  my $self = shift;
  my @scores;
  my $iter = combinations([ reverse (2..14) ], 3);
  while (my $c = $iter->next) {
    push( @scores, join( "", map { sprintf("%02d", $_) } sort { $b <=> $a } @$c ) );
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
        sort { $b <=> $a } ( ($card1) x 2, $card2 ) 
      );
    }
  }
  return [ @temp ];
}

# three-of-a-kind
sub threes3 {
  my @temp;
  for my $card1 ( 2 .. 14 ) {
    push @temp,
      join('',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ($card1) x 3
      );
  }
  return [ @temp ];
}

##############
# four cards #
##############

# unpaired
sub unpaired4 {
  my $self = shift;
  my @scores;
  my $iter = combinations([ reverse (2..14) ], 4);
  while (my $c = $iter->next) {
    push( @scores, join( "", map { sprintf("%02d", $_) } sort { $b <=> $a } @$c ) );
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
  return [ @temp ];
}

# two pair
sub two_pair4 {
  my @temp;
  for my $card1 ( reverse combinations( [ reverse ( 2 .. 14 ) ], 2 ) ) {
    push @temp,
      join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ( $card1->[0] ) x 2, ( $card1->[1] ) x 2 ) 
      );
  }
  return [ @temp ];
}

# three-of-a-kind
sub threes4 {
  my @temp;
  for my $card1 ( 2 .. 14 ) {
    for my $card2 ( grep { $_ != $card1 } ( 2 .. 14 ) ) {
      push @temp, 
        join('',
          map { sprintf( "%02d", $_ ) }
          sort { $b <=> $a } ($card1) x 3, ($card2)
        );
    }
  }
  return [ @temp ];
}

# four-of-a-kind
sub fours4 {
  my @temp;
  for my $card ( 2 .. 14 ) {
    #for my $suit ( qw(c d h s) ) {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        ($card) x 4 );
        #($card) x 4 ) . $suit;
    #}
  }
  return [ @temp ];
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
