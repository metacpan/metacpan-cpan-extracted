package Set::Integer::Gapfillers;
$VERSION = '0.08';
use strict;
use Carp;

sub new {
    my $class = shift;
    my $initref = _args_check(@_);
    return bless $initref, $class;
}

sub all_segments {
    my $self = shift;
    my %params = _check_extra_args(@_);
    _expand_upon_request($self->{segments}, \%params);
}

sub gapfillers {
    my $self = shift;
    my %params = _check_extra_args(@_);
    my @segments = @{$self->{segments}};
    my @gaps;
    for (my $n = 0; $n <= $#segments; $n++) {
        push @gaps, $segments[$n] unless $self->{statuses}->[$n];
    }
    _expand_upon_request( [ @gaps ], \%params);
}

sub segments_needed {
    my $self = shift;
    my %params = _check_extra_args(@_);
    my @segments_needed = @{ $self->{segments} };
    # If the lower bound to the requested range fell in a provided segment,
    # then the first segment returned may have "unneeded" elements on its
    # lower side.
    # Analogously, if the upper bound fell in a provided segment,
    # then the last segment returned may have "unneeded" elements on its
    # upper side.
    # We need to snip these unneeded elements off.
    if ($self->{statuses}->[0]) {
        if ($segments_needed[0]->[0] < $self->{lower}) {
            $segments_needed[0]->[0] = $self->{lower};
        }
    }
    if ($self->{statuses}->[-1]) {
        if ($segments_needed[-1]->[1] > $self->{upper}) {
            $segments_needed[-1]->[1] = $self->{upper};
        }
    }
    _expand_upon_request([ @segments_needed ], \%params);
}

sub _args_check {
    my %args = @_;
    croak "Need lower bound: $!" unless defined $args{lower};
    croak "Need upper bound: $!" unless defined $args{upper};
    croak "Lower bound must be numeric: $!" unless $args{lower} =~ /^-?\d+$/;
    croak "Upper bound must be numeric: $!" unless $args{upper} =~ /^-?\d+$/;
    croak "Upper bound must be >= lower bound: $!" 
        unless $args{upper} >= $args{lower};
    croak "Need 'sets' argument: $!" unless defined $args{sets};
    croak "'sets' must be array reference: $!"
        unless ref($args{sets}) eq 'ARRAY'; 
    foreach my $pairref (@{$args{sets}}) {
        croak "Elements of 'sets' must be 2-element array references: $!"
            unless scalar(@{$pairref}) == 2;
        foreach my $n (@{$pairref}) {
            croak "Elements of sets must be numeric: $!"
                unless $n =~ /^-?\d+$/;
        }
        croak "First element of each array must be <= second element\n$pairref->[0] has problem: $!"
            unless $pairref->[0] <= $pairref->[1];
    }
    my @sets = sort { $a->[0] <=> $b->[0] } @{$args{sets}};
    my (@firsts, @seconds);
    for (my $i=0; $i<=$#sets; $i++) {
        if ($i > 0) {
            croak "First element of each array must be > second element of previous array: $!"
                unless ($sets[$i]->[0] > $sets[$i-1]->[1]);
        } else {
            1;
        }
        $firsts[$i]  = $sets[$i]->[0];
        $seconds[$i] = $sets[$i]->[1];
    }
    my %intermediate;
    $intermediate{sets}    = \@sets;
    $intermediate{firsts}  = \@firsts;
    $intermediate{seconds} = \@seconds;
    $intermediate{lower}   = $args{lower};
    $intermediate{upper}   = $args{upper};
    my ($segmentsref, $statusref) = _calculate(%intermediate);
    my %init = (
        segments    => $segmentsref,
        statuses    => $statusref,
        lower       => $intermediate{lower},
        upper       => $intermediate{upper},
    );
    return \%init;
}

