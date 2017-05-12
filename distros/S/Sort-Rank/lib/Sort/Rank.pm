package Sort::Rank;

use warnings;
use strict;
use Carp;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(rank_sort rank_group);

use version; our $VERSION = qv( '0.0.2' );

sub rank_group {
    my $array   = shift;
    my $extract = shift;

    if ( ref( $array ) eq 'HASH' ) {

        # Turn a hash into an array
        my @a = map { [ $_, $array->{$_} ] } keys %$array;
        $array = \@a;
    }

    croak "rank_sort needs an array reference"
      unless ref $array eq 'ARRAY';

    # Default score extraction sub
    $extract ||= sub {
        my $item = shift;
        croak "Array item must be a hash with a key called 'score'."
          unless ref( $item ) eq 'HASH' && exists $item->{score};
        return $item->{score};
    };

    croak "Key extractor must be a code ref"
      unless ref( $extract ) eq 'CODE';

    my $pos = 1;
    my @ar  = sort {

        # Sort on score then original position
        $b->[0] <=> $a->[0]
          || $a->[1] <=> $b->[1]
      }
      map {

        # Build array of score, original position, value
        [ $extract->( $_ ), $pos++, $_ ]
      } @$array;

    my @out = ();
    for my $i ( 0 .. $#ar ) {

        # Need to start a new chunk?
        if ( $i == 0 || $ar[$i]->[0] != $ar[ $i - 1 ]->[0] ) {
            push @out, [ $i + 1 ];
        }

        # Add item to current chunk
        push @{ $out[-1] }, $ar[$i]->[2];
    }

    return wantarray ? @out : \@out;
}

sub rank_sort {
    my @grp = rank_group( @_ );
    my @out = ();

    # Unwrap groups
    for my $g ( @grp ) {
        my $rank = shift @$g;
        my $many = ( @$g > 1 ) ? '=' : '';
        for my $i ( @$g ) {
            push @out, [ $rank, $many, $i ];
        }
    }

    return wantarray ? @out : \@out;
}

1;
__END__

=head1 NAME

Sort::Rank - Sort arrays by some score and organise into ranks.

=head1 VERSION

This document describes Sort::Rank version 0.0.2

=head1 SYNOPSIS

    use Sort::Rank qw(rank_sort rank_group);

    my @scores = (
        {   score   => 80,  name    => 'Andy'       },
        {   score   => 70,  name    => 'Chrissie'   },
        {   score   => 90,  name    => 'Alex'       },
        {   score   => 90,  name    => 'Rosie'      },
        {   score   => 80,  name    => 'Therese'    },
        {   score   => 10,  name    => 'Mac'        },
        {   score   => 10,  name    => 'Horton'     },
    );

    my @sorted = rank_sort(\@scores);

    # Result:
    # @sorted = (
    #     [   1, '=', { 'name' => 'Alex',     'score' => 90   } ],
    #     [   1, '=', { 'name' => 'Rosie',    'score' => 90   } ],
    #     [   3, '=', { 'name' => 'Andy',     'score' => 80   } ],
    #     [   3, '=', { 'name' => 'Therese',  'score' => 80   } ],
    #     [   5, '',  { 'name' => 'Chrissie', 'score' => 70   } ],
    #     [   6, '=', { 'name' => 'Mac',      'score' => 10   } ],
    #     [   6, '=', { 'name' => 'Horton',   'score' => 10   } ]
    # );

=head1 DESCRIPTION

Typically when presenting positions in some league or popularity chart
or formatting a table of examination results entries with the same
score are grouped together by rank like this:

    ========================
    Pos     Score   Name
    ========================
    1       90      Alex
    2 =     80      Therese
    2 =     80      Chrissie
    4       70      Andy
    ========================

This module takes care of the (slightly) tricky business of organising
an array of items each of which has a numeric element representing a
score into rank order in this way.

Two exportable functions are provided C<rank_sort> and C<rank_group>.
They both take the same parameters and differ only in the format of the
results they return. C<rank_group> returns a hierarchical array of
arrays that groups together elements from the original array that have
the same score.

C<rank_sort> returns a flattened version of the same information. Each
element is annotated with its rank and a flag to indicate whether it
shares that rank with any other elements.

=head1 INTERFACE

