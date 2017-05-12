## This file is Copyright (C) 2002, Paul Prince <princep@charter.net>.
## It is licensed and distributed under the terms of Perl itself.

package Qmail::Control::Lock;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.01';

use Fcntl qw/:flock/;

require Exporter;

=head1 NAME

Qmail::Control::Lock - Perl extension for locking Qmail's control file
subsystem.

=head1 SYNOPSIS

  use Qmail::Control::Lock;

  my $lock = Qmail::Control::Lock->new();

  # Get a shared lock on the control subsystem. 
  $lock->lock_shared() or die "Couldn't get sh lock: $!\n";

  # Get an exclusive lock on the control subsystem. 
  $lock2->lock_exclusive() or die "Couldn't get ex lock: $!\n";

  # Change a shared lock to an exclusive lock.
  $lock->relock('exclusive') or die "Couldn't change sh to ex lock: $!\n";

  # Unlock the control subsystem.
  $lock->unlock();
  $lock2->unlock();

=head1 DESCRIPTION

Qmail::Control::Lock provides and interface for locking Qmail's control
file subsystem.

Dan Bernstein does not endorse this module or this
locking method, and as far as I know, only Qmail::Control::Lock uses it.

=head1 EXPORTS

None by default.

=cut

######################
# METHODS START HERE #
######################

=head1 METHODS

=over 30

=item Qmail::Control::Lock->new()

Creates a new Qmail::Control::Lock object.

Returns a reference to the newly created object.

Takes no arguments, currently.  This may change, but the argumentless
form will always exist.

=cut

sub new {
#    Do I need this stuff?? 
#    my $invocant = shift;
#    my $class = ref($invocant) || $invocant;
#    bless($class);

    # Create a new Qmail::Control::Lock object.
    my $self = { };
    bless($self);

    # Locking is achieved by calling flock() on QMAILHOME/control/.lock .
    # This is ususally /var/qmail/control/.lock , which is what we
    # assume.

    # Open the lockfile for reading.
    my $lockfile_handle;
    open($lockfile_handle, '<', '/var/qmail/control/.lock');

    # Put a reference to the filehandle into the hash which represents the
    # object.
    $self->{'lockfile_handle'} = $lockfile_handle;

    # Return a reference to the newly created object.
    return $self;
}

=item $lock->lock_shared();

Gets a shared lock on the Qmail control file subsystem.

Returns true on success or undef on a serious error.

Takes no arguments.

=cut

sub lock_shared {
    my $self = shift;

    # Confirm that there is a filehandle in $self.
    exists $self->{'lockfile_handle'} or return undef;

    # Lock that filehandle.
    flock ($self->{'lockfile_handle'},           LOCK_SH) or return undef;
    
    # Let the object know that it is locked, and how.
    $self->{'locked'} = 'shared';

    # Return true.
    return 1;
}

=item $lock->lock_exclusive();

Gets an exclusive lock on the Qmail control file subsystem.

Returns true on success or undef on a serious error.

Takes no arguments.

=cut

sub lock_exclusive {
    my $self = shift;

    # Confirm that there is a filehandle in $self.
    exists $self->{'lockfile_handle'} or return undef;

    # Lock that filehandle.
    flock ($self->{'lockfile_handle'},           LOCK_EX) or return undef;
    
    # Let the object know that it is locked, and how.
    $self->{'locked'} = 'exclusive';

    # Return true.
    return 1;
}

=item $lock->relock();

Changes one type of lock (either shared or exclusive) into another.

Returns true on success or undef on a serious error.

Takes a single argument, either 'shared' or 'exclusive', which indicates
which type of lock to engage.  If you pass 'shared', and the lock is
already 'shared', this is a no-op.

=cut

sub relock {
    my $self = shift;

    # Confirm that there is a filehandle in $self.
    exists $self->{'lockfile_handle'} or return undef;

#    # Unlock that filehandle.
#    flock ($self->{'lockfile_handle'}, LOCK_UN) or return undef;

    # If we got 'shared', lock 'shared'.
    if ($_[0] eq 'shared') {
        flock ($self->{'lockfile_handle'}, LOCK_SH) or return undef;
    }
    # Else, if we got 'exclusive', lock 'exclusive'.
    elsif ($_[0] eq 'exclusive') {
        flock ($self->{'lockfile_handle'}, LOCK_EX) or return undef;
    }
    # Else, we got an invalud param, return undef.
    else {
        return undef;
    }

    # Let the object know that it is locked, and how.
    $self->{'locked'} = $_[0];

    # Return true.
    return 1;
}

=item $lock->unlock();

Unlocks the Qmail control file subsystem.

Returns nothing.

Takes no arguments.

=cut

sub unlock {
    my $self = shift;

    # Unlock that filehandle.
    flock ($self->{'lockfile_handle'}, LOCK_UN);
    
    # Let the object know that it is not locked.
    delete $self->{'locked'};

    # Return true.
    return 1;
}

=pod

=back

=head1 AUTHOR

Paul Prince, E<lt>princep@charter.netE<gt>

=head1 SEE ALSO

L<perl>.
L<Qmail::Control::Lock>.

=cut

sub DESTROY {
    my $self = shift;
    close $self->{'lockfile_handle'};
}

# End the package.
1;
