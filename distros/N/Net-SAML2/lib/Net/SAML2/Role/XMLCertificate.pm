package Net::SAML2::Role::XMLCertificate;
use Moose::Role;

our $VERSION = '0.88'; # VERSION

# ABSTRACT: Common behaviour for Certificates in XML


sub get_pem_from_keynode {
    my $self = shift;
    my $node = shift;

    $node->setNamespace('http://www.w3.org/2000/09/xmldsig#', 'ds');

    my ($text)
        = $node->findvalue("ds:KeyInfo/ds:X509Data/ds:X509Certificate", $node)
        =~ /^\s*(.+?)\s*$/s;

    # rewrap the base64 data from the metadata; it may not
    # be wrapped at 64 characters as PEM requires
    $text =~ s/\n//g;

    my @lines;
    while(length $text > 64) {
        push @lines, substr $text, 0, 64, '';
    }
    push @lines, $text;

    $text = join "\n", @lines;

    return "-----BEGIN CERTIFICATE-----\n$text\n-----END CERTIFICATE-----\n";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Role::XMLCertificate - Common behaviour for Certificates in XML

=head1 VERSION

version 0.88

=head2 B<get_pem_from_keynode>

Get the PEM from the X509Certificate.

=head1 AUTHOR

Timothy Legge <timlegge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Venda Ltd, see the CONTRIBUTORS file for others.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