sub _calculate {
    my %args = @_;
    my @all_segments;
    my @statuses;
    my %status;
    # Inspect for either of two oddball but easy-to-compute cases.
    # Cases of $args{lower} in gap after last provided segment 
    #      and $args{upper} in gap before first provided segment
    if (
        $args{firsts}->[0]   > $args{upper} 
             or
        $args{seconds}->[-1] < $args{lower} 
    ) {
        push @all_segments, [ $args{lower}, $args{upper} ];
        push @statuses, 0;
        return (\@all_segments, \@statuses);
    }
    my $i = 0;
    my $j = scalar(@{$args{seconds}}) - 1;
    $i++ until ( $args{lower} <  $args{firsts}->[$i] );
    $j-- while ( $args{upper} <  $args{firsts}->[$j] );
    # $status{xxx} true:  starting (ending) in provided segment
    # $status{xxx} false: starting (ending) in subsequent gap
    $status{lower} = ($args{lower} <= $args{seconds}->[$i-1]) ? 1 : 0;
    $status{upper} = ($args{upper} <= $args{seconds}->[$j]  ) ? 1 : 0;

    # Case of $args{lower} in gap below the first provided segment.
    # I have to handle this separately because its $i value would be -1 ... 
    # which would created problems if used as an array subscript
    if ($args{lower} < $args{firsts}->[0]) {
        push @all_segments, [ $args{lower}, $args{firsts}->[0] - 1 ];
        push @statuses, 0;
        if ($j == 0) {
                push @all_segments, $args{sets}[0];
                push @statuses, 1;
            if (! $status{upper}) {
                push @all_segments, [ $args{seconds}->[0] + 1, $args{upper} ];
                push @statuses, 0;
            }
        } else {
            for my $p (0..$j-1) {
                push @all_segments, $args{sets}[$p];
                push @statuses, 1;
                unless ($args{seconds}->[$p] + 1 == $args{firsts}->[$p+1]) {
                    push @all_segments, 
                        [ $args{seconds}->[$p] + 1, $args{firsts}->[$p+1] - 1 ];
                    push @statuses, 0;
               } 
            }
            push @all_segments, $args{sets}[$j];
            push @statuses, 1;
            if (! $status{upper}) {
                push @all_segments, 
                    [ $args{seconds}->[$j] + 1, $args{upper} ];
                push @statuses, 0;
            }
        }
        return (\@all_segments, \@statuses);
    }

    # Cases where $args{lower} and $args{upper} occur within same interior
    # provided segment/following gap pair
    # 3 sub-cases:
    # both in segment
    # lower in segment; upper in gap
    # both in gap
    # I want to handle these here so that subsequently I can proceed on
    # assumption that lower and upper are in different pairs
    my $h = $i - 1;
    if ($h == $j) {
        if ($status{lower} and $status{upper}) {
            push @all_segments, $args{sets}[$h];
            push @statuses, 1;
        } elsif ($status{lower} and ! $status{upper}) {
            push @all_segments, $args{sets}[$h];
            push @statuses, 1;
            push @all_segments, 
                [ $args{seconds}->[$h] + 1, $args{upper} ];
            push @statuses, 0;
        } elsif (! $status{lower} and ! $status{upper}) {
            push @all_segments, [ $args{lower}, $args{upper} ];
            push @statuses, 0;
        }
        return (\@all_segments, \@statuses);
    }
    # So now I'm ready to handle the remaining -- and most likely to occur --
    # cases:  Starting in one segment-gap pair (other than the first) and
    # ending in a different segment-gap pair.
    # First handle the location of the lower bound:
    if ($status{lower}) {
        push @all_segments, $args{sets}[$h];
        push @statuses, 1;
        push @all_segments, 
            [ $args{seconds}->[$h] + 1, $args{firsts}->[$i] - 1 ];
        push @statuses, 0;
    } else {
        push @all_segments, 
            [ $args{lower}, $args{firsts}->[$i] - 1 ];
        push @statuses, 0;
    }
    # Next handle all other segment-gap pairs except the last:
    for my $p ($i..$j-1) {
        push @all_segments, $args{sets}[$p];
        push @statuses, 1;
        unless ($args{seconds}->[$p] + 1 == $args{firsts}->[$p+1]) {
            push @all_segments, 
                [ $args{seconds}->[$p] + 1, $args{firsts}->[$p+1] - 1 ];
            push @statuses, 0;
       } 
    }
    # Finally, handle the final segment and possible gap:
    push @all_segments, $args{sets}[$j];
    push @statuses, 1;
    if (! $status{upper}) {
        push @all_segments, 
            [ $args{seconds}->[$j] + 1, $args{upper} ];
        push @statuses, 0;
    }
    return (\@all_segments, \@statuses);
}

