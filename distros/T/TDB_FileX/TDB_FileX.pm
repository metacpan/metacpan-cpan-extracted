package TDB_FileX;

use common::sense;

use Exporter ();
use XSLoader ();

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our %EXPORT_TAGS = (
   flags => [qw(
      ALLOW_NESTING
      BIGENDIAN
      CLEAR_IF_FIRST
      CONVERT
      DEFAULT
      DISALLOW_NESTING
      INCOMPATIBLE_HASH
      INTERNAL
      MUTEX_LOCKING
      NOLOCK
      NOMMAP
      NOSYNC
      SEQNUM
      VOLATILE
   )],
   insert => [qw(
      INSERT
      MODIFY
      REPLACE
   )],
   error => [qw(
      SUCCESS
      ERR_CORRUPT
      ERR_EXISTS
      ERR_IO
      ERR_LOCK
      ERR_LOCK_TIMEOUT
      ERR_NOEXIST
      ERR_NOLOCK
      ERR_OOM
      ERR_EINVAL
      ERR_RDONLY
   )],
   debug => [qw(
      DEBUG_FATAL
      DEBUG_ERROR
      DEBUG_WARNING
      DEBUG_TRACE}
   )],
);

our @EXPORT_OK;

Exporter::export_ok_tags qw(flags insert error debug);

$EXPORT_TAGS{all} = \@EXPORT_OK;

our $VERSION = '0.97';

XSLoader::load __PACKAGE__, $VERSION;

1;
__END__

=head1 NAME

TDB_FileX - Perl access to the trivial database library

=head1 SYNOPSIS

  use TDB_FileX;

  # tie interface
  tie %hash, TDB_FileX => $filename,
     hash_size => 8000,
     mutex     => 1,
  ;
  $hash{key} = 'value';
  while (my ($k, $v) = each %hash) { print "$k -> $v\n" }

  # OO interface
  my $tdb = TDB_FileX->open ($filename, flags => TDB_FileX::CLEAR_IF_FIRST)
     or die $!;

  $tdb->store (key => 'value') or die $tdb->errorstr;
  $tdb->traverse (sub { print "$_[0] -> $_[1]\n" });

=head1 DESCRIPTION

TDB is a simple database similar to GDBM, but allows multiple simultaneous
writers. It's main drawback is the need to manually configure a hash table
size in advance - see the C<hash_size> option for C<open>.

TDB_FileX provides a simple C<tie> interface, similar to DB_File and
friends; and an object-oriented interface, which provides access to most
of the functions in the TDB library.

=head2 COMPARISON TO OTHER DBMS

TDB stands for trivial database - and indeed, the database structure is
very simple, requiring manual sizing at creation time, and being limited
to 4GB size.

But otherwise, TDB has features that no other simple DBM has -
fine-grained locking, multiprocess database access and transactions.

GDBM_File for example has a single per-process lock, so only one process
can write to the database. Most others have no locking and will happily
corrupt your database. TDB_FileX is safe to use from multiple processes.

As for data safety, GDBM databases easily corrupt (in current version of
GDBM), and while GDBM databases can be 30% more compact than equivalent
TDB databases, they tend to grow over time (I regularly find 10GB GDBM
databases (actual disk usage) that reorganize to 300MB files and have
never stored more than that). TDB files do not usually have such bad
growth behaviour, but also have no reorganize function to shrink the
database again.

So, if you want safe access from multiple proceses and have a good idea
of how many keys to store, TDB_FileX is the thing. If you only want
protectioon against obvious data corruption and processes can wait, GDBM
is a probably a better choice.

=head1 ERROR HANDLKING

