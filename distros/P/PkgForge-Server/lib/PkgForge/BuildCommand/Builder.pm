package PkgForge::BuildCommand::Builder;    # -*-perl-*-
use strict;
use warnings;

# $Id: Queue.pm.in 13577 2010-08-26 08:34:57Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 13577 $
# $HeadURL: https://svn.lcfg.org/svn/source/trunk/PkgForge/lib/PkgForge/Queue.pm.in $
# $Date: 2010-08-26 09:34:57 +0100 (Thu, 26 Aug 2010) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use File::Path ();
use File::Spec ();
use File::Temp ();
use PkgForge::SourceUtils ();

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(Bool Int Str);
use Readonly;

with 'PkgForge::BuildCommand' => { -excludes => [  'build_name' ] };

requires 'build';

enum 'PkgForgeErrorPolicy' => [qw/immediate retry/];

Readonly my %SOURCE_TYPES =>
  map { $_ => 1 } PkgForge::SourceUtils::list_source_types();

subtype 'PkgForgeSourceType'
  => as Str,
  => where { exists $SOURCE_TYPES{$_} };

subtype 'PkgForgeSourceTypeList'
  => as 'ArrayRef[PkgForgeSourceType]';

coerce 'PkgForgeSourceTypeList'
  => from Str
  => via { [$_] };

has 'platform' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    documentation => 'The platform to build on',
);

has 'architecture' => (
    is        => 'ro',
    isa       => Str,
    required  => 0,
    predicate => 'has_architecture',
    documentation => 'The architecture to build on',
);

has 'timeout' => (
    is        => 'ro',
    isa       => Int,
    default   => 600, # 10 minutes
    documentation => 'Time after which a build job should be killed',
);

has 'accepts' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'PkgForgeSourceTypeList',
    required => 1,
    coerce   => 1,
    handles  => {
        list_acceptable_types => 'elements',
    },
    documentation => 'The type of source packages accepted by the builder',
);

has 'error_policy' => (
    is      => 'ro',
    isa     => 'PkgForgeErrorPolicy',
    default => 'retry',
    documentation => 'Response type on package build failure',
);

has 'debug' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
    documentation => 'Turn on the printing of debug statements',
);

subtype 'FileTempDir' => as class_type('File::Temp::Dir');

has 'tmpdir' => (
    is       => 'ro',
    isa      => 'Str|FileTempDir',
    required => 1,
    default  => sub {
        return File::Temp->newdir( 'pkgforge-XXXXX',
                                   TMPDIR  => 1,
                                   CLEANUP => 1 );
    },
    documentation => 'Temporary directory'
);

no Moose::Role;

sub build_name {
    my ($self) = @_;

    my $name;
    if ( $self->has_architecture ) {
        $name = join q{-}, $self->platform, $self->architecture;
    } else {
        $name = $self->platform;
    }

    return $name;
}

sub filter_sources {
    my ( $self, $job ) = @_;

    my @sources;
    for my $type ($self->list_acceptable_types) {
        my @matches = $job->filter_packages( sub { $_->type eq $type } );
        push @sources, @matches;
    }

    return @sources;
}

sub register_info {
  my ( $self, $job, $buildinfo ) = @_;

  # Add the builder information to the buildinfo object

  $buildinfo->platform($self->platform);
  if ( $self->has_architecture ) {
    $buildinfo->architecture($self->architecture);
  }

  return
}

sub run {
    my ( $self, $job, $buildinfo, $buildlog ) = @_;

    my $logger = $buildlog->logger;

    $self->register_info( $job, $buildinfo );

    my @sources = $self->filter_sources($job);
    if ( scalar @sources == 0 ) {
      return;
    }

    $buildinfo->sources(\@sources);

    my $run_result = eval { $self->build( $job, $buildinfo, $buildlog ) };
    if ( !$run_result || $EVAL_ERROR ) {
        if ($EVAL_ERROR) {
            die $EVAL_ERROR; # rethrow
        } else {
            return 0;
        }
    }

    return 1;
}

1;
__END__

=head1 NAME

PkgForge::BuildCommand::Builder - A Moose role to be used by PkgForge builders.

=head1 VERSION

     This documentation refers to PkgForge::Builder version 1.1.10

=head1 SYNOPSIS

     package PkgForge::BuildCommand::Builder::Foo;

     use Moose;

     with 'PkgForge::BuildCommand::Builder';

     sub verify_environment { ... }

     sub build { ... }

=head1 DESCRIPTION

This is a role which gathers common functionality and sets some
requirements on how a Package Forge builder class must be implemented.

=head1 ATTRIBUTES

The following attributes will be part of any class which implements
this role:

=over

=item tmpdir

This is a secure location which can be used for generating temporary
files during the build process. If nothing is specified then the
L<File::Temp> module will be used to generate a randomly named
directory which will be cleaned up at the end of the process.

=item platform

This is the name of the platform for which the builder is being
used, for example, C<f13> or C<sl5>. This is a required attribute.

=item architecture

This is the name of the architecture for which the builder is being
used, for example, C<i386> or C<x86_64>. This does have any
significance on some platforms so it is an optional attribute.

=item name

This is the name of the builder process. Normally you do not need to
set this attribute, the default is the combination of the platform and
architecture (if set) joined with a hyphen, e.g. platform C<f13> and
architecture C<x86_64> gives a name of C<f13-x86_64>.

=item timeout

This is the maximum time (in seconds) that the build process is
allowed to take. Any process still running after this time should be
killed.

=item error_policy

This is a string used to record the required response to any source
package build errors. The currently supported values are C<retry> and
C<immediate>. In immediate-mode the builder will stop as soon as any
source package in the job fails to build. The default is retry-mode in
which the builder will keep attempting to build more packages for the
job as long as more build each time. This is very useful as it is
often the situation that a job contains a set of packages where some
of them have build-dependencies on others. Ordering them manually
might be difficult so in the retry-mode although the job might take a
bit longer to build there is an improved chance of complete success.

=back

=head1 SUBROUTINES/METHODS

The following methods are available to all classes which implement
this role:

=over

=item run( $job, $buildinfo )

This method takes a L<PkgForge::Job> object and a
L<PkgForge::BuildInfo> object. The run method registers the builder
information into the BuildInfo object (using C<register_info>) and
filters the sources (using C<filter_sources>). The Job and BuildInfo
objects are then passed into the C<build> method (which must be
implemented by each class).

=item filter_sources($job)

This method takes the L<PkgForge::Job> object and filters the source
packages to find those which are suitable for this builder. For
example, if the builder only accepts SRPMs then a list of only those
packages which are in the L<PkgForge::Source::SRPM> class will be
returned.

=item register_info( $job, $buildinfo )

=back

This role requires that any implementing class provides the following
methods:

=over

=item verify_environment()

This method should validate the build environment and return 1 if
everything is correct. If a problem is found the method should die
with a useful message.

=item build( $job, $buildinfo )

This is the main method which does the work of building the packages
from source. It receives a L<PkgForge::Job> object and a
L<PkgForge::BuildInfo> object which contains the list of sources to be
built. On completion the method is expected to register successful and
failed packages, and also all the products and log files generated by
the build with the BuildInfo object. See the L<PkgForge::BuildInfo>
documentation for API information.

=back

=head1 CONFIGURATION AND ENVIRONMENT

This module does not use any configuration files. You will need to
install the correct build tools for the target platform (see the
information in the documentation for the specific module you require).

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::Types>.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Job>, L<PkgForge::Builder::RPM>, L<PkgForge::BuildInfo>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux5, Fedora13

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2010-2011 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
