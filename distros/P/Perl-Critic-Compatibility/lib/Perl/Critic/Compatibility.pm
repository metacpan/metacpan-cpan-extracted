#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/Perl-Critic-Compatibility/lib/Perl/Critic/Compatibility.pm $
#     $Date: 2008-06-07 22:26:28 -0500 (Sat, 07 Jun 2008) $
#   $Author: clonezone $
# $Revision: 2425 $

package Perl::Critic::Compatibility;

use 5.006;

use strict;
use warnings;

our $VERSION = '1.001';

1; # Magic true value required at end of module

__END__

=for stopwords

=head1 NAME

Perl::Critic::Compatibility - Policies for Perl::Critic concerned with compatibility with various versions of Perl.

=head1 AFFILIATION

This module has no functionality, but instead contains documentation
for this distribution and acts as a means of pulling other modules
into a bundle.  All of the Policy modules contained herein will have
an "AFFILIATION" section announcing their participation in this
grouping.


=head1 VERSION

This document describes Perl::Critic::Compatibility version 1.001.


=head1 SYNOPSIS

Some L<Perl::Critic> policies that will help you keep your code
compatible with other versions of Perl, regardless of the version that
you're developing with.  This includes both backward and forward
compatibility.


=head1 DESCRIPTION

The included policies are:

=over

=item L<Perl::Critic::Policy::Compatibility::ProhibitColonsInBarewordHashKeys>

Perls after 5.8 don't support having colons in unquoted hash keys.
[Severity: 5]


=item L<Perl::Critic::Policy::Compatibility::ProhibitThreeArgumentOpen>

Perls prior to 5.6 didn't support three argument open.  [Severity: 5]


=back


=head1 INTERFACE

None.  This is nothing but documentation.


=head1 DIAGNOSTICS

None.  This is nothing but documentation.


=head1 CONFIGURATION AND ENVIRONMENT

All policies included are in the "compatibility" theme.  See the
L<Perl::Critic> documentation for how to make use of this.


=head1 DEPENDENCIES

L<Perl::Critic>


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-critic-compatibility@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.


=head1 ACKNOWLEDGMENTS

Adam Kennedy for inspiring this.  Nay, demanding it.


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 LICENSE AND COPYRIGHT

Copyright (c)2008, Elliot Shank C<< <perl@galumph.com> >>. All rights
reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.


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

# setup vim: set filetype=perl tabstop=4 softtabstop=4 expandtab :
# setup vim: set shiftwidth=4 shiftround textwidth=78 nowrap autoindent :
# setup vim: set foldmethod=indent foldlevel=0 :
