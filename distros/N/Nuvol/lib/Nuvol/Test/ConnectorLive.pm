package Nuvol::Test::ConnectorLive;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT      = ();
our @EXPORT_OK   = qw|build_test_connector test_basics test_drivelist|;
our %EXPORT_TAGS = (all => \@EXPORT_OK, build => ['build_test_connector']);

use Nuvol::Test::Roles ':metadata';
use Test::More;

use Nuvol;

sub build_test_connector ($service) {
  note "Create test connector for $service";

  my $configvar  = uc "NUVOL_${service}_LIVE";
  my $configfile = $ENV{$configvar};
  plan skip_all => "$configvar=/path/to/config"    unless $configfile;
  plan skip_all => "'$configfile' does not exist!" unless -f $configfile;

  ok my $connector = Nuvol::connect($configfile), 'Create connector';
  isa_ok $connector, 'Nuvol::Connector';

  return $connector;
}

sub test_basics ($connector, $service) {
  note 'Basics';

  test_metadata_methods $connector, $service;

  ok my $config = $connector->config, 'Get config';

SKIP: {
    skip 'No refresh token available', 6 unless $config->refresh_token;

    my $old_access_token = $config->access_token;
    ok $config->validto(time)->save, 'Invalidate token';

    ok my $new_access_token = $connector->_access_token, 'Refresh token';

    isnt $new_access_token, $old_access_token, 'Access token has changed';
    ok $config = $connector->config, 'Get new config';
    is $config->access_token, $new_access_token, 'New token is in config';
    ok $connector->config->validto > time + 60, 'Token is valid';
  }
}

sub test_drivelist ($connector) {
  my $service = $connector->SERVICE;

  note 'Drive list';

  ok my $drives = $connector->list_drives, 'Get drives';
  isa_ok $drives, 'Mojo::Collection';
  ok $drives->size > 0, 'Drives available';
  $drives->each(
    sub ($drive, $i) {
      isa_ok $drive, 'Nuvol::Drive';
      ok $drive->does("Nuvol::${service}::Drive"), 'Role applied';
    }
  );
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::ConnectorLive - Live test functions for Nuvol connectors

=head1 SYNOPSIS

    use Nuvol::Test::ConnectorLive ':all';
    use Nuvol::Test::ConnectorLive ':build';    # build_test_connector

    my $connector = build_test_connector $service;

    test_basics;
    test_drivelist;

=head1 DESCRIPTION

L<Nuvol::Test::Connector> provides live test functions for Nuvol connectors.

=head1 FUNCTIONS

=head2 build_test_connector

    $connector = build_test_connector $service;

Returns a L<Nuvol::Connector> for the specified service, using the config file defined in the
environment variable.

=head2 test_basics

    test_basics $connector, $service;

Tests the basic functionality of the connector, like updating the access token.

=head2 test_drivelist

    test_drivelist $connector;

Performs tests with L<Nuvol::Connector/update_drives>, L<Nuvol::Connector/drives>, and
L<Nuvol::Connector/drive>.

=head1 SEE ALSO

L<Nuvol::Connector>, L<Nuvol::Test>, L<Nuvol::Test::Connector>.

=cut
