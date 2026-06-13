package RPi::WiringPi::Meta;

use strict;
use warnings;

use Carp qw(croak);
use IPC::Shareable qw(:flock);
use JSON::XS;
use String::CRC32 qw(crc32);

our $VERSION = '3.1802';

# Mirrors IPC::Shareable's signed 32-bit key_t overflow correction (_shm_key)
use constant MAX_KEY_INT_SIZE => 0x80000000;

sub meta {
    my ($self) = @_;

    return $self->{meta_knot} if exists $self->{meta_knot};

    # Tie a SCALAR holding our own JSON string (not a HASH). This keeps the
    # entire blob in a single segment; tying a HASH (or storing a ref) would
    # make IPC::Shareable fan each nested structure out into its own segment.

    my $blob;

    my $knot = tie $blob, 'IPC::Shareable', {
        key     => $self->{shm_key},
        create  => 1,
        destroy => 0,
    } or die "Can't create shared memory segment: $!";

    $self->{meta_scalar} = \$blob;
    $self->{meta_knot}   = $knot;

    return $knot;
}
sub meta_erase {
    my ($self, $all) = @_;

    $all //= 0;

    $self->_meta_txn(sub {
        my ($clean_store, $storage);

        if ($all) {
            $clean_store = {};
        }
        else {
            $storage = $self->meta_fetch()->{storage};
            $clean_store = defined $storage ? { storage => $storage } : {};
        }

        $self->meta_store($clean_store);
    });
}
sub meta_remove {
    # Removes the underlying shared memory segment (and its semaphore set)
    # entirely, not just its contents. Unlike meta_erase(), which empties the
    # blob but leaves the segment allocated (destroy => 0), this frees the SysV
    # segment so it no longer appears in ipcs. A later meta() call transparently
    # creates a fresh segment.

    my ($self) = @_;

    return if ! exists $self->{meta_knot};

    $self->{meta_knot}->remove;

    delete $self->{meta_knot};
    delete $self->{meta_scalar};

    return 1;
}
sub meta_key_check {
    # This is a class method, and must be called on the class prior to creating
    # a Pi object

    my ($class, $key) = @_;

    if (! defined $key){
        croak "meta_key_check() requires a key sent in...\n";
    }

    # Derive the integer segment key exactly as IPC::Shareable does (CRC32 of
    # the string key, with signed 32-bit overflow correction), then probe for
    # the segment's existence without creating it.

    my $int = crc32($key);
    $int -= MAX_KEY_INT_SIZE if $int >= MAX_KEY_INT_SIZE;

    my $shm_check = shmget($int, 0, 0);
    return defined $shm_check ? 1 : 0;
}
sub meta_key {
    my ($self) = @_;
    return $self->meta->seg->key;
}
sub meta_lock {
    my ($self, $flags) = @_;
    $flags = LOCK_EX if ! defined $flags;
    $self->meta->lock($flags);
}
sub _meta_txn {
    # Runs $code with the meta lock held, guaranteeing the lock is released
    # even if $code dies (a die between lock and unlock would otherwise hold
    # the exclusive lock indefinitely across processes). Any error is
    # re-thrown after the unlock

    my ($self, $code, $flags) = @_;

    $self->meta_lock($flags);

    my @ret = eval { $code->() };
    my $err = $@;

    $self->meta_unlock;

    die $err if $err;

    return wantarray ? @ret : $ret[0];
}
sub meta_unlock {
    my ($self) = @_;
    $self->meta->unlock;
}
sub meta_fetch {
    my ($self) = @_;

    $self->meta;

    # decode_json() always returns a fresh, fully detached structure, so callers
    # may safely mutate nested keys before calling meta_store(). A new segment
    # reads back as undef.

    my $json = ${ $self->{meta_scalar} };
    $json = '{}' if ! defined $json || $json eq '';

    return decode_json $json;
}
sub meta_store {
    my ($self, $data) = @_;

    if (! defined $data){
        croak "meta_store() requires a hash reference sent in...\n";
    }

    $self->meta;

    # Store a single JSON string (a non-ref scalar) so the whole blob lives in
    # one segment. IPC::Shareable croaks itself if it exceeds the segment size.

    ${ $self->{meta_scalar} } = encode_json $data;
}
sub meta_delete {
    my ($self, $name) = @_;

    if (! defined $name){
        croak "when setting a metadata slot, you must send in a name\n";
    }

    $self->_meta_txn(sub {
        my $shm = $self->meta_fetch;
        delete $shm->{storage}{$name};
        $self->meta_store($shm);
    });
}
sub meta_get {
    my ($self, $name) = @_;

    if (! defined $name){
        croak "when getting a metadata slot, you must send in a name\n";
    }

    return $self->_meta_txn(sub {
        my $shm = $self->meta_fetch;

        my $data;
        $data = { %{ $shm->{storage}{$name} } } if exists $shm->{storage}{$name};

        return $data;
    });
}
sub meta_set {
    my ($self, $name, $data) = @_;

    if (! defined $name){
        croak "when setting a metadata slot, you must send in a name\n";
    }

    if (ref $data ne 'HASH'){
        croak "when setting a metadata slot, you must supply a hash reference\n";
    }

    $self->_meta_txn(sub {
        my $shm = $self->meta_fetch;
        $shm->{storage}{$name} = { %$data };
        $self->meta_store($shm);
    });
}

