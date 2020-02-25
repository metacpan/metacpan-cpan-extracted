package Nuvol::Test::FolderLive;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT      = ();
our @EXPORT_OK   = qw|build_test_folder test_basics test_cd|;
our %EXPORT_TAGS = (all => \@EXPORT_OK, build => ['build_test_folder']);

use Nuvol::Test::Roles qw|:folder :metadata|;
use Nuvol::Test::DriveLive ':build';
use Test::More;

my $testfolder = '/Nuvol Testfolder/';

sub build_test_folder ($service) {
  note "Create test folder for $service";

  ok my $drive = build_test_drive($service), 'Create test drive';

  note 'Cleanup';
  ok my $old_folder = $drive->item($testfolder), "Look for old '$testfolder'";
  if ($old_folder->exists) {
    is $old_folder->remove, $old_folder, "Remove '$testfolder'";
  }

  note 'Create folder';
  ok my $folder = $drive->item($testfolder), 'Get test folder';
  isa_ok $folder, 'Nuvol::Item';
  test_folder_applied $folder, $service; 

  return $folder;
}

sub test_basics ($folder, $service) {
  note 'Basics';

  test_metadata_methods $folder, $service;
}

sub test_cd ($folder, $service) {
  note 'CD';

  is $folder->make_path, $folder, 'Create folder';
  test_folder_methods $folder, $service;

  is $folder->remove_tree, $folder, 'Remove folder';
  ok !$folder->exists, 'Folder doesn\'t exist';
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::ConnectorLive - Live test functions for Nuvol folders

=head1 SYNOPSIS

    use Nuvol::Test::FolderLive ':all';
    use Nuvol::Test::FolderLive ':build';    # build_test_folder

    my $folder = build_test_folder $service;

    test_basics;
    test_cd;

=head1 DESCRIPTION

L<Nuvol::Test::Connector> provides live test functions for Nuvol folders.

The tests are skipped if the environment variables for the different services are not set or don't
point to an existing folder. The variable names are C<NUVOL_DUMMY_LIVE>, C<NUVOL_OFFICE365_LIVE>.

See L<ConnectorLive|Nuvol::Test::ConnectorLive/DESCRIPTION> for instructions how to activate live
tests.

=head1 FUNCTIONS

=head2 build_test_folder

    $folder = build_test_folder $service;

Returns a L<Nuvol::Folder> for the specified service, using the config folder defined in the environment
variable.

=head2 test_basics

    test_basics $folder, $service;

Tests the basic functionality of the folder.

=head2 test_cd

    test_crud $folder, $service;

Tries to create and delete a folder.

=head1 SEE ALSO

L<Nuvol::Folder>, L<Nuvol::Test>, L<Nuvol::Test::Folder>.

=cut
