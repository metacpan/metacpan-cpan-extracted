package Poker::Eval::Chinese;
use Algorithm::Combinatorics qw(combinations);
use Moo;

=head1 NAME

Poker::Eval::Chinese - Evaluate and score Chinese poker hands. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 INTRODUCTION

Calculates score plus royalties for "front", "middle", and "back" Chinese poker hands. 

=cut

extends 'Poker::Eval';

has 'chinese_scorer' => (
  is  => 'rw',
  isa => sub { die "Not a Score!\n" unless $_[0]->isa('Poker::Score') },
  required => 1,
);

sub best_hand {
  my ( $self, $front, $middle, $back ) = @_;
  my $front_score    = $self->chinese_scorer->score($front);
  my $front_royalty  = &_royalty_front($front_score);
  my $middle_score   = $self->scorer->score($middle);
  my $middle_royalty = &_royalty_middle($middle_score);
  my $back_score   = $self->scorer->score($back);
  my $back_royalty   = &_royalty_back($back_score);
  if ( $back_score >= $middle_score && $middle_score >= $front_score ) {
    return {
      front  => { score => $front_score,  royalty => $front_royalty },
      middle => { score => $middle_score, royalty => $middle_royalty },
      back   => { score => $back_score,   royalty => $back_royalty },
    };
  }
}

sub _royalty_back {
  my $score = shift;
  if ( $score >= 5853 && $score <= 5862 ) {
    return 2;
  }
  elsif ( $score >= 5863 && $score <= 7139 ) {
    return 4;
  }
  elsif ( $score >= 7140 && $score <= 7295 ) {
    return 6;
  }
  elsif ( $score >= 7296 && $score <= 7451 ) {
    return 10;
  }
  elsif ( $score >= 7452 && $score <= 7460 ) {
    return 15;
  }
  elsif ( $score == 7461 ) {
    return 25;
  }
  else {
    return 0;
  }
}

sub _royalty_middle {
  my $score = shift;
  if ( $score >= 4995 && $score <= 5852 ) {
    return 2;
  }
  if ( $score >= 5853 && $score <= 5862 ) {
    return 4;
  }
  elsif ( $score >= 5863 && $score <= 7139 ) {
    return 8;
  }
  elsif ( $score >= 7140 && $score <= 7295 ) {
    return 12;
  }
  elsif ( $score >= 7296 && $score <= 7451 ) {
    return 20;
  }
  elsif ( $score >= 7452 && $score <= 7460 ) {
    return 30;
  }
  elsif ( $score == 7461 ) {
    return 50;
  }
  else {
    return 0;
  }
}

sub _royalty_front {
  my $score = shift;
  if ( $score >= 2156 && $score <= 2322 ) {
    return 1;
  }
  elsif ( $score >= 2376 && $score <= 2542 ) {
    return 2;
  }
  elsif ( $score >= 2596 && $score <= 2762 ) {
    return 3;
  }
  elsif ( $score >= 2816 && $score <= 2982 ) {
    return 4;
  }
  elsif ( $score >= 3036 && $score <= 3202 ) {
    return 5;
  }
  elsif ( $score >= 3256 && $score <= 3422 ) {
    return 6;
  }
  elsif ( $score >= 3476 && $score <= 3642 ) {
    return 7;
  }
  elsif ( $score >= 3696 && $score <= 3862 ) {
    return 8;
  }
  elsif ( $score >= 3916 && $score <= 4082 ) {
    return 9;
  }
  elsif ( $score == 4995 ) {
    return 10;
  }
  elsif ( $score == 5061 ) {
    return 11;
  }
  elsif ( $score == 5127 ) {
    return 12;
  }
  elsif ( $score == 5193 ) {
    return 13;
  }
  elsif ( $score == 5259 ) {
    return 14;
  }
  elsif ( $score == 5325 ) {
    return 15;
  }
  elsif ( $score == 5391 ) {
    return 16;
  }
  elsif ( $score == 5457 ) {
    return 17;
  }
  elsif ( $score == 5523 ) {
    return 18;
  }
  elsif ( $score == 5589 ) {
    return 19;
  }
  elsif ( $score == 5655 ) {
    return 20;
  }
  elsif ( $score == 5721 ) {
    return 21;
  }
  elsif ( $score == 5787 ) {
    return 22;
  }
  else {
    return 0;
  }
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
