package Net::ACME::Certificate;

=pod

=encoding utf-8

=head1 NAME

Net::ACME::Certificate - resource abstraction for C<Net::ACME>

=head1 SYNOPSIS

    my $has_cert = Net::ACME::Certificate->new(
        content => $cert_der,
        type => 'application/pkix-cert',
        issuer_cert_uri => 'http://uri/to/issuer/cert',
    );

    my $cert_pem2 = $has_cert->pem();
    my (@issuers_pem) = $has_cert->issuers_pem();

=head1 DESCRIPTION

This module encapsulates interaction with ACME “certificate” resources
when the certificate is available.

For handling cases of non-availability (i.e., HTTP 202 status from the
ACME server), see C<Net::ACME::Certificate::Pending>.

=cut

use strict;
use warnings;

use Call::Context ();
use Crypt::Format ();

use Net::ACME::HTTP ();

sub new {
    my ( $class, %opts ) = @_;

    die 'requires “content”!'         if !$opts{'content'};
    die 'requires “type”!'            if !$opts{'type'};
    die 'requires “issuer_cert_uri”!' if !$opts{'issuer_cert_uri'};

    my $self = bless {}, $class;

    $self->{"_$_"} = $opts{$_} for qw(content type issuer_cert_uri);

    return $self;
}

sub issuers_pem {
    my ($self) = @_;

    Call::Context::must_be_list();

    my @pems;

    my $uri = $self->{'_issuer_cert_uri'};
    while ($uri) {
        my $http = Net::ACME::HTTP->new();
        my $resp = $http->get($uri);

        #TODO: Check response status code.

        _STATIC_die_if_wrong_mime_type( $resp->header('content-type') );

        push @pems, _STATIC_der_to_pem( $resp->content() );

        my $new_uri = { $resp->links() }->{'up'};

        #Paranoia: Detect weirdness where an ACME server might consider
        #a root cert to be its own issuer (cuz it is, really).
        undef $new_uri if $new_uri && $new_uri eq $uri;

        $uri = $new_uri;
    }

    return @pems;
}

sub pem {
    my ($self) = @_;

    if ( defined $self->{'_type'} ) {
        _STATIC_die_if_wrong_mime_type( $self->{'_type'} );

        return _STATIC_der_to_pem( $self->{'_content'} );
    }

    return undef;
}

#----------------------------------------------------------------------

sub _STATIC_die_if_wrong_mime_type {
    my ($type) = @_;

    if ( $type ne 'application/pkix-cert' ) {
        die "Unrecognized certificate MIME type: “$type”";
    }

    return;
}

sub _STATIC_der_to_pem {
    my ($der) = @_;

    return Crypt::Format::der2pem( $der, 'CERTIFICATE' );
}

1;
