package Nuvol::Connector;
use Mojo::Base -base, -signatures;

use Mojo::Collection;
use Mojo::URL;
use Mojo::UserAgent;
use Nuvol::Config;
use Print::Colored ':all';

# constructor

sub new ($class, $configfile, $service = '', $params = {}) {
  my $self = bless {configfile => $configfile}, $class;

  # existing config
  if (-e $configfile) {
    my $config = $self->config;
    $self->with_roles("Nuvol::$config->{service}::Connector");
  }

  # create new config
  else {
    Carp::croak 'Service missing!' unless $service;
    $self->with_roles("Nuvol::${service}::Connector");
    my %config_params = (configfile => $self->configfile, service => $self->SERVICE);
    $config_params{$_} = $params->{$_} || $self->DEFAULTS->{$_} for qw|app_id redirect_uri scope|;
    Nuvol::Config->new($configfile, \%config_params);
  }

  $self->with_roles('Nuvol::Role::Metadata');

  return $self;
}

# methods

sub authenticate ($self) {
  my $config = $self->config;

  # get authorization code
  my $url = Mojo::URL->new($self->AUTH_URL)->query(
    client_id     => $config->app_id,
    scope         => $config->scope,
    response_type => 'code',
    redirect_uri  => $config->redirect_uri,
  );
  say $self->NAME;
  say qq|Open the following link in your browser and allow the application to access your drive:\n|;
  say_info qq|$url\n|;

  my $in = prompt_input 'Paste the response URL: ', -stdio;
  my $code = Mojo::URL->new($in)->query->param('code')
    or die color_error 'URL contains no code';

  # redeem code for access tokens
  print 'Get new token ... ';
  my $ua   = Mojo::UserAgent->new;
  my %form = (
    client_id    => $config->app_id,
    redirect_uri => $config->redirect_uri,
    code         => $code,
    grant_type   => 'authorization_code',
  );
  my $res = $ua->post($self->TOKEN_URL, form => \%form)->result;
  die color_error $res->message if $res->is_error;
  my $response = $res->json;
  say_ok 'ok';

  # update config
  print 'Update config ... ';
  $self->authenticated($response);
  say_ok 'ok';

  return $self;
}

sub authenticated ($self, $params) {
  my $config = $self->config;

  $self->_set_token($config, $params);
  $config->save;

  return $self;
}

sub config ($self) {
  return Nuvol::Config->new($self->configfile);
}

sub configfile ($self) {
  return $self->{configfile};
}

sub disconnect ($self) {
  my $config = $self->config;
  $config->$_('') for qw|access_token refresh_token scope validto|;
  $config->save;

  return $self;
}

sub drive ($self, $path) {
  require Nuvol::Drive;
  return Nuvol::Drive->new($self, {path => $path});
}

sub list_drives ($self) {
  require Nuvol::Drive;
  my $config = $self->config;

  my @drives   = $self->_load_drivelist;
  my $c_drives = Mojo::Collection->new(map { Nuvol::Drive->new($self, $_) } @drives);

  return $c_drives;
}

# internal methods

sub _access_token ($self) {
  my $config = $self->config;

  if ($config->validto < time + 10) {
    $self->_update_token($config);
    $config->save;
  }

  return $config->access_token;
}

sub _auth_headers ($self, $headers = {}) {
  my $access_token = $self->_access_token;
  $headers->{Authorization} = "Bearer $access_token";
  return $headers;
}

sub _set_token ($self, $config, $params) {
  $config->$_($params->{$_}) for qw|access_token refresh_token scope|;
  if ($params->{expires_in}) {
    $config->validto(time + $params->{expires_in});
  }

  return $self;
}

sub _ua_delete ($self, $url) {
  return Mojo::UserAgent->new->delete($url, $self->_auth_headers)->result;
}

sub _ua_get ($self, $url) {
  return Mojo::UserAgent->new->get($url, $self->_auth_headers)->result;
}

sub _ua_post ($self, $url, $json) {
  return Mojo::UserAgent->new->post($url, $self->_auth_headers, json => $json)->result;
}

sub _ua_put ($self, $url, $content, $headers = {ContentType => 'text/plain'}) {
  return Mojo::UserAgent->new->put($url, $self->_auth_headers($headers), $content)->result;
}

sub _ua_put_asset ($self, $url, $asset, $headers = {}) {
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->build_tx(PUT => $self->_auth_headers($headers));
  $tx->req->content->asset($asset);

  $ua->start($tx);

  return $tx->res;
}