The TDB C API is not well designed - among other things, error handling
is a bit erratic. Many TDB functions that normally should just work are
marked with a [CROAK] - these will throw an exception on error, the
exception string being the error message. C<$!> is set to the numerical
error value in that case (and will stringify into the wrong OS-error
string, so don't do that!).

This is so that you can concentrate on the important parts, while there
are still no silent unexpected errors.

The other functions will not generally croak - check their description for
details on how errors are handled.

Functions that are not part of the TDB API (such as
C<register_hash_function>) may croak on errors without being marked as
such. The above only refers to TDB API functions, as they cannot throw
perl exceptions themselves.

=head2 FUNCTIONS

=over 4

=item $tdb = tie %hash, TDB_FileX => $path[ , key => value...]

=item $tdb = TDB_FileX->open ($path[, key => value...])

TDB_FileX constructor (same as C<TIE>). Opens $path and returns a
TDB_FileX object. The same arguments may be passed to the C<tie>
function. On error, C<undef> is returned.

You should consider specifying at least C<log_cb> and C<hash_size> (and
possibly C<mutex>), everything else has sensible defaults.

To open a tdb file that is created and used by another application
(maximising compatibility):

   my $tdb = TDB_FileX->open ($path, log_cb => sub { warn $_[1] })
      or die "$path: failed to open\n";

To successfully open another database, you might have to duplicate some of
the settings, e.g. whether mutex locking is used or the hash function. The
C<log_cb> output usually will tell you what's wrong.

To open a tdb file with good performance for many thousands of large keys,
maybe not compatible to other programs:

   my $tdb = TDB_FileX->open ($path,
      hash_size => 10000,
      hash      => "xxh3",
      mutex     => 1,
      nocow     => 1,
      log_cb    => sub { warn $_[1] },
   ) or die "$path: failed to open\n";

The following key-value pairs are understood:

=over

=item tdb_flags => $flags (default: C<TDB_FileX::DEFAULT>)

A set of flags that influence the behaviour and format of the database.

=over

=item C<DEFAULT>

Same as C<0> - no flags.

=item C<CLEAR_IF_FIRST>

If this is the first open, wipe the db.

=item C<INTERNAL>

In-memory database only, path will be ignored.

=item C<NOLOCK>

Don't do any locking.

=item C<NOMMAP>

Don't use mmap.

=item C<NOSYNC>

Don't use synchronous transactions.

=item C<SEQNUM>

Maintain a sequence number.

=item C<VOLATILE>

Activate the per-hashchain freelist, default 5. (Same as calling
C<set_max_dead> with C<5> instead of the default C<0>).

=item C<ALLOW_NESTING>

Allow transactions to nest.

=item C<DISALLOW_NESTING>

Disallow transactions to nest.

=item C<INCOMPATIBLE_HASH>

Better default hash functioa, but can't be opened by tdb < 1.2.6.

=item C<MUTEX_LOCKING>

Optimized locking using robust mutexes if supported,

=back

=item open_flags => $flags (default: C<Fcntl::O_RDWR | Fcntl::O_CREAT>)

Standard open flags, as used in C<sysopen>.

=item mode => $mode (default: C<0666>)

Standard file open mode, as use din C<sysopen>. Only used when creating
the database file.

=item hash_size => $int (default: internal to libtdb, but normally C<131>)

The size of the internal hash table - only used when creating the
database. The default is usually very low and only good for a few thousand
keys. As a rule of thumb, it should be at least one percent of the number
of keys you plan to store, e.g. for C<800000> keys you should use around a
size of C<8000>.

Every hash entry is only 4 octets, os usually it isn't an issue to make the
hash table too large.

To give you an idea of the performance, I inserted about 600000 records,
3GB of data, into a TDB file, using different hash sizes.

    size time
     131 160s
     256  85s
    1024  12s
    4096   5s
    8192   4s

As you can see, the default hash table size for this case caused it to
use 40 times the time to insert than a larger hash table, the optimum
being around 75 keys per hash entry. But the databse easily was cached in
memory. If that is not the case, you might want to consider a hash table
that is larger than the number of keys you want to store - each hash slot
only uses 4 octets.

=item log_cb => $cb->($level, $msg)

Sets a code reference that is called with a message and a log level
(lower means more important, there are C<DEBUG_FATAL>, C<DEBUG_ERROR>,
C<DEBUG_WARNING> and C<DEBUG_TRACE}>). Unlike the "debug" in the name
might indicate, if you want to find out why, for instance, you could not
open a database, you need to use a logging callback.

=item hash => $hash (default: C<undef>)

Selects a hash function to use.

=over

=item C<"default"> or C<undef>

Use autodetection and use either C<"jenkins"> or the original tdb hash function.

=item C<"jenkins">

The jenkins hash function. Relatively fast, and recommended for modern tdb databases
that need to be interoperable between implementations.

=item C<"fnv1ax">

The FNV1-A hash with 32 bit post-mixing. Pretty good and very fast for
keys up to 10-20 octets.

=item C<"xxh3">

