#-----------------------------------------------------------------
# Proc::Async
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer se below.
#
# ABSTRACT: Running and monitoring processes asynchronously
# PODNAME: Proc::Async
#-----------------------------------------------------------------

use warnings;
use strict;
package Proc::Async;

our $VERSION = '0.2.0'; # VERSION

use Carp;
use File::Temp qw{ tempdir };
use File::Path qw{ remove_tree };
use File::Spec;
use File::Find;
use File::Slurp;
use Proc::Async::Config;
use Proc::Daemon;
use Config;

use constant STDOUT_FILE => '___proc_async_stdout___';
use constant STDERR_FILE => '___proc_async_stderr___';
use constant CONFIG_FILE => '___proc_async_status.cfg';

use constant {
    STATUS_UNKNOWN     => 'unknown',
    STATUS_CREATED     => 'created',
    STATUS_RUNNING     => 'running',
    STATUS_COMPLETED   => 'completed',
    STATUS_TERM_BY_REQ => 'terminated by request',
    STATUS_TERM_BY_ERR => 'terminated by error',
};

# options used in the start() method
use constant {
    ALLOW_SHELL => 'ALLOW_SHELL',
    TIMEOUT     => 'TIMEOUT',
};

#
my $KNOWN_OPTIONS = {
    ALLOW_SHELL() => 1,
    TIMEOUT() => 1,
};

#-----------------------------------------------------------------
# Start an external program and return its ID.
#    starts ($args, [$options])
#    starts (@args, [$options])
#  $args    ... an arrayref with the full command-line (including the
#               external program name)
#  @args    ... an array with the full command-line (including the
#               external program name)
#  $options ... a hashref with additional options:
#               ALLOW_SHELL => 1
#               TIMEOUT => number of second to spend
#-----------------------------------------------------------------
sub start {
    my $class = shift;
    croak ("START: Undefined external process.")
        unless @_ > 0;
    my ($args, $options) = _process_start_args (@_);
    _check_options ($options);

    # create a job ID and a job directory
    my $jobid = _generate_job_id ($options);
    my $dir = _id2dir ($jobid);

    # create configuration file
    my ($cfg, $cfgfile) = _start_config ($jobid, $args, $options);

    # demonize itself
    my $daemon = Proc::Daemon->new(
        work_dir     => $dir,
        child_STDOUT => File::Spec->catfile ($dir, STDOUT_FILE),
        child_STDERR => File::Spec->catfile ($dir, STDERR_FILE),
        );
    my $daemon_pid = $daemon->Init();
    if ($daemon_pid) {
        # this is a parent of the already detached daemon
        return $jobid;
    }

    #
    # --- this is the daemon (child) branch
    #

    # fork and start an external process
    my $pid = fork();

    if ($pid) {
        #
        # --- this branch is executed in the parent (wrapper) process;
        #

        # update the configuration file
        $cfg->param ("job.pid", $pid);
        update_status ($cfg,
                       STATUS_RUNNING,
                       "started at " . scalar localtime());
        $cfg->param ("job.started", time());
        $cfg->save();

        # wait for the child process to finish
        # TBD: if TIMEOUT then use alarm and non-blocking waitpid
        my $reaped_pid = waitpid ($pid, 0);
        my $reaped_status = $?;

        if ($reaped_status == -1) {
            update_status ($cfg,
                           STATUS_UNKNOWN,
                           "No such child process"); # can happen?

        } elsif ($reaped_status & 127) {
            update_status ($cfg,
                           STATUS_TERM_BY_REQ,
                           "terminated by signal " . ($reaped_status & 127),
                           (($reaped_status & 128) ? "with" : "without") . " coredump",
                           "terminated at " . scalar localtime(),
                           _elapsed_time ($cfg));

        } else {
            my $exit_code = $reaped_status >> 8;
            if ($exit_code == 0) {
                update_status ($cfg,
                               STATUS_COMPLETED,
                               "exit code $exit_code",
                               "completed at " . scalar localtime(),
                               _elapsed_time ($cfg));
            } else {
                update_status ($cfg,
                               STATUS_TERM_BY_ERR,
                               "exit code $exit_code",
                               "completed at " . scalar localtime(),
                               _elapsed_time ($cfg));
            }
        }
        $cfg->save();

        # the wrapper of the daemon finishes; do not return anything
        exit (0);

    } elsif ($pid == 0) {
        #
        # --- this branch is executed in the just started child process
        #

        # replace itself by an external process
        if ($options->{ ALLOW_SHELL() } or @$args > 1) {
            # this allows to execute things such as: 'date | wc'
            exec (@$args) or
                croak "Cannot execute the external process: " . _join_args ($args) . "\n";
        } else {
            # this is always save against interpreting $args by a shell
            exec { $args->[0] } @$args or
                croak "Cannot execute (using an indirect object) the external process: " . _join_args ($args) . "\n";
        }

    } else {
        #
        # --- this branch is executed only when there is an error in the forking
        #
        croak "Cannot start an external process: " . _join_args ($args) . " - $!\n";
    }
}

