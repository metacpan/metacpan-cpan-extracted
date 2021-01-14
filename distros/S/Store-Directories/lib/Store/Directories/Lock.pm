package Store::Directories::Lock;
use strict;
use warnings;

=head1 NAME

Store::Directories::Lock - Represents a lock on a L<Store::Directories> entry
that releases itself when out-of-scope.

=head1 SYNOPSIS

    use Store::Directories;

    # Please use Store::Directories's "lock_*" methods for creating
    # new locks
    my $store = Store::Directories->init("path/to/store");

    {
        my $lock = $store->lock_sh('foo');
        # $lock now asserts a shared lock on the directory with key 'foo'

        # You can now read the contents of the directory knowing that no
        # other processes can modify it (but you may not modify it either)
    }

    # The lock is released once it is out-of-scope

    {
        my $lock = $store->lock_ex('foo')
        # $lock now asserts an exclusive lock on the directory with key 'foo'

        # You can now modify the contents of the directory knowing that no
        # other processes can modify or read it.
    }

    # Once again, released once out-of-scope


=head1 DESCRIPTION

Instances of this class are returned by L<Store::Direcotries>'s C<lock_ex> and
C<lock_sh> methods. The existence of one of these instances asserts that this
process has either a shared or exclusive lock (to borrow L<flock(2)> 
terminology) over an entry in the corresponding L<Store::Directories> database.

A process can have only one lock for a given entry at a time. Attempting to
create a new lock on the same entry will result in an error.

B<NOTE:> Locks lose their power over forks. That means a lock asserts itself
I<only> for the process that it was created in and only for the lifetime of
the copy of itself in that process. The copy of a lock in a child process
does not gaurentee that the lock still holds (nor will it remove the lock
when it goes out-of-scope).

B<WARNING:> This package (optionally) exports the constants C<UN>,C<SH> 
and C<EX>. While these have similiar meanings to the L<Fcntl> constants 
with similiar names, they are B<NOT EQUIVALENT> to one another.

=cut

use Carp;
use Exporter;
use Scalar::Util qw(blessed);

use Devel::GlobalDestruction;

use constant UN => 0;
use constant SH => 1;
use constant EX => 2;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(UN SH EX);

=head1 METHODS

=over 4

=item * B<new> I<STORE>, I<KEY>, I<[MODE]>

(You I<can> call this method if you like, but you really should use
the C<lock_sh> or C<lock_ex> methods on L<Store::Directories> instead).

Create a new lock that asserts this process has a lock over the directory with
C<KEY> in the L<Store::Directories> referred to by C<STORE>.
C<MODE> is one of the constants (C<EX> or C<SH>) specifying which kind of lock
to create. If undefined, defaults to C<SH> (for a shared lock).

This will block until the desired lock can be obtained. For a shared lock,
this means the function will wait until any processes with exclusive locks
release them and for an exclusive lock, it will wait until any other
processes release all of their locks on the key.

This will croak if this process already has a lock for that key, or
if the key does not exist in the store (or if a database error occurs).
=cut
sub new {
    my ($class, $store, $key, $mode) = @_;
    $mode //= SH;

    unless (blessed($store) && $store->isa('Store::Directories')) {
        croak "Must provide a Store::Directories instance for this lock."
    }
    unless ($mode == SH || $mode == EX) {
        croak "Mode must be either one of the 'SH' or 'EX' constants.";
    }

    my $dbh = $store->_new_connection;
    # Ensure this process does not have a lock already
    croak "Process already has lock on key '$key'." if _get_lock_mode($dbh, $key);

    # Add a new lock
    _add_lock($dbh, $key, $mode);
    return $class->_new_raw($store, $key, $$, $mode);

}

=item * B<exclusive>

Returns true/false indicating whether the lock is exclusive or not. This can
I<NOT> be used to set the status of the lock.
=cut
sub exclusive {
    my $self = shift;
    return $self->{mode} == EX ? 1 : 0;
}

=item * B<DESTROY>

Release this lock. Naturally, you shouldn't call this directly and let the
garbage-collector do it for you.
=cut
sub DESTROY {
    my $self = shift;
    return if in_global_destruction || $self->{_destroyed};

    # Don't do anything if we're now in a different process than
    # the one that created the lock (for example, if the process
    # forked)
    return unless $self->{ownerpid} == $$;

    my $dbh = $self->{store}->_new_connection;
    my $sth = $dbh->prepare("DELETE FROM lock WHERE pid = ? AND slug = ?");
    my $rv  = $sth->execute($$, $self->{key});
    defined $rv or die "could not release lock in DESTROY: ".$dbh->errstr;

    $self->{_destroyed} = 1;
}

=back

=cut

########################
# PRIVATE METHODS
########################

# $Store::Directories::Lock->_new_raw STORE KEY PID MODE
# Blesses a new Lock with the given parameters. Assumes the lock
# has already been created in the database and any parameter-checking
# has already been done.
sub _new_raw {
    my $class = shift;
    my $self = bless {}, $class;
    @{$self}{'store','key','ownerpid','mode','_destroyed'} = (@_, 0);
    return $self;
}

########################
# PRIVATE FUNCTIONS
########################

# _get_proc_start_time [PID]
# Get the start time of the process with the given PID
# (or of this process if one isn't specified)
sub _get_proc_start_time {
    my $pid = shift // $$;
    my $statfile = "/proc/$pid/stat";

    open(my $fh, '<', $statfile) or return undef;
    my $stat = <$fh>;
    close $fh;
    return undef unless $stat;
    $stat =~ m/\) [RSDZTW] (?:\d+ ){18}(\d+)/;

    croak "could not read process start time." unless $1;
    return $1;
}

