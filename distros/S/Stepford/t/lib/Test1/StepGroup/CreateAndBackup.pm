## no critic (Modules::ProhibitMultiplePackages)
package Test1::StepGroup::CreateAndBackup;

use strict;
use warnings;

# two inner step classes in one step group file
# the inner steps are under the Test1::Step namespace
# the group package is under the Test1::StepGroup namespace

package Test1::Step::CreateAFile;

use namespace::autoclean;

use Stepford::Types qw( Dir File );

use Moose;

with 'Stepford::Role::Step::FileGenerator';

has tempdir => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
);

has inner_steps_test_original_file => (
    traits  => ['StepProduction'],
    is      => 'ro',
    isa     => File,
    lazy    => 1,
    default => sub { $_[0]->tempdir->file('foo.orig') },
);

sub run { $_[0]->inner_steps_test_original_file->touch }

package Test1::Step::BackupAFile;

use namespace::autoclean;

use Stepford::Types qw( Dir File );

use Moose;

with 'Stepford::Role::Step::FileGenerator';

has tempdir => (
    is       => 'ro',
    isa      => Dir,
    required => 1,
);

has inner_steps_test_original_file => (
    traits   => ['StepDependency'],
    is       => 'ro',
    isa      => File,
    required => 1,
);

has inner_steps_test_backup_file => (
    traits  => ['StepProduction'],
    is      => 'ro',
    isa     => File,
    lazy    => 1,
    default => sub { $_[0]->tempdir->file('foo.bak') },
);

sub run {
    my $self = shift;

    $self->inner_steps_test_original_file->copy_to(
        $self->inner_steps_test_backup_file );
}

__PACKAGE__->meta->make_immutable;

1;
