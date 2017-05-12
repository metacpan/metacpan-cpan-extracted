package Mojolicious::Plugin::AppCacheManifest;

use Mojo::Base qw( Mojolicious::Plugin );

our $VERSION = "0.05";
our %HEADERS = map +( $_, undef ), qw( CACHE FALLBACK NETWORK SETTINGS );
our %CACHE;

has "timeout";

sub register
{
	my ( $self, $app, $conf ) = @_;
	my $extension = $conf->{extension} // "appcache";
	my $re = join( "|", map quotemeta,
	    ref( $extension )
	     ?  @$extension
	     : ( $extension )
	);
	my $redir = qr!\A (.*?) /+ [^/]+ \. (?: $re ) \z!x;
	my $static = $app->static();

	$self->timeout( $conf->{timeout} // 0 );

	$app->hook( before_dispatch => sub {
		my $c = shift;
		my $stash = $c->stash();
		my $tx = $c->tx();
		my $req = $tx->req();
		my $res = $tx->res();
		my $url = $req->url();
		my $path  = $stash->{path}
			  ? Mojo::Path->new( $stash->{path} )
			  : $url->path->clone();
		my $parts = $path->canonicalize->parts();

		# catch nonsense
		return if @$parts == 0 || $parts->[0] eq "..";

		# check for extensions
		unless ( $path =~ $redir ) {
			# otherwise do what the static dispatch code does
			return unless $static->serve( $c, join( "/", @$parts ) );

			$stash->{"mojo.static"}++;
			return !!$c->rendered();
		}

		# setup and prepare
		my $code = 200;
		my $asset = $static->file( join( "/", @$parts ) );
		my ( $output, $last_modified ) = $self->_process(
			$asset->slurp(),
			$asset->path(),
			$static->paths(),
		);

		# save bandwith if possible
		if ( my $date = $req->headers->if_modified_since() ) {
			$code = 304
				if $last_modified eq Mojo::Date->new( $date );
		}

		# send response with conditional body
		$res->code( $code );
		$res->headers->content_type( "text/cache-manifest" );
		$res->headers->last_modified( $last_modified );
		$res->body( $output )
			if $code == 200;

		$stash->{"mojo.static"}++;
		return !!$c->rendered();
	} );

	return $self;
}

sub _process
{
	my ( $self, $body, $path, $dirs ) = @_;
	my $timeout = $self->timeout();
	my $mtime = ( stat( $path ) )[9];
	my $time = time();

	# use cache when file modification and timeout are fine
	return @{ $CACHE{ $path } }[2,3] if
	  exists( $CACHE{ $path } ) &&
		  $CACHE{ $path }[0] >= $mtime &&
		  $CACHE{ $path }[1] + $timeout > $time;

	# extract structure, find highest last modification and generate new output
	my $manifest = $self->_parse( $body );
	my $date = $self->_find_last_modified( $manifest, $mtime, $dirs );
	my $output = $self->_generate( $manifest, $date );

	# put into cache when a timeout is given
	$CACHE{ $path } = [ $date->epoch(), $time, $output, $date ]
		if $timeout > 0;

	return ( $output, $date );
}

sub _parse
{
	my ( $self, $body ) = @_;

	return unless # found and removed the header
	    $body =~ s!\A CACHE [ ] MANIFEST [ \t\r\n] \s* !!sx;

	# split sections by header; prepend header for initial section
	my @body = ( "CACHE", split( m/
	    ^ \s* (\S+) \s* : \s* \r?\n \s*
	/mx, $body ) );

	my %seen;
	my %manifest;

	while ( @body and my $header = uc( shift( @body ) ) ) {
		my $part = shift( @body );

		# skip unknown
		next unless exists( $HEADERS{ $header } );

		# separate lines without comments
		my @lines = grep( +(
		    ! m!\A [#] !x
		), split( m! \s* \r?\n \s* !x, $part ) );

		# unique elements in order; fallback section has pairs
		push( @{ $manifest{ $header } }, map +( $header eq "FALLBACK"
		    ? m!\A (\S+) \s+ (\S+) !x && ! $seen{ $header, $1, $2 }++
		        ? [ $1, $2 ] : ( )
		    : ! $seen{ $header, $_ }++
		        ? ( $_ ) : ( )
		), @lines );
	}

	return \%manifest;
}

sub _find_last_modified
{
	my ( $self, $manifest, $maxmtime, $dirs ) = @_;
	my @parts = map Mojo::URL->new( $_ )->path->canonicalize->parts(),
		    @{ $manifest->{CACHE} };

	# check all paths but prevent path traversal attempts
	for my $path ( map join( "/", @$_ ), grep $_->[0] ne "..", @parts ) {
		my $mtime = 0;

		# try the path in each directory
		stat( "$_/$path" ) and
		    # keep the modification time
		    $mtime = ( stat( _ ) )[9],
		    # stop on the first hit
		    last
			for @$dirs;

		$maxmtime = $mtime if $mtime > $maxmtime;
	}

	return Mojo::Date->new( $maxmtime );
}

sub _generate
{
	my ( $self, $manifest, $date ) = @_;
	my @output = (
		"CACHE MANIFEST",
		"# $date",
	);

	# put cache section explicitely first
	push( @output, @{ $manifest->{CACHE} } )
		if $manifest->{CACHE};

	# followed by fallback in pairs
	push( @output, "FALLBACK:", map "@$_", @{ $manifest->{FALLBACK} } )
		if $manifest->{FALLBACK};

	# finally settings and network in that order
	push( @output, "$_:", @{ $manifest->{ $_ } } )
		for grep $manifest->{ $_ }, qw( SETTINGS NETWORK );

	return join( "\n", @output, "" ); # trailing newline
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::AppCacheManifest - Offline web application manifest support for Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin( "AppCacheManifest" );
  $self->plugin( "AppCacheManifest" => { extension => "manifest" } );
  $self->plugin( "AppCacheManifest" => { extension => [qw[ appcache manifest mf ]] } );
  $self->plugin( "AppCacheManifest" => { timeout => 60 * 5 } );
  
  # Mojolicious::Lite
  plugin "AppCacheManifest";
  plugin "AppCacheManifest" => { extension => "manifest" };
  plugin "AppCacheManifest" => { extension => [qw[ appcache manifest mf ]] };
  plugin "AppCacheManifest" => { timeout => 60 * 5 };

=head1 DESCRIPTION

This plugin manages manifest delivery for
L<Offline Web applications|http://www.whatwg.org/specs/web-apps/current-work/multipage/offline.html>.
It read manifests, checks modification of contained files that exist in static
directories, and returns a clean manifest with only one comment containing a
timestamp to allow for cache invalidation on changes.

=head1 OPTIONS

=head2 extension

  # Mojolicious::Lite
  plugin "AppCacheManifest" => { extension => "manifest" };
  plugin "AppCacheManifest" => { extension => [qw[ appcache manifest mf ]] };

Manifest file extension, allows array references to pass multiple extensions and
defaults to C<appcache>.

=head2 timeout

  # Mojolicious::Lite
  plugin "AppCacheManifest" => { timeout => 60 * 5 };

Cache timeout after which all files in the cache section of manifests get
checked again, defaults to C<0> seconds (disabled).

Note: Manifests are always tested and trigger a full check when they change.

=head1 METHODS

=head2 timeout

Accessor for L</timeout>, see above.

=head1 SEE ALSO

=over 8

=item *

Specification for
L<Offline Web applications|http://www.whatwg.org/specs/web-apps/current-work/multipage/offline.html>.

=item *

L<HTML5::Manifest> has a different approach by generating the manifest programmatically.

=back

=head1 AUTHOR

Simon Bertrang, E<lt>janus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Simon Bertrang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

