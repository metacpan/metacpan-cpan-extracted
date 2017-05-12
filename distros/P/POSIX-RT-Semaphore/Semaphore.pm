package POSIX::RT::Semaphore;
#============================================================================#

use 5.008;
use strict;
our ($VERSION, @EXPORT_OK);

BEGIN {
	$VERSION = '0.05';
	require XSLoader;
	XSLoader::load(__PACKAGE__, $VERSION);

	# -- Set up exports at BEGIN time
	@EXPORT_OK =
		('SIZEOF_SEM_T', grep {/^(_SC_)?SEM_[A-Z_]+/} keys %POSIX::RT::Semaphore::); 

	# -- awkwardness to support threaded
	#    operation
	if ($INC{'threads.pm'}) {
		require threads::shared;
		no warnings 'redefine';

		for ('Unnamed::init', 'Named::open') {
			no strict 'refs';

			my $sym = __PACKAGE__ . "::$_";
			my $ctor = \&{$sym};
			*{$sym} = sub {
				my $psem = &$ctor;
				&threads::shared::share($psem) if defined $psem;
				$psem;
			}
		}

		my $dtor = \&POSIX::RT::Semaphore::_base::DESTROY;
		*POSIX::RT::Semaphore::_base::DESTROY = sub {
			lock($_[0]);
			return unless threads::shared::_refcnt($_[0]) == 1;
			&$dtor;
		};
	} # -- if ($INC{'threads.pm'})

}

use strict;
use warnings;

#
# -- Internal methods
#

sub import {
  require Exporter;
  goto &Exporter::import;
}

#
# -- Public methods
#

sub init {
	shift @_;
	return POSIX::RT::Semaphore::Unnamed->init(@_);
}

sub open {
	shift @_;
	return POSIX::RT::Semaphore::Named->open(@_);
}

1;

__END__

=head1 NAME

POSIX::RT::Semaphore - Perl interface to POSIX.1b semaphores

=head1 SYNOPSIS

  use POSIX::RT::Semaphore;
  use Fcntl;            # O_CREAT, O_EXCL for named semaphore creation

  ## unnamed semaphore, initial value 1
  $sem = POSIX::RT::Semaphore->init(0, 1);

  ## named semaphore, initial value 1
  $nsem = POSIX::RT::Semaphore->open("/mysem", O_CREAT, 0660, 1);

  ## method synopsis

  $sem->wait;                             # down (P) operation
  ... protected section ...
  $sem->post;                             # up (V) operation

  if ($sem->trywait) {                    # non-blocking wait (trydown)
    ... protected section ...
    $sem->post;
  }

  $sem->timedwait(time() + 10);           # wait up to 10 seconds

=head1 DESCRIPTION

POSIX::RT::Semaphore provides an object-oriented Perl interface to POSIX.1b
Realtime semaphores, as supported by your system.  A POSIX semaphore (herein:
psem) is a high-performance, persistent synchronization device.

I<Unnamed> psems are typically used for synchronization between the threads
of a single process, or between a set of related processes which have
inherited the psem from a common ancestor.  I<Named> psems are typically
used for interprocess synchronization, but may also serve interthreaded
designs.

=head1 CLASS METHODS

Unless otherwise specified, all methods return the undefined value on
failure (setting $!), and a true value on success.

=over 4

=item init PSHARED, VALUE

A convenience for the POSIX::RT::Semaphore::Unnamed-E<gt>init class method.

Return a new POSIX::RT::Semaphore::Unnamed object, initialized to VALUE.  If
PSHARED is non-zero, the psem may be shared between processes (subject to
implementation CAVEATS, below).

Unnamed semaphores persist until explicitly released by calling their
C<destroy> method.

=item open NAME

=item open NAME, OFLAGS

=item open NAME, OFLAGS, MODE

=item open NAME, OFLAGS, MODE, VALUE

A convenience for the POSIX::RT::Semaphore::Named-E<gt>open class method.

Return a new POSIX::RT::Semaphore::Named object, referring to the underlying
semaphore NAME.  Other processes may attempt to access the same psem by
that NAME.

OFLAGS may specify O_CREAT and O_EXCL, imported from the L<Fcntl|Fcntl>
module, to create a new system semaphore.  A filesystem-like MODE,
defaulting to 0666, and an initial VALUE, defaulting to 1, may be supplied.

Named semaphores persist until explicitly removed by a call to the C<unlink>
class method.  A subsequent C<open> of that NAME will return a new system
psem.

=item unlink NAME

Remove the named semaphore identified by NAME.  Analogous to unlinking a
file on UNIX-like systems, removal does not invalidate psems already held
open by other processes.

