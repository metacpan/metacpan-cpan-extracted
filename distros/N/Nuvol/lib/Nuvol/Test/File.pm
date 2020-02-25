package Nuvol::Test::File;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT      = ();
our @EXPORT_OK   = qw|build_test_file test_basics|;
our %EXPORT_TAGS = (all => \@EXPORT_OK, build => ['build_test_file']);

use Test::More;
use Nuvol::Test::Drive ':build';
use Nuvol::Test::Roles ':file';

my $package          = 'Nuvol::Item';
my $package_role     = 'File';
my @internal_methods = qw||;

sub build_test_file ($service) {
  note "Create test file for $service";

  use_ok $package or BAIL_OUT "Unable to load $package";

  test_file_prerequisites $service;

  my $drive = build_test_drive $service;
  ok my $object = $package->new($drive, {path => '/Nuvol Testfile.txt', type => $package_role}),
    'Create object';

  return $object;
}

sub test_basics ($file, $service) {
  note 'Basics';

  can_ok $file, $_ for @internal_methods;

  test_file_applied $file, $service;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::File - Test functions for Nuvol files

=head1 SYNOPSIS

    use Nuvol::Test::File ':all';
    use Nuvol::Test::File ':build';    # build_test_file

    my $file = build_test_file $service;

    test_basics;

=head1 DESCRIPTION

L<Nuvol::Test::File> provides test functions for Nuvol files.

=head1 FUNCTIONS

=head2 build_test_file

    $file = build_test_file $service;

Returns a L<Nuvol::Item> with applied L<File|Nuvol::Role::File> roles for the specified service.

=head2 test_basics

    test_basics $file, $service;

Tests the basic structure of the file.

=head1 SEE ALSO

L<Nuvol::Role::File>, L<Nuvol::Test>, L<Nuvol::Test::FileLive>.

=cut
