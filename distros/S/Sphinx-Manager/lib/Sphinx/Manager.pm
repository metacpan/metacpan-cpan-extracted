package Sphinx::Manager;

use warnings;
use strict;
use base qw/Class::Accessor::Fast/;

use Carp qw/croak/;
use Proc::ProcessTable;
use Path::Class;
use File::Spec;
use Sphinx::Config;
use Errno qw/ECHILD/;
use POSIX;

our $VERSION = '0.08';

__PACKAGE__->mk_accessors(qw/config_file 
			  pid_file 
			  bindir 
			  searchd_args 
                          searchd_sudo
			  indexer_args 
                          indexer_sudo
			  process_timeout 
                          pre_exec_callback
                          max_fd
			  debug/);

my $default_config_file = 'sphinx.conf';
my $default_process_timeout = 10;
my $default_max_fd = 100;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);

    $self->debug(0) unless $self->debug;
    $self->config_file($default_config_file) unless $self->config_file;
    $self->process_timeout($default_process_timeout) unless $self->process_timeout;
    $self->max_fd($default_max_fd);

    return $self;
}

# Determines pid_file from explicitly given file or by reading the config
sub _find_pidfile {
    my $self = shift;

    my $config_file = $self->config_file || $default_config_file;

    if (my $file = $self->pid_file) {
	return $self->{_pid_file} = Path::Class::file($file);
    }
    if ($self->{_config_file} && $config_file eq $self->{_config_file}) {
	# Config file unchanged
	return $self->{_pid_file} if $self->{_pid_file};
    }
    $self->_load_config_file;
    return $self->{_pid_file};
}

# Loads given config file and extracts the pid_file
sub _load_config_file {
    my $self = shift;

    my $config_file = $self->config_file || $default_config_file;

    my $config = Sphinx::Config->new;
    $config->parse($config_file);
    if (my $pid_file = $config->get('searchd', undef, 'pid_file')) {
	$self->{_pid_file} = Path::Class::file($pid_file);
    }
    $self->{_config_file} = Path::Class::file($config_file); # records which file we have loaded
}

# Find executable file
sub _find_exe {
    my $self = shift;
    my $name = shift;

    return Path::Class::file($self->bindir, $name) if $self->bindir;

    my @candidates = map { Path::Class::file($_, $name) } File::Spec->path();
    for my $bin (@candidates) {
	return $bin if -x "$bin";
    }
    die "Failed to find $name binary in bindir or system path; please specify bindir correctly";
}

# Find a process for given pid; return the PID if the process matches the given pattern
# If pid is not given, returns all process IDs matching the pattern
sub _findproc {
    my ($self, $pid, $pat) = @_;

    my $t = Proc::ProcessTable->new;

    if ($pid) {
	my $process;
	for (@{$t->table}) {
	    $process = $_, last if $_->pid == $pid;
	}
	return [ $pid ] if $process;
    }
    else {
	my @procs;
	for (@{$t->table}) {
	    my $cmndline = $_->{cmndline} || $_->{fname};
	    warn "Checking $cmndline against $pat" if $self->debug > 2;
	    push(@procs, $_->pid) if $cmndline =~ /$pat/;
	}
	return \@procs;
    }

    return [];
}

# Waits for a PID to disappear from the process table; returns 1 if found, 0 if timeout.
sub _wait_for_death {
    my $self = shift;
    my $pid = shift;
    my $timeout = $self->process_timeout || $default_process_timeout;

    my $ret = 0;
    my $t = time() + $timeout;
    while (time() < $t) {
	$ret++, last unless @{$self->_findproc($pid)};
	sleep(1);
    }
    return $ret;
}

# Waits for a process matching a given pattern to appear in the process table; returns 1 if found, 0 if timeout.
sub _wait_for_proc {
    my $self = shift;
    my $pat = shift;
    my $timeout = $self->process_timeout || $default_process_timeout;

    my $ret = 0;
    my $t = time() + $timeout;
    while (time() < $t) {
	$ret++, last if @{$self->_findproc(undef, $pat)};
	sleep(1);
    }
    return $ret;
}

sub _system_with_status
{
    my (@args) = @_;

    if ( ! @args ){
        return "No parameters provided";
    }

    local $SIG{'CHLD'} = 'DEFAULT';

    my $output = qx{@args};
    my $status = $?;

    unless ($status == 0) {
        if ($? == -1) {
            return "@args failed to execute: $!";
        }
        if ($? & 127) {
            return sprintf("@args died with signal %d, %s coredump\n",
                           ($? & 127),  ($? & 128) ? 'with' : 'without');
        }
        return sprintf("@args exited with value %d. Output from execution:\n%s\n", $? >> 8, $output);
    }
    return '';
}

# Get regexp for matching command line
sub _get_searchd_matchre {
    my $self = shift;
    my $c = $self->{_config_file}->stringify;
    return qr/searchd.*(?:\s|=)$c(?:$|\s)/;
}

