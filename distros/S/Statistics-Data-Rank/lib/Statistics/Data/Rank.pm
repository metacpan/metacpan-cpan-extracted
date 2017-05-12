package Statistics::Data::Rank;

use 5.006;
use strict;
use warnings FATAL => 'all';
use base qw(Statistics::Data);
use Carp qw(croak);
use List::AllUtils qw(sum0);
use Statistics::Lite qw(count mean min);
use String::Util qw(hascontent);
$Statistics::Data::Rank::VERSION = '0.02';

=head1 NAME

Statistics::Data::Rank - Utilities for ranking data

=head1 VERSION

This is documentation for Version 0.02, released February 2015.

=head1 SYNOPSIS

 use Statistics::Data::Rank;
 my $rank = Statistics::Data::Rank->new();
 my %vars = ('nodrug' => [174, 224, 260], 'placebo' => [261, 213, 231], 'morphine' => [199, 143, 113]);
 my $ranks_href = $rankd->ranks_between(data => \%vars); # pre-load data:
 $rankd->load(\%vars); 
 $ranks_href = $rankd->ranks_within();
 my $sor = $rankd->sum_of_ranks_within(); # or _between()
 # or specify which vars to rank/sum-rank:
 $sor = $rankd->sum_of_ranks_within(lab => [qw/placebo morphine/]);

=head1 DESCRIPTION

