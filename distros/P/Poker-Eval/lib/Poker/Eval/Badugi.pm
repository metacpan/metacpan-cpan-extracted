package Poker::Eval::Badugi;
use Algorithm::Combinatorics qw(combinations);
use Moo;
use Poker::Score::Badugi;

=head1 NAME

Poker::Eval::Badugi - Evaluate and score Badugi poker hands.  

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 SYNOPSIS

See Poker::Eval for code examples

=cut

extends 'Poker::Eval';

sub best_hand {
  my ( $self, $hole ) = @_;
  my $best = Poker::Hand->new(cards => $hole);
  my $iter = combinations( $hole, scalar @$hole > 4 ? 4 : scalar @$hole);
  while (my $combo = $iter->next ) {
    my (@list, %seen);
    for my $c (sort { $self->scorer->_rank_map->{$a->rank} <=> $self->scorer->_rank_map->{$b->rank} } @$combo) {
      if ( !$seen{ $c->suit } && !$seen{ $c->rank } ) {
        push @list, $c;
        $seen{ $c->suit }++; 
        $seen{ $c->rank }++; 
      }
    }
    my $score = $self->scorer->score( [@list] );
    if ( defined $score && $score >= $best->score ) {
      $best->score($score);
      $best->best_combo(\@list);
    }
  }
  $best->name($self->scorer->hand_name( $best->score ));
  return $best;
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