sub get_searchd_pid {
    my $self = shift;

    my $pids = [];
    my $pidfile = $self->_find_pidfile;
    if ( -f "$pidfile" ) {
	if (my $pid = $pidfile->slurp(chomp => 1)) {
	    push(@$pids, $pid) if @{$self->_findproc($pid, 'searchd')};
	}
    }
    if (! @$pids) {
	# backup plan if PID file is empty or invalid
	$pids = $self->_findproc(undef, $self->_get_searchd_matchre);
    }
    warn("Found searchd pid " . join(", ", @$pids)) if $self->debug;
    return $pids;
}

sub start_searchd {
    my $self = shift;
    my $ok_if_running = shift;

    my $pidfile = $self->_find_pidfile;
    warn "start_searchd: Checking pidfile $pidfile" if $self->debug;

    if ( -f "$pidfile" ) {
	my $pid = Path::Class::file($pidfile)->slurp(chomp => 1);
	warn "start_searchd: Found PID $pid" if $self->debug;
	if ($pid && @{$self->_findproc($pid, qr/searchd/)}) {
	    return if $ok_if_running;
	    die "searchd is already running, PID $pid";
	}
    }

    my @args;
    if (my $sudo = $self->searchd_sudo) {
	if (ref($sudo) ne 'ARRAY') {
	    $sudo = [ split(/\s+/, $sudo) ];
	}
	push(@args, @$sudo);
    }
    push(@args, $self->_find_exe('searchd'));
    push(@args, "--config", $self->{_config_file}->stringify);
    push(@args, @{$self->searchd_args}) if $self->searchd_args;
    warn("Executing " . join(" ", @args)) if $self->debug;

    local $SIG{CHLD} = 'IGNORE';
    my $pid = fork();
    die "Fork failed: $!" unless defined $pid;
    if ($pid == 0) {
	fork() and exit; # double fork to ensure detach

        if ($self->pre_exec_callback) {
            # give caller the opportunity to tidy up resources after the fork
            $self->pre_exec_callback->($self, \@args);
        }
        else {
            # close any open files.  We don't know which are open so close lots.
            POSIX::close($_) for 0 .. $self->max_fd;
        }

	exec(@args)
	    or die("Failed to exec @args}: $!");
    }

    die "Searchd not running after timeout" 
	unless $self->_wait_for_proc($self->_get_searchd_matchre);

}

sub _kill {
    my ($self, $sig, @pids) = @_;

    if (my $sudo = $self->searchd_sudo) {
	my @args;
	if (ref($sudo) ne 'ARRAY') {
	    $sudo = [ split(/\s+/, $sudo) ];
	}
	push(@args, @$sudo);
	push(@args, 'kill');
	push(@args, "-$sig", @pids);
	_system_with_status(@args);
    }
    else {
	kill $sig, @pids;
    }
}

sub stop_searchd {
    my $self = shift;

    my $pids = $self->get_searchd_pid;
    if (@$pids) {
	$self->_kill(15, @$pids);
	unless ($self->_wait_for_death(@$pids)) {
	    $self->_kill(9, @$pids);
	    unless ($self->_wait_for_death(@$pids)) {
		die "Failed to stop searchd PID " . join(", ", @$pids) . ", even with sure kill";
	    }
	}
    }
    # nothing found to kill so assume success
}

sub restart_searchd {
    my $self = shift;
    $self->stop_searchd;
    $self->start_searchd(1);
}

sub reload_searchd {
    my $self = shift;
    
    my $pids = $self->get_searchd_pid;
    if (@$pids) {
	# send HUP
	$self->_kill(1, @$pids);
    }
    else {
	$self->start_searchd(1);
    }
}

sub run_indexer {
    my $self = shift;
    my @extra_args = @_;

    my @args;
    if (my $sudo = $self->indexer_sudo) {
	if (ref($sudo) ne 'ARRAY') {
	    $sudo = [ split(/\s+/, $sudo) ];
	}
	push(@args, @$sudo);
    }
    push(@args, my $indexer = $self->_find_exe('indexer'));

    warn("Using indexer @args") if $self->debug;
    die "Cannot execute Sphinx indexer binary $indexer" unless -x "$indexer";

    my $config = $self->config_file || $default_config_file;
    push(@args, "--config", $config);
    push(@args, @{$self->indexer_args}) if $self->indexer_args;
    push(@args, @extra_args) if @extra_args;

    if (my $status = _system_with_status(@args)) {
	die $status;
    }
}

1;

__END__ 

=head1 NAME

Sphinx::Manager - Sphinx search engine management (start/stop)

=head1 SYNOPSIS

    use Sphinx::Manager;

    my $mgr = Sphinx::Manager->new({ config_file => '/etc/sphinx.conf' });
    $mgr->start_searchd;
    $mgr->restart_searchd;
    $mgr->reload_searchd;
    $mgr->stop_searchd;
    $mgr->get_searchd_pid;
    $mgr->run_indexer;

=head1 DESCRIPTION

