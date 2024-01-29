package Protocol::Database::PostgreSQL::Constants;

use strict;
use warnings;

our $VERSION = '2.001'; # VERSION

=head1 NAME

Protocol::Database::PostgreSQL::Constants - some constants used in the PostgreSQL protocol

=head1 DESCRIPTION

Exports some constants - mostly SSL-related.

=cut

use Exporter qw(import export_to_level);

use List::Util qw(uniqstr);

=head1 EXPORTS

(note that SSL here actually means TLS).

=over 4

=item * C<SSL_DISABLE> - do not use SSL

=item * C<SSL_PREFER> - use SSL if we can

=item * C<SSL_REQUIRE> - only use SSL

=back

=cut

use constant {
    SSL_DISABLE => 0,
    SSL_PREFER  => 1,
    SSL_REQUIRE => 2,
};

=head2 SSL_NAME_MAP

Mapping from plain text words to the C<SSL_*> constants.

=over 4

=item * C<disable>

=item * C<prefer>

=item * C<require>

=back

=cut

our %SSL_NAME_MAP = (
    disable => SSL_DISABLE,
    prefer  => SSL_PREFER,
    require => SSL_REQUIRE,
);

our %EXPORT_TAGS = (
    v1 => [qw(SSL_DISABLE SSL_PREFER SSL_REQUIRE)],
);
our @EXPORT_OK = uniqstr map { @$_ } values %EXPORT_TAGS;

1;

__END__

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2010-2019. Licensed under the same terms as Perl itself.

