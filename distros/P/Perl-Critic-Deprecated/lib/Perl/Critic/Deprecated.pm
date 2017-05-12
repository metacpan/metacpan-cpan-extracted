#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/Perl-Critic-Deprecated/lib/Perl/Critic/Deprecated.pm $
#     $Date: 2013-10-29 09:19:05 -0700 (Tue, 29 Oct 2013) $
#   $Author: thaljef $
# $Revision: 4216 $

package Perl::Critic::Deprecated;

use 5.006001;

use strict;
use warnings;

our $VERSION = '1.119';

1; # Magic true value required at end of module

__END__

=for stopwords perlartistic merchantability

=head1 NAME

Perl::Critic::Deprecated - Policies and modules that were formerly included with Perl::Critic itself, but which have been superseded by others.

=head1 AFFILIATION

This module has no functionality, but instead contains documentation for this
distribution and acts as a means of pulling other modules into a bundle.  All
of the Policy modules contained herein will have an "AFFILIATION" section
announcing their participation in this grouping.


=head1 VERSION

This document describes Perl::Critic::Deprecated version 1.119.


=head1 SYNOPSIS

Some L<Perl::Critic|Perl::Critic> policies and modules have had their
functionality superseded by others and thus merely slow things down when
analyzing code. They are put here in case anyone still wants/needs to use
them.


=head1 DESCRIPTION

The included policies are:

=over

=item L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs|Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseSubs>

Write C<$my_variable = 42> instead of C<$MyVariable = 42>.  [Default severity 1]


=item L<Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars|Perl::Critic::Policy::NamingConventions::ProhibitMixedCaseVars>

Write C<sub my_function{}> instead of C<sub MyFunction{}>.  [Default severity 1]


=item L<Perl::Critic::Policy::Miscellanea::RequireRcsKeywords|Perl::Critic::Policy::Miscellanea::RequireRcsKeywords>

Put source-control keywords in every file.  [Default severity 2]

=back


=head1 INTERFACE

None.  This is nothing but documentation.


=head1 DIAGNOSTICS

None.  This is nothing but documentation.


=head1 CONFIGURATION AND ENVIRONMENT

All policies included are in the "deprecated" theme.  See the
L<Perl::Critic|Perl::Critic> documentation for how to make use of this.


=head1 DEPENDENCIES

L<Perl::Critic|Perl::Critic>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-critic-deprecated@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 COPYRIGHT

Copyright (c) 2008-2013, Elliot Shank C<< <perl@galumph.com> >>. Some
rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic|perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.


=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