#-----------------------------------------------------------------
# Pretty print of the list of arguments (given as an arrayref).
#-----------------------------------------------------------------
sub _join_args {
    my $args = shift;
    return join (" ", map {"'$_'"} @$args);
}

#-----------------------------------------------------------------
# Return a pretty-formatted elapsed time of the just finished job.
#-----------------------------------------------------------------
sub _elapsed_time {
    my $cfg = shift;
    my $started = $cfg->param ("job.started");
    return "elapsed time unknown" unless $started;
    my $elapsed = time() - $started;
    return "elapsed time $elapsed seconds";
}

#-----------------------------------------------------------------
# Extract arguments for the start() method and return:
#  ( [args], {options} )
# -----------------------------------------------------------------
sub _process_start_args {
    my @args;
    my $options;
    if (ref $_[0] and ref $_[0] eq 'ARRAY') {
        # arguments for external process are given as an arrayref...
        @args = @{ shift() };
        $options = (ref $_[0] and ref $_[0] eq 'HASH') ? shift @_ : {};
    } else {
        # arguments for external process are given as an array...
        $options = (ref $_[-1] and ref $_[-1] eq 'HASH') ? pop @_ : {};
        @args = @_;
    }
    return (\@args, $options);
}

#-----------------------------------------------------------------
# Update status and its details (just in memory - in the given $cfg).
#-----------------------------------------------------------------
sub update_status {
    my ($cfg, $status, @details) = @_;

    # remove the existing status and its details
    $cfg->remove ("job.status");
    $cfg->remove ("job.status.detail");

    # put updated values
    $cfg->param ("job.status", $status);
    foreach my $detail (@details) {
        $cfg->param ("job.status.detail", $detail);
    }

    # note the finished time if the new status indicates the termination
    if ($status eq STATUS_COMPLETED or
        $status eq STATUS_TERM_BY_REQ or
        $status eq STATUS_TERM_BY_ERR) {
        $cfg->param ("job.ended", time());
    }
}

# -----------------------------------------------------------------
# Return status of the given job (given by $jobid). In array context,
# it also returns (optional) details of the status.
# -----------------------------------------------------------------
sub status {
    my ($class, $jobid) = @_;
    return unless defined wantarray; # don't bother doing more
    my $dir = _id2dir ($jobid);
    my ($cfg, $cfgfile) = $class->get_configuration ($dir);
    my $status = $cfg->param ('job.status') || STATUS_UNKNOWN;
    my @details = ($cfg->param ('job.status.detail') ? $cfg->param ('job.status.detail') : ());
    return wantarray ? ($status, @details) : $status;
}

#-----------------------------------------------------------------
# Return true if the status of the job indicates that the external
# program had finished (well or badly).
# -----------------------------------------------------------------
sub is_finished {
    my ($class, $jobid) = @_;
    my $status = $class->status ($jobid);
    return
        $status eq STATUS_COMPLETED   ||
        $status eq STATUS_TERM_BY_REQ ||
        $status eq STATUS_TERM_BY_ERR;
}

#-----------------------------------------------------------------
# Return the name of the working directory for the given $jobid.
# Or undef if such working directory does not exist.
# -----------------------------------------------------------------
sub working_dir {
    my ($class, $jobid) = @_;
    my $dir = _id2dir ($jobid);
    return -e $dir && -d $dir ? $dir : undef;
}

