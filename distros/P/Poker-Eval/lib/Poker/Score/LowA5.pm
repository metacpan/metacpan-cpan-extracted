package Poker::Score::LowA5;
use Moo;
use Algorithm::Combinatorics qw(combinations);

=head1 NAME

Poker::Score::LowA5 - Identify and score lowball A-5 poker hand. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 INTRODUCTION

Straights and flushes do not affect the strengh of your hand and Aces always play low.

=head1 SYNOPSIS

See Poker::Score for code example.

=cut

extends 'Poker::Score';

sub _build_rank_map {
  my $self = shift;
  $self->_rank_map({
    'A' => '01',
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
  });
}

sub _build_hands {  # generates all possible lowA5 hands
  my $self = shift;
  my %map = ( 1 => 'Five-of-a-Kind' );
  my @hands = @{ $self->fives };
  $map{ $#hands } = 'Four-of-a-Kind';
  push(@hands, @{ $self->fours });
  $map{ $#hands } = 'a Full House';
  push(@hands, @{ $self->houses });
  $map{ $#hands } = 'Three-of-a-Kind';
  push(@hands, @{ $self->threes });
  $map{ $#hands } = 'Two Pair';
  push(@hands, @{ $self->two_pair });
  $map{ $#hands } = 'One Pair';
  push(@hands, @{ $self->one_pair });
  $map{ $#hands } = 'a High Card';
  push(@hands, @{ $self->unpaired });
  $self->hands( [ @hands ] );
  $self->_hand_map( \%map );
}

sub unpaired {
  my $self = shift;
  my @scores;
  my $iter = combinations([1..13], 5);
  while (my $c = $iter->next) {
    push( @scores, join( "", map { sprintf("%02d", $_) } sort { $b <=> $a } @$c ) );
  }
  #$self->hands([ sort { $b <=> $a } @scores ]);
  return [ sort { $b <=> $a } @scores ];
}

# one pair
sub one_pair {
  my @temp;
  for my $card ( 1 .. 13 ) {
    for my $c (
      reverse combinations( [ reverse grep { $_ != $card } ( 1 .. 13 ) ], 3 ) )
      #reverse combinations( [ grep { $_ != $card } ( 1 .. 13 ) ], 3 ) )
    {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ($card) x 2, @$c ) );
    }
  }
  return [reverse @temp];
}

# two pair
sub two_pair {
  my @temp;
  for my $c ( reverse combinations( [ reverse( 1 .. 13 ) ], 2 ) ) {
    for my $card ( grep { $_ != $c->[0] && $_ != $c->[1] } ( 1 .. 13 ) ) {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ( $c->[0] ) x 2, ( $c->[1] ) x 2, $card ) );
    }
  }
  return [reverse @temp];
}

# three-of-a-kind
sub threes {
  my @temp;
  for my $card ( 1 .. 13 ) {
    for my $c (
      reverse combinations( [ reverse grep { $_ != $card } ( 1 .. 13 ) ], 2 ) )
    {
      push @temp, join(
        '',
        map { sprintf( "%02d", $_ ) }

          sort { $b <=> $a } ($card) x 3, @$c
      );
    }
  }
  return [reverse @temp];
}

# full house
sub houses {
  my @temp;
  for my $card1 ( 1 .. 13 ) {
    for my $card2 ( grep { $_ != $card1 } ( 1 .. 13 ) ) {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ($card1) x 3, ($card2) x 2 ) );
    }
  }
  return [reverse @temp];
}

# four-of-a-kind
sub fours {
  my @temp;
  for my $card1 ( 1 .. 13 ) {
    for my $card2 ( grep { $_ != $card1 } ( 1 .. 13 ) ) {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ($card1) x 4, $card2 ) );
    }
  }
  return [reverse @temp];
}

# five-of-a-kind
sub fives {
  my @temp;
  for my $card ( 1 .. 13 ) {
    push @temp,
      join( '',
      map { sprintf( "%02d", $_ ) }
      ($card) x 5);
  }
  return [reverse @temp];
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
