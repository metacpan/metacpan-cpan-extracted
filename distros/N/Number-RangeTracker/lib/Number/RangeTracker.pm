package Number::RangeTracker;
use strict;
use warnings;
use List::Util 'max';
use List::MoreUtils qw(lastidx lastval);
use Scalar::Util 'looks_like_number';
use Carp;
use Mouse;

=head1 NAME

Number::RangeTracker - Keep track of numerical ranges quickly

=head1 VERSION

Version 0.6.1

=cut

our $VERSION = '0.6.1';

=head1 SYNOPSIS

Create and modify ranges (three range syntaxes shown):

    my $range = Number::RangeTracker->new;
    $range->add( [ 1, 10 ], '11..20' );
    $range->remove( 6, 15 );

Output ranges, their complement, or integers within ranges
(differences between scalar and list contexts shown):

    $range->output;
      # Scalar context: '1..5,16..20'
      # List context:   ( 1 => 5, 16 => 20 )

    $range->complement;
      # Scalar context: '-inf..0,6..15,21..+inf'
      # List context:   ( -inf => 0, 6 => 15, 21 => +inf )

    $range->integers;
      # Scalar context: '1,2,3,4,5,16,17,18,19,20'
      # List context:   ( 1, 2, 3, 4, 5, 16, 17, 18, 19, 20 )

Examine range characteristics:

    $range->length;              # 8
    $range->size;                # 10

    $range->is_in_range(100);    # 0
    $range->is_in_range(18);     # 1, 16, 20

=head1 DESCRIPTION

An instance of the Number::RangeTracker class is used to keep track of
a set of numerical ranges. Ranges can be added to and removed from
this collection of ranges. Overlapping ranges are collapsed to form a
single, longer range. Ranges can be manipulated, examined, and output
in a variety of ways.

While some other modules associate values with a range of keys (see
L</SEE ALSO>), the objective of Number::RangeTracker is to quickly and
easily monitor the integers on a number line that are covered by at
least one range. Number::RangeTracker performs significantly faster
than other modules that have similar functions (see L</SEE ALSO>).

=over 4

=item new

Initializes a new Number::RangeTracker object.

=cut

has '_added'   => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has '_removed' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has '_messy_add' => ( is => 'rw', isa => 'Bool', default => 0 );
has '_messy_rem' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'units'      => ( is => 'ro', isa => 'Num',  default => 1 );
has 'start'      => ( is => 'rw', isa => 'Num' );
has 'end'        => ( is => 'rw', isa => 'Num' );

=item add( START, END )

Add one or more ranges. This can be used multiple times to add ranges
to the object. Ranges can be added in several ways. The following are
equivalent.

    $range->add( [ 1, 10 ], [ 16, 20 ] );
    $range->add( 1, 10, 16, 20 );
    $range->add( '1..10', '16..20' );

=cut

sub add {
    my $self = shift;

    my $ranges = _get_range_inputs(@_);
    while ( scalar @$ranges ) {
        my ( $start, $end ) = splice @$ranges, 0, 2;
        $self->_update_range( $start, $end, '_added' );
    }
}

sub _get_range_inputs {
    my @range_input = @_;

    my @ranges;
    for (@range_input) {
        if ( ref $_ eq "ARRAY" ) {    # [ 1, 10 ], [ 16, 20 ]
            push @ranges, @$_;
        }
        elsif (/^\d+\.\.\d+$/) {      # '1..10', '16..20'
            push @ranges, split /\.\./;
        }
        else {                        # 1, 10, 16, 20
            push @ranges, $_;
        }
    }

    croak "Odd number of elements in input ranges (start/stop pairs expected)"
        if scalar @ranges % 2 != 0;

    return \@ranges;
}

=item remove( START, END )

Remove one or more ranges from the current set of ranges. This can be
used multiple times to remove ranges from the object. Ranges can be
removed with the same syntax used for adding ranges.

=cut

sub remove {
    my $self = shift;

    my $ranges = _get_range_inputs(@_);
    while ( scalar @$ranges ) {
        my ( $start, $end ) = splice @$ranges, 0, 2;
        $self->_update_range( $start, $end, '_removed' );
    }
}

sub _update_range {
    my $self = shift;

    my ( $start, $end, $add_or_rem ) = @_;

    $self->collapse
        if $self->_messy_rem && $add_or_rem eq '_added';

    croak "'$start' not a number in range '$start to $end'"
        unless looks_like_number $start;
    croak "'$end' not a number in range '$start to $end'"
        unless looks_like_number $end;

    if ( $start > $end ) {
        carp
            "Warning: Range start ($start) is greater than range end ($end); values have been swapped";
        ( $start, $end ) = ( $end, $start );
    }

    if ( exists $self->{$add_or_rem}{$start} ) {
        $self->{$add_or_rem}{$start}
            = max( $end, $self->{$add_or_rem}{$start} );
    }
    else {
        $self->{$add_or_rem}{$start} = $end;
    }

    if ( $add_or_rem eq '_added' ) {
        $self->_messy_add(1);
    }
    else {
        $self->_messy_rem(1);
    }
}

