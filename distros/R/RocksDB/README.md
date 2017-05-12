# NAME

RocksDB - Perl extension for RocksDB

# SYNOPSIS

    use RocksDB;

    my $db = RocksDB->new('/path/to/db', { create_if_missing => 1 });
    # put, get and delete
    $db->put(foo => 'bar');
    my $val = $db->get('foo');
    $db->delete('foo');

    # batch
    $db->update(sub {
        my $batch = shift; # RocksDB::WriteBatch object
        $batch->put(foo => 'bar');
        $batch->delete('bar');
    });
    # or manually
    my $batch = RocksDB::WriteBatch->new;
    $batch->put(foo => 'bar');
    $batch->delete('bar');
    $db->write($batch);

    # iteration
    my $iter = $db->new_iterator->seek_to_first;
    while (my ($key, $value) = $iter->each) {
        printf "%s: %s\n", $key, $value;
    }

    # in reverse order
    $iter->seek_to_last;
    while (my ($key, $value) = $iter->reverse_each) {
        printf "%s: %s\n", $key, $value;
    }

    # The tie interface
    tie my %db, 'RocksDB', '/path/to/db', { create_if_missing => 1 };

# DESCRIPTION

__RocksDB__ is a Perl extension for RocksDB.

RocksDB is an embeddable persistent key-value store for fast storage.

