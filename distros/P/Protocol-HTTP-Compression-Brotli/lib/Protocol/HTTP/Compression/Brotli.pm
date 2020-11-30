package Protocol::HTTP::Compression::Brotli;
use Protocol::HTTP;

our $VERSION = '1.0.3';

XS::Loader::bootstrap;

1;

=head1 NAME

Protocol::HTTP::Compression::Brotli - Brotli compression plugin for Protocol::HTTP

=cut

=head1 DESCRIPTION

This module does not have any Perl interface or usage from Perl. It is just needed
to be installed to allow transparent brotli compression/uncompression of 
Content-Endoding in L<Protocol::HTTP>. In other words, L<Protocol::HTTP> is
responsible for loading this optional compression plugin.

=head1 SEE ALSO

L<Protocol::HTTP>

L<Brotli|https://github.com/google/brotli>

L<XS::libbrotli>

=head1 AUTHOR

Ivan Baidakou <dmol@cpan.org>, Crazy Panda LTD

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