The XXH3 hash. Very good and fast especially for long keys.

=item value returned by C<register_hash_function>

Use a custom hash function registered via C<register_hash_function>.

=back

=item mutex => $bool (default: C<0>)

TDB can take advantage of fast interprocess mutexes, which can be
orders of magnitude faster than the syscall-based locking used by
default, but only works on the same machine.

Normally, you need to call C<TDB_FileX::runtime_check_for_robust_mutexes>
and set the C<MUTEX_LOCKING> flag if support is indicated.

This option, when enabled, enables C<MUTEX_LOCKING> if it is supported
by the platform - which involves a fork when opening the database. When
disabled, it will remove the flag.

It is recommended to keep this one, but enabling this changes the format
of the database, so might not be an option if interoperability with other
programs is required.

=item nocow => $bool (default: C<0>)

Set the no-copy-on-write flag I<iff> this flag is true, C<open_flags>
contains C<O_CREAT>, C<tdb_flags> do not contain C<INTERNAL> and this is
supported on the platform and filesystem. Copy-on-write filesystems have
to make a copy of every block written to, which can both be costly and can
cause massive fragmentation of the database file.

Setting the no-copy-on-write flag (same as C<chattr +C>) disables this,
usually at the expense of data protection (checksumming), reducing the
safety to the level of a normal filesystem such as ext4.

This is best effort and usually only takes effect when the
database is initially created. If it fails, TDB_FileX will simply
continue. Correctness should not be affected either way.

=back

There is no explicit close function. The database is closed implicitly
when there are no remaining references.

=item $tdb->store ($key, $value[, $flag=REPLACE]) [CROAK]

Store $value in the database with key w$key. The $flag defaults to
C<REPLACE>, but can also be C<INSERT> or C<MODIFY>, see tdb_store(3) for
details.

=item $tdb->append ($key, $value) [CROAK]

Appends $data to the data already stored for $key, or creates a new entry with it.

=item $data = $tdb->fetch ($key) [CROAK]

Fetch the value associated with $key, or C<undef> if it is not found (or
on any error).

=item $tdb->delete ($key) [CROAK]

Delete the value associated with $key.

=item $bool = $tdb->exists ($key)

Return true if the $key is found, false otherwise.

=item $key = $tdb->firstkey

Return the key of the first value in the database. Returns C<undef> on
failure or if there are no keys in the database. See tdb_firstkey(3)
for details.

=item $key = $tdb->nextkey ($lastkey)

Return the next key in the database after $lastkey. Returns C<undef> on
failure or if there are no more keys in the database. See tdb_nextkey(3)
for details.

=item $code = $tdb->error

Returns the current error state of the C<$tdb> object. See the list of
error codes given in L<EXPORTS>.

=item $mesage = $tdb->errorstr

Returns a printable string that describes the error state of the
database.

=item $tdb->reopen [CROAK]

Closes and reopens the database. Required after a
L<fork|perlfunc/fork>, if both processes wish to use the database.

B<NB:> If C<reopen> fails, then it is unsafe to call any further methods
on C<$tdb>. Thus, the only way to find out I<why> C<reopen> failed is to
use a logging function.

=item TDB_FileX::reopen_all [CROAK]

Closes and reopens all open databases. See C<reopen>.

B<NB:> If C<reopen_all> fails, there is no indication of I<which> C<$tdb>
objects failed or why. If you have to survive failures, you may wish to do
your own C<reopen> loop instead.

=item $tdb->traverse ($cb->($key, $data)) [CROAK]

Call $cb for each entry in the database. The callback should return false
to continue, or a true value to abort the traversal.

The callback is called with the key and value as arguments and should
return a false value if you wish to continue traversal, and a true value
if the traversal should be aborted.

C<traverse> returns the number of elements traversed. If $cb is C<undef>,
then this function simply counts the number of elements.

=item $tdb->traverse_read ($cb->($key, $data)) [CROAK]

Like C<traverse>, but only acquires a read lock.

=item $tdb->set_logging_function ($cb->($level, $msg))

Set the logging function to use when this database object encounters
errors.

$cb is called with the severity level (an integer) and the message (a
string).

=item $tdb->lockall [CROAK]

Lock an entire database with an exclusive write lock, returning false on
error. The purpose of this call is to avoid locking overhead for many
operations, but the database has to be unlocked manually when done.