See [http://rocksdb.org/](http://rocksdb.org/) for more details.

# INSTALLATION

This distribution bundles the rocksdb source tree, so you don't need to have rocksdb.

If rocksdb already installed, the installer figures out it.

rocksdb depends on some environment. See vendor/rocksdb/INSTALL.md before installation.

Currently rocksdb supports Linux and OS X only.

# CONSTRUCTOR

## `RocksDB->new($name :Str[, $options :HashRef]) :RocksDB`

Open the database with the specified $name and returns a new RocksDB object.

## `RocksDB->open($name :Str[, $options :HashRef]) :RocksDB`

Alias for `new`.

# METHODS

## `$db->get($key :Str[, $read_options :HashRef]) :Maybe[Str]`

If the database contains an entry for $key returns the corresponding value.
If there is no entry for $key returns undef.

## `$db->get_multi(@keys :(Str) [, $read_options :HashRef]) :HashRef`

Retrieve several values associated with @keys. @keys should be an array of scalars.

Returns reference to hash, where $href->{$key} holds corresponding value.

## `$db->put($key :Str, $value :Str[, $write_options :HashRef]) :Undef`

Set the database entry for $key to $value.

## `$db->put_multi($key_values :HashRef [, $write_options :HashRef]) :Undef`

Set the database entry for $key\_values.

## `$db->delete($key :Str[, $write_options :HashRef]) :Undef`

Remove the database entry (if any) for $key.

## `$db->remove($key :Str[, $write_options :HashRef]) :Undef`

Alias for `remove`.

## `$db->exists($key :Str) :Bool`

Return true if the $key is present, false otherwise.

## `$db->key_may_exist($key :Str[, $value_ref :ScalarRef, $read_options :HashRef]) :Bool`

If the key definitely does not exist in the database, then this method
returns false, else true. If the caller wants to obtain value when the key
is found in memory, a ScalarRef for $value\_ref must be passed.
This check is potentially lighter-weight than invoking $db->get(). One way
to make this lighter weight is to avoid doing any IOs.
Default implementation here returns true and not set $value.

## `$db->merge($key :Str, $value :Str[, $write_options :HashRef]) :Undef`

Merge the database entry for $key with $value.
The semantics of this operation is determined by the user provided merge\_operator when opening DB.

## `$db->write($batch :RocksDB::WriteBatch[, $write_options :HashRef]) :Undef`

Apply the specified updates to the database.

## `$db->update($callback :CodeRef[, $write_options :HashRef]) :Undef`

Call $db->write by callback style.

    $db->update(sub {
        my $batch = shift;
    }); # apply $batch

## `$db->new_iterator([$read_options :HashRef]) :RocksDB::Iterator`

Return a [RocksDB::Iterator](https://metacpan.org/pod/RocksDB::Iterator) over the contents of the database.
The result of $db->new\_iterator() is initially invalid (caller must
call one of the seek methods on the iterator before using it).

## `$db->get_snapshot() :RocksDB::Snapshot`

Return a handle to the current DB state.  Iterators created with
this handle will all observe a stable snapshot of the current DB
state.

## `$db->get_approximate_size($from :Str, $to :Str) :Int`

Return the approximate file system space used by keys in "$from .. $to".

Note that the returned sizes measure file system space usage, so
if the user data compresses by a factor of ten, the returned
sizes will be one-tenth the size of the corresponding user data size.

The results may not include the sizes of recently written data.

## `$db->get_property($property :Str) :Str`

DB implementations can export properties about their state
via this method.  If $property is a valid property understood by this
DB implementation, returns its current value. Otherwise returns undef.

Valid property names include:

    "rocksdb.num-files-at-level<N>" - return the number of files at level <N>,
       where <N> is an ASCII representation of a level number (e.g. "0").
    "rocksdb.stats" - returns a multi-line string that describes statistics
       about the internal operation of the DB.
    "rocksdb.sstables" - returns a multi-line string that describes all
       of the sstables that make up the db contents.

## `$db->compact_range($begin :Maybe[Str], $end :Maybe[Str] [, $compact_options :HashRef]) :Undef`

Compact the underlying storage for the key range \[begin,end\].
In particular, deleted and overwritten versions are discarded,
and the data is rearranged to reduce the cost of operations
needed to access the data.  This operation should typically only
be invoked by users who understand the underlying implementation.

begin == undef is treated as a key before all keys in the database.
end == undef is treated as a key after all keys in the database.
Therefore the following call will compact the entire database:

    $db->compact_range;

$compact\_options might be:

- reduce\_level :Bool

    Defaults to true.

- target\_level :Int

    Defaults to -1.

## `$db->number_levels() :Int`

Number of levels used for this DB.

## `$db->max_mem_compaction_level() :Int`

Maximum level to which a new compacted memtable is pushed if it
does not create overlap.

## `$db->level0_stop_write_trigger() :Int`

Number of files in level-0 that would stop writes.

## `$db->get_name() :Str`

Get DB name -- the exact same name that was provided as an argument to
RocksDB->new()

## `$db->flush([$flush_options :HashRef]) :Undef`

Flush all mem-table data.

## `$db->disable_file_deletions() :Undef`

Prevent file deletions. Compactions will continue to occur,
but no obsolete files will be deleted. Calling this multiple
times have the same effect as calling it once.

## `$db->enable_file_deletions() :Undef`

Allow compactions to delete obselete files.

## `$db->get_sorted_wal_files() :(HashRef, ...)`

Retrieve the sorted list of all wal files with earliest file first.

    (
      {
        # log file's pathname relative to the main db dir
        'path_name' => '/000003.log',
        # Primary identifier for log file.
        # This is directly proportional to creation time of the log file
        'log_number' => 157,
        # Log file can be either alive or archived
        'type' => 'alive', # or 'archived'
        # Starting sequence number of writebatch written in this log file
        'start_sequence' => 85,
        # Size of log file on disk in Bytes
        'size_file_bytes' => 28,
      },
      ...
    )

## `$db->get_latest_sequence_number() :Int`

The sequence number of the most recent transaction.

## `$db->get_updates_since($seq_number :Int) :RocksDB::TransactionLogIterator`

Sets iter to an iterator that is positioned at a write-batch containing
seq\_number. If the sequence number is non existent, it returns an iterator
at the first available seq\_no after the requested seq\_no.
Must set WAL\_ttl\_seconds or WAL\_size\_limit\_MB to large values to
use this api, else the WAL files will get
cleared aggressively and the iterator might keep getting invalid before
an update is read.

## `$db->delete_file($name :Str) :Undef`

Delete the file name from the db directory and update the internal state to
reflect that. Supports deletion of sst and log files only. 'name' must be
path relative to the db directory. eg. 000001.sst, /archive/000003.log

## `$db->get_live_files_meta_data() :(HashRef, ...)`

Returns a list of all table files with their level, start key and end key.

    (
      {
        # Name of the file
        'name' => '/000140.sst',
        # Level at which this file resides.
        'level' => 1
        # File size in bytes.
        'size' => 339,
        # Smallest user defined key in the file.
        'smallestkey' => 'bar',
        # Largest user defined key in the file.
        'largestkey' => 'foo',
        # smallest seqno in file
        'smallest_seqno' => '0',
        # largest seqno in file
        'largest_seqno' => '0',
      },
      ...
    )

## `$db->get_statistics() :RocksDB::Statistics`

Returns a [RocksDB::Statistics](https://metacpan.org/pod/RocksDB::Statistics) object.

It's necessary to specify the 'enable\_statistics' option
when openning the DB.

## `$db->get_db_identity() :Str`

Returns the globally unique ID created at database creation time.

## `RocksDB->destroy_db($name :Str) :Undef`

Destroy the contents of the specified database.
Be very careful using this method.

## `RocksDB->repair_db($name :Str) :Undef`

If a DB cannot be opened, you may attempt to call this method to
resurrect as much of the contents of the database as possible.
Some data may be lost, so be careful when calling this function
on a database that contains important information.

## `RocksDB->major_version() :Int`

Returns the major version of rocksdb.

## `RocksDB->minor_version() :Int`

Returns the minor version of rocksdb.

# OPTIONS

The following options are supported.

For details, see the documentation for RocksDB itself.

## Open options

- IncreaseParallelism :Undef

    Call DBOptions.IncreaseParallelism(). Value will be ignored.

- PrepareForBulkLoad :Undef

    Call Options.PrepareForBulkLoad(). Value will be ignored.

- OptimizeForPointLookup :Int

    Call ColumnFamilyOptions.OptimizeForPointLookup() with given value.

- OptimizeLevelStyleCompaction :Maybe\[Int\]

    Call ColumnFamilyOptions.OptimizeLevelStyleCompaction() with given value.

- OptimizeUniversalStyleCompaction :Maybe\[Int\]

    Call ColumnFamilyOptions.OptimizeUniversalStyleCompaction() with given value.

- read\_only :Bool

    Defaults to false. If true, call rocksdb::DB::OpenForReadOnly().

- comparator :RocksDB::Comparator

    Defaults to undef. See [RocksDB::Comparator](https://metacpan.org/pod/RocksDB::Comparator).

- merge\_operator :RocksDB::MergeOperator

    Defaults to undef. See [RocksDB::MergeOperator](https://metacpan.org/pod/RocksDB::MergeOperator), [RocksDB::AssociativeMergeOperator](https://metacpan.org/pod/RocksDB::AssociativeMergeOperator).

- compaction\_filter :RocksDB::CompactionFilter

    Defaults to undef. See [RocksDB::CompactionFilter](https://metacpan.org/pod/RocksDB::CompactionFilter).

- create\_if\_missing :Bool

    Defaults to false.

- error\_if\_exists :Bool

    Defaults to false.

- paranoid\_checks :Bool

    Defaults to false.

- write\_buffer\_size :Int

    Defaults to 4MB.

- max\_write\_buffer\_number :Int

    Defaults to 2.

- min\_write\_buffer\_number\_to\_merge :Int

    Defaults to 1.

- max\_open\_files :Int

    Defaults to 1000.

- max\_total\_wal\_size :Int

    Defaults to 0.

- compression :Str

    Defaults to 'snappy'. It can be specified using the following arguments.

        snappy
        zlib
        bzip2
        lz4
        lz4hc
        none

- compression\_per\_level :ArrayRef\[Str\]

        ['snappy', 'zlib', 'zlib', 'bzip2', 'lz4', 'lz4hc' ...]
- prefix\_extractor :RocksDB::SliceTransform

    Defaults to undef. See [RocksDB::SliceTransform](https://metacpan.org/pod/RocksDB::SliceTransform), [RocksDB::FixedPrefixTransform](https://metacpan.org/pod/RocksDB::FixedPrefixTransform).

- num\_levels :Int

    Defaults to 7.

- level0\_file\_num\_compaction\_trigger :Int

    Defaults to 4.

- level0\_slowdown\_writes\_trigger :Int

    Defaults to 8.

- level0\_stop\_writes\_trigger :Int

    Defaults to 12.

- max\_mem\_compaction\_level :Int

    Defaults to 2.

- target\_file\_size\_base :Int

    Defaults to 2MB.

- target\_file\_size\_multiplier :Int

    Defaults to 1.

- max\_bytes\_for\_level\_base :Int

    Defaults to 10MB.

- max\_bytes\_for\_level\_multiplier :Int

    Defaults to 10.

- max\_bytes\_for\_level\_multiplier\_additional :ArrayRef\[Int\]

    Defaults to 1.

- expanded\_compaction\_factor :Int

    Defaults to 25.

- source\_compaction\_factor :Int

    Defaults to 1.

- max\_grandparent\_overlap\_factor :Int

    Defaults to 10.

- enable\_statistics :Bool

    Defaults to false. See [RocksDB::Statistics](https://metacpan.org/pod/RocksDB::Statistics).

- disableDataSync :Bool

    Defaults to false.

- use\_fsync :Bool

    Defaults to false.

- db\_log\_dir :Str

    Defaults to "".

- wal\_dir :Str

    Defaults to "".

- delete\_obsolete\_files\_period\_micros :Int

    Defaults to 21600000000 (6 hours).

- max\_background\_compactions :Int

    Defaults to 1.

- max\_background\_flushes :Int

    Defaults to 1.

- max\_log\_file\_size :Int

    Defaults to 0.

- log\_file\_time\_to\_roll :Int

    Defaults to 0 (disabled).

- keep\_log\_file\_num :Int

    Defaults to 1000.

- soft\_rate\_limit :Num

    Defaults to  0 (disabled).

- hard\_rate\_limit :Num

    Defaults to 0 (disabled).

- rate\_limit\_delay\_max\_milliseconds :Int

    Defaults to 1000.

- max\_manifest\_file\_size :Int

    Defaults to MAX\_INT.

- table\_cache\_numshardbits :Int

    Defaults to 4.

- table\_cache\_remove\_scan\_count\_limit :Int

    Defaults to 16.

- arena\_block\_size :Int

    Defaults to 0.

- disable\_auto\_compactions :Bool

    Defaults to false.

- WAL\_ttl\_seconds :Int

    Defaults to 0.

- WAL\_size\_limit\_MB :Int

    Defaults to 0.

- manifest\_preallocation\_size :Int

    Defaults to 4MB.

- purge\_redundant\_kvs\_while\_flush :Bool

    Defaults to true.

- allow\_os\_buffer :Bool

    Defaults to true.

- allow\_mmap\_reads :Bool

    Defaults to false.

- allow\_mmap\_writes :Bool

    Defaults to true.

- is\_fd\_close\_on\_exec :Bool

    Defaults to true.

- skip\_log\_error\_on\_recovery :Bool

    Defaults to false.

- stats\_dump\_period\_sec :Int

    Defaults to 3600 (1 hour).

- advise\_random\_on\_open :Bool

    Defaults to true.

- access\_hint\_on\_compaction\_start :Str

    Defaults to 'normal'. It can be specified using the following arguments.

        normal
        none
        sequential
        willneed

- use\_adaptive\_mutex :Bool

    Defaults to false.

- bytes\_per\_sync :Int

    Defaults to 0.

- compaction\_style :Str

    Defaults to 'level'. It can be specified using the following arguments.

        level
        universal
        fifo

- verify\_checksums\_in\_compaction :Bool

    Defaults to true.

- compaction\_options\_universal :HashRef

    See 'Universal compaction options' section below.

- compaction\_options\_fifo :HashRef

    See 'FIFO compaction options' section below.

- filter\_deletes :Bool

    Defaults to false.

- max\_sequential\_skip\_in\_iterations :Int

    Defaults to 8.

- inplace\_update\_support :Bool

    Defaults to false.

- inplace\_update\_num\_locks :Int

    Defaults to 10000, if inplace\_update\_support = true, else 0.

- memtable\_prefix\_bloom\_bits :Int

    If prefix\_extractor is set and bloom\_bits is not 0, create prefix bloom for memtable.

- memtable\_prefix\_bloom\_probes :Int

    Number of hash probes per key.

- memtable\_prefix\_bloom\_huge\_page\_tlb\_size :Int

    Page size for huge page TLB for bloom in memtable. If <=0, not allocate from huge page TLB but from malloc.

- bloom\_locality :Int

    Defaults to 0.

- max\_successive\_merges :Int

    Defaults to 0 (disabled).

- min\_partial\_merge\_operands :Int

    Defaults to 2.

- block\_based\_table\_options :HashRef

    See 'Block-based table options' section below.

- plain\_table\_options :HashRef

    See 'Plain table options' section below.

- cuckoo\_table\_options :HashRef

    See 'Cuckoo table options' section below.

## Block-based table options

- cache\_index\_and\_filter\_blocks :Bool

    Defaults to false.

- index\_type :Str

    Defaults to 'binary\_search'. It can be specified using the following arguments.

        binary_search
        hash_search

- hash\_index\_allow\_collision :Bool

    Defaults to true.

- checksum :Str

    Defaults to 'crc32c'. It can be specified using the following arguments.

        no_checksum
        crc32c
        xxhash

- block\_cache :RocksDB::Cache

    Defaults to undef. See [RocksDB::Cache](https://metacpan.org/pod/RocksDB::Cache), [RocksDB::LRUCache](https://metacpan.org/pod/RocksDB::LRUCache).

- block\_cache\_compressed :RocksDB::Cache

    Defaults to undef. See [RocksDB::Cache](https://metacpan.org/pod/RocksDB::Cache), [RocksDB::LRUCache](https://metacpan.org/pod/RocksDB::LRUCache).

- block\_size :Int

    Defaults to 4K.

- block\_restart\_interval :Int

    Defaults to 16.

- filter\_policy :RocksDB::FilterPolicy

    Defaults to undef. See [RocksDB::FilterPolicy](https://metacpan.org/pod/RocksDB::FilterPolicy), [RocksDB::BloomFilterPolicy](https://metacpan.org/pod/RocksDB::BloomFilterPolicy).

- whole\_key\_filtering :Bool

    Defaults to true.

- no\_block\_cache :Bool

    Defaults to false.

- block\_size\_deviation :Int

    Defaults to 10.

## Plain table options

- user\_key\_len :Int

    Defaults to 0 (variable length).

- bloom\_bits\_per\_key :Int

    Defaults to 10.

- hash\_table\_ratio :Num

    Defaults to 0.75.

- index\_sparseness :Int

    Defaults to 16.

- huge\_page\_tlb\_size :Int

    Defaults to 0.

- encoding\_type :Str

    Defaults to 'plain'. It can be specified using the following arguments.

        plain
        prefix

- full\_scan\_mode :Bool

    Defaults to false.

- store\_index\_in\_file :Bool

    Defaults to false.

## Cuckoo table options

- hash\_table\_ratio :Num

    Defaults to 0.9.

- max\_search\_depth :Int

    Defaults to 100.

- cuckoo\_block\_size :Int

    Defaults to 5.

- identity\_as\_first\_hash :Bool

    Defaults to false.

- use\_module\_hash :Bool

    Defaults to true.

## Universal compaction options

- size\_ratio :Int

    Defaults to 1.

- min\_merge\_width :Int

    Defaults to 2.

- max\_merge\_width :Int

    Defaults to UINT\_MAX.

- max\_size\_amplification\_percent :Int

    Defaults to 200.

- compression\_size\_percent :Int

    Defaults to -1.

- stop\_style :Str

    Defaults to 'total\_size'. It can be specified using the following arguments.

        total_size
        similar_size

## FIFO compaction options

- max\_table\_files\_size :Int

    Defaults to 1GB.

## Read options

- verify\_checksums :Bool

    Defaults to true.

- fill\_cache :Bool

    Defaults to true.

- snapshot :RocksDB::Snapshot

    Defaults to undef.  See [RocksDB::Snapshot](https://metacpan.org/pod/RocksDB::Snapshot).

- read\_tier :Str

    Defaults to 'read\_all'. It can be specified using the following arguments.

        read_all
        block_cache

- tailing :Bool

    Defaults to false.

- total\_order\_seek :Bool

    Defaults to false.

## Write options

- sync :Bool

    Defaults to false.

- disableWAL :Bool

    Defaults to false.

- timeout\_hint\_us :Int

    Defaults to 0.

## Flush options

- wait :Bool

    Defaults to true.

# SEE ALSO

[http://rocksdb.org/](http://rocksdb.org/)

# AUTHOR

Jiro Nishiguchi <jiro@cpan.org>

# COPYRIGHT AND LICENSE

    Copyright (c) 2013, Jiro Nishiguchi All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:
    
       * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
       * Redistributions in binary form must reproduce the above
    copyright notice, this list of conditions and the following disclaimer
    in the documentation and/or other materials provided with the
    distribution.
       * Neither the name of Jiro Nishiguchi. nor the names of its
    contributors may be used to endorse or promote products derived from
    this software without specific prior written permission.
    
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
    A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
    OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
    LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
    THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
    OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

See also vendor/rocksdb/LICENSE for bundled RocksDB sources.
