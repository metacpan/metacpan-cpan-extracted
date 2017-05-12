#######################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-More/lib/Perl/Critic/Policy/ValuesAndExpressions/RestrictLongStrings.pm $
#     $Date: 2013-10-29 09:39:11 -0700 (Tue, 29 Oct 2013) $
#   $Author: thaljef $
# $Revision: 4222 $
########################################################################

package Perl::Critic::Policy::ValuesAndExpressions::RestrictLongStrings;

use 5.006001;

use strict;
use warnings;

use Carp;
use Readonly;

use Perl::Critic::Utils qw{ :severities };
use base 'Perl::Critic::Policy';

our $VERSION = '1.003';

#---------------------------------------------------------------------------

Readonly::Scalar my $DESC => 'Long string mixed with code';
Readonly::Scalar my $EXPL =>
    'Put long strings in their own subroutine or split them';

#---------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw< more readability > }
sub applies_to       { return 'PPI::Token::Quote' }

sub supported_parameters {
    return (
        {   name            => 'max_length',
            description     => 'The maximum line length to allow.',
            default_string  => '78',
            behavior        => 'integer',
            integer_minimum => 1,
        },
    );
}

#---------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    my $length = length $elem->string;
    return if $length <= $self->{_max_length};

    # Allow long strings in the last statment of a subroutine
    my $stmt = $elem->statement;
    if ( !$stmt->snext_sibling ) {
        my $stmt_parent = $stmt->parent;
        if ( $stmt_parent->isa('PPI::Structure::Block') ) {

            # Named subroutine
            return if $stmt_parent->parent->isa('PPI::Statement::Sub');

            # Anonymous subroutine
            my $sib = $stmt_parent->sprevious_sibling;
            return if $sib && $sib->isa('PPI::Token::Word') && 'sub' eq $sib;
        }
    }

    return $self->violation( $DESC, $EXPL, $elem );
}

1;

__END__

#---------------------------------------------------------------------------

=pod

=for stopwords

=head1 NAME

Perl::Critic::Policy::ValuesAndExpressions::RestrictLongStrings - Stop mixing long strings with code.


=head1 AFFILIATION

This policy is part of L<Perl::Critic::More|Perl::Critic::More>, a bleeding
edge supplement to L<Perl::Critic|Perl::Critic>.


=head1 DESCRIPTION

Long text strings in the middle of code is very distracting and wreaks havoc
on code formatting.  Consider putting long strings in external data files,
C<__DATA__> sections, or in their own subroutines.

This policy complains if a long string is not the last line of a subroutine.
"Long" is defined as 78 characters by default.  This value can be altered in
your Perl::Critic configuration via the C<max_length> property.  For example,
you may add the following to your F<.perlcriticrc> file:

  [ValuesAndExpressions::RestrictLongStrings]
  max_length = 50


=head1 TODO

Add option to allow long strings that don't include newlines.


=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>


=head1 COPYRIGHT

Copyright (c) 2006-2008 Chris Dolan

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
