package Nuvol::Test::Drive;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT      = ();
our @EXPORT_OK   = qw|build_test_drive test_basics test_url|;
our %EXPORT_TAGS = (all => \@EXPORT_OK, build => ['build_test_drive']);

use Test::More;
use Mojo::File 'tempfile';
use Nuvol::Test::Connector ':build';
use Nuvol::Test::Roles ':metadata';

my $package   = 'Nuvol::Drive';
my @constants = qw|SERVICE|;

sub build_test_drive ($service) {
  note "Create test drive for $service";

  use_ok $package or BAIL_OUT "Unable to load $package";

  test_metadata_prerequisites $package, $service;

  my $connector = build_test_connector $service;
  ok my $object = $package->new($connector, {path => '~'}), 'Create object';

  return $object;
}

sub test_basics ($drive, $service) {
  note 'Basics';

  can_ok $drive, $_ for @constants;

  test_metadata_applied $drive, $service;
}

sub test_url ($drive, $urls) {
  my $connector     = $drive->connector;
  my $connector_url = $connector->url;

  note 'URLs';

  for my $url ($urls->@*) {
    is $package->new($connector, {$url->[0], $url->[1]})->url, "$connector_url/$url->[2]",
      "URL for $url->[0]";
  }
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::Drive - Test functions for Nuvol drives

=head1 SYNOPSIS

    use Nuvol::Test::Drive ':all';
    use Nuvol::Test::Drive ':build';    # build_test_drive

    my $drive = build_test_drive $service;

    test_basics;
    test_url;

=head1 DESCRIPTION

L<Nuvol::Test::Drive> provides test functions for Nuvol drives.

=head1 FUNCTIONS

=head2 build_test_drive

    $drive = build_test_drive $service;

Returns a L<Nuvol::Drive> for the specified service.

=head2 test_basics

    test_basics $drive, $service;

Tests the basic structure of the drive.

=head2 test_url

    test_url $drive, \@urls;

Tests URLs built from IDs and paths.

=head1 SEE ALSO

L<Nuvol::Drive>, L<Nuvol::Test>, L<Nuvol::Test::DriveLive>.

=cut
