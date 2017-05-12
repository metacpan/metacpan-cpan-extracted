package Net::SAML2::IdP;
use Moose;
use MooseX::Types::Moose qw/ Str Object HashRef ArrayRef /;
use MooseX::Types::URI qw/ Uri /;

=head1 NAME

Net::SAML2::IdP - SAML Identity Provider object

=head1 SYNOPSIS

  my $idp = Net::SAML2::IdP->new_from_url($IDP);
  my $sso_url = $idp->sso_url('urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect');

=head1 METHODS

=cut

use Crypt::OpenSSL::VerifyX509;
use Crypt::OpenSSL::X509;
use HTTP::Request::Common;
use LWP::UserAgent;
use XML::XPath;

=head2 new

Constructor

 * entityID

=cut

has 'entityid'       => (isa => Str, is => 'ro', required => 1);
has 'cacert'         => (isa => Str, is => 'ro', required => 1);
has 'sso_urls'       => (isa => HashRef[Str], is => 'ro', required => 1);
has 'slo_urls'       => (isa => HashRef[Str], is => 'ro', required => 1);
has 'art_urls'       => (isa => HashRef[Str], is => 'ro', required => 1);
has 'certs'          => (isa => HashRef[Str], is => 'ro', required => 1);
has 'formats'        => (isa => HashRef[Str], is => 'ro', required => 1);
has 'default_format' => (isa => Str, is => 'ro', required => 1);

=head2 new_from_url( url => $url, cacert => $cacert )

Create an IdP object by retrieving the metadata at the given URL.

Dies if the metadata can't be retrieved.

=cut

sub new_from_url {
    my ($class, %args) = @_;
        
    my $req = GET $args{url};
    my $ua = LWP::UserAgent->new;

    my $res = $ua->request($req);
    die "no metadata" unless $res->is_success;
    my $xml = $res->content;

    return $class->new_from_xml( xml => $xml, cacert => $args{cacert} );
}

=head2 new_from_xml( xml => $xml, cacert => $cacert )

Constructor. Create an IdP object using the provided metadata XML
document.

=cut

sub new_from_xml {
    my ($class, %args) = @_;

    my $xpath = XML::XPath->new( xml => $args{xml} );
    $xpath->set_namespace('md', 'urn:oasis:names:tc:SAML:2.0:metadata');
    $xpath->set_namespace('ds', 'http://www.w3.org/2000/09/xmldsig#');

    my $data;

    for my $sso ($xpath->findnodes('//md:EntityDescriptor/md:IDPSSODescriptor/md:SingleSignOnService')) {
        my $binding = $sso->getAttribute('Binding');
        $data->{SSO}->{$binding} = $sso->getAttribute('Location');
    }

    for my $slo ($xpath->findnodes('//md:EntityDescriptor/md:IDPSSODescriptor/md:SingleLogoutService')) {
        my $binding = $slo->getAttribute('Binding');
        $data->{SLO}->{$binding} = $slo->getAttribute('Location');
    }

    for my $art ($xpath->findnodes('//md:EntityDescriptor/md:IDPSSODescriptor/md:ArtifactResolutionService')) {
        my $binding = $art->getAttribute('Binding');
        $data->{Art}->{$binding} = $art->getAttribute('Location');
    }

    for my $format ($xpath->findnodes('//md:EntityDescriptor/md:IDPSSODescriptor/md:NameIDFormat')) {
        $format = $format->string_value;
        my ($short_format) = $format =~ /urn:oasis:names:tc:SAML:(?:2.0|1.1):nameid-format:(.*)$/;
        if (defined $short_format) {
            $data->{NameIDFormat}->{$short_format} = $format;
            $data->{DefaultFormat} = $short_format unless exists $data->{DefaultFormat};
        }
    }

    for my $key ($xpath->findnodes('//md:EntityDescriptor/md:IDPSSODescriptor/md:KeyDescriptor')) {
        my $use = $key->getAttribute('use');
        my ($text) = $key->findvalue('ds:KeyInfo/ds:X509Data/ds:X509Certificate') =~ /^\s*(.+?)\s*$/s;

        # rewrap the base64 data from the metadata; it may not
        # be wrapped at 64 characters as PEM requires
        $text =~ s/\n//g;

        my @lines;
        while (length $text > 64) {
            push @lines, substr $text, 0, 64, '';
        }
        push @lines, $text;

        $text = join "\n", @lines;
                
        # form a PEM certificate
        $data->{Cert}->{$use} = sprintf("-----BEGIN CERTIFICATE-----\n%s\n-----END CERTIFICATE-----\n", $text);
    }
        
    my $self = $class->new(
        entityid       => $xpath->findvalue('//md:EntityDescriptor/@entityID')->value,
        sso_urls       => $data->{SSO},
        slo_urls       => $data->{SLO},
        art_urls       => $data->{Art},
        certs          => $data->{Cert},
        formats        => $data->{NameIDFormat},
        default_format => $data->{DefaultFormat},
        cacert         => $args{cacert},
    );

    return $self;
}

sub BUILD {
    my ($self) = @_;
    my $ca = Crypt::OpenSSL::VerifyX509->new($self->cacert);
        
    for my $use (keys %{ $self->certs }) {
        my $cert = Crypt::OpenSSL::X509->new_from_string($self->certs->{$use});
        unless ($ca->verify($cert)) {
            die "can't verify IdP '$use' cert";
        }
    }       
}

=head2 sso_url($binding)

Returns the url for the SSO service using the given binding. Binding
name should be the full URI. 

=cut

sub sso_url {
    my ($self, $binding) = @_;
    return $self->sso_urls->{$binding};
}

=head2 slo_url($binding)

Returns the url for the Single Logout Service using the given
binding. Binding name should be the full URI.

=cut

sub slo_url {
    my ($self, $binding) = @_;
    return $self->slo_urls->{$binding};
}

=head2 art_url($binding)

Returns the url for the Artifact Resolution service using the given
binding. Binding name should be the full URI.

=cut

sub art_url {
    my ($self, $binding) = @_;
    return $self->art_urls->{$binding};
}

=head2 cert($use)

Returns the IdP's certificate for the given use (e.g. 'signing').

=cut

sub cert {
    my ($self, $use) = @_;
    return $self->certs->{$use};
}

=head2 binding($name)

Returns the full Binding URI for the given binding name. Includes this
module's currently-supported bindings.

=cut

sub binding {
    my ($self, $name) = @_;

    my $bindings = {
        redirect => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
        soap     => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
    };
        
    if (exists $bindings->{$name}) {
        return $bindings->{$name};
    }

    return;
}

=head2 format($short_name)

Returns the full NameID Format URI for the given short name.

If no short name is provided, returns the URI for the default format,
the one listed first by the IdP.

If no NameID formats were advertised by the IdP, returns undef.

=cut

sub format {
    my ($self, $short_name) = @_;

    if (defined $short_name && exists $self->formats->{$short_name}) {
        return $self->formats->{$short_name};
    }
    elsif ($self->default_format) {
        return $self->formats->{$self->default_format};
    }
    else {
        return;
    }
}

__PACKAGE__->meta->make_immutable;
