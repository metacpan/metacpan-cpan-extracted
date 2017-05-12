package PkgForge::BuildInfo;
use strict;
use warnings;

use File::Spec ();
use Sys::Hostname ();

use Moose;
use MooseX::Types::Moose qw(Bool Int Str);
use PkgForge::Types qw(SourcePackageList);
use PkgForge::SourceUtils ();

with 'PkgForge::YAMLStorage';

has '+yamlfile' => ( default => 'buildinfo.yml' );

has 'builder' => (
  traits   => ['PkgForge::Serialise'],
  is       => 'rw',
  isa      => Str,
);

has 'platform' => (
  traits   => ['PkgForge::Serialise'],
  is       => 'rw',
  isa      => Str,
);

has 'architecture' => (
  traits   => ['PkgForge::Serialise'],
  is       => 'rw',
  isa      => Str,
);

has 'hostname' => (
  traits   => ['PkgForge::Serialise'],
  is       => 'rw',
  isa      => Str,
  required => 1,
  default  => sub { Sys::Hostname::hostname }
);

has 'starttime' => (
  traits   => ['PkgForge::Serialise'],
  is       => 'rw',
  isa      => Int,
  required => 1,
  default  => sub { time },
);

has 'endtime' => (
  traits   => ['PkgForge::Serialise'],
  is       => 'rw',
  isa      => Int,
  required => 1,
  lazy     => 1,
  default  => sub { time },
);

has 'jobid' => (
  traits   => ['PkgForge::Serialise'],
  is  => 'rw',
  isa => Str,
);

has 'sources' => (
  traits     => ['Array','PkgForge::Serialise'],
  is         => 'rw',
  isa        => SourcePackageList,
  default    => sub { [] },
  handles    => {
    sources_list  => 'elements',
    sources_count => 'count',
  },
  pack       => sub { PkgForge::SourceUtils::pack_packages($_[0]) },
  unpack     => sub { PkgForge::SourceUtils::unpack_packages($_[0]) },
  documentation => 'The set of source packages to be built',
);

has 'success' => (
  traits     => [ 'Array', 'PkgForge::Serialise' ],
  is         => 'rw',
  isa        => SourcePackageList,
  default    => sub { [] },
  handles    => {
    has_success   => 'count',
    success_count => 'count',
  },
  pack       => sub { PkgForge::SourceUtils::pack_packages($_[0]) },
  unpack     => sub { PkgForge::SourceUtils::unpack_packages($_[0]) },
  documentation => 'The set of source packages successfully built',
);

has 'failures' => (
  traits     => [ 'Array', 'PkgForge::Serialise' ],
  is         => 'rw',
  isa        => SourcePackageList,
  default    => sub { [] },
  handles    => {
    has_failures  => 'count',
    failure_count => 'count',
  },
  pack       => sub { PkgForge::SourceUtils::pack_packages($_[0]) },
  unpack     => sub { PkgForge::SourceUtils::unpack_packages($_[0]) },
  documentation => 'The set of source packages which failed to build',
);

has 'products' => (
  traits  => [ 'Array', 'PkgForge::Serialise' ],
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
  handles => {
    products_list => 'elements',
    add_products  => 'push',
  },
  pack    => sub { basename_only($_[0]) },
  documentation => 'The products of building the job',
);

has 'logs' => (
  traits  => [ 'Array', 'PkgForge::Serialise' ],
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
  handles => {
    logs_list => 'elements',
    add_logs  => 'push',
  },
  pack    => sub { basename_only($_[0]) },
  documentation => 'The log files from building the job',
);

has 'phases' => (
  traits  => ['Array','PkgForge::Serialise' ],
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  default => sub { ['init'] },
  handles => {
    phases_list   => 'elements',
    phase_reached => 'push',
  },
  documentation => 'Which phase in the build process has been reached',
);

has 'completed' => (
  traits  => ['PkgForge::Serialise'],
  is      => 'rw',
  isa     => Bool,
  default => 0,
  documentation => 'A boolean which indicates whether the job completed',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub basename_only { [ map { (File::Spec->splitpath($_))[2] } @{$_[0]} ] }

sub built_successfully {
  my ($self) = @_;

  return ( $self->has_success && !$self->has_failures );
}

sub last_phase {
  my ($self) = @_;

  my $last_phase = ($self->phases_list)[-1];

  return $last_phase;
}

sub source_files {
  my ($self) = @_;

  # We are only interested in the file names (i.e. the basename part)
  # not the full path.

  # There is a chance that the same filename may be in more than one
  # source object so uniqueify using a hash.

  my %files;
  for my $source ($self->sources_list) {
    my $file = $source->file;
    $files{$file} = 1;
  }

  # Sort so that we always return the same list of strings for the
  # same sources list.

  my @files = sort keys %files;

  return @files;
}

1;
__END__
