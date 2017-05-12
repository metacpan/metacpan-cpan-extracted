package PkgForge::Daemon::Buildd; # -*-perl-*-
use strict;
use warnings;

# $Id: Buildd.pm.in 17473 2011-06-01 13:07:47Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 17473 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/PkgForge-Server/PkgForge_Server_1_1_10/lib/PkgForge/Daemon/Buildd.pm.in $
# $Date: 2011-06-01 14:07:47 +0100 (Wed, 01 Jun 2011) $

our $VERSION = '1.1.10';

my $PLEASE_STOP = 0;

use Moose;
use MooseX::Types::Moose qw(Int);

extends 'PkgForge::Daemon', 'PkgForge::Handler::Buildd';

has 'poll' => (
    is       => 'ro',
    isa      => Int,
    default  => 60,
    required => 1,
    documentation => 'Interval (in seconds) to wait between queue runs',
);

# Different pidfile for each individual buildd

override 'init_pidfile' => sub {
  my ($self) = @_;

  my $file = $self->progname . '-' . $self->name . '.pid';
  my $path = File::Spec->catfile( $self->pidfile_dir, $file );

  return $path;
};

override 'status_message' => sub {
  my ( $self, $pid ) = @_;

  my $name = $self->name;
  if ($pid) {
    print "Build daemon '$name' is running with PID $pid\n";
  } else {
    print "Build daemon '$name' is not running\n";
  }

  return;
};

override 'shutdown' => sub {
    my ($self) = @_;

    $self->logger->notice('Handling shutdown request');

    $PLEASE_STOP = 1;

    return;
};

after 'start' => sub {
    my ($self) = @_;

    my $name = $self->name;

    $self->logger->notice("Starting build daemon '$name'");

    $self->preflight();

    while ( !$PLEASE_STOP ) {
        my $task = $self->next_task;
        while ( !$PLEASE_STOP && !defined $task ) {
            sleep $self->poll;
            $task = $self->next_task;
        }

        if ( !$PLEASE_STOP ) {
            my $uuid = $task->job->uuid;
            $self->logger->notice("Starting task $uuid on " . $self->name);
            $self->execute($task);
            $self->logger->notice("Finished task $uuid on " . $self->name);
        }

        # Try to leave the registry in a nice state if we didn't complete
        # the job. This way it will be attempted again later.

        $self->reset_unfinished_tasks();

    }

    $self->logger->notice("Stopping build daemon '$name'");

    exit 0;
};

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__