#-----------------------------------------------------------------
# Return a list of (some) filenames in a job directory that is
# specified by the given $jobid. The filenames are relative to this
# job directory, and they may include subdirectories if there are
# subdirectories within this job directory. The files with the special
# names (see the constants STDOUT_FILE, STDERR_FILE, CONFIG_FILE) are
# ignored. If there is an empty directory, it is also ignored.
#
# For example, if the contents of a job directory is:
#    ___proc_async_stdout___
#    ___proc_async_stderr___
#    ___proc_async_status.cfg
#    a.file
#    a.dir/
#       file1
#       file2
#       b.dir/
#          file3
#    empty.dir/
#
# then the returned list will look like this:
#    ('a.file',
#     'a.dir/file1',
#     'a.dir/file2',
#     'b.dir/file3')
#
# It can croak if the $jobid is empty. If it does not represent an
# existing (and readable) directory, it returns an empty list (without
# croaking).
# -----------------------------------------------------------------
sub result_list {
    my ($class, $jobid) = @_;
    my $dir = _id2dir ($jobid);
    return () unless -e $dir;

    my @files = ();
    find (
        sub {
            my $regex = quotemeta ($dir);
            unless (m{^\.\.?$} || -d) {
                my $file = $File::Find::name;
                $file =~ s{^$regex[/\\]?}{};
                push (@files, $file)
                    unless
                    $file eq STDOUT_FILE or
                    $file eq STDERR_FILE or
                    $file eq CONFIG_FILE;
            }
          },
        $dir);
    return @files;
}

#-----------------------------------------------------------------
# Return the content of the given $file from the job given by
# $jobid. The $file is a relative filename; must be one of those
# returned by method result_list().
#
# Return undef if the $file does not exist (or if it does not exist in
# the list returned by result_list().
# -----------------------------------------------------------------
sub result {
    my ($class, $jobid, $file) = @_;
    my @allowed_files = $class->result_list ($jobid);
    my $dir = _id2dir ($jobid);
    my $is_allowed = exists { map {$_ => 1} @allowed_files }->{$file};
    return unless $is_allowed;
    return read_file (File::Spec->catfile ($dir, $file));
}

#-----------------------------------------------------------------
# Return the content of the STDOUT from the job given by $jobid. It
# may be an empty string if the job did not produce any STDOUT, or if
# the job does not exist anymore.
# -----------------------------------------------------------------
sub stdout {
    my ($class, $jobid) = @_;
    my $dir = _id2dir ($jobid);
    my $file = File::Spec->catfile ($dir, STDOUT_FILE);
    my $content = "";
    eval {
        $content = read_file ($file);
    };
    return $content;
}

#-----------------------------------------------------------------
# Return the content of the STDERR from the job given by $jobid. It
# may be an empty string if the job did not produce any STDERR, or if
# the job does not exist anymore.
# -----------------------------------------------------------------
sub stderr {
    my ($class, $jobid) = @_;
    my $dir = _id2dir ($jobid);
    my $file = File::Spec->catfile ($dir, STDERR_FILE);
    my $content = "";
    eval {
        $content = read_file ($file);
    };
    return $content;
}

#-----------------------------------------------------------------
# Remove files belonging to the given job, including its directory.
# -----------------------------------------------------------------
sub clean {
    my ($class, $jobid) = @_;
    my $dir = _id2dir ($jobid);
    my $file_count = remove_tree ($dir);  #, {verbose => 1});
    return $file_count;
}

# -----------------------------------------------------------------
# Send a signal to the given job. $signal is a positive integer
# between 1 and 64. Default is 9 which means the KILL signal. Return
# true on success, zero on failure (no such job, no such process). It
# may also croak if the $jobid is invalid or missing, at all, or if
# the $signal is invalid.
# -----------------------------------------------------------------
sub signal {
    my ($class, $jobid, $signal) = @_;
    my $dir = _id2dir ($jobid);
    $signal = 9 unless $signal;    # Note that $signal zero is also changed to 9
    croak "Bad signal: $signal.\n"
        unless $signal =~ m{^[+]?\d+$};
    my ($cfg, $cfgfile) = $class->get_configuration ($dir);
    my $pid = $cfg->param ('job.pid');
    return 0 unless $pid;
    return kill $signal, $pid;
}

