package RocksDB;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.05";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;
__END__

=head1 NAME

RocksDB - Perl extension for RocksDB

=head1 SYNOPSIS

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

=head1 DESCRIPTION

B<RocksDB> is a Perl extension for RocksDB.

RocksDB is an embeddable persistent key-value store for fast storage.

See L<http://rocksdb.org/> for more details.

=head1 INSTALLATION

This distribution bundles the rocksdb source tree, so you don't need to have rocksdb.

If rocksdb already installed, the installer figures out it.

rocksdb depends on some environment. See vendor/rocksdb/INSTALL.md before installation.

Currently rocksdb supports Linux and OS X only.

=head1 CONSTRUCTOR

=head2 C<< RocksDB->new($name :Str[, $options :HashRef]) :RocksDB >>

Open the database with the specified $name and returns a new RocksDB object.

=head2 C<< RocksDB->open($name :Str[, $options :HashRef]) :RocksDB >>

Alias for C<new>.

=head1 METHODS

=head2 C<< $db->get($key :Str[, $read_options :HashRef]) :Maybe[Str] >>

If the database contains an entry for $key returns the corresponding value.
If there is no entry for $key returns undef.

=head2 C<< $db->get_multi(@keys :(Str) [, $read_options :HashRef]) :HashRef >>

Retrieve several values associated with @keys. @keys should be an array of scalars.

Returns reference to hash, where $href->{$key} holds corresponding value.

=head2 C<< $db->put($key :Str, $value :Str[, $write_options :HashRef]) :Undef >>

Set the database entry for $key to $value.

=head2 C<< $db->put_multi($key_values :HashRef [, $write_options :HashRef]) :Undef >>

Set the database entry for $key_values.

=head2 C<< $db->delete($key :Str[, $write_options :HashRef]) :Undef >>

Remove the database entry (if any) for $key.

=head2 C<< $db->remove($key :Str[, $write_options :HashRef]) :Undef >>

Alias for C<remove>.

=head2 C<< $db->exists($key :Str) :Bool >>

Return true if the $key is present, false otherwise.

=head2 C<< $db->key_may_exist($key :Str[, $value_ref :ScalarRef, $read_options :HashRef]) :Bool >>

If the key definitely does not exist in the database, then this method
returns false, else true. If the caller wants to obtain value when the key
is found in memory, a ScalarRef for $value_ref must be passed.
This check is potentially lighter-weight than invoking $db->get(). One way
to make this lighter weight is to avoid doing any IOs.
Default implementation here returns true and not set $value.

=head2 C<< $db->merge($key :Str, $value :Str[, $write_options :HashRef]) :Undef >>

Merge the database entry for $key with $value.
The semantics of this operation is determined by the user provided merge_operator when opening DB.

=head2 C<< $db->write($batch :RocksDB::WriteBatch[, $write_options :HashRef]) :Undef >>

Apply the specified updates to the database.

=head2 C<< $db->update($callback :CodeRef[, $write_options :HashRef]) :Undef >>

Call $db->write by callback style.

  $db->update(sub {
      my $batch = shift;
  }); # apply $batch

=head2 C<< $db->new_iterator([$read_options :HashRef]) :RocksDB::Iterator >>

Return a L<RocksDB::Iterator> over the contents of the database.
The result of $db->new_iterator() is initially invalid (caller must
call one of the seek methods on the iterator before using it).

=head2 C<< $db->get_snapshot() :RocksDB::Snapshot >>

Return a handle to the current DB state.  Iterators created with
this handle will all observe a stable snapshot of the current DB
state.

=head2 C<< $db->get_approximate_size($from :Str, $to :Str) :Int >>

Return the approximate file system space used by keys in "$from .. $to".

Note that the returned sizes measure file system space usage, so
if the user data compresses by a factor of ten, the returned
sizes will be one-tenth the size of the corresponding user data size.

The results may not include the sizes of recently written data.

=head2 C<< $db->get_property($property :Str) :Str >>

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

=head2 C<< $db->compact_range($begin :Maybe[Str], $end :Maybe[Str] [, $compact_options :HashRef]) :Undef >>

