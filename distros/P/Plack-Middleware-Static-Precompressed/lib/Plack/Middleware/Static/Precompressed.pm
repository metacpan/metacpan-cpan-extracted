use 5.008001; use strict; use warnings;

package Plack::Middleware::Static::Precompressed;
our $VERSION = '1.002';
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(
	ext_map
	default_charset
	max_file_size
	max_total_size
	max_open_files
	files
	root
	path_info
	handle_cb
	fh_error_cb
	response_cb
);

use Plack::Middleware::NeverExpire 1.201 ();
use Plack::Util ();
use Cache::LRU ();

sub new {
	my $self = shift->SUPER::new( @_ );

	$self->ext_map( { gz => 'gzip', br => 'br' } ) unless defined $self->ext_map;
	$self->default_charset( 'utf-8' )              unless defined $self->default_charset;
	$self->max_file_size( 8192 )                   unless defined $self->max_file_size;
	$self->max_total_size( 8192 * 1024 )           unless defined $self->max_total_size;
	$self->max_open_files( 128 )                   unless defined $self->max_open_files;
	$self->handle_cb( \&_default_handle_cb )       unless $self->handle_cb;
	$self->fh_error_cb( \&_default_fh_error_cb )   unless $self->fh_error_cb;

	if ( my $root = $self->root ) {
		require File::Find;
		File::Find::find( {
			wanted => sub { -f and $self->add_file( $_, ( stat _ )[ 7, 9 ] ) },
			no_chdir => 1
		}, $root );
	}

	if ( my $files = $self->files ) {
		$self->files( undef );
		for my $path ( @$files ) {
			$self->add_file( $path, ( stat $path )[ 7, 9 ] );
		}
	}

	$self;
}

sub prepare_app {
	my $self = shift;
	return if $self->{'fh_cache'}; # already prepared

	$self->app( sub { [ 404, [qw( Content-Type text/plain )], [ 'Not found' ] ] } ) unless $self->app;

	my $resources = \%{ $self->{'resources'} };
	my @bad = map "\n  $_", sort grep !exists $resources->{ $_ }{'size'}, keys %$resources;
	die __PACKAGE__ . ': cannot handle resources without identity encoding:', @bad, "\n" if @bad;

	$self->{'fh_cache'} = Cache::LRU->new( size => $self->max_open_files );
	my $total = 0;
	for my $representation (
		sort { $a->{'size'} <=> $b->{'size'} }
		map +( $_, $_->{'enc'} ? values %{ $_->{'enc'} } : () ),
		values %$resources
	) {
		my $size = $representation->{'size'};
		last if $size > $self->max_file_size;
		last if $total + $size > $self->max_total_size;
		$total += $size;
		my $path = $representation->{'path'};
		my $fh = $self->handle_cb->( $path ) or _default_fh_error_cb( $path );
		my $body_ref = _slurp_psgi_handle( $fh );
		( my $len = length $$body_ref ) += 0;
		$size == $len or die __PACKAGE__ . ": mismatch between content length ($len) and the size passed to add_file ($size) for $path\n";
		$representation->{'fh'} = _default_handle_cb( $body_ref );
	}

	for my $representation ( values %$resources ) {
		my $encodings = $representation->{'enc'} or next;
		$encodings->{'x-gzip'} = $_ for $encodings->{'gzip'} || (); # RFC 9110 section 8.4.1.3
		$representation->{'avail_rx'} = join '|', map quotemeta, keys %$encodings;
	}
}

sub get_content_encoding_from_extension {
	my $self = shift;
	my $ext_map = $self->ext_map or return;
	my $ext_rx = ( $ext_map eq ( $self->{'cached_ext_map'} || '' ) ) ? $self->{'cached_ext_rx'} : do {
		$self->{'cached_ext_map'} = "$ext_map";
		$self->{'cached_ext_rx'} = join '|', map quotemeta, sort keys %$ext_map;
	};
	$_[0] =~ s/\.($ext_rx)\z// ? $ext_map->{ $1 } : ();
}

sub add_files { my $self = shift; $self->add_file( @$_ ) for @_; $self }

