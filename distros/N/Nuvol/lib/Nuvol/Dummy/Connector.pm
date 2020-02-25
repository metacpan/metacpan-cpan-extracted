package Nuvol::Dummy::Connector;
use Mojo::Base -role, -signatures;

use Mojo::File 'path';

use constant {
  API_URL  => 'file:',
  AUTH_URL => 'auth_url',
  DEFAULTS => {
    app_id        => 'dummy_app_id',
    redirect_uri  => 'redirect_uri',
    response_type => 'code',
    scope         => 'dummy_scope',
  },
  INFO_URL  => 'info_url',
  NAME      => 'Nuvol Dummy Connector',
  TOKEN_URL => 'token_url',
  SERVICE   => 'Dummy',
};

# internal methods

sub _build_url ($self, @path) {
  my $url = Mojo::URL->new($self->API_URL . path($self->configfile)->dirname);
  push $url->path->@*, @path if @path;

  return $url;
}

sub _do_disconnect ($self) {}

sub _get_description ($self) {
  return $self->NAME . ' ' . $self->configfile;
}

sub _get_name ($self) {
  return $self->NAME;
}

sub _load_drivelist ($self) {
  my @drives;
  path($self->configfile)->sibling('drives')->list({dir => 1})->each(
    sub ($path, $i) {
      if (-d $path) {
        my %metadata = (
          id     => pack('u', $path),
          folder => $path,
        );
        push @drives, {id => $metadata{id}, metadata => \%metadata};
      }
    }
  );

  return @drives;
}

sub _load_metadata ($self) {
  return {id => 12345};
}

sub _update_token ($self, $config) {
  my $rand = int rand 100000;
  $config->access_token("Access Token $rand")->refresh_token("Refresh Token $rand")
    ->validto(time + 3600);
}

1;

=encoding utf8

=head1 NAME

Nuvol::Dummy::Connector - Internal methods for dummy connectors

=head1 DESCRIPTION

L<Nuvol::Dummy::Connector> provides internal methods for dummy connectors.

=head1 SEE ALSO

L<Nuvol::Connector>, L<Nuvol::Dummy>.

=cut
