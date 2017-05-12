package POE::Component::Server::NNTP::Constants;
$POE::Component::Server::NNTP::Constants::VERSION = '1.06';
# ABSTRACT: importable constants for POE::Component::Server::NNTP plugins.

require Exporter;
@ISA = qw( Exporter );
%EXPORT_TAGS = ( 'ALL' => [ qw( NNTPD_EAT_NONE NNTPD_EAT_CLIENT NNTPD_EAT_PLUGIN NNTPD_EAT_ALL ) ] );
Exporter::export_ok_tags( 'ALL' );

use strict;
use warnings;

# Our constants
sub NNTPD_EAT_NONE	() { 1 }
sub NNTPD_EAT_CLIENT	() { 2 }
sub NNTPD_EAT_PLUGIN	() { 3 }
sub NNTPD_EAT_ALL	() { 4 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::NNTP::Constants - importable constants for POE::Component::Server::NNTP plugins.

=head1 VERSION

version 1.06

=head1 SYNOPSIS

  use POE::Component::Server::NNTP::Constants qw(:ALL);

=head1 DESCRIPTION

POE::Component::Server::NNTP::Constants defines a number of constants that are required by the plugin system.

=head1 EXPORTS

=over

=item C<NNTPD_EAT_NONE>

Value: 1

=item C<NNTPD_EAT_CLIENT>

Value: 2

=item C<NNTPD_EAT_PLUGIN>

Value: 3

=item C<NNTPD_EAT_ALL>

Value: 4

=back

=head1 SEE ALSO

L<POE::Component::Server::NNTP>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
