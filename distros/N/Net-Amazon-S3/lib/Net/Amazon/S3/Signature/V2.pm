package Net::Amazon::S3::Signature::V2;
# ABSTRACT: V2 signatures
$Net::Amazon::S3::Signature::V2::VERSION = '0.98';
use Moose;
use URI::Escape qw( uri_escape_utf8 );
use HTTP::Date qw[ time2str ];
use MIME::Base64 qw( encode_base64 );
use URI::QueryParam;
use URI;

use Net::Amazon::S3::Constants;

use namespace::clean;

extends 'Net::Amazon::S3::Signature';

my $AMAZON_HEADER_PREFIX = 'x-amz-';

sub enforce_use_virtual_host {
    0;
}

sub sign_request {
    my ($self, $request) = @_;

    $self->_add_auth_header( $request );
}

sub sign_uri {
    my ($self, $request, $expires) = @_;

    my $aws_access_key_id = $self->http_request->s3->aws_access_key_id;

    my $canonical_string = $self->_canonical_string( $request, $expires );
    my $encoded_canonical = $self->_encode( $canonical_string );

    my $uri = URI->new( $request->uri );

    $uri->query_param( AWSAccessKeyId => $aws_access_key_id );
    $uri->query_param( Expires        => $expires );
    $uri->query_param( Signature      => $encoded_canonical );

    $uri->as_string;
}

sub _add_auth_header {
    my ( $self, $request ) = @_;

    my $aws_access_key_id     = $self->http_request->s3->aws_access_key_id;
    my $aws_secret_access_key = $self->http_request->s3->aws_secret_access_key;

    if ( not $request->headers->header('Date') ) {
        $request->header( Date => time2str(time) );
    }

	$self->_append_authorization_headers ($request);

    my $canonical_string = $self->_canonical_string( $request );
    my $encoded_canonical = $self->_encode( $canonical_string );
    $request->header( Authorization => "AWS $aws_access_key_id:$encoded_canonical" );
}

sub _canonical_string {
    my ( $self, $request, $expires ) = @_;
    my $method = $request->method;
    my $path = $self->http_request->path;

    my %interesting_headers = ();
    for my $key ($request->headers->header_field_names) {
        my $lk = lc $key;
        if (   $lk eq 'content-md5'
            or $lk eq 'content-type'
            or $lk eq 'date'
            or $lk =~ /^$AMAZON_HEADER_PREFIX/ )
        {
            $interesting_headers{$lk} = $self->_trim( $request->header( $lk ) );
        }
    }

    # these keys get empty strings if they don't exist
    $interesting_headers{'content-type'} ||= '';
    $interesting_headers{'content-md5'}  ||= '';

    # just in case someone used this.  it's not necessary in this lib.
    $interesting_headers{'date'} = ''
        if $interesting_headers{Net::Amazon::S3::Constants->HEADER_DATE};

    # if you're using expires for query string auth, then it trumps date
    # (and x-amz-date)
    $interesting_headers{'date'} = $expires if $expires;

    my $buf = "$method\n";
    foreach my $key ( sort keys %interesting_headers ) {
        if ( $key =~ /^$AMAZON_HEADER_PREFIX/ ) {
            $buf .= "$key:$interesting_headers{$key}\n";
        } else {
            $buf .= "$interesting_headers{$key}\n";
        }
    }

    # don't include anything after the first ? in the resource...
    $path =~ /^([^?]*)/;
    $buf .= "/$1";

    # ...unless there any parameters we're interested in...
    if ( $path =~ /[&?](acl|torrent|location|uploads|delete)($|=|&)/ ) {
        $buf .= "?$1";
    } elsif ( my %query_params = URI->new($path)->query_form ){
        #see if the remaining parsed query string provides us with any query string or upload id
        if($query_params{partNumber} && $query_params{uploadId}){
            #re-evaluate query string, the order of the params is important for request signing, so we can't depend on URI to do the right thing
            $buf .= sprintf("?partNumber=%s&uploadId=%s", $query_params{partNumber}, $query_params{uploadId});
        }
        elsif($query_params{uploadId}){
            $buf .= sprintf("?uploadId=%s",$query_params{uploadId});
        }
    }

    return $buf;
}

# finds the hmac-sha1 hash of the canonical string and the aws secret access key and then
# base64 encodes the result (optionally urlencoding after that).
sub _encode {
    my ( $self, $str, $urlencode ) = @_;
    my $hmac = Digest::HMAC_SHA1->new($self->http_request->s3->aws_secret_access_key);
    $hmac->add($str);
    my $b64 = encode_base64( $hmac->digest, '' );
    if ($urlencode) {
        return $self->_urlencode($b64);
    } else {
        return $b64;
    }
}

sub _urlencode {
    my ( $self, $unencoded ) = @_;
    return uri_escape_utf8( $unencoded, '^A-Za-z0-9_-' );
}

sub _trim {
    my ( $self, $value ) = @_;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Signature::V2 - V2 signatures

=head1 VERSION

version 0.98

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
