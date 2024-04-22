package Net::SAML2::Binding::SOAP;
use Moose;

our $VERSION = '0.79'; # VERSION

use Carp qw(croak);
use HTTP::Request::Common;
use LWP::UserAgent;
use MooseX::Types::URI qw/ Uri /;
use Try::Tiny;
use XML::LibXML::XPathContext;

use Net::SAML2::XML::Sig;
use Net::SAML2::XML::Util qw/ no_comments /;
use Net::SAML2::Util qw/ deprecation_warning /;

with 'Net::SAML2::Role::VerifyXML';

# ABSTRACT: SOAP binding for SAML



has 'ua' => (
    isa      => 'Object',
    is       => 'ro',
    lazy     => 1,
    builder  => 'build_user_agent',
);


sub build_user_agent {
    return LWP::UserAgent->new();
}

has 'url'      => (isa => Uri, is => 'ro', required => 1, coerce => 1);
has 'key'      => (isa => 'Str', is => 'ro', required => 1);
has 'cert'     => (isa => 'Str', is => 'ro', required => 1);
has 'idp_cert' => (isa => 'ArrayRef[Str]', is => 'ro', required => 1, predicate => 'has_idp_cert');
has 'cacert' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 0,
    predicate => 'has_cacert'
);
has 'anchors' => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 0,
    predicate => 'has_anchors'
);

has verify => (
    is        => 'ro',
    isa       => 'HashRef',
    predicate => 'has_verify',
);

# BUILDARGS

# Earlier versions expected the idp_cert to be a string.  However, metadata
# can include multiple signing certificates so the $idp->cert is now
# expected to be an arrayref to the certificates.  To avoid breaking existing
# applications this changes the the cert to an arrayref if it is not
# already an array ref.
#
# Please remove the build args logic after 6 months from april 18th 2024

around BUILDARGS => sub {
    my $orig = shift;
    my $self = shift;

    my %params = @_;
    if ($params{idp_cert} && ref($params{idp_cert}) ne 'ARRAY') {
        $params{idp_cert} = [$params{idp_cert}];
        deprecation_warning("Please use an array ref for idp_cert");
    }

    return $self->$orig(%params);
};


sub request {
    my ($self, $message) = @_;
    my $request = $self->create_soap_envelope($message);

    my $soap_action = 'http://www.oasis-open.org/committees/security';

    my $req = POST $self->url, Content => $request;
    # SOAP actions should be wrapped in double quotes:
    # https://www.w3.org/TR/2000/NOTE-SOAP-20000508/#_Toc478383528
    $req->header('SOAPAction'     => sprintf('"%s"', $soap_action));
    $req->header('Content-Type'   => 'text/xml');
    $req->header('Content-Length' => length $request);

    my $res = $self->ua->request($req);

    if (!$res->is_success) {
        croak(
            sprintf(
                "Unable to perform request: %s (%s)",
                $res->message, $res->code
            )
        );
    }

    return $self->handle_response($res->decoded_content);

}


sub handle_response {
    my ($self, $response) = @_;

    my $saml = _get_saml_from_soap($response);
    my @errors;
    foreach my $cert (@{$self->idp_cert}) {
        my $success = try {
            $self->verify_xml(
                $saml,
                no_xml_declaration => 1,
                cert_text          => $cert,
                cacert             => $self->cacert,
                anchors            => $self->anchors,
                $self->has_verify ? (
                    ns => { 'artifact' => $self->verify->{ns} },
                    id_attr => '/artifact:' . $self->verify->{attr_id},
                ) : (),
            );
            return 1;
        }
        catch { push (@errors, $_); return 0; };

        return $saml if $success;
    }

    if (@errors) {
        croak "Unable to verify XML with the given certificates: "
        . join(", ", @errors);
    }
}


