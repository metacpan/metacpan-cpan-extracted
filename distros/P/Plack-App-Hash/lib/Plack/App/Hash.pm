#!/usr/bin/perl
use 5.006;
use strict;
use warnings;

package Plack::App::Hash;
$Plack::App::Hash::VERSION = '1.000';
# ABSTRACT: Serve up the contents of a hash as a website

use parent 'Plack::Component';

use Plack::Util ();
use Array::RefElem ();
use HTTP::Status ();
#use Digest::SHA;

use Plack::Util::Accessor qw( content headers auto_type default_type );

sub call {
	my $self = shift;
	my $env  = shift;

	my $path = $env->{'PATH_INFO'} || '';
	$path =~ s!\A/!!;

	my $content = $self->content;
	return $self->error( 404 ) unless $content and exists $content->{ $path };
	return $self->error( 500 ) if ref $content->{ $path };

	my $headers = ( $self->headers || $self->headers( {} ) )->{ $path };

	if ( not defined $headers ) {
		$headers = [];
	}
	elsif ( not ref $headers ) {
		require JSON::MaybeXS;
		$headers = JSON::MaybeXS::decode_json $headers;
	}

	return $self->error( 500 ) if 'ARRAY' ne ref $headers;

	{
		my $auto    = $self->auto_type;
		my $default = $self->default_type;
		last unless $auto or $default;
		last if Plack::Util::header_exists $headers, 'Content-Type';
		$auto &&= do { require Plack::MIME; Plack::MIME->mime_type( $path ) };
		Plack::Util::header_push $headers, 'Content-Type' => $_ for $auto || $default || ();
	}

	if ( not Plack::Util::header_exists $headers, 'Content-Length' ) {
		Plack::Util::header_push $headers, 'Content-Length' => length $content->{ $path };
	}

	my @body;
	Array::RefElem::av_push @body, $content->{ $path };
	return [ 200, $headers, \@body ];
}

sub error {
	my $status = pop;
	my $pkg = __PACKAGE__;
	my $body = [ qq(<!DOCTYPE html>\n<title>$pkg $status</title><h1><font face=sans-serif>) . HTTP::Status::status_message $status ];
	return [ $status, [
		'Content-Type'   => 'text/html',
		'Content-Length' => length $body->[0],
	], $body ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::Hash - Serve up the contents of a hash as a website

=head1 VERSION

version 1.000

=head1 SYNOPSIS

 use Plack::App::Hash;
 my $app = Plack::App::Hash->new(
     content      => { '' => 'Hello World!' },
     default_type => 'text/plain',
 )->to_app;

=head1 DESCRIPTION

This PSGI application responds to HTTP requests by looking up the request path
in a hash and returning the value of that key (if found) as the response body.

This is useful for cases like inlining the content of a boilerplate static site
into a single-page-application-in-a-module, or serving up a tied DBM hash that
other programs can update while the web app itself contains very little logic
E<ndash> in short, for one-off hacks and scaling down.

=head1 CONFIGURATION

=over 4

=item C<content>

The content of your site. Each key-value pair will be one resource in your URI
space. The key is its URI path without leading slash, and the is the content of
the resource. Values must not be references.

=item C<headers> (optional)

The headers of your resources. As in C<content>, each key is a URI path without
leading slash. The value of a key may be either an array reference or a string
containing a JSON encoding of an array. In either case it is taken to mean the
L<PSGI> header array for the resource.

=item C<auto_type> (optional)

If true, a C<Content-Type> header value will be computed automatically for any
responses which do not already have one by way of the C<headers> hash.

=item C<default_type> (optional)

The C<Content-Type> value to use for any responses which would not otherwise
have one, whether by matching C<headers> or by C<auto_type> fallback.

=back

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
