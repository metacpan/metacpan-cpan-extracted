package Shared::Simple;

use 5.010;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Shared::Simple', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Shared::Simple - Inter-process shared memory key-value store

=head1 SYNOPSIS

  use Shared::Simple;

  # First process: create a fresh segment (cleans up any stale leftovers)
  my $shm = Shared::Simple->new('myapp', Shared::Simple::EXCLUSIVE);

  # Subsequent processes: attach to the existing segment
  my $shm = Shared::Simple->new('myapp', Shared::Simple::SHARED);
  # or simply omit the mode SHARED is the default
  my $shm = Shared::Simple->new('myapp');

  # Store a value
  $shm->put('greeting', 'hello');

  # Retrieve a value
  my $val = $shm->get('greeting');   # 'hello'

  # Missing key returns undef
  my $x = $shm->get('nosuchkey');    # undef

=head1 DESCRIPTION

C<Shared::Simple> provides a persistent, named key-value store backed by
POSIX shared memory (C<shm_open>/C<mmap>).  Multiple processes can open
the same named segment simultaneously; reads and writes are serialised
with a process-shared POSIX mutex.  The underlying hash table resizes
automatically when it runs out of space.

=head1 METHODS

=head2 new

  my $shm = Shared::Simple->new($name);
  my $shm = Shared::Simple->new($name, $mode);

Opens or creates a POSIX shared memory segment identified by C<$name>.

C<$mode> controls how an existing segment is handled and must be one of
the two constants exported by this module:

=over 4

=item C<Shared::Simple::SHARED> (default)

Create-or-attach semantics.  If the named segment does not yet exist it
is created and initialised; if it already exists the process attaches to
it.  This is the right mode for every worker that shares data with
others.  If another process is currently initialising the segment,
C<new> will wait up to five seconds before croaking with a timeout
error.

=item C<Shared::Simple::EXCLUSIVE>

Fresh-start semantics.  Any existing segment with this name is unlinked
before the new one is created, guaranteeing a clean, empty hash table.
Use this once at program startup -- typically in the parent process
before forking -- to ensure a consistent initial state regardless of
leftovers from previous runs.  See L</CAVEATS> for important
restrictions.

=back

C<$name> must be a non-empty string short enough to form a valid POSIX
shared memory name (roughly C<NAME_MAX - 1> characters on the target
platform).

Returns a blessed C<Shared::Simple> object.  Croaks on failure.

=head2 put

  $shm->put($key, $value);

Stores C<$value> under C<$key> in the shared segment.  If C<$key>
already exists its value is overwritten.

Constraints:

=over 4

=item *

Both C<$key> and C<$value> must be defined and non-empty strings.

=item *

C<$value> must not exceed B<32 bytes>.

=back

Returns C<1> on success.  Croaks on validation failure or an internal
error.

=head2 get

  my $value = $shm->get($key);

Looks up C<$key> in the shared segment.  Returns the stored string on
success, or C<undef> if the key does not exist.

C<$key> must be a defined, non-empty string; otherwise the method
croaks.

=head2 get_size

  my $n = $shm->get_size;

Returns the number of key-value pairs currently stored in the shared
segment as an integer.

=head2 get_all

  my $href = $shm->get_all;

Returns a reference to a Perl hash containing every key-value pair
currently stored in the shared segment.  The returned hash is a
snapshot taken under the lock; it is independent of the shared memory
and safe to read or modify after the call returns.

=head1 CONCURRENCY

All operations acquire a process-shared POSIX mutex before touching
shared memory.  On Linux, the mutex is configured as robust: if a
process dies while holding the lock, the next caller will recover it
automatically (C<EOWNERDEAD> handling).  This recovery is not available
on macOS.

=head1 LIMITATIONS

=over 4

=item *

Values are limited to B<32 bytes>.  Storing longer strings will croak.

=item *

The shared memory segment persists until it is explicitly unlinked from
the filesystem (e.g. with C<shm_unlink(3)>); destroying the Perl object
only detaches the mapping.

=back

=head1 CAVEATS

=head2 EXCLUSIVE mode is not safe to call concurrently

C<EXCLUSIVE> unlinks the underlying POSIX shared memory objects and
recreates them from scratch.  This is an inherently destructive,
non-atomic sequence of operations.  If two or more processes call
C<new> with C<EXCLUSIVE> for the same name at the same time, they will
race to destroy each other's live segment, causing data corruption,
invalid internal state, and unpredictable failures in every process
sharing that segment.

B<Only one process must ever call C<new> with C<EXCLUSIVE> for a given
name at any one time>, and no other process should be attached to the
segment when it does so.  The intended pattern is:

  # Parent / coordinator -- runs once before workers start
  Shared::Simple->new('myapp', Shared::Simple::EXCLUSIVE);

  # Workers -- fork after the parent has finished initialising
  for (1 .. $N) {
      fork or do {
          my $shm = Shared::Simple->new('myapp', Shared::Simple::SHARED);
          ...;
          exit;
      };
  }

=head1 AUTHOR

Denys Fisher, E<lt>shmakins at gmail dot comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 by Denys Fisher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
