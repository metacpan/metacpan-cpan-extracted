package Net::SAML2::Role::VerifyXML;
use Moose::Role;
our $VERSION = '0.80'; # VERSION

use Net::SAML2::XML::Sig;
use Crypt::OpenSSL::Verify;
use Crypt::OpenSSL::X509;
use Carp qw(croak);
use List::Util qw(none);
use Try::Tiny;

# ABSTRACT: A role to verify the SAML response XML




sub verify_xml {
    my $self = shift;
    my $xml  = shift;
    my %args = @_;

    my $cacert   = delete $args{cacert};
    my $anchors  = delete $args{anchors};

    my $x = Net::SAML2::XML::Sig->new({
        x509      => 1,
        %args,
    });

    croak("XML signature check failed") unless $x->verify($xml);

    return if !$anchors && !$cacert;

    my $cert = $x->signer_cert
        or die "Certificate not provided in SAML Response, cannot validate\n";

    if ($cacert) {
        my $ca = Crypt::OpenSSL::Verify->new($cacert, { strict_certs => 0 });
        try { $ca->verify($cert) }
        catch {
            croak("Could not verify CA certificate: $_");
        };
    }

    return if !$anchors;

    if (ref $anchors ne 'HASH') {
        croak("Unable to verify anchor trust");
    }

    my ($key) = keys %$anchors;
    if (none { $key eq $_ } qw(subject issuer issuer_hash)) {
        croak("Unable to verify anchor trust, requires subject, issuer or issuer_hash");
    }

    my $got = $cert->$key;
    my $want = $anchors->{$key};
    if (!ref $want) {
        $want = [ $want ];
    }

    if (none { $_ eq $got } @$want) {
        croak("Could not verify trust anchors of certificate!");
    }
    return;

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Role::VerifyXML - A role to verify the SAML response XML

=head1 VERSION

version 0.80

=head1 SYNOPSIS

    use Net::SAML2::Some::Module;

    use Moose;
    with 'Net::SAML2::Role::VerifyXML';

    sub do_something_with_xml {
        my $self = shift;
        my $xml  = shift;

        $self->verify_xml($xml,
            # Most of these options are passed to Net::SAML2::XML::Sig, except for the
            # cacert
            # Most options are optional
            cacert    => $self->cacert,
            cert_text => $self->cert,
            no_xml_declaration => 1,
        );
    }

=head1 DESCRIPTION

=head1 METHODS

=head2 verify_xml($xml, %args)

    $self->verify_xml($xml,
        # Most of these options are passed to Net::SAML2::XML::Sig, except for the
        # cacert
        # Most options are optional
        cert_text => $self->cert,
        no_xml_declaration => 1,

        # Used for a trust model, if lacking, everything is trusted
        cacert  => $self->cacert,
        # or check specific certificates based on subject/issuer or issuer hash
        anchors => {
            # one of the following is allowed
            subject     => ["subject a",     "subject b"],
            issuer      => ["Issuer A",      "Issuer B"],
            issuer_hash => ["Issuer A hash", "Issuer B hash"],
        },
    );

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
