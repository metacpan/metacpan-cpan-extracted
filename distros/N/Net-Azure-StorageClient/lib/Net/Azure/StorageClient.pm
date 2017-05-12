package Net::Azure::StorageClient;
use strict;
use warnings;
{
  $Net::Azure::StorageClient::VERSION = '0.5';
}
use LWP::UserAgent;
use HTTP::Date;
use URI::QueryParam;
use MIME::Base64;
use Digest::SHA qw( hmac_sha256_base64 );

sub new {
    my $class = shift;
    my %args  = @_;
    my $type = $args{ type };
    if ( $type && $type =~ /^Blob$/i ) { # |Table|Queue
        $type = ucfirst( $type );
        $class .= "::" . $type;
        eval "use $class;";
        # die "Unsupported StorageClient $class: $@" if $@;
    }
    my $obj = bless {}, $class;
    $obj->{ type } = lc( $type ) if $type;
    $obj->init( @_ );
}

sub init {
    my $storageClient = shift;
    my %args = @_;
    $storageClient->{ account_name } = $args{ account_name };
    $storageClient->{ primary_access_key } = $args{ primary_access_key };
    $storageClient->{ api_version } = $args{ api_version } || '2012-02-12';
    $storageClient->{ protocol } = $args{ protocol } || 'https';
    return $storageClient;
}

sub sign {
    my $storageClient = shift;
    my ( $req, $params ) = @_;
    my $key = $storageClient->{ primary_access_key };
    my $api_version = $storageClient->{ api_version };
    $req->header( 'x-ms-version', $api_version );
    $req->header( 'x-ms-date', HTTP::Date::time2str() );
    if ( my $data = $params->{ body } ) {
        require Digest::MD5;
        $req->header( 'Content-MD5', Digest::MD5::md5_base64( $data ) . '==' );
        # $req->header( 'If-None-Match', '*' );
    }
    if ( $params && ( my $headers = $params->{ headers } ) ) {
        for my $key ( keys %$headers ) {
            $req->header( $key, $headers->{ $key } );
        }
    }
    my $canonicalized_headers = join '', map { lc( $_ ) . ':' .
       $req->header( $_ ) . "\n" } sort grep { /^x-ms/ } keys %{ $req->headers };
    my $account = $req->uri->authority;
    $account =~ s/^([^.]*).*$/$1/;
    my $path = $req->uri->path;
    my $canonicalized_resource = "/${account}${path}";
    $canonicalized_resource .= join '', map { "\n" . lc( $_ ) . ':' .
        join( ',', sort $req->uri->query_param( $_ ) ) }
            sort $req->uri->query_param;
    my $method = $req->method;
    my $encoding = $req->header( 'Content-Encoding' ) || '';
    my $language = $req->header( 'Content-Language' ) || '';
    my $length = $req->header( 'Content-Length' );
    if (! defined $length ) {
        $length = '';
    }
    my $md5 = $req->header( 'Content-MD5' ) || '';
    my $content_type = $req->header( 'Content-Type' ) || '';
    my $date = $req->header( 'Date' ) || '';
    my $if_mod_since = $req->header( 'If-Modified-Since' ) || '';
    my $if_match = $req->header( 'If-Match' ) || '';
    my $if_none_match = $req->header( 'If-None-Match' ) || '';
    my $if_unmod_since = $req->header( 'If-Unmodified-Since' ) || '';
    my $range = $req->header( 'Range' ) || '';
    my @headers = ( $method, $encoding, $language, $length, $md5, $content_type, $date,
                    $if_mod_since, $if_match, $if_none_match, $if_unmod_since, $range );
    push ( @headers, "${canonicalized_headers}${canonicalized_resource}" );
    my $string_to_sign = join( "\n", @headers );
    # print $string_to_sign;
    my $signature = hmac_sha256_base64( $string_to_sign, decode_base64( $key ) );
    $signature .= '=' x ( 4 - ( length( $signature ) % 4 ) );
    $req->authorization( "SharedKey ${account}:${signature}" );
    return $req;
}