#-----------------------------------------------------------------
# Check given $options (a hashref), some may be removed.
# -----------------------------------------------------------------
sub _check_options {
    my $options = shift;

    # TIMEOUT may not be used on some architectures; must be a
    # positive integer
    if (exists $options->{TIMEOUT}) {
        my $timeout = $options->{TIMEOUT};
        if (_is_int ($timeout)) {
            if ($timeout == 0) {
                delete $options->{TIMEOUT};
            } elsif ($timeout < 0) {
                delete $options->{TIMEOUT};
                carp "Warning: Option TIMEOUT is negative. Ignored.\n";
            }
        } else {
            delete $options->{TIMEOUT};
            carp "Warning: Option TIMEOUT is not a number (found '$options->{TIMEOUT}'). Ignored.\n";
        }
        if (exists $options->{TIMEOUT}) {
            my $has_nonblocking = $Config{d_waitpid} eq "define" || $Config{d_wait4} eq "define";
            unless ($has_nonblocking) {
                delete $options->{TIMEOUT};
                carp "Warning: Option TIMEOUT cannot be used on this system. Ignored.\n";
            }
        }
    }

    # check for unknown options
    foreach my $key (sort keys %$options) {
        carp "Warning: Unknown option '$key'. Ignored.\n"
            unless exists $KNOWN_OPTIONS->{$key};
    }

}

sub _is_int {
    my ($str) = @_;
    return unless defined $str;
    return $str =~ /^[+-]?\d+$/ ? 1 : undef;
}

#-----------------------------------------------------------------
# Create a configuration instance and load it from the configuration
# file (if exists) for the given job. Return ($cfg, $cfgfile).
# -----------------------------------------------------------------
sub get_configuration {
    my ($class, $jobid) = @_;
    my $dir = _id2dir ($jobid);
    my $cfgfile = File::Spec->catfile ($dir, CONFIG_FILE);
    my $cfg = Proc::Async::Config->new ($cfgfile);
    return ($cfg, $cfgfile);
}

#-----------------------------------------------------------------
# Create and fill the configuration file. Return the filename and a
# configuration instance.
# -----------------------------------------------------------------
sub _start_config {
    my ($jobid, $args, $options) = @_;

    # create configuration file
    my ($cfg, $cfgfile) = Proc::Async->get_configuration ($jobid);

    # ...and fill it
    $cfg->param ("job.id", $jobid);
    foreach my $arg (@$args) {
        $cfg->param ("job.arg", $arg);
    }
    foreach my $key (sort keys %$options) {
        $cfg->param ("option.$key", $options->{$key});
    }
    $cfg->param ("job.status", STATUS_CREATED);

    $cfg->save();
    return ($cfg, $cfgfile);
}

#-----------------------------------------------------------------
# Create and return a unique ID.
#### (the ID may be influenced by some of the $options).
#-----------------------------------------------------------------
sub _generate_job_id {
    # my $options = shift;  # an optional hashref
    # if ($options and exists $options->{DIR}) {
    #   return tempdir ( CLEANUP => 0, DIR => $options->{DIR} );
    # } else {
        # return tempdir ( CLEANUP => 0 );
    # }
    return tempdir (CLEANUP => 0, DIR => File::Spec->tmpdir);
}

#-----------------------------------------------------------------
# Return a name of a directory asociated with the given job ID; in
# this implementation, it returns the same value as the job ID; it
# croaks if called without a parameter OR if $jobid points to a
# strange (not expected) place.
#-----------------------------------------------------------------
sub _id2dir {
    my $jobid = shift;
    croak ("Missing job ID.\n")
        unless $jobid;

    # does the $jobid start in the temporary directory?
    my $tmpdir = File::Spec->tmpdir;  # this must be the same as used in _generate_job_id
    croak ("Invalid job ID '$jobid'.\n")
        unless $jobid =~ m{^\Q$tmpdir\E[/\\]};

    return $jobid;
}

1;



=pod

=head1 NAME

Proc::Async - Running and monitoring processes asynchronously

=head1 VERSION

version 0.2.0