sub handle_request {
    my ($self, $request) = @_;

    my $saml = _get_saml_from_soap($request);
    my @errors;
    if (defined $saml) {
        foreach my $cert (@{$self->idp_cert}) {
            my $success = try {
                $self->verify_xml(
                    $saml,
                    cert_text => $cert,
                    cacert    => $self->cacert
                );
                return 1;
            }
            catch { push (@errors, $_); return 0; };
            return $saml if $success;
        }

        if (@errors) {
            croak "Unable to verify XML with the given certificates: "
            . join(", ", @errors);
        }
    }

    return;
}

sub _get_saml_from_soap {
    my $soap  = shift;
    my $dom   = no_comments($soap);
    my $parser = XML::LibXML::XPathContext->new($dom);
    $parser->registerNs('soap-env', 'http://schemas.xmlsoap.org/soap/envelope/');
    $parser->registerNs('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');
    my $set = $parser->findnodes('/soap-env:Envelope/soap-env:Body/*');
    if ($set->size) {
        return $set->get_node(1)->toString();
    }
    return;
}


sub create_soap_envelope {
    my ($self, $message) = @_;

    # sign the message
    my $sig = Net::SAML2::XML::Sig->new({
        x509 => 1,
        key  => $self->key,
        cert => $self->cert,
        exclusive => 1,
        no_xml_declaration => 1,
    });
    my $signed_message = $sig->sign($message);

    # OpenSSO ArtifactResolve hack
    #
    # OpenSSO's ArtifactResolve parser is completely hateful. It demands that
    # the order of child elements in an ArtifactResolve message be:
    #
    # 1: saml:Issuer
    # 2: dsig:Signature
    # 3: samlp:Artifact
    #
    # Really.
    #
    if ($signed_message =~ /ArtifactResolve/) {
        $signed_message =~ s!(<dsig:Signature.*?</dsig:Signature>)!!s;
        my $signature = $1;
        $signed_message =~ s/(<\/saml:Issuer>)/$1$signature/;
    }

    # test verify
    my $ret = $sig->verify($signed_message);
    die "failed to sign" unless $ret;

    my $soap = <<"SOAP";
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/"><SOAP-ENV:Body>$signed_message</SOAP-ENV:Body></SOAP-ENV:Envelope>
SOAP
    return $soap;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SAML2::Binding::SOAP - SOAP binding for SAML

=head1 VERSION

version 0.79

=head1 SYNOPSIS

    my $soap = Net::SAML2::Binding::SOAP->new(
        url      => $idp_url,
        key      => $key,
        cert     => $cert,
        idp_cert => $idp_cert,
    );

    my $response = $soap->request($req);

Note that LWP::UserAgent maybe used which means that environment variables
may affect the use of https see:

=over

=item * L<PERL_LWP_SSL_CA_FILE and HTTPS_CA_FILE|https://metacpan.org/pod/LWP::UserAgent#SSL_ca_file-=%3E-$path>

=item * L<PERL_LWP_SSL_CA_PATH and HTTPS_CA_DIR|https://metacpan.org/pod/LWP::UserAgent#SSL_ca_path-=%3E-$path>

=back

=head1 METHODS

=head2 new( ... )

Constructor. Returns an instance of the SOAP binding configured for
the given IdP service url.

Arguments:

=over

=item B<ua>

(optional) a LWP::UserAgent-compatible UA
You can build the user agent to your liking when extending this class by
overriding C<build_user_agent>

=item B<url>

the service URL

=item B<key>

the key to sign with

=item B<cert>

the corresponding certificate

=item B<idp_cert>

the idp's signing certificate

=item B<cacert>

the CA for the SAML CoT

=back

=head2 build_user_agent

Builder for the user agent

=head2 request( $message )

Submit the message to the IdP's service.

Returns the Response, or dies if there was an error.

=head2 handle_response( $response )

Handle a response from a remote system on the SOAP binding.

Accepts a string containing the complete SOAP response.

=head2 handle_request( $request )

Handle a request from a remote system on the SOAP binding.

Accepts a string containing the complete SOAP request.

=head2 create_soap_envelope( $message )

Signs and SOAP-wraps the given message.

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