sub request {
    my $storageClient = shift;
    my ( $method, $url, $params ) = @_;
    $url = '' unless ( $url );
    if ( $url !~ m!^https{0,1}://! ) {
        if ( $url !~ m !^/! ) {
            $url = '/' . $url;
        }
        my $type = $storageClient->{ type };
        my $account = $storageClient->{ account_name };
        my $protocol = $storageClient->{ protocol };
        $url = "${protocol}://${account}.${type}.core.windows.net${url}";
    }
    my $body;
    if ( defined( $params->{ body } ) ) {
        $body = $params->{ body };
    }
    $method = 'GET' unless $method;
    my $req = new HTTP::Request( $method => $url );
    $req->content_length( length( $body ) ) if defined $body;
    $req = $storageClient->sign( $req, $params );
    $req->content( $body ) if defined $body;
    my $ua = LWP::UserAgent->new;
    return $ua->request( $req );
}

sub get {
    my $storageClient = shift;
    $storageClient->request( 'GET', @_ );
}

sub head {
    my $storageClient = shift;
    $storageClient->request( 'HEAD', @_ );
}

sub put {
    my $storageClient = shift;
    $storageClient->request( 'PUT', @_ );
}

sub delete {
    my $storageClient = shift;
    $storageClient->request( 'DELETE', @_ );
}

sub post {
    my $storageClient = shift;
    $storageClient->request( 'POST', @_ );
}

sub _signed_identifier {
    my $storageClient = shift;
    my $length = shift;
    my @char = () ;
    push @char, ( 'a' .. 'z' );
    push @char, ( 'A' .. 'Z' );
    push @char, ( 0 .. 9 );
    my $res = '';
    for ( my $i=1; $i <= $length; $i++ ) {
        $res .= $char[ int( rand( $#char + 1 ) ) ];
    }
    return $res;
}

sub _adjust_path {
    my $storageClient = shift;
    my $path = shift;
    $path =~ s!^/!!;
    if ( my $type = $storageClient->{ type } ) {
        my $arg;
        if ( $type eq 'blob' ) {
            $arg = 'container_name'
        }
        # table, queue...
        if ( $arg && ( my $root = $storageClient->{ $arg } ) ) {
            $path = $root . '/' . $path;
        }
    }
    return $path;
}

1;

__END__

=head1 NAME

Net::Azure::StorageClient - Windows Azure Storage Client

=head1 SYNOPSIS

  my $StorageClient = Net::Azure::StorageClient->new(
                                    type => 'Blob',
                                    account_name => $you_account_name,
                                    primary_access_key => $your_primary_access_key,
                                    [ protocol => 'https', ]
                                    [ api_version => '2012-02-12', ] );

=head1 METHODS

=head2 sign

Specifying the authorization header to HTTP::Request object.
http://msdn.microsoft.com/en-us/library/dd179428.aspx

    my $req = new HTTP::Request( 'GET', $url );
    $req = $StorageClient->sign( $req, $params );

=head2 request

Specifying the authorization header and send request.

    # Specifying $url or $path, Send GET request.

    my $api = '/path/to/api?foo=bar';
    my $type = $blobService->{ type }; # 'blob'
    my $account = $blobService->{ account_name };
    my $protocol = $blobService->{ protocol };
    my $url = "${protocol}://${account}.${type}.core.windows.net/${api}";
    my $res = $StorageClient->request( 'GET', $url );

    # Request with custom http headers and request body. Send POST request.
    my $params = { 
                   headers => { 'x-ms-foo' => 'bar', },
                   body => $request_body,
                 };
    my $res = $StorageClient->request( 'PUT', $url, $params );

    # return HTTP::Response object.

=head2 get

Specifying the authorization header and send 'GET' request.

=head2 put

Specifying the authorization header and send 'PUT' request.

=head2 head

Specifying the authorization header and send 'HEAD' request.

=head2 delete

Specifying the authorization header and send 'DELETE' request.

=head2 post

Specifying the authorization header and send 'POST' request.

=head1 AUTHOR

Junnama Noda <junnama@alfasado.jp>

=head1 COPYRIGHT

Copyright (C) 2013, Junnama Noda.

=head1 LICENSE

This program is free software;
you can redistribute it and modify it under the same terms as Perl itself.

=cut