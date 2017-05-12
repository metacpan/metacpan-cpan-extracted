use strict;
use warnings;
package Plack::Middleware::LowerUrl;
use parent qw( Plack::Middleware );

sub call {
  my ($self, $env) = @_;
  if ( $env->{REQUEST_URI} ) {
    my ($path, $params) = split(/\?/, $env->{REQUEST_URI});
    $path = lc $path;
    $env->{REQUEST_URI} = join('?', $path, $params);
  }
  if ( $env->{PATH_INFO} ) {
    $env->{PATH_INFO} = lc $env->{PATH_INFO} if $env->{PATH_INFO};
  }
  my $res = $self->app->($env);
  return $res;
}

1;

=head1 NAME

Plack::Middleware::LowerUrl - Make everything lower!

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable "Plack::Middleware::LowerUrl";
        $app;
    };

=head1 DESCRIPTION

L<Plack::Middleware::LowerUrl> will just make the REQUEST_URI and PATH_INFO lower.
It will skip over any passed in parameters.

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware>

=head1 AUTHOR

Logan Bell, C<< <logie@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013, Logan Bell

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
