use 5.008001;
use strict;
use warnings;

package Statistics::RankOrder;
# ABSTRACT: Algorithms for determining overall rankings from a panel of judges
our $VERSION = '0.13'; # VERSION

use Carp;
use Class::Tiny {
    _data => sub { [] }
};



sub add_judge {
    my ( $self, $obs ) = @_;
    push @{ $self->_data }, $obs;
    return scalar @{ $self->_data };
}


sub best_majority_rank {
    my ($self) = shift;
    my %candidates = $self->candidates;
    my %best_maj;
    while ( my ( $cand, $scores ) = ( each %candidates ) ) {
        my @sorted = sort { $a <=> $b } @$scores;
        my $index  = int( @sorted / 2 );
        my $bom    = $sorted[$index];
        my ( $som, $tom, $to ) = (0) x 3;
        for (@sorted) {
            $to += $_;
            $tom += $_, $som++ if $_ <= $bom;
        }
        $best_maj{$cand} = {
            bom => $bom,
            som => $som,
            tom => $tom,
            to  => $to
        };
    }
    my %compare;
    for my $k ( keys %best_maj ) {
        $compare{$k} = 0;
        $compare{$k} += (
            $best_maj{$k}{bom} <=> $best_maj{$_}{bom}      # low is good
              || $best_maj{$_}{som} <=> $best_maj{$k}{som} # high is good
              || $best_maj{$k}{tom} <=> $best_maj{$_}{tom} # low is good
              || $best_maj{$k}{to} <=> $best_maj{$_}{to}   # low is good
        ) for keys %best_maj;
    }
    return _scores_to_ranks(%compare);
}


sub candidates {
    my ($self) = @_;
    my %c;
    for my $j ( $self->judges ) {
        push @{ $c{ $j->[$_] } }, $_ for 0 .. $#{$j};
    }
    return %c;
}


sub judges {
    my ($self) = @_;
    return @{ $self->_data };
}


sub mean_rank {
    my ($self) = shift;
    return $self->trimmed_mean_rank(0);
}


sub median_rank {
    my ($self) = shift;
    my %candidates = $self->candidates;
    my %medians;
    while ( my ( $cand, $scores ) = ( each %candidates ) ) {
        my @sorted = sort { $a <=> $b } @$scores;
        my $index = int( @sorted / 2 );
        $medians{$cand} = $sorted[$index];
    }
    return _scores_to_ranks(%medians);
}


