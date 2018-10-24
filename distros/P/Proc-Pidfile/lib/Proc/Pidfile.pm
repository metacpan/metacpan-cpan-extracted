package Proc::Pidfile;
$Proc::Pidfile::VERSION = '1.09';
use 5.006;
use strict;
use warnings;

use Fcntl                   qw/ :flock         /;
use File::Basename          qw/ basename       /;
use Carp                    qw/ carp croak     /;
use Time::HiRes             qw/ usleep         /;
use File::Spec::Functions   qw/ catfile tmpdir /;

sub new 
{ 
    my $class = shift;
    my %args = @_;
    my $self = bless \%args, $class;

    $self->{retries} = 2 unless defined($self->{retries});

    unless ( $self->{pidfile} ) {
        my $basename = basename( $0 );
        my $dir      = tmpdir();

        croak "Can't write to $dir\n" unless -w $dir;

        my $pidfile  = catfile($dir, "$basename.pid");

        # untaint the path, since it includes externally generated info
        # TODO: should we be a bit more pedantic on "valid path"?
        $pidfile = $1 if ($pidfile =~ /^\s*(.*)\s*/);

        $self->_verbose( "pidfile: $pidfile\n" );
        $self->{pidfile} = $pidfile;
    }
    $self->_create_pidfile();
    return $self;
}

sub DESTROY
{
    my $self = shift;

    $self->_destroy_pidfile();
}

sub pidfile
{
    my $self = shift;
    return $self->{pidfile};
}

sub _verbose
{
    my $self = shift;
    return unless $self->{verbose};
    print STDERR @_;
}

sub _get_pid
{
    my $self = shift;
    my $pidfile = $self->{pidfile};
    $self->_verbose( "get pid from $pidfile\n" );
    open( PID, $pidfile ) or croak "can't read pid file $pidfile\n";
    flock( PID, LOCK_SH ) or croak "can't lock pid file $pidfile\n";
    my $pid = <PID>;
    if (defined($pid) && $pid =~ /([0-9]+)/) {
        $pid = $1;
    }
    else {
        croak "can't get pid from pidfile $pidfile\n";
    }
    chomp( $pid );
    flock( PID, LOCK_UN );
    close( PID );
    $self->_verbose( "pid = $pid\n" );
    return $pid;
}

sub _is_running
{
    my $pid = shift;

    if ($^O eq 'riscos') {
        require Proc::ProcessTable;

        my $table = Proc::ProcessTable->new()->table;
        my %processes = map { $_->pid => $_ } @$table;
        return exists $processes{$pid};
    }
    else {
        return kill(0, $pid) || $!{'EPERM'};
    }
}

sub _create_pidfile
{
    my $self    = shift;
    my $pidfile = $self->{pidfile};
    my $attempt = 1;

    while ( -e $pidfile ) {
        $self->_verbose( "pidfile $pidfile exists\n" );
        my $pid = $self->_get_pid();
        $self->_verbose( "pid in pidfile $pidfile = $pid\n" );
        if ( _is_running( $pid ) ) {
            
            # this might be a race condition, or parallel smoke testers,
            # so we'll back off a random amount of time and try again
            if ($attempt <= $self->{retries}) {
                ++$attempt;
                # TODO: let's try this. Guessing we don't have to
                #       bother with increasing backoff times
                my $backoff = 100 + rand(300);
                $self->_verbose("backing off for $backoff microseconds before trying again");
                usleep(100 + rand(300));
                next;
            }

            if ( $self->{silent} ) {
                exit;
            }
            else {
                croak "$0 already running: $pid ($pidfile)\n";
            }
        }
        else {
            $self->_verbose( "$pid has died - replacing pidfile\n" );
            open( PID, ">$pidfile" ) or croak "Can't write to $pidfile\n";
            print PID "$$\n";
            close( PID );
            last;
        }
    }

    if (not -e $pidfile) {
        $self->_verbose( "no pidfile $pidfile\n" );
        open( PID, ">$pidfile" ) or croak "Can't write to $pidfile: $!\n";
        flock( PID, LOCK_EX ) or croak "Can't lock pid file $pidfile\n";
        print PID "$$\n" or croak "Can't write to pid file $pidfile\n";
        flock( PID, LOCK_UN );
        close( PID ) or croak "Can't close pid file $pidfile: $!\n";
        $self->_verbose( "pidfile $pidfile created\n" );
    }

    $self->{created} = 1;
}

