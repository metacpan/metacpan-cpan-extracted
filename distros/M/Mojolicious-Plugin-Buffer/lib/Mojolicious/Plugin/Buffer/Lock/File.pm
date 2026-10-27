package Mojolicious::Plugin::Buffer::Lock::File;

use strict;
use warnings;
use autodie qw(:all);

use Mojo::Base -base;

use Carp qw(croak);
use Fcntl qw(:flock O_CREAT O_RDWR);
use File::Path ();
use File::Spec ();
use Mojo::Util qw(encode md5_sum trim);
use Mojolicious::Plugin::Buffer::I18N qw(i18n);
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Scalar::Util qw(blessed);
use Sub::Private { mode => 'enforce' };
use Sub::Protected;

use version; our $VERSION = version->declare('0.001.0');

# Lock files are created world-readable/writable before the umask is applied,
# so the directory's permissions decide who may take a lock
Readonly::Scalar my $LOCK_FILE_MODE => oct('0666');
Readonly::Scalar my $LOCK_FILE_SUFFIX => '.lock';

has dir => undef;
has messages => undef;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Buffer::Lock::File - flock-based lock backend

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

The usual way: give the plugin a directory and let it build this backend.

    use Mojolicious::Lite;
    use CHI;

    plugin 'Buffer' => {
	cache          => CHI->new(driver => 'File', root_dir => '/var/cache/myapp'),
	cache_lock_dir => '/var/lib/myapp/buffer-locks',
    };

Build the backend yourself, for example to reword its messages, and pass it
as C<cache_lock>:

    use Mojolicious::Plugin::Buffer::Lock::File;

    my $lock = Mojolicious::Plugin::Buffer::Lock::File->new(
	dir      => '/var/lib/myapp/buffer-locks',
	messages => {lock_failed => 'lock %{path} is broken: %{error}'},
    );
    plugin 'Buffer' => {cache => $cache, cache_lock => $lock};

Use it on its own, for example so that only one copy of a cron job rebuilds
a report at a time:

    use Mojolicious::Plugin::Buffer::Lock::File;

    my $lock = Mojolicious::Plugin::Buffer::Lock::File->new(dir => '/run/myapp');

    # Always take BOTH return values (see COMMON PITFALLS)
    my ($guard, $error) = $lock->acquire('nightly-report');
    die "$error\n" if defined $error;
    exit 0 unless $guard;    # another copy is already running

    build_report();
    $lock->release($guard);

Spread the lock files over sub-directories by overriding the protected
C<_path> method in a subclass:

    package MyApp::Lock;
    use Mojo::Base 'Mojolicious::Plugin::Buffer::Lock::File';
    use File::Path ();
    use File::Spec ();
    use Mojo::Util qw(encode md5_sum);

    sub _path {
	my ($self, $key) = @_;
	my $digest = md5_sum(encode('UTF-8', $key));
	my $sub = File::Spec->catdir($self->dir, substr($digest, 0, 2));
	File::Path::make_path($sub);
	return File::Spec->catfile($sub, "$digest.lock");
    }

=head1 DESCRIPTION

This is the built-in lock backend for L<Mojolicious::Plugin::Buffer>.  The
plugin uses it when you set
L<cache_lock_dir|Mojolicious::Plugin::Buffer/cache_lock_dir>.

=head2 What problem does it solve?

A web server often runs several copies of your program at the same time.
Each copy is called a I<worker>.  When a page is not in the cache yet, every
worker that gets a request for it would build the same page at the same
time.  That wastes work.  A I<lock> lets exactly one worker build the page.
The other workers wait, then read the finished page from the cache.

=head2 How it works, in plain words

=over 4

=item 1. Each cache key gets its own small, empty file in L</dir>.  The file
name is the MD5 digest of the key, so any key makes a safe file name.

=item 2. To take the lock, the backend opens that file and asks the operating
system for an exclusive lock on it (C<flock>).  It does not wait: if another
open file handle already holds the lock, the answer is "busy" at once.

=item 3. The lock lasts as long as the file stays open.  The open file lives
inside the I<guard> that L</acquire> returns.

=item 4. L</release> closes the file, which frees the lock.  If the process
crashes or is killed, the operating system closes the file and frees the
lock too.  So a dead worker can never block a key for ever.

=back

All workers must use the same directory.  This works for workers on one
machine.  For workers on different machines, use
L<Mojolicious::Plugin::Buffer::Lock::Redis>.

=head2 Words used in this document

=over 4

=item key

A text string that names one cache entry, for example C<buffer:0123abcd>.

=item guard

