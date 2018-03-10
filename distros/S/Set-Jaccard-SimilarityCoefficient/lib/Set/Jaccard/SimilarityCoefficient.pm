# -*- mode: cperl; -*-
package Set::Jaccard::SimilarityCoefficient;
use warnings;
use strict;
use utf8;
use autodie;
use Exception::Class qw(
  BadArgumentException
  DivideByZeroException
);
use ReadonlyX;
use Set::Scalar;

our $VERSION = '1.6.1';

## no critic( Subroutines::ProhibitCallsToUnexportedSubs )
# ------ Error messages
Readonly::Scalar my $BAD_SET_A =>
  'must have either ArrayRef or Set::Scalar value for set A';
Readonly::Scalar my $BAD_SET_B =>
  'must have either ArrayRef or Set::Scalar value for set B';
Readonly::Scalar my $DIVIDE_BY_ZERO =>
  'Cannot calculate when size(Union(A B)) == 0';
## use critic

=function

Calculate the Jaccard Similarity Coefficient.

=cut

sub calc {
    my ( $set_a_arg, $set_b_arg ) = @_;
    my $set_a;
    my $set_b;

## no critic( Modules::RequireExplicitInclusion )
    if ( !defined $set_a_arg
        || ( ref $set_a_arg ne 'ARRAY' && ref $set_a_arg ne 'Set::Scalar' ) )
    {
        BadArgumentException->throw($BAD_SET_A);
    }

    if ( !defined $set_b_arg
        || ( ref $set_b_arg ne 'ARRAY' && ref $set_b_arg ne 'Set::Scalar' ) )
    {
        BadArgumentException->throw($BAD_SET_B);
    }

    if ( ref $set_a_arg eq 'Set::Scalar' ) {
        $set_a = $set_a_arg->clone();
    }
    else {
        $set_a = Set::Scalar->new( @{$set_a_arg} );
    }

    if ( ref $set_b_arg eq 'Set::Scalar' ) {
        $set_b = $set_b_arg->clone();
    }
    else {
        $set_b = Set::Scalar->new( @{$set_b_arg} );
    }

    my $intersection = $set_a->intersection($set_b);
    my $union        = $set_a->union($set_b);

    if ( $union->size <= 0 ) {
        DivideByZeroException->throw($DIVIDE_BY_ZERO);
    }
## use critic

    return $intersection->size / $union->size;
}

#
# This file is part of Set-Jaccard-SimilarityCoefficient
#
# This software is copyright (c) 2018 by Mark Leighton Fisher.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

1;

=encoding utf8

=head1 NAME

Set::Jaccard::SimilarityCoefficient - Calculate the Jaccard Similarity Coefficient of 2 sets

=head1 VERSION

# VERSION

=head1 SYNOPSIS

$res = Set::Jaccard::SimilarityCoefficient::calc(\@set_a, \@set_b);

OR

my $a = Set::Scalar->new(@set_a);
my $b = Set::Scalar->new(@set_b);
$res = Set::Jaccard::SimilarityCoefficient::calc($a, $b);

=head1 DESCRIPTION

Set::Jaccard::SimilarityCoefficient lets you calculate the Jaccard Similarity
Coefficient for either arrayrefs or Set::Scalar objects.

Briefly, the Jaccard Similarity Coefficient is a simple measure of how similar
2 sets are. The calculation is (in pseudo-code):

=over 4

    count(difference(SET-A, SET-B)) / count(union(SET-A, SET-B))

=back

There is a Jaccard Similarity Coefficient routine already in CPAN, but it is
specialized for use by Text::NSP. I wanted a generic routine that could be
used by anyone so Set::Jaccard::SimilarityCoefficient was born.

=head1 SUBROUTINES/METHODS

calc(A, B) calculates the Jaccard Similarity Coefficient for the arguments
A and B. A and B can be either array references or Set::Scalar objects.

=head1 DIAGNOSTICS

new() will complain if A or B is empty, not either a reference to an array,
or not a Set::Scalar object.

calc() could theoretically throw DivideByZeroException when the union
of the two sets has 0 members. However, that would require set A or
set B to have 0 members, which was previously prohibited by the
prohibition on empty sets.

=head1 CONFIGURATION AND ENVIRONMENT

This module should work wherever Perl works.

=head1 DEPENDENCIES

Set::Scalar

=head1 INCOMPATIBILITIES

None that I know of.

=head1 BUGS AND LIMITATIONS

There are no bugs that I know of. Given that this is non-trivial code,
there will be bugs.

The types of arguments are limited to either array references or
Set::Scalar objects.

=head1 AUTHOR

Mark Leighton Fisher, <markleightonfisher@gmail.com>

=head1 LICENSE AND COPYRIGHT

Set::JaccardSimilarityCoefficient is licensed under the same terms
as Perl itself.

=cut
