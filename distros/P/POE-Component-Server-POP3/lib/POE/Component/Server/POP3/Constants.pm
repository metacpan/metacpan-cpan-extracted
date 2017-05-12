package POE::Component::Server::POP3::Constants;
$POE::Component::Server::POP3::Constants::VERSION = '0.12';
#ABSTRACT: importable constants for POE::Component::Server::POP3 plugins.

require Exporter;
@ISA = qw( Exporter );
%EXPORT_TAGS = ( 'ALL' => [ qw( POP3D_EAT_NONE POP3D_EAT_CLIENT POP3D_EAT_PLUGIN POP3D_EAT_ALL ) ] );
Exporter::export_ok_tags( 'ALL' );

use strict;
use warnings;

# Our constants
sub POP3D_EAT_NONE	() { 1 }
sub POP3D_EAT_CLIENT	() { 2 }
sub POP3D_EAT_PLUGIN	() { 3 }
sub POP3D_EAT_ALL	() { 4 }

qq[POP3 will eat itself];

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::POP3::Constants - importable constants for POE::Component::Server::POP3 plugins.

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  use POE::Component::Server::POP3::Constants qw(:ALL);

=head1 DESCRIPTION

POE::Component::Server::POP3::Constants defines a number of constants that are required by the plugin system.

=head1 EXPORTS

=over

=item C<POP3D_EAT_NONE>

Value: 1

=item C<POP3D_EAT_CLIENT>

Value: 2

=item C<POP3D_EAT_PLUGIN>

Value: 3

=item C<POP3D_EAT_ALL>

Value: 4

=back

=head1 SEE ALSO

L<POE::Component::Server::POP3>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