sub _expand_upon_request {
    my $compressed_ref = shift;
    my $paramsref = shift;
    if (defined $paramsref->{expand} and $paramsref->{expand}) {
        my @expanded;
        foreach my $pairref (@{$compressed_ref}) {
            push @expanded, [ $pairref->[0] .. $pairref->[1] ];
        }
        return [ @expanded ];
    } else {
        return $compressed_ref;
    }
}

sub _check_extra_args {
    my @args = @_;
    my %params;
    if ( scalar(@args) ) {
        unless ( scalar(@args) % 2 ) {
            %params = @args;
        } else {
            croak "Need even number of arguments: $!";
        }
    }
    return %params;
}

1;

#################### DOCUMENTATION #################### 

=head1 NAME

Set::Integer::Gapfillers - Fill in the gaps between integer ranges

=head1 SYNOPSIS

    use Set::Integer::Gapfillers;
    $gf = Set::Integer::Gapfillers->new(
        lower   => -12,
        upper   =>  62,
        sets    => [
            [  1, 17 ],     # Note:  Use comma, not 
            [ 25, 42 ],     # range operator (..)
            [ 44, 50 ],
        ],
    );

    $segments_needed_ref = $gf->segments_needed();

    $gapfillers_ref      = $gf->gapfillers();

    $all_segments_ref    = $gf->all_segments();

Any of the three preceding output methods can also be called with an C<expand>
option:

    $segments_needed_ref = $gf->segments_needed( expand => 1 );

=head1 DESCRIPTION

This Perl extension provides methods which may be useful in manipulating sets
whose elements are consecutive integers.  Suppose that you are provided with
the following non-intersecting, non-overlapping sets of consecutive integers:

    {  1 .. 17 } 
    { 25 .. 42 } 
    { 44 .. 50 }

Suppose further that you are provided with the following lower and upper
bounds to a range of consecutive integers:

    lower:  12
    upper:  62

Provide a set of sets which:

=over 4

=item *

when joined together, would form a set of consecutive integers from the 
lower to the upper bound, inclusive; and 

=item *

are derived from:

=over 4

=item *

the sets provided;

=item *

proper subsets thereof; or

=item *

newly generated sets which fill in the gaps below, in between or above the 
provided sets.

=back

=back

Once a Set::Integer::Gapfillers object has been constructed, its C<segments_needed()>
method can be used to provide these results:

    { 12 .. 17 }    # subset of 1st set provided
    { 18 .. 24 }    # gap-filler set
    { 25 .. 42 }    # 2nd set provided
    { 43 .. 43 }    # gap-filler set
                    # (which happens to consist of a single element)
    { 44 .. 50 }    # 3rd set provided
    { 51 .. 62 }    # gap-filler set for range above highest provided set

Alternatively, you may only wish to examine the gap-filler sets.  The 
C<gapfillers()> method provides this set of sets.

    { 18 .. 24 }    # gap-filler set
    { 43 .. 43 }    # gap-filler set
    { 51 .. 62 }    # gap-filler set

And, as an additional alternative, you may wish to have your set of sets begin
or end with I<all> the values of a given provided set, rather than a proper
subset thereof containing only those values needed to populate the desired
range.  In that case, use the C<all_segments()> method.

    {  1 .. 17 }    # 1st set provided
    { 18 .. 24 }    # gap-filler set
    { 25 .. 42 }    # 2nd set provided
    { 43 .. 43 }    # gap-filler set
                    # (which happens to consist of a single element)
    { 44 .. 50 }    # 3rd set provided
    { 51 .. 62 }    # gap-filler set for range above highest provided set

The results returned by the C<all_segments()> method differ from those
returned by the C<segments_needed()> method only at the lower or upper ends.
If, as in the above example, the lower bound of the target range of integers
falls inside a provided segment, the first set returned by
C<all_segments()> will be the I<entire> first set provided; the first set
returned by C<segments_needed()> will be a I<proper subset> of the first set
provided, starting with the requested lower bound.

=head1 USAGE

=head2 Publicly Callable Methods

=head3 C<new()>

    $gf = Set::Integer::Gapfillers->new(
        lower   => -12,
        upper   =>  62,
        sets    => [
            [  1, 17 ],     # Note:  Use comma, not 
            [ 25, 42 ],     # range operator (..)
            [ 44, 50 ],
        ],
    );

