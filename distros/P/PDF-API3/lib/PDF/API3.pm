# ------------------------------------------------------------------------------
package PDF::API3;

use strict;
use warnings;

our $VERSION = '3.001';
$VERSION = eval $VERSION;
our $AUTHORITY = 'cpan:OTTO';

1;

__END__
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

=pod

=head1 NAME

PDF::API3 - Next version after PDF::API2

=head1 SYNOPSIS

=head1 DESCRIPTION

C<PDF::API3> is the beginning of a rewrite of C<PDF::API2>.

The purpose of this slightly modified version is to announce intensions
for a rewrite, hopefully spawn participation, and to utilize cpan-RT
for tracking bugs/fixes and wishlists/implementations.

After much time, effort, and with well received results,
Alfred Reibenschuh is abandoning C<PDF::API2>.
see L<http://tech.groups.yahoo.com/group/perl-text-pdf-modules/message/3615>.

However we have seen great progress in moving towards paperless methods.

Furthermore the PDF specification is now an ISO standard.

Now is the time to really push forward with the development of an even
better perl pdf solution.

This is a beginning toward that goal.

This version starts with C<PDF::API2> 0.73,
creating a new interfaced named C<PDF::API3> with a new version numbering
starting at 3.001.

There are a growing number of PDF "quick solutions". It is hoped that
C<PDF::API3> can coalesce many under one library. There is commonality
that all "quick solutions" will need: find, open, read, write, parse files.

The intent is to provide a universal library for which other "solutions"
may utilize for lower level functionality. As such, all PDF::API2 modules
have been re-named as C<PDF::API3::Compat::API2>.

The intent is that the interface at the C<API2> level will stay the same.

As the library is refactored, a new C<API3> interface will be formulated.
Low level functionality will be factored into C<PDF::API3::Lib>. The
typical programmer interface will be factored under C<PDF::API3>. The
typical programmer interface would utilized the lower level routines
of C<PDF::API3::Lib>.

Other PDF libraries may be incorporated as C<PDF::API3::Compat::distA>,
C<PDF::API3::Compat::distB>, C<PDF::API3::Compat::distC>, etc. As these are
refactored to utilize or generalize C<PDF::API3::Lib>, their typical
programmer interface will move under C<PDF::API3> if general, or may be
spun off as C<PDF::API3x> extensions

The intent is to use git and encourage distributed development.
A git and wiki will be put up soon.

Development philosophy includes development of lots of tests,
tidy'ing and critic utilities, and utlization of Moose and other
libraries that will speed development and provide a clean, solid,
easily maintained, production ready system. And to develop appropriate
programmer and maintenance documentation. Yes - maintenance of how it
works and why choices were made so as to ease maintenance of it by others.

The intent of putting this release out is to inform the community of
the effort, encourage others to participate, and to utilize the bug
tracking system of CPAN for tracking bugs and new development.

Consider this pre-alpha software.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please enter into cpan-RT.

=head1 FEATURE REQUESTS

Please enter into cpan-RT.

=head1 AUTHOR

Otto Hirr

Hopefully many others will contribute.

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Otto Hirr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

=over 4

=item Alfred Reibenschuh for developing PDF::API2

=item Martin Hosken for developing Text::PDF and Font::TTF used in PDF::API2

=back

=cut

# ------------------------------------------------------------------------------
# End of file
# ------------------------------------------------------------------------------
