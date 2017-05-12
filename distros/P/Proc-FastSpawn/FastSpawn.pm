=head1 NAME

Proc::FastSpawn - fork+exec, or spawn, a subprocess as quickly as possible

=head1 SYNOPSIS

   use Proc::FastSpawn;

   # simple use
   my $pid = spawn "/bin/echo", ["echo", "hello, world"];
   ...
   waitpid $pid, 0;

   # with environment
   my $pid = spawn "/bin/echo", ["echo", "hello, world"], ["PATH=/bin", "HOME=/tmp"];

   # inheriting file descriptors
   pipe R, W or die;
   fd_inherit fileno W;
   my $pid = spawn "/bin/sh", ["sh", "-c", "echo a pipe >&" . fileno W];
   close W;
   print <R>;

=head1 DESCRIPTION

The purpose of this small (in scope and footprint) module is simple:
spawn a subprocess asynchronously as efficiently and/or fast as
possible. Basically the same as calling fork+exec (on POSIX), but
hopefully faster than those two syscalls.

Apart from fork overhead, this module also allows you to fork+exec
programs when otherwise you couldn't - for example, when you use POSIX
threads in your perl process then it generally isn't safe to call
fork from perl, but it is safe to use this module to execute external
processes.

If neither of these are problems for you, you can safely ignore this
module.

So when is fork+exec not fast enough, how can you do it faster, and why
would it matter?

Forking a process requires making a complete copy of a process. Even
thought almost every implementation only copies page tables and not the
memory itself, this is still not free. For example, on my 3.6GHz amd64
box, I can fork a 5GB process only twenty times a second. For a real-time
process that must meet stricter deadlines, this is too slow. For a busy
and big web server, starting CGI scripts might mean unacceptable overhead.

A workaround is to use C<vfork> - this function isn't very portable, but
it avoids the memory copy that C<fork> has to do. Some systems have an
optimised implementation of C<spawn>, and some systems have nothing.

This module tries to abstract these differences away.

As for what improvements to expect - on the 3.6GHz amd64 box that this
module was originally developed on, a 3MB perl process (basically just
perl + Proc::FastSpawn) takes 3.6s to run /bin/true 10000 times using
fork+exec, and only 2.6s when using vfork+exec. In a 22MB process, the
difference is already 5.0s vs 2.6s, and so on.

=head1 FUNCTIONS

All the following functions are currently exported by default.

=over 4

=cut

package Proc::FastSpawn;

# only used on WIN32 - maddeningly complex and doesn't even work
sub _quote {
   $_[0] = [@{ $_[0] }]; # make copy

   for (@{ $_[0] }) {
      if (/[\x01-\x20"]/) { # some sources say only space, "\t\n\v need to be escaped, microsoft says space and tab
         s/(\\*)"/$1$1\\"/g; # double + extra escape before "
         s/(\\+)$/$1$1/;     # just double at end
         $_ = '"' . $_ . '"';
      }
   }
}

BEGIN {
   $VERSION = '1.2';

   our @ISA = qw(Exporter);
   our @EXPORT = qw(spawn spawnp fd_inherit);
   require Exporter;

   require XSLoader;
   XSLoader::load (__PACKAGE__, $VERSION);
}

=item $pid = spawn $path, \@argv[, \@envp]

Creates a new process and tries to make it execute C<$path>, with the given
arguments and optionally the given environment variables, similar to
calling fork + execv, or execve.

Returns the PID of the new process if successful. On any error, C<undef>
is currently returned. Failure to execution might or might not be reported
as C<undef>, or via a subprocess exit status of C<127>.

=item $pid = spawnp $file, \@argv[, \@envp]

Like C<spawn>, but searches C<$file> in C<$ENV{PATH}> like the shell would
do.

=item fd_inherit $fileno[, $on]

File descriptors can be inherited by the spawned processes or not. This is
decided on a per file descriptor basis. This module does nothing to any
preexisting handles, but with this call, you can change the state of a
single file descriptor to either be inherited (C<$on> is true or missing)
or not C<$on> is false).

Free portability pro-tip: it seems native win32 perls ignore $^F and set
all file handles to be inherited by default - but this function can switch
it off.

=back

=head1 PORTABILITY NOTES

On POSIX systems, this module currently calls vfork+exec, spawn, or
fork+exec, depending on the platform. If your platform has a good vfork or
spawn but is misdetected and falls back to slow fork+exec, drop me a note.

On win32, the C<_spawn> family of functions is used, and the module tries
hard to patch the new process into perl's internal pid table, so the pid
returned should work with other Perl functions such as waitpid. Also,
win32 doesn't have a meaningful way to quote arguments containing
"special" characters, so this module tries it's best to quote those
strings itself. Other typical platform limitations (such as being able to
only have 64 or so subprocesses) are not worked around.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

