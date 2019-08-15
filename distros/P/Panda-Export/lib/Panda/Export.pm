package Panda::Export;
use 5.012;

our $VERSION = '2.2.8';

=head1 NAME

Panda::Export - [DEPRECATED] Replacement for Exporter.pm + const.pm written in C, also provides C API.

=cut

require Panda::XSLoader;
Panda::XSLoader::load();

=head1 DESCRIPTION

This module is deprecated and fully unsupported. Use L<Export::XS> instead.

=head1 AUTHOR

Pronin Oleg <syber@cpan.org>, Crazy Panda LTD

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
