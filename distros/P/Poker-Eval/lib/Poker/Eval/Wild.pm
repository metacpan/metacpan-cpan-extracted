package Poker::Eval::Wild;
use Algorithm::Combinatorics qw(combinations combinations_with_repetition);
use Moo;

=head1 NAME

Poker::Eval::Wild - Evaluate and score wildcard poker hands.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

See Poker::Eval for code example.

=head1 INTRODUCTION

Evaluate highball wildcard hands. The lowball wildcard evaluator doesn't quite work yet. To mark a card as wild, set the wild_flag of the Poker::Card object to true. 

=cut

extends 'Poker::Eval::Community';

sub best_hand {
  my ( $self, $hole ) = @_;
  my $best = Poker::Hand->new(cards => $hole);
  return $best
    if $self->card_count >
      ( scalar @$hole + scalar @{ $self->community_cards } );
  my ( @wild, @normal );
  for my $card ( @$hole, @{ $self->community_cards } ) {
    if ( $card->is_wild ) {
      push @wild, $card;
    }
    else {
      push @normal, $card;
    }
  }
  my $wild_count = scalar @wild;
  $wild_count = $wild_count > 5 ? 5 : $wild_count;
  my $norm_used = 5 > $wild_count ? 5 - $wild_count : 0;
  my @wild_combos;
  if ( $wild_count > 4 ) {
    my $flat_hand = '1414141414';
    #$best->best_combo($flat_hand);
    $best->score($self->scorer->hand_score($flat_hand));
  }
  elsif ( $wild_count == 4 ) {
    my @ranks = sort { $a <=> $b }
         map { $self->scorer->rank_val( $_->rank ) } @normal;
    my $high_rank = sprintf( "%02d", pop @ranks);
    my $flat_hand = join '', ($high_rank) x 5;
    #$best->best_combo($flat_hand);
    $best->score($self->scorer->hand_score($flat_hand));
  }
  else {
    @wild_combos =
      combinations_with_repetition( [ map { sprintf( "%02d", $_ ) } 2 .. 14 ],
      $wild_count );
    my $norm_iter = combinations( [@normal], $norm_used );
    while ( my $norm_combo = $norm_iter->next ) {

      my %suit;
      my $max = 0;
      my @norm_ranks = map { $self->scorer->rank_val( $_->rank ) } @$norm_combo;
      for my $card (@$norm_combo) {
        $suit{ $card->suit }++;
        $max = $suit{ $card->suit } if $suit{ $card->suit } >= $max;
      }
      my $flush_possible = $max + $wild_count > 4 ? 1 : 0;

      for my $wild_combo (@wild_combos) {
        my $flat_combo =
          join( '', sort { $b <=> $a } ( @$wild_combo, @norm_ranks ) );
        my $score = $self->scorer->hand_score($flat_combo);
        if ($flush_possible) {
          my $flush_score = $self->scorer->hand_score( $flat_combo . 's' ) || 0;
          $score = $flush_score if $flush_score > $score;
        }
        if ( defined $score && $score >= $best->score ) {
          #$best->best_combo($flat_combo),
          $best->score($score);
        }
      }
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