Both of the functions this module can export (C<rank_sort> and
C<rank_group>) take the same parameters: an array reference and
optionally a reference to a subroutine that can extract the score
value from each item in the array. If each element of the array to
be sorted is a hash with a key called 'score' no score extraction
subroutine need be provided. If you are building the data array
specifically to pass to C<rank_sort> or C<rank_group> this is
the easiest option.

    my $scores = [
        { name => 'Bill', score => 89 },
        { name => 'Ted', score => 80 },
        { name => 'Aristotle', score => 80 }
    ]

    my @sorted = rank_sort($scores);

If the array contains objects of some other type (i.e. anything other
than hashes with a key called 'score') you must provide a subroutine to
extract the score from each element.

    my $scores = [
        [ 100, 'Smartass' ],
        [   3, 'Dunce' ],
        [  75, 'Andy' ]
    ];

    my @sorted = rank_sort($scores, sub {
        # Extract score from an element
        my $item = shift;
        return $item->[0];
    });

The extraction subroutine is passed a reference to an element of the
array and must return a numeric score - either by retrieving it from the
array element or by calculating it.

=over

=item C<rank_sort()>

Given an array reference and optional score extraction subroutine return
an array containing the elements of the input array arranged in rank
order. Each element of the returned array is a reference to a three
element array containing the rank of this element, a flag that indicates
whether this rank is shared with other elements and the corresponding
value from the input array.

For example

    use Sort::Rank qw(rank_sort);

    my @scores = (
        {   score   => 80,  name    => 'Andy'       },
        {   score   => 70,  name    => 'Chrissie'   },
        {   score   => 90,  name    => 'Alex'       },
        {   score   => 90,  name    => 'Rosie'      },
        {   score   => 80,  name    => 'Therese'    },
        {   score   => 10,  name    => 'Mac'        },
        {   score   => 10,  name    => 'Horton'     },
    );

    my @sorted = rank_sort(\@scores);

    # Result:
    # @sorted = (
    #     [   1, '=', { 'name' => 'Alex',     'score' => 90   } ],
    #     [   1, '=', { 'name' => 'Rosie',    'score' => 90   } ],
    #     [   3, '=', { 'name' => 'Andy',     'score' => 80   } ],
    #     [   3, '=', { 'name' => 'Therese',  'score' => 80   } ],
    #     [   5, '',  { 'name' => 'Chrissie', 'score' => 70   } ],
    #     [   6, '=', { 'name' => 'Mac',      'score' => 10   } ],
    #     [   6, '=', { 'name' => 'Horton',   'score' => 10   } ]
    # );

In a scalar context returns an array reference instead of an array.

As explained above a reference to a subroutine that extracts the score
from each element of the input array may be passed as a second argument.
If no such subroutine is provided it is assumed that each element of the
input array is a reference to a hash that contains a key called 'score'.

=item C<rank_group()>

Called in the same way as C<rank_sort>. Returns an array that groups the
elements from the input array like this:

    use Sort::Rank qw(rank_group);

    my @scores = (
        {   score   => 80,  name    => 'Andy'       },
        {   score   => 70,  name    => 'Chrissie'   },
        {   score   => 90,  name    => 'Alex'       },
        {   score   => 90,  name    => 'Rosie'      },
        {   score   => 80,  name    => 'Therese'    },
        {   score   => 10,  name    => 'Mac'        },
        {   score   => 10,  name    => 'Horton'     },
    );

    my @sorted = rank_group(\@scores);

    # Result:
    # @sorted = (
    #     [
    #         1,  # Rank of this group
    #         { 'name' => 'Alex',         'score' => 90 },
    #         { 'name' => 'Rosie',        'score' => 90 }
    #     ],
    #     [
    #         3,
    #         { 'name' => 'Andy',         'score' => 80 },
    #         { 'name' => 'Therese',      'score' => 80 }
    #     ],
    #     [
    #         5,
    #         { 'name' => 'Chrissie',     'score' => 70 }
    #     ],
    #     [
    #         6,
    #         { 'name' => 'Mac',          'score' => 10 },
    #         { 'name' => 'Horton',       'score' => 10 }
    #     ]
    # );

=back

=head1 DIAGNOSTICS

=over

=item C<< rank_sort needs an array reference >>

The first argument to C<rank_sort> and C<rank_group> must be a reference
to the array to be sorted.

=item C<< Array item must be a hash with a key called 'score'. >>

If no score extraction subroutine is provided the elements of the
input array must be references to hashes each of which has a key
named 'score'.

=item C<< Key extractor must be a code ref >>

The optional second argument to both C<rank_group> and C<rank_sort> must
be a reference to a subroutine that will return the score that
corresponds to each element in the array.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Sort::Rank requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-sort-rank@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
