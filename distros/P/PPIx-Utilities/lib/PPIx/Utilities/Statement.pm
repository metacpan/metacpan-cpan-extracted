##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/PPIx-Utilities/lib/PPIx/Utilities/Statement.pm $
#     $Date: 2010-11-13 14:25:12 -0600 (Sat, 13 Nov 2010) $
#   $Author: clonezone $
# $Revision: 3990 $
##############################################################################

package PPIx::Utilities::Statement;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.001000';

use Readonly;


use PPI 1.208 qw< >; # Just for the version check.

use base 'Exporter';

our @EXPORT_OK = qw(
    get_constant_name_elements_from_declaring_statement
);


Readonly::Hash my %IS_COMMA => ( q[,] => 1, q[=>] => 1 );


sub get_constant_name_elements_from_declaring_statement {
    my ($element) = @_;

    return if not $element;
    return if not $element->isa('PPI::Statement');

    if ( $element->isa('PPI::Statement::Include') ) {
        my $pragma;
        if ( $pragma = $element->pragma() and $pragma eq 'constant' ) {
            return _get_constant_names_from_constant_pragma($element);
        } # end if
    } elsif ( not $element->specialized() and $element->schildren() > 2 ) {
        my $supposed_constant_function = $element->schild(0)->content();
        my $declaring_scope = $element->schild(1)->content();

        if (
                (
                        $supposed_constant_function eq 'const'
                    or  $supposed_constant_function =~ m< \A Readonly \b >xms
                )
            and ($declaring_scope eq 'our' or $declaring_scope eq 'my')
        ) {
            return $element->schild(2);
        } # end if
    } # end if

    return;
} # end get_constant_name_elements_from_declaring_statement()


sub _get_constant_names_from_constant_pragma {
    my ($include) = @_;

    my @arguments = $include->arguments() or return;

    my $follower = $arguments[0];
    return if not defined $follower;

    # We test for a 'PPI::Structure::Block' in the following because some
    # versions of PPI parse the last element of 'use constant { ONE => 1, TWO
    # => 2 }' as a block rather than a constructor. As of PPI 1.206, PPI
    # handles the above correctly, but still blows it on 'use constant 1.16 {
    # ONE => 1, TWO => 2 }'.
    if (
            $follower->isa( 'PPI::Structure::Constructor' )
        or  $follower->isa( 'PPI::Structure::Block' )
    ) {
        my $statement = $follower->schild( 0 ) or return;
        $statement->isa( 'PPI::Statement' ) or return;

        my @elements;
        my $inx = 0;
        foreach my $child ( $statement->schildren() ) {
            if (not $inx % 2) {
                push @{ $elements[ $inx ] ||= [] }, $child;
            } # end if

            if ( $IS_COMMA{ $child->content() } ) {
                $inx++;
            } # end if
        } # end foreach

        return map
            {
                (
                        $_
                    and @{$_} == 2
                    and '=>' eq $_->[1]->content()
                    and $_->[0]->isa( 'PPI::Token::Word' )
                )
                    ? $_->[0]
                    : ()
            }
            @elements;
    } else {
        return $follower;
    } # end if

    return $follower;
} # end _get_constant_names_from_constant_pragma()


1;

__END__

=pod

=for stopwords

=head1 NAME

PPIx::Utilities::Statement - Extensions to L<PPI::Statement|PPI::Statement>.


=head1 VERSION

This document describes PPIx::Utilities::Statement version 1.1.0.


=head1 SYNOPSIS

    use PPI::Document qw< >;

    use PPIx::Utilities::Statement qw<
        get_constant_name_elements_from_declaring_statement
    >;

    my $document = PPI::Document->new(\'Readonly::Scalar my $THINGY => 47.2;');

    # Returns the PPI::Token::Symbol for "$THINGY".
    my ($constant) = get_constant_name_elements_from_declaring_statement(
        $document->schild(0)
    );


=head1 DESCRIPTION

This is a collection of functions for dealing with
L<PPI::Statement|PPI::Statement>s.


=head1 INTERFACE

Nothing is exported by default.


=head2 C<get_constant_name_elements_from_declaring_statement($statement)>

Given a L<PPI::Statement|PPI::Statement>, if the statement is a
L<Readonly|Readonly> or L<Const::Fast|Const::Fast> declaration statement or a
C<use constant>, returns the names of the things being defined.

Given

    use constant 1.16 FOO => 'bar';

this will return the L<PPI::Token::Word|PPI::Token::Word> containing C<'FOO'>.
Given

    use constant 1.16 { FOO => 'bar', 'BAZ' => 'burfle' };

this will return a list of the L<PPI::Token|PPI::Token>s containing C<'FOO'>
and C<'BAZ'>. Similarly, given

    Readonly::Hash my %FOO => ( bar => 'baz' );

or

    const my %FOO => ( bar => 'baz' );

this will return the L<PPI::Token::Symbol|PPI::Token::Symbol> containing
C<'%FOO'>.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-ppix-utilities@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Thomas R. Wyant, III C<< <wyant at cpan dot org> >>


=head1 COPYRIGHT

Copyright (c) 2009-2010 Thomas R. Wyant, III.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.


=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab shiftround :
