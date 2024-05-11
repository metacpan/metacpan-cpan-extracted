use warnings;
use 5.020;
use experimental qw( postderef signatures );

package Plack::Middleware::Zstandard 0.02 {

  # ABSTRACT: Compress response body with Zstandard

  use parent qw( Plack::Middleware );
  use Plack::Util ();
  use Plack::Util::Accessor qw( level _constructor_args vary );
  use Ref::Util qw( is_plain_arrayref );
  use Compress::Stream::Zstd::Compressor ();

  sub prepare_app ($self) {
    if(defined $self->level) {
      $self->_constructor_args([$self->level]);
    } else {
      $self->_constructor_args([]);
    }
  }

  sub call ($self, $env) {

    my $res = $self->app->($env);

    $self->response_cb($res, sub ($res) {
      return undef if $env->{HTTP_CONTENT_RANGE};

      my $h = Plack::Util::headers($res->[1]);
      return undef if Plack::Util::status_with_no_entity_body($res->[0]);
      return undef if $h->exists('Cache-Control') && $h->get('Cache-Control') =~ /\bno-transform\b/;

      if($self->vary // 1) {
        my @vary = split /\s*,\s*/, ($h->get('Vary') || '');
        push @vary, 'Accept-Encoding';
        $h->set('Vary' => join(",", @vary));
      }

      # Do not clobber already existing encoding
      return if $h->exists('Content-Encoding') && $h->get('Content-Encoding') ne 'identity';

      return undef unless ($env->{HTTP_ACCEPT_ENCODING} // '') =~ /\bzstd\b/;

      $h->set('Content-Encoding' => 'zstd');
      $h->remove('Content-Length');

      my $compressor = Compress::Stream::Zstd::Compressor->new($self->_constructor_args->@*);

      if($res->[2] && is_plain_arrayref $res->[2]) {
        $res->[2] = [grep length, map { $compressor->compress($_) } grep defined, $res->[2]->@*];
        my $end = $compressor->end;
        push $res->[2]->@*, $end if length $end;
        return undef;
      } else {
        return sub ($chunk) {
          if(defined $chunk) {
            return $compressor->compress($chunk);
          } elsif(defined $compressor) {
            my $end = $compressor->end;
            undef $compressor;
            return $end;
          } else {
            return undef;
          }
        };
      }
    });
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::Zstandard - Compress response body with Zstandard

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Plack::Builder;
 
 my $app = sub {
   return [
     200,
     [ 'Content-Type' => 'text/plain' ],
     [ "Hello World!\n" ],
   ];
 };
 
 builder {
   enable 'Zstandard';
   $app;
 };

=head1 DESCRIPTION

This middleware encodes the body of the response using Zstandard, based on the C<Accept-Encoding>
request header.

=head1 CONFIGURATION

=over 4

=item level

Compression level.  Should be an integer from 1 to 22.  If not provided, then the default will
be chosen by L<Compress::Stream::Zstd>.

=item vary

If set to true (the default), then the response will vary on C<Content-Encoding>.  This is usually
what you want, but if you have another middleware or application that is already vary'ing on that
header, you may want to set this to false.

=back

=head1 SEE ALSO

=over 4

=item L<Plack::Middleware::Deflater>

=item L<Compress::Stream::Zstd>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
