package Poker::Score::Badugi27;
use Moo;
use Algorithm::Combinatorics qw(combinations);

=head1 NAME

Poker::Score::Badugi27 - Scoring system used in the game of Badeucy. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 INTRODUCTION

Normally the lowest Badugi is A-2-3-4. However, in Badeucy aces are also high for the Badugi hand. This makes the best Badugi hand 2-3-4-5.

=head1 SYNOPSIS

See Poker::Score for code example.

=cut

extends 'Poker::Score::Badugi';

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

sub _build_hands {    # generates all possible Badugi hands
  my $self = shift;
  my @all_scores = ();
  for my $count ( 1 .. 4 ) {
    my @scores;
    my $iter = combinations( [ 2 .. 14 ], $count );
    while ( my $c = $iter->next ) {
      push( @scores,
        join( '', map { sprintf( "%02d", $_ ) } sort { $b <=> $a } @$c ) );
    }
    $self->_hand_map->{scalar @all_scores} = $count . ' card Badugi';
    push @all_scores, sort { $b <=> $a } @scores;
  }
  $self->hands( [@all_scores] );
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
