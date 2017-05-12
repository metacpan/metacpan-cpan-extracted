package PkgForge::Handler::Buildd; # -*-perl-*-
use strict;
use warnings;

# $Id: Buildd.pm.in 17469 2011-06-01 12:36:28Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 17469 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Handler/Buildd.pm.in $
# $Date: 2011-06-01 13:36:28 +0100 (Wed, 01 Jun 2011) $

our $VERSION = '1.1.10';

use English qw(-no_match_vars);
use File::Copy ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use PkgForge::BuildInfo ();
use PkgForge::BuildLog ();
use PkgForge::Job ();
use Try::Tiny;
use UNIVERSAL::require;

use Readonly;
Readonly my $BUILD_COMMAND_STUB => 'PkgForge::BuildCommand';
Readonly my $TMPDIR_PERMS => oct('0750');

use Moose;
use MooseX::Types::Moose qw(Int Str);
use Moose::Util::TypeConstraints;

extends 'PkgForge::Handler';

with 'PkgForge::Registry::Role';

subtype 'PkgForgeBuildCommandBuilder'
  => as role_type("$BUILD_COMMAND_STUB\::Builder");

subtype 'PkgForgeBuildCommandSubmitter'
  => as role_type("$BUILD_COMMAND_STUB\::Submitter");

subtype 'PkgForgeBuildCommandSigner'
  => as role_type("$BUILD_COMMAND_STUB\::Signer");

subtype 'PkgForgeBuildCommandCheck'
  => as role_type("$BUILD_COMMAND_STUB\::Check");

subtype 'PkgForgeBuildCommandReporter'
  => as role_type("$BUILD_COMMAND_STUB\::Reporter");

has 'builder' => (
  is        => 'ro',
  isa       => 'Str|HashRef[HashRef]',
  required  => 1,
);

has 'submitters' => (
  traits   => ['Array'],
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 0,
  handles  => {
    'has_submitters'  => 'count',
    'submitters_list' => 'elements',
  },
  default  => sub { [] },
);

has 'signers' => (
  traits   => ['Array'],
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 0,
  handles  => {
    'has_signers'  => 'count',
    'signers_list' => 'elements',
  },
  default  => sub { [] },
);

has 'checks' => (
  traits   => ['Array'],
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 0,
  handles  => {
    has_checks  => 'count',
    checks_list => 'elements',
  },
  default  => sub { [] },
);

has 'reports' => (
  traits   => ['Array'],
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 0,
  handles  => {
    has_reports  => 'count',
    reports_list => 'elements',
  },
  default  => sub { [] },
);

has 'build_command' => (
  is       => 'ro',
  isa      => 'PkgForgeBuildCommandBuilder',
  init_arg => undef,
  required => 1,
  lazy     => 1,
  builder  => 'load_build_command',
);

has 'submit_commands' => (
  traits   => ['Array'],
  is       => 'ro',
  isa      => 'ArrayRef[PkgForgeBuildCommandSubmitter]',
  init_arg => undef,
  required => 1,
  lazy     => 1,
  handles  => {
    submit_commands_list => 'elements',
  },
  builder  => 'load_submit_commands',
);

has 'sign_commands' => (
  traits   => ['Array'],
  is       => 'ro',
  isa      => 'ArrayRef[PkgForgeBuildCommandSigner]',
  init_arg => undef,
  required => 1,
  lazy     => 1,
  handles  => {
    sign_commands_list => 'elements',
  },
  builder  => 'load_sign_commands',
);

has 'check_commands' => (
  traits   => ['Array'],
  is       => 'ro',
  isa      => 'ArrayRef[PkgForgeBuildCommandCheck]',
  init_arg => undef,
  required => 1,
  lazy     => 1,
  handles  => {
    check_commands_list => 'elements',
  },
  builder  => 'load_check_commands',
);

has 'report_commands' => (
  traits    => ['Array'],
  is       => 'ro',
  isa      => 'ArrayRef[PkgForgeBuildCommandReporter]',
  init_arg => undef,
  required => 1,
  lazy     => 1,
  handles  => {
    report_commands_list => 'elements',
  },
  builder  => 'load_report_commands',
);

has 'name' => (
  is       => 'ro',
  isa      => Str,
  required => 1,
  documentation => 'Name of the build daemon',
);

has '+tmpdir' => (
  lazy    => 1,
  default => sub {
    my ($self) = @_;
    return File::Spec->catdir( '/var/tmp/pkgforge/', $self->name );
  },
);

has 'timeout' => (
  is        => 'ro',
  isa       => Int,
  default   => 600, # 10 minutes
  documentation => 'Time after which a build job should be killed',
);