=item $tdb->unlockall [CROAK]

Unlock an entire database previously locked with
C<lockall>.

=item $tdb->lockall_read [CROAK]

Same as C<lockall>, but uses a shared read lock instead of a writer lock.

=item $tdb->unlockall_read [CROAK]

Opposite of C<lockall_read>.

=item $tdb->lockall_mark [CROAK]

=item $tdb->lockall_unmark [CROAK]

These apparently mark and unmark locks internally, but do not actually do
locking. Probably you should not use this, but feel free to tell me when
these are useful.

=item $tdb->lockall_nonblock [CROAK]

=item $success = $tdb->lockall_read_nonblock [CROAK]

Try to lock, but instead of waiting, fail if the lock could not
be acquired. Returns true if the lock could be acquired, false
otherwise. Croaks on all other errors.

=item $tdb->transaction_start [CROAK]

Starts a transaction - all operations will be queued, but not applied
to the database, until the transaction is either committed C<transaction_commit>
or aborted/thrown away, with C<transaction_cancel>.

=item $tdb->transaction_start_nonblock [CROAK]

Tries to start a transaction, but instead of waiting, fail if the lock
could not be acquired. Returns true if the transaction could be started,
false otherwise. Croaks on all other errors.

Please tell me what this does.

=item $tdb->transaction_commit [CROAK]

Applies all changes in the transaction.

=item $tdb->transaction_cancel [CROAK]

Throws away all changes in the transaction.

=item $tdb->transaction_prepare_commit [CROAK]

Instead of calling C<transaction_commit> you can do the commit in
two phases by calling this method before commit, which does the expensive
steps first.

=item $bool = $tdb->transaction_active

Returns true if a transaction is currently active.

=item $tdb->enable_seqnum

Enables sequence number generatiuon supporet for the database.

=item $seq = $tdb->get_seqnum

Returns the current sequence number. Internally, this is a 32 bit unsigned
integer, but the API converts it into a native integer, so the same
internal sequence number might be represented differently on different
machines.

=item $tdb->increment_seqnum_nonblock

Increments the sequence number. Note that the sequence number is also
incremented by TDB itself oon many operations.

=item $size = $tdb->hash_size

Returns the size of the hash table. The size cannot be changed other than
by recreating the database.

=item $octets = $tdb->map_size

Returns the current mmap size for the database.

=item $flags = $tdb->get_flags

Returns the flags for the database (the same as the C<tdb_flags> in C<open>).

=item $tdb->add_flags ($flag)

Tried to add flags to the database - yes, the parameter says C<$flag> (singular)
but the documentation and the code say I<flags> (plural).

=item $tdb->remove_flags ($flag)

Attempts to remove flags from the database.

=item $tdb->set_max_dead ($max_dead)

Set the maximum number of dead records per hash chain.

=item $fileno = $tdb->fd

Returns the file descriptor (not file handle) for the underlying database file.

=item $path = $tdb->name

Returns the path used to open the database.

=item $tdb->wipe_all [CROAK]

Efficientlly deletes all entries in the database. This does not shrink the
file itself.

=item $tdb->repack [CROAK]

Tries to improve layout of the database by copying all items into a
temporary in-memory database, wiping the database, and copying all items
back. Yes, everything must fit into memory.

=item $bool = $tdb->check ($cb->($key, $value))

Does extensive checks on the database, optionally (if not C<undef>)
calling a check function for each pair, which must return true if the data
is valid.

Returns a boolean indicating whether the database was found healthy and
all the calls to the callback returned true.

=item $bool = $tdb->rescue ($cb->($key, $value))

Tries to recover some or all key-value pairs from a potentially damanged
database file. For each recovered pair it calls the given callback.

Returns a boolean indicating whether the database was found healthy and
all the calls to the callback returned true.

=item $bool = TDB_FileX::runtime_check_for_robust_mutexes

Tests whether robust mutexes are available for locking. This involves
forking the process, so it can be costly and problematic. This function
needs to be called before using the C<MUTEX_LOCKING> flag. But see the
C<mutex> parametrer to C<open> for an alternative.

=item $tdb->dump_all

Dump the records and freelist to STDOUT in an almost human readable
form.

=item $summary = $tdb->summary

