package PITA::Test::Image::Qemu;

=pod

=head1 NAME

PITA::Test::Image::Qemu - A tiny Qemu test image that only boots and pings

=head1 DESCRIPTION

This distribution contains a small Qemu image intended for snapshot-mode
testing of the L<PITA::Guest::Driver::Qemu> module.

Primarily, it is intended for testing the launch-shutdown cycle, and not
for testing discovery or package testing.

It verifies that the driver is using the F<qemu> binary properly.

=head1 METHODS

=cut

use 5.006;
use strict;
use File::ShareDir ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.41';
}

1;

=pod

=head2 filename

The static C<filename> method returns the location of the expanded testing
image, verified to exist. The file will be available only with read
permissions, and without the ability to write.

=cut

sub filename {
	File::ShareDir::dist_file('PITA-Test-Image-Qemu', 'qemu.img');
}

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PITA-Test-Image-Qemu>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

The Practical Image Testing Architecture (L<http://ali.as/pita/>)

L<PITA>, L<PITA::Guest::Driver::Qemu>

=head1 COPYRIGHT

Copyright 2006 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
