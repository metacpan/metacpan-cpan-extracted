package Nuvol::Test::DriveLive;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT      = ();
our @EXPORT_OK   = qw|build_test_drive test_basics|;
our %EXPORT_TAGS = (all => \@EXPORT_OK, build => ['build_test_drive']);

use Nuvol::Test::Roles ':metadata';
use Nuvol::Test::ConnectorLive ':build';
use Test::More;

sub build_test_drive ($service) {
  note "Create test drive for $service";

  ok my $connector = build_test_connector($service),
    'Create test connector';

  note 'Illegal values';
  eval { $connector->drive };
  like $@, qr/Too few arguments for subroutine/, 'Can\'t create drive without parameters';

  note 'Create drive';
  ok my $drive = $connector->drive('~'), 'Get default drive';
  isa_ok $drive, 'Nuvol::Drive';

  return $drive;
}

sub test_basics ($drive, $service) {
  note 'Basics';

  test_metadata_methods $drive, $service;

  delete $drive->{metadata};
  ok $drive->id,          'Drive has an id';
  ok $drive->description, 'Drive has a description';
  ok $drive->name,        'Drive has a name';
  ok $drive->metadata,    'Drive has metadata';
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::ConnectorLive - Live test functions for Nuvol drives

=head1 SYNOPSIS

    use Nuvol::Test::DriveLive ':all';
    use Nuvol::Test::DriveLive ':build';    # build_test_drive

    my $drive = build_test_drive $service;

    test_basics;

=head1 DESCRIPTION

L<Nuvol::Test::DriveLive> provides live test functions for Nuvol drives.

See L<ConnectorLive|Nuvol::Test::ConnectorLive/DESCRIPTION> for instructions how to activate live
tests.

=head1 FUNCTIONS

=head2 build_test_drive

    $drive = build_test_drive $service;

Returns a L<Nuvol::Drive> for the specified service, using the config file defined in the
environment variable.

=head2 test_basics

    test_basics $drive, $service;

Tests the basic functionality of the drive.

=head1 SEE ALSO

L<Nuvol::Drive>, L<Nuvol::Test>, L<Nuvol::Test::Drive>.

=cut
