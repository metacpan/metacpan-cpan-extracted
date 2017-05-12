package PkgForge::Builder;    # -*-perl-*-
use strict;
use warnings;

# $Id: Builder.pm.in 16589 2011-04-05 10:42:02Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16589 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Builder.pm.in $
# $Date: 2011-04-05 11:42:02 +0100 (Tue, 05 Apr 2011) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use File::Path ();
use File::Spec ();
use File::Temp ();
use PkgForge::BuildTopic ();
use PkgForge::SourceUtils ();

use Moose::Role;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(Bool Int Str);
use Readonly;

requires 'run', 'submit_packages', 'verify_environment';

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

has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 0,
    builder  => 'build_name',
    lazy     => 1,
    documentation => 'The name of the platform',
);

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

has 'logdir' => (
    is            => 'ro',
    isa           => Str,
    required      => 1,
    documentation => 'The directory for log files',
);

has 'resultsdir' => (
    is            => 'ro',
    isa           => Str,
    required      => 1,
    documentation => 'The directory for build job results',
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

sub stringify {
    my ($self) = @_;
    return $self->name;
}

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

sub new_topic {
    my ( $self, $job ) = @_;

    my $job_resultsdir = PkgForge::Utils::job_resultsdir( $self->resultsdir,
                                                          $job->id );

    my $topic_resultsdir = File::Spec->catdir( $job_resultsdir, $self->name );

    if ( !-d $topic_resultsdir ) {
        my $ok = eval { File::Path::mkpath($topic_resultsdir) };
        if ( !$ok || $EVAL_ERROR ) {
            die "Failed to create directory $topic_resultsdir: $EVAL_ERROR\n";
        }
    }

    my $topic_logdir
      = File::Spec->catdir( $self->logdir, $self->name, $job->id );

    if ( !-d $topic_logdir ) {
        my $ok = eval { File::Path::mkpath($topic_logdir) };
        if ( !$ok || $EVAL_ERROR ) {
            die "Failed to create directory $topic_logdir: $EVAL_ERROR\n";
        }
    }

    my @sources = $self->filter_sources($job);

    my $topic = PkgForge::BuildTopic->new( job        => $job,
                                           resultsdir => $topic_resultsdir,
                                           logdir     => $topic_logdir,
                                           debug      => $self->debug,
                                           sources    => [@sources] );

    return $topic;
}

sub build {
    my ( $self, $job ) = @_;

    my $topic = $self->new_topic($job);

    my $run_result = eval { $self->run($topic) };
    if ( !$run_result || $EVAL_ERROR ) {
        $topic->finish();
        if ($EVAL_ERROR) {
            die $EVAL_ERROR; # rethrow
        } else {
            return 0;
        }
    }

    my $submit_result = eval { $self->submit_packages($topic) };
    if ( !$submit_result || $EVAL_ERROR ) {
        $topic->finish();
        if ($EVAL_ERROR) {
            die $EVAL_ERROR; # rethrow
        } else {
            return 0;
        }
    }

    $topic->finish();

    return 1;
}

1;
__END__

=head1 NAME

PkgForge::Builder - A Moose role to be used by PkgForge builders.

=head1 VERSION

     This documentation refers to PkgForge::Builder version 1.1.10

=head1 SYNOPSIS

     package PkgForge::Builder::Foo;

     use Moose;

     with 'PkgForge::Builder';

     sub verify_environment { ... }

     sub run { ... }

     sub submit_packages { ... }

=head1 DESCRIPTION

This is a role which gathers common functionality and sets some
requirements on how a Package Forge builder class must be implemented.

=head1 ATTRIBUTES

The following attributes will be part of any class which implements
this role:

=over

=item resultsdir

This is the location of the directory into which results will be
stored. This is the top-level directory, within this directory there
will be a sub-directory for each job and within that a sub-directory
for each task. This attribute must be specified.

=item logdir

This is the location of the directory into which the log file for the
builds will be stored. This attribute must be specified. After
completion of the build the log file will be copied to the specific
results directory.

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

=item build( $job, $resultsdir )

This method takes a L<PkgForge::Job> object and the base results
directory into which build results and log files are stored. These are
passed into the C<new_topic> method and then the newly created
BuildTopic is passed to the C<run> method (which must be implemented
by each class). If the run method returns successfully then the
C<submit_packages> method (which must also be implemented by each
class) is also called with the BuildTopic object.

=item new_topic( $job, $resultsdir )

This method takes a L<PkgForge::Job> object and the base results
directory into which build results and log files are stored. Within
this directory a job/build specific directory tree will be assembled
along the lines of C<uuid/platform-arch/>
(e.g. C<i8Mq2Q0nRaG171vp1FpLxw/f13-i386/>). This method returns a
L<PkgForge::BuildTopic> object which is a simple container for various
information related to building a particular job on a particular
platform and architecture. Most builder methods which do work expect
to receive a BuildTopic object.

=item filter_sources($job)

This method takes the L<PkgForge::Job> object and filters the source
packages to find those which are suitable for this builder. For
example, if the builder only accepts SRPMs then a list of only those
packages which are in the L<PkgForge::Source::SRPM> class will be
returned.

=back

This role requires that any implementing class provides the following
methods:

=over

=item verify_environment()

This method should validate the build environment and return 1 if
everything is correct. If a problem is found the method should die
with a useful message.

=item run($topic)

This is the main method which does the work of building the packages
from source. It receives the L<PkgForge::BuildTopic> object.

=item submit_packages($topic)

This method is used for submitting the built packages to the specified
results directory. You need to pass in an L<PkgForge::BuildTopic>
object.

=back

=head1 CONFIGURATION AND ENVIRONMENT

This module does not use any configuration files. You will need to
install the correct build tools for the target platform (see the
information in the documentation for the specific module you require).

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::Types>.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Builder::RPM>, L<PkgForge::BuildTopic>

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