sub _update_oauth_token ($self, $config) {
  my $ua   = Mojo::UserAgent->new;
  my $url  = $self->TOKEN_URL;
  my %form = (
    client_id     => $config->app_id,
    redirect_uri  => $config->redirect_uri,
    refresh_token => $config->refresh_token,
    grant_type    => 'refresh_token',
  );

  my $res = $ua->post($url, form => \%form)->result;
  Carp::confess $res->message if $res->is_error;

  $self->_set_token($config, $res->json);

  return $self;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Connector - Base class for Nuvol connectors

=head1 SYNOPSIS

    # existing config file
    use Nuvol;
    my $configfile = '/path/to/configfile';
    my $connector  = Nuvol::connect($configfile);

    # new config file
    use Nuvol::Connector;
    my $connector = Nuvol::Connector->new($configfile, $service);

    # with additional parameters
    my $connector = Nuvol::Connector->new($configfile, $service, $params);

    $connector->authenticate;
    $connector->authenticated;
    $connector->config;
    $connector->configfile;
    $connector->disconnect;
    $connector->drive;
    $connector->drives;
    $connector->update_drives;
    $connector->url;

=head1 DESCRIPTION

L<Nuvol::Connector> is the base class for Nuvol connectors.

=head2 config file

The parameters for the connection are stored in a config file. The information in this file allows
full access to your cloud service for anyone who can read it. It should be stored at a secure place.

=head1 CONSTRUCTOR

=head2 via Nuvol

    use Nuvol;
    $configfile = '/path/to/configfile';
    $connector  = Nuvol::connect($configfile);

Connections with existing config files are opened with L<Nuvol::connect>.

=head2 new

    $connector = Nuvol::Connector->new($configfile, $service);

To create a new file, the parameter C<$service> is required. It defines the type of service that
will be activated. Available services are L<Dummy|Nuvol::Connector::Dummy> and
L<Office365|Nuvol::Connector::Office365>.

    %params = (
      app_id       => $app_id,
      redirect_uri => $redirect_uri,
      scope        => $scope,
    );
    $connector = Nuvol::Connector->new($configfile, $service, \%params);

Optional parameters can be used to define C<app_id>, C<redirect_uri>, C<scope>. Notice that the final
value for the scope is set during authentication.

    $connector = Nuvol::Connector->new($configfile);

If the config file exists all values are read from it and additional parameters are ignored.

=head1 METHODS

L<Nuvol::Connector> inherits the following methods from L<Nuvol::Role::Metadata>:

=over

=item L<description|Nuvol::Role::Metadata/description>

=item L<id|Nuvol::Role::Metadata/id>

=item L<metadata|Nuvol::Role::Metadata/metadata>

=item L<name|Nuvol::Role::Metadata/name>

=item L<url|Nuvol::Role::Metadata/url>

=back

=head2 authenticate

    $connector->authenticate;

Starts an interactive authentication process. It will display a URL that has to be opened in a
browser to start the authorization flow. The resulting URL is copied back to the console where it is
used to retrieve the access tokens. If this process succeeds, the information is written to the
config file. From now on it is possible to open the connector directly with L<Nuvol::connect>.

=head2 authenticated

    %params = (
      access_token  => $access_token,
      expires_in    => $seconds,
      refresh_token => $refresh_token,
      scope         => $scope,
    );
    $connector = $connector->authenticated(\%params);

Setter for new authentication tokens. Can be used if the authentication is made in an external
module.

=head2 config

    $value = $connector->config;

Getter for the config. Returns a L<Nuvol::Config>.

=head2 configfile

    $value = $connector->configfile;

Getter for the path to the configfile.

=head2 disconnect

    $connector = $connector->disconnect($newvalue);

Deletes the confidential information (access token, refresh token and valitidy time) from the config
file. To use it again it has to be re-authenticated.

=head2 drive

    $drive = $connector->drive($path);

Getter for a drive with the specified C<path>. Returns a L<Nuvol::Drive>.

=head2 list_drives

    $drives        = $connector->list_drives;
    $default_drive = $connector->list_drives->first;

Lists the available drives. Returns a L<Mojo::Collection> containing one or more L<Nuvol::Drive>
with the default drive at the first position. This list may be incomplete.

=head1 SEE ALSO

L<Nuvol>, L<Nuvol::Drive>.

=cut