=back

=head1 SEMAPHORE OBJECT METHODS

=head2 Common Methods

=over 4

=item getvalue

Return the current value of the semaphore, or, if the value is zero, a
negative number whose absolute value is the number of currently waiting
processes.

=item name

Return the object's associated name as set by L</open>, or undef if created
by L</init>.  Deprecated for unnamed psems.

=item post

Atomically increment the semaphore, allowing waiters to proceed if the new
counter value is greater than zero.

=item timedwait ABSOLUTE_TIMEOUT

Attempt atomically to decrement the semaphore, waiting until
ABSOLUTE_TIMEOUT before failing.

  $sem->timedwait(time() + .5);  # wait half a second

=item trywait

Atomically decrement the semaphore, failing immediately if the counter is at
or below zero.

=item wait

Atomically decrement the semaphore, blocking indefinitely until successful.

=back

=head2 POSIX::RT::Semaphore::Unnamed Methods

=over 4

=item destroy

Invalidate the underlying semaphore.  Subsequent method calls on the psem
will simply croak.  Operations on a destroyed psem by another process, one
which has inherited the now-defunct semaphore, for example, are undefined.

This method may fail if any processes is blocked on the underlying
semaphore.

Note that this is distinct from Perl's DESTROY.

=back

=head2 POSIX::RT::Semaphore::Named Methods

=over 4

=item close

Close the named semaphore for the calling process; subsequent method calls
on the object will simply croak.  The underlying psem, however, is not
removed until a call to C<POSIX::RT::Semaphore-E<gt>unlink()>, nor does the call
to C<close> affect any other process' connection to the same semaphore.

This method is called implicitly when the last object representing
a particular semaphore in a process is C<DESTROY>ed.

=back

=head1 CONSTANTS

POSIX::RT::Semaphore offers a number of constants for import:

=over 4

=item SEM_NSEMS_MAX, _SC_SEM_NSEMS_MAX

The maximum number of semaphores, per-process.  This number is actually
_POSIX_SEM_NSEMS_MAX, and the _SC constant may be passed to
C<POSIX::sysconf()> to determine the process' true current limit.

=item SEM_VALUE_MAX, _SC_SEM_VALUE_MAX

The highest value a semaphore may have.  This number is actually
_POSIX_SEM_VALUE_MAX, and the _SC constant may be passed to
C<POSIX::sysconf()> to determine the process' true, current ceiling.

=item SIZEOF_SEM_T

The size of a C<sem_t> object on your system.

=back

Your system may define other constants for import, such as SEM_NAME_LEN or
SEM_NAME_MAX (each the maximum length of a named semaphore's name).

=head1 CAVEATS

=over 4

=item PERSISTENCE

POSIX semaphores are system constructs existing apart from the processes
that use them.  For named psems in particular, this means that the value of
a newly opened semaphore may not be that VALUE specified in the L</open>
call. 

Depending on the application, it may be advisable to L</unlink> psems before
opening them, or to specify O_EXCL, to avoid opening a pre-existing psem.  

=item ENOSYS AND WORSE

Implementation details vary, to put it mildly.  Consult your system
documentation.

Some systems support named but not anonymous semaphores, others the
opposite, and still others are somewhere in between.  L</timedwait> may not
be implemented (failing with $! set to ENOSYS).  L</getvalue> is much more
widely supported, though its special negative semantics may not be.

More subtly, L</init> with a non-zero PSHARED may succeed, but the resultant
psem might be copied across processes if it was not allocated in shared
memory.  On systems supporting mmap(), POSIX::RT::Semaphore initializes
psems in anonymous, shared memory to avoid this unpleasantness.

Semaphore name semantics is implementation defined, making portable name
selection difficult.  POSIX conservatives will use only pathname-like names
with a single, leading slash and no other slashes (e.g., "/my_sem").
However, at least the OSF/Digital/Tru64 implementation currently maps names
directly to the filesystem, encouraging semaphores such as "/tmp/my_sem". 
On at least some FreeBSD implementations, semaphore pathnames may be no
longer than 14 characters.

=item MISC

wait/post are known by many names: down/up, acquire/release, P/V, and
lock/unlock to name a few.

=back

=head1 TODO

Extend init() to support user-supplied, shared memory objects.

=head1 SEE ALSO

L<IPC::Semaphore>, L<Thread::Semaphore>

=head1 AUTHOR

Michael J. Pomraning

Please report bugs via rt.cpan.org.

=head1 COPYRIGHT AND LICENSE

Copyright 2009 by Michael J. Pomraning

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