my %is_rx = map +( $_ => 1 ), '', ref qr//;
sub add_file {
	my ( $self, $path, $size, $mtime ) = ( shift, @_ );

	my $headers = [];
	$mtime and push @$headers, 'Last-Modified' => Plack::Middleware::NeverExpire::imf_fixdate( $mtime );

	my $get_path_info = $self->path_info;
	if ( $get_path_info and $is_rx{ ref $get_path_info } ) {
		my $rx = $get_path_info;
		$self->path_info( $get_path_info = sub { /$rx/s ? $1 : $_ } );
	}
	my ( $path_info, $enc ) = $get_path_info ? map $get_path_info->( $_, $headers ), my $copy = $path : $path;
	$path_info =~ s!\A(?:\.?/)?!/!;

	if ( defined $enc ) {
		$enc = 'gzip' if 'x-gzip' eq $enc; # RFC 9110 section 8.4.1.3 (see also further below)
		undef $enc if 'identity' eq $enc or '*' eq $enc;
	} else {
		$enc = $self->get_content_encoding_from_extension( $path_info );
	}

	my $identity = \%{ $self->{'resources'}{ $path_info } };
	my $representation = $enc ? \%{ $identity->{'enc'}{ $enc } } : $identity;
	$representation->{'path'} = $path;
	$representation->{'size'} = $size || 0;

	if ( exists $identity->{'size'} and my $encodings = $identity->{'enc'} ) {
		my @useless = grep $encodings->{ $_ }{'size'} >= $identity->{'size'}, keys %$encodings;
		@useless < keys %$encodings
			? delete @$encodings{ @useless }
			: delete $identity->{'enc'};
	}

	return $self if $enc;

	# we remove these here so we won't need to use Plack::Util::header_set at runtime
	Plack::Util::header_remove( $headers, 'Vary' );
	Plack::Util::header_remove( $headers, 'Content-Encoding' );
	Plack::Util::header_remove( $headers, 'Content-Length' );

	unless ( Plack::Util::header_exists( $headers, 'Content-Type' ) ) {
		require Plack::MIME;
		if ( my $type = Plack::MIME->mime_type( $path_info ) ) {
			my $default = $type =~ m!^text/! && $self->default_charset;
			$type .= ";charset=$default" if $default;
			push @$headers, 'Content-Type' => $type;
		}
	}

	$representation->{'hdrs'} = $headers;

	$self;
}

sub call {
	my ( $self, $env ) = ( shift, @_ );

	my $representation = $self->{'resources'}{ $env->{'PATH_INFO'} || '/' }
		or return $self->app->( $env );

	my ( $resource_headers, $headers ) = $representation->{'hdrs'};

	if ( my $encodings = $representation->{'enc'} ) {
		my $accepted = 'identity';
		if ( defined ( my $will_accept = $env->{'HTTP_ACCEPT_ENCODING'} ) ) {
			my $candidate;
			# we accept any q-value other than 0 but we ignore it
			# we just send the smallest acceptable representation
			for my $enc ( ( lc $will_accept ) =~ m[
				(?: \A | , )
				\s* ( $representation->{'avail_rx'} ) \s*
				(?: ; \s* q= (?:
					1(?:\.0{1,3})?
					|
					0\.(?:[1-9][0-9]{0,2}|0[1-9][0-9]?|00[1-9])
				) \s* )?
				(?: \z | (?=,) )
			]gx ) {
				( $representation, $accepted ) = ( $candidate, $enc )
					if $candidate = $encodings->{ $enc }
					and $candidate->{'size'} < $representation->{'size'};
			}
		}
		$headers = [
			Vary => 'Accept-Encoding',
			@$resource_headers,
			'Content-Encoding' => $accepted,
			'Content-Length' => $representation->{'size'},
		];
	} else {
		$headers = [ @$resource_headers, 'Content-Length' => $representation->{'size'} ];
	}

	my $fh = $representation->{'fh'} || $self->{'fh_cache'}->get( $representation->{'path'} ) || do {
		my $path = $representation->{'path'};
		$self->{'fh_cache'}->set( $path, $self->handle_cb->( $path ) || return $self->fh_error_cb->( $path ) );
	};

	my $res = [ 200, $headers, $fh ];
	$self->{'response_cb'} && $self->{'response_cb'}->( $res );
	$res;
}

