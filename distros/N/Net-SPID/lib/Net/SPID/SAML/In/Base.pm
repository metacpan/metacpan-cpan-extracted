package Net::SPID::SAML::In::Base;
$Net::SPID::SAML::In::Base::VERSION = '0.15';
use Moo;

extends 'Net::SPID::SAML::ProtocolMessage';

has '_idp'  => (is => 'rw', required => 0); # Net::SPID::SAML::IdP
has 'xml'   => (is => 'ro', required => 1);
has 'url'   => (is => 'ro', required => 0);
has 'xpath' => (is => 'lazy');

my %fields = qw(
    ID              /*/@ID
    Destination     /*/@Destination
    InResponseTo    /*/@InResponseTo
    Issuer          /*/saml:Issuer
);

# generate accessors for all the above fields
foreach my $f (keys %fields) {
    has $f => (is => 'lazy', builder => sub {
        $_[0]->xpath->findvalue($fields{$f})->value
    });
}

has 'relaystate' => (is => 'ro');

use Carp qw(croak);
use Crypt::OpenSSL::RSA;
use IO::Uncompress::RawInflate qw(rawinflate);
use MIME::Base64 qw(decode_base64);
use XML::XPath;
use URI;
use URI::QueryParam;

sub BUILDARGS {
    my ($class, %args) = @_;
    
    if (exists $args{base64}) {
        $args{xml} = decode_base64(delete $args{base64});
    }
    
    if (exists $args{url}) {
        my $u = URI->new($args{url});
        if ($u->query_param('SAMLEncoding')) {
            croak "Invalid SAMLEncoding"
                if $u->query_param('SAMLEncoding') ne 'urn:oasis:names:tc:SAML:2.0:bindings:URL-Encoding:DEFLATE';
        }
        my $payload = $u->query_param('SAMLRequest') // $u->query_param('SAMLResponse');
        $payload = decode_base64($payload);
        rawinflate \$payload => \my $deflated;
        $args{xml} = $deflated;
        $args{relaystate} //= $u->query_param('RelayState');
    }
    
    return {%args};
}

sub BUILD {
    my ($self) = @_;
    
    print STDERR $self->xml;
}

sub _build_xpath {
    my ($self) = @_;
    
    my $xpath = XML::XPath->new(xml => $self->xml);
    $xpath->set_namespace('saml',  'urn:oasis:names:tc:SAML:2.0:assertion');
    $xpath->set_namespace('samlp', 'urn:oasis:names:tc:SAML:2.0:protocol');
    $xpath->set_namespace('dsig',  'http://www.w3.org/2000/09/xmldsig#');
    return $xpath;
}

sub validate {
    my ($self, %args) = @_;
    
    my $xpath = $self->xpath;
    
    # detect IdP
    my $idp = $self->_idp($self->_spid->get_idp($self->Issuer))
        or croak "Unknown Issuer: " . $self->Issuer;
    
    return 1;
}

sub _validate_post_or_redirect {
    my ($self) = @_;
    
    my $xpath = $self->xpath;
    
    if ($xpath->findnodes('/*/dsig:Signature')->size > 0) {
        # message is signed, it's HTTP-POST
        my $pubkey = Crypt::OpenSSL::RSA->new_public_key($self->_idp->cert->pubkey);
        Mojo::XMLSig::verify($self->xml, $pubkey)
            or croak "Signature verification failed";
    } elsif ($self->url) {
        # this is supposed to be a HTTP-Redirect binding
        my $u = URI->new($self->url);
        
        # verify the response
        my $SigAlg = $u->query_param('SigAlg');
        my $pubkey = Crypt::OpenSSL::RSA->new_public_key($self->_idp->cert->pubkey);
        if ($SigAlg eq 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha256') {
            $pubkey->use_sha256_hash;
        } elsif ($SigAlg eq 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha384') {
            $pubkey->use_sha384_hash;
        } elsif ($SigAlg eq 'http://www.w3.org/2001/04/xmldsig-more#rsa-sha512') {
            $pubkey->use_sha512_hash;
        } else {
            croak "Unsupported SigAlg: $SigAlg";
        }
        
        my $sig = decode_base64($u->query_param_delete('Signature'));
        $pubkey->verify($u->query, $sig)
            or croak "Signature verification failed";
    
        return 1;
    } else {
        croak "Message does not contain signature, and URL was not supplied.";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::SPID::SAML::In::Base

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
