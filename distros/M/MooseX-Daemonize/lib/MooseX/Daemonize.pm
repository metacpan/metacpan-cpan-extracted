use strict;
use warnings;
package MooseX::Daemonize; # git description: v0.20-8-g6d23389
# ABSTRACT: Role for daemonizing your Moose based application

our $VERSION = '0.21';

use Moose::Role;
use MooseX::Types::Path::Class;
use File::Path qw(make_path);
use namespace::autoclean;

with 'MooseX::Daemonize::WithPidFile',
     'MooseX::Getopt';

sub OK    () { 0 }
sub ERROR () { 1 }

has progname => (
    metaclass => 'Getopt',
    isa       => 'Str',
    is        => 'ro',
    lazy      => 1,
    required  => 1,
    default   => sub {
        ( my $name = lc $_[0]->meta->name ) =~ s/::/_/g;
        return $name;
    },
    documentation => 'the name of the daemon',
);

has pidbase => (
    metaclass => 'Getopt',
    isa       => 'Path::Class::Dir',
    is        => 'ro',
    coerce    => 1,
    required  => 1,
    lazy      => 1,
    default   => sub { Path::Class::Dir->new('', 'var', 'run') },
    documentation => 'the base for our pid (default: /var/run)',
);

has basedir => (
    metaclass => 'Getopt',
    isa       => 'Path::Class::Dir',
    is        => 'ro',
    coerce    => 1,
    required  => 1,
    lazy      => 1,
    default   => sub { Path::Class::Dir->new('/') },
    documentation => 'the directory to chdir to (default: /)',
);

has foreground => (
    metaclass   => 'Getopt',
    cmd_aliases => 'f',
    isa         => 'Bool',
    is          => 'ro',
    default     => sub { 0 },
    documentation => 'if true, the process won\'t background',
);

has stop_timeout => (
    metaclass => 'Getopt',
    isa       => 'Int',
    is        => 'rw',
    default   => sub { 2 },
    documentation => 'number of seconds to wait for the process to stop, before trying harder to kill it (default: 2 s)',
);

# internal book-keeping

has status_message => (
    metaclass => 'NoGetopt',
    isa       => 'Str',
    is        => 'rw',
    clearer   => 'clear_status_message',
);

has exit_code => (
    metaclass => 'NoGetopt',
    isa       => 'Int',
    is        => 'rw',
    clearer   => 'clear_exit_code',
);

# methods ...

## PID file related stuff ...

sub init_pidfile {
    my $self = shift;
    my $file = $self->pidbase . '/' . $self->progname . '.pid';

    if ( !-d $self->pidbase ) {
        make_path( $self->pidbase, { error => \my $err } );
        if (@$err) {
            confess sprintf( "Cannot create pidbase directory '%s': %s",
                $self->pidbase, @$err );
        }
    }

    confess "Cannot write to $file" unless (-e $file ? -w $file : -w $self->pidbase);
    MooseX::Daemonize::Pid::File->new( file => $file );
}

# backwards compat,
sub check      { (shift)->pidfile->is_running }
sub save_pid   { (shift)->pidfile->write      }
sub remove_pid { (shift)->pidfile->remove     }
sub get_pid    { (shift)->pidfile->pid        }

## signal handling ...

sub setup_signals {
    my $self = shift;
    $SIG{'INT'} = sub { $self->shutdown };
# I can't think of a sane default here really ...
#    $SIG{'HUP'} = sub { $self->handle_sighup };
}

sub shutdown {
    my $self = shift;
    $self->pidfile->remove if $self->pidfile->pid == $$;
    exit(0);
}

## daemon control methods ...

sub start {
    my $self = shift;

    $self->clear_status_message;
    $self->clear_exit_code;

    if ($self->pidfile->is_running) {
        $self->exit_code($self->OK);
        $self->status_message('Daemon is already running with pid (' . $self->pidfile->pid . ')');
        return !($self->exit_code);
    }

    if ($self->foreground) {
        $self->is_daemon(1);
    }
    else {
        eval { $self->daemonize };
        if ($@) {
            $self->exit_code($self->ERROR);
            $self->status_message('Start failed : ' . $@);
            return !($self->exit_code);
        }
    }

    unless ($self->is_daemon) {
        $self->exit_code($self->OK);
        $self->status_message('Start succeeded');
        return !($self->exit_code);
    }

    $self->pidfile->pid($$);

    # Change to basedir
    chdir $self->basedir;

    $self->pidfile->write;
    $self->setup_signals;
    return $$;
}

sub status {
    my $self = shift;

    $self->clear_status_message;
    $self->clear_exit_code;

    if ($self->pidfile->is_running) {
        $self->exit_code($self->OK);
        $self->status_message('Daemon is running with pid (' . $self->pidfile->pid . ')');
    }
    else {
        $self->exit_code($self->ERROR);
        $self->status_message('Daemon is not running with pid (' . $self->pidfile->pid . ')');
    }

    return !($self->exit_code);
}

sub restart {
    my $self = shift;

    $self->clear_status_message;
    $self->clear_exit_code;

    unless ($self->stop) {
        $self->exit_code($self->ERROR);
        $self->status_message('Restart (Stop) failed : ' . $@);
    }

    unless ($self->start) {
        $self->exit_code($self->ERROR);
        $self->status_message('Restart (Start) failed : ' . $@);
    }

    if ($self->exit_code == $self->OK) {
        $self->exit_code($self->OK);
        $self->status_message("Restart successful");
    }

    return !($self->exit_code);
}

# Make _kill *really* private
my $_kill;

sub stop {
    my $self = shift;

    $self->clear_status_message;
    $self->clear_exit_code;

    # if the pid is not running
    # then we don't need to stop
    # anything ...
    if ($self->pidfile->is_running) {

        # if we are foreground, then
        # no need to try and kill
        # ourselves
        unless ($self->foreground) {

            # kill the process ...
            eval { $self->$_kill($self->pidfile->pid) };
            # and complain if we can't ...
            if ($@) {
                $self->exit_code($self->ERROR);
                $self->status_message('Stop failed : ' . $@);
            }
            # or gloat if we succeed ..
            else {
                $self->exit_code($self->OK);
                $self->status_message('Stop succeeded');
            }

        }
    }
    else {
        # this just returns the OK
        # exit code for now, but
        # we should make this overridable
        $self->exit_code($self->OK);
        $self->status_message("Not running");
    }

    # if we are returning to our script
    # then we actually need the opposite
    # of what the system/OS expects
    return !($self->exit_code);
}

