package Poker::Score::HighSuit;
use Moo;

=head1 NAME

Poker::Score::HighSuit - Score highest card of a specific suit.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 INTRODUCTION

Scoring system typically used in split-pot games like High Chicago where half the pot goes to the player holding the highest Spade.

=head1 SYNOPSIS

See Poker::Score for code example.

=cut

extends 'Poker::Score';

sub score {
  my ( $self, $cards, $suit ) = @_;
  my ($high_card) =
    sort { $self->rank_val( $b->rank ) <=> $self->rank_val( $a->rank ) }
    grep { !$_->up_flag && $_->suit eq $suit } @$cards;

  if ($high_card) {
    return {
      score => $self->rank_val( $high_card->rank ),
      hand  => [$high_card],
    };
  }
}

1;
