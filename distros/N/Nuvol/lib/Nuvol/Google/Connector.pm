package Nuvol::Google::Connector;
use Mojo::Base -role, -signatures;

use constant {
  AUTH_URL => 'https://accounts.google.com/o/oauth2/auth',
  API_URL  => 'https://www.googleapis.com',
  DEFAULTS => {
    app_id        => '',
    app_secret    => '',
    redirect_uri  => '',
    response_type => 'code',
    scope         => 'drive',
  },
  INFO_URL  => '',
  NAME      => 'Nuvol Google Connector',
  TOKEN_URL => 'https://www.googleapis.com/token',
  SERVICE   => 'Google',
};

# internal methods

sub _build_url ($self, @path) {
  my $url = Mojo::URL->new($self->API_URL);
  push $url->path->@*, @path if @path;

  return $url;
}

sub _do_disconnect ($self) { }

sub _get_name ($self) { }

sub _get_description ($self) { }

sub _load_drivelist ($self) { }

sub _load_metadata ($self) { }

sub _update_token ($self, $config) { }

1;

=encoding utf8

=head1 NAME

Nuvol::Google::Connector - Internal methods for Google connectors

=head1 DESCRIPTION

L<Nuvol::Google::Connector> provides internal methods for Google connectors.

=head1 SEE ALSO

L<Nuvol::Connector>, L<Nuvol::Google>.

=cut
