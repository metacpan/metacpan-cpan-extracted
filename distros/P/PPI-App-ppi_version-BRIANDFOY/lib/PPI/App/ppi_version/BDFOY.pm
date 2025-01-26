package PPI::App::ppi_version::BDFOY;
use parent qw(PPI::App::ppi_version::BRIANDFOY);

our $VERSION = '1.006';

1;

=encoding utf8

=head1 NAME

PPI::App::ppi_version::BDFOY - brian d foy's rip off of Adam's ppi_version

=head1 SYNOPSIS

Install the new version:

	% cpan PPI::App::ppi_version::BRIANDFOY

Then use it as before:

	# call it like PPI::App::ppi_version
	% ppi_version show

	% ppi_version change 1.23 1.24

	# call it with less typing. With no arguments, it assumes 'show'.
	% ppi_version

	# with arguments that are not 'show' or 'change', assume 'change'
	% ppi_version 1.23 1.24

=head1 DESCRIPTION

This module used to be called L<PPI::App::ppi_version::BDFOY>, but then
I changed my PAUSE ID to BRIANDFOY. Along with that, I updated this
package name. This particular file is here just for legacy. You
should update to use PPI::App::ppi_version::BRIANDFOY

=head1 SOURCE AVAILABILITY

This source is part of a Github project:

	https://github.com/briandfoy/ppi-app-ppi_version-briandfoy

=head1 AUTHOR

Adam Kennedy wrote the original, and I stole some of the code. I even
inherit from the original.

brian d foy, C<< <briandfoy@pobox.com> >>

=head1 COPYRIGHT

Copyright © 2008-2025, brian d foy C<briandfoy@pobox.com>. All rights reserved.

You may redistribute this under the same terms as the Artistic License 2.0.

=cut
