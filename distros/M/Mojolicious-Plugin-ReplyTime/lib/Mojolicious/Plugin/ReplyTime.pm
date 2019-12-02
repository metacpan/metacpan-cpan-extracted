package Mojolicious::Plugin::ReplyTime;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

sub register {
  my ($self, $app) = @_;

  $app->helper('reply.time' => sub {
    shift->respond_to(
      html => {text => scalar localtime},
      json => {json => {time => scalar localtime}},
    );
  });
  $app->routes->get('/replytime')->to(cb => sub {
    shift->reply->time
  });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::ReplyTime - Reply with a simple response of just the
current time

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('ReplyTime');

  # Mojolicious::Lite
  plugin 'ReplyTime';

  # Demo
  $ perl -Mojo -E 'plugin "ReplyTime"; app->start' routes
  /replytime  GET  replytime
  $ perl -Mojo -E 'plugin "ReplyTime"; app->start' get /replytime
  Sat Nov 30 17:45:57 2019

=head1 DESCRIPTION

L<Mojolicious::Plugin::ReplyTime> is a L<Mojolicious> plugin that adds a
reply helper named "time" to the Mojolicious controller object. It will
respond to a JSON request with '{"time":"[scalar localtime]"}' and any other
request with a plain text response of just the localtime as a scalar.

Also included is a get route called /replytime that will call the
reply->time helper.

Also included is a C<replytime> command line utility which will launch a simple
Mojolicious daemon that will respond to any request with the local time. The
purpose for this is simply testing: rather than a static response in which you
are unsure if the response is cached or not, reply time also responds with
something fresh.

=head1 METHODS

L<Mojolicious::Plugin::ReplyTime> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
