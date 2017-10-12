package Mojolicious::Plugin::StaticCache;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

sub register {
    my ($self, $app, $conf) = @_;

    $conf->{even_in_dev}   ||= 0;
    $conf->{max_age}       ||= 2592000;
    $conf->{cache_control} ||= "max-age=$conf->{max_age}, must-revalidate";
    my $mode = $app->mode;
    my $edev = $conf->{even_in_dev};

    $app->hook(after_static => sub {
        my $c = shift;
        if ($mode ne 'development' || $edev) {
            $c->res->headers->cache_control($conf->{cache_control});
        }
    });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::StaticCache - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('StaticCache');
  # With options
  $self->plugin('StaticCache' => { even_in_dev => 1, max_age => 2592000 });

  # Mojolicious::Lite
  plugin 'StaticCache';
  # With options
  plugin 'StaticCache' => { even_in_dev => 1, max_age => 2592000 };

=head1 DESCRIPTION

L<Mojolicious::Plugin::StaticCache> is a L<Mojolicious> plugin which add a Control-Cache header to each static file served by Mojolicious.

=head1 OPTIONS

L<Mojolicious::Plugin::StaticCache> supports the following options.

=head2 even_in_dev

  # Mojolicious
  $self->plugin('StaticCache' => { even_in_dev => 1 });

Add the Cache-Control header even if Mojolicious mode is not 'production'.

Default is to not add the Cache-Control header if the mode is not 'production'.

=head2 max_age

  # Mojolicious
  $self->plugin('StaticCache' => { max_age => 2592000 });

Specify the maximum cache time for the Cache-Control header.

Default is 2592000.

=head2 cache_control

  # Mojolicious
  $self->plugin('StaticCache' => { cache_control => 'max-age=2592000, must-revalidate' });

Specify the content of the Cache-Control header.

Default is "max-age=$max_age, must-revalidate".

=head1 METHODS

L<Mojolicious::Plugin::StaticCache> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 BUGS and SUPPORT

The latest source code can be browsed and fetched at:

  https://framagit.org/luc/mojolicious-plugin-staticcache
  git clone https://framagit.org/luc/mojolicious-plugin-staticcache.git

Bugs and feature requests will be tracked at:

  https://framagit.org/luc/mojolicious-plugin-staticcache/issues

=head1 AUTHOR

  Luc DIDRY
  CPAN ID: LDIDRY
  ldidry@cpan.org
  https://fiat-tux.fr/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