The value L</acquire> returns when you get the lock.  Keep it, and give it
back to L</release>.  Do not look inside it.

=item flock

The operating system's file-locking call.  Only one open file handle can
hold an exclusive C<flock> on a file at a time.

=back

=head1 ATTRIBUTES

Attributes are set with L</new>.  Each one also has an accessor method with
the same name, made by L<Mojo::Base>.

=head2 dir

The directory that holds the lock files.  It is required.  L</new> creates it
(and any missing parent directories) and checks that it is writable.

=head3 API SPECIFICATION

=head4 Input

    # $lock->dir reads the value.  $lock->dir($path) changes it WITHOUT
    # creating or checking the directory; see COMMON PITFALLS.
    { dir => { type => 'string', min => 1, optional => 1 } }

=head4 Output

    # Return::Set schema: the path when reading, the object when writing
    { type => 'string' }

=head2 messages

An optional hash of message overrides, keyed by message key.  See
L<Mojolicious::Plugin::Buffer::I18N> for the keys and the text format.  The
plugin passes its own C<messages> option here when it builds this backend
from C<cache_lock_dir>.

=head3 API SPECIFICATION

=head4 Input

    { messages => { type => 'hashref', optional => 1 } }

=head4 Output

    # Return::Set schema: the hash (or undef) when reading, the object
    # when writing
    { type => 'hashref', optional => 1 }

=head1 METHODS

=head2 new

    my $lock = Mojolicious::Plugin::Buffer::Lock::File->new(dir => $dir);

=head3 Purpose

Create the backend, creating the lock directory if necessary.

=head3 Arguments

=over 4

=item C<dir> (named, required)

A directory path, as a non-empty string.

=item C<messages> (named, optional)

A hash of message overrides.

=back

=head3 Returns

The new object.

=head3 Side effects

Creates C<dir> and any missing parents.

=head3 Example

    my $lock = Mojolicious::Plugin::Buffer::Lock::File->new(
	dir => '/var/lib/myapp/buffer-locks',
    );

=head3 API SPECIFICATION

=head4 Input

    {
	dir      => { type => 'string', min => 1 },
	messages => { type => 'hashref', optional => 1 },
    }

=head4 Output

    # Return::Set schema
    { type => 'object', isa => 'Mojolicious::Plugin::Buffer::Lock::File' }

=head3 MESSAGES

    Key                     Message                                         Resolution
    ----------------------  ----------------------------------------------  ---------------------------------
    option_cache_lock_dir   cache_lock_dir must be a directory path         Pass a non-empty string
    lock_dir_create_failed  cannot create cache_lock_dir 'DIR': OS ERROR    Fix the parent's permissions, or
                                                                            the path (e.g. a file is in the
                                                                            way)
    lock_dir_not_writable   cache_lock_dir 'DIR' is not a writable          Change the owner or mode of DIR
                            directory

All three croak.  The OS error is Perl's C<$!> text and follows the
process's C<LC_MESSAGES> only inside C<use locale>.

=cut