Return a textual summary of the database. The format isn't documented,
but for some random databas,e I got this output:

   Size of file/data: 325001216/238324906
   Header offset/logical size: 4001792/320999424
   Number of records: 117209
   Incompatible hash: no
   Active/supported feature flags: 0x00000001/0x00000001
   Robust mutexes locking: yes
   Smallest/average/largest keys: 11/36/102
   Smallest/average/largest data: 10/1997/2921430
   Smallest/average/largest padding: 9/530/749374
   Number of dead records: 0
   Smallest/average/largest dead records: 0/0/0
   Number of free records: 1126
   Smallest/average/largest free records: 12/15312/14681136
   Number of hash chains: 100000
   Smallest/average/largest hash chains: 0/1/8
   Number of uncoalesced records: 0
   Smallest/average/largest uncoalesced runs: 0/0/0
   Percentage keys/data/padding/free/dead/rechdrs&tailers/hashes: 1/72/19/5/0/1/0

=item $octets = $tdb->freelist_size

Returns the total number of free (unused) octets in the file.

=item $tdb->printfreelist

Dump the freelist to STDOUT.

=item $num_entries = $tdb->validate_freelist [CROAK]

Verifies consistency of freelist and return the number of entries. This
loads the whole freelist into memory, using an in-memory tdb database,
which did strike Jeremy as extremely clever.

=item $func = TDB_FileX::register_hash_function $callback->($key)

Registers a custom hash function. The callback should take a key and
return a 32 bit integer hash of it.

Returns a value that is suitable to be used as the name of a hash function
(C<hash> argument to C<open>).

A maximum of four custom hash functions cna be registered.

=item TDB_FileX::unrregister_hash_function ($func)

Frees the hash function registered by a previous call to
C<register_hash_function>. Note that you I<MUST NOT> unregister a function
that is still in use.

=back

=head2 EXPORTS

Nothing constants are exported by default.

The tag C<:all> exports allpo of the constants.

Individually or with the tag C<:flags>:

  DEFAULT
  CLEAR_IF_FIRST
  INTERNAL
  NOLOCK
  NOMMAP
  CONVERT
  BIGENDIAN
  NOSYNC
  SEQNUM
  VOLATILE
  ALLOW_NESTING
  DISALLOW_NESTING
  INCOMPATIBLE_HASH
  MUTEX_LOCKING

Individually or with the tag C<:insert>:

  REPLACE
  INSERT
  MODIFY

Individually or with the tag C<:error>:

  SUCCESS
  ERR_CORRUPT
  ERR_IO
  ERR_LOCK
  ERR_OOM
  ERR_EXISTS
  ERR_NOLOCK
  ERR_LOCK_TIMEOUT
  ERR_NOEXIST
  ERR_EINVAL
  ERR_RDONLY

Individually or with the tag C<:debug>:

  DEBUG_FATAL
  DEBUG_ERROR
  DEBUG_WARNING
  DEBUG_TRACE

=head1 UNICODE HANDLING

TDB databases can only store octet strings. Unlike most other database
interfaces, TDB_FileX will safely handle Perl strings by downgrading
them. Perl will warn about strings that cnanot be downgraded.

=head1 DISK USAGE

TDB databses use 24 octets for every key-value pair, plus the octet size
of the key and sata, e.g. the pair "key" => "value" takes up 24+3+5 octets
on disk.

The database header is 168 octets (if I haven't miscounted).

Each hashtable entry is 4 octets, and one more than the hash size is
allocated, so the hash table size is (hash_size + 1) * 4.

=head1 LIMITATIONS

=head2 Database Size

As far as I can see, TDB databases are limited to 4 GB.

=head2 Hash Functions

Hash functioons need to be set globally - they are limited to a maximum of
4, but this can be easily extended, but requires source code editing. This
is due to a limitation of the TDB C API.

=head2 No recovery after failed C<reopoen_all>

There is no way to survive an error during C<reopen_all>.
Unfortunately this is a limitation in the TDB C API.

=head2 No way to resize hash table

Performance degrades majorly when the databse grows larger then
accomodated by the hash table size, and the hash table size needs to be
set at database creation time and cannot be resized later.

=head1 SEE ALSO

tdb(3), L<perltie>.

=head1 AUTHOR

Angus Lees, E<lt>gus@inodes.org>

Currently maintained by Marc A. Lehmann <schmorp@schmorp.de>
http://home.schmorp.de/

=cut
