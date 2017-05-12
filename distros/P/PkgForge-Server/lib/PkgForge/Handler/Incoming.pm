package PkgForge::Handler::Incoming;    # -*-perl-*-
use strict;
use warnings;

# $Id: Incoming.pm.in 17739 2011-06-30 04:46:31Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 17739 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Handler/Incoming.pm.in $
# $Date: 2011-06-30 05:46:31 +0100 (Thu, 30 Jun 2011) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use File::Temp ();
use PkgForge::Job   ();
use PkgForge::Queue ();
use Try::Tiny;

use Readonly;
Readonly my $SECONDS_IN_MINUTE => 60;
Readonly my $TMPDIR_PERMS => oct('0750');

use Moose;
use MooseX::Types::Moose qw(Int);

extends 'PkgForge::Handler';

with 'PkgForge::Registry::Role';

has 'wait_for_job' => (
    is       => 'ro',
    isa      => Int,
    default  => 5 * $SECONDS_IN_MINUTE,    # 5 minutes in seconds
    required => 1,
    documentation => 'Time to wait in case job is still being submitted',
);

has '+logconf' => (
    default => '/etc/pkgforge/log-incoming.cfg',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub preflight  {
    my ($self) = @_;

    my $in_dir = $self->incoming;

    if ( !-d $in_dir ) {
        $self->logger->log_and_die(
            level   => 'critical',
            message => "Incoming jobs directory '$in_dir' does not exist",
        );
    }

    my $out_dir = $self->accepted;

    if ( !-d $out_dir ) {
        $self->logger->log_and_die(
            level   => 'critical',
            message => "Accepted jobs directory '$out_dir' does not exist",
        );
    }

    try {
      my $tmp = File::Temp->new(TEMPLATE => 'pkgforge-XXXX',
                                UNLINK   => 1,
                                DIR      => $out_dir );
      $tmp->print("test\n") or die "Failed to print to temp file: $OS_ERROR\n";
      $tmp->close or die "Could not close temp file: $OS_ERROR\n";
    } catch {
      $self->logger->log_and_die(
        level   => 'critical',
        message => "Accepted jobs directory '$out_dir' is not writable: $_",
      );
    };

    my $tmpdir = $self->tmpdir;

    $self->logger->debug("Temporary directory is $tmpdir");

    if ( !-d $tmpdir ) {
        my $ok = eval { File::Path::mkpath( $tmpdir, 0, $TMPDIR_PERMS ) };
        if ( !$ok || $EVAL_ERROR ) {
            $self->logger->log_and_die(
                level   => 'critical',
                message => "Could not create temporary directory '$tmpdir': $EVAL_ERROR"
            );
        }
    }

    chmod $TMPDIR_PERMS, $tmpdir or
      $self->logger->log_and_die(
        level   => 'critical',
        message => "Could not set permissions on temporary directory '$tmpdir': $OS_ERROR"
    );

    $ENV{TMPDIR} = $tmpdir;

    return 1;
}

sub execute {
    my ($self) = @_;

    my $queue = $self->load_queue;
    if ( !defined $queue ) {
      return;
    }

    for my $qentry ( $queue->entries ) {

        my $job = $self->load_job($qentry);
        if ( !defined $job ) {
            next;
        }

        my $ok = $self->validate_job($job);
        if ( !$ok ) {
            next;
        }

        my $accepted_job = $self->transfer_job($job);
        if ( !defined $accepted_job ) {
            next;
        }

        my $registered = $self->register_tasks($accepted_job);
        if ( !$registered ) {
            next;
        }

        $self->remove_from_incoming($job);
    }

    return;
}

sub load_queue {
    my ($self) = @_;

    my $in_dir = $self->incoming;

    # Load the queue of jobs

    my $queue = try {
      PkgForge::Queue->new(
        directory => $in_dir,
        logger    => $self->logger,
      );
    } catch {
      $self->logger->error( "Could not load a job queue from incoming directory '$in_dir': $_" );
      return;
    };

    if ( defined $queue ) {
      $queue->erase_cruft;

      if ( $self->debug ) {
        my $count = $queue->count_entries;
        $self->logger->debug("Found $count entries in the incoming queue");
      }
    }

    return $queue;
}

sub remove_from_incoming {
    my ( $self, $obj ) = @_;

    # This will take either a qentry or a job object, they can both do scrub()

    if ( $self->debug ) {
        $self->logger->debug("Scrubbing $obj from incoming queue");
    }

    my @errors;
    $obj->scrub( { error => \@errors } );
    if ( scalar @errors > 0 ) {
        $self->logger->error("Failed to erase incoming queue entry: @errors");
    }

    return;
}

sub load_job {
    my ( $self, $qentry ) = @_;

    $self->logger->notice("Processing $qentry");

    # We start with no failure set. It can be changed to either of:
    # 1. 'soft' - only a failure if the job is found to be overdue
    # 2. 'hard' - a complete failure

    my $fail = '';
    my $error_message;

    my $job = eval { PkgForge::Job->new_from_qentry($qentry) };

    if ( !$job || $EVAL_ERROR ) {
        $fail = 'soft';
        $error_message = $EVAL_ERROR;
        $self->log_problem("Failed to load job $qentry, will retry until timeout is reached");
    }

    # Check the job is not in the registry. If it is then we will
    # continue if the status is "incoming".

    my $exists_but_ok = 0;
    if ( !$fail ) {

        if ( $self->registry->job_exists($job) ) {
            my $status = eval { $self->registry->get_job_status($job) };
            if ( $status ne 'incoming' ) {
                $self->log_problem("A job with ID $job has been previously registered");
                $fail = 'hard';
            } else {
                $exists_but_ok = 1;
            }
        }
    }

    if ( !$fail && !$exists_but_ok ) {
        my $ok = eval { $self->registry->register_job($job) };

        if ( !$ok || $EVAL_ERROR ) {
            $self->log_problem( "Failed to add job $job to registry",
                                $EVAL_ERROR );
            $fail = 'hard';
        } else {
            $self->logger->notice("Registered job $job");
        }

    }

    if ($fail) {
        if ( $fail eq 'soft' &&
             $qentry->overdue( $self->wait_for_job ) ) {
            $fail = 'hard';
        }

        if ( $fail eq 'hard' ) {
            $self->log_problem( "Failed to load job $qentry", $error_message );
            $self->remove_from_incoming($qentry);
        }

        undef $job;
    }

    return $job;
}

sub validate_job {
    my ( $self, $job ) = @_;

    my $valid = eval { $job->validate() };

    if ( !$valid || $EVAL_ERROR ) {
        $self->log_problem( "Invalid job $job", $EVAL_ERROR );
        # Packages may still be in transit so not a full fail
        if ( $job->overdue( $self->wait_for_job ) ) {
            $self->update_job_status( $job, 'invalid' );
            $self->remove_from_incoming($job);
        }

        return 0;
    }

    $self->update_job_status( $job, 'valid' );
    $self->logger->notice("Validated job $job, will accept");

    return 1;
}

sub transfer_job {
    my ( $self, $job ) = @_;

    my $out_dir = $self->accepted;

    my $new_obj = eval { $job->transfer($out_dir) };
    if ( !$new_obj || $EVAL_ERROR ) {    # Full fail, no waiting about
        $self->log_problem( "Failed to transfer job $job to accepted queue",
                            $EVAL_ERROR );

        $self->update_job_status( $job, 'failed' );
        $self->remove_from_incoming($job);

        return;
    } else {
        $self->update_job_status( $job, 'accepted' );
        $self->logger->notice("Successfully accepted job $job");
    }

    return $new_obj;
}

sub register_tasks {
    my ( $self, $job ) = @_;

    my $ok = eval { $self->registry->register_tasks($job) };

    if ( !$ok || $EVAL_ERROR ) {
        $self->log_problem( "Failed to add tasks for job $job to registry",
                            $EVAL_ERROR );

        $self->update_job_status( $job, 'failed' );

        return 0;
    } else {
        $self->logger->notice("Registered tasks for $job");
    }

    return 1;
}

sub update_job_status {
    my ( $self, $job, $status ) = @_;

    my $ok = eval { $self->registry->update_job_status( $job, $status ) };

    if ( !$ok || $EVAL_ERROR ) {
        $self->log_problem( "Failed to update status for job $job to '$status'",
                            $EVAL_ERROR );
        $self->remove_from_incoming($job);

        return 0;
    } elsif ( $self->debug ) {
        $self->logger->debug("Updated status for $job to $status");
    }

    return 1;

}

1;
__END__

=head1 NAME

PkgForge::Handler::Incoming - Package Forge handler for the incoming directory

=head1 VERSION

     This documentation refers to PkgForge::Handler::Incoming version 1.1.10

=head1 SYNOPSIS

     use PkgForge::Handler::Incoming;

     my $handler = PkgForge::Handler::Incoming->new();

     # or
     my $handler = PkgForge::Handler::Incoming->new_with_options();

     # or
     my $handler = PkgForge::Handler::Incoming->new_with_config();

     $handler->execute();

=head1 DESCRIPTION

This Package Forge handler handles the incoming jobs queue. The
incoming queue is represented with a L<PkgForge::Queue> and is
processed in order of submission time. Any entry which does not look
like a job will be erased immediately. Anything else will be loaded as
a L<PkgForge::Job> object and validated. If the job is valid the
handler will move the job to the accepted queue and register the job
for the relevant build daemons.

=head1 ATTRIBUTES

See L<PkgForge::Handler> for all the attributes inherited by
application of that role. This class also adds the following
attributes:

=over

=item wait_for_job

The time (in seconds) to wait for a job to be considered fully
submitted, the default is 5 minutes. Submitted jobs are considered for
acceptance on every pass of the incoming queue made by this
handler. If the job appears to be incomplete for any reason this is
the length of time the handler will wait for further data to
appear. After this time has passed any incomplete job may be erased.

=back

=head1 SUBROUTINES/METHODS

See L<PkgForge::Handler> for all methods inherited from that
class. This class implements the required C<execute> method.

=over

=item execute()

=item preflight()

Runs through a set of pre-flight checks which must be correct before
running the C<execute> method. This is separated out so that it can be
called after the handler object is created but before the execution is
begun. This is particularly useful for when running as a daemon.

=item load_queue()

This method scans the incoming build job directory and loads anything
found into a L<PkgForge::Queue> object. If it is not possible to scan
the directory then this method will die since such a failure renders
this handler useless. It will remove anything which does not appear to
be a valid build job entry. The queue object will be returned.

=item load_job($qentry)

This method takes a L<PkgForge::Queue::Entry> object and attempts to
convert it into a full L<PkgForge::Job> object. If successfully loaded
the job will be registered in the Package Forge registry with a status
of C<incoming>. If the loading fails then a period of grace is given
in case the files associated with the job are still in transit. If the
failure continues to occur after the end of the grace period then the
submitted job will be deleted. On success the L<PkgForge::Job> object
will be returned, on failure (either temporary or permanent) the undef
value be returned.

=item validate_job($job)

This method takes a L<PkgForge::Job> object and carries out
validation. Mostly this validation it to ensure that the submitted job
has not been corrupted during the submission process. If successful
the job will be marked in the Package Forge registry as C<valid>. If
the job is found to be invalid then, in a similar way to the
C<load_job> method, a grace period is permitted. If the validation
failure continues to occur after the end of the grace period then the
submitted job will be deleted and marked in the registry as
C<invalid>. On success a true value will be returned, otherwise it
will return a false value.

Please note that this method does not do any authorization checks.

=item transfer_job($job)

This method takes a L<PkgForge::Job> object and attempts to transfer
the job to the C<accepted> directory. If successful then the job will
be marked as C<accepted> in the Package Forge registry and a new
L<PkgForge::Object> will be returned which represents the accepted
job. If the transfer fails then the submitted job will be deleted and
it will be marked in the registry as C<failed>, the method will then
return undef.

=item register_tasks($job)

A convenience wrapper for the method of the same name provided by
L<PkgForge::Registry>. Will log errors, returns false on failure and
true on success.

=item remove_from_incoming($object)

This method will take either a L<PkgForge::Queue::Entry> or a
L<PkgForge::Job> object. It erases the entire directory holding all
files associated with the job, it also kills the object as it no
longer has any physical meaning. In each case, the C<scrub> method is
called, see the specific documentation for further details.

=item update_job_status( $job, $status_name )

A convenience wrapper for the method of the same name provided by
L<PkgForge::Registry>. Will log errors, returns false on failure and
true on success.

=back

=head1 CONFIGURATION AND ENVIRONMENT

By default Package Forge handlers can be configured via the
C</etc/pkgforge/handlers.yml> YAML file. This class will also examine
the file C</etc/pkgforge/incoming.yml>, if it exists, and settings in
that file will have precedence. You can override the path to the
configuration file via the C<configfile> attribute.

By default, the logging system can be configured via
C</etc/pkgforge/incoming.log>. If the file does not exist then the
handler will log to stderr.

=head1 DEPENDENCIES

This module is powered by L<Moose> and also uses L<MooseX::Types>,
L<Readonly>.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Handler>, L<PkgForge::Job>,
L<PkgForge::Queue>, L<PkgForge::Queue::Entry>

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

    Copyright (C) 201O University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