sub new {
	my ($class, @args) = @_;

	# Params::Get accepts both new(dir => ...) and new({dir => ...})
	my $self = $class->SUPER::new(get_params(undef, @args) // {});
	my $dir = $self->dir;

	croak $self->i18n('option_cache_lock_dir') unless _valid_dir($dir);

	# Ask File::Path for structured errors: plain $! text per path, without
	# the "at FILE line N" its own die would add.  The last entry is about
	# the directory itself, which is the one the user named.
	File::Path::make_path($dir, {error => \my $errors});
	if ($errors && @$errors) {
		my ($path, $message) = %{$errors->[-1]};
		croak $self->i18n('lock_dir_create_failed', {dir => $dir, error => length($path) ? "$path: $message" : $message});
	}
	croak $self->i18n('lock_dir_not_writable', {dir => $dir}) unless -d $dir && -w $dir;

	return $self;
}

=head2 acquire

    my ($guard, $error) = $lock->acquire($key);

=head3 Purpose

Try, without waiting, to become the only process building C<$key>.

=head3 Arguments

=over 4

=item C<$key> (positional, required)

The cache key: any defined string, in any language, emoji included.  Only
its MD5 digest reaches the file system.

=back

=head3 Returns

A two-element list, as the lock protocol in
L<Mojolicious::Plugin::Buffer/cache_lock> requires: C<($guard, undef)> when
the lock was taken, C<(undef, undef)> when another process holds it, and
C<(undef, $error)> on failure.  The guard is opaque.  Call it in list
context; see L</COMMON PITFALLS>.

=head3 Side effects

Creates the lock file if it does not exist and keeps it open while the
guard lives.

=head3 Example

    my ($guard, $error) = $lock->acquire('buffer:0123abcd');
    if ($guard) {
	# ... build the entry ...
	$lock->release($guard);
    } elsif (defined $error) {
	warn $error;
    } else {
	# somebody else is building it
    }

=head3 API SPECIFICATION

=head4 Input

    { key => { type => 'string', position => 0 } }

=head4 Output

    # Return::Set schema (list of two)
    {
	type => 'arrayref',
	schema => [
	    { type => 'hashref', optional => 1 },   # guard
	    { type => 'string',  optional => 1 },   # error
	],
    }

=head3 MESSAGES

    Key                 Message                        Resolution
    ------------------  -----------------------------  ---------------------------------
    lock_key_undefined  cache key is not defined       Pass a defined key
    lock_open_failed    cannot open PATH: OS ERROR     Check the directory still exists
                                                       and is writable
    lock_failed         cannot lock PATH: OS ERROR     The filesystem does not support
                                                       flock; use another backend

These are returned, not thrown.

=head3 PSEUDOCODE

    reject an undefined key
    open (creating) DIR/md5(key).lock
    on failure return the OS error
    try a non-blocking exclusive flock
    if it succeeded, return a guard holding the handle
    close the handle
    if flock said "would block", return (undef, undef)
    otherwise return the OS error

=cut

sub acquire {
	my ($self, @args) = @_;

	# get_params() confesses on an empty list; no key is a returned error
	my $key = @args ? get_params('key', @args)->{key} : undef;
	return (undef, $self->i18n('lock_key_undefined')) unless defined($key);

	my $path = $self->_path($key);

	# autodie turns a failed sysopen into an exception carrying $!
	my $fh = eval { sysopen(my $handle, $path, O_RDWR | O_CREAT, $LOCK_FILE_MODE); $handle };
	return (undef, $self->i18n('lock_open_failed', {path => $path, error => _os_error($@)})) unless $fh;

	# autodie does not throw when a LOCK_NB flock would block: it returns
	# false, which is the "somebody else holds it" answer
	my $locked = eval { flock($fh, LOCK_EX | LOCK_NB) };
	my $error = $@;
	return ({fh => $fh, path => $path}, undef) if $locked;

	eval { close($fh) };
	return (undef, undef) unless $error;
	return (undef, $self->i18n('lock_failed', {path => $path, error => _os_error($error)}));
}

=head2 release

    my ($ok, $error) = $lock->release($guard);

=head3 Purpose

Give up a lock taken by L</acquire>.

=head3 Arguments

=over 4

=item C<$guard> (positional, required)

A guard returned by L</acquire>.  A false value, or a guard that was already
released, is accepted and ignored.

=back

=head3 Returns

C<(1, undef)> on success, C<(0, $error)> if unlocking or closing failed.  The
lock is gone either way, because the handle is closed.

=head3 Side effects

Unlocks and closes the lock file handle and removes it from the guard.

=head3 Example

    my ($ok, $error) = $lock->release($guard);
    warn $error unless $ok;

=head3 API SPECIFICATION

=head4 Input

    { guard => { type => 'hashref', optional => 1, position => 0 } }

=head4 Output

    # Return::Set schema (list of two)
    {
	type => 'arrayref',
	schema => [
	    { type => 'boolean' },                  # released
	    { type => 'string', optional => 1 },    # error
	],
    }

=head3 MESSAGES

    Key            Message                        Resolution
    -------------  -----------------------------  -------------------------
    unlock_failed  cannot unlock PATH: OS ERROR   Usually harmless: closing
                                                  the handle drops the lock

=cut

sub release {
	my ($self, $guard) = @_;

	my $fh = (ref($guard) eq 'HASH') ? delete($guard->{fh}) : undef;
	my $ok = !$fh || eval { flock($fh, LOCK_UN); close($fh); 1 };

	# The handle is gone either way, so the lock is gone too; only report
	return $ok
		? (1, undef)
		: (0, $self->i18n('unlock_failed', {path => $guard->{path}, error => _os_error($@)}));
}

# Purpose:        Map a cache key to its lock file path.
# Entry criteria: $key is a defined string.
# Exit status:    An absolute or dir-relative path ending in .lock.
# Side effects:   None.  Protected so a subclass can share a directory
#                 layout, e.g. sharding the files into subdirectories.
sub _path :Protected {
	my ($self, $key) = @_;

	# md5_sum dies on characters above 255, so hash the UTF-8 bytes
	return File::Spec->catfile($self->dir, md5_sum(encode('UTF-8', $key)) . $LOCK_FILE_SUFFIX);
}

# Purpose:        Check that a value can name the lock directory.
# Entry criteria: Any scalar.
# Exit status:    True for a non-empty, non-reference string.
# Side effects:   None.
sub _valid_dir :Private {
	my $dir = shift;

	return eval { validate_strict(schema => {dir => {type => 'string', min => 1}}, input => {dir => $dir}); 1 } && !ref($dir);
}

# Purpose:        Extract the OS error text from an exception.
# Entry criteria: An autodie::exception, or any other exception.
# Exit status:    The $! text for an autodie exception, else the trimmed
#                 exception text.
# Side effects:   None.
sub _os_error :Private {
	my $exception = shift;

	return (blessed($exception) && $exception->isa('autodie::exception'))
		? '' . $exception->errno
		: trim("$exception");
}

1;

=head1 COMMON PITFALLS

=over 4

=item * B<Always take both return values.>  L</acquire> returns a list of
two values.  In scalar context Perl gives you only the I<last> one, which is
the error slot:

    my $guard = $lock->acquire($key);           # WRONG: $guard is undef
    my ($guard, $error) = $lock->acquire($key); # right

The wrong form is worse than it looks.  The real guard is thrown away at
once, which closes the file, so the lock you just took is released before
the next line runs.

=item * B<Keep the guard while you work.>  The lock lives inside the guard.
If the guard variable goes out of scope, the file is closed and the lock is
freed, even though you never called L</release>.

=item * B<The lock is not re-entrant.>  If your own process already holds
the lock for a key, a second C<acquire> for the same key returns "busy"
C<(undef, undef)>.  This is true even for the same object, because each call
opens a new file handle.

=item * B<Forking while you hold a lock shares it.>  A child process made
with C<fork> inherits the open file, so the lock stays held until the parent
I<and> the child have closed it.  Release locks before you fork.

=item * B<Do not change C<dir> after C<new>.>  L</new> creates and checks the
directory.  Setting it later with C<< $lock->dir($path) >> skips both checks,
so a typing mistake only shows up as an error from every L</acquire>.

=item * B<Lock files are never deleted.>  There is one empty file per key
that was ever built.  Deleting a file while another process has it open
would let two builders run, so only clean the directory while the
application is stopped.

=item * B<Network file systems.>  C<flock> is unreliable on some network
file systems, especially older NFS.  Use
L<Mojolicious::Plugin::Buffer::Lock::Redis> when workers are on different
machines.

=item * B<undef values.>  C<acquire(undef)> does not die; it returns
C<(undef, 'cache key is not defined')>.  The empty string is a valid key.
C<release(undef)> and releasing the same guard twice both return
C<(1, undef)> and do nothing.  C<< new(dir =E<gt> undef) >> croaks.
C<< messages =E<gt> undef >> means "no overrides".

=back

=head1 ENCODING

=over 4

=item Keys

Any Perl string is safe, including accented letters, any other non-ASCII
text and emoji.  The key is encoded as UTF-8 bytes before it is hashed, so
the same characters always name the same lock file, however Perl stores
them internally.  Only the MD5 digest reaches the file system.  A subclass
that overrides C<_path> must do the same, because C<md5_sum> dies on a
character above U+00FF.

=item dir

A directory name goes to the operating system as bytes.  An ASCII path is
always safe.  For a non-ASCII path, pass a byte string that is already
encoded the way your file system expects, usually UTF-8:

    use Encode qw(encode);
    my $lock = Mojolicious::Plugin::Buffer::Lock::File->new(
	dir => encode('UTF-8', "/srv/caf\x{e9}/locks"),
    );

=item messages

Override texts may hold any characters, including emoji.  The messages this
module returns are Perl character strings.  Print them to a handle with an
encoding layer, such as C<binmode(STDERR, ':encoding(UTF-8)')>, or Perl
warns "Wide character".  L<Mojo::Log> encodes to UTF-8 by itself.

=item Operating-system errors

The text after C<OS ERROR> in a message is Perl's C<$!>.  It is English
unless the program runs under C<use locale>.

=back

=head1 LIMITATIONS

=over 4

=item * Lock files are never deleted.  Removing one while another process
has it open would let a third process lock a new file of the same name, and
two builders would run.  They are empty, so the cost is one inode per key
ever built.

=item * C<flock> is only advisory and is unreliable on some network
filesystems (older NFS in particular).  Use the Redis backend there.

=item * The protocol returns a two-element list rather than a reference,
because that is the documented interface third-party backends implement.

=back

=head1 SEE ALSO

L<Mojolicious::Plugin::Buffer>, L<Mojolicious::Plugin::Buffer::Lock::Redis>,
L<Mojolicious::Plugin::Buffer::I18N>.

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 FORMAL SPECIFICATION

This section describes the backend in the Z notation, for readers who want
an exact model.  You do not need it to use the module.  C<KEY> is the set of
cache keys, C<PATH> the set of file names and C<PID> the set of processes.
C<held> records which process holds the lock for each key.

    [KEY, PATH, PID, TEXT, Guard]

    file : KEY → PATH
    ∀ k : KEY • file k = dir ⁀ "/" ⁀ md5(utf8(k)) ⁀ ".lock"

    ┌─ Locks ─────────────────────────────────────
    │ dir : PATH
    │ held : KEY ⇸ PID
    ├─────────────────────────────────────────────
    │ dir ≠ ∅
    └─────────────────────────────────────────────

    ┌─ ProcessExit ───────────────────────────────
    │ ΔLocks
    │ p? : PID
    ├─────────────────────────────────────────────
    │ held′ = held ⩥ {p?}
    └─────────────────────────────────────────────

=head2 new

    ┌─ New ───────────────────────────────────────
    │ Locks′
    │ dir? : PATH ; fs, fs′ : PATH ⇸ Node ; result! : Locks
    ├─────────────────────────────────────────────
    │ dir? ≠ ∅
    │ dir? ∈ dom fs′ ∧ isDirectory(fs′ dir?) ∧ writable(fs′ dir?)
    │ fs ⊆ fs′
    │ dir′ = dir? ∧ held′ = ∅ ∧ result! = θLocks′
    └─────────────────────────────────────────────
    -- Otherwise: croak, and fs′ may hold the parents created so far

=head2 acquire

C<ok> means the lock file could be opened and the file system supports
C<flock>.  The lock is not re-entrant: when C<held key? = me> the result is
"busy", the same as for any other holder.

    ┌─ Acquire ───────────────────────────────────
    │ ΔLocks
    │ key? : KEY ; me : PID
    │ guard! : Guard ∪ {⊥} ; error! : TEXT ∪ {⊥}
    ├─────────────────────────────────────────────
    │ ok ∧ key? ∉ dom held ⇒
    │     held′ = held ⊕ {key? ↦ me} ∧ guard! ≠ ⊥ ∧ error! = ⊥
    │ ok ∧ key? ∈ dom held ⇒
    │     held′ = held ∧ guard! = ⊥ ∧ error! = ⊥
    │ ¬ok ⇒
    │     held′ = held ∧ guard! = ⊥ ∧ error! ≠ ⊥
    └─────────────────────────────────────────────

=head2 release

    ┌─ Release ───────────────────────────────────
    │ ΔLocks
    │ guard? : Guard ∪ {⊥} ; ok! : 𝔹 ; error! : TEXT ∪ {⊥}
    ├─────────────────────────────────────────────
    │ guard? ≠ ⊥ ⇒ held′ = {key(guard?)} ⩤ held
    │ guard? = ⊥ ⇒ held′ = held ∧ ok! = true
    │ ok! = true ⇔ error! = ⊥
    └─────────────────────────────────────────────
    -- The lock is gone even when ok! = false, because the handle is closed

=head1 STATE DIAGRAM

Each cache key's lock is in one of two states.  The backend object itself
has no other state: after L</new> it is ready, and it stays ready.  The
numbers on the arrows are explained below the picture.

       +-----------+            (1)              +-----------+
       |   FREE    | --------------------------> |   HELD    |
       |  (key k)  | <-------------------------- |  (key k)  |
       +-----------+       (2), (3) or (4)       +-----------+
          |     ^                                    |     ^
          +-----+ (5), (7)                           +-----+ (6), (8)

    (1) acquire(k)  [the file opens and flock is granted]
        / returns (guard, undef); the file stays open inside the guard
    (2) release(guard)
        / unlock and close the file; returns (1, undef), or (0, error)
          if unlocking failed - the lock is gone either way
    (3) the guard goes out of scope
        / Perl closes the file, which frees the lock
    (4) the holding process exits or is killed
        / the operating system closes the file, which frees the lock
    (5) acquire(k)  [the file cannot be opened, or flock is not supported]
        / returns (undef, error); nothing changes
    (6) acquire(k)  [flock would block], from ANY process, the holder too
        / returns (undef, undef); nothing changes
    (7) release(undef), or release of a guard already released
        / returns (1, undef); nothing changes
    (8) fork()
        / the child shares the open file, so the key stays HELD until
          both processes have closed it

The plugin's own use of these states is drawn in
L<Mojolicious::Plugin::Buffer/STATE DIAGRAM>.

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut
