package PkgForge::Registry; # -*- perl -*-
use strict;
use warnings;

# $Id: Registry.pm.in 16554 2011-04-01 04:52:34Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 16554 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Registry/PkgForge_Registry_1_3_0/lib/PkgForge/Registry.pm.in $
# $Date: 2011-04-01 05:52:34 +0100 (Fri, 01 Apr 2011) $

our $VERSION = '1.3.0';

use English qw(-no_match_vars);

use Moose;
use MooseX::Types::Moose qw(Int Str);

use PkgForge::Registry::Schema ();

with 'PkgForge::ConfigFile', 'MooseX::Getopt';

has '+configfile' => (
    default => sub { return [ '/etc/pkgforge/registry.yml' ]; },
);

has 'name' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
    documentation => 'The name of the database',
);

has 'host' => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_host',
    documentation => 'The host name of the database server',
);

has 'port' => (
    is        => 'ro',
    isa       => Int,
    predicate => 'has_port',
    documentation => 'The port on which the database server is listening',
);

has 'user' => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    default   => q{},
    documentation => 'The user name with which to connect to the database',
);

has 'pass' => (
    is        => 'ro',
    isa       => 'Maybe[Str]',
    default   => q{},
    documentation => 'The password with which to connect to the database',
);

has 'schema' => (
    is      => 'ro',
    isa     => 'PkgForge::Registry::Schema',
    lazy    => 1,
    builder => '_connect',
    documentation => 'The DBIx::Class schema object',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub build_dsn {
    my ($self) = @_;

    my $dsn = 'dbi:Pg:dbname=' . $self->name;
    if ( $self->has_host ) {
        $dsn = $dsn . ';host=' . $self->host;
    }
    if ( $self->has_port ) {
        $dsn = $dsn . ';port=' . $self->port;
    }

    return $dsn;
}

sub _connect {
    my ($self) = @_;

    my $dsn  = $self->build_dsn;
    my $user = $self->user;
    my $pass = $self->pass;

    my %attrs = (
        AutoCommit => 1,
        RaiseError => 1
    );

    my $schema
        = PkgForge::Registry::Schema->connect( $dsn, $user, $pass, \%attrs );

    return $schema;
}

sub get_builder {
    my ( $self, $builder_name ) = @_;

    my $rs = $self->schema->resultset('Builder');

    my $builder = $rs->search( { name => $builder_name } )->single;

    if ( !defined $builder ) {
        die "Failed to find a builder named '$builder_name' in the registry\n";
    }

    return $builder;
}

sub _get_task_status {
    my ( $self, $status_name ) = @_;

    my $rs = $self->schema->resultset('TaskStatus');

    my $status = $rs->search( { name => $status_name } )->single;

    if ( !defined $status ) {
        die "Could not find the '$status_name' task status in the registry\n";
    }

    return $status;
}

sub reset_unfinished_tasks {
    my ( $self, $builder_name ) = @_;

    my $needsbuild_status = $self->_get_task_status('needs build');
    my $building_status   = $self->_get_task_status('building');

    my $rs = $self->schema->resultset('Task')->search(
        { 'status'        => $building_status->id,
          'builder.name'  => $builder_name,
        },
        { join => 'builder' } );

    eval { $self->schema->txn_do(
               sub { $rs->update_all( { status => $needsbuild_status->id } ) }
             )
    };

    if ($EVAL_ERROR) {
        die "Failed to reset the status of unfinished tasks for builder '$builder_name': $EVAL_ERROR\n";
    }

    return;
}

sub next_new_task {
    my ( $self, $builder_name ) = @_;

    my $schema = $self->schema;

    my $builder  = $self->get_builder($builder_name);
    my $platform = $builder->platform;

    my $needsbuild_status = $self->_get_task_status('needs build');
    my $building_status   = $self->_get_task_status('building');

    # There is no way to do row-level locking in DBIx::Class so use raw SQL

    my $sql = q(SELECT * FROM task WHERE platform = ? AND status = ? FOR UPDATE OF task);

    my $dbh = $self->schema->storage->dbh();

    # BEGIN TRANSACTION AND LOCK ROWS
    $schema->txn_begin;

    my $result = eval {
        my $sth = $dbh->prepare_cached($sql);

        $sth->execute( $platform->id, $needsbuild_status->id );
        $sth->finish;

        # This finds the next appropriate task purely on a
        # submission-time basis. The oldest job will be selected
        # first. At a later date we might add support for selecting
        # jobs by size or allowing prioritisation based on the other
        # job attributes.

        my $tasks =
            $schema->resultset('Task')->search( { platform => $platform->id,
                                                  status   => $needsbuild_status->id }, { order_by => { -asc => 'modtime' } } );

        if ( $tasks->count > 0 ) {
            my $task = $tasks->first;

            $builder->current($task->id);
            $builder->update();

            $task->status($building_status->id);
            $task->update();

            return $task;
        }

        return;
    };

    if ($EVAL_ERROR) {
        $schema->txn_rollback();
        die $EVAL_ERROR; # pass on the exception;
    } else {
        $schema->txn_commit();
    }

    # END TRANSACTION

    return $result;
}

# TODO: look at merging the code from fail_task and finalise_task as
#       they do the same process but just set a different status.

sub fail_task {
    my ( $self, $builder_name, $uuid ) = @_;

    my $builder  = $self->get_builder($builder_name);
    my $platform = $builder->platform;

    my $fail_status = $self->_get_task_status('fail');

    my $schema  = $self->schema;
    my $job_rs  = $schema->resultset('Job');
    my $task_rs = $schema->resultset('Task');

    my $job = $job_rs->search( { uuid => $uuid } )->single;
    if ( !defined $job ) {
        die "Failed to find a registry entry for job '$uuid'\n";
    }

    my $task = $task_rs->search( { job      => $job->id,
                                   platform => $platform->id } )->single;
    if ( !defined $task ) {
        my $id = $job->id;
        my $name = $platform->name;
        my $arch = $platform->arch;
        die "Failed to find a task for job $id on platform $name/$arch: $EVAL_ERROR\n";
    }

    my $task_id = $task->id;
    my $current = $builder->current->id;

    if ( $task_id != $current ) {
        die "Something weird is happening. Cannot set fail for task '$task_id' when it is not the current active task ($current).";
    }

    eval { $schema->txn_do(
        sub {
            $task->status($fail_status->id);
            $task->update();
        }
    ) };

    if ($EVAL_ERROR) {
        die "Failed to set the status for task $task_id: $EVAL_ERROR\n";
    }

    return;
}

sub finalise_task {
    my ( $self, $builder_name, $uuid ) = @_;

    my $builder  = $self->get_builder($builder_name);
    my $platform = $builder->platform;

    my $success_status = $self->_get_task_status('success');

    my $schema  = $self->schema;
    my $job_rs  = $schema->resultset('Job');
    my $task_rs = $schema->resultset('Task');

    my $job = $job_rs->search( { uuid => $uuid } )->single;
    if ( !defined $job ) {
        die "Failed to find a registry entry for job '$uuid'\n";
    }

    my $task = $task_rs->search( { job      => $job->id,
                                   platform => $platform->id } )->single;
    if ( !defined $task ) {
        my $id = $job->id;
        my $name = $platform->name;
        my $arch = $platform->arch;
        die "Failed to find a task for job $id on platform $name/$arch: $EVAL_ERROR\n";
    }

    my $task_id = $task->id;
    my $current = $builder->current->id;

    if ( $task_id != $current ) {
        die "Something weird is happening. Cannot set success for task '$task_id' when it is not the current active task ($current).";
    }

    eval { $schema->txn_do(
        sub {
            $task->status($success_status->id);
            $task->update();
        }
    ) };

    if ($EVAL_ERROR) {
        die "Failed to set the status for task $task_id: $EVAL_ERROR\n";
    }

    return;
}

sub get_job_status {
    my ( $self, $job ) = @_;

    my $uuid = $job->id;

    my $schema  = $self->schema;
    my $job_rs  = $schema->resultset('Job');

    my $job_in_db = $job_rs->search( { uuid => $uuid } )->single;

    if ( !defined $job_in_db ) {
        die "Failed to find a registry entry for job $uuid\n";
    }

    return $job_in_db->status->name || 'unknown';
}

sub update_job_status {
    my ( $self, $job, $status_name ) = @_;

    my $uuid = $job->id;

    my $schema  = $self->schema;
    my $job_rs  = $schema->resultset('Job');
    my $stat_rs = $schema->resultset('JobStatus');

    my $job_in_db = $job_rs->search( { uuid => $uuid } )->single;

    if ( !defined $job_in_db ) {
        die "Failed to find a registry entry for job $uuid\n";
    }

    my $status = $stat_rs->search( { name => $status_name } )->single;

    if ( !defined $status ) {
        die "Could not find the '$status_name' job status in the registry\n";
    }

    eval { $schema->txn_do( sub {
        $job_in_db->status( $status->id );
        $job_in_db->update() }
    ) };

    if ($EVAL_ERROR) {
        die "Failed to update the status of job $uuid to '$status_name'\n";
    }

    return 1;
}

sub job_exists {
    my ( $self, $job ) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');

    my $matches = $job_rs->search( { uuid => $job->id } );

    if ( $matches->count > 0 ) {
        return 1;
    }

    return 0;
}

sub register_job {
    my ( $self, $job ) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');

    my $matches = $job_rs->search( { uuid => $job->id } );

    if ( $matches->count > 0 ) {
        die 'Could not add a new job with ID ' . $job->id . " as it already exists\n";
    }

    my $job_in_db = eval { $schema->txn_do(
                 sub {
                     $job_rs->create( { submitter => $job->submitter,
                                        size      => $job->size,
                                        uuid      => $job->id, } );
                 }
    ) };

    if ( !$job_in_db || $EVAL_ERROR ) {
        die 'Failed to register a new job with ID ' . $job->id . ": $EVAL_ERROR\n";
    }

    return 1;
}

sub register_tasks {
    my ( $self, $job ) = @_;

    my $schema = $self->schema;
    my $job_rs = $schema->resultset('Job');

    my $job_in_db = $job_rs->search( { uuid => $job->id } )->single;

    if ( !defined $job_in_db ) {
        die 'Failed to find a registry entry for job ' . $job->id . " \n";
    }

    my $platform_rs = $schema->resultset('Platform');

    my @platforms = $platform_rs->search( { active => 1 } );

    my @targets = map { { name => $_->name,
                          arch => $_->arch,
                          auto => $_->auto } } @platforms;

    my @wanted = $job->process_build_targets(@targets);

    my $task_rs = $schema->resultset('Task');

    # Will set the job status to 'registered' once all/any tasks are added.

    my $registered_status = $schema->resultset('JobStatus')->search(
                                           { name => 'registered' } )->single;

    if ( !defined $registered_status ) {
        die "Could not find the 'registered' job status in the registry\n";
    }

# BEGIN TRANSACTION

    eval { $schema->txn_do( sub {
        for my $wanted (@wanted) {
            my ( $name, $arch ) = @{$wanted};
            my $platform
              = $platform_rs->search( { name => $name,
                                        arch => $arch } )->single;

            if ( defined $platform && $platform->active ) {
                $task_rs->create( { job      => $job_in_db->id,
                                    platform => $platform->id } );
            }
        }

        $job_in_db->status($registered_status->id);
        $job_in_db->update();

    }

    ) };

# END TRANSACTION

    if ($EVAL_ERROR) {
        die 'Failed to register tasks for job ' . $job->id . ": $EVAL_ERROR\n";
    }

    return 1;
}

1;
__END__

=head1 NAME

PkgForge::Registry - A Moose class used for access to the PkgForge registry.

=head1 VERSION

     This documentation refers to PkgForge::Registry version 1.3.0

=head1 SYNOPSIS

     use PkgForge::Registry;

     my $registry = PkgForge::Registry->new();

     # or more usefully...

     my $registry
           = PkgForge::Registry->new_with_config( configfile => "foo.yml" );

     # Get the DBIx::Class schema object

     my $schema = $registry->schema;

     # Provides some high-level methods

     if ( !$registry->job_exists($job) ) {
         $registry->register_job($job);
     }

     $registry->update_job_status($job,'valid');

=head1 DESCRIPTION

This class manages access to the Package Forge registry. It provides
configuration handling methods for setting the various DBI parameters
which are used to load the L<DBIx::Class> schema object. It also
provides some high-level functions which are used for registering
build jobs and managing the status of separate tasks associated with
each job.

=head1 ATTRIBUTES

This class has the following attributes:

=over

=item name

This is the name of the database being used to store the
registry information. This attibute MUST be specified, there is no
default value.

=item host

This is the host name for the database server. This attribute is
optional, see L<DBD::Pg> for details of the default value.

=item port

This is the port number for the database server. This attribute is
optional, see L<DBD::Pg> for details of the default value.

=item user

This is the name of the user to be used for accessing the database.
This attribute is optional, see L<DBD::Pg> for details of the default
value.

=item pass

This is the password for the user to be used for accessing the database.
This attribute is optional, see L<DBD::Pg> for details of the default
value.

=item schema

This gives access to the L<DBIx::Class::Schema> object.

=item configfile

The name for a configuration file which can be used for loading the
registry attributes. The default is
C</etc/pkgforge/registry.yml>. This only has an effect when you create
a new object using the C<new_with_config> method.

=back

=head1 SUBROUTINES/METHODS

This class has the following methods:

=over

=item new()

Create a new instance of this class. Optionally a hash (or reference
to a hash) of attributes and their values can be specified.

=item new_with_config()

Create a new instance of this class using the attribute values set in
a configuration file. By default, the C</etc/pkgforge/registry.yml>
will be loaded, if it exists. The configuration file can be changed
using the C<configfile> attribute. See L<PkgForge::ConfigFile> for
more details.

=item build_dsn()

This returns the DBI Data Source Name (DSN) built from the various
attributes. The DSN is passed through to the DBI layer and this method
is mainly provided to help future sub-classes which might need to
override the database driver.

=item register_job($job)

This method takes a L<PkgForge::Job> object and registers the job into
the PkgForge registry. Firstly a check is made that no other job with
the same UUID has already been registered. If successful the method
will return true, if anything fails then the method will die.

=item register_tasks($job)

This method takes a L<PkgForge::Job> object and registers the
associated tasks (if any). Firstly this method checks that the job has
already been registered (this should be done with C<register_job>). It
then calls the C<process_build_targets> method on the job object with
the current list of active build target platforms to find out which
platforms and architectures are required. A task is added for each
required platform (if any). The job status will be updated to
C<registered> if the tasks are successfully registered. If successful
the method will return true, if anything fails then the method will
die.

=item get_job_status($job)

This method takes a L<PkgForge::Job> object and returns the name of
the current status for the job. This method will die if it cannot find
the relevant job, if no status is found then C<unknown> will be
returned.

=item update_job_status($job, $status_name)

This method takes a L<PkgForge::Job> object and the name of a status
to which the job status field should be set. If anything fails this
method will die.

=item reset_unfinished_tasks($builder_name)

This method takes the name of a registered builder and resets any
associated unfinished tasks (in the C<building> status) to the C<needs
build> status. This is particularly useful when a shut down of a
builder has been requested before a task is finished. The task can
then be picked up again later by another operational daemon.

=item next_new_task($builder_name)

This method takes the name of a registered builder and returns the
next task in the status C<needs build> (if any). If a new task is found
then it will be moved into the C<building> status, the C<current> job
for that builder will be recorded and a
L<PkgForge::Registry::Schema::Result::Job> object will be returned. If
no new tasks are found the method will return C<undef>, if an error
occurs the method will die.

Whilst selecting the next task all rows in the database for that
platform containing tasks needing building will be locked. This is to
avoid multiple builders for the same platform taking on the same
tasks.

=item fail_task( $builder_name, $job_uuid )

This registers a task as having failed to build on the platform
supported by the specified builder. Note that, to maintain
consistency, this method requires the specified job to be the same as
that which is considered C<current> for the builder.

=item finalise_task( $builder_name, $job_uuid )

This registers a task as having successfully built on the platform
supported by the specified builder. Note that, to maintain consistency,
this method requires the specified job to be the same as that which is
considered C<current> for the builder.

=back

=head1 CONFIGURATION AND ENVIRONMENT

If the C<new_with_config> method is used then configuration
information can be loaded from a file. The default file name is
C</etc/pkgforge/registry.yml> but that can be overridden using the
C<configfile> attribute.

It is not necessary to set all the attributes to successfully connect
to the database. The L<DBI> layer has support for using environment
variables for nearly all possible connection options, see L<DBD::Pg>
for full details.

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::ConfigFromFile>
and L<MooseX::Types>. The L<DBIx::Class> object-relational mapper
modules are used for database access. Currently PkgForge requires
PostgreSQL for the database backend, this means that the L<DBD::Pg>
module is also necessary.

=head1 SEE ALSO

L<PkgForge>

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

    Copyright (C) 2010 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