sub _vim{1;};

1;

__END__

=head1 NAME

RPi::WiringPi::Meta - Shared memory meta data management for RPI::WiringPi

=head1 DESCRIPTION

This module contains various utilities for the shared memory storage area. This
area allows both the software and you, the user, to share Perl variables across
different scripts and processes easily.

=head1 SYNOPSIS

    my $pi = RPi::WiringPi->new;

    my %data = (a => 1, b => 2, c => [1, 2, 3]);

    # add a new or set an existing storage slot (must be an href)

    $pi->meta_set('my_data', \%data);

    # retrieve an existing storage slot (always an href)

    my $stats = $pi->meta_get('stats');

    # delete an existing storage slot

    $pi->meta_delete('stats');

=head1 METHODS

=head2 meta

Instantiates and returns the shared memory object that stores the meta data.

Internally, we tie a scalar to L<IPC::Shareable> holding a single JSON-encoded
string, which keeps the entire meta data blob within one shared memory segment.
The returned object is the L<IPC::Shareable> "knot" (the tied object).

=head2 meta_set($name, $href)

Adds a user-defined hash reference to the shared memory segment with it's key
named C<$name>.

Parameters:

    $name

Mandatory, String: Any value that is a legitimate value for a hash key.

    $href

Mandatory, Hash Reference: A hash reference that contains your data.

=head2 meta_get($name)

Retrieves a user-defined hash reference from the shared memory.

Parameters:

    $name

Mandatory, String: The key name for the user defined data.

Returns: Hash reference.

=head2 meta_delete($name)

Deletes a user-defined shared memory segment.

Parameters:

    $name

Mandatory, String: The key name for the user defined data to delete.

=head2 meta_fetch

B<NOTE>: For most use cases, users should use the L</meta_get($name)> method as
opposed to this one. The data held in the shared memory is critical to proper
operation of the software.

Fetches and returns the shared memory data as a hash reference.

B<NOTE>: You should always wrap the C<meta_fetch()> call with calls to
C<meta_lock()> and C<meta_unlock()>.

=head2 meta_store($data)

B<NOTE>: For most use cases, users should use the L</meta_get($name)> method as
opposed to this one. The data held in the shared memory is critical to proper
operation of the software.

Serializes and stores the shared data.

Parameters:

    $data

Mandatory, Hash Reference. The data to store (should be a modified version that
was retrieved using C<meta_fetch()>).

B<NOTE>: You should always wrap the C<meta_store()> call with calls to
C<meta_lock()> and C<meta_unlock()>.

=head2 meta_lock($flags)

C<meta_fetch()> and C<meta_store()> do not lock on their own, so you must wrap
your fetch/mutate/store transactions with C<meta_lock()> and C<meta_unlock()>
to keep them atomic across processes.

Parameters:

    $flags

Mandatory, Integer. See L<flock|http://man7.org/linux/man-pages/man2/flock.2.html>
for details as to what's available here.

Default: If C<$flags> is not sent in, we default to an exclusive lock
(C<LOCK_EX>).

=head2 meta_unlock

Performs an unlock after you're done with C<meta_lock()>.

=head2 meta_key

Returns the integer shared memory key that links the object to the shared memory
segment.

B<NOTE>: This integer is derived by L<IPC::Shareable> from the string C<shm_key>
via a CRC32 hash (with signed 32-bit overflow correction), so it is B<not> the
raw byte-packed value of the string. For example, the default C<rpiw> string key
resolves to C<1323166506>.

=head2 meta_key_check($key)

Checks whether a shared memory segment with the key C<$key> exists or not.

Parameters:

    $key

Mandatory, String: The string key to validate against (eg. C<rpiw>). This is
converted to its integer segment key internally using the same CRC32 derivation
that L<IPC::Shareable> uses, then probed for existence without creating it.

Returns: True C<1> if the shared memory segment exists, and false C<0>
otherwise.

=head2 meta_erase($all)

Erases and resets all meta data. Do not use this method lightly.

Parameters:

    $all

Optional, Bool: If true, we'll delete the user-based C<storage> shared memory
data along with the software's internal data, and if false, we'll leave that
user data intact. Defaults to false (C<0>).

=head2 meta_remove

Removes the underlying shared memory segment (and its semaphore set) entirely,
freeing the SysV resources so the segment no longer appears in C<ipcs>.

This differs from L</meta_erase($all)>, which only empties the stored data but
leaves the segment allocated (it's created with C<destroy =E<gt> 0> so it
persists across processes). Use C<meta_remove()> when you're truly finished with
the segment and want to reclaim it.

B<NOTE>: A subsequent call to any C<meta_*> method transparently creates a fresh,
empty segment, so this is safe to call mid-process.

Returns: True C<1> if a segment was removed, or C<undef> if there was no live
segment to remove.

=head1 AUTHOR

Steve Bertrand, E<lt>steveb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016-2026 by Steve Bertrand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.
