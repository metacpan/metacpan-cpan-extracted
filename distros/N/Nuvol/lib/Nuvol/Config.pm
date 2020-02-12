package Nuvol::Config;
use Mojo::Base -base, -signatures;

use Mojo::File 'path';
use Mojo::JSON qw|decode_json encode_json|;

# constants

use constant CONFIG_PARAMS =>
  'access_token app_id redirect_uri refresh_token scope service validto';

# constructor

sub new ($class, $configfile, $params = {}) {
  my $self;

  my $file = path($configfile)->with_roles('+Digest');

  if (-e $file) {
    if (-f $file) {
      $self = decode_json $file->slurp;
      $self->{file} = $file;
    } else {
      Carp::croak "'$file' is not a file!";
    }
  } else {

    # check params
    for (qw|app_id redirect_uri scope service|) {
      Carp::croak "Parameter $_ missing!" unless $params->{$_};
    }

    $self = {file => $file, $params->%*};
    $file->dirname->make_path;
    $file->spurt(encode_json $self)->chmod(0700);
  }
  $self->{digest} = $file->md5_sum;

  return bless $self, $class;
}

# methods

has [qw|access_token hash refresh_token scope validto|];

sub app_id ($self)       { return $self->{app_id}; }
sub digest ($self)       { return $self->{digest}; }
sub file ($self)         { return $self->{file}; }
sub redirect_uri ($self) { return $self->{redirect_uri}; }

sub save ($self) {
  my $file = $self->file;
  Carp::croak "'$file' is modified!" if $file->md5_sum ne $self->digest;
  $file->spurt(encode_json { $self->%{split / /, CONFIG_PARAMS} });
  $self->{digest} = $file->md5_sum;

  return $self;
}

sub service ($self) { return $self->{service}; }

1;

=encoding utf8

=head1 NAME

Nuvol::Config - Config for Nuvol connectors

=head1 SYNOPSIS

    use Nuvol;
    my $connector = Nuvol::connect($configfile);
    my $config    = $connector->config;

    $config->access_token;
    $config->app_id;
    $config->digest;
    $config->file;
    $config->redirect_uri;
    $config->refresh_token;
    $config->save;
    $config->scope;
    $config->service;
    $config->validto;

=head1 DESCRIPTION

L<Nuvol::Config> is a file-based container for Nuvol connector configurations.

=head2

=head1 CONSTRUCTOR

=head2 via Nuvol

    use Nuvol;

    $connector = Nuvol::connect($configfile);
    $config    = $connector->config;

In daily use a L<Nuvol::Config> is created with L<Nuvol::Connector/config>.

=head2 new

    use Nuvol::Config;

    %params = (
      app_id       => $app_id,
      redirect_uri => $redirect_uri,
      scope        => $scope,
      service      => $service,
    );
    $config = Nuvol::Config->new($configfile, \%params);

Internally the constructor is called. If the file doesn't exist the above parameters are required.

=head1 METHODS

=head2 access_token

    $access_token = $config->access_token;
    $config       = $config->access_token($new_access_token);

Getter and setter for the access token.

=head2 app_id

    $app_id = $config->app_id;

Getter for the app id.

=head2 digest

    $digest = $config->digest;

Getter for the digest of the L</file> at the time of the last access.

=head2 file

    $file = $config->file;

Getter for the config file. Returns a L<Mojo::File> with L<Mojo::File::Role::Digest>.

=head2 redirect_uri

    $redirect_uri = $config->redirect_uri;

Getter for the redirect URI.

=head2 refresh_token

    $refresh_token = $config->refresh_token;
    $config        = $config->refresh_token($new_refresh_token);

Getter and setter for the refresh token.

=head2 save

    $config = $config->save;

Saves the current values to the L<config file|/file>.

=head2 scope

    $scope  = $config->scope;
    $config = $config->scope($new_scope);

Getter and setter for the scope.

=head2 service

    $service = $config->service;

Getter for the service of the connection.

=head2 validto

    $validto  = $config->validto;
    $config   = $config->validto($new_validto);

Getter and setter for the validto time.

=head1 SEE ALSO

L<Nuvol::Connector>.

=cut