=item collapse

When ranges are added or removed, overlapping ranges are not collapsed
until necessary. This allows range Number::RangeTracker to be very
fast.

Ranges can be manually collapsed to avoid memory issues when
working with very large amounts of ranges. In one test, a million
overlapping ranges required ~100 MB of memory. This requirement was
cut drastically by collapsing ranges after every 100,000th range was
added.

Ranges are automatically collapsed (and merged or removed where
appropriate) (1) before ranges are added (if there are ranges still
waiting to be removed) and (2) before each of the following methods is
executed.

=cut

sub collapse {
    my $self = shift;

    return unless $self->_messy_add || $self->_messy_rem;

    $self->_collapse_ranges('_added') if $self->_messy_add;

    if ( $self->_messy_rem ) {
        $self->_collapse_ranges('_removed');
        $self->_remove_ranges;
    }

    $self->_messy_add(0);
    $self->_messy_rem(0);
}

sub _collapse_ranges {
    my $self = shift;

    my $add_or_rem = shift;

    my @cur_interval;
    my %temp_ranges;

    for my $start ( sort { $a <=> $b } keys %{ $self->{$add_or_rem} } ) {
        my $end = $self->{$add_or_rem}{$start};

        unless (@cur_interval) {
            @cur_interval = ( $start, $end );
            next;
        }

        my ( $cur_start, $cur_end ) = @cur_interval;
        if ( $start <= $cur_end + 1 ) {    # +1 makes it work for integer ranges only
            @cur_interval = ( $cur_start, max( $end, $cur_end ) );
        }
        else {
            $temp_ranges{ $cur_interval[0] } = $cur_interval[1];
            @cur_interval = ( $start, $end );
        }
    }
    $temp_ranges{ $cur_interval[0] } = $cur_interval[1];
    $self->{$add_or_rem} = \%temp_ranges;
}

sub _remove_ranges {
    my $self = shift;

    my @starts = sort { $a <=> $b } keys %{ $self->_added };

    for my $start ( sort { $a <=> $b } keys %{ $self->_removed } ) {
        my $end = $self->{_removed}{$start};

        my $left_start_idx  = lastidx { $_ < $start } @starts;
        my $right_start_idx = lastidx { $_ <= $end } @starts;

        my $left_start  = $starts[$left_start_idx];
        my $right_start = $starts[$right_start_idx];
        next unless defined $left_start && defined $right_start;

        my $left_end  = $self->{_added}{$left_start};
        my $right_end = $self->{_added}{$right_start};

        # range to remove touches the start of at least one added range
        if ( $right_start_idx - $left_start_idx > 0 ) {
            delete @{ $self->{_added} }
                { @starts[ $left_start_idx + 1 .. $right_start_idx ] };
            splice @starts, 0, $right_start_idx + 1 if $right_start_idx > -1;
        }
        else {
            splice @starts, 0, $left_start_idx + 1 if $left_start_idx > -1;
        }

        # range to remove starts inside an added range
        if ( $start <= $left_end && $left_start_idx != -1 ) {
            $self->{_added}{$left_start} = $start - 1;
        }

        # range to remove ends inside an added range
        if ( $end >= $right_start && $end < $right_end ) {
            my $new_start = $end + 1;
            $self->{_added}{$new_start} = $right_end;
            unshift @starts, $new_start;
        }

        delete ${ $self->{_removed} }{$start};
    }
}

=item length

Returns the total length of all ranges combined.

=cut

sub length {
    my $self = shift;

    $self->collapse;

    my $length = 0;
    for ( keys %{ $self->_added } ) {
        $length += $self->{_added}{$_} - $_;
    }
    return $length;
}

=item size

Returns the total number of elements (i.e., integers) of all ranges.

=cut

sub size {
    my $self = shift;

    $self->collapse;

    my $size = 0;
    for ( keys %{ $self->_added } ) {
        $size += $self->{_added}{$_} - $_ + 1;    # +1 makes it work for integer ranges only
    }
    return $size;
}

=item is_in_range( VALUE )

Test whether a VALUE is contained within one of the ranges. Returns 0
for a negative result. Returns a list of three numbers for a positive
result: 1, start position of the containing range, end position of the
containing range.

=cut

sub is_in_range {
    my $self = shift;

    my $query = shift;

    $self->collapse;

    my @starts = sort { $a <=> $b } keys %{ $self->_added };
    my $start = lastval { $_ <= $query } @starts;

    return 0 unless defined $start;

    my $end = $self->{_added}{$start};
    if ( $end < $query ) {
        return 0;
    }
    else {
        return ( 1, $start, $end );
    }

}

=item output

Returns all ranges sorted by their start positions. In list context,
returns a list of all ranges sorted by start positions. This is
suitable for populating a hash, an array, or even another range
object. In scalar context, returns a string of ranges formatted as:
C<1..10,16..20>.

