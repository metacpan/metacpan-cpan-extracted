use strict;

use Test::More;

use Mojo::File 'tempdir';

my $package;

BEGIN {
  $package = 'Nuvol::Config';
  use_ok $package or BAIL_OUT "Unable to load $package";
}

my $tempdir    = tempdir();
my $configfile = "$tempdir/config/connector.conf";
my $service    = 'Nothing';

note 'Constants';

can_ok $package, $_ for qw|CONFIG_PARAMS|;

is $package->CONFIG_PARAMS,
  'access_token app_id redirect_uri refresh_token response_type scope service validto',
  'Config param keys';

note 'Create object';

my %test_params = (
  app_id        => 'my app id',
  redirect_uri  => 'redirect uri',
  response_type => 'response_type',
  scope         => 'none',
  service       => $service
);

my %config_params;
for my $key (sort keys %test_params) {
  eval { $package->new($configfile, \%config_params) };
  like $@, qr/Parameter $key missing!/, "Error for missing $key";
  $config_params{$key} = $test_params{$key};
}

ok my $config = $package->new($configfile, \%config_params), 'Create object';
ok -e $configfile, 'Config file exists';

note 'Content';

my %readonly = (file => $configfile);
$readonly{$_} = $test_params{$_} for grep !/scope/, keys %test_params;

my %readwrite = (
  access_token  => 'access',
  refresh_token => 'refresh',
  scope         => 'scope',
  validto       => '2020-12-31',
);

while (my ($fn, $value) = each %readonly) {
  can_ok $config, $fn;
  is $config->$fn, $value, "Correct value for $fn";
  eval { $config->$fn(999) };
  like $@, qr/Too many arguments/, "$fn is readonly";
}

while (my ($fn, $value) = each %readwrite) {
  can_ok $config, $fn;
  is $config->$fn($value), $config, "Set value for $fn";
  is $config->$fn, $value, "Correct value for $fn";
}

is $config->save, $config, 'Save changes';

note 'Re-open file';
ok $config = $package->new($configfile), 'Re-open file';
is $config->file, $configfile, 'Path to config file';
isa_ok $config->file, 'Mojo::File', 'File object';

while (my ($fn, $value) = (each %readonly, each %readwrite)) {
  is $config->$fn, $value, "Correct value for $fn";
}

note 'Illegal values';
ok $config = $package->new($configfile), 'Re-open file';
ok my $config2 = $package->new($configfile), 'Open a second time';
is $config2->refresh_token('new refresh token')->save, $config2, 'Set new refresh token and save';
eval { $config->save };
like $@, qr/is modified!/, 'Can\'t overwrite modified file';

eval { $package->new($tempdir) };
like $@, qr/is not a file!/, 'Correct error when trying to open directory';

done_testing();
