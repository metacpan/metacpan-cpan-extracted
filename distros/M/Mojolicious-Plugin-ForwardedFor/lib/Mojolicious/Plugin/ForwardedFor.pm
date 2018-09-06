package Mojolicious::Plugin::ForwardedFor;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util 'trim';

our $VERSION = '0.001';

sub register {
  my ($self, $app, $options) = @_;

  my ($levels, $err);
  {
    local $@;
    use warnings FATAL => 'numeric';
    unless (eval { $levels = int($options->{levels} // $ENV{MOJO_REVERSE_PROXY} // 1); 1 }) {
      $err = $@;
    }
  }

  die "Invalid reverse proxy 'levels' for ForwardedFor: $err" if defined $err;

  $app->helper(forwarded_for => sub {
    my $c = shift;
    return $c->tx->original_remote_address unless $levels > 0;
    my @addresses = split /\s*,\s*/, trim($c->tx->req->headers->header('X-Forwarded-For') // '');
    return $addresses[-$levels] // $addresses[0] // $c->tx->original_remote_address;
  });
}

1;

=head1 NAME

Mojolicious::Plugin::ForwardedFor - Retrieve the remote address from X-Forwarded-For

=head1 SYNOPSIS

  use Mojolicious::Lite;
  plugin ForwardedFor => {levels => 2}; # number of reverse proxies you control
  any '/' => sub {
    my $c = shift;
    $c->render(json => {remote_addr => $c->forwarded_for});
  };
  app->start;

=head1 DESCRIPTION

L<Mojolicious> supports deployment via a
L<reverse proxy|Mojolicious::Guides::Cookbook/"Reverse proxy"> setup by
specifying the L<proxy|Mojo::Server::Hypnotoad/"proxy"> configuration option
for Hypnotoad, or the C<MOJO_REVERSE_PROXY> environment variable. However,
L<Mojo::Transaction/"remote_address"> will in this case only return the most
recent address from the C<X-Forwarded-For> header, as it cannot automatically
determine how many remote addresses correspond to proxies.

L<Mojolicious::Plugin::ForwardedFor> can be configured with the number of
reverse proxy L</"levels"> that you control, and provides a L</"forwarded_for">
helper method that will return the remote address at that level. It is
important to set L</"levels"> no higher than the number of proxies that will
have appended addresses to the C<X-Forwarded-For> header, as the original
requests can pass anything as the initial value of the header, and thus spoof
additional proxy levels.

=head1 HELPERS

L<Mojolicious::Plugin::ForwardedFor> implements the following helpers.

=head2 forwarded_for

  my $remote_addr = $c->forwarded_for;

Returns the least recently appended remote address from the C<X-Forwarded-For>
header, while skipping no more than the configured number of reverse proxy
L</"levels">. Returns the originating address of the current request if
configured for 0 reverse proxy levels, or if no addresses have been appended to
the header.

=head1 METHODS

L<Mojolicious::Plugin::ForwardedFor> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);
  $plugin->register(Mojolicious->new, {levels => 1});

Register helper in L<Mojolicious> application. Takes the following options:

=over 4

=item levels

Number of remote proxy levels to allow for when parsing C<X-Forwarded-For>.
Defaults to the value of the C<MOJO_REVERSE_PROXY> environment variable, or 1.

=back

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::Transaction>, L<Mojolicious::Guides::Cookbook>