sub _slurp_psgi_handle {
	my ( $fh ) = @_;
	local $/;
	my $body = '';
	while ( defined( my $line = $fh->getline ) ) { $body .= $line }
	$fh->close;
	\$body;
}

sub _default_fh_error_cb { die __PACKAGE__ . ": could not open $_[0]: $!\n" }

sub _default_handle_cb {
	open my $fh, '<:raw', $_[0] or return undef;
	( bless $fh, 'Plack::Util::IOWithPath::Reusable' )->path( $_[0] );
	$fh;
}

sub dump_map {
	my ( $self, $printer ) = ( shift, @_ );
	$self->prepare_app;
	my $resources = $self->{'resources'};
	if ( 'CODE' ne ref $printer ) {
		my $fh = $printer;
		$printer = sub { print $fh @_ };
	}
	$printer->( map {
		my $encodings = $resources->{ $_ }{'enc'};
		my @enc = $encodings ? sort keys %$encodings : ();
		"$_ ($resources->{ $_ }{'size'} bytes)\n",
		map { " - $_ ($encodings->{ $_ }{'size'} bytes)\n" } @enc;
	} sort keys %$resources );
	$self;
}

package Plack::Util::IOWithPath::Reusable;
use parent -norequire => 'Plack::Util::IOWithPath';
sub close { seek $_[0], 0, 0 } # subvert PSGI spec for our purposes

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Static::Precompressed - serve a tree of static pre-compressed files

=head1 SYNOPSIS

 use Plack::Builder;

 builder {
     enable 'Static::Precompressed',
		root => 'static',
		path_info => '^static/(.*)';
     $app;
 };

=head1 DESCRIPTION

This middleware does HTTP content negotiation based on content encoding,
given a set of files that never change. It is meant primarily as a complement
to middlewares such as L<Deflater|Plack::Middleware::Deflater> which compress
each response on the fly – as is necessary for generated responses, but
wasteful when it repeats the same work for the same unchanged files over and
over again.
This middleware lets you compress each static asset file just once,
e.g. as part of your build process, then at runtime just picks the smallest one
that the client can use.

If a URL is not matched, it is passed to the wrapped L<PSGI> application.
But you can also use this middleware as a standalone L<PSGI> application,
in which case it will return a 404 response for URLs it does not have.
If you would like to use it like this but dislike instantiating a middleware,
you can use the included dummy L<Plack::App::File::Precompressed> wrapper.

=head1 CONFIGURATION OPTIONS

=over 4

=item C<files>

An array of file paths to pass to L</C<add_file>>.

Size and modification time will be retrieved from L<C<stat>|perlfunc/stat>.

=item C<root>

The path of a directory to search for files to pass to L</C<add_file>>.

Only files which pass the L<C<-f>|perlfunc/-X> test will be used.

Size and modification time will be retrieved from L<C<stat>|perlfunc/stat>.

L<File::Find> will be loaded if you pass this option, but not otherwise.

=item C<path_info>

A pattern or a callback which will be used by L</C<add_file>> to get
the HTTP metadata for each file.

 path_info => '^static/(.*)',

If it is a pattern (string or L<C<qr>|perlfunc/qr> object), each file path will
be matched against the pattern, and if successful, the first capture (C<$1>)
will be used as the URI path for the file. The C</s> flag will be enabled on
the match (which only affects patterns passed as strings, not C<qr> objects).

 path_info => sub {
   my ( $path, $headers ) = @_;
   # ...
   return ( $uri_path, $content_encoding );
 },

If it is a callback, it will be called for each file and passed the file path
and a reference to a headers array. The callback may mutate the headers array
and/or return a list consisting of a URI path and a content encoding. Both
values may be undefined.

=item C<ext_map>