########################
# DATABASE FUNCTIONS
#   most of these functions require
#   an active database handle (DBH)
#   as an argument and expect to be
#   used as parts of a larger transaction
########################

# _get_lock_mode DBH KEY
# Get the mode of the lock (if any) that this process has over the
# the given key. Returns one of the three constants EX, SH or UN. (UN
# meaning no lock)
sub _get_lock_mode {
    my ($dbh, $key) = @_;

    my $sth = $dbh->prepare(<<END);
        SELECT exclusive FROM lock WHERE
            pid =  ? AND
            slug = ?
END
    $sth->execute($$, $key) or croak "Could not fetch locks: ".$dbh->errstr;
    my $mode = $sth->fetch;
    $dbh->err and croak "Could not fetch locks: ".$dbh->errstr;

    return UN unless defined $mode;
    return $mode->[0] ? EX : SH;
}

# _prune_locks DBH KEY
# Go through all of the locks for the given KEY and delete any whose processes
# are no longer alive.
sub _prune_locks {
    my ($dbh, $key) = @_;

    my $sth = $dbh->prepare("SELECT pid, start_time FROM lock WHERE slug = ?");
    $sth->execute($key) or croak "Failed to fetch locks: ".$dbh->errstr;
    my ($pid, $lock_time);
    $sth->bind_columns(\$pid, \$lock_time);

    my @dead_procs;
    while ($sth->fetch) {
        my $time  = _get_proc_start_time($pid);
        my $alive = ( defined $time && $time == $lock_time );
        push @dead_procs, $pid unless $alive;
    }
    $dbh->err   and croak "Failed to fetch locks: ".$dbh->errstr;

    if (@dead_procs) {
        $sth = $dbh->prepare("DELETE FROM lock WHERE pid = ?");
        for (@dead_procs) {
            $sth->execute($_) or croak "Failed to delete lock. ".$dbh->errstr;
        }
    }

}

# _add_lock DBH KEY MODE
# Same semantics as _add_lock_noblock (below), but will repeatedly try to get
# a lock until it succeeds. Always returns true, but returns -1 if the this
# process already has the requested lock. Otherwise returns 1.
#
# DON'T CALL THIS AS PART OF A LARGER TRANSACTION. Otherwise, other processes
# won't get a chance to remove their locks and you'll potentially get
# deadlocked.
sub _add_lock {
    my $dbh = $_[0];

    my $status;
    until ($status) {
        $dbh->begin_work;
        $status = eval { _add_lock_noblock(@_); };
        unless(defined $status) {
            $dbh->rollback;
            croak $@;
        };
        $dbh->commit;
        #sleep rand 0.05;
    }
    return $status;
}

# _add_lock_noblock DBH KEY MODE
# Attempt to add a lock for the given key for this process in the given mode.
# This will fail if another process already has an
# incompatible lock.
#
# Returns:
# 0  - on failure becuase another process has a lock already
# 1  - on success
# -1 - on "failure" because THIS process already has the requested lock
#
# This can also be used to change the type of lock for this process (e.g.
# upgrading to an exclusive lock by calling MODE set to EX for a process
# that already has a shared lock)
sub _add_lock_noblock {
    my ($dbh, $key, $mode) = @_;
    # convert mode into "exclusive?" boolean for SQLite
    $mode = ($mode == SH ? 0 : 1);

    my $select = "SELECT pid, start_time, exclusive FROM lock WHERE slug = ?";
    # If we want a shared lock, we only need to look for exclusive locks
    # in the database.
    $select .= " AND exclusive = 1" unless $mode;

    my $sth = $dbh->prepare($select);
    $sth->execute($key) or croak "Failed to fetch locks: ".$dbh->errstr;
    my ($lock_pid, $lock_time, $lock_mode);
    $sth->bind_columns(\$lock_pid, \$lock_time, \$lock_mode);

    # Iterate through rows
    my @dead_procs;
    while ($sth->fetch) {
        if ($lock_pid == $$) {
            # If we already have the requested lock, we can stop now
            return -1 if $lock_mode == $mode;
        }
        else {
            # There's a lock stopping us. Is its process still running?
            my $time  = _get_proc_start_time($lock_pid);
            my $alive = (defined $time && $time == $lock_time);
            # If the lock is still alive, we can't get a lock
            return 0 if $alive;
            # Otherwise, we know the process is dead and can delete it
            # from the table.
            push @dead_procs, $lock_pid;
        }
    }
    $dbh->err   and croak "Failed to fetch locks: ".$dbh->errstr;

    # Remove any dead processes
    if (@dead_procs) {
        $sth = $dbh->prepare("DELETE FROM lock WHERE pid = ?");
        for (@dead_procs) {
            $sth->execute($_) or croak "Failed to delete lock. ".$dbh->errstr;
        }
    }

    # Add/update our lock
    $sth = $dbh->prepare(<<END);
    INSERT OR REPLACE INTO
            lock(pid, start_time, slug, exclusive)
        VALUES
            (?, ?, ?, ?)
END
    $sth->execute($$, _get_proc_start_time, $key, $mode)
        or croak "Failed to insert lock. ".$dbh->errstr;

    1;
}

1;
