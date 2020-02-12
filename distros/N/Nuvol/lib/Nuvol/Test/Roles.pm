package Nuvol::Test::Roles;
use Mojo::Base -base, -signatures;

use Exporter 'import';
our @EXPORT      = ();
our @EXPORT_OK   = ();
our %EXPORT_TAGS = (all => \@EXPORT_OK);
for my $role (qw|file folder metadata|) {
  push @EXPORT_OK, map {"test_${role}_$_"} qw|applied methods prerequisites|;
  $EXPORT_TAGS{$role} = [map {"test_${role}_$_"} qw|applied methods prerequisites|];
}

use Test::More;

my $obj_regex = qr/^Nuvol::([^:_]*)/;

# File

my @file_required = qw|_do_remove _do_slurp _do_spurt _from_file _from_host _from_url _get_download_url _to_host|;

sub test_file_applied ($object, $service) {
  my $role = "Nuvol::${service}::File";

  note 'File role';

  is $object->SERVICE, $service, "Service is $service";
  is $object->type, 'File', 'Type is File';
  ok $object->does($role), "Role $role applied";
  ok $object->does('Nuvol::Role::File'), 'File role applied';
}

sub test_file_prerequisites ($service) {
  my $role = "Nuvol::${service}::File";

  note 'Prerequisites for File';

  use_ok $role or BAIL_OUT "Unable to load $role";
  can_ok $role, $_ for @file_required;
}

sub test_file_methods ($object, $service) {
  note 'File';
}

# Folder

my @folder_required = qw|_do_make_path _do_remove_tree|;

sub test_folder_applied ($object, $service) {
  my $role = "Nuvol::${service}::Folder";

  note 'Folder role';

  is $object->SERVICE, $service, "Service is $service";
  is $object->type, 'Folder', 'Type is Folder';
  ok $object->does($role), "Role $role applied";
  ok $object->does('Nuvol::Role::Folder'), 'Folder role applied';
}

sub test_folder_prerequisites ($service) {
  my $role = "Nuvol::${service}::Folder";

  note 'Prerequisites for Folder';

  use_ok $role or BAIL_OUT "Unable to load $role";
  can_ok $role, $_ for @folder_required;
}

sub test_folder_methods ($object, $service) {
  note 'Folder';
}

# Metadata

my @metadata_methods  = qw|metadata description id name url|;
my @metadata_required = qw|_build_url _get_description _get_name _load_metadata|;

sub test_metadata_applied ($object, $service) {
  ref($object) =~ $obj_regex;
  my $role = "Nuvol::${service}::$1";

  note 'Metadata role';

  is $object->SERVICE, $service, "Service is $service";
  ok $object->does($role), "Role $role applied";

  ok $object->does('Nuvol::Role::Metadata'), "Metadata role applied";
  ok my $url = $object->url('abc99', 'def88'), 'Returns URL';
  isa_ok $url, 'Mojo::URL';
  is $url->path->[-1], 'def88', 'Path is extended';
}

sub test_metadata_methods ($object, $service) {
  note 'Metadata';
  ok $object->$_, "$_ returns a value" for grep !/id/, @metadata_methods;
}

sub test_metadata_prerequisites ($package, $service) {
  $package =~ $obj_regex;
  my $role = "Nuvol::${service}::$1";

  note 'Prerequisites for Metadata';

  use_ok $role or BAIL_OUT "Unable to load $role";
  can_ok $role, $_ for @metadata_required;
}

1;

=encoding utf8

=head1 NAME

Nuvol::Test::Roles - Test functions for Nuvol roles

=head1 SYNOPSIS

    # File
    use Nuvol::Test::Roles ':file';

    test_file_prerequisites;
    test_file_applied;
    test_file_methods;

    # Metadata
    use Nuvol::Test::Roles ':metadata';

    test_metadata_prerequisites;
    test_metadata_applied;
    test_metadata_methods;

=head1 DESCRIPTION

L<Nuvol::Test::Roles> provides test functions for Nuvol roles.

=head1 FUNCTIONS

=head2 test_file_applied

    test_file_applied $object, $service;

Tests if the L<File|Lib::Nuvol::Role::File> role and the service file role are applied.

=head2 test_file_methods

    test_file_methods $object, $service;    # live tests only

Tests if the L<File methods|Lib::Nuvol::Role::File/METHODS> return values.

=head2 test_file_prerequisites

    test_file_prerequisites $package, $service;

Tests if all the prerequisites for the L<File|Lib::Nuvol::Role::File> and the service file roles are met.

=head2 test_folder_applied

    test_folder_applied $object, $service;

Tests if the L<Folder|Lib::Nuvol::Role::Folder> role and the service folder role are applied.

=head2 test_folder_methods

    test_folder_methods $object, $service;    # live tests only

Tests if the L<Folder methods|Lib::Nuvol::Role::Folder/METHODS> return values.

=head2 test_folder_prerequisites

    test_folder_prerequisites $package, $service;

Tests if all the prerequisites for the L<Folder|Lib::Nuvol::Role::Folder> and the service folder roles are met.

=head2 test_metadata_applied

    test_metadata_applied $object, $service;

Tests if the L<Metadata|Lib::Nuvol::Role::Metadata> role is applied.

=head2 test_metadata_methods

    test_metadata_methods $object, $service;    # live tests only

Tests if the L<Metadata methods|Lib::Nuvol::Role::Metadata/METHODS> return values.

=head2 test_metadata_prerequisites

    test_metadata_prerequisites $package, $service;

Tests if all the prerequisites for the L<Metadata|Lib::Nuvol::Role::Metadata> role are met.

=head1 SEE ALSO

L<Nuvol::Test>, L<Nuvol::Test::Connector>, L<Nuvol::Test::Drive>, L<Nuvol::Test::Item>.

=cut
