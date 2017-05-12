package Mojolicious::Plugin::CSSCompressor;

use strict;
use warnings;

use Mojo::Base qw( Mojolicious::Plugin );

use CSS::Compressor qw( css_compress );

our $VERSION = '0.01';

sub HEADER()
{
	'X-CSS-Compressor-Path'
}

sub register
{
	my ( $self, $app, $conf ) = @_;
	my $suffix = $conf->{suffix} // '-min';
	my $re = ref( $suffix )
	       ? $suffix
	       : quotemeta( $suffix )
	;

	$app->hook( before_dispatch => sub {
		my $self = shift;
		my $req = $self->req();
		my $urlpath = $req->url->path();

		# skip it without a matching suffix
		return unless
		    my ( $path ) = $urlpath =~ m!\A (.*) $re \. css \z!x;

		# adjust request path for static dispatch
		$req->url->path( $path . '.css' );

		# keep the original path around to restore later
		$req->headers->remove( HEADER )->add( HEADER, $urlpath );
	} );

	$app->hook( after_dispatch => sub {
		my $self = shift;
		my $req = $self->req();
		my $res = $self->res();

		# the original path indicates when to do something
		return unless
		    my $urlpath = $req->headers->header( HEADER );

		# restore original path
		$req->url->path( $urlpath );

		# only compress when the content type looks ok
		return unless
		    ( $res->headers->content_type() // '' ) =~ m!\A text / css \b!x;

		# get static output
		my $body = $res->body();

		# and deliver compressed version instead
		$res->body( css_compress( $body ) );
	} );
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::CSSCompressor - Mojolicious plugin to compress stylesheets

=head1 SYNOPSIS

  # in a lite app with default suffix -min
  plugin 'CSSCompressor';
  
  # or a normal app
  sub startup {
      # ...
  
      # use .min as suffix instead of the default -min
      $self->plugin( 'CSSCompressor', suffix => '.min' );
  
      # ...
  }

=head1 DESCRIPTION

This plugin looks at the file name and content type to compress stylesheets.

=head1 CONFIGURATION

=over 8

=item suffix

String or regular expression object used as suffix to match against
the request filename. The suffix will be stripped out and used to
get the source file to compress.
Using and empty string as suffix means all css content will be
compressed even without suffix.

=back

=head1 SEE ALSO

L<CSS::Compressor>, L<Mojolicious>, L<Mojolicious::Lite>

=head1 AUTHOR

Simon Bertrang E<lt>janus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Simon Bertrang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