=head1 SYNOPSIS

   use Proc::Async;

   # start an external program
   $jobid = Proc::Async->start ('blastx', '-query', '/data/my.seq', '-out', 'blastout');

   # later, usually from another program (or in another time),
   # investigate what is the external program doing
   if (Proc::Async->is_finished ($jobid)) {
      @files = Proc::Async->result_list ($jobid);
      foreach my $file (@files) {
         print Proc::Async->result ($file);
      }
      print Proc::Async->stdout();
      print Proc::Async->stderr();
   }

   $status = Proc::Async->status ($jobid);

=head1 DESCRIPTION

This module can execute an external process, monitor its state, get
its results and, if needed, kill it prematurely and remove its
results. There are, of course, many modules that cover similar
functionality, including functions directly built-in in Perl. So why
to have this module, at all? The main feature is hidden in the second
part of the module name, the word B<Async>. The individual methods (to
execute, to monitor, to get results, etc.) can be called (almost)
independently from each other, from separate Perl programs, and there
may be any delay between them.

It focuses mainly on invoking external programs from the CGI scripts
in the web applications. Here is a typical scenario: Your CGI script
starts an external program which may take some time before it
finishes. The CGI scripts does not wait for it and returns back,
remembering (e.g. in a form of a hidden variable in the returned HTML
page) the only thing, the ID of the just started job (a
C<jobID>). Meanwhile, the invoked external program has been
I<demonized> (it became a daemon process, a process nobody waits
for). Now you have another CGI script that can use the remembered
C<jobID> to monitor status and get results of the previously started
process.

The core functionality, the demonization, is done by the module
C<Proc::Daemon>. If you plan to write a single program that starts a
daemon process and waits for it, then you may need just the
C<Proc::Daemon> module. But if you wish to split individual calls into
two or more programs then the C<Proc::Async> may be your choice.

=head1 METHODS

All methods of this module are I<class> methods, there is no C<new>
instance constructor. It does not make much sense to have an instance
if you wish to use it from a separate program, does it? The
communication between individual calls is done in a temporary
directory (as it is explained later in this documentation but it is
not important for the module usage).

=head2 start($args [,$options]) I<or> start(@args, [$options])

This method starts an external program, makes a daemon process from
it, does not wait for its completion and returns a token, a job
ID. This token will be used as an argument in all other
methods. Therefore, there is no sense to call any of the other
methods without calling the C<start()> first.

C<$args> is an arrayref with the full command-line (including the
external program name). Or, it can be given as a normal list C<@args>.

