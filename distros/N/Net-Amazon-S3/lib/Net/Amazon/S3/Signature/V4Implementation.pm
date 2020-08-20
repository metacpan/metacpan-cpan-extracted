package Net::Amazon::S3::Signature::V4Implementation;
# ABSTRACT: Implements the Amazon Web Services signature version 4, AWS4-HMAC-SHA256 (copy of Net::Amazon::Signature::V4)
$Net::Amazon::S3::Signature::V4Implementation::VERSION = '0.91';

use strict;
use warnings;
use sort 'stable';

use Digest::SHA qw/sha256_hex hmac_sha256 hmac_sha256_hex/;
use Time::Piece ();
use URI::Escape;
use URI;
use URI::QueryParam;

our $ALGORITHM = 'AWS4-HMAC-SHA256';
our $MAX_EXPIRES = 604800; # Max, 7 days

our $X_AMZ_ALGORITHM      = 'X-Amz-Algorithm';
our $X_AMZ_CONTENT_SHA256 = 'X-Amz-Content-Sha256';
our $X_AMZ_CREDENTIAL     = 'X-Amz-Credential';
our $X_AMZ_DATE           = 'X-Amz-Date';
our $X_AMZ_EXPIRES        = 'X-Amz-Expires';
our $X_AMZ_SIGNEDHEADERS  = 'X-Amz-SignedHeaders';
our $X_AMZ_SIGNATURE      = 'X-Amz-Signature';



sub new {
	my $class = shift;
	my ( $access_key_id, $secret, $endpoint, $service ) = @_;
	my $self = {
		access_key_id => $access_key_id,
		secret        => $secret,
		endpoint      => $endpoint,
		service       => $service,
	};
	bless $self, $class;
	return $self;
}


sub sign {
	my ( $self, $request ) = @_;

	$request = $self->_augment_request( $request );

	my $authz = $self->_authorization( $request );
	$request->header( Authorization => $authz );
	return $request;
}


sub sign_uri {
	my ( $self, $uri, $expires_in ) = @_;

	my $request = $self->_augment_uri( $uri, $expires_in );

	my $signature = $self->_signature( $request );

	$uri = $request->uri;
	my $query = $uri->query;
	$uri->query( undef );
	$uri = $uri . '?' . $self->_sort_query_string( $query );
	$uri .= "&$X_AMZ_SIGNATURE=$signature";

	return $uri;
}

# _headers_to_sign:
# Return the sorted lower case headers as required by the generation of canonical headers

sub _headers_to_sign {
	my $req = shift;

	my @headers_to_sign = $req->uri->query_param( $X_AMZ_SIGNEDHEADERS )
		? $req->uri->query_param( $X_AMZ_SIGNEDHEADERS )
		: $req->headers->header_field_names
		;

	return sort { $a cmp $b } map { lc } @headers_to_sign
}

# _augment_request:
# Append mandatory header fields

sub _augment_request {
	my ( $self, $request ) = @_;

	$request->header($X_AMZ_DATE => $self->_format_amz_date( $self->_req_timepiece($request) ))
		unless $request->header($X_AMZ_DATE);

	$request->header($X_AMZ_CONTENT_SHA256 => sha256_hex($request->content))
		unless $request->header($X_AMZ_CONTENT_SHA256);

	return $request;
}

# _augment_uri:
# Append mandatory uri parameters

sub _augment_uri {
	my ($self, $uri, $expires_in) = @_;

	my $request = HTTP::Request->new( GET => $uri );

	$request->uri->query_param( $X_AMZ_DATE => $self->_format_amz_date( $self->_now ) )
		unless $request->uri->query_param( $X_AMZ_DATE );

	$request->uri->query_param( $X_AMZ_ALGORITHM => $ALGORITHM )
		unless $request->uri->query_param( $X_AMZ_ALGORITHM );

	$request->uri->query_param( $X_AMZ_CREDENTIAL => $self->_credential( $request ) )
		unless $request->uri->query_param( $X_AMZ_CREDENTIAL );

	$request->uri->query_param( $X_AMZ_EXPIRES => $expires_in || $MAX_EXPIRES )
		unless $request->uri->query_param( $X_AMZ_EXPIRES );
	$request->uri->query_param( $X_AMZ_EXPIRES => $MAX_EXPIRES )
		if $request->uri->query_param( $X_AMZ_EXPIRES ) > $MAX_EXPIRES;

	$request->uri->query_param( $X_AMZ_SIGNEDHEADERS => 'host' );

	return $request;
}