Compact the underlying storage for the key range [begin,end].
In particular, deleted and overwritten versions are discarded,
and the data is rearranged to reduce the cost of operations
needed to access the data.  This operation should typically only
be invoked by users who understand the underlying implementation.

begin == undef is treated as a key before all keys in the database.
end == undef is treated as a key after all keys in the database.
Therefore the following call will compact the entire database:

   $db->compact_range;

$compact_options might be:

=over

=item reduce_level :Bool

Defaults to true.

=item target_level :Int

Defaults to -1.

=back

=head2 C<< $db->number_levels() :Int >>

Number of levels used for this DB.

=head2 C<< $db->max_mem_compaction_level() :Int >>

Maximum level to which a new compacted memtable is pushed if it
does not create overlap.

=head2 C<< $db->level0_stop_write_trigger() :Int >>

Number of files in level-0 that would stop writes.

=head2 C<< $db->get_name() :Str >>

Get DB name -- the exact same name that was provided as an argument to
RocksDB->new()

=head2 C<< $db->flush([$flush_options :HashRef]) :Undef >>

Flush all mem-table data.

=head2 C<< $db->disable_file_deletions() :Undef >>

Prevent file deletions. Compactions will continue to occur,
but no obsolete files will be deleted. Calling this multiple
times have the same effect as calling it once.

=head2 C<< $db->enable_file_deletions() :Undef >>

Allow compactions to delete obselete files.

=head2 C<< $db->get_sorted_wal_files() :(HashRef, ...) >>

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

=head2 C<< $db->get_latest_sequence_number() :Int >>

The sequence number of the most recent transaction.

=head2 C<< $db->get_updates_since($seq_number :Int) :RocksDB::TransactionLogIterator >>

Sets iter to an iterator that is positioned at a write-batch containing
seq_number. If the sequence number is non existent, it returns an iterator
at the first available seq_no after the requested seq_no.
Must set WAL_ttl_seconds or WAL_size_limit_MB to large values to
use this api, else the WAL files will get
cleared aggressively and the iterator might keep getting invalid before
an update is read.

=head2 C<< $db->delete_file($name :Str) :Undef >>

Delete the file name from the db directory and update the internal state to
reflect that. Supports deletion of sst and log files only. 'name' must be
path relative to the db directory. eg. 000001.sst, /archive/000003.log

=head2 C<< $db->get_live_files_meta_data() :(HashRef, ...) >>

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

=head2 C<< $db->get_statistics() :RocksDB::Statistics >>

Returns a L<RocksDB::Statistics> object.

It's necessary to specify the 'enable_statistics' option
when openning the DB.

=head2 C<< $db->get_db_identity() :Str >>

Returns the globally unique ID created at database creation time.

=head2 C<< RocksDB->destroy_db($name :Str) :Undef >>

Destroy the contents of the specified database.
Be very careful using this method.

=head2 C<< RocksDB->repair_db($name :Str) :Undef >>

If a DB cannot be opened, you may attempt to call this method to
resurrect as much of the contents of the database as possible.
Some data may be lost, so be careful when calling this function
on a database that contains important information.

=head2 C<< RocksDB->major_version() :Int >>

Returns the major version of rocksdb.

=head2 C<< RocksDB->minor_version() :Int >>

Returns the minor version of rocksdb.

=head1 OPTIONS

The following options are supported.

For details, see the documentation for RocksDB itself.

=head2 Open options

=over 4

=item IncreaseParallelism :Undef

Call DBOptions.IncreaseParallelism(). Value will be ignored.

=item PrepareForBulkLoad :Undef

Call Options.PrepareForBulkLoad(). Value will be ignored.

=item OptimizeForPointLookup :Int

Call ColumnFamilyOptions.OptimizeForPointLookup() with given value.

=item OptimizeLevelStyleCompaction :Maybe[Int]

Call ColumnFamilyOptions.OptimizeLevelStyleCompaction() with given value.

=item OptimizeUniversalStyleCompaction :Maybe[Int]

Call ColumnFamilyOptions.OptimizeUniversalStyleCompaction() with given value.

=item read_only :Bool

Defaults to false. If true, call rocksdb::DB::OpenForReadOnly().

=item comparator :RocksDB::Comparator

Defaults to undef. See L<RocksDB::Comparator>.

=item merge_operator :RocksDB::MergeOperator

