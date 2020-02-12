package Net::Amazon::S3::Signature::V4;
# ABSTRACT: V4 signatures
$Net::Amazon::S3::Signature::V4::VERSION = '0.89';
use Moose;

use Net::Amazon::S3::Signature::V4Implementation;
use Digest::SHA;
use Ref::Util;

use Net::Amazon::S3::Signature::V2;

use namespace::clean;

extends 'Net::Amazon::S3::Signature';

sub enforce_use_virtual_host {
    1;
}

sub redirect_handler {
    my ($self, $http_request, $response, $ua, $h) = @_;

    my $region = $response->header('x-amz-bucket-region') or return;

    # change the bucket region in request
    my $request = $response->request;
    $request->uri( $response->header( 'location' ) );

    # sign the request again
    $request->headers->remove_header('Authorization');
    $request->headers->remove_header('x-amz-date');
    $http_request->_sign_request( $request, $region );

    return $request;
}

sub _bucket_region {
    my ($self) = @_;

    return $self->http_request->region;
}

sub _sign {
    my ($self, $region) = @_;

    return Net::Amazon::S3::Signature::V4Implementation->new(
        $self->http_request->s3->aws_access_key_id,
        $self->http_request->s3->aws_secret_access_key,
        $region || $self->_bucket_region,
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

    unless ($request->header ('x-amz-security-token')) {
        my $aws_session_token = $self->http_request->s3->aws_session_token;
        $request->header ('x-amz-security-token' => $aws_session_token)
            if defined $aws_session_token;
    }

    my $sign = $self->_sign( $region );
    $self->_host_to_region_host( $sign, $request );
    $sign->sign( $request );

    return $request;
}

sub sign_uri {
    my ($self, $request, $expires_at) = @_;

    unless ($request->uri->query_param('x-amz-security-token')) {
        my $aws_session_token = $self->http_request->s3->aws_session_token;
        $request->uri->query_param('x-amz-security-token' => $aws_session_token)
            if defined $aws_session_token;
    }

    my $sign = $self->_sign;
    $self->_host_to_region_host( $sign, $request );

    return $sign->sign_uri( $request->uri, $expires_at - time );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Signature::V4 - V4 signatures

=head1 VERSION

version 0.89

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
