##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-Deprecated/lib/Perl/Critic/Policy/NamingConventions/ProhibitMixedCaseSubs.pm $
#     $Date: 2013-10-29 09:11:44 -0700 (Tue, 29 Oct 2013) $
#   $Author: thaljef $
# $Revision: 4214 $
##############################################################################

package Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs;

use 5.006001;
use strict;
use warnings;
use Readonly;

use Perl::Critic::Utils qw{ :severities };

use base 'Perl::Critic::Policy';

our $VERSION = '1.119';

#-----------------------------------------------------------------------------

Readonly::Scalar my $UPPER_LOWER    => qr/ [[:upper:]] [[:lower:]] /xms;
Readonly::Scalar my $LOWER_UPPER    => qr/ [[:lower:]] [[:upper:]] /xms;
Readonly::Scalar my $MIXED_RX       => qr{ $UPPER_LOWER | $LOWER_UPPER }xmso;
Readonly::Scalar my $DESC     => 'Mixed-case subroutine name';
Readonly::Scalar my $EXPL     => [ 45, 46 ];

#-----------------------------------------------------------------------------

sub supported_parameters { return ()                            }
sub default_severity     { return $SEVERITY_LOWEST              }
sub default_themes       { return qw( deprecated pbp cosmetic ) }
sub applies_to           { return 'PPI::Statement::Sub'         }

#-----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, undef ) = @_;
    (my $name = $elem->name() ) =~ s/\A.*:://xms;
    if ( $name =~ m/$MIXED_RX/xms ) {
        return $self->violation( $DESC, $EXPL, $elem );
    }
    return;    #ok!
}

1;

__END__

#-----------------------------------------------------------------------------

=pod

=head1 NAME

Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs - Write C<sub my_function{}> instead of C<sub MyFunction{}>.


=head1 AFFILIATION

This Policy is part of the
L<Perl::Critic::Deprecated|Perl::Critic::Deprecated> distribution.


=head1 DESCRIPTION

Conway's recommended naming convention is to use lower-case words
separated by underscores.  Well-recognized acronyms can be in ALL
CAPS, but must be separated by underscores from other parts of the
name.

    sub foo_bar{}   #ok
    sub foo_BAR{}   #ok
    sub FOO_bar{}   #ok
    sub FOO_BAR{}   #ok

    sub Some::Class::foo{}   #ok, grudgingly

    sub FooBar {}   #not ok
    sub FOObar {}   #not ok
    sub fooBAR {}   #not ok
    sub fooBar {}   #not ok


=head1 CONFIGURATION

This Policy is not configurable except for the standard options.


=head1 SEE ALSO

L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars|Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars>

This policy is deprecated.  Its functionality has been superseded by
L<Perl::Critic::Policy::NamingConventions::Capitalization|Perl::Critic::Policy::NamingConventions::Capitalization>.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2013 Jeffrey Ryan Thalhammer.  All rights reserved.

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
