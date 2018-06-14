package Mojolicious::Plugin::Prometheus::Shared::FastMmap;
use Mojo::Base 'Mojolicious::Plugin::Prometheus';
use Role::Tiny::With;

our $VERSION = '1.0.1';

with 'Mojolicious::Plugin::Prometheus::Role::SharedFastMmap';
1;
__END__

=for stopwords mmapped

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Prometheus::Shared::FastMmap - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Prometheus::Shared::FastMmap');

  # Mojolicious::Lite
  plugin 'Prometheus::Shared::FastMmap';

  # Mojolicious::Lite, with custom response buckets (seconds)
  plugin 'Prometheus::Shared::FastMmap' => { response_buckets => [qw/4 5 6/] };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Prometheus::Shared::FastMmap> is a L<Mojolicious> plugin that exports Prometheus metrics from Mojolicious, using a shared mmapped file between workers.

It uses L<Mojolicious::Plugin::Prometheus> under the hood, and adds a shared cache using L<Mojolicious::Plugin::CHI> + L<CHI> + L<Cache::FastMmap> to provide metrics for all workers under a pre-forking daemon like L<Mojo::Server::Hypnotoad>.

See L<Mojolicious::Plugin::Prometheus> for more complete documentation.

=head1 METHODS

L<Mojolicious::Plugin::Prometheus::Shared::FastMmap> inherits all methods from
L<Mojolicious::Plugin::Prometheus> and implements no new ones.

=head2 register

  $plugin->register($app, \%config);

Register plugin in L<Mojolicious> application.

C<%config> can have all the original values as L<Mojolicious::Plugin::Prometheus>, and adds the following keys:

=over 2

=item * cache_dir

The path to store the mmapped file. See L<CHI::Driver::FastMmap> for details (used as root_dir).

Default: ./cache

=item * cache_size

Defaults to '5m'. See L<CHI::Driver::FastMmap> for details.

=back

=head1 AUTHOR

Vidar Tyldum

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018, Vidar Tyldum

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

=over 2

=item L<Mojolicious::Plugin::Prometheus>

=item L<CHI::Driver::FastMmap>

=item L<Net::Prometheus>

=item L<Mojolicious>

=item L<Mojolicious::Guides>

=item L<http://mojolicious.org>

=back

=cut
