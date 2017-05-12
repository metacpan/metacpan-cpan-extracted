##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/tags/Perl-Critic-Dynamic-0.05/lib/Perl/Critic/Dynamic.pm $
#     $Date: 2009-04-25 13:24:01 -0700 (Sat, 25 Apr 2009) $
#   $Author: shawnmoore $
# $Revision: 3293 $
##############################################################################

package Perl::Critic::Dynamic;

use strict;
use warnings;

#-----------------------------------------------------------------------------

our $VERSION = 0.05;

#-----------------------------------------------------------------------------

1;

__END__

#-----------------------------------------------------------------------------

=pod

=for stopwords Mathworks

=head1 NAME

Perl::Critic::Dynamic - Non-static policies for Perl::Critic

=head1 AFFILIATION

This module has no functionality, but instead contains documentation
for this distribution and acts as a means of pulling other modules
into a bundle.  All of the Policy modules contained herein will have
an "AFFILIATION" section announcing their participation in this
grouping.

=head1 DESCRIPTION

L<Perl::Critic> is primarily used as a static source code analyzer,
which means that it never compiles or executes any of the code that it
examines.  But since Perl is a dynamic language, there are certain
types of problems that cannot be discovered until the code is actually
compiled.

This distribution includes L<Perl::Critic::DynamicPolicy>, which can
be used as a base class for Policies that wish to compile the code
they analyze.  The distribution also contains
L<Perl::Critic::Policy::Dynamic::ValidateAgainstSymbolTable> which
demonstrates the use of L<Perl::Critic::DynamicPolicy>.

=head1 ACKNOWLEDGMENTS

Development of the C<Perl-Critic-Dynamic> distribution was financed by
a grant from The Mathworks (L<http://mathworks.com>).  The
Perl::Critic team sincerely thanks The Mathworks for their generous
support of the Perl community and open-source software.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2007 Jeffrey Ryan Thalhammer.  All rights reserved.

=cut
