package Nuvol::Connector;
use Mojo::Base -base, -signatures;

use Mojo::Collection;
use Mojo::Parameters;
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
    my %config_params = (service => $self->SERVICE);
    for (sort keys $self->DEFAULTS->%*) {
      $config_params{$_} = $params->{$_} || $self->DEFAULTS->{$_}
        or Carp::croak "Parameter $_ missing!";
    }
    Nuvol::Config->new($configfile, \%config_params);
  }

  $self->with_roles('Nuvol::Role::Metadata');

  return $self;
}

# methods

sub authenticate ($self) {
  my $config = $self->config;

  # get authorization code
  my $response_type = $config->response_type;
  my %query         = (client_id => $config->app_id, response_type => $response_type);
  for (qw|scope redirect_uri|) {
    $query{$_} = $config->$_ if ($config->$_ || '') ne 'none';
  }
  my $url = Mojo::URL->new($self->AUTH_URL)->query(\%query);
  say $self->NAME;
  my $fn = $self->can("_auth_$response_type")
    or Carp::croak "Unsupported response type '$response_type'!";
  say qq|Open the following link in your browser and allow the application to access your drive:\n|;
  say_info qq|$url\n|;

  my $in       = prompt_input 'Paste the response URL: ', -stdio;
  my $response = $fn->($self, $config, Mojo::URL->new($in));

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

sub drive ($self, $path = '~') {
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

  if ($config->validto && $config->validto < time + 10) {
    $self->_update_token($config);
    $config->save;
  }

  return $config->access_token;
}

sub _auth_code ($self, $config, $url) {
  my $code = $url->query->param('code') or die color_error 'URL contains no code!';

  # redeem code for access tokens
  print 'Get new token ... ';
  my $ua   = Mojo::UserAgent->new;
  my %form = (
    client_id  => $config->app_id,
    code       => $code,
    grant_type => 'authorization_code',
  );
  $form{redirect_uri} = $config->redirect_uri if $config->redirect_uri ne 'none';
  my $res = $ua->post($self->TOKEN_URL, form => \%form)->result;
  die color_error $res->message if $res->is_error;

  my $response = $res->json;
  say_ok 'ok';

  return $response;
}

sub _auth_headers ($self, $headers = {}) {
  my $access_token = $self->_access_token;
  $headers->{Authorization} = "Bearer $access_token";

  return $headers;
}

sub _auth_token ($self, $config, $url) {
  my $rv = {
    access_token =>Mojo::Parameters->new($url->fragment)->param('access_token'),
  };

  return $rv;
}

sub _set_token ($self, $config, $params) {
  $config->$_($params->{$_}) for qw|access_token refresh_token scope|;
  if ($params->{expires_in}) {
    $config->validto(time + $params->{expires_in});
  }

  return $self;
}

sub _ua_delete ($self, $url, @request) {
  return $self->_ua_tx(DELETE => $url, @request);
}

sub _ua_get ($self, $url, @request) {
  return $self->_ua_tx(GET => $url, @request);
}

sub _ua_post ($self, $url, @request) {
  return $self->_ua_tx(POST => $url, @request);
}

sub _ua_put ($self, $url, @request) {
  return $self->_ua_tx(PUT => $url, @request);
}

sub _ua_tx ($self, $method, $url, @request) {
  my $ua      = Mojo::UserAgent->new;
  my $headers = $self->_auth_headers(ref $request[0] eq 'HASH' ? shift @request : {});

  return $ua->start($ua->build_tx($method, $url, $headers, @request))->result;
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

    use Nuvol;
    my $configfile = '/path/to/configfile';
    
    # existing config file
    my $connector  = Nuvol::connect($configfile);

    # new or existing config file
    my $connector  = Nuvol::autoconnect($configfile);

    # with additional parameters
    use Nuvol::Connector;
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

=head1 CONSTRUCTOR

=head2 via Nuvol

    use Nuvol;
    $configfile = '/path/to/configfile';
    $connector  = Nuvol::connect($configfile);      # existing config file
    $connector  = Nuvol::autoconnect($configfile);  # new or existing config file

Connections are opened with L<Nuvol::connect> or L<Nuvol::autoconnect>.

=head2 new

    $connector = Nuvol::Connector->new($configfile, $service);

To create a new file, the parameter C<$service> is required. It defines the type of service that
will be activated in all objects created with this connector. Available services are
L<Dropbox|Nuvol::Connector::Dropbox>, L<Office365|Nuvol::Connector::Office365>, and
L<Dummy|Nuvol::Connector::Dummy>

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
 
    $ perl -MNuvol::Connector -E'Nuvol::Connector->new("~/.office365.conf", "Office365")->authenticate'

New config files can be created and authenticated in the console.

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
file. On some services it invalidates the tokens on the server side, so it is always more secure to
use this method instead of just deleting the file.

To use a disconnected config file again it has to be re-authenticated with L</authenticate>.

=head2 drive

    $drive = $connector->drive($path);

Getter for a drive with the specified C<path>. Returns a L<Nuvol::Drive>.

    $drive = $connector->drive;
    $drive = $connector->drive('~');

Called with no parameter or with C<~> as path will return the default drive.

=head2 list_drives

    $drives        = $connector->list_drives;
    $default_drive = $connector->list_drives->first;

Lists the available drives. Returns a L<Mojo::Collection> containing one or more L<Nuvol::Drive>
with the default drive at the first position. This list may be incomplete.

=head1 SEE ALSO

L<Nuvol>, L<Nuvol::Config>, L<Nuvol::Drive>, L<Nuvol::Role::Metadata>.

=cut
