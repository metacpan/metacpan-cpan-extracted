package Nuvol::Test::ItemLive;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT      = ();
our @EXPORT_OK   = qw|build_test_item test_basics|;
our %EXPORT_TAGS = (all => \@EXPORT_OK, build => ['build_test_item']);

use Nuvol::Test::Roles ':metadata';
use Nuvol::Test::DriveLive ':build';
use Test::More;

sub build_test_item ($service, $path = '/') {
  note "Create test item for $service";

  ok my $drive = build_test_drive($service), 'Create test drive';

  note 'Illegal values';
  eval { $drive->item };
  like $@, qr/Too few arguments for subroutine/, 'Can\'t create item without parameters';

  note 'Create item';
  ok my $item = $drive->item($path), "Get item '$path'";
  isa_ok $item, 'Nuvol::Item';

  return $item;
}

sub test_basics ($item, $service) {
  note 'Basics';

  test_metadata_methods $item, $service;

  delete $item->{metadata};
  ok $item->id,          'Item has an id';
  ok $item->description, 'Item has a description';
  ok $item->name,        'Item has a name';
  ok $item->metadata,    'Item has metadata';
  ok $item->realpath,    'Item has a realpath';
  ok $item->exists,      'Item exists';
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::ConnectorLive - Live test functions for Nuvol items

=head1 SYNOPSIS

    use Nuvol::Test::ItemLive ':all';
    use Nuvol::Test::ItemLive ':build';    # build_test_item

    my $item = build_test_drive $service;

    test_basics;

=head1 DESCRIPTION

L<Nuvol::Test::Connector> provides live test functions for Nuvol items.

The tests are skipped if the environment variables for the different services are not set or don't
point to an existing file. The variable names are C<NUVOL_DUMMY_LIVE>, C<NUVOL_OFFICE365_LIVE>.

See L<ConnectorLive|Nuvol::Test::ConnectorLive/DESCRIPTION> for instructions how to activate live
tests.

=head1 FUNCTIONS

=head2 build_test_item

    $item = build_test_item $service;
    $item = build_test_item $service, $path;    # default '/'

Returns a L<Nuvol::Item> for the specified service, using the config file defined in the environment
variable. If no path is provided, the test item will be the root folder.

=head2 test_basics

    test_basics $item, $service;

Tests the basic functionality of the item.

=head1 SEE ALSO

L<Nuvol::Item>, L<Nuvol::Test>, L<Nuvol::Test::Item>.

=cut
