package Plack::Middleware::CSS::Compressor;

use strict;
use warnings;

use parent qw( Plack::Middleware );

use CSS::Compressor qw( css_compress );

use Plack::Util::Accessor qw( suffix );
use Plack::Util;

our $VERSION = '0.01';

sub prepare_app
{
	my $self = shift;
	my $suffix = $self->suffix();

	unless ( defined( $suffix ) ) {
		$suffix = '-min';
	}

	# make the suffix usable in regular expressions
	$self->suffix( ref( $suffix )
		? $suffix
		: quotemeta( $suffix )
	);
}

sub call
{
	my ( $self, $env ) = @_;
	my $suffix = $self->suffix();
	my $path_info = $env->{PATH_INFO};

	# match and adjust file name and extension
	unless ( $env->{PATH_INFO} =~ s!\A (.*) $suffix ([.]css) \z!$1$2!x ) {
		# otherwise pass through
		return $self->app->( $env );
	}

	# call underlying handler with adjusted path
	my $res = $self->app->( $env );

	# make sure the response is an array and not streamed
	unless ( ref( $res ) eq 'ARRAY' ) {
		return $res;
	}

	my $h = Plack::Util::headers( $res->[1] );
	my $ct = $h->get( 'Content-Type' );

	# got a stylesheet as response
	if ( $res->[0] == 200 && $ct && $ct =~ m!\A text/css \b!x ) {
		my $css = '';

		# collect all css chunks
		Plack::Util::foreach( $res->[2], sub { $css .= $_[0] } );

		# store compressed css as new body
		$res->[2] = [ css_compress( $css ) ];

		# adjust length
		$h->set( 'Content-Length' => length( $res->[2][0] ) );
	}
	# nothing found with the adjusted path
	elsif ( $res->[0] == 404 ) {
		# restore original path
		$env->{PATH_INFO} = $path_info;
		# and try again
		$res = $self->app->( $env );
	}

	return $res;
}

1;

__END__

=head1 NAME

Plack::Middleware::CSS::Compressor - Plack middleware to compress stylesheets

=head1 SYNOPSIS

  use Plack::App::File;
  use Plack::Builder;

  builder {
      mount '/public' => builder {
          enable 'CSS::Compressor';
          Plack::App::File( root => './public' );
      };
      mount '/' => $app;
  };

  # or in a middleware setup

  builder {
      enable 'CSS::Compressor',
          suffix => '.min'
      ;
      enable 'Static',
          path => sub { s!\A /public/ !!x },
          root => './public/'
      ;

      $app;
  };

=head1 DESCRIPTION

This middleware provides the possibility to compress stylesheets on the fly.

=head1 OPTIONS

=over 8

=item suffix

String or regular expression object that matches a suffix at the end of the file.
This allows to control compression through the file name.
To unconditionally enable compression set the suffix to an empty string.

=back

=head1 SEE ALSO

L<CSS::Compressor>, L<Plack>

=head1 AUTHOR

Simon Bertrang E<lt>janus@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Simon Bertrang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

