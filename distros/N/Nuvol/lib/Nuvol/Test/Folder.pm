package Nuvol::Test::Folder;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT      = ();
our @EXPORT_OK   = qw|build_test_folder test_basics|;
our %EXPORT_TAGS = (all => \@EXPORT_OK, build => ['build_test_folder']);

use Test::More;
use Nuvol::Test::Drive ':build';
use Nuvol::Test::Roles ':folder';

my $package          = 'Nuvol::Item';
my $package_role     = 'Folder';
my @internal_methods = qw||;

sub build_test_folder ($service) {
  note "Create test folder for $service";

  use_ok $package or BAIL_OUT "Unable to load $package";

  test_folder_prerequisites $service;

  my $drive = build_test_drive $service;
  ok my $object = $package->new($drive, {path => '/Nuvol Testfolder/', type => $package_role}),
    'Create object';

  return $object;
}

sub test_basics ($folder, $service) {
  note 'Basics';

  can_ok $folder, $_ for @internal_methods;

  test_folder_applied $folder, $service;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::Folder - Test functions for Nuvol folders

=head1 SYNOPSIS

    use Nuvol::Test::Folder ':all';
    use Nuvol::Test::Folder ':build';    # build_test_folder

    my $folder = build_test_folder $service;

    test_basics;
    test_type;
    test_url;

=head1 DESCRIPTION

L<Nuvol::Test::Folder> provides test functions for Nuvol folders.

=head1 FUNCTIONS

=head2 build_test_folder

    $folder = build_test_folder $service;

Returns a L<Nuvol::Item> with applied L<Folder|Nuvol::Role::Folder> roles for the specified service.

=head2 test_basics

    test_basics $folder, $service;

Tests the basic structure of the folder.

=head1 SEE ALSO

L<Nuvol::Role::Folder>, L<Nuvol::Test>, L<Nuvol::Test::FolderLive>.

=cut
