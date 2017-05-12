package Mojolicious::Plugin::Log::Access;
use Mojolicious::Plugin -base;

our $VERSION = 0.031;

sub register {
  my ($self, $app) = @_;
  $app->hook(after_dispatch => sub {
    my $c = shift;
    $app->log->info(sprintf '%s "%s" %s', $c->tx->remote_address,
        $c->req->url->to_abs->path_query, $c->res->code);
  });
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::Log::Access - Provide access logging

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Log::Access');

  # Mojolicious::Lite
  plugin 'Log::Access';

=head1 DESCRIPTION

Mojolicious::Plugin::Log::Access is a L<Mojolicious> plugin for adding access
logging to your web application.

=head1 USAGE

Simply add the plugin as shown above.  Whenever the app is in log levels 'debug'
or 'info', it will log each page access as an 'info' message.

Alternatively, if you only want info-level access logging when in 'production'
mode, you can restrict the plugin for only that mode.

  sub startup {
    my $self = shift;
    $self->plugin('Log::Access') if $self->mode eq 'production';

The log entry is deliberately simple.

  [info] <ip address> <page> <status code>

If you need more, L<Mojolicious::Plugin::AccessLog> supports Apache-style
formats.

=head1 TIMESTAMPS

If you want custom timestamps (irrespective of access logging) this plugin
combines seamlessly with L<Mojolicous::Plugin::Log::Timestamp>.

  # Mojolicious
  $self->plugin('Log::Access');
  $self->plugin('Log::Timestamp' => {pattern => '%y%m%d %X'});

  # Mojolicious::Lite
  plugin 'Log::Access';
  plugin 'Log::Timestamp' => {pattern => '%y%m%d %X'};

This is illustrated in C<test/99-play.pl>.

=head1 METHODS

L<Mojolicious::Plugin::Log::Access> inherits all methods from
L<Mojolicious::Plugin>.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 RATIONALE

It is fairly typical that in a production environment web apps will run in
'production' mode and use a log level of 'info'.  Often the administrators will
expect page hits to be logged in a similar style to the likes of apache and
nginx, showing ip address and resulting status code.

This solves an unrelated problem for me.  Sometimes when migrating legacy css or
js, it is important to monitor and catch all 404s; these indicate migration work
yet unfinished.  It can be difficult to see them at log level 'debug'.

Sebastian suggested using an after_dispatch hook in a plugin, so here it is.
When needing to solve the second problem I can develop in log level 'info' since
production-style access logging is exactly what I need.

=head1 COPYRIGHT AND LICENSE

Everything here (incl tools and ideas) was provided by Sebastian Riedel.  It was
packaged by Nic Sandfield.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<Mojolicous::Plugin::AccessLog>, L<Mojar::Log>, L<Mojolicious::Guides>,
L<http://mojolicio.us>.