$_kill = sub {
    my ( $self, $pid ) = @_;
    return unless $pid;
    unless ( CORE::kill 0 => $pid ) {
        # warn "$pid already appears dead.";
        return;
    }

    if ( $pid eq $$ ) {
        die "$pid is us! Can't commit suicide.";
    }

    my $timeout = $self->stop_timeout;

    # kill 0 => $pid returns 0 if the process is dead
    # $!{EPERM} could also be true if we cant kill it (permission error)

    # Try SIGINT ... 2s ... SIGTERM ... 2s ... SIGKILL ... 3s ... UNDEAD!
    my $terminating_signal;
    for ( [ 2, $timeout ], [15, $timeout], [9, $timeout * 1.5] ) {
        my ($signal, $timeout) = @$_;
        $timeout = int $timeout;

        CORE::kill($signal, $pid);

        while ($timeout) {
            unless(CORE::kill 0 => $pid or $!{EPERM}) {
                $terminating_signal = $signal;
                last;
            }
            $timeout--;
            sleep(1) if $timeout;
        }

        last if $terminating_signal;
    }

    if($terminating_signal) {
        if($terminating_signal == 9) {
            # clean up the pidfile ourselves iff we used -9 and it worked
            warn "Had to resort to 'kill -9' and it worked, wiping pidfile";
            eval { $self->pidfile->remove };
            if ($@) {
                warn "Could not remove pidfile ("
                   . $self->pidfile->file
                   . ") because : $!";
            }
        }
        return;
    }

    # IF it is still running
    Carp::carp "$pid doesn't seem to want to die.";     # AHH EVIL DEAD!
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Daemonize - Role for daemonizing your Moose based application

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    package My::Daemon;
    use Moose;

    with qw(MooseX::Daemonize);

    # ... define your class ....

    after start => sub {
        my $self = shift;
        return unless $self->is_daemon;
        # your daemon code here ...
    };

    # then in your script ...

    my $daemon = My::Daemon->new_with_options();

    my ($command) = @{$daemon->extra_argv}
    defined $command || die "No command specified";

    $daemon->start   if $command eq 'start';
    $daemon->status  if $command eq 'status';
    $daemon->restart if $command eq 'restart';
    $daemon->stop    if $command eq 'stop';

    warn($daemon->status_message);
    exit($daemon->exit_code);

=head1 DESCRIPTION

Often you want to write a persistent daemon that has a pid file, and responds
appropriately to Signals. This module provides a set of basic roles as an
infrastructure to do that.

=head1 WARNING

The maintainers of this module now recommend using L<Daemon::Control> instead.

=head1 CAVEATS

When going into background MooseX::Daemonize closes all open file
handles. This may interfere with you logging because it may also close the log
file handle you want to write to. To prevent this you can either defer opening
the log file until after start. Alternatively, use can use the
'dont_close_all_files' option either from the command line or in your .sh
script.

Assuming you want to use Log::Log4perl for example you could expand the
MooseX::Daemonize example above like this.

    after start => sub {
        my $self = shift;
        return unless $self->is_daemon;
        Log::Log4perl->init(\$log4perl_config);
        my $logger = Log::Log4perl->get_logger();
        $logger->info("Daemon started");
        # your daemon code here ...
    };

=head1 ATTRIBUTES

This list includes attributes brought in from other roles as well
we include them here for ease of documentation. All of these attributes
are settable though L<MooseX::Getopt>'s command line handling, with the
exception of C<is_daemon>.

=over

=item I<progname Path::Class::Dir | Str>

The name of our daemon, defaults to C<$package_name =~ s/::/_/>;

=item I<pidbase Path::Class::Dir | Str>

The base for our PID, defaults to C</var/run/>

=item I<basedir Path::Class::Dir | Str>

The directory we chdir to; defaults to C</>.

=item I<pidfile MooseX::Daemonize::Pid::File | Str>

The file we store our PID in, defaults to C<$pidbase/$progname.pid>

=item I<foreground Bool>

If true, the process won't background. Useful for debugging. This option can
be set via Getopt's -f.

=item I<no_double_fork Bool>

If true, the process will not perform the typical double-fork, which is extra
added protection from your process accidentally acquiring a controlling terminal.
More information can be found by Googling "double fork daemonize".

=item I<ignore_zombies Bool>

If true, the process will not clean up zombie processes.
Normally you don't want this.

=item I<dont_close_all_files Bool>

If true, the objects open filehandles will not be closed when daemonized.
Normally you don't want this.

=item I<is_daemon Bool>

If true, the process is the backgrounded daemon process, if false it is the
parent process. This is useful for example in an C<after 'start' => sub { }>
block.

B<NOTE:> This option is explicitly B<not> available through L<MooseX::Getopt>.

=item I<stop_timeout>

Number of seconds to wait for the process to stop, before trying harder to kill
it. Defaults to 2 seconds.

=back

These are the internal attributes, which are not available through MooseX::Getopt.

=over 4

=item I<exit_code Int>

=item I<status_message Str>

=back

=head1 METHODS

=head2 Daemon Control Methods

These methods can be used to control the daemon behavior. Every effort
has been made to have these methods DWIM (Do What I Mean), so that you
can focus on just writing the code for your daemon.

Extending these methods is best done with the L<Moose> method modifiers,
such as C<before>, C<after> and C<around>.

=over 4

=item B<start>

Setup a pidfile, fork, then setup the signal handlers.

=item B<stop>

Stop the process matching the pidfile, and unlinks the pidfile.

=item B<restart>

Literally this is:

    $self->stop();
    $self->start();

=item B<status>

=item B<shutdown>

=back

=head2 Pidfile Handling Methods

=over 4

=item B<init_pidfile>

This method will create a L<MooseX::Daemonize::Pid::File> object and tell
it to store the PID in the file C<$pidbase/$progname.pid>.

=item B<check>

This checks to see if the daemon process is currently running by checking
the pidfile.

=item B<get_pid>

Returns the PID of the daemon process.

=item B<save_pid>

Write the pidfile.

=item B<remove_pid>

Removes the pidfile.

=back

=head2 Signal Handling Methods

=over 4

=item B<setup_signals>

Setup the signal handlers, by default it only sets up handlers for SIGINT and
SIGHUP. If you wish to add more signals just use the C<after> method modifier
and add them.

=item B<handle_sigint>

Handle a INT signal, by default calls C<$self->stop()>

=item B<handle_sighup>

Handle a HUP signal. By default calls C<$self->restart()>

=back

=head2 Exit Code Methods

These are overridable constant methods used for setting the exit code.

=over 4

=item OK

Returns 0.

=item ERROR

Returns 1.

=back

=head2 Introspection

=over 4

=item meta()

The C<meta()> method from L<Class::MOP::Class>

=back

=head1 DEPENDENCIES

L<Moose>, L<MooseX::Getopt>, L<MooseX::Types::Path::Class> and L<POSIX>

=head1 INCOMPATIBILITIES

Obviously this will not work on Windows.

=head1 SEE ALSO

L<Daemon::Control>, L<Proc::Daemon>, L<Daemon::Generic>

=head1 THANKS

Mike Boyko, Matt S. Trout, Stevan Little, Brandon Black, Ash Berlin and the
#moose denizens

Some bug fixes sponsored by Takkle Inc.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=MooseX-Daemonize>
(or L<bug-MooseX-Daemonize@rt.cpan.org|mailto:bug-MooseX-Daemonize@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://lists.perl.org/list/moose.html>.

There is also an irc channel available for users of this distribution, at
L<C<#moose> on C<irc.perl.org>|irc://irc.perl.org/#moose>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Chris Prather <chris@prather.org>

=back

=head1 CONTRIBUTORS

=for stopwords Karen Etheridge Michael Reddick Yuval Kogman Ash Berlin Brandon L Black David Steinbrunner Dave Rolsky Chisel Wright

=over 4

=item *

Karen Etheridge <ether@cpan.org>

=item *

Michael Reddick <michael.reddick@gmail.com>

=item *

Yuval Kogman <nothingmuch@woobling.org>

=item *

Ash Berlin <ash@cpan.org>

=item *

Brandon L Black <blblack@gmail.com>

=item *

David Steinbrunner <dsteinbrunner@pobox.com>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Chisel Wright <chisel@chizography.net>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