A hash that maps file extensions to content encodings,
used by L</C<add_file>>.

Defaults to C<< { gz => 'gzip', br => 'br' } >>.

=item C<default_charset>

Charset to use for files with a C<text/*> MIME type from L<Plack::MIME>,
used by L</C<add_file>>.

Defaults to C<utf-8>.

=item C<response_cb>

A L<C<Plack::Util::response_cb>|Plack::Util/response_cb> callback for the
reponse. You may want to use something like
L<C<inject_headers>|Plack::Middleware::NeverExpire/inject_headers> from
L<Plack::Middleware::NeverExpire> here.

=item C<max_file_size>

Maximum size in bytes of files to read into memory on startup.

Defaults to 8192 bytes.

You can set this to 0 to disable buffering or C<9**9**9> to disable the limit.

=item C<max_total_size>

Maximum amount of data in bytes to read into memory at startup.

Defaults to 8 megabytes.

Files will be prioritized by increasing size.

You can set this to 0 to disable buffering or C<9**9**9> to disable the limit.

=item C<max_open_files>

Maximum number of open filehandles to cache.

Defaults to 128.

This applies to files larger than L</C<max_file_size>>.

You can set this to 0 disable filehandle caching.

=item C<handle_cb>

A callback that is passed a file path and returns a handle.

Defaults to a wrapper around L<C<open>|perlfunc/open>.

The handle must be a L<PSGI>-compatible L<body filehandle|PSGI/Body>
(i.e. an object with C<getline> and C<close> methods), but with one additional
requirement: I<instead> of closing the file, C<close> B<must> do (the
equivalent of) S<C<seek $fh, 0, 0>>.

This option allows you to completely isolate this middleware from the real
filesystem, provided you also use neither the L</C<files>> nor L</C<root>>
options, and that all your calls to L</C<add_file>> or L</C<add_files>>
explicitly pass a size for all files.

=item C<fh_error_cb>

A callback that is called if an error is encountered while trying to open
a file at runtime.

Defaults to throwing an exception.

The callback is passed a file path and expected to return a L<PSGI> response
(if it does return).

=back

=head1 METHODS

=head2 C<add_file>

Takes a file path and size and optionally a modification time and
registers the file to be served at runtime:

 $app->add_file( $path, $size, $mtime );

This takes care of assigning a URI path to each file. Different versions of the
same file (e.g. F<styles.css> and F<styles.css.gz>) need to be assigned the
same URI path (e.g. C</styles.css>) but with different content encodings
(e.g. none and C<gzip>, respectively, in this case).

When some known URI path is requested, the middleware will respond with the
smallest file that the client supports.

The unencoded file for a URI path is by definition supported, and is given
priority over any other versions that are not smaller. This means that any
encoded file which is not smaller than its unencoded version will be ignored
entirely.

Each URI path must have a file without a content encoding.

The L</C<path_info>> configuration option, if set, is asked for the URI path
for the file. If it is a callback and does not return a true value as the URI
path, or if it is a pattern and it does not match the file path, then the file
path itself will be used as the URI path.

The URI path will addtionally be normalized to begin with a C</> regardless of
whether it starts with C</> or C<./> or neither.

If no L</C<path_info>> callback is given or the returned content encoding is
undefined then the URI path will be matched against the extensions given in the
L</C<ext_map>> option. If a match is found, the file will be assigned to the
URI path without the extension, with the corresponding encoding.

If the L</C<path_info>> callback does not add a C<Content-Type> header to the
headers array then L<Plack::MIME> will be loaded and passed the URI path to set
a default MIME type; for C<text/*> MIME types, the L</C<default_charset>> will
be added.

=head2 C<add_files>

Takes a list of arrays to pass as arguments to L</C<add_file>>. In other words,

 $app->add_files( [ 'foo', 48 ], [ 'boot', 96 ] );

does the same as

 $app->add_file( 'foo', 48 );
 $app->add_file( 'boot', 96 );

=head1 SEE ALSO

L<Plack::Middleware::Deflater>

L<Plack::Middleware::Precompressed> is effectively obsoleted by this middleware.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
