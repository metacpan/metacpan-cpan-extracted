package PkgForge::BuildTopic;    # -*-perl-*-
use strict;
use warnings;

# $Id: BuildTopic.pm.in 16580 2011-04-05 10:03:29Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16580 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/BuildTopic.pm.in $
# $Date: 2011-04-05 11:03:29 +0100 (Tue, 05 Apr 2011) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use File::Copy ();
use File::Spec ();

use Moose;
use MooseX::Types::Moose qw(Bool Str);
use PkgForge::Types qw(SourcePackageList);

with 'MooseX::LogDispatch';

has 'debug' => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
    documentation => 'Turn on the printing of debug statements',
);

has 'job' => (
    is       => 'ro',
    isa      => 'PkgForge::Job',
    required => 1,
    handles  => [qw/bucket/],
    documentation => 'The job to be built',
);

has 'resultsdir' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    documentation => 'Where the results and log files for a build job should be stored'
);

has 'logfile' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    lazy     => 1,
    default  => sub {
        my $self = shift @_;
        my $logfile = File::Spec->catfile( $self->logdir,
                                           'pkgforge-build.log' );
    },
    documentation => 'The PkgForge build log file',
);

has 'logdir' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    documentation => 'Where the pkgforge build log will be stored'
);

has 'sources' => (
    traits     => ['Array'],
    is         => 'rw',
    isa        => SourcePackageList,
    default    => sub { [] },
    handles    => {
        'sources_list' => 'elements',
    },
    documentation => 'The set of source packages to be built',
);

has 'log_dispatch_conf' => (
    is       => 'ro',
    isa      => 'HashRef',
    lazy     => 1,
    required => 1,
    default  => sub {
        my $self = shift;

        return {
            class          => 'Log::Dispatch::File',
            min_level      => 'debug',
            filename       => $self->logfile,
            mode           => 'append',
            format         => '[%d] [%p] %m%n',
            close_on_write => 1,
        };
    },
    documentation => 'The configuration for Log::Dispatch',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub store_logs {
    my ( $self, @files ) = @_;

    my $logger = $self->logger;

    my $resultsdir = $self->resultsdir;

    for my $file (@files) {
        if ($self->debug) {
            $logger->debug("Storing $file in $resultsdir");
        }
        File::Copy::copy( $file, $resultsdir )
          or $logger->log_and_die(
              level   => 'critical',
              message => "Could not copy $file to $resultsdir: $OS_ERROR"
          );
    }

    return 1;
}

sub store_results {
    my ( $self, @files ) = @_;

    my $logger = $self->logger;

    my $resultsdir = $self->resultsdir;

    for my $file (@files) {
        if ($self->debug) {
            $logger->debug("Storing $file in $resultsdir");
        }
        File::Copy::copy( $file, $resultsdir )
          or $logger->log_and_die(
              level   => 'critical',
              message => "Could not copy $file to $resultsdir: $OS_ERROR"
          );
    }

    return 1;
}

sub finish {
    my ($self) = @_;

    my $logfile    = $self->logfile;
    my $resultsdir = $self->resultsdir;

    if ( -f $logfile ) {
        File::Copy::copy( $logfile, $resultsdir )
          or die "Could not copy $logfile to $resultsdir: $OS_ERROR\n";
    }

    return 1;
}



1;
__END__

=head1 NAME

PkgForge::BuildTopic - A PkgForge class to represent the current build task

=head1 VERSION

This documentation refers to PkgForge::BuildTopic version 1.1.10

=head1 SYNOPSIS

     use PkgForge::BuildTopic;

     my $topic = PkgForge::BuildTopic->new( job        => $job,
                                            resultsdir => $results,
                                            sources    => \@sources );

     $topic->logger->info('Hello World');

     $topic->store_logs(@files);

     $topic->store_results(@rpms);

=head1 DESCRIPTION

This class is designed to be used internally by L<PkgForge::Builder>
classes. It exists purely for convenience to simplify passing around
all the information necessary for building the current Job on a
particular platform. It has methods for storing the generated files
into the correct locations for a job on a particular platform.

=head1 ATTRIBUTES

=over

=item job

This is the L<PkgForge::Job> object for the current task. This
attribute must be specified.

=item logdir

This is the directory into which pkgforge logs for a build task should
be stored whilst the job is being built. This directory should be on a
local file system. Once the task is finished the logfile will be
copied to the results directory for the specific task (which may be on
a network filesystem).

=item resultsdir

This is the directory into which results and log files will be stored
for this particular build of this job on a platform. This attribute
must be specified.

=item sources

This is a reference to an array of L<PkgForge::Source> objects which
will be built for this task. They should be a subset of Source objects
from the specified Job which are of the applicable type for the
current Builder but no validity checks are done.

=item debug

This is a boolean which controls whether debugging messages are
printed. The default is false (i.e. no debug messages).

=back

=head1 SUBROUTINES/METHODS

=over

=item logger

This is a L<Log::Dispatch> object which can be used to send log
messages to the correct location for the current build job on a
particular platform.

=item store_logs(@files)

This method will store the specified list of log files into the
correct location for the current job on the current build platform.

=item store_results(@files)

This method will store the specified list of package files into the
correct location for the current job on the current build platform.

=item finish()

This method can be used when you are finished with the build topic. It
will copy the pkgforge build log file into the results directory for
the task.

=back

=head1 CONFIGURATION AND ENVIRONMENT

This module does not use any configuration files.

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::Types> and
L<Moose::LogDispatch>.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Builder>, L<PkgForge::Builder::RPM>

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
