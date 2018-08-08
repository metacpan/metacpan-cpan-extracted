package Net::SPID::SAML::Out::Base;
$Net::SPID::SAML::Out::Base::VERSION = '0.15';
use Moo;

extends 'Net::SPID::SAML::ProtocolMessage';

has '_idp'              => (is => 'ro', required => 1); # Net::SPID::SAML::IdP
has 'ID'                => (is => 'lazy');
has 'IssueInstant'      => (is => 'lazy');

use Crypt::OpenSSL::Random;
use DateTime;
use IO::Compress::RawDeflate qw(rawdeflate);
use MIME::Base64 qw(encode_base64);
use Mojo::XMLSig;
use XML::Writer;
use URI;
use URI::QueryParam;

sub _build_ID {
    my ($self) = @_;
    
    # first character must not be a digit
    return "_" . unpack 'H*', Crypt::OpenSSL::Random::random_pseudo_bytes(16);
}

sub _build_IssueInstant {
    my ($self) = @_;
    
    return DateTime->now(time_zone => 'UTC');
}

sub xml {
    my ($self) = @_;
    
    my $saml  = 'urn:oasis:names:tc:SAML:2.0:assertion';
    my $samlp = 'urn:oasis:names:tc:SAML:2.0:protocol';
    my $x = XML::Writer->new( 
        OUTPUT          => 'self', 
        NAMESPACES      => 1,
        FORCED_NS_DECLS => [$saml, $samlp],
        PREFIX_MAP      => {
            $saml   => 'saml2',
            $samlp  => 'saml2p'
        },
        UNSAFE          => 1,  # this enables raw()
    );
    
    return ($x, $saml, $samlp);
}

sub _signature_template {
    my ($self, $ref) = @_;
    
    my $cert = $self->_spid->sp_cert->as_string;
    $cert =~ s/^-+BEGIN CERTIFICATE-+\n//;
    $cert =~ s/\n-+END CERTIFICATE-+\n?//;
    
    # TODO: replace this with XML::Writer calls in order to disable UNSAFE?
    return <<"EOF"
  <ds:Signature xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
    <ds:SignedInfo>
      <ds:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" />
      <ds:SignatureMethod Algorithm="http://www.w3.org/2001/04/xmldsig-more#rsa-sha256" />
      <ds:Reference URI="#$ref">
        <ds:Transforms>
          <ds:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
          <ds:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" />
        </ds:Transforms>
        <ds:DigestMethod Algorithm="http://www.w3.org/2001/04/xmlenc#sha256" />
        <ds:DigestValue></ds:DigestValue>
      </ds:Reference>
    </ds:SignedInfo>
    <ds:SignatureValue></ds:SignatureValue>
    <ds:KeyInfo>
      <ds:X509Data>
        <ds:X509Certificate>$cert</ds:X509Certificate>
      </ds:X509Data>
    </ds:KeyInfo>
  </ds:Signature>
EOF
}

sub redirect_url {
    my ($self, $url, %args) = @_;
    
    $args{param} //= 'SAMLRequest';
    
    my $xml = $self->xml(binding => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');
    print STDERR $xml, "\n";
    
    my $payload = '';
    rawdeflate \$xml => \$payload;
    $payload = encode_base64($payload, '');
    
    my $u = URI->new($url);
    $u->query_param($args{param}, $payload);
    $u->query_param('RelayState', $args{relaystate}) if defined $args{relaystate};
    $u->query_param('SigAlg', 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256');
    
    my $sig = encode_base64($self->_spid->sp_key->sign($u->query), '');
    $u->query_param('Signature', $sig);

    return $u->as_string;
}

sub post_form {
    my ($self, $url, %args) = @_;
    
    my $xml = $self->xml(
        signature_template => 1,
        binding            => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST',
    );
    print "$xml\n\n";
    $xml = Mojo::XMLSig::sign($xml, $self->_spid->sp_key);
    my $payload = encode_base64($xml, '');
    
    my $param = $args{param} // 'SAMLRequest';
    my $relaystate = $args{relaystate} // '';
    $relaystate =~ s/"/&quot;/g;
    $relaystate =~ s/</&lt;/g;
    $relaystate =~ s/>/&rt;/g;
    
    return <<"EOF"
<html>
    <body onload="javascript:document.forms[0].submit()">
        <form method="post" action="$url">
            <input type="hidden" name="$param" value="$payload">
            <input type="hidden" name="RelayState" value="$relaystate">
        </form>
    </body>
</html>
EOF
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::Out::Base

=head1 VERSION

version 0.15

=for Pod::Coverage *EVERYTHING*

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Alessandro Ranellucci.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