has '+logconf' => (
  default => '/etc/pkgforge/log-buildd.cfg',
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub load_command_module {
  my ( $self, $modtype, $value ) = @_;

  my ( $module, %params );

  if ( find_type_constraint('Str')->check($value) ) {
    $module = $value;
  } elsif ( find_type_constraint('HashRef')->check($value) ) {
    my %data = %{$value};

    my @names = keys %data;
    if ( scalar @names > 1 ) {
      my $names_list = join q{, }, @names;
      die "Only one $modtype module may be specified, found a list: $names_list\n";
    }

    $module = $names[0];
    if ( ref $data{$module} eq 'HASH' ) {
      %params = %{$data{$module}};
    } elsif ( ref $data{$module} eq 'ARRAY' ) {
      %params = @{$data{$module}};
    } else {
      die "Cannot handle extra $modtype module parameters in $data{$module}\n";
    }

  } else {
    die "Cannot load $modtype module\n";
  }

  my $stub = join q{::}, $BUILD_COMMAND_STUB, $modtype;
  if ( $module !~ m/^\Q$stub\E/ ) {
    $module = join q{::}, $stub, $module;
  }

  $module->require
    or die "Cannot load $modtype module '$module': $UNIVERSAL::require::ERROR\n";

  return ( $module, %params );
}

sub load_commands_list {
  my ( $self, $modtype, @modlist ) = @_;

  my @commands;
  for my $entry (@modlist) {
    my ( $module, %params ) = $self->load_command_module( $modtype, $entry );

    my $command = $module->new(%params);

    push @commands, $command;
  }

  return \@commands;
}

sub load_build_command {
  my ($self) = @_;

  my ( $module, %params )
    = $self->load_command_module( 'Builder', $self->builder );

  # Load the builder from the database

  my $builder_in_db = $self->registry->get_builder($self->name);
  my $platform = $builder_in_db->platform;

  if ( !$platform->active ) {
    die "This platform is not currently registered as active\n";
  }

  my ( $platform_name, $platform_arch ) = ( $platform->name, $platform->arch );

  my $obj = $module->new(
    platform     => $platform_name,
    architecture => $platform_arch,
    timeout      => $self->timeout,
    tmpdir       => $self->tmpdir,
    debug        => $self->debug,
    %params,
  );

  return $obj;
}

sub load_submit_commands {
  my ($self) = @_;

  my $build_cmd = $self->build_command;

  my $platform_name = $build_cmd->platform;
  my $platform_arch = $build_cmd->architecture;

  my @submitters;
  for my $entry ($self->submitters_list) {

    my ( $module, %params )
      = $self->load_command_module( 'Submitter', $entry );

    my $obj = $module->new(
      platform     => $platform_name,
      architecture => $platform_arch,
      %params,
    );

    push @submitters, $obj;
  }

  return \@submitters;
}

sub load_check_commands {
  my ($self) = @_;

  return $self->load_commands_list( 'Check', $self->checks_list );
}

sub load_sign_commands {
  my ($self) = @_;

  return $self->load_commands_list( 'Signer', $self->signers_list );
}


sub load_report_commands {
  my ($self) = @_;

  return $self->load_commands_list( 'Reporter', $self->reports_list );
}

sub preflight {
  my ($self) = @_;

  my $accept_dir = $self->accepted;

  if ( !-d $accept_dir ) {
    $self->logger->log_and_die(
      level   => 'critical',
      message => "Accepted jobs directory '$accept_dir' does not exist"
    );
  }

  my $results_dir = $self->results;

  if ( !-d $results_dir ) {
    $self->logger->log_and_die(
      level   => 'critical',
      message => "Results directory '$results_dir' does not exist"
    );
  }

  # Test that we have the correct permissions to write into the
  # results directory.

  try {
    my $tmp = File::Temp->new( TEMPLATE => 'pkgforge-XXXX',
                               UNLINK   => 1,
                               DIR      => $results_dir );
    $tmp->print("test\n") or die "Failed to print to temp file: $OS_ERROR\n";
    $tmp->close or die "Could not close temp file: $OS_ERROR\n";
  } catch {
    $self->logger->log_and_die(
      level   => 'critical',
      message => "Results directory '$results_dir' is not writable: $_"
    );
  };

  # Verify the environment for the various commands.

  for my $cmd ( $self->build_command,
                $self->check_commands_list,
                $self->submit_commands_list,
                $self->report_commands_list ) {
    try {
      $cmd->verify_environment;
    } catch {
      $self->logger->log_and_die(
        level   => 'critical',
        message => "The build environment is incomplete: $_\n",
      );
    };
  }

  # Setup the temporary directory if it does not already exist. This
  # is different directory for each build daemon.

  my $tmpdir = $self->tmpdir;

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

sub next_task {
  my ($self) = @_;

  my $registry = $self->registry;
  my $next_task = eval { $registry->next_new_task($self->name) };

  if ($EVAL_ERROR) {
    $self->log_problem( 'Failed to query registry for a new build job',
                        $EVAL_ERROR );
    return;
  }

  if ( !defined $next_task && $self->debug ) {
    my $name = $self->name;
    $self->logger->debug("Nothing waiting in the queue for '$name'");
  }

  return $next_task;
}

sub load_job {
  my ( $self, $task ) = @_;

  my $uuid = $task->job->uuid;

  my $jobs_dir = $self->accepted;

  my $job_dir = File::Spec->catdir( $jobs_dir, $uuid );

  my $job = eval { PkgForge::Job->new_from_dir($job_dir) };

  if ( $EVAL_ERROR || !defined $job ) {
    $self->log_problem( "Failed to load build job from $job_dir",
                        $EVAL_ERROR );
    return;
  }

  return $job;
}

sub execute {
  my ( $self, $task ) = @_;

  try { 
    $task ||= $self->next_task();
    if ( !defined $task ) {
      return;
    }

    my $job = $self->load_job($task);
    if ( !defined $job ) {
      return;
    }

    my $ok = $self->build($job);
    if ( !$ok ) {
      return;
    }
  } catch {
    $self->logger->log_and_die(
      level   => 'critical',
      message => "Something bad happened: $_",
    );
  };

  return;
}

sub fail_job {
  my ( $self, $job ) = @_;

  eval { $self->registry->fail_task( $self->name, $job->id ) };

  if ($EVAL_ERROR) {
    $self->logger->log_and_die(
      level   => 'critical',
      message => "Failed to set failure for build job '$job' in registry: $EVAL_ERROR",
    );
  }

  $self->logger->notice("Failed job $job");

  return 1;
}

sub finish_job {
  my ( $self, $job ) = @_;

  eval { $self->registry->finalise_task( $self->name, $job->id ) };

  if ($EVAL_ERROR) {
    $self->logger->log_and_die(
      level   => 'critical',
      message => "Failed to finalise build job '$job' in registry: $EVAL_ERROR",
    );
  }

  $self->logger->notice("Successfully completed job $job");

  return 1;
}

sub reset_unfinished_tasks {
  my ($self) = @_;

  eval { $self->registry->reset_unfinished_tasks($self->name) };
  if ( $EVAL_ERROR ) {
    $self->log_problem( 'Failed to reset unfinished tasks', $EVAL_ERROR );
  }

  return;
}

sub store_products {
  my ( $self, $buildinfo, $resultsdir ) = @_;

  if ( !-d $resultsdir ) {
    try {
      File::Path::mkpath($resultsdir);
    } catch {
      $self->logger->log_and_die(
        level   => 'critical',
        message => "Failed to create directory '$resultsdir': $_",
      );
    };
  }

  my %sources_list = map { $_ => 1 } $buildinfo->source_files;

  for my $file ( $buildinfo->products_list ) {
    if ( !-f $file ) {
      $self->logger->error("Failed to transfer file '$file': it does not exist");
      next;
    }

    # Do not transfer source files that we already have stored elsewhere

    my $basename = (File::Spec->splitpath($file))[2];
    if ( exists $sources_list{$basename} ) {
      next;
    }

    my $ok = File::Copy::copy( $file, $resultsdir );
    if ( !$ok ) {
      $self->logger->error("Failed to transfer file '$file': $OS_ERROR");
    }

  }

  return;
}

sub store_logs {
  my ( $self, $buildinfo, $resultsdir ) = @_;

  if ( !-d $resultsdir ) {
    try {
      File::Path::mkpath($resultsdir);
    } catch {
      $self->logger->log_and_die(
        level   => 'critical',
        message => "Failed to create directory '$resultsdir': $_",
      );
    };
  }

  for my $file ($buildinfo->logs_list) {
    if ( !-f $file ) {
      $self->logger->error("Failed to transfer logfile '$file': it does not exist");
      next;
    }

    my $ok = File::Copy::copy( $file, $resultsdir );
    if ( !$ok ) {
      $self->logger->error("Failed to transfer logfile '$file': $OS_ERROR");
    }

  }

  return;
}


sub build {
  my ( $self, $job ) = @_;

  # Local log file directory for this particular job.

  my $job_logdir = File::Spec->catdir( $self->logdir, $self->name, $job->id );

  if ( !-d $job_logdir ) {
    $self->logger->debug("Will create job log directory '$job_logdir'");

    try {
      File::Path::mkpath($job_logdir);
    } catch {
      $self->logger->log_and_die(
        level   => 'critical',
        message => "Failed to create directory '$job_logdir': $_",
      );
    };
  }

  # Final results directory for this particular job.

  my $builder = $self->build_command;
  my $subdir = $builder->platform;
  if ( $builder->has_architecture ) {
    $subdir = join q{-}, $subdir, $builder->architecture;
  }

  my $job_resultsdir
    = File::Spec->catdir( $self->results, $job->id, $subdir );

  if ( !-d $job_resultsdir ) {

    $self->logger->debug("Will create job results directory '$job_resultsdir'");

    try {
      File::Path::mkpath($job_resultsdir);
    } catch {
      $self->logger->log_and_die(
        level   => 'critical',
        message => "Failed to create directory '$job_resultsdir': $_",
      );
    };
  }

  # Check the job actually contains some source packages.

  my $num = $job->count_packages;
  if ( $num == 0 ) {
    $self->logger->notice("Ignoring build job $job as it has zero source packages");
    $self->finish_job($job);
    return 1;
  } else {
    $self->logger->debug("Job has $num source packages");
  }

  $self->logger->notice("Attempting to build job $job");

  my $buildlog = PkgForge::BuildLog->new( debug  => $self->debug,
                                          logdir => $job_logdir );

  my $buildinfo_file = File::Spec->catfile( $job_resultsdir,
                                            'buildinfo.yml' );

  my $buildinfo = PkgForge::BuildInfo->new( 
    builder  => $self->name,
    jobid    => $job->id,
    logs     => [$buildlog->logfile],
    yamlfile => $buildinfo_file,
  );

  my $success = 0;
  try {

    $buildinfo->phase_reached('build');
    my $build_ok = $self->build_command->run( $job, $buildinfo, $buildlog );
    if ( !$build_ok ) {
      die "Failed to build $job\n";
    }

    $buildinfo->phase_reached('check');
    for my $command ($self->check_commands_list) {
      $buildinfo->phase_reached("check-$command");
      my $pass = $command->run( $job, $buildinfo, $buildlog );

      if (!$pass) {
        die "Failed check: '$command'\n";
      }
    }

    $buildinfo->phase_reached('sign');
    for my $command ($self->sign_commands_list) {
      $buildinfo->phase_reached("sign-$command");
      my $pass = $command->run( $job, $buildinfo, $buildlog );

      if (!$pass) {
        die "Failed signing: '$command'\n";
      }
    }

    $buildinfo->phase_reached('submit');
    for my $command ($self->submit_commands_list) {
      $buildinfo->phase_reached("submit-$command");
      my $pass = $command->run( $job, $buildinfo, $buildlog );

      if (!$pass) {
        die "Failed submission: '$command'\n";
      }
    }


    $buildinfo->phase_reached('end');
    $buildinfo->completed(1);
    $success = 1;

  } catch {
    $buildlog->logger->error("An error occurred during the build process: $_");
    $buildlog->logger->error("Giving up at phase: '" . $buildinfo->last_phase . "'");

    $success = 0;
  };

  # Mark the status in the registry
  if ($success) {
    $self->finish_job($job);
  } else {
    $self->fail_job($job);
  }

  for my $report ($self->report_commands_list) {
    try {
      $report->run( $job, $buildinfo, $buildlog );
    } catch {
      $buildlog->logger->error( "Failed to run report: $_" );
    };
  }

  $buildinfo->store_in_yamlfile();
  $self->store_logs( $buildinfo, $job_resultsdir );
  $self->store_products( $buildinfo, $job_resultsdir );

  return $success;
}

1;
__END__

=head1 NAME

PkgForge::Handler::Buildd - Package Forge Build Daemon

=head1 VERSION

This documentation refers to PkgForge::Handler::Buildd version 1.1.10

=head1 SYNOPSIS

     use PkgForge::Handler::Buildd;

     my $handler = PkgForge::Handler::Buildd->new_with_config();

     $handler->preflight;

     $handler->execute();

=head1 DESCRIPTION

This is a Package Forge build handler. It does the work of driving the
build process for a particular task which is part of a previously
accepted job. Each supported platform/architecture has a separate
build handler which selects the appropriate tasks from the queue,
attempts the build and then submits the results if successful. This
module is intended to be platform and package format agnostic, the
relevant Package Forge builders will be selected and used to generate
the actual packages.

=head1 ATTRIBUTES

This class inherits attributes from the L<PkgForge::Handler> class,
see that module documentation for full details. The following
attributes are added or modified:

=over

=back

=head1 CONFIGURATION AND ENVIRONMENT

The value of any attribute can be set via the YAML configuration files
C</etc/pkgforge/handlers.yml> and C</etc/pkgforge/buildd.yml>

The logging for this build handler is configured using the
C</etc/pkgforge/log-buildd.cfg> file. If the file does not exist then
the handler will log to stderr.

=head1 DEPENDENCIES

This module is powered by L<Moose> and uses L<MooseX::Types>.

=head1 SEE ALSO

L<PkgForge>, L<PkgForge::Handler>

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
