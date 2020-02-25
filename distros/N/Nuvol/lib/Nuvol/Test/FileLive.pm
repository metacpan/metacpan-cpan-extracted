package Nuvol::Test::FileLive;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT      = ();
our @EXPORT_OK   = qw|build_test_file test_basics test_copy test_crud|;
our %EXPORT_TAGS = (all => \@EXPORT_OK, build => ['build_test_file']);

use FindBin;
use Mojo::File 'path';
use Mojo::URL;
use Nuvol::Test::Roles qw|:file :metadata|;
use Nuvol::Test::DriveLive ':build';
use Test::More;

my $testfile1     = '/Nuvol Testfile 1.txt';
my $testfile2     = '/Nuvol Testfile 2.txt';
my $host_testfile = '../resources/Testfile.txt';
my $web_testfile  = 'https://nuvol.ch/Testfile.txt';
my $web_content = "This file was downloaded from https://nuvol.ch.\n";

sub build_test_file ($service) {
  note "Create test file for $service";

  ok my $drive = build_test_drive($service), 'Create test drive';

  note 'Cleanup';
  for my $filename ($testfile1, $testfile2) {
    ok my $old_file = $drive->item($filename), "Look for old '$filename'";
    if ($old_file->exists) {
      is $old_file->remove, $old_file, "Remove '$filename'";
    }
  }

  note 'Create file';
  ok my $file = $drive->item($testfile1), 'Get test file';
  isa_ok $file,            'Nuvol::Item';
  test_file_applied $file, $service;

  return $file;
}

sub test_basics ($file, $service) {
  note 'Basics';

  test_metadata_methods $file, $service;
}

sub test_copy ($file, $service) {
  note 'Copy';

  ok my $host_file    = path("$FindBin::Bin/$host_testfile"), 'Create test file on host';
  ok my $host_content = $host_file->slurp, 'Read original content';
  is $file->copy_from($host_file), $file, 'Upload file from host';
  is $file->slurp, $host_content, 'Content is identical';

  ok my $copy = $file->copy_to($testfile2), 'Copy to second file on drive';
  is $copy->slurp, $host_content, 'Content is identical';

  ok my $tempfile = Mojo::File::tempfile, 'Create temporary file';
  is $file->copy_to($tempfile), $tempfile, 'Download to host';
  is $tempfile->slurp, $host_content, 'Content is identical';

  ok my $url = Mojo::URL->new($web_testfile), 'URL for web testfile';
  is $file->copy_from($url), $file, 'Download from URL';
  is $file->slurp, $web_content, 'Content is identical';

  eval { $file->copy_to($url); };
  like $@, qr/Mojo::URL.*not supported/, 'Can\'t copy to URL';
  eval { $file->copy_to($file->drive); };
  like $@, qr/Nuvol::Drive.*not supported/, 'Can\'t copy to other objects';
  eval { $file->copy_from('A folder/'); };
  like $@, qr/not a file/, 'Can\'t copy from folder';
  eval { $file->copy_from($file->drive); };
  like $@, qr/Nuvol::Drive.*not supported/, 'Can\'t copy from other objects';

  is $file->remove, $file, 'Remove file';
  is $copy->remove, $copy, 'Remove copy';
}

sub test_crud ($file, $service) {
  note 'CRUD';

  my $teststring1 = 'A Nuvol testfile.';
  my $teststring2 = 'This text was changed.';

  is $file->spurt($teststring1), $file, 'Write text to file';
  test_file_methods $file, $service;
  ok my $url = $file->download_url, 'File has a download URL';
  isa_ok $url, 'Mojo::URL';
  is $file->slurp, $teststring1, 'Read content';

  is $file->spurt($teststring2), $file, 'Write another text';
  is $file->slurp, $teststring2, 'Content has changed';

  is $file->remove, $file, 'Remove file';
  ok !$file->exists, 'File doesn\'t exist';
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::ConnectorLive - Live test functions for Nuvol files

=head1 SYNOPSIS

    use Nuvol::Test::FileLive ':all';
    use Nuvol::Test::FileLive ':build';    # build_test_file

    my $file = build_test_file $service;

    test_basics;
    test_crud;
    test_copy;

=head1 DESCRIPTION

L<Nuvol::Test::Connector> provides live test functions for Nuvol files.

The tests are skipped if the environment variables for the different services are not set or don't
point to an existing file. The variable names are C<NUVOL_DUMMY_LIVE>, C<NUVOL_OFFICE365_LIVE>.

See L<ConnectorLive|Nuvol::Test::ConnectorLive/DESCRIPTION> for instructions how to activate live
tests.

=head1 FUNCTIONS

=head2 build_test_file

    $file = build_test_file $service;

Returns a L<Nuvol::File> for the specified service, using the config file defined in the environment
variable.

=head2 test_basics

    test_basics $file, $service;

Tests the basic functionality of the file.

=head2 test_copy

    test_copy $file, $service;

Tests copying, up- and downloading.

=head2 test_crud

    test_crud $file, $service;

Tries to create, read, update, and delete a file.

=head1 SEE ALSO

L<Nuvol::File>, L<Nuvol::Test>, L<Nuvol::Test::File>.

=cut