Defaults to undef. See L<RocksDB::MergeOperator>, L<RocksDB::AssociativeMergeOperator>.

=item compaction_filter :RocksDB::CompactionFilter

Defaults to undef. See L<RocksDB::CompactionFilter>.

=item create_if_missing :Bool

Defaults to false.

=item error_if_exists :Bool

Defaults to false.

=item paranoid_checks :Bool

Defaults to false.

=item write_buffer_size :Int

Defaults to 4MB.

=item max_write_buffer_number :Int

Defaults to 2.

=item min_write_buffer_number_to_merge :Int

Defaults to 1.

=item max_open_files :Int

Defaults to 1000.

=item max_total_wal_size :Int

Defaults to 0.

=item compression :Str

Defaults to 'snappy'. It can be specified using the following arguments.

  snappy
  zlib
  bzip2
  lz4
  lz4hc
  none

=item compression_per_level :ArrayRef[Str]

  ['snappy', 'zlib', 'zlib', 'bzip2', 'lz4', 'lz4hc' ...]

=item prefix_extractor :RocksDB::SliceTransform

Defaults to undef. See L<RocksDB::SliceTransform>, L<RocksDB::FixedPrefixTransform>.

=item num_levels :Int

Defaults to 7.

=item level0_file_num_compaction_trigger :Int

Defaults to 4.

=item level0_slowdown_writes_trigger :Int

Defaults to 8.

=item level0_stop_writes_trigger :Int

Defaults to 12.

=item max_mem_compaction_level :Int

Defaults to 2.

=item target_file_size_base :Int

Defaults to 2MB.

=item target_file_size_multiplier :Int

Defaults to 1.

=item max_bytes_for_level_base :Int

Defaults to 10MB.

=item max_bytes_for_level_multiplier :Int

Defaults to 10.

=item max_bytes_for_level_multiplier_additional :ArrayRef[Int]

Defaults to 1.

=item max_compaction_bytes: Int

Defaults to target_file_size_base * 25.

=item enable_statistics :Bool

Defaults to false. See L<RocksDB::Statistics>.

=item use_fsync :Bool

Defaults to false.

=item db_log_dir :Str

Defaults to "".

=item wal_dir :Str

Defaults to "".

=item delete_obsolete_files_period_micros :Int

Defaults to 21600000000 (6 hours).

=item max_background_compactions :Int

Defaults to 1.

=item max_background_flushes :Int

Defaults to 1.

=item max_log_file_size :Int

Defaults to 0.

=item log_file_time_to_roll :Int

Defaults to 0 (disabled).

=item keep_log_file_num :Int

Defaults to 1000.

=item soft_rate_limit :Num

Defaults to  0 (disabled).

=item hard_rate_limit :Num

Defaults to 0 (disabled).

=item rate_limit_delay_max_milliseconds :Int

Defaults to 1000.

=item max_manifest_file_size :Int

Defaults to MAX_INT.

=item table_cache_numshardbits :Int

Defaults to 4.

=item arena_block_size :Int

Defaults to 0.

=item disable_auto_compactions :Bool

Defaults to false.

=item WAL_ttl_seconds :Int

Defaults to 0.

=item WAL_size_limit_MB :Int

Defaults to 0.

=item manifest_preallocation_size :Int

Defaults to 4MB.

=item purge_redundant_kvs_while_flush :Bool

Defaults to true.

=item allow_mmap_reads :Bool

Defaults to false.

=item allow_mmap_writes :Bool

Defaults to true.

=item is_fd_close_on_exec :Bool

Defaults to true.

=item skip_log_error_on_recovery :Bool

Defaults to false.

=item stats_dump_period_sec :Int

Defaults to 3600 (1 hour).

=item advise_random_on_open :Bool

Defaults to true.

=item access_hint_on_compaction_start :Str

Defaults to 'normal'. It can be specified using the following arguments.

  normal
  none
  sequential
  willneed

=item use_adaptive_mutex :Bool

Defaults to false.

=item bytes_per_sync :Int

Defaults to 0.

=item compaction_style :Str

Defaults to 'level'. It can be specified using the following arguments.

  level
  universal
  fifo

=item compaction_options_universal :HashRef

