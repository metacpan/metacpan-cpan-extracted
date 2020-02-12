package Nuvol::Test::Connector;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT = ();
our @EXPORT_OK
  = qw|build_test_connector test_authenticate test_basics test_config test_constants test_defaults test_disconnect|;
our %EXPORT_TAGS = (all => \@EXPORT_OK, build => ['build_test_connector']);

use Mojo::File 'tempdir';
use Mojo::URL;
use Nuvol::Test::Roles ':metadata';
use Test::More;

my $package      = 'Nuvol::Connector';
my @constants    = qw|API_URL AUTH_URL DEFAULTS INFO_URL NAME TOKEN_URL SERVICE|;
my @defaults     = qw|app_id redirect_uri scope|;
my @role_methods = qw|_get_description _get_name _load_drivelist _load_metadata _update_token|;

sub build_test_connector ($service) {
  note "Create test connector for $service";

  use_ok $package or BAIL_OUT "Unable to load $package";

  test_metadata_prerequisites $package, $service;

  my $configfile = tempdir->child('testconfig.conf');
  ok my $object = $package->new($configfile, $service), 'Create object';

  return $object;
}

sub test_authenticate ($connector, $tokens) {
  note 'Authenticate';

  my $validto = time + $tokens->{expires_in};
  is $connector->authenticated($tokens), $connector, 'Set tokens';
  ok my $config = $connector->config, 'Get config';
  is $config->$_, $tokens->{$_}, "Correct $_" for qw|access_token refresh_token scope|;
  is $config->validto, $validto, 'Correct validity.';
}

sub test_basics ($connector, $service) {
  note 'Basics';

  can_ok $connector, $_ for @constants;
  ok $connector->DEFAULTS->{$_}, "Default $_" for @defaults;

  test_metadata_applied $connector, $service;

  ok -e $connector->configfile, 'Config file exists';
}

sub test_config ($connector) {
  note 'Config';

  ok my $config = $connector->config, 'Get config';
  is $config->file,    $connector->configfile, 'Identical config file';
  is $config->service, $connector->SERVICE,    'Correct service';
  for (@defaults) {
    is $config->$_, $connector->DEFAULTS->{$_}, "Correct $_";
  }
}

sub test_constants ($connector, $constants) {
  note 'Constants';

  for (sort keys $constants->%*) {
    is $connector->$_, $constants->{$_}, "Constant $_";
  }
}

sub test_defaults ($connector, $defaults) {
  note 'Defaults';

  for (@defaults) {
    is $connector->DEFAULTS->{$_}, $defaults->{$_}, "Default $_";
  }
}

sub test_disconnect ($connector) {
  note 'Disconnect';

  is $connector->disconnect, $connector, 'Call disconnect';
  ok my $config = $connector->config, 'Get config';
  ok !$config->$_, "$_ is empty" for qw|access_token refresh_token validto|;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::Connector - Test functions for Nuvol connectors

=head1 SYNOPSIS

    use Nuvol::Test::Connector ':all';
    use Nuvol::Test::Connector ':build';    # build_test_connector

    my $connector = build_test_connector $service;

    test_basics;
    test_constants;
    test_defaults;
    test_config;
    test_authenticate;
    test_disconnect;

=head1 DESCRIPTION

L<Nuvol::Test::Connector> provides test functions for Nuvol connectors.

=head1 FUNCTIONS

=head2 build_test_connector

    $connector = build_test_connector $service;

Returns a L<Nuvol::Connector> for the specified service, using a config file in a temporary folder.

=head2 test_authenticate

    %tokens = (
      access_token  => $access_token,
      expires_in    => $seconds,
      refresh_token => $refresh_token,
      scope         => $scope
    );
    test_authenticate $connector, \%tokens;

Simulates a successful authentication.

=head2 test_basics

    test_basics $connector, $service;

Tests the basic structure of the connector.

=head2 test_config

    test_config $connector;

Tests the content of the config and config file.

=head2 test_constants

    %constants = (...);
    test_constants $connector, \%constants;

Tests the content of the constants.
    
=head2 test_defaults

    %defaults = (...);
    test_defaults $connector, \%defaults;

Tests the default values.
    
=head2 test_disconnect

    test_disconnect $connector;

Disconnects and checks if the authentication tokens are deleted.

=head1 SEE ALSO

L<Nuvol::Connector>, L<Nuvol::Test>, L<Nuvol::Test::ConnectorLive>.

=cut
