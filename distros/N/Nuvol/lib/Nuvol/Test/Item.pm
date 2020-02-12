package Nuvol::Test::Item;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT      = ();
our @EXPORT_OK   = qw|build_test_item test_basics test_type test_url|;
our %EXPORT_TAGS = (all => \@EXPORT_OK, build => ['build_test_item']);

use Test::More;
use Nuvol::Test::Drive ':build';
use Nuvol::Test::Roles ':metadata';

my $package          = 'Nuvol::Item';
my @constants        = qw|SERVICE|;
my @internal_methods = qw|_check_existence _get_type|;

sub build_test_item ($service) {
  note "Create test item for $service";

  use_ok $package or BAIL_OUT "Unable to load $package";

  test_metadata_prerequisites $package, $service;

  my $drive = build_test_drive $service;
  ok my $object = $package->new($drive, {path => 'Nuvol Testfile.txt', type => 'Unknown'}),
    'Create object';

  return $object;
}

sub test_basics ($item, $service) {
  note 'Basics';

  can_ok $item, $_ for @constants;
  can_ok $item, $_ for @internal_methods;

  test_metadata_applied $item, $service;
}

sub test_type ($item, $types) {
  my $drive = $item->drive;

  note 'Types';

  for my $type ($types->@*) {
    is $package->new($drive, $type->{params})->type, $type->{type}, "Type for $type->{url}";
  }
}

sub test_url ($item, $urls) {
  my $drive     = $item->drive;
  my $drive_url = $drive->url;

  note 'URLs';

  for my $url ($urls->@*) {
    my $expected = $url->{url} ? "$drive_url/$url->{url}" : $drive_url;
    is $package->new($drive, $url->{params})->url, $expected, "URL for $url->{url}";
  }
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::Item - Test functions for Nuvol items

=head1 SYNOPSIS

    use Nuvol::Test::Item ':all';
    use Nuvol::Test::Item ':build';    # build_test_item

    my $item = build_test_item $service;

    test_basics;
    test_type;
    test_url;

=head1 DESCRIPTION

L<Nuvol::Test::Item> provides test functions for Nuvol items.

=head1 FUNCTIONS

=head2 build_test_item

    $item = build_test_item $service;

Returns a L<Nuvol::Item> for the specified service.

=head2 test_basics

    test_basics $item, $service;

Tests the basic structure of the item.

=head2 test_type

    test_type $item, \@types;

Tests if the correct type is detected.

=head2 test_url

    test_url $item, \@urls;

Tests URLs built from IDs and paths.

=head1 SEE ALSO

L<Nuvol::Item>, L<Nuvol::Test>, L<Nuvol::Test::ItemLive>.

=cut
