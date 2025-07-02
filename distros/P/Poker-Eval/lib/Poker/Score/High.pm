package Poker::Score::High;
use Moo;
use Algorithm::Combinatorics qw(combinations);

=head1 NAME

Poker::Score::High - Identify and score specific highball poker hand. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

See Poker::Score for code example.

=cut

extends 'Poker::Score';

sub _build_hands {
  my $self = shift;
  my %map = ( 1 => 'a High Card' );
  my @hands = @{ $self->unpaired };
  $map{ $#hands } = 'One Pair';
  push(@hands, @{ $self->one_pair });
  $map{ $#hands } = 'Two Pair';
  push(@hands, @{ $self->two_pair });
  $map{ $#hands } = 'Three-of-a-Kind';
  push(@hands, @{ $self->threes });
  $map{ $#hands } = 'a Straight';
  push(@hands, @{ $self->straights });
  $map{ $#hands } = 'a Flush';
  push(@hands, @{ $self->flushes });
  $map{ $#hands } = 'a Full House';
  push(@hands, @{ $self->houses });
  $map{ $#hands } = 'Four-of-a-Kind';
  push(@hands, @{ $self->fours });
  $map{ $#hands } = 'a Straight Flush';
  push(@hands, @{ $self->straight_flushes });
  $map{ $#hands } = 'Five-of-a-Kind';
  push(@hands, @{ $self->fives });
  $self->hands( [ @hands ] );
  $self->_hand_map( \%map );
}

# straights
has 'straights' => (
  is  => 'rw',
  isa => sub {
    die "Not an array.\n" unless ref( $_[0] ) eq 'ARRAY';
  },
  builder => '_build_straights'
);

sub _build_straights {
  return [
    '1405040302', '0605040302', '0706050403', '0807060504', '0908070605',
    '1009080706', '1110090807', '1211100908', '1312111009', '1413121110'
  ];
}

# unpaired non-straight combinations
has 'unpaired' => (
  is      => 'rw',
  isa     => sub { die "Not an array.\n" unless ref( $_[0] ) eq 'ARRAY' },
  builder => '_build_unpaired',
);

sub _build_unpaired {
  my $self     = shift;
  my %straight = map { $_, 1 } @{ $self->straights };
  my $iter     = combinations( [ reverse( 2 .. 14 ) ], 5 );
  my @unpaired;
  while ( my $c = $iter->next ) {
    push @unpaired,
      join( '', map { sprintf( "%02d", $_ ) } sort { $b <=> $a } @$c );
  }
  return [ grep { !exists $straight{$_} } sort { $a <=> $b } @unpaired ];
}

# four-of-a-kind
sub fours {
  my @temp;
  for my $card1 ( 2 .. 14 ) {
    for my $card2 ( grep { $_ != $card1 } ( 2 .. 14 ) ) {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ($card1) x 4, $card2 ) );
    }
  }
  return [@temp];
}

# five-of-a-kind
sub fives {
  my @temp;
  for my $card ( 2 .. 14 ) {
    push @temp,
      join( '',
      map { sprintf( "%02d", $_ ) }
      ($card) x 5);
  }
  return [@temp];
}

# full house
sub houses {
  my @temp;
  for my $card1 ( 2 .. 14 ) {
    for my $card2 ( grep { $_ != $card1 } ( 2 .. 14 ) ) {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ($card1) x 3, ($card2) x 2 ) );
    }
  }
  return [@temp];
}

# three-of-a-kind
sub threes {
  my @temp;
  for my $card ( 2 .. 14 ) {
    for my $c (
      reverse combinations( [ reverse grep { $_ != $card } ( 2 .. 14 ) ], 2 ) )
    {
      push @temp, join(
        '',
        map { sprintf( "%02d", $_ ) }

          sort { $b <=> $a } ($card) x 3, @$c
      );
    }
  }
  return [@temp];
}

# two pair
sub two_pair {
  my @temp;
  for my $c ( reverse combinations( [ reverse( 2 .. 14 ) ], 2 ) ) {
    for my $card ( grep { $_ != $c->[0] && $_ != $c->[1] } ( 2 .. 14 ) ) {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ( $c->[0] ) x 2, ( $c->[1] ) x 2, $card ) );
    }
  }
  return [@temp];
}

# one pair
sub one_pair {
  my @temp;
  for my $card ( 2 .. 14 ) {
    for my $c (
      reverse combinations( [ reverse grep { $_ != $card } ( 2 .. 14 ) ], 3 ) )
    {
      push @temp,
        join( '',
        map { sprintf( "%02d", $_ ) }
        sort { $b <=> $a } ( ($card) x 2, @$c ) );
    }
  }
  return [@temp];
}

# non-straight flushes
sub flushes {
  my $self = shift;
  return [ map { $_ . 's' } @{ $self->unpaired } ];
}

# straight flushes
sub straight_flushes {
  my $self = shift;
  return [ map { $_ . 's' } @{ $self->straights } ];
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
