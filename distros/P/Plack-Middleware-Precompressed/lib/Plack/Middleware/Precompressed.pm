use 5.006;
use strict;
use warnings;

package Plack::Middleware::Precompressed;
$Plack::Middleware::Precompressed::VERSION = '1.103';
# ABSTRACT: serve pre-gzipped content to compression-enabled clients

use parent 'Plack::Middleware';

use Plack::Util::Accessor qw( match rules env_keys );
use Plack::MIME ();
use Plack::Util ();
use Array::RefElem ();

sub rewrite {
	my $self = shift;
	my ( $env ) = @_;
	my $rules = $self->rules;
	$rules ? $rules->( defined $env ? $env : () ) : ( $_ .= '.gz' );
}

sub call {
	my $self = shift;
	my ( $env ) = @_;

	my $encoding;
	my $path = $env->{'PATH_INFO'};
	my $have_match = $self->match ? $path =~ $self->match : 1;

	# the `deflate` encoding is unreliably messy so we won't support it
	# c.f. http://zoompf.com/2012/02/lose-the-wait-http-compression
	if ( $have_match ) {
		( $encoding ) =
			grep { $_ eq 'gzip' or $_ eq 'x-gzip' }
			map  { s!\s+!!g; split /,/, lc }
			grep { defined }
			$env->{'HTTP_ACCEPT_ENCODING'};
	}

	my $res = do {
		my $keys = $self->env_keys || [];
		local @$env{ 'PATH_INFO', @$keys } = ( $path, @$env{ @$keys } ) if $encoding;
		if ( $encoding ) {
			my %pass_env;
			Array::RefElem::hv_store %pass_env, $_, $env->{ $_ } for @$keys;
			$self->rewrite( \%pass_env ) for $env->{'PATH_INFO'};
		}
		delete local $env->{'HTTP_ACCEPT_ENCODING'} if $encoding;
		$self->app->( $env );
	};

	return $res unless $have_match;

	my $is_fail;
	my $final_res = Plack::Util::response_cb( $res, sub {
		my $res = shift;
		$is_fail = $res->[0] != 200;
		return if $is_fail;
		Plack::Util::header_push( $res->[1], 'Vary', 'Accept-Encoding' );
		if ( $encoding ) {
			my $mime = Plack::MIME->mime_type( $path );
			Plack::Util::header_set( $res->[1], 'Content-Type', $mime ) if $mime;
			Plack::Util::header_push( $res->[1], 'Content-Encoding', $encoding );
		}
		return;
	} );

	return $is_fail ? $self->app->( $env ) : $final_res;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Precompressed - serve pre-gzipped content to compression-enabled clients

=head1 VERSION

version 1.103

=head1 SYNOPSIS

 use Plack::Builder;

 builder {
     enable 'Precompressed', match => qr!\.js\z!;
     $handler;
 };

=head1 DESCRIPTION

Plack::Middleware::Precompressed is an alternative (or rather, complement) to
middlewares like L<Deflater|Plack::Middleware::Deflater>, which will compress
response bodies on the fly. For dynamic resources, that behaviour is necessary,
but for static resources it is a waste: identical entities will be compressed
over and over. Instead, I<Precompressed> allows you to compress static
resources once, e.g. as part of your build process, and then serve the
compressed resource in place of the uncompressed one for compression-enabled
clients.

To do so, by default it appends a C<.gz> suffix to the C<PATH_INFO> and tries
to serve that. If that fails, it will then try again with the unmodified URI.

B<Note>: this means requests for resources that are not pre-compressed will
always be dispatched I<twice>. You are are advised to use either the C<match>
parameter or L<the Conditional middleware|Plack::Middleware::Conditional> or
something of the sort, to prevent requests from passing through this middleware
unnecessarily.

=head1 CONFIGURATION OPTIONS

=over 4

=item C<match>

Specifies a regex that must match the C<PATH_INFO> to trigger the middleware.

=item C<rules>

A callback that is expected to transform the path instead of using the default
behaviour of appending C<.gz> to the file path. C<PATH_INFO> will be aliased to
the C<$_> variable, so you can do something like this:

 enable 'Precompressed', match => qr!\.js\z!, rules => sub { s!^/?!/z/! };

This example will prepend C</z/> to file paths instead of appending C<.gz> to
them.

=item C<env_keys>

An array of PSGI environment key names. If you specify any, then the C<rules>
callback will receive a reference to a hash with just these keys, aliased to
the values in the PSGI environment that will be passed to the wrapped app. You
can modify these values to modify the environment it will see. This allows you
do to something like this:

 enable 'Precompressed', env_keys => [ 'HTTP_HOST' ],
	rules => sub { $_[0]{'HTTP_HOST'} = 'gzip.assets.example.com' };

This somewhat peculiar interface is necessary so the middleware can abstract
away the details of trying to copy as little data as possible during a request.

=back

=head1 SUBCLASSING

If you reuse a particular configuration of Plack::Middleware::Precompressed in
many projects, you can avoid repeating the same configuration in each of them
by subclassing this middleware and overriding the C<rewrite> and C<env_keys>
methods.

The C<rewrite> method will be called just as the C<rules> callback would be.

The C<env_keys> method should return an array reference and will have the same
effect on the C<rewrite> method as the configuration option on the C<rules>
callback.

=head1 SEE ALSO

L<Plack::Middleware::Deflater>

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