=cut

sub output {
    my $self = shift;

    $self->collapse;

    if ( wantarray() ) {
        return %{ $self->_added };
    }
    elsif ( defined wantarray() ) {
        return join ',', map {"$_..$self->{_added}{$_}"}
            sort { $a <=> $b } keys %{ $self->_added };
    }
    elsif ( !defined wantarray() ) {
        carp 'Useless use of output() in void context';
    }
    else { croak 'Bad context for output()'; }
}

=item integers

Returns each integer contained within the ranges. In list context,
returns a sorted list. In scalar context, returns a sorted,
comma-delimited string of integers.

=cut

sub integers {
    my $self = shift;

    my @ranges = split ",", $self->output;
    my @elements;

    for (@ranges) {
        for my $value ( eval $_ ) {
            push @elements, $value;
        }
    }

    if ( wantarray() ) {
        return @elements;
    }
    elsif ( defined wantarray() ) {
        return join ',', @elements;
    }
    elsif ( !defined wantarray() ) {
        carp 'Useless use of output_elements() in void context';
    }
    else { croak 'Bad context for output_elements()'; }
}

=item complement( UNIVERSE_START, UNIVERSE_END )

Returns the complement of a set of ranges. The output is in list
context sorted by range start positions.

    my $original_range = Number::RangeTracker->new;
    $original_range->add( [ 11, 20 ], [ 41, 60 ], [ 91, 110 ] );

    my %complement = $original_range->complement;
    # -inf => 10,
    # 21   => 40,
    # 61   => 90,
    # 111  => +inf

UNIVERSE_START and UNIVERSE_END can be used to specify a finite subset
of the 'universe' of numbers (defaults are -/+ infinity. The
complement ranges are bounded by these values.

    %complement = $original_range->complement( 1, 50 );
    # 1  => 10,
    # 21 => 40

A new object with the complement of a set of ranges can be created
quickly and easily.

    my $complement_range = Number::RangeTracker->new;
    $complement_range->add( $original_range->complement );

=cut

sub complement {
    my ( $self, $universe_start, $universe_end ) = @_;

    $universe_start = '-inf' unless defined $universe_start;
    $universe_end   = '+inf' unless defined $universe_end;

    my $complement = Number::RangeTracker->new;
    $complement->add( $universe_start, $universe_end );
    $complement->remove( $self->output );

    return $complement->output;
}

=back

=head1 SEE ALSO

=over 4

=item Monitor the integers covered by at least one range

Although there is some functional overlap between this module,
L<Number::Range|Number::Range>, and
L<Range::Object::Serial|Range::Object::Serial>, Number::RangeTracker
is significantly faster.

It takes less than one second for Number::RangeTracker to add 100,000
overlapping ranges. Over this same period of time, Number::Range and
Range::Serial::Object are only able to add 1,000 and 300 ranges,
respectively.

Some tasks require even higher throughput. When adding 1 million
overlapping ranges, Number::Range took >250 times as long as
Number::RangeTracker (35 min 31 sec vs. 8 sec). Range::Object::Serial
slows exponentially as ranges are added and, therefore, it was not
feasible to test this many ranges.

=begin HTML

<p><img src="https://raw.githubusercontent.com/mfcovington/Number-RangeTracker/master/compare-modules/speed-comparison.png"
width="675" alt="Speed comparison of range modules" /></p>

=end HTML

=begin text

        A figure comparing the speed of the three modules is available at:
        https://raw.githubusercontent.com/mfcovington/Number-RangeTracker/master/compare-modules/speed-comparison.png


=end text

=back

=begin markdown

    ![See https://raw.githubusercontent.com/mfcovington/Number-RangeTracker/master/compare-modules/speed-comparison.png for a speed comparison of range modules](https://raw.githubusercontent.com/mfcovington/Number-RangeTracker/master/compare-modules/speed-comparison.png "Speed comparison of range modules")

=end markdown

=over 4

=item Ranges with strandedness (like double-stranded DNA or mile posts
on a two-way road)

L<Bio::Range|Bio::Range>

=item Compare numbers in an imprecision-tolerant manner

L<Number::Tolerant|Number::Tolerant>

=item Named ranges

L<Tie::RangeHash|Tie::RangeHash>,
L<Array::IntSpan|Array::IntSpan>

=back

=head1 SOURCE AVAILABILITY

The source code is on Github:
L<https://github.com/mfcovington/Number-RangeTracker>

=head1 AUTHOR

Michael F. Covington, <mfcovington@gmail.com>

=head1 BUGS

Please report any bugs or feature requests at
L<https://github.com/mfcovington/Number-RangeTracker/issues>.

=head1 INSTALLATION

To install this module from GitHub using cpanm:

    cpanm git@github.com:mfcovington/Number-RangeTracker.git

Alternatively, download and run the following commands:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Number::RangeTracker

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael F. Covington.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

__PACKAGE__->meta->make_immutable();