sub _destroy_pidfile
{
    my $self = shift;

    return unless $self->{created};
    my $pidfile = $self->{pidfile};
    $self->_verbose( "destroy $pidfile\n" );
    if ( $pidfile and -e $pidfile ) {
        my $pid = $self->_get_pid();
        $self->_verbose( "pid in $pidfile = $pid\n" );
        if ( $pid == $$ ) {
            $self->_verbose( "remove pidfile: $pidfile\n" );
            unlink( $pidfile ) if $pidfile and -e $pidfile;
        }
        elsif ($^O ne 'MSWin32' && $^O ne 'riscos') {
            $self->_verbose(  "$pidfile not my pidfile - maybe my parent's?\n" );
            my $ppid = getppid();
            $self->_verbose(  "parent pid = $ppid\n" );
            if ( $ppid != $pid ) {
                carp "pid $pid in $pidfile is not mine ($$) - I am $0 - or my parents ($ppid)\n";
            }
        }
        else {
            $self->_verbose(  "$pidfile not my pidfile - can't check if it's my parent's on this OS\n" );
        }
    }
    else {
        carp "pidfile $pidfile doesn't exist\n";
    }
}

#------------------------------------------------------------------------------
#
# Start of POD
#
#------------------------------------------------------------------------------

=head1 NAME

Proc::Pidfile - a simple OO Perl module for maintaining a process id file for
the curent process

=head1 SYNOPSIS

    my $pp = Proc::Pidfile->new( pidfile => "/path/to/your/pidfile" );
    # if the pidfile already exists, die here
    $pidfile = $pp->pidfile();
    undef $pp;
    # unlink $pidfile here

    my $pp = Proc::Pidfile->new();
    # creates pidfile in default location
    my $pidfile = $pp->pidfile();
    # tells you where this pidfile is ...

    my $pp = Proc::Pidfile->new( silent => 1 );
    # if the pidfile already exists, exit silently here
    ...
    undef $pp;

=head1 DESCRIPTION

Proc::Pidfile is a very simple OO interface which manages a pidfile for the
current process.
You can pass the path to a pidfile to use as an argument to the constructor,
or you can let Proc::Pidfile choose one
("/$tmpdir/$basename", where C<$tmpdir> is from C<File::Spec>).

Pidfiles created by Proc::Pidfile are automatically removed on destruction of
the object. At destruction, the module checks the process id in the pidfile
against its own, and against its parents (in case it is a spawned child of the
process that originally created the Proc::Pidfile object), and barfs if it
doesn't match either.

If you pass a "silent" parameter to the constructor, then it will still check
for the existence of a pidfile, but will exit silently if one is found. This is
useful for, for example, cron jobs, where you don't want to create a new
process if one is already running, but you don't necessarily want to be
informed of this by cron.

=head2 Retries

If another instance of your script is already running,
we'll retry a couple of times,
with a random number of microseconds between each attempt.

You can specify the number of retries, for example if you
want to try more times for some reason:

 $pidfile = $pp->pidfile(retries => 4);

By default this is set to 2,
which means if the first attempt to set up a pidfile fails,
it will try 2 more times, so three attempts in total.

Setting retries to 0 (zero) will disable this feature.


=head1 SEE ALSO

L<Proc::PID::File> - provides a similar interface.

L<PidFile> - provides effectively the same functionality,
but via class methods. Hasn't been updated since 2011,
and has quite a few CPAN Testers fails.

L<IPC::Pidfile> - provides a simple interface, but has some restrictions,
and its documentation even recommends you consider a different module,
as it has a race condition.

L<IPC::Lockfile> - very simple interface, and uses a different mechanism:
it tries to lock the script file which used the module.
The trouble with that is that you might be running someone else's script,
and thus can't lock it.

L<Sys::RunAlone> - another one with a simple default interface,
but can be configured to retry. Based on locking, rather than a pid file.
Doesn't work on Windows.

L<Linux::Pidfile> - Linux-specific solution.

=head1 REPOSITORY

L<https://github.com/neilbowers/Proc-Pidfile>

=head1 AUTHOR

Ave Wrigley E<lt>awrigley@cpan.orgE<gt>

Now maintained by Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2003 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
#
# True ...
#
#------------------------------------------------------------------------------

1;