This module provides utilities to start, stop, restart, and reload the Sphinx
search engine binary (searchd), and to run the Sphinx indexer program.  The
utilities are designed to handle abnormal conditions, such as PID files not
being present when expected, and so should be robust in most situations.

=head1 CONSTRUCTOR

=head2 new

    $mgr = Sphinx::Manager->new(\%opts);

Create a new Sphinx manager.  The names of options are the same as the
setter/getter functions listed below.


=cut

=head1 SETTERS/GETTERS

=head2 config_file

    $mgr->config_file($filename)
    $filename = $mgr->config_file;

Set/get the configuration file.  Defaults to sphinx.conf in current working directory.

=head2 pid_file

    $mgr->pid_file($filename)
    $filename = $mgr->pid_file;

Set/get the PID file.  If given, this will be used in preference to any value in the given config_file.

=head2 bindir

    $mgr->bindir($dir)
    $dir = $mgr->bindir;

Set/get the directory in which to find the Sphinx binaries.

=head2 debug

    $mgr->debug(1);
    $mgr->debug(0);
    $debug_state = $mgr->debug;

Enable/disable debugging messages, or read back debug status.

=head2 process_timeout

    $mgr->process_timeout($secs)
    $secs = $mgr->process_timeout;

Set/get the time (in seconds) to wait for processes to start or stop.

=head2 searchd_bin

Optional full path to searchd.  If not specified, normal rules for finding an executable in the PATH environment are used.

=head2 searchd_args

    $mgr->searchd_args(\@args)
    $args = $mgr->searchd_args;

Set/get the extra command line arguments to pass to searchd when started using
start_searchd.  These should be in the form of an array, each entry comprising
one option or option argument.  Arguments should exclude '--config CONFIG_FILE',
which is included on the command line by default.

=head2 searchd_sudo

Optional sudo wrapper for running searchd as root or another user.
Set to 'sudo', or 'sudo -u USER', or sudo with any other options.  If
not set, searchd is run as the current user.  Of course, for this to
work, sudo privileges should be enabled for the current user and
typically without a password.  Could also be set to the name of any
other wrapper program to provide custom functionality.

=head2 indexer_args

    $mgr->indexer_args(\@args)
    $args = $mgr->indexer_args;

Set/get the extra command line arguments to pass to the indexer program when
started using run_indexer.  These should be in the form of an array, each entry
comprising one option or option argument.  Arguments should exclude '--config
CONFIG_FILE', which is included on the command line by default.


=head2 indexer_sudo

Same as L<searchd_sudo> above, for running the indexer.

=head2 max_fd

Maximum file descriptor number to close prior to launching searchd.
This is to support environments such as mod_perl where open file
descriptors would otherwise be inherited and left open in the
subprocess.  Detecting open files is problematic so instead we close
all files from 0 to max_fd.

=head2 pre_exec_callback

A callback function that provides an alternative to max_fd, allowing
the provider of the callback function to clean up resources (like
closing files) after the process forks and before it execs searchd.
If pre_exec_callback is provided, max_fd is not used.

The callback is invoked as

  pre_exec_callback($mgr, \@searchd_exec_args)

This also provides the opportunity to modify @searchd_exec_args if the caller wishes.

=head1 METHODS

=head2 start_searchd

    $mgr->start_searchd;
    $mgr->start_searchd($ok_if_running);

Starts the Sphinx searchd daemon.  Unless $ok_if_running is set, dies if searchd
cannot be started or if it is already running.  If $ok_if_running is set and
searchd is found to be already running, returns quietly without trying to start
it.

=head2 stop_searchd

    $mgr->stop_searchd;

Stops Sphinx searchd daemon.  Dies if searchd cannot be stopped.


=head2 restart_searchd

    $mgr->restart_searchd;

Stops and then starts the searchd daemon.

=head2 reload_searchd

    $mgr->reload_searchd;

Sends a HUP signal to the searchd daemon if it is running, to tell it to reload
its databases; otherwise starts searchd.

=head2 get_searchd_pid

    $pids = $mgr->get_searchd_pid;

Returns an array ref containing the PID(s) of the searchd daemon.  If the PID
file is in place and searchd is running, then an array containing a single PID
is returned.  If the PID file is not present or is empty, the process table is
checked for other searchd processes running with the specified config file; if
found, all are returned in the array.


=head2 run_indexer(@args)

Runs the indexer program; dies on error.  Arguments passed to the indexer are
"--config CONFIG_FILE" followed by args set through indexer_args, followed by
any additional args given as parameters to run_indexer.

=head1 CAVEATS

This module has been tested primarily on Linux.  It should work on any other
operating systems where fork() is supported and Proc::ProcessTable works.

=head1 SEE ALSO

L<Sphinx::Search>, L<Sphinx::Config>

=head1 AUTHOR

Jon Schutz, L<http://notes.jschutz.net>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sphinx-config at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sphinx-Manager>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sphinx::Manager

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sphinx-Manager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sphinx-Manager>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sphinx-Manager>

=item * Search CPAN

L<http://search.cpan.org/dist/Sphinx-Manager>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Jon Schutz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

