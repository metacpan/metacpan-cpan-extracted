use strict;
use warnings;
package Net::SAML2::Util;
our $VERSION = '0.79'; # VERSION

use Crypt::OpenSSL::Random qw(random_pseudo_bytes);

# ABSTRACT: Utility functions for Net::SAML2

use Exporter qw(import);

our @EXPORT_OK = qw(
    generate_id
    deprecation_warning
);

sub generate_id {
    return 'NETSAML2_' . unpack 'H*', random_pseudo_bytes(32);
}

sub deprecation_warning {
    warn "Net::SAML2 deprecation warning: " . shift . "\n";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Util - Utility functions for Net::SAML2

=head1 VERSION

version 0.79

=head1 SYNOPSIS

    use Net::SAML2::Util qw(generate_id);

=head1 DESCRIPTION

=head1 METHODS

=head2 sub generate_id {}

Generate a NETSAML2 Request Id

=head2 sub deprecation_warning {}

Show a warning that a Deprecated feature is being used

=head1 AUTHORS

=over 4

=item *

Chris Andrews  <chrisa@cpan.org>

=item *

Timothy Legge <timlegge@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
