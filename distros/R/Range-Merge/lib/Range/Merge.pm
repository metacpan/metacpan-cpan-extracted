#!/usr/bin/perl

#
# Copyright (C) 2016-2019 Joelle Maslak
# All Rights Reserved - See License
#

package Range::Merge;
$Range::Merge::VERSION = '2.191190';
use strict;
use warnings;

use Range::Merge::Boilerplate 'script';

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(merge merge_discrete merge_ipv4);

use List::Util qw(max);
use Net::CIDR;
use Socket;

# ABSTRACT: Merges ranges of data including subset/superset ranges



sub merge($ranges) {
    my $sorted = _sort($ranges);
    my $split  = [];
    _split( $sorted, $split );
    return _combine($split);
}


sub merge_discrete($values) {
    my $ranges = [];

    my $run;

    for my $num ( sort { $a <=> $b } @$values ) {
        if ( !defined $run ) {
            $run = [ $num, $num ];
            push @$ranges, $run;
        } else {
            if ( $run->[1] == $num ) {
                # Do nothing
            } elsif ( $run->[1] == $num - 1 ) {
                $run->[1] = $num;
            } else {
                $run = [ $num, $num ];
                push @$ranges, $run;
            }
        }
    }

    return $ranges;
}


sub merge_ipv4($cidr) {
    my $ranges = [];
    @$ranges = map { _cidr2range($_) } @$cidr;
    my $combined = merge($ranges);
    return _range2cidr($combined);
}

sub _cidr2range($cidr) {
    my ( $ip, @a ) = @$cidr;
    my ($range) = Net::CIDR::cidr2range($ip);
    my (@parts) = map { unpack( 'N', inet_aton($_) ) } split( /-/, $range );

    return [ @parts, @a ];
}

sub _range2cidr($ranges) {
    my @output;
    foreach my $range (@$ranges) {
        my ( $start, $end, @other ) = @$range;
        $start = inet_ntoa( pack( 'N', $start ) );
        $end   = inet_ntoa( pack( 'N', $end ) );
        foreach my $cidr ( Net::CIDR::range2cidr("$start-$end") ) {
            push @output, [ $cidr, @other ];
        }
    }
    return \@output;
}

# Sorts by starting address and then by reverse (less specific to more
# specific)
sub _sort($ranges) {
    my (@output) = sort { ( $a->[0] <=> $b->[0] ) || ( $b->[1] <=> $a->[0] ) } @$ranges;
    return \@output;
}

sub _merge($ranges) {
    my $split = [];
    _split( $ranges, $split );
    return _combine($split);
}

sub _combine($ranges) {
    my @output;

    my $last;
    foreach my $range (@$ranges) {
        if ( !defined($last) ) {
            $last = [@$range];
            next;
        }
        if ( ( $last->[1] == $range->[0] - 1 ) && ( scalar(@$last) == scalar(@$range) ) ) {
            my $nomatch;
            for ( my $i = 2; $i < scalar(@$range); $i++ ) {
                if ( $last->[$i] ne $range->[$i] ) {
                    $nomatch = 1;
                    last;
                }
            }
            if ($nomatch) {
                push @output, $last;
                $last = [@$range];
            } else {
                $last->[1] = $range->[1];
            }
        } else {
            push @output, $last;
            $last = [@$range];
        }
    }
    if ( defined($last) ) { push @output, $last }

    return \@output;
}

sub _split ( $ranges, $output, $stack = [] ) {
    # Termination condition
    return if scalar( $ranges->@* ) == 0;

    # We just repeatedly call _add_to_stack
    foreach my $range ( $ranges->@* ) {
        _add_to_stack( $range, $stack, $output );
    }

    # Return stack
    if ( scalar( $stack->@* ) ) {
        push $output->@*, $stack->@*;
    }

    return;
}