sub trimmed_mean_rank {
    my ( $self, $trim ) = @_;
    die "Can't trim away all scores" if 2 * $trim >= $self->judges;
    my %candidates = $self->candidates;
    my %means;
    while ( my ( $cand, $scores ) = ( each %candidates ) ) {
        my @sorted = sort { $a <=> $b } @$scores;
        @sorted = @sorted[ $trim .. $#sorted - $trim ];
        my $avg = 0;
        $avg += $_ for @sorted;
        $means{$cand} = $avg / @sorted;
    }
    return _scores_to_ranks(%means);
}

#--------------------------------------------------------------------------#
# Private functions
#--------------------------------------------------------------------------#

sub _scores_to_ranks {
    my (%scores) = @_;
    my %ranks;
    my $cur_rank   = 0;
    my $index      = 0;
    my $last_score = -keys %scores;
    for my $cand ( sort { $scores{$a} <=> $scores{$b} } keys %scores ) {
        $index++;
        $cur_rank = $index if $scores{$cand} > $last_score;
        $ranks{$cand} = $cur_rank;
        $last_score = $scores{$cand};
    }
    return %ranks;
}

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding utf-8

=head1 NAME

Statistics::RankOrder - Algorithms for determining overall rankings from a panel of judges

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  use Statistics::RankOrder;

  my $r = Statistics::RankOrder->new();
  
  $r->add_judge( [qw( A B C )] );
  $r->add_judge( [qw( A C B )] );
  $r->add_judge( [qw( B A C )] );

  my %ranks = $r->mean_rank;
  my %ranks = $r->trimmed_mean_rank(1);
  my %ranks = $r->median_rank;
  my %ranks = $r->best_majority_rank;

=head1 DESCRIPTION

This module offers algorithms for combining the rank-ordering of candidates by
a panel of judges.  For the purpose of this module, the term "candidates" means
candidates in an election, brands in a taste-test, competitors in a sporting
event, and so on.  "Judges" means those rank-ordering the candidates, whether
these are event judges, voters, etc.  Unlike "voting" algorithms (e.g.
majority-rule or single-transferable-vote), these algorithms require judges to
rank-order all candidates.  (Ties may be permissible for some algorithms).

Algorithms included are:

=over

=item * Lowest-Mean

=item * Trimmed-Lowest-Mean

=item * Median-Rank

=item * Best-of-Majority

=back

In this alpha version, there is minimal error checking. Future versions will
have more robust error checking and may have additional ranking methods such as 
pair-ranking methods.

=head1 METHODS

=head2 new

 $r = Statistics::RankOrder->new();

Creates a new object with no judges on the panel (i.e. no data);

=head2 C<add_judge>

 $r->add_judge( [qw( A B C D E )] );

Adds a judge to the panel.  The single argument is an array-reference with
the names of candidates ordered from best to worst.

=head2 C<best_majority_rank>

 my %ranks = $r->best_majority_rank;

Ranks candidates according to the "Best-of-Majority" algorithm.  The median
rank is found for each candidate.  If there are an even number of judges, the
worst of the two median ranks is used.  The idea behind this method is that the
result for a candidate represents the worst rank such that a majority of
judges support that rank or better.  Ties in the median ranks are broken by the
following comparisons, in order, until the tie is broken:

=over

=item * larger "Size of Majority" (SOM) -- number of judges ranking at median rank or better

=item * lower "Total Ordinals of Majority" (TOM) -- sum of ordinal rankings of judges ranking at median rank
or better

=item * lower "Total Ordinals" (TO) -- sum of all ordinals from all judges

=back

If a tie still exists after these comparisons, then the tie stands.  (In
practice, this is generally rare.)  When a tie occurs, the next rank assigned
after the tie is calculated as if the tie had not occurred.  E.g., 1st, 2nd,
2nd, 4th, 5th.

Returns a hash where the keys are the names of the candidates and the 
values are their rankings, with 1 being best and higher numbers worse. 

=head2 C<candidates>

 my %candidates = $r->candidates;

Returns a hash with keys being the names of candidates and the values being
array references containing the rankings from all judges for each candidate.

=head2 C<judges>

 my @judges = $r->judges;

Returns a list of array-references representing the rank-orderings of each
judge.

=head2 C<mean_rank>

 my %ranks = $r->mean_rank;

Ranks candidates according to the "Lowest Mean Rank" algorithm.  The average
rank is computed for each candidate.  The candidate with the lowest mean rank
is placed 1st, the second lowest mean rank is 2nd, and so on.  If the mean
ranks are the same, the candidates tie for that position.  When a tie occurs,
the next rank assigned after the tie is calculated as if the tie had not
occurred.  E.g., 1st, 2nd, 2nd, 4th, 5th.

Returns a hash where the keys are the names of the candidates and the 
values are their rankings, with 1 being best and higher numbers worse. 

=head2 C<median_rank>

 my %ranks = $r->median_rank;

Ranks candidates according to the "Median Rank" algorithm.  The median rank is
found for each candidate.  If there are an even number of judges, the worst of
the two median ranks is used.  The idea behind this method is that the result
for a candidate represents the lowest rank such that a majority of judges
support that rank or better.  The candidate with the lowest median rank is
placed 1st, the second lowest median rank is 2nd, and so on.  If the median
ranks are the same, the candidates tie for that position.  When a tie occurs,
the next rank assigned after the tie is calculated as if the tie had not
occurred.  E.g., 1st, 2nd, 2nd, 4th, 5th.

Returns a hash where the keys are the names of the candidates and the 
values are their rankings, with 1 being best and higher numbers worse. 

=head2 C<trimmed_mean_rank>

 my %ranks = $r->trimmed_mean_rank( N );

Ranks candidates according to the "Trimmed Lowest Mean Rank" algorithm.  The
average rank is computed for each candidate after dropping the N lowest
and N highest scores.  E.g. C<trimmed_mean_rank(2)> will drop
the 2 lowest and highest scores.  The candidate with the lowest mean rank is
placed 1st, the second lowest mean rank is 2nd, and so on.  If the mean ranks
are the same, the candidates tie for that position.  When a tie occurs, the
next rank assigned after the tie is calculated as if the tie had not occurred.
E.g., 1st, 2nd, 2nd, 4th, 5th.

Returns a hash where the keys are the names of the candidates and the 
values are their rankings, with 1 being best and higher numbers worse. 

=head1 SEE ALSO

=over

=item * L<Lingua::EN::Number::Ordinate> -- for converting "1" to "1st", etc.

=back

For further details on various ranking methods, in particular, the "Best of
Majority" method, see the following articles:

=over

=item * "Rating Skating", Gilbert W. Basset and Joseph Persky, Journal
of the American Statistical Association, volume 89, Issue 427 (Sept 1994),
pp. 1075-1079

=item * "The Canadians Should Have Won!?", Maureen T. Carroll, Elyn K. Rykken,
and Jody M. Sorensen.  L<http://mathcs.muhlenberg.edu/~rykken/skating-full.pdf>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/Statistics-RankOrder/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/Statistics-RankOrder>

  git clone https://github.com/dagolden/Statistics-RankOrder.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by David A Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
