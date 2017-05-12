package Proc::Launcher::Manager;
use strict;
use warnings;

our $VERSION = '0.0.37'; # VERSION

use Moo;
use MooX::Types::MooseLike::Base qw(Bool Str HashRef InstanceOf);

use Carp;
use File::Path;
use POSIX qw(:sys_wait_h);

use Proc::Launcher;
use Proc::Launcher::Supervisor;

=head1 NAME

Proc::Launcher::Manager - manage multiple Proc::Launcher objects

=head1 VERSION

version 0.0.37

=head1 SYNOPSIS

    use Proc::Launcher::Manager;

    my $shared_config = { x => 1, y => 2 };

    my $monitor = Proc::Launcher::Manager->new( app_name  => 'MyApp' );

    # a couple of different components
    $monitor->register( daemon_name  => 'component1',
                        start_method => sub { MyApp->start_component1( $config ) }
                   );
    $monitor->register( daemon_name  => 'component2',
                        start_method => sub { MyApp->start_component2( $config ) }
                   );

    # using class/method/context rather than a code ref
    $monitor->register( daemon_name  => 'webui',
                        class        => 'MyApp::WebUI',
                        start_method => 'start_webui',
                        context      => $config,
                   );

    # start all registered daemons.  processes that are already
    # running won't be restarted.
    $monitor->start();

    # stop all daemons
    $monitor->stop();
    sleep 1;
    $monitor->force_stop();

    # display all processes stdout/stderr from the log file that's
    # been generated since we started
    $monitor->read_log( sub { print "$_[0]\n" } );

    # get a specific daemon or perform actions on one
    my $webui = $monitor->daemon('webui');
    $monitor->daemon('webui')->start();

    # start the process supervisor.  this will start up an event loop
    # and won't exit until it is killed.  any processes not already
    # running will be started.  all processes will be monitored and
    # automatically restarted if they exit.
    $monitor->supervisor->start();

    # shut down/restart the supervisor
    $monitor->supervisor->stop();
    $monitor->supervisor->force_stop();
    $monitor->supervisor->restart();


=head1 DESCRIPTION

This library makes it easier to deal with multiple L<Proc::Launcher>
processes by providing methods to start and stop all daemons with a
single command.  Please see the documentation in L<Proc::Launcher> to
understand how this these libraries differ from other similar forking
and controller modules.

It also provides a supervisor() method which will fork a daemon that
will monitor the other daemons at regular intervals and restart any
that have stopped.  Note that only one supervisor can be running at
any given time for each pid_dir.

There is no tracking of inter-service dependencies nor predictable
ordering of service startup.  Instead, daemons should be designed to
wait for needed resources.  See L<Launcher::Cascade> if you need to
handle dependencies.

=cut

#_* Roles

with 'Proc::Launcher::Roles::Launchable';

#_* Attributes

has 'debug'      => ( is         => 'ro',
                      isa        => Bool,
                      default    => 0,
                  );

has 'pid_dir'    => ( is         => 'ro',
                      isa        => Str,
                      lazy       => 1,
                      default    => sub {
                          my $dir = join "/", $ENV{HOME}, "logs";
                          unless ( -d $dir ) {  mkpath( $dir ); }
                          return $dir;
                      },
                  );

has 'launchers'  => ( is         => 'rw',
                      isa        => HashRef[InstanceOf['Proc::Launcher']],
                  );


has 'supervisor' => ( is         => 'rw',
                      lazy       => 1,
                      default    => sub {
                          my $self = shift;

                          return Proc::Launcher->new(
                              daemon_name  => 'supervisor',
                              pid_dir      => $self->pid_dir,
                              start_method => sub {
                                  Proc::Launcher::Supervisor->new( manager => $self )->monitor();
                              },
                          );
                      },
                  );


#_* Methods

=head1 METHODS

=over 8

=item register( %options )

Create a new L<Proc::Launcher> object with the specified options.  If
the specified daemon already exists, no changes will be made.

=cut

sub register {
    my ( $self, %options ) = @_;

    $options{pid_dir} = $self->pid_dir;

    my $daemon;
    unless ( $self->{daemons}->{ $options{daemon_name} } ) {
        $daemon = Proc::Launcher->new( %options );
    }

    # just capturing the position of the tail end of the log file
    $self->read_log( undef, $daemon );

    $self->{daemons}->{ $options{daemon_name} } = $daemon;
}

=item daemon( 'daemon_name' )

Return the L<Proc::Launcher> object for a specified daemon.

=cut

sub daemon {
    my ( $self, $daemon_name ) = @_;

    return $self->{daemons}->{ $daemon_name };
}


=item daemons()

Return a list of L<Proc::Launcher> objects.

=cut

sub daemons {
    my ( $self ) = @_;

    my @daemons;

    for my $daemon_name ( $self->daemons_names() ) {
        push @daemons, $self->{daemons}->{ $daemon_name };
    }

    return @daemons;
}

=item daemons_names()

Return a list of the names of all registered daemons.

=cut