For example:

   my $jobid = Proc::Async->start (qw{ wget -O cpan.index.html http://search.cpan.org/index.html });

or

   my $jobid = Proc::Async->start ( [qw{ wget -O cpan.index.html http://search.cpan.org/index.html }] );

If the given array of arguments has only one element, it is still
considered as an array. Therefore, you cannot use a single string
representing the full command-line:

   # this will not work
   $jobid = start ("date -u");

This is a feature not a bug. It prevents to let the shell interprets
the meta-characters inside the arguments. More about it in the Perl's
documentation (try: C<perldoc -f exec>). But sometimes you are willing
to sacrifice safety and to let a shell to act for your benefit. An
example is the usage of a pipe character in the command line. In order
to allow it, you need to specify an option C<Proc::Async::ALLOW_SHELL>
in the start() method:

   # this works
   $jobid = start ("date -u", { Proc::Async::ALLOW_SHELL() => 1 });

   # ...and this works, as well
   # (it prints number 3 to the standard output)
   $jobid = start ("echo one two three | wc -w", { Proc::Async::ALLOW_SHELL() => 1 });

The options (so far only one is recognized) are given as a hashref
that is the last argument of the C<start()> method. The keys of this
hash are defined as constants in this module:

   use constant {
      ALLOW_SHELL => 'ALLOW_SHELL',

   };

For each job, this method creates a temporary directory (within your
system temporary directory, which is, on Unix system, usually C</tmp>)
and change there (C<chdir>) before executing the wanted external
program. Keep this directory change in mind if your external programs
are in the same directory as your Perl program that invokes them. You
can use, for example, the C<FindBin> module to locate them correctly:

   use FindBin qw($Bin);
   ...
   my @args = ("$Bin/my-external-program", ....);
   $jobid = Proc::Async->start (\@args);

If you need to access this job directory (in case that you need more
than provided by the methods of this module), use the method
C<working_dir()> to get its path and name.

=head2 status($jobid)

In scalar context, it returns status of the given process (given by
its $jobid). The status is expressed by a plain text using the
following constants:

   use constant {
       STATUS_UNKNOWN     => 'unknown',
       STATUS_CREATED     => 'created',
       STATUS_RUNNING     => 'running',
       STATUS_COMPLETED   => 'completed',
       STATUS_TERM_BY_REQ => 'terminated by request',
       STATUS_TERM_BY_ERR => 'terminated by error',
   };

In array context, it additionally returns (optional) details of the
status. There can be zero to more details accompanying the status,
e.g. the exit code, or the signal number that caused the process to
die. The details are in plain text, no constants used. For example:

   $jobid = Proc::Async->start ('date');
   @status = Proc::Async->status ($jobid);
   print join ("\n", @status);

will print:

   running
   started at Sat May 18 09:35:27 2013

or

   $jobid = Proc::Async->start ('sleep', 5);
   ...
   @status = Proc::Async->status ($jobid);
   print join ("\n", @status);

will print:

   completed
   exit code 0
   completed at Sat May 18 09:45:12 2013
   elapsed time 5 seconds

or, a case when the started job was killed:

   $jobid = Proc::Async->start ('sleep', 60);
   Proc::Async->signal ($jobid, 9);
   @status = Proc::Async->status ($jobid);
   print join ("\n", @status);

will print:

   terminated by request
   terminated by signal 9
   without coredump
   terminated at Sat May 18 09:41:56 2013
   elapsed time 0 seconds

=head2 is_finished($jobid)

A convenient method that returns true if the status of the job
indicates that the external program had finished (well or badly). Or
false if not. Which includes the case when the state is unknown.

=head2 signal($jobid [,$signal])

It sends a signal to the given job (given by the
C<$jobid>). C<$signal> is a positive integer between 1 and 64. Default
is 9 which means the KILL signal. The available signals are the ones
listed out by C<kill -l> on your system.

It returns true on success, zero on failure (no such job, no such
process). It can also croak if the C<$signal> is invalid.

=head2 result_list($jobid)

It returns a list of (some) filenames that exist in the job directory
that is specified by the given $jobid. The filenames are relative to
this job directory, and they may include subdirectories if there are
subdirectories within this job directory (it all depends what your
external program created there). For example:

   $jobid = Proc::Async->start (qw{ wget -o log.file -O output.file http://www.perl.org/index.html });
   ...
   @files = Proc::Async->result_list ($jobid);
   print join ("\n", @files);

prints:

   output.file
   log.file

The names of the files returned by the C<result_list()> can be used in
the method C<result()> in order to get the file content.

If the given $jobid does not represent an existing (and readable)
directory, it returns an empty list (without croaking).

If the external program created new files inside new directories, the
C<result_list()> returns names of these files, too. In other words, it
returns names of all files found within the job directory (however
deep in sub-directories), except special files (see the next
paragraph) and empty sub-directories.

There are also files with the special names, as defined by the
following constants:

   use constant STDOUT_FILE => '___proc_async_stdout___';
   use constant STDERR_FILE => '___proc_async_stderr___';
   use constant CONFIG_FILE => '___proc_async_status.cfg';

These files contain standard streams of the external programs (their
content can be fetched by the methods C<stdout()> and C<stderr()>) and
internal information about the status of the executed program.

Another example: If the contents of a job directory is the following:

   ___proc_async_stdout___
   ___proc_async_stderr___
   ___proc_async_status.cfg
   a.file
   a.dir/
      file1
      file2
      b.dir/
         file3
   empty.dir/

then the returned list will look like this:

   ('a.file',
    'a.dir/file1',
    'a.dir/file2',
    'b.dir/file3')

=head2 result($jobid, $file)

It returns the content of the given $file from the job given by
$jobid. The $file is a relative filename; must be one of those
returned by method C<result_list()>. It returns undef if the $file
does not exist (or if it does not exist in the list returned by
C<result_list()>).

For getting content of the standard stream, use the following methods:

=head2 stdout($jobid)

It returns the content of the STDOUT from the job given by $jobid. It
may be an empty string if the job did not produce any STDOUT, or if
the job does not exist anymore.

=head2 stderr($jobid)

It returns the content of the STDERR from the job given by $jobid. It
may be an empty string if the job did not produce any STDERR, or if
the job does not exist anymore.

If you execute an external program that cannot be found you will find
an error message about it here, as well:

   my $jobid = Proc::Async->start ('a-bad-program');
   ...
   print join ("\n", Proc::Async->status ($jobid);

      terminated by error
      exit code 2
      completed at Sat May 18 11:02:04 2013
      elapsed time 0 seconds

   print Proc::Async->stderr();

      Can't exec "a-bad-program": No such file or directory at lib/Proc/Async.pm line 148.

=head2 working_dir($jobid)

It returns the name of the working directory for the given $jobid. Or
undef if such working directory does not exist.

You may notice that the $jobid looks like a name of a working
directory. Actually, in the current implementation, it is, indeed, the
same. But it may change in the future. Therefore, better use this
method and do not rely on such sameness.

=head2 clean($jobid)

It deletes all files belonging to the given job, including its job
directory. It returns the number of file successfully deleted.  If you
ask for a status of the job after being cleaned up, you get
C<STATUS_UNKNOWN>.

=head2 get_configuration($jobid)

Use this method only if you wish to look at the internals (for example
to get exact starting and ending time of a job). It creates a
configuration (an instance of C<Proc::Async::Config>) and fills it
from the configuration file (if such file exists) for the given
job. It returns a two-element array, the first element being a
configuration instance, the second element the file name where the
configuration was filled from:

   my $jobid = Proc::Async->start ('date', '-u');
   ...
   my ($cfg, $cfgfile) = Proc::Async->get_configuration ($jobid);
   foreach my $name ($cfg->param) {
      foreach my $value ($cfg->param ($name)) {
          print STDOUT "$name=$value\n";
      }
   }

will print:

   job.arg=date
   job.arg=-u
   job.ended=1368865570
   job.id=/tmp/q74Bgd8mXX
   job.pid=22273
   job.started=1368865570
   job.status=completed
   job.status.detail=exit code 0
   job.status.detail=completed at Sat May 18 11:26:10 2013
   job.status.detail=elapsed time 0 seconds

=head1 ADDITIONAL FILES

The module distribution has several example and helping files (which
are not installed when the module is fetched by the C<cpan> or
C<cpanm>).

=head3 scripts/procasync

It is a command-line oriented script that can invoke any of the
functionality of this module. Its purpose is to test the module and,
perhaps more importantly, to show how to use the module's
methods. Otherwise, it does not make much sense (that is why it is not
normally installed).

It has its own (but only short) documentation:

   scripts/procasync -help

or

   perldoc scripts/procasync

Some examples are:

   scripts/procasync -start date
   scripts/procasync -start 'date -u'
   scripts/procasync -start 'sleep 100'

The C<-start> arguments can be repeated if its arguments have spaces:

   scripts/procasync -start cat -start '/data/filename with spaces'

All lines above print a job ID that must be used in a consequent usage:

   scripts/procasync -jobid /tmp/hBsXcrafhn -status
   scripts/procasync -jobid /tmp/hBsXcrafhn -stdout -stderr -rlist
   scripts/procasync -jobid /tmp/hBsXcrafhn -wdir
   ...etc...

=head3 examples/README

Because this module is focused mainly on its usage within CGI scripts,
there is an example of a simple web application. The C<README> file
explains how to install it and run it from your web server. Here
L<http://sites.google.com/site/martinsenger/extester-screenshot.png>
is its screenshot.

=head3 t/data/extester

This script can be used for testing this module (as it is used in the
regular Perl tests and in the web application mentioned above). It can
be invoked as an external program and, depending on its command line
arguments, it creates some standard and/or standard error streams,
exits with the specified exit code, etc. It has its own documentation:

   perldoc t/data/extester

An example of its command-line:

   extester -stdout an-out -stderr an-err -exit 5 -create a.tmp=5 few/new/dirs/b.tmp=3 an/empty/dir/=0

which writes given short texts into stdout and stderr, creates two
files (C<a.tmp> and C<b.tmp>, the latter one together with the given
sub-directories hierarchy) and it exits with exit code 5.

=head1 BUGS

Please report any bugs or feature requests to
L<http://github.com/msenger/Proc-Async/issues>.

=head2 Missing features

=over

=item Standard input

Currently, there is no support for providing standard input for the
started external process.

=back

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC-KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

