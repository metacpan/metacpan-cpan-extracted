package Poker::Score::Low27;
use Moo;

=head1 NAME

Poker::Score::Low27 - Identify and score lowball 2-7 poker hand. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 INTRODUCTION

Straights and flushes count against your low hand and Aces always play high.

=head1 SYNOPSIS

See Poker::Score for code example.

=cut

extends 'Poker::Score::High';

after _build_hands => sub {
  my $self = shift;
  my %map;
  $self->hands( [ reverse @{ $self->hands } ] );

  my @names =
    map  { $self->_hand_map->{$_} }
    sort { $a <=> $b } keys %{ $self->_hand_map };
  my @keys = sort { $a <=> $b } keys %{ $self->_hand_map };
  my $lowest = shift @keys;
  for my $key (@keys) {
    $map{ $#{ $self->hands } - $key } = shift @names;
  }
  $map{ $lowest } = pop @names;
  $self->_hand_map( \%map );
  #print Dumper(\%map);
};

# straights
# Aces always play high in the 27 scoring system
# e.g., A2345 is NOT a straight
sub _build_straights {
  return [
    '0605040302', '0706050403', '0807060504', '0908070605', '1009080706',
    '1110090807', '1211100908', '1312111009', '1413121110',
  ];
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
