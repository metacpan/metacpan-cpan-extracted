package POE::Component::Server::SimpleSMTP::Constants;
BEGIN {
  $POE::Component::Server::SimpleSMTP::Constants::VERSION = '1.50';
}

#ABSTRACT: importable constants for POE::Component::Server::SimpleSMTP plugins.

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our %EXPORT_TAGS = ( 'ALL' => [ qw( SMTPD_EAT_NONE SMTPD_EAT_CLIENT SMTPD_EAT_PLUGIN SMTPD_EAT_ALL ) ] );
Exporter::export_ok_tags( 'ALL' );

# Our constants
sub SMTPD_EAT_NONE	() { 1 }
sub SMTPD_EAT_CLIENT	() { 2 }
sub SMTPD_EAT_PLUGIN	() { 3 }
sub SMTPD_EAT_ALL	() { 4 }

1;


__END__
=pod

=head1 NAME

POE::Component::Server::SimpleSMTP::Constants - importable constants for POE::Component::Server::SimpleSMTP plugins.

=head1 VERSION

version 1.50

=head1 SYNOPSIS

  use POE::Component::Server::SimpleSMTP::Constants qw(:ALL);

=head1 DESCRIPTION

POE::Component::Server::SimpleSMTP::Constants defines a number of constants that are required by the plugin system.

=head1 EXPORTS

=over

=item SMTPD_EAT_NONE

Value: 1

=item SMTPD_EAT_CLIENT

Value: 2

=item SMTPD_EAT_PLUGIN

Value: 3

=item SMTPD_EAT_ALL

Value: 4

=back

=head1 SEE ALSO

L<POE::Component::Server::SimpleSMTP>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