sub _add_to_stack ( $range, $stack, $output ) {
    if ( !scalar( $stack->@* ) ) {
        # Empty stack
        push $stack->@*, $range;
        return;
    }

    # We know the following:
    #
    # 1. The stack is sorted
    # 2. There are no overlapping elements
    #    2a. Thus we only have to split 1 element max
    # 3. The stack has at least one element

    my (@lstack) = grep { $_->[1] < $range->[0] } @$stack;
    my (@rstack) = grep { $_->[0] > $range->[1] } @$stack;
    my (@mid)    = grep { ( $_->[0] <= $range->[1] ) && ( $_->[1] >= $range->[0] ) } @$stack;

    # Clear stack
    @$stack = ();

    # Output the stuff completely to the left of the new range
    push @$output, @lstack;

    # Option 1 -> No middle element, so just add the range (and the
    # right stack) to the stack
    if ( !scalar(@mid) ) {
        push @$stack, $range, @rstack;
        return;
    }

    # We start with the left and right parts of the element that might
    # need to be split.
    my (@left)  = $mid[0]->@*;
    my (@right) = $mid[0]->@*;

    # Does the ele needing split start before the range?  If so, add the piece
    # needed to the output
    if ( $left[0] < $range->[0] ) {
        @left[1] = $range->[0] - 1;
        if ( $left[0] <= $left[1] ) {
            push @$output, \@left;
        }
    }

    # We need to add the range to the stack
    push @$stack, $range;

    # Does the ele needing split end after the range?  If so, add the
    # piece to the stack
    if ( $right[1] > $range->[1] ) {
        @right[0] = $range->[1] + 1;
        if ( $right[0] <= $right[1] ) {
            push @$stack, \@right;
        }
    }

    push @$stack, @rstack;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Range::Merge - Merges ranges of data including subset/superset ranges

=head1 VERSION

version 2.191190

=head1 SYNOPSIS

  use Range::Merge qw(merge);
  my $output = merge($inrange);

=head1 DESCRIPTION

Many problems require merging of ranges.  For instance, one can parse
a BGP route table where there are a combinatrion of routes and produce
ranges that reduce the table size.  For instance, an ISP might announce
both 192.0.2.0/28 and 192.0.2.16/28 - these could be consolidated as
192.0.2.0/27 (assuming that other constraints, such as having identical
data, are met).

IP addresses are one example of this type of data - many variations
exist.  Because IP addresses can be represented as integers, it is possible
to write a generic range merging alogirthm that operates on integers.

=head1 FUNCTIONS

=head2 merge($ranges)

This is the soul of the C<Range::Merge> module - it merges an array
reference of ranges (passed in as the sole argument).  The output is
an array reference of the merged ranges.

=head2 merge_discrete($values)

This functionality is similar to the C<merge> function, except it simply
takes an array reference of individual, discrete, value.

The output is in standard range form.

=head2 merge_ipv4($cidr)

This is functionally similar to the C<merge> function, except for the
type of input it takes. The C<$cidr> parameter must consist of an
array reference of array references.  Each of the child array references
reference of ranges (passed in as the sole argument).  The output is
an array reference of the merged ranges.

The output is then turned back into CIDRs.

=head1 RANGE DATA DEFINITION

Range data is defined as two integers, a start and an end, along with
optional data elements.  This is represented as an array reference of
array references.  Note that the "most specific" elements are used for
the desired values for a piont on a range.  For instance, this is range
data:

  [ [0,12,'foo'], [4,8,'bar'] ]

In this case, the desired output of "merged" data would be:

  [ [0,3,'foo'], [4,8,'bar'], [9,12,'foo'] ]

This example is invalid range data:

  [ [0,12,'foo'], [8,14,'bar'] ]

The above data is invalid because of an ambiguity - Does C<12>
have the value of C<'foo'> or the value of C<'bar'>?  Thus, an exception
will be thrown.

Note that multiple data elements or no data elements can be present,
so long as the start and end integers exist for each range value.  Thus,
this is valid:

  [ [0,12], [4,8] ]

This, too is valid:

  [ [0,12,'foo','baz'], [4,8,'bar','baz'] ]

In this case, we would expect the merged output to look like:

  [ [0,3,'foo','baz'], [4,8,'bar','baz'], [9,12,'foo','baz'] ]

There is a specialized version which is simply a list of numbers, such as:

  [ 0, 1, 3, 5, 6 ]

This woud return the output:

  [ [0, 1], [3, 3], [5, 6] ]

Yet another form is used by the C<merge_discrete()> function.  There is also
a variation on this where, instead of a start and end integer, there is an IP
address (IPv4 only at this point).  For example:

  [ [ '0.0.0.0/4' ], [ '128.0.0.0/1' ] ]

This form is used by the C<merge_ipv4()> function.

=head1 AUTHOR

Joelle Maslak <jmaslak@antelope.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2019 by Joelle Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