sub daemons_names {
    my ( $self ) = @_;

    return ( sort keys %{ $self->{daemons} } );
}

=item is_running()

Return a list of the names of daemons that are currently running.

This will begin by calling rm_zombies() on one of daemon objects,
sleeping a second, and then calling rm_zombies() again.  So far the
test cases have always passed when using this strategy, and
inconsistently passed with any subset thereof.

While it seems that this is more complicated than shutting down a
single process, it's really just trying to be a bit more efficient.
When managing a single process, is_running might be called a few times
until the process exits.  Since we might be managing a lot of daemons,
this method is likely to be a bit more efficient and will hopefully
only need to be called once (after the daemons have been given
necessary time to shut down).

This may be reworked a bit in the future since calling sleep will halt
all processes in single-threaded cooperative multitasking frameworks.

=cut

sub is_running {
    my ( $self ) = @_;

    my @daemon_names = $self->daemons_names();

    unless ( scalar @daemon_names ) {
        print "is_running() called when no daemons registered\n";
        return;
    }

    # clean up deceased child processes before checking if processes
    # are running.
    $self->daemon($daemon_names[0])->rm_zombies();

    # # give any processes that have ceased a second to shut down
    sleep 1;

    # again clean up deceased child processes before checking if
    # processes are running.
    $self->daemon($daemon_names[0])->rm_zombies();

    my @running = ();

    for my $daemon_name ( @daemon_names ) {
        if ( $self->daemon($daemon_name)->is_running() ) {
            push @running, $daemon_name
        }
    }

    return @running;
}

=item start( $data )

Call the start() method on all registered daemons.  If the daemon is
already running it will not be restarted.

=cut

sub start {
    my ( $self, $data ) = @_;

    my $started;

    for my $daemon ( $self->daemons() ) {
        if ( $daemon->is_running() ) {
            print "daemon already running: ", $daemon->daemon_name, "\n";
        }
        else {
            print "starting daemon: ", $daemon->daemon_name, "\n";
            $daemon->start();
            $started++;
        }
    }

    return $started;
}


=item stop()

Call the stop() method on all daemons.

=cut

sub stop {
    my ( $self ) = @_;

    for my $daemon ( $self->daemons() ) {
        print "stopping daemon: ", $daemon->daemon_name, "\n";
        $daemon->stop();
    }

    return 1;
}

=item force_stop()

Call the force_stop method on all daemons.

=cut

sub force_stop {
    my ( $self ) = @_;

    for my $daemon ( $self->daemons() ) {
        print "forcefully stopping daemon: ", $daemon->daemon_name, "\n";
        $daemon->force_stop();
    }

    return 1;
}

=item disable()

Call the disable() method on all daemons.

=cut

sub disable {
    my ( $self ) = @_;

    for my $daemon ( $self->daemons() ) {
        print "disabling daemon: ", $daemon->daemon_name, "\n";
        $daemon->disable();
    }

    return 1;
}

=item enable()

Call the enable() method on all daemons.

=cut

sub enable {
    my ( $self ) = @_;

    for my $daemon ( $self->daemons() ) {
        print "enabling daemon: ", $daemon->daemon_name, "\n";
        $daemon->enable();
    }

    return 1;
}

=item read_log()

=cut

sub read_log {
    my ( $self, $output_callback, @daemons ) = @_;

    unless ( scalar @daemons ) { @daemons = $self->daemons() }

    for my $daemon ( @daemons ) {
        $daemon->read_log( $output_callback );
    }
}

=item tail( $output_callback, $timeout_secs )

Poll all daemons for output for the specified number of seconds.  Any
output received in that time will be sent to $output_callback.  Each
line of output will be prefixed with the daemon name.



=cut

sub tail {
    my ( $self, $output_callback, $timeout ) = @_;

    # create an array of Log::Tail objects to be passed to select()
    my @tails;

    # select() will return the paths associated with each daemon, so
    # we need to be able to look up the name of a daemon based on it's
    # log file path.
    my %daemons;
    for my $daemon ( $self->daemons() ) {
        push @tails, $daemon->file_tail;
        $daemons{ $daemon->log_file } = $daemon->daemon_name;
    }

    # calculate the time when we're done processing.
    my $end = time + $timeout;

    # display all new log output to stdout
    my $count;
    while ( 1 ) {

        my ($nfound,$timeleft,@pending)=
            File::Tail::select(undef,undef,undef,1,@tails);

        if ($nfound) {
            foreach (@pending) {
                my $daemon_name = $daemons{ $_->{input} } || $_->{input};
                my $text = $_->read;

                for my $line ( split /\n/, $text ) {
                    my $output = sprintf( "%-8s: %-1s", $daemon_name, $line );
                    $output_callback->( "$output\n" );
                }
            }
        }
        else {
            # if we spawned any child procs, reap any that died
            waitpid(-1, WNOHANG);
            sleep 1;
        }

        # if timeout was specified, quit when the timeout has passed.
        if ( $timeout ) {
            last if time > $end;
        }
    }

    return 1;
}



=back

=cut

1;
