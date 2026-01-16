package SBOM::CycloneDX::Enum::ProtocolType;

use 5.010001;
use strict;
use warnings;
use utf8;

use Exporter 'import';
our (@EXPORT_OK, %EXPORT_TAGS, %ENUM);

BEGIN {

    %ENUM = (
        TLS           => 'tls',
        SSH           => 'ssh',
        IPSEC         => 'ipsec',
        IKE           => 'ike',
        SSTP          => 'sstp',
        WPA           => 'wpa',
        DTLS          => 'dtls',
        QUIC          => 'quic',
        EAP_AKA       => 'eap-aka',
        EAP_AKA_PRIME => 'eap-aka-prime',
        PRINS         => 'prins',
        X_5G_AKA      => '5g-aka',
        OTHER         => 'other',
        UNKNOWN       => 'unknown',
    );

    require constant;
    constant->import(\%ENUM);

    @EXPORT_OK   = sort keys %ENUM;
    %EXPORT_TAGS = (all => \@EXPORT_OK);

}

sub values { sort values %ENUM }


1;

=encoding utf-8

=head1 NAME

SBOM::CycloneDX::Enum::ProtocolType - The protocol type used by cryptographic assets

=head1 SYNOPSIS

    use SBOM::CycloneDX::Enum qw(PROTOCOL_TYPE);

    say PROTOCOL_TYPE->IPSEC;


    use SBOM::CycloneDX::Enum::ProtocolType;

    say SBOM::CycloneDX::Enum::ProtocolType->SSH;


    use SBOM::CycloneDX::Enum::ProtocolType qw(:all);

    say IKE;


=head1 DESCRIPTION

L<SBOM::CycloneDX::Enum::ProtocolType> is ENUM package used by L<SBOM::CycloneDX::CryptoProperties::ProtocolProperties>.


=head1 CONSTANTS

=over

=item * C<TLS>, Transport Layer Security

=item * C<SSH>, Secure Shell

=item * C<IPSEC>, Internet Protocol Security

=item * C<IKE>, Internet Key Exchange

=item * C<SSTP>, Secure Socket Tunneling Protocol

=item * C<WPA>, Wi-Fi Protected Access

=item * C<DTLS>, Datagram Transport Layer Security

=item * C<QUIC>, Quick UDP Internet Connections

=item * C<EAP_AKA>, Extensible Authentication Protocol variant

=item * C<EAP_AKA_PRIME>, Enhanced version of EAP-AKA

=item * C<PRINS>, Protection of Inter-Network Signaling

=item * C<X_5G_AKA> (5g-aka), Authentication and Key Agreement for 5G

=item * C<OTHER>, Another protocol type

=item * C<UNKNOWN>, The protocol type is not known

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-SBOM-CycloneDX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-SBOM-CycloneDX>

    git clone https://github.com/giterlizzi/perl-SBOM-CycloneDX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2025-2026 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
