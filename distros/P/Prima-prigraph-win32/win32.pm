package Prima::prigraph::win32;
use vars qw($VERSION);

$VERSION = '1.06';

1;

__DATA__

=pod

=head1 NAME 

Prima::prigraph::win32 - binary prigraph.dll distribution for win32

=head1 DISTRIBUTION

L<Prima> needs image libraries to work correctly. Unix and cygwin builds rely
on existing installations of C<libjpeg>, C<libungif>, C<libtiff>, C<libpng>,
C<libXpm>, and C<libX11>, all of them being optional dependencies.

This binary distribution provides support for the BMP,PCX,GIF,JPEG,TIFF,PNG,XBM,XPM 
graphic formats, among others, for MSVC and cygwin builds.

=head1 SEE ALSO

L<Prima>

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
