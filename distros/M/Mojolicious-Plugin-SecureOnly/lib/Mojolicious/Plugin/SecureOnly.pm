package Mojolicious::Plugin::SecureOnly;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.03';

has 'conf' => sub { {} };

sub register {
  my ($self, $app, $conf) = @_;

  $self->conf({%$conf, %{$app->config('SecureOnly')||{}}});

  $app->hook(before_dispatch => sub {
    my $c = shift;

    if ( $self->conf->{not_modes} ) {
      return if grep { $_ eq $app->mode } @{$self->conf->{not_modes}||[]};
    }
    if ( $self->conf->{modes} ) {
      return unless grep { $_ eq $app->mode } @{$self->conf->{modes}||[]};
    }

    return if $c->req->is_secure;
    return $app->log->warn('SecureOnly disabled; Reverse Proxy support not enabled in Mojolicious, see http://mojolicious.org/perldoc/Mojo/Server#reverse_proxy')
      if !$c->tx->req->reverse_proxy && detect_proxy($c);

    my $url = $c->req->url->to_abs;
    $url->scheme('https');
    $url->port($self->conf->{secureport}) if $self->conf->{secureport};
    $c->app->log->debug("SecureOnly enabled; Request for insecure resource, redirecting to $url");
    $c->redirect_to($url);
  });
}

sub detect_proxy {
  my $c = shift;
  return $c->tx->req->headers->header('X-Forwarded-For') || $c->tx->req->headers->header('X-Forwarded-Proto')
}

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::SecureOnly - Mojolicious Plugin to force all requests
secure.

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('SecureOnly');

  # Mojolicious::Lite
  plugin 'SecureOnly' => {secureport => 3001};

=head1 DESCRIPTION

L<Mojolicious::Plugin::SecureOnly> is a L<Mojolicious> plugin that will
redirect all insecure requests to a secure resource.

=head1 METHODS

L<Mojolicious::Plugin::SecureOnly> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