B<Purpose:>  Constructor of a Set::Integer::Gapfillers object.

B<Arguments:>  List of key-value pairs.  C<lower> and C<upper> take integers
denoting the lower and upper bounds of the range of integers desired as the
result.  C<sets> takes a reference to an anonymous array whose elements are,
in turn, references to anonymous arrays whose B<two> elements are the lowest
and highest numbers in a range of consecutive integers.

I<Note:>  The sets of consecutive integers supplied must be non-overlapping.
Set::Integer::Gapfillers will C<croak> if supplied with arguments such as these:

    $gf = Set::Integer::Gapfillers->new(
        lower   => -12, upper   =>  62,
        sets    => [
            [  1, 30 ],   # no good:  overlaps with next set
            [ 25, 48 ],   # no good:  overlaps with previous and next sets 
            [ 44, 50 ],   # no good:  overlaps with previous set
        ],
    );

I<Note:>  Only two elements should be supplied in the anonymous arrays
supplied as elements to the array reference which is the value of C<sets>:
the lowest and highest (or, first and last) elements in each array.  You
should B<not> use Perl's range operator (I<e.g.,> C<[ 25 .. 48 ]>) in this
instance.

B<Returns:>  A Set::Integer::Gapfillers object.

=head3 C<segments_needed()>

    $segments_needed_ref   = $gf->segments_needed();

B<Purpose:>  Generate a set of sets which (a) when joined together, would 
form a set of consecutive integers from the lower to the upper bound, 
inclusive; and (b) are derived from (i) the sets provided; (ii) proper 
subsets thereof; or (iii) newly generated sets which fill in the gaps below, 
in between or above the provided sets.

B<Arguments:>  None required.  C<expand => 1> is optional (see FAQ).

B<Returns:>  A reference to an anonymous array whose elements are, in turn,
anonymous arrays of two elements:  the lowest and highest integers in a
particular subset.  But when the C<expand> option is set, the return value is
a reference to an anonymous array whose elements are, in turn, references to
arrays each of which holds I<the entire range> of each set needed -- not just
the beginning and end points.


=head3 C<gapfillers()>

    $gapfillers_ref = $gf->gapfillers();

B<Purpose:>  Generate a set of the newly generated sets needed to fill in the
gaps below, in between or above the sets provided to the constructor.  The
sets, like those returned by C<segments_needed()>, are denoted by their lower
and upper bounds rather than by their entire contents.

B<Arguments:>  None required.  C<expand => 1> is optional (see FAQ).

B<Returns:>  A reference to an anonymous array whose elements are, in turn,
anonymous arrays holding two elements: the lower and upper bounds of the
integer ranges needed to provide gap-filling as described in 'Purpose'.  When
the C<expand> option is set, the contents of those inner sets are expanded to
include the full range of integers needed, not just the beginning and end
points.

=head3 C<all_segments()>

    $all_segments_ref = $gf->all_segments();

B<Purpose:>  Generate a set of all sets needed in order to populate a set of 
consecutive integers from the lower to the upper bound, inclusive.  The sets
generated are derived from (a) the sets provided or (b) newly generated sets 
which fill in the gaps below, in between or above the provided sets.  

B<Arguments:>  None required.  C<expand => 1> is optional (see FAQ).

B<Returns:>  A reference to an anonymous array whose elements are, in turn,
anonymous arrays holding the sets described in 'Purpose'.  When
the C<expand> option is set, the contents of those inner sets are expanded to
include the full range of integers needed, not just the beginning and end
points.

=head1 FAQ

=over 4

=item 1.  How do the sets returned by the three non-constructor methods differ from one another?

With C<segments_needed()>, the objective is:  I<Show me whether the integers 
I need to fill the desired range will come from sets already provided or from 
newly created gap-filling sets.>

With C<gapfillers()>, the objective is:  I<Show me the sets of integers I 
will need to create to fill the gaps between the sets already provided.> 

With C<all_segments()>, the objective is:  I<Show me all the sets of integers
-- those already provided and those I will have to create -- from which I will
pull integers to populate the desired range.>

Here are two examples:

=over 4

