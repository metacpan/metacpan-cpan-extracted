package Poker::Score::Low8;
use Moo;
use Algorithm::Combinatorics qw(combinations);

=head1 NAME

Poker::Score::Low8 - Identify and score lowball 8 or better poker hand. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 INTRODUCTION

This scoring system is typically used in split-pot games.

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

sub _build_hands {  # generates all possible low8 hands
  my $self = shift;
  my @scores;
  my $iter = combinations([1..8], 5);
  while (my $c = $iter->next) {
    push( @scores, join( "", map { sprintf("%02d", $_) } sort { $b <=> $a } @$c ) );
  }
  $self->hands([ sort { $b <=> $a } @scores ]);
  #$self->_hand_map( {} );
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
