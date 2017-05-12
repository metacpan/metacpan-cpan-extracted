package Mojolicious::Plugin::ProxyPassReverse::SubDir;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

sub register {
  my ($self, $app, $conf) = @_;

  $conf //= {};
  my $header = $conf->{header} // 'X-Forwarded-Host';
  my $value  = $conf->{value};
  my $depth  = $conf->{depth} // 1;

  $app->hook(before_dispatch => sub {
    my $c = shift;

    if ( defined ( my $v = $c->req->headers->header($header) ) ) {
      return if defined $value and $v ne $value;

     DEPTH:
      for ( 1 .. $depth ) {
        push @{ $c->req->url->base->path->parts },
          shift @{ $c->req->url->path->parts };
      }
    }
  });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ProxyPassReverse::SubDir - Mojolicious Plugin for reverse
proxy and sub-directory environment

=head1 SYNOPSIS

  ## 1. Basic
  # Mojolicious
  $self->plugin('ProxyPassReverse::SubDir');

  # Mojolicious::Lite
  plugin 'ProxyPassReverse::SubDir';


  ## 2. For Custom HTTP Header (Default: X-Forwarded-Host)
  # Mojolicious
  $self->plugin('ProxyPassReverse::SubDir' => {
    header => 'X-Forwarded-Your-Custom-Header',
  });

  # Mojolicious::Lite
  plugin 'ProxyPassReverse::SubDir' => {
    header => 'X-Forwarded-Your-Custom-Header',
  };


  ## 3. For Custom HTTP Header Value
  # Mojolicious
  $self->plugin('ProxyPassReverse::SubDir' => {
    header => 'X-Forwarded-Your-Custom-Header',
    value  => 'On',
  });

  # Mojolicious::Lite
  plugin 'ProxyPassReverse::SubDir' => {
    header => 'X-Forwarded-Your-Custom-Header',
    value  => 'On',
  };

  ## 4. For Custom Sub-Directory Depth
  # Mojolicious
  $self->plugin('ProxyPassReverse::SubDir' => {
    depth => 2, # Ex) http://example.com/foo/bar => http://example.com:3000/
  });

  # Mojolicious::Lite
  plugin 'ProxyPassReverse::SubDir' => {
    depth => 2, # Ex) http://example.com/foo/bar => http://example.com:3000/
  };

=head1 DESCRIPTION

L<Mojolicious::Plugin::ProxyPassReverse::SubDir> is a L<Mojolicious> plugin to
easily support reverse proxy and sub-directory environment.

=head1 METHODS

L<Mojolicious::Plugin::ProxyPassReverse::SubDir> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=head1 AUTHOR

Shingo MURATA E<lt>murata@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
