package Net::Amazon::S3::Signature::V4;
# ABSTRACT: V4 signatures
$Net::Amazon::S3::Signature::V4::VERSION = '0.98';
use Moose;

use Net::Amazon::S3::Signature::V4Implementation;
use Digest::SHA;
use Ref::Util;

use Net::Amazon::S3::Constants;
use Net::Amazon::S3::Signature::V2;

use namespace::clean;

extends 'Net::Amazon::S3::Signature';

sub enforce_use_virtual_host {
    1;
}

sub redirect_handler {
    my ($self, $http_request, $response, $ua, $h) = @_;

    my $region = $response->header(Net::Amazon::S3::Constants->HEADER_BUCKET_REGION) or return;

    # change the bucket region in request
    my $request = $response->request;
    $request->uri( $response->header( 'location' ) );

    # sign the request again
    $request->headers->remove_header('Authorization');
    $request->headers->remove_header(Net::Amazon::S3::Constants->HEADER_DATE);
    $http_request->_sign_request( $request, $region );

    return $request;
}

sub _sign {
    my ($self, $region) = @_;

    return Net::Amazon::S3::Signature::V4Implementation->new(
        $self->http_request->s3->aws_access_key_id,
        $self->http_request->s3->aws_secret_access_key,
        $region || $self->http_request->region,
        's3',
    );
}

sub _host_to_region_host {
    my ($self, $sign, $request) = @_;

    my $host = $request->uri->host;
    return if $sign->{endpoint} eq 'us-east-1';
    return unless $host =~ s/(?<=\bs3)(?=\.amazonaws\.com$)/"-" . $sign->{endpoint}/e;

    $request->uri->host( $host );
}

sub sign_request {
    my ($self, $request, $region) = @_;

    my $sha = Digest::SHA->new( '256' );
    if (Ref::Util::is_coderef( my $coderef = $request->content )) {
        while (length (my $snippet = $coderef->())) {
            $sha->add ($snippet);
        }

        $request->header( $Net::Amazon::S3::Signature::V4Implementation::X_AMZ_CONTENT_SHA256 => $sha->hexdigest );
    }

	$self->_append_authorization_headers ($request);

    my $sign = $self->_sign( $region );
    $self->_host_to_region_host( $sign, $request );
    $sign->sign( $request );

    return $request;
}

sub sign_uri {
    my ($self, $request, $expires_at) = @_;

	$self->_append_authorization_query_params ($request);

    my $sign = $self->_sign;
    $self->_host_to_region_host( $sign, $request );

    return $sign->sign_uri( $request->uri, $expires_at - time, $request->method );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Signature::V4 - V4 signatures

=head1 VERSION

version 0.98

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
