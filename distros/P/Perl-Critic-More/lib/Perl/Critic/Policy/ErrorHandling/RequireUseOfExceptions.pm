##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-More/lib/Perl/Critic/Policy/ErrorHandling/RequireUseOfExceptions.pm $
#     $Date: 2013-10-29 09:39:11 -0700 (Tue, 29 Oct 2013) $
#   $Author: thaljef $
# $Revision: 4222 $
##############################################################################

package Perl::Critic::Policy::ErrorHandling::RequireUseOfExceptions;

use 5.006001;

use strict;
use warnings;

use Readonly;

use Perl::Critic::Utils qw{ :severities :classification :data_conversion };
use base 'Perl::Critic::Policy';

our $VERSION = '1.003';

#-----------------------------------------------------------------------------

sub default_severity     { return $SEVERITY_HIGH }
sub default_themes       { return qw< more maintenance > }
sub applies_to           { return 'PPI::Token::Word' }
sub supported_parameters { return () }

#-----------------------------------------------------------------------------

Readonly::Hash my %FATAL_FUNCTIONS => hashify(qw< die croak confess >);

sub violates {
    my ( $self, $elem, undef ) = @_;

    return if not exists $FATAL_FUNCTIONS{$elem};

    return if not is_function_call($elem);

    return $self->violation(
        "Found use of $elem. Use an exception instead.",
        'Exception objects should be used instead of the standard Perl error mechanism.',
        $elem,
    );
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::ErrorHandling::RequireUseOfExceptions - Use exceptions instead of C<die>, C<croak>, or C<confess>.

=head1 AFFILIATION

This policy is part of L<Perl::Critic::More|Perl::Critic::More>, a bleeding
edge supplement to L<Perl::Critic|Perl::Critic>.

=head1 DESCRIPTION

If the decision is made that a system should use exceptions, then there should
be no use of C<die>, C<croak>, or C<confess>.

=head1 AUTHOR

Elliot Shank C<< <perl@galumph.org> >>

=head1 COPYRIGHT

Copyright (c) 2007-2008 Elliot Shank.  All rights reserved.

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