Performs ranking of nammed data, either by an independent, between-variable method (as in Kruskall-Wallis test), or a dependent, cross-variable method (as in Friedman test). Methods return hash of ranks and sum-of-ranks. Data must be pre-loaded (as per L<Statistics::Data|Statistics::Data/load> or sent to the methods with the argument B<data> as a hash-ref of array-refs. Output is tested ahead of installation to ensure it matches published data (Siegal, 1956).

=head1 SUBROUTINES/METHODS

=head2 new

 $rankd = Statistics::Data->new();

Constructor, expecting/accepting no args. Inherited from L<Statistics::Data|Statistics::Data>.

=head2 load, add, unload

 $rankd->load('a' => [1, 4], 'b' => [3, 7]);

The given data can now be used by any of the following methods. This is inherited from L<Statistics::Data|Statistics::Data>, and all its other methods are available here via the class object. Only passing of data as a hash of arrays (HOA) is supported for now. Alternatively, give each of the following methods the HOA for the optional named argument B<data>.

=head2 ranks_between

 $ranks_href = $rankd->ranks_between(data => $values_href);
 $ranks_href = $rankd->ranks_between(lab => [qw/fez bop/]); # two, say, of previously loaded data
 $ranks_href = $rankd->ranks_between(); # all of any previously loaded data
 ($ranks_href, $ties_aref, $nties) = $rankd->ranks_between(data => $values_href);

Given a hash of arefs where the keys are names (groups, treatments) of the sample data (each as an aref), return a hash of the ranks of each value under each name, after pooling all the data and ranking them with a link to their name.  Ties are resolved by giving each tied score the mean of the ranks for which it is tied (see Siegal, 1956, p. 188ff). If called in list context, then a reference to an array of the number of variables having the same value per its rank, and a scalar for the number of ties, are also returned. Before ranking, data are checked for numeracy, and any non-numeric or empty values are culled.

Used, e.g., by Kruskal-Wallis ANOVA, L<Jonckheere-Terpstra|Statistics::ANOVA::JT> ANOVA, Dwass-Steel comparison, and Worsley-cluster tests.

=cut

sub ranks_between {
    my ( $self, %args ) = @_;
    my $data =
      $args{'data'}
      ? delete $args{'data'}
      : $self->get_hoa_by_lab_numonly_indep(%args);
    croak 'Variable data must be numeric and not empty'
      if not ref $data
      or not scalar keys %{$data};    # $self->all_numeric( values %{$data} );
    my ( $ranks_href, $xtied_aref, $nties, $ties_var ) = _ranks_between($data);
    return
      wantarray ? ( $ranks_href, $xtied_aref, $nties, $ties_var ) : $ranks_href;
}

=head2 ranks_within

 $ranks_href = $rankd->ranks_within(data => $values_href); # pass data now
 $ranks_href = $rankd->ranks_within(); # using all of any previously loaded data
 ($ranks_href, $ties_href) = $rankd->ranks_within();

Given a hash of arefs where the keys are variable names, and the values are their actual sample data (each as an aref), returns a hash of the ranks of each value under each name, calculated dependently (per the values across individual indices). So if 'a' => [1, 3, 7] and 'b' => [4, 5, 6], the ranks returned will be 'a' => [1, 2, 6] and 'b' => [3, 4, 5]. Ties are resolved by giving each tied score the mean of the ranks for which it is tied (see Siegal, 1956, p. 188ff). If called in list context, then a reference to hash of aref is also returned, giving the number of variables having the same value at each index for a rank. Before ranking, data are checked for numeracy, and any non-numeric or empty values are culled.

Used, e.g., by L<Friedman|Statistics::ANOVA::Friedman> and L<Page|Statistics::ANOVA::Page> tests.

=cut

sub ranks_within {
    my ( $self, %args ) = @_;
    my $data =
      $args{'data'}
      ? delete $args{'data'}
      : $self->get_hoa_by_lab_numonly_across(%args);
    croak 'Variable data must be numeric and not empty'
      if not ref $data
      or not scalar keys %{$data};    # $self->all_numeric( values %{$data} );
    my ( $ranks_href, $xtied_href ) = _ranks_within($data);
    return wantarray ? ( $ranks_href, $xtied_href ) : $ranks_href;
}

=head2 sum_of_ranks_between

 $sor = $rankd->sum_of_ranks_between(); # all pre-loaded data
 $sor = $rankd->sum_of_ranks_between(data => HASHREF); # or using these data
 $sor = $rankd->sum_of_ranks_between(lab => STRING); # or for a particular load

Returns the sum of ranks for (1) the entire dataset, either as given in argument B<data>, or all pre-loaded variables; or for a particular pre-loaded dataset (variable) as given in the named argument B<lab>, where (assuming more than one variable), all values have been pooled and ordered by value per variable.

=cut

sub sum_of_ranks_between {
    my ( $self, %args ) = @_;
    my $lab        = delete $args{'lab'};
    my $ranks_href = $self->ranks_between(%args);
    if ( hascontent($lab) ) {
        croak 'Named variable does not exist'
          if !exists $ranks_href->{$lab};
        return sum0( @{ $ranks_href->{$lab} } );
    }
    else {
        return {
            map { $_ => sum0( @{ $ranks_href->{$_} } ) }
              keys %{$ranks_href}
        };
    }
}

=head2 sum_of_ranks_within

 $sor = $rankd->sum_of_ranks_within(); # all pre-loaded data
 $sor = $rankd->sum_of_ranks_within(data => HASHREF); # or using these data
 $sor = $rankd->sum_of_ranks_within(lab => STRING); # or for a particular load

If called in array context, the sum-href is returned followed by the href of ties (useful for some statistic). Otherwise, it returns the href of summed ranks. The sum for a particular named variable can also be returned by the argument B<lab>.

=cut

sub sum_of_ranks_within {
    my ( $self, %args ) = @_;
    my $lab = delete $args{'lab'};
    my ( $ranks_href, $xtied_href ) = $self->ranks_within(%args);
    if ( hascontent($lab) ) {
        croak 'Named variable does not exist'
          if !exists $ranks_href->{$lab};
        return sum0( @{ $ranks_href->{$lab} } );
    }
    else {
        my $sums =
          { map { $_ => sum0( @{ $ranks_href->{$_} } ) } keys %{$ranks_href} };
        return wantarray ? ( $sums, $xtied_href ) : $sums;
    }
}

=head2 sumsq_ranks_within

Returns the sum of the squared sums-of-ranks calculated dependently (per the values across individual indices). Used in L<Friedman ANOVA|Statistics::ANOVA::Friedman>. Expects a hashref of the variables, keyed by name. Called in list context, also returns a hash of the tied ranks.

=cut

sub sumsq_ranks_within {
    my ( $self,       %args )       = @_;
    my ( $ranks_href, $xtied_href ) = $self->ranks_within(%args);
    my $sumsq = sum0( map { sum0( @{$_} )**2 } values %{$ranks_href} );
    return wantarray ? ( $sumsq, $xtied_href ) : $sumsq;
}

sub _ranks_between {
    my $href_of_data          = shift;
    my $href_of_lab_by_values = _hash_of_aref_names_per_values($href_of_data);
    my @sorted = sort { $a <=> $b } keys %{$href_of_lab_by_values};
    my ( $nties, $ties_var, @xtied, %ranks ) = ( 1, 0 );
    for my $i ( 0 .. scalar @sorted - 1 ) {    # loop thru all values in order
        my @groups = @{ $href_of_lab_by_values->{ $sorted[$i] } };
        my $nties_i = scalar @groups;    # for values within all and any group
        if ( $nties_i > 1 ) {            # must be ties
            $ties_var += ( $nties_i**3 - $nties_i );
            for (@groups) {
                push @{ $ranks{$_} }, mean( $nties .. $nties + $nties_i - 1 );
            }
            $nties += $nties_i;
        }
        else {
            push @{ $ranks{ $groups[0] } }, $nties++;
        }
        push @xtied, $nties_i;
    }
    $nties--;
    return ( \%ranks, \@xtied, $nties, $ties_var )
      ;    # rank hash-of-arefs, tie-correction, N, ari of tied group Ns
}

sub _ranks_within {
    my $href_of_data = shift;
    my ( $old, $cur, $col, $ties, $av_rank, %ranks, %row_values ) = ( 0, 0 );
    my %xtied = ();

# - set the averaged ranks, going down each index:
# - list the values at this index in each data-array:
# - a value might occur in more than one var at this index, so store an array of the vars:

    for my $i ( 0 .. _min_n_of_hoa($href_of_data) - 1 ) {
        for ( keys %{$href_of_data} ) {
            push @{ $row_values{ ( @{ $href_of_data->{$_} } )[$i] } },
              $_;    # hash with values as keys and names as arefs
        }

       # loop adapted from Boggs' "rank" function in Statistics-RankCorrelation:
        for my $rval ( sort { $a <=> $b } keys %row_values ) {
            $ties =
              scalar @{ $row_values{$rval} };  # N vars of same value per source
            $cur += $ties;
            if ( $ties > 1 ) {
                $av_rank = $old + ( $ties + 1 ) / 2;    # average tied data
                for ( @{ $row_values{$rval} } ) {
                    push @{ $ranks{$_} }, $av_rank;
                }
                push @{ $xtied{$i} }, $ties;
            }
            else {
                push @{ $ranks{ $row_values{$rval}[0] } }, $cur;
                push @{ $xtied{$i} }, $ties;
            }
            $old = $cur;
        }
        ( $old, $cur, %row_values ) = ( 0, 0 );
    }
    return ( \%ranks, \%xtied );
}

# create a hash from a hash of named data where the keys are the values of the data linked to an aref of the names

sub _hash_of_aref_names_per_values {
    my $hoa     = shift;
    my %grouped = ();
    for my $name ( keys %{$hoa} ) {
        for ( @{ $hoa->{$name} } ) {
            push @{ $grouped{$_} }, $name;
        }
    }
    return \%grouped;
}

sub _min_n_of_hoa {
    my $data = shift;
    return min( map { count( @{ $data->{$_} } ) } keys %{$data} );
}

=head1 DEPENDENCIES

L<List::AllUtils|List::AllUtils> : used for summing.

L<Statistics::Data|Statistics::Data> : used as base.

L<Statistics::Lite|Statistics::Lite> : for basic decriptives.

L<String::Util|String::Util> : string content checking.

=head1 DIAGNOSTICS

=over 4

=item Variable data must be numeric and not empty

C<croak>ed ahead of calculating (sum of) ranks between or within and there is no hashref of data available.

=item Named variable does not exist

C<croak>ed by sum_of_ranks_between and sum_of_ranks_within if the value of the optional argument B<lab> does not exist as pre-loaded data; either in a call to L<load|Statistics::Data/load> or L<add|Statistics::Data/add>, or as B<data> in the present method. 

=back

=head1 REFERENCES

Siegal, S. (1956). I<Nonparametric statistics for the behavioral sciences>. New York, NY, US: McGraw-Hill

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-statistics-data-rank-0.02 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Data-Rank-0.02>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Data::Rank


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Data-Rank-0.02>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Data-Rank-0.02>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Data-Rank-0.02>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Data-Rank-0.02/>

=back

=head1 ACKNOWLEDGEMENTS

L<Statistics::RankCorrelation|Statistics::RankCorrelation> : loop for dealing with ties in calculating "ranks within" adapted from Boggs' "rank" function.

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;    # End of Statistics::Data::Rank