# _canonical_request:
# Construct the canonical request string from an HTTP::Request.

sub _canonical_request {
	my ( $self, $req ) = @_;

	my $creq_method = $req->method;

	my ( $creq_canonical_uri, $creq_canonical_query_string ) = 
		( $req->uri =~ m@([^?]*)\?(.*)$@ )
		? ( $1, $2 )
		: ( $req->uri, '' );
	$creq_canonical_uri =~ s@^https?://[^/]*/?@/@;
	$creq_canonical_uri = _simplify_uri( $creq_canonical_uri );
	$creq_canonical_query_string = $self->_sort_query_string( $creq_canonical_query_string );

	# Ensure Host header is present as its required
	if (!$req->header('host')) {
		$req->header('Host' => $req->uri->host);
	}
	my $creq_payload_hash = $req->header($X_AMZ_CONTENT_SHA256)
		# Signed uri doesn't have content
		|| 'UNSIGNED-PAYLOAD';

	# There's a bug in AMS4 which causes requests without x-amz-date set to be rejected
	# so we always add one if its not present.
	my $amz_date = $req->header($X_AMZ_DATE);
	my @sorted_headers = _headers_to_sign( $req );
	my $creq_canonical_headers = join '',
		map {
			sprintf "%s:%s\x0a",
				lc,
				join ',', sort {$a cmp $b } _trim_whitespace($req->header($_) )
		}
		@sorted_headers;
	my $creq_signed_headers = $self->_signed_headers( $req );
	my $creq = join "\x0a",
		$creq_method, $creq_canonical_uri, $creq_canonical_query_string,
		$creq_canonical_headers, $creq_signed_headers, $creq_payload_hash;

	return $creq;
}

# _string_to_sign
# Construct the string to sign.

sub _string_to_sign {
	my ( $self, $req ) = @_;
	my $dt = $self->_req_timepiece( $req );
	my $creq = $self->_canonical_request($req);
	my $sts_request_date = $self->_format_amz_date( $dt );
	my $sts_credential_scope = join '/', $dt->strftime('%Y%m%d'), $self->{endpoint}, $self->{service}, 'aws4_request';
	my $sts_creq_hash = sha256_hex( $creq );

	my $sts = join "\x0a", $ALGORITHM, $sts_request_date, $sts_credential_scope, $sts_creq_hash;
	return $sts;
}

# _authorization
# Construct the authorization string

sub _signature {
	my ( $self, $req ) = @_;

	my $dt = $self->_req_timepiece( $req );
	my $sts = $self->_string_to_sign( $req );
	my $k_date    = hmac_sha256( $dt->strftime('%Y%m%d'), 'AWS4' . $self->{secret} );
	my $k_region  = hmac_sha256( $self->{endpoint},        $k_date    );
	my $k_service = hmac_sha256( $self->{service},         $k_region  );
	my $k_signing = hmac_sha256( 'aws4_request',           $k_service );

	my $authz_signature = hmac_sha256_hex( $sts, $k_signing );
	return $authz_signature;
}

sub _credential {
	my ( $self, $req ) = @_;

	my $dt = $self->_req_timepiece( $req );

	my $authz_credential = join '/', $self->{access_key_id}, $dt->strftime('%Y%m%d'), $self->{endpoint}, $self->{service}, 'aws4_request';
	return $authz_credential;
}

sub _signed_headers {
	my ( $self, $req ) = @_;

	my $authz_signed_headers = join ';', _headers_to_sign( $req );
	return $authz_signed_headers;
}

