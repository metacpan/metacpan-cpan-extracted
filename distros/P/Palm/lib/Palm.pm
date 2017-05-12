package Palm;
#
# ABSTRACT: Palm OS utility functions
#
#	Copyright (C) 1999, 2000, Andrew Arensburger.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.

use strict;
use warnings;
use vars qw( $VERSION );

# One liner, to allow MakeMaker to work.
$VERSION = '1.400';
# This file is part of Palm 1.400 (March 14, 2015)


my $EPOCH_1904 = 2082844800;		# Difference between Palm's
					# epoch (Jan. 1, 1904) and
					# Unix's epoch (Jan. 1, 1970),
					# in seconds.


sub palm2epoch {
	return $_[0] - $EPOCH_1904;
}


sub epoch2palm {
	return $_[0] + $EPOCH_1904;
}


sub mkpdbname {
	my $name = shift;
	$name =~ s![%/\x00-\x19\x7f-\xff]!sprintf("%%%02X",ord($&))!ge;
	return $name;
}


1;

__END__

=head1 NAME

Palm - Palm OS utility functions

=head1 VERSION

This document describes version 1.400 of
Palm, released March 14, 2015
as part of Palm version 1.400.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 palm2epoch

	my @parts = localtime( palm2epoch($palmtime) );

Converts a S<Palm OS> timestamp to a Unix Epoch time. Note, however, that S<Palm OS>
time is in the timezone of the Palm itself while Epoch is defined to be in
the GMT timezone. Further conversion may be necessary.

=head2 epoch2palm

	my $palmtime = epoch2palm( time() );

Converts Unix epoch time to Palm OS time.

=head2 mkpdbname

	$PDB->Write( mkpdbname($PDB->{name}) );

Convert a S<Palm OS> database name to a 7-bit ASCII representation. Native
Palm database names can be found in ISO-8859-1 encoding. This encoding
isn't going to generate the most portable of filenames and, in particular,
ColdSync databases use this representation.

=head1 SEE ALSO

L<Palm::PDB>

=head1 CONFIGURATION AND ENVIRONMENT

Palm requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHORS

Andrew Arensburger C<< <arensb AT ooblick.com> >>

Currently maintained by Christopher J. Madsen C<< <perl AT cjmweb.net> >>

Please report any bugs or feature requests
to S<C<< <bug-Palm AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=Palm >>.

You can follow or contribute to p5-Palm's development at
L<< https://github.com/madsen/p5-Palm >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Andrew Arensburger & Alessandro Zummo.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