See 'Universal compaction options' section below.

=item compaction_options_fifo :HashRef

See 'FIFO compaction options' section below.

=item max_sequential_skip_in_iterations :Int

Defaults to 8.

=item inplace_update_support :Bool

Defaults to false.

=item inplace_update_num_locks :Int

Defaults to 10000, if inplace_update_support = true, else 0.

=item memtable_prefix_bloom_size_ratio :Int

Defaults to 0 (disable).

=item bloom_locality :Int

Defaults to 0.

=item max_successive_merges :Int

Defaults to 0 (disabled).

=item block_based_table_options :HashRef

See 'Block-based table options' section below.

=item plain_table_options :HashRef

See 'Plain table options' section below.

=item cuckoo_table_options :HashRef

See 'Cuckoo table options' section below.

=back

=head2 Block-based table options

=over 4

=item cache_index_and_filter_blocks :Bool

Defaults to false.

=item index_type :Str

Defaults to 'binary_search'. It can be specified using the following arguments.

  binary_search
  hash_search

=item hash_index_allow_collision :Bool

Defaults to true.

=item checksum :Str

Defaults to 'crc32c'. It can be specified using the following arguments.

  no_checksum
  crc32c
  xxhash

=item block_cache :RocksDB::Cache

Defaults to undef. See L<RocksDB::Cache>, L<RocksDB::LRUCache>.

=item block_cache_compressed :RocksDB::Cache

Defaults to undef. See L<RocksDB::Cache>, L<RocksDB::LRUCache>.

=item block_size :Int

Defaults to 4K.

=item block_restart_interval :Int

Defaults to 16.

=item filter_policy :RocksDB::FilterPolicy

Defaults to undef. See L<RocksDB::FilterPolicy>, L<RocksDB::BloomFilterPolicy>.

=item whole_key_filtering :Bool

Defaults to true.

=item no_block_cache :Bool

Defaults to false.

=item block_size_deviation :Int

Defaults to 10.

=back

=head2 Plain table options

=over 4

=item user_key_len :Int

Defaults to 0 (variable length).

=item bloom_bits_per_key :Int

Defaults to 10.

=item hash_table_ratio :Num

Defaults to 0.75.

=item index_sparseness :Int

Defaults to 16.

=item huge_page_tlb_size :Int

Defaults to 0.

=item encoding_type :Str

Defaults to 'plain'. It can be specified using the following arguments.

  plain
  prefix

=item full_scan_mode :Bool

Defaults to false.

=item store_index_in_file :Bool

Defaults to false.

=back

=head2 Cuckoo table options

=over 4

=item hash_table_ratio :Num

Defaults to 0.9.

=item max_search_depth :Int

Defaults to 100.

=item cuckoo_block_size :Int

Defaults to 5.

=item identity_as_first_hash :Bool

Defaults to false.

=item use_module_hash :Bool

Defaults to true.

=back

=head2 Universal compaction options

=over 4

=item size_ratio :Int

Defaults to 1.

=item min_merge_width :Int

Defaults to 2.

=item max_merge_width :Int

Defaults to UINT_MAX.

=item max_size_amplification_percent :Int

Defaults to 200.

=item compression_size_percent :Int

Defaults to -1.

=item stop_style :Str

Defaults to 'total_size'. It can be specified using the following arguments.

  total_size
  similar_size

=back

=head2 FIFO compaction options

=over 4

=item max_table_files_size :Int

Defaults to 1GB.

=back

=head2 Read options

=over 4

=item verify_checksums :Bool

Defaults to true.

=item fill_cache :Bool

Defaults to true.

=item snapshot :RocksDB::Snapshot

Defaults to undef.  See L<RocksDB::Snapshot>.

=item read_tier :Str

Defaults to 'read_all'. It can be specified using the following arguments.

  read_all
  block_cache

=item tailing :Bool

Defaults to false.

=item total_order_seek :Bool

Defaults to false.

=back

=head2 Write options

=over 4

=item sync :Bool

Defaults to false.

=item disableWAL :Bool

Defaults to false.

=back

=head2 Flush options

=over 4

=item wait :Bool

Defaults to true.

=back

=head1 SEE ALSO

L<http://rocksdb.org/>

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

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

=cut
