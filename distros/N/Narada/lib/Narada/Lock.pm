package Narada::Lock;

use warnings;
use strict;
use Carp;

our $VERSION = 'v2.3.7';

use Export::Attrs;
use Narada;
use Fcntl qw( :DEFAULT :flock F_SETFD FD_CLOEXEC );
use Errno;
use Time::HiRes qw( sleep );


use constant IS_NARADA1 => eval { local $SIG{__DIE__}; Narada::detect('narada-1') } || undef;
use constant DIR        => IS_NARADA1 ? 'var/' : q{};
use constant LOCKNEW    => DIR.'.lock.new';
use constant LOCKFILE   => DIR.'.lock';
use constant TICK       => 0.1;

my $F_lock;


sub shared_lock :Export {
    my $timeout = shift;
    return 1 if $ENV{NARADA_SKIP_LOCK};
    sysopen $F_lock, LOCKFILE, O_RDONLY|O_CREAT         or croak "open: $!";
    while (1) {
        next            if -e LOCKNEW;
        last            if flock $F_lock, LOCK_SH|LOCK_NB;
        $!{EWOULDBLOCK}                                 or croak "flock: $!";
    } continue {
        return          if defined $timeout and (($timeout-=TICK) < TICK);
        sleep TICK;
    }
    return 1;
}

sub exclusive_lock :Export {
    return if $ENV{NARADA_SKIP_LOCK};
    sysopen $F_lock, LOCKFILE, O_WRONLY|O_CREAT         or croak "open: $!";
    while (1) {
        last if flock $F_lock, LOCK_EX|LOCK_NB;
        $!{EWOULDBLOCK}                                 or croak "flock: $!";
        system('touch', LOCKNEW) == 0                   or croak "touch: $!/$?";
        sleep TICK;
    }
    system('touch', LOCKNEW) == 0                       or croak "touch: $!/$?";
    return;
}

sub unlock_new :Export {
    return if $ENV{NARADA_SKIP_LOCK};
    unlink LOCKNEW;
    return;
}

sub unlock :Export {
    return if $ENV{NARADA_SKIP_LOCK};
    if ($F_lock) {
        flock $F_lock, LOCK_UN                          or croak "flock: $!";
    }
    return;
}

sub child_inherit_lock :Export {
    my ($is_inherit) = @_;
    return if $ENV{NARADA_SKIP_LOCK};
    if ($F_lock) {
        fcntl $F_lock, F_SETFD, $is_inherit ? 0 : FD_CLOEXEC or croak "fcntl: $!";
    }
    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Narada::Lock - manage project locks


=head1 VERSION

This document describes Narada::Lock version v2.3.7


=head1 SYNOPSIS

    use Narada::Lock qw( shared_lock unlock child_inherit_lock );
    use Narada::Lock qw( exclusive_lock unlock_new unlock );

    shared_lock();
    unlock();
    shared_lock(0) or die "Can't get lock right now";
    unlock();
    shared_lock(5) or die "Can't get lock in 5 seconds";
    unlock();

    shared_lock();
    system('sleep 1');
    child_inherit_lock(1);
    system('sleep 10 &');
    child_inherit_lock(0);
    system('sleep 1');
    unlock();

    exclusive_lock();
    # do critical operations, reboot-safe
    unlock_new();
    # do non-critical operations, still in exclusive mode
    unlock();


=head1 DESCRIPTION

To allow safe backup/update/maintenance of project, there should be
possibility to guarantee consistent state of project, at some point.
To reach this goal, ALL operations which modify project data on disk
(including both project files and database) must be done under shared lock,
and all operations which require consistent project state must be done
under exclusive lock.

This module contain helper functions to manage project locks, but all
operations required for these locks can be implemented using any
programming language, so all applications in project (including non-perl
applications) are able to manage project locks.

Shared lock is set using flock(2) LOCK_SH on file C<.lock>.
Exclusive lock is set using flock(2) LOCK_EX on file C<.lock>.

=head2 FREEZE NEW TASKS

There exists scenario when it's impossible to set exclusive lock:
if new tasks will start and set shared lock before old tasks will drop shared
lock (and so shared lock will be set all of time).

To work around this scenario another file C<.lock.new> should be used
as semaphore - it should be created before trying to set exclusive lock,
and new tasks shouldn't try to set shared lock while this file exists.

This file should be removed after finishing critical operations - this
guarantee project data will not change even if system will be rebooted,
because after reboot existence of file C<.lock.new> will prevent from
starting new tasks with shared locks but not prevent from placing
exclusive lock again and continue these critical operations.


=head1 INTERFACE 

=head2 shared_lock

    shared_lock( $timeout );

Try to get shared lock which is required to modify any project data (files or
database).

If $timeout undefined - will wait forever until lock will be granted.
If $timeout >=1 will try to get lock every 1 second until $timeout expire.

Use unlock() to free this lock.

Return: true if able to get lock.

=head2 exclusive_lock

    exclusive_lock();

Try to get exclusive lock which is required to guarantee consistent project
state (needed while backup/update/maintenance operations).

Set two locks: create file C<.lock.new> which signal other scripts to
not try to set shared lock while this file exists and get LOCK_EX on file
C<.lock> to be sure all current tasks finished and unlocked their
shared locks.

Will delay until get lock.

Use unlock_new() in combination with exit() or unlock() to free these locks.

Return: nothing.

=head2 unlock_new

    unlock_new();

Free first lock set by exclusive_lock() (i.e. remove file C<.lock.new>).
This allow other tasks to get shared_lock() after this process exit or
call unlock().

Return: nothing.

=head2 unlock

    unlock();

Free lock set by shared_lock() (or second lock set by exclusive_lock()).

Return: nothing.

=head2 child_inherit_lock

    child_inherit_lock( $is_inherit );

By default, child processes don't inherit our FD with lock.
This is acceptable only if we don't run child in background or if
child will get own locks on start.

In other cases you should call child_inherit_lock() with true value in
$is_inherit to force child to inherit our lock (just like DJB's `setlock`
or Pepe's `chpst -[lL]` do).
Calling child_inherit_lock() with false value in $is_inherit will switch
back to default behaviour (new child will not inherit FD with lock).

Examples:

 # OK: not in background
 system("rm -rf var/something");

 # OK: in background, but this is our script,
 # which will get lock on it's own
 system("./another_script_of_this_project &");

 # ERROR: in background, no lock
 system("( sleep 5; rm -rf var/something ) &");

 # OK: in background, inherit lock
 child_inherit_lock(1); # from now all childs will inherit lock
 system("( sleep 5; rm -rf var/something ) &");
 child_inherit_lock(0); # next child will not inherit lock

Return: nothing.


=head1 CONFIGURATION AND ENVIRONMENT

Narada::Lock requires configuration files and directories provided by
Narada framework.

If $ENV{NARADA_SKIP_LOCK} is set to any true value then shared_lock(),
exclusive_lock(), unlock_new(), unlock() and child_inherit_lock() will do
nothing (shared_lock() will return true).


=head1 COMPATIBILITY

Narada 1.x project use C<var/.lock> instead of C<.lock>.

Narada 1.x project use C<var/.lock.new> instead of C<.lock.new>.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/Narada/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/Narada>

    git clone https://github.com/powerman/Narada.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Narada>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Narada>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Narada>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Narada>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Narada>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
