package POE::Component::Client::NNTP::Constants;
{
  $POE::Component::Client::NNTP::Constants::VERSION = '2.22';
}

# ABSTRACT: importable constants for POE::Component::Client::NNTP plugins.

use strict;
use warnings;

require Exporter;
our @ISA = qw( Exporter );
our %EXPORT_TAGS = ( 'ALL' => [ qw( NNTP_EAT_NONE NNTP_EAT_CLIENT NNTP_EAT_PLUGIN NNTP_EAT_ALL ) ] );
Exporter::export_ok_tags( 'ALL' );

# Our constants
sub NNTP_EAT_NONE	() { 1 }
sub NNTP_EAT_CLIENT	() { 2 }
sub NNTP_EAT_PLUGIN	() { 3 }
sub NNTP_EAT_ALL	() { 4 }

1;


__END__
=pod

=head1 NAME

POE::Component::Client::NNTP::Constants - importable constants for POE::Component::Client::NNTP plugins.

=head1 VERSION

version 2.22

=head1 SYNOPSIS

  use POE::Component::Client::NNTP::Constants qw(:ALL);

=head1 DESCRIPTION

POE::Component::Client::NNTP::Constants defines a number of constants that are required by the plugin system.

=head1 EXPORTS

=over

=item C<NNTP_EAT_NONE>

Value: 1

=item C<NNTP_EAT_CLIENT>

Value: 2

=item C<NNTP_EAT_PLUGIN>

Value: 3

=item C<NNTP_EAT_ALL>

Value: 4

=back

=head1 SEE ALSO

L<POE::Component::Client::NNTP>

L<POE::Component::Pluggable>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chris Williams and Dennis Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

