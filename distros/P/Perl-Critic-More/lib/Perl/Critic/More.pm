##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-More/lib/Perl/Critic/More.pm $
#     $Date: 2013-10-29 09:39:11 -0700 (Tue, 29 Oct 2013) $
#   $Author: thaljef $
# $Revision: 4222 $
##############################################################################
package Perl::Critic::More;

use 5.006001;

use warnings;
use strict;

our $VERSION = '1.003';

1;

__END__

=pod

=for stopwords metacode RJBS gauge

=head1 NAME

Perl::Critic::More - Supplemental policies for Perl::Critic

=head1 SYNOPSIS

  perl -MCPAN -e'install Perl::Critic::More'
  perlcritic -theme more lib/Foo.pm

=head1 AFFILIATION

This file has no functionality, but instead is a placeholder for a loose
collection of Perl::Critic policies.  All of those policies will have an
"Affiliation" section announcing their participation in this grouping.

=head1 DESCRIPTION

This is a collection of L<Perl::Critic|Perl::Critic> policies that are not
included in the Perl::Critic core for a variety of reasons:

=over

=item * Experimental

Some policies need some time to work out their kinks, test usability, or gauge
community interest.  A subset of these will end up in the core Perl::Critic
someday.

=item * Requires special dependencies

For example, some policies require development versions of PPI (or some other
CPAN module).  These will likely end up in the Perl::Critic core when their
dependencies are fulfilled.

=item * Peripheral to Perl

For example, the C<Editor::RequireEmacsFileVariables> policy is metacode.
Also, the C<Miscellanea::RequireRcsKeywords> policy pertains to the
development process, not the code itself. These are not part of Perl::Critic's
mission.

=item * Special purpose

For example, policies like C<CodeLayout::RequireASCII> designed to scratch
itches not felt by most of the community.  These will always remain in a
Perl::Critic supplement instead of in the core.

=back

All of these policies have the theme C<more> so they can be turned off as a
group via F<.perlcriticrc> by adding this line:

  theme = not more

The special purpose ones may be part of the C<notrecommended> theme.  Avoid
these via:

  theme = not notrecommended

Sorry about the double-negative...  See L<Perl::Critic/"CONFIGURATION"> for
details on how to interact with themes.

=head1 SEE ALSO

L<Perl::Critic|Perl::Critic>

L<Perl::Critic::Bangs|Perl::Critic::Bangs> - Andy Lester's fantastic list of code pet peeves

L<Perl::Critic::Lax|Perl::Critic::Lax> - RJBS' more-lenient versions of some core Perl::Critic policies

L<parrot|parrot> - the parrot team has developed a few specialized Perl::Critic
policies of their own

=head1 AUTHOR

Chris Dolan <cdolan@cpan.org>

The included policies may have other authors -- please see them individually.

This distribution is controlled by the Perl::Critic team.  If you want to add
a policy to this collection, check out our Subversion repository and mailing lists at
L<http://perlcritic.tigris.org>.

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