sub _authorization {
	my ( $self, $req ) = @_;

	my $authz_signature = $self->_signature( $req );
	my $authz_credential = $self->_credential( $req );
	my $authz_signed_headers = $self->_signed_headers( $req );

	my $authz = "$ALGORITHM Credential=$authz_credential,SignedHeaders=$authz_signed_headers,Signature=$authz_signature";
	return $authz;

}

sub _simplify_uri {
	my $orig_uri = shift;
	my @parts = split /\//, $orig_uri;
	my @simple_parts = ();
	for my $part ( @parts ) {
		if ( ! length $part || $part eq '.' ) {
		} elsif ( $part eq '..' ) {
			pop @simple_parts;
		} else {
			push @simple_parts, $part;
		}
	}
	my $simple_uri = '/' . join '/', @simple_parts;
	$simple_uri .= '/' if $orig_uri =~ m@/$@ && $simple_uri !~ m@/$@;
	return $simple_uri;
}
sub _sort_query_string {
	my $self = shift;
	return '' unless $_[0];
	my @params;
	for my $param ( split /&/, $_[0] ) {
		my ( $key, $value ) = 
			map { tr/+/ /; uri_escape( uri_unescape( $_ ) ) } # escape all non-unreserved chars
			split /=/, $param;
		push @params, [$key, (defined $value ? $value : '')];
		#push @params, [$key, $value];
	}
	return join '&',
		map { join '=', grep defined, @$_ }
		sort { ( $a->[0] cmp $b->[0] ) || ( $a->[1] cmp $b->[1] ) }
		@params;
}
sub _trim_whitespace {
	return map { my $str = $_; $str =~ s/^\s*//; $str =~ s/\s*$//; $str } @_;
}
sub _str_to_timepiece {
	my $date = shift;
	if ( $date =~ m/^\d{8}T\d{6}Z$/ ) {
		# assume basic ISO 8601, as demanded by AWS
		return Time::Piece->strptime($date, '%Y%m%dT%H%M%SZ');
	} else {
		# assume the format given in the AWS4 test suite
		$date =~ s/^.{5}//; # remove weekday, as Amazon's test suite contains internally inconsistent dates
		return Time::Piece->strptime($date, '%d %b %Y %H:%M:%S %Z');
	}
}

sub _format_amz_date {
	my ($self, $dt) = @_;

	$dt->strftime('%Y%m%dT%H%M%SZ');
}

sub _now {
	return scalar Time::Piece->gmtime;
}

sub _req_timepiece {
	my ($self, $req) = @_;
	my $x_date = $req->header($X_AMZ_DATE) || $req->uri->query_param($X_AMZ_DATE);
	my $date = $x_date || $req->header('Date');
	if (!$date) {
		# No date set by the caller so set one up
		my $piece = $self->_now;
		$req->date($piece->epoch);
		return $piece
	}
	return _str_to_timepiece($date);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Signature::V4Implementation - Implements the Amazon Web Services signature version 4, AWS4-HMAC-SHA256 (copy of Net::Amazon::Signature::V4)

=head1 VERSION

version 0.91

=head1 DESCRIPTION

This package clones L<Net::Amazon::Signature::V4> 0.19 adding support for
signing URIs (GET request)

Until https://github.com/Grinnz/Net-Amazon-Signature-V4/pull/5 will be merged
we have to maintain our clone.

=head1 Net::Amazon::Signature::S4 AUTHORS

Tim Nordenfur, C<< <tim at gurka.se> >>

Maintained by Dan Book, C<< <dbook at cpan.org> >>

=head2 sign( $request )

Signs a request with your credentials by appending the Authorization header. $request should be an HTTP::Request. The signed request is returned.

=head2 sign_uri( $uri, $expires_in? )

Signs an uri with your credentials by appending the Authorization query parameters.

C<< $expires_in >> integer value in range 1..604800 (1 second .. 7 days).

C<< $expires_in >> default value is its maximum: 604800

The signed uri is returned.

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