=item *

    $gf = Set::Integer::Gapfillers->new(
        lower   =>  10,
        upper   =>  22,
        sets    => [
            [  9, 11 ],
            [ 15, 18 ],
            [ 20, 24 ],
        ],
    );

The three non-constructor methods return sets as follows:

                      9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
    segments_needed:     A  A  B  B  B  C  C  C  C  D  E  E  E
    gapfillers:                B  B  B              D
    all_segments:     A  A  A  B  B  B  C  C  C  C  D  E  E  E  E  E

... where C<A>, C<C> and C<E> are elements coming from provided sets and C<B>
and C<D> are coming from newly-created gap-filling sets.

=item *

    $gf = Set::Integer::Gapfillers->new(
        lower   =>  10,
        upper   =>  22,
        sets    => [
            [  9, 11 ],
            [ 15, 18 ],
            [ 20, 20 ],
        ],
    );

The three non-constructor methods return sets as follows:

                      9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
    segments_needed:     A  A  B  B  B  C  C  C  C  D  E  F  F
    gapfillers:                B  B  B              D     F  F
    all_segments:     A  A  A  B  B  B  C  C  C  C  D  E  F  F       

... where C<A>, C<C> and C<E> are elements coming from provided sets and C<B>,
C<D> and C<F> are coming from newly-created gap-filling sets.

=back

=item 2.  Why do the output methods, by default, return references to two-element arrays rather than the full range of integers needed?

Memory and speed.

In an earlier implementation, F<Set::Integer::Gapfillers> calculated its return values
by supplying the constructor's C<sets> argument with a list of references to 
arrays of consecutive integers -- C<[ 12 .. 22 ]> -- rather than a list of
references to two-element arrays of the lower and upper bounds of the integer
ranges desired -- C<[ 12, 22 ]>.  All internal calculations were made by
comparing the lower and upper bounds supplied with the arrays supplied.  This
proved to be a memory hog and slow.  

F<Set::Integer::Gapfillers> was then revised to
require the user to supply only the beginning and end points of the provided
segments.  Although this complicated the logic of the internal calculations
for the module author, it led to a vastly reduced memory footprint and vast
speedup in producing results.  It was therefore decided to make the output
methods return values in the same manner, I<i.e.,> beginning and end points of
ranges, rather than the entire ranges.

However, what an end-user of F<Set::Integer::Gapfillers> might really be after is those
entire ranges.  Hence, the C<expand => 1> option is provided so that the
results look like this:

    $gf = Set::Integer::Gapfillers->new(
        lower   => -12,
        upper   =>  62,
        sets    => [
            [  1, 17 ],
            [ 25, 42 ],
            [ 44, 50 ],
        ],
    );

    $segments_needed_ref = $gf->( expand => 1);
    __END__
    $segments_needed_ref: [
        [-12 ..  0 ],   # without 'expand':  [ -12, 0 ]
        [  1 .. 17 ],
        [ 18 .. 24 ],
        [ 25 .. 42 ],
        [ 43 .. 43 ],
        [ 44 .. 50 ],
        [ 51 .. 62 ],
    ]

=back

=head1 BUGS

None reported so far.

=head1 SUPPORT

Via e-mail to author at address below.

=head1 AUTHOR

    James E Keenan
    CPAN ID: JKEENAN
    jkeenan@cpan.org
    http://search.cpan.org/~jkeenan/

=head1 ACKNOWLEDGEMENTS

This Perl extension has its origin in a question I posed on Perlmonks
(L<http://perlmonks.org/?node_id=539350>).  BrowserUK's response
(L<http://perlmonks.org/?node_id=539357>) was ingenious and terse and led me
to think that the solution could be modularized.  However, when I realized
that my original question had not fully specified my objective, I found I
could no longer use BrowserUK's algorithm and had to work my own out -- so any
bugs are my fault, not his!

=head1 COPYRIGHT

Copyright 2006.  James E. Keenan.  United States.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).  During the Perlmonks thread mentioned in ACKNOWLEDGMENTS, reference
was made to CPAN module Set::Infinite (L<http://search.cpan.org/dist/Set-Infinite/>), and specifically to
C<Set::Infinite::minus()> as possibly providing another solution to the
gap-filling problem.  Set::Array and Set::Scalar should also be consulted if
you need a wider arrange of methods to perform set operations.

=cut
