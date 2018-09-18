use strict;
use warnings;

use Test::More;
use RocksDB;
use File::Temp;
use POSIX ();

{
    package MyComparator;
    sub new { bless {}, shift }
    sub compare {
        my ($self, $A, $B) = @_;
        $A cmp $B;
    }
    package MyMergeOperator;
    sub new { bless {}, shift }
    package MyCompactionFilter;
    sub new { bless {}, shift }
}

my $name = File::Temp::tmpnam;
my $db = RocksDB->new($name, {
    read_only                                 => 0,
    comparator                                => RocksDB::Comparator->new(MyComparator->new),
    merge_operator                            => RocksDB::MergeOperator->new(MyMergeOperator->new),
    compaction_filter                         => RocksDB::CompactionFilter->new(MyCompactionFilter->new),
    create_if_missing                         => 1,
    error_if_exists                           => 0,
    paranoid_checks                           => 0,
    write_buffer_size                         => 4 * 1024 * 1024,
    max_write_buffer_number                   => 2,
    min_write_buffer_number_to_merge          => 1,
    max_open_files                            => 1000,
    max_total_wal_size                        => 0,
    compression                               => 'zlib',
    compression_per_level                     => ['zlib', 'bzip2'],
    filter_policy                             => RocksDB::BloomFilterPolicy->new(10),
    prefix_extractor                          => RocksDB::FixedPrefixTransform->new(8),
    num_levels                                => 7,
    level0_file_num_compaction_trigger        => 4,
    level0_slowdown_writes_trigger            => 8,
    level0_stop_writes_trigger                => 12,
    max_mem_compaction_level                  => 2,
    target_file_size_base                     => 2 * 1024 * 1024,
    target_file_size_multiplier               => 1,
    max_bytes_for_level_base                  => 10 * 1024 * 1024,
    max_bytes_for_level_multiplier            => 10,
    max_bytes_for_level_multiplier_additional => [1],
    max_compaction_bytes                      => 1677721600,
    enable_statistics                         => 0,
    use_fsync                                 => 0,
    db_log_dir                                => '',
    wal_dir                                   => '',
    delete_obsolete_files_period_micros       => 21600000000,
    max_background_compactions                => 1,
    max_background_flushes                    => 0,
    max_log_file_size                         => 0,
    log_file_time_to_roll                     => 0,
    keep_log_file_num                         => 1000,
    soft_rate_limit                           => 0,
    hard_rate_limit                           => 0,
    rate_limit_delay_max_milliseconds         => 1000,
    max_manifest_file_size                    => POSIX::INT_MAX,
    table_cache_numshardbits                  => 4,
    arena_block_size                          => 0,
    disable_auto_compactions                  => 0,
    WAL_ttl_seconds                           => 0,
    WAL_size_limit_MB                         => 0,
    manifest_preallocation_size               => 4 * 1024 * 1024,
    purge_redundant_kvs_while_flush           => 1,
    allow_mmap_reads                          => 0,
    allow_mmap_writes                         => 1,
    is_fd_close_on_exec                       => 1,
    skip_log_error_on_recovery                => 0,
    stats_dump_period_sec                     => 3600,
    advise_random_on_open                     => 1,
    access_hint_on_compaction_start           => 'normal',
    use_adaptive_mutex                        => 0,
    bytes_per_sync                            => 0,
    compaction_style                          => 'universal',
    compaction_options_universal              => {
        size_ratio                     => 1,
        min_merge_width                => 2,
        max_merge_width                => POSIX::UINT_MAX,
        max_size_amplification_percent => 200,
        compression_size_percent       => -1,
        stop_style                     => 'total_size',
    },
    max_sequential_skip_in_iterations         => 8,
    inplace_update_support                    => 0,
    inplace_update_num_locks                  => 10000,
    memtable_prefix_bloom_size_ratio          => 0,
    memtable_prefix_bloom_probes              => 1,
    memtable_huge_page_size                   => 0,
    bloom_locality                            => 0,
    max_successive_merges                     => 0,
    block_based_table_options                 => {
        cache_index_and_filter_blocks => 0,
        index_type                    => 'binary_search',
        hash_index_allow_collision    => 1,
        checksum                      => 'crc32c',
        block_cache                   => RocksDB::LRUCache->new(1024),
        block_cache_compressed        => RocksDB::LRUCache->new(1024),
        block_size                    => 4 * 1024,
        block_restart_interval        => 16,
        whole_key_filtering           => 1,
        no_block_cache                => 0,
        block_size_deviation          => 10,
    },
});
isa_ok $db, 'RocksDB';

$db->put('foo', 'bar', {
    sync       => 0,
    disableWAL => 0,
    tailing    => 0,
});
my $snapshot = $db->get_snapshot;
is $db->get('foo', {
    verify_checksums => 0,
    fill_cache       => 1,
    snapshot         => $snapshot,
    read_tier        => 'read_all',
    total_order_seek => 1,
}), 'bar';
$db->flush({ wait => 1 });
done_testing;

END {
    RocksDB->destroy_db($name);
}
