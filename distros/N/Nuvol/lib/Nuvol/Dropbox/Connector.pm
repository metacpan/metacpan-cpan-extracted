package Nuvol::Dropbox::Connector;
use Mojo::Base -role, -signatures;

use constant {
  AUTH_URL => 'https://www.dropbox.com/oauth2/authorize',
  API_URL  => 'https://api.dropboxapi.com/2',
  DEFAULTS => {
    redirect_uri  => 'https://nuvol.ch/redirect',
    response_type => 'token',
    scope         => 'none',
    app_id        => 'g536fryrx8oyijl',
  },
  INFO_URL  => 'https://api.dropboxapi.com/2/check/user',
  NAME      => 'Nuvol Dropbox Connector',
  TOKEN_URL => 'https://api.dropboxapi.com/oauth2/token',
  SERVICE   => 'Dropbox',
};

# internal methods

sub _build_url ($self, @path) {
  my $url = Mojo::URL->new($self->API_URL);
  push $url->path->@*, @path if @path;

  return $url;
}

sub _do_disconnect ($self) {
  $self->_ua_post($self->url('auth/token/revoke'));
}

sub _get_name ($self) {
  return $self->metadata->{name}{display_name};
}

sub _get_description ($self) {
  my $metadata = $self->metadata;
  return $self->SERVICE . " $metadata->{name}{display_name} <$metadata->{email}>";
}

sub _load_drivelist ($self) {
  my $metadata = $self->metadata;
  my @drives   = ({id => $metadata->{id}, metadata => $metadata});

  return @drives;
}

sub _load_metadata ($self) {
  my $config = $self->config;
  my $res = $self->_ua_post($self->url('users/get_current_account'));
  Carp::confess $res->message if $res->is_error;

  my $metadata = $res->json;
  $metadata->{id} = $metadata->{account_id};

  return $metadata;
}

sub _update_token ($self, $config) {
  return $self->_update_oauth_token($config);
}

1;

=encoding utf8

=head1 NAME

Nuvol::Dropbox::Connector - Internal methods for Dropbox connectors

=head1 DESCRIPTION

L<Nuvol::Dropbox::Connector> provides internal methods for Dropbox connectors.

=head1 SEE ALSO

L<Nuvol::Connector>, L<Nuvol::Dropbox>.

=cut
