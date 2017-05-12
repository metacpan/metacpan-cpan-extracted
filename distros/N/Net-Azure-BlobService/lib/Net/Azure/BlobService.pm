package Net::Azure::BlobService;
use HTTP::Date;
use Digest::MD5 qw(md5_base64);
use Digest::SHA qw(hmac_sha256_base64);
use LWP::UserAgent;
use MIME::Base64;
use Moose;
our $VERSION = '0.35';

has 'primary_access_key' => ( is => 'ro', isa => 'Str', required => 1 );
has 'user_agent' => (
    is      => 'ro',
    isa     => 'LWP::UserAgent',
    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->env_proxy;
        return $ua;
    }
);

sub sign_http_request {
    my ( $self, $http_request ) = @_;

    my $host = $http_request->uri->host;
    my ($account) = $host =~ /^(.+?)\./;

    $http_request->header( ':x-ms-version', '2011-08-18' );
    $http_request->header( 'Date',          time2str() );
    $http_request->content_length( length $http_request->content );

    my $canonicalized_headers = join "",
        map { lc( substr( $_, 1 ) ) . ':' . $http_request->header($_) . "\n" }
        sort grep {/^:x-ms/i} $http_request->header_field_names;

    my $canonicalized_resource
        = '/' . $account . $http_request->uri->path . join "", map {
              "\n"
            . lc($_) . ':'
            . join( ',', sort $http_request->uri->query_param($_) )
        } sort $http_request->uri->query_param;

    my $string_to_sign
        = $http_request->method . "\n"
        . ( $http_request->header('Content-Encoding')    // '' ) . "\n"
        . ( $http_request->header('Content-Language')    // '' ) . "\n"
        . ( $http_request->header('Content-Length')      // '' ) . "\n"
        . ( $http_request->header('Content-MD5')         // '' ) . "\n"
        . ( $http_request->header('Content-Type')        // '' ) . "\n"
        . ( $http_request->header('Date')                // '' ) . "\n"
        . ( $http_request->header('If-Modified-Since')   // '' ) . "\n"
        . ( $http_request->header('If-Match')            // '' ) . "\n"
        . ( $http_request->header('If-None-Match')       // '' ) . "\n"
        . ( $http_request->header('If-Unmodified-Since') // '' ) . "\n"
        . ( $http_request->header('Range')               // '' ) . "\n"
        . $canonicalized_headers
        . $canonicalized_resource;

    my $signature = hmac_sha256_base64( $string_to_sign,
        decode_base64( $self->primary_access_key ) );
    $signature .= '=';

    $http_request->header( 'Authorization',
        "SharedKey " . $account . ":" . $signature );
    return $http_request;
}

sub make_http_request {
    my ( $self, $http_request ) = @_;
    $self->sign_http_request($http_request);
    return $self->user_agent->request($http_request);
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Net::Azure::BlobService - Interface to Azure Blob Service

=head1 SYNOPSIS

  my $blobservice = Net::Azure::BlobService->new(
      primary_access_key => $primary_access_key );

  # Get Blob Service Properties
  my $uri = URI->new("https://$account.blob.core.windows.net/");
  $uri->query_form( [ restype => 'service', comp => 'properties' ] );
  my $request = GET $uri;

  my $response = $blobservice->make_http_request($request);

=head1 DESCRIPTION

This module provides access to the REST interface to Windows Azure Platform Blob
Service for storing text and binary data:

  http://msdn.microsoft.com/en-us/library/windowsazure/dd135733.aspx

You must sign up to a storage account and obtain a primary access key. Create an
HTTP request as per the page above and this module can sign the request, make
the request and return an HTTP::Response object.

See the examples/ directory for more examples on calling different Blob Service
operations.

This module intentionally does not interpret the response, but typically it will
have content type of 'application/xml' which you can parse with your favourite
XML parser.

=head1 METHODS

=head2 make_http_request

Sign and make an HTTP request:

  my $response = $blobservice->make_http_request($request);

=head2 sign_http_request

Sign an HTTP request:

  my $signed_request = $blobservice->sign_http_request($request);

=head1 AUTHOR

Leon Brocard <acme@astray.com>

=head1 COPYRIGHT

Copyright (C) 2012, Leon Brocard.

=head1 LICENSE

This module is free software; you can redistribute it or
modify it under the same terms as Perl itself.
