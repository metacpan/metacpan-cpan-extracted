####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v11.7.0
#
#      Don't edit this file, use the source template instead
#
#                 ANY CHANGES HERE WILL BE LOST !
#
####################################################################


use v5.26;
use warnings;
use experimental 'signatures';
use Future::AsyncAwait;
use Object::Pad;

class Sys::Async::Virt::Domain v0.1.5;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.1.5;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    CHECKPOINT_CREATE_REDEFINE                                    => (1 << 0),
    CHECKPOINT_CREATE_QUIESCE                                     => (1 << 1),
    CHECKPOINT_CREATE_REDEFINE_VALIDATE                           => (1 << 2),
    SNAPSHOT_CREATE_REDEFINE                                      => (1 << 0),
    SNAPSHOT_CREATE_CURRENT                                       => (1 << 1),
    SNAPSHOT_CREATE_NO_METADATA                                   => (1 << 2),
    SNAPSHOT_CREATE_HALT                                          => (1 << 3),
    SNAPSHOT_CREATE_DISK_ONLY                                     => (1 << 4),
    SNAPSHOT_CREATE_REUSE_EXT                                     => (1 << 5),
    SNAPSHOT_CREATE_QUIESCE                                       => (1 << 6),
    SNAPSHOT_CREATE_ATOMIC                                        => (1 << 7),
    SNAPSHOT_CREATE_LIVE                                          => (1 << 8),
    SNAPSHOT_CREATE_VALIDATE                                      => (1 << 9),
    NOSTATE                                                       => 0,
    RUNNING                                                       => 1,
    BLOCKED                                                       => 2,
    PAUSED                                                        => 3,
    SHUTDOWN                                                      => 4,
    SHUTOFF                                                       => 5,
    CRASHED                                                       => 6,
    PMSUSPENDED                                                   => 7,
    NOSTATE_UNKNOWN                                               => 0,
    RUNNING_UNKNOWN                                               => 0,
    RUNNING_BOOTED                                                => 1,
    RUNNING_MIGRATED                                              => 2,
    RUNNING_RESTORED                                              => 3,
    RUNNING_FROM_SNAPSHOT                                         => 4,
    RUNNING_UNPAUSED                                              => 5,
    RUNNING_MIGRATION_CANCELED                                    => 6,
    RUNNING_SAVE_CANCELED                                         => 7,
    RUNNING_WAKEUP                                                => 8,
    RUNNING_CRASHED                                               => 9,
    RUNNING_POSTCOPY                                              => 10,
    RUNNING_POSTCOPY_FAILED                                       => 11,
    BLOCKED_UNKNOWN                                               => 0,
    PAUSED_UNKNOWN                                                => 0,
    PAUSED_USER                                                   => 1,
    PAUSED_MIGRATION                                              => 2,
    PAUSED_SAVE                                                   => 3,
    PAUSED_DUMP                                                   => 4,
    PAUSED_IOERROR                                                => 5,
    PAUSED_WATCHDOG                                               => 6,
    PAUSED_FROM_SNAPSHOT                                          => 7,
    PAUSED_SHUTTING_DOWN                                          => 8,
    PAUSED_SNAPSHOT                                               => 9,
    PAUSED_CRASHED                                                => 10,
    PAUSED_STARTING_UP                                            => 11,
    PAUSED_POSTCOPY                                               => 12,
    PAUSED_POSTCOPY_FAILED                                        => 13,
    PAUSED_API_ERROR                                              => 14,
    SHUTDOWN_UNKNOWN                                              => 0,
    SHUTDOWN_USER                                                 => 1,
    SHUTOFF_UNKNOWN                                               => 0,
    SHUTOFF_SHUTDOWN                                              => 1,
    SHUTOFF_DESTROYED                                             => 2,
    SHUTOFF_CRASHED                                               => 3,
    SHUTOFF_MIGRATED                                              => 4,
    SHUTOFF_SAVED                                                 => 5,
    SHUTOFF_FAILED                                                => 6,
    SHUTOFF_FROM_SNAPSHOT                                         => 7,
    SHUTOFF_DAEMON                                                => 8,
    CRASHED_UNKNOWN                                               => 0,
    CRASHED_PANICKED                                              => 1,
    PMSUSPENDED_UNKNOWN                                           => 0,
    PMSUSPENDED_DISK_UNKNOWN                                      => 0,
    CONTROL_OK                                                    => 0,
    CONTROL_JOB                                                   => 1,
    CONTROL_OCCUPIED                                              => 2,
    CONTROL_ERROR                                                 => 3,
    CONTROL_ERROR_REASON_NONE                                     => 0,
    CONTROL_ERROR_REASON_UNKNOWN                                  => 1,
    CONTROL_ERROR_REASON_MONITOR                                  => 2,
    CONTROL_ERROR_REASON_INTERNAL                                 => 3,
    AFFECT_CURRENT                                                => 0,
    AFFECT_LIVE                                                   => 1 << 0,
    AFFECT_CONFIG                                                 => 1 << 1,
    NONE                                                          => 0,
    START_PAUSED                                                  => 1 << 0,
    START_AUTODESTROY                                             => 1 << 1,
    START_BYPASS_CACHE                                            => 1 << 2,
    START_FORCE_BOOT                                              => 1 << 3,
    START_VALIDATE                                                => 1 << 4,
    START_RESET_NVRAM                                             => 1 << 5,
    SCHEDULER_CPU_SHARES                                          => "cpu_shares",
    SCHEDULER_GLOBAL_PERIOD                                       => "global_period",
    SCHEDULER_GLOBAL_QUOTA                                        => "global_quota",
    SCHEDULER_VCPU_PERIOD                                         => "vcpu_period",
    SCHEDULER_VCPU_QUOTA                                          => "vcpu_quota",
    SCHEDULER_EMULATOR_PERIOD                                     => "emulator_period",
    SCHEDULER_EMULATOR_QUOTA                                      => "emulator_quota",
    SCHEDULER_IOTHREAD_PERIOD                                     => "iothread_period",
    SCHEDULER_IOTHREAD_QUOTA                                      => "iothread_quota",
    SCHEDULER_WEIGHT                                              => "weight",
    SCHEDULER_CAP                                                 => "cap",
    SCHEDULER_RESERVATION                                         => "reservation",
    SCHEDULER_LIMIT                                               => "limit",
    SCHEDULER_SHARES                                              => "shares",
    BLOCK_STATS_FIELD_LENGTH                                      => 80,
    BLOCK_STATS_READ_BYTES                                        => "rd_bytes",
    BLOCK_STATS_READ_REQ                                          => "rd_operations",
    BLOCK_STATS_READ_TOTAL_TIMES                                  => "rd_total_times",
    BLOCK_STATS_WRITE_BYTES                                       => "wr_bytes",
    BLOCK_STATS_WRITE_REQ                                         => "wr_operations",
    BLOCK_STATS_WRITE_TOTAL_TIMES                                 => "wr_total_times",
    BLOCK_STATS_FLUSH_REQ                                         => "flush_operations",
    BLOCK_STATS_FLUSH_TOTAL_TIMES                                 => "flush_total_times",
    BLOCK_STATS_ERRS                                              => "errs",
    MEMORY_STAT_SWAP_IN                                           => 0,
    MEMORY_STAT_SWAP_OUT                                          => 1,
    MEMORY_STAT_MAJOR_FAULT                                       => 2,
    MEMORY_STAT_MINOR_FAULT                                       => 3,
    MEMORY_STAT_UNUSED                                            => 4,
    MEMORY_STAT_AVAILABLE                                         => 5,
    MEMORY_STAT_ACTUAL_BALLOON                                    => 6,
    MEMORY_STAT_RSS                                               => 7,
    MEMORY_STAT_USABLE                                            => 8,
    MEMORY_STAT_LAST_UPDATE                                       => 9,
    MEMORY_STAT_DISK_CACHES                                       => 10,
    MEMORY_STAT_HUGETLB_PGALLOC                                   => 11,
    MEMORY_STAT_HUGETLB_PGFAIL                                    => 12,
    MEMORY_STAT_NR                                                => 13,
    MEMORY_STAT_LAST                                              => 13,
    DUMP_CRASH                                                    => (1 << 0),
    DUMP_LIVE                                                     => (1 << 1),
    DUMP_BYPASS_CACHE                                             => (1 << 2),
    DUMP_RESET                                                    => (1 << 3),
    DUMP_MEMORY_ONLY                                              => (1 << 4),
    MIGRATE_LIVE                                                  => (1 << 0),
    MIGRATE_PEER2PEER                                             => (1 << 1),
    MIGRATE_TUNNELLED                                             => (1 << 2),
    MIGRATE_PERSIST_DEST                                          => (1 << 3),
    MIGRATE_UNDEFINE_SOURCE                                       => (1 << 4),
    MIGRATE_PAUSED                                                => (1 << 5),
    MIGRATE_NON_SHARED_DISK                                       => (1 << 6),
    MIGRATE_NON_SHARED_INC                                        => (1 << 7),
    MIGRATE_CHANGE_PROTECTION                                     => (1 << 8),
    MIGRATE_UNSAFE                                                => (1 << 9),
    MIGRATE_OFFLINE                                               => (1 << 10),
    MIGRATE_COMPRESSED                                            => (1 << 11),
    MIGRATE_ABORT_ON_ERROR                                        => (1 << 12),
    MIGRATE_AUTO_CONVERGE                                         => (1 << 13),
    MIGRATE_RDMA_PIN_ALL                                          => (1 << 14),
    MIGRATE_POSTCOPY                                              => (1 << 15),
    MIGRATE_TLS                                                   => (1 << 16),
    MIGRATE_PARALLEL                                              => (1 << 17),
    MIGRATE_NON_SHARED_SYNCHRONOUS_WRITES                         => (1 << 18),
    MIGRATE_POSTCOPY_RESUME                                       => (1 << 19),
    MIGRATE_ZEROCOPY                                              => (1 << 20),
    MIGRATE_PARAM_URI                                             => "migrate_uri",
    MIGRATE_PARAM_DEST_NAME                                       => "destination_name",
    MIGRATE_PARAM_DEST_XML                                        => "destination_xml",
    MIGRATE_PARAM_PERSIST_XML                                     => "persistent_xml",
    MIGRATE_PARAM_BANDWIDTH                                       => "bandwidth",
    MIGRATE_PARAM_BANDWIDTH_POSTCOPY                              => "bandwidth.postcopy",
    MIGRATE_PARAM_BANDWIDTH_AVAIL_SWITCHOVER                      => "bandwidth.avail.switchover",
    MIGRATE_PARAM_GRAPHICS_URI                                    => "graphics_uri",
    MIGRATE_PARAM_LISTEN_ADDRESS                                  => "listen_address",
    MIGRATE_PARAM_MIGRATE_DISKS                                   => "migrate_disks",
    MIGRATE_PARAM_MIGRATE_DISKS_DETECT_ZEROES                     => "migrate_disks_detect_zeroes",
    MIGRATE_PARAM_DISKS_PORT                                      => "disks_port",
    MIGRATE_PARAM_DISKS_URI                                       => "disks_uri",
    MIGRATE_PARAM_COMPRESSION                                     => "compression",
    MIGRATE_PARAM_COMPRESSION_MT_LEVEL                            => "compression.mt.level",
    MIGRATE_PARAM_COMPRESSION_MT_THREADS                          => "compression.mt.threads",
    MIGRATE_PARAM_COMPRESSION_MT_DTHREADS                         => "compression.mt.dthreads",
    MIGRATE_PARAM_COMPRESSION_XBZRLE_CACHE                        => "compression.xbzrle.cache",
    MIGRATE_PARAM_COMPRESSION_ZLIB_LEVEL                          => "compression.zlib.level",
    MIGRATE_PARAM_COMPRESSION_ZSTD_LEVEL                          => "compression.zstd.level",
    MIGRATE_PARAM_AUTO_CONVERGE_INITIAL                           => "auto_converge.initial",
    MIGRATE_PARAM_AUTO_CONVERGE_INCREMENT                         => "auto_converge.increment",
    MIGRATE_PARAM_PARALLEL_CONNECTIONS                            => "parallel.connections",
    MIGRATE_PARAM_TLS_DESTINATION                                 => "tls.destination",
    MIGRATE_MAX_SPEED_POSTCOPY                                    => (1 << 0),
    SHUTDOWN_DEFAULT                                              => 0,
    SHUTDOWN_ACPI_POWER_BTN                                       => (1 << 0),
    SHUTDOWN_GUEST_AGENT                                          => (1 << 1),
    SHUTDOWN_INITCTL                                              => (1 << 2),
    SHUTDOWN_SIGNAL                                               => (1 << 3),
    SHUTDOWN_PARAVIRT                                             => (1 << 4),
    REBOOT_DEFAULT                                                => 0,
    REBOOT_ACPI_POWER_BTN                                         => (1 << 0),
    REBOOT_GUEST_AGENT                                            => (1 << 1),
    REBOOT_INITCTL                                                => (1 << 2),
    REBOOT_SIGNAL                                                 => (1 << 3),
    REBOOT_PARAVIRT                                               => (1 << 4),
    DESTROY_DEFAULT                                               => 0,
    DESTROY_GRACEFUL                                              => 1 << 0,
    DESTROY_REMOVE_LOGS                                           => 1 << 1,
    SAVE_BYPASS_CACHE                                             => 1 << 0,
    SAVE_RUNNING                                                  => 1 << 1,
    SAVE_PAUSED                                                   => 1 << 2,
    SAVE_RESET_NVRAM                                              => 1 << 3,
    SAVE_PARAM_FILE                                               => "file",
    SAVE_PARAM_DXML                                               => "dxml",
    SAVE_PARAM_IMAGE_FORMAT                                       => "image_format",
    SAVE_PARAM_PARALLEL_CHANNELS                                  => "parallel.channels",
    CPU_STATS_CPUTIME                                             => "cpu_time",
    CPU_STATS_USERTIME                                            => "user_time",
    CPU_STATS_SYSTEMTIME                                          => "system_time",
    CPU_STATS_VCPUTIME                                            => "vcpu_time",
    BLKIO_WEIGHT                                                  => "weight",
    BLKIO_DEVICE_WEIGHT                                           => "device_weight",
    BLKIO_DEVICE_READ_IOPS                                        => "device_read_iops_sec",
    BLKIO_DEVICE_WRITE_IOPS                                       => "device_write_iops_sec",
    BLKIO_DEVICE_READ_BPS                                         => "device_read_bytes_sec",
    BLKIO_DEVICE_WRITE_BPS                                        => "device_write_bytes_sec",
    MEMORY_PARAM_UNLIMITED                                        => 9007199254740991,
    MEMORY_HARD_LIMIT                                             => "hard_limit",
    MEMORY_SOFT_LIMIT                                             => "soft_limit",
    MEMORY_MIN_GUARANTEE                                          => "min_guarantee",
    MEMORY_SWAP_HARD_LIMIT                                        => "swap_hard_limit",
    MEM_CURRENT                                                   => 0,
    MEM_LIVE                                                      => 1 << 0,
    MEM_CONFIG                                                    => 1 << 1,
    MEM_MAXIMUM                                                   => (1 << 2),
    NUMATUNE_MEM_STRICT                                           => 0,
    NUMATUNE_MEM_PREFERRED                                        => 1,
    NUMATUNE_MEM_INTERLEAVE                                       => 2,
    NUMATUNE_MEM_RESTRICTIVE                                      => 3,
    NUMA_NODESET                                                  => "numa_nodeset",
    NUMA_MODE                                                     => "numa_mode",
    GET_HOSTNAME_LEASE                                            => (1 << 0),
    GET_HOSTNAME_AGENT                                            => (1 << 1),
    METADATA_DESCRIPTION                                          => 0,
    METADATA_TITLE                                                => 1,
    METADATA_ELEMENT                                              => 2,
    XML_SECURE                                                    => (1 << 0),
    XML_INACTIVE                                                  => (1 << 1),
    XML_UPDATE_CPU                                                => (1 << 2),
    XML_MIGRATABLE                                                => (1 << 3),
    SAVE_IMAGE_XML_SECURE                                         => (1 << 0),
    BANDWIDTH_IN_AVERAGE                                          => "inbound.average",
    BANDWIDTH_IN_PEAK                                             => "inbound.peak",
    BANDWIDTH_IN_BURST                                            => "inbound.burst",
    BANDWIDTH_IN_FLOOR                                            => "inbound.floor",
    BANDWIDTH_OUT_AVERAGE                                         => "outbound.average",
    BANDWIDTH_OUT_PEAK                                            => "outbound.peak",
    BANDWIDTH_OUT_BURST                                           => "outbound.burst",
    BLOCK_RESIZE_BYTES                                            => 1 << 0,
    BLOCK_RESIZE_CAPACITY                                         => 1 << 1,
    MEMORY_VIRTUAL                                                => 1 << 0,
    MEMORY_PHYSICAL                                               => 1 << 1,
    UNDEFINE_MANAGED_SAVE                                         => (1 << 0),
    UNDEFINE_SNAPSHOTS_METADATA                                   => (1 << 1),
    UNDEFINE_NVRAM                                                => (1 << 2),
    UNDEFINE_KEEP_NVRAM                                           => (1 << 3),
    UNDEFINE_CHECKPOINTS_METADATA                                 => (1 << 4),
    UNDEFINE_TPM                                                  => (1 << 5),
    UNDEFINE_KEEP_TPM                                             => (1 << 6),
    VCPU_OFFLINE                                                  => 0,
    VCPU_RUNNING                                                  => 1,
    VCPU_BLOCKED                                                  => 2,
    VCPU_INFO_CPU_OFFLINE                                         => -1,
    VCPU_INFO_CPU_UNAVAILABLE                                     => -2,
    VCPU_CURRENT                                                  => 0,
    VCPU_LIVE                                                     => 1 << 0,
    VCPU_CONFIG                                                   => 1 << 1,
    VCPU_MAXIMUM                                                  => (1 << 2),
    VCPU_GUEST                                                    => (1 << 3),
    VCPU_HOTPLUGGABLE                                             => (1 << 4),
    IOTHREAD_POLL_MAX_NS                                          => "poll_max_ns",
    IOTHREAD_POLL_GROW                                            => "poll_grow",
    IOTHREAD_POLL_SHRINK                                          => "poll_shrink",
    IOTHREAD_THREAD_POOL_MIN                                      => "thread_pool_min",
    IOTHREAD_THREAD_POOL_MAX                                      => "thread_pool_max",
    DEVICE_MODIFY_CURRENT                                         => 0,
    DEVICE_MODIFY_LIVE                                            => 1 << 0,
    DEVICE_MODIFY_CONFIG                                          => 1 << 1,
    DEVICE_MODIFY_FORCE                                           => (1 << 2),
    STATS_STATE_STATE                                             => "state.state",
    STATS_STATE_REASON                                            => "state.reason",
    STATS_CPU_TIME                                                => "cpu.time",
    STATS_CPU_USER                                                => "cpu.user",
    STATS_CPU_SYSTEM                                              => "cpu.system",
    STATS_CPU_HALTPOLL_SUCCESS_TIME                               => "cpu.haltpoll.success.time",
    STATS_CPU_HALTPOLL_FAIL_TIME                                  => "cpu.haltpoll.fail.time",
    STATS_CPU_CACHE_MONITOR_COUNT                                 => "cpu.cache.monitor.count",
    STATS_CPU_CACHE_MONITOR_PREFIX                                => "cpu.cache.monitor.",
    STATS_CPU_CACHE_MONITOR_SUFFIX_NAME                           => ".name",
    STATS_CPU_CACHE_MONITOR_SUFFIX_VCPUS                          => ".vcpus",
    STATS_CPU_CACHE_MONITOR_SUFFIX_BANK_COUNT                     => ".bank.count",
    STATS_CPU_CACHE_MONITOR_SUFFIX_BANK_PREFIX                    => ".bank.",
    STATS_CPU_CACHE_MONITOR_SUFFIX_BANK_SUFFIX_ID                 => ".id",
    STATS_CPU_CACHE_MONITOR_SUFFIX_BANK_SUFFIX_BYTES              => ".bytes",
    STATS_BALLOON_CURRENT                                         => "balloon.current",
    STATS_BALLOON_MAXIMUM                                         => "balloon.maximum",
    STATS_BALLOON_SWAP_IN                                         => "balloon.swap_in",
    STATS_BALLOON_SWAP_OUT                                        => "balloon.swap_out",
    STATS_BALLOON_MAJOR_FAULT                                     => "balloon.major_fault",
    STATS_BALLOON_MINOR_FAULT                                     => "balloon.minor_fault",
    STATS_BALLOON_UNUSED                                          => "balloon.unused",
    STATS_BALLOON_AVAILABLE                                       => "balloon.available",
    STATS_BALLOON_RSS                                             => "balloon.rss",
    STATS_BALLOON_USABLE                                          => "balloon.usable",
    STATS_BALLOON_LAST_UPDATE                                     => "balloon.last-update",
    STATS_BALLOON_DISK_CACHES                                     => "balloon.disk_caches",
    STATS_BALLOON_HUGETLB_PGALLOC                                 => "balloon.hugetlb_pgalloc",
    STATS_BALLOON_HUGETLB_PGFAIL                                  => "balloon.hugetlb_pgfail",
    STATS_VCPU_CURRENT                                            => "vcpu.current",
    STATS_VCPU_MAXIMUM                                            => "vcpu.maximum",
    STATS_VCPU_PREFIX                                             => "vcpu.",
    STATS_VCPU_SUFFIX_STATE                                       => ".state",
    STATS_VCPU_SUFFIX_TIME                                        => ".time",
    STATS_VCPU_SUFFIX_WAIT                                        => ".wait",
    STATS_VCPU_SUFFIX_HALTED                                      => ".halted",
    STATS_VCPU_SUFFIX_DELAY                                       => ".delay",
    STATS_CUSTOM_SUFFIX_TYPE_CUR                                  => ".cur",
    STATS_CUSTOM_SUFFIX_TYPE_SUM                                  => ".sum",
    STATS_CUSTOM_SUFFIX_TYPE_MAX                                  => ".max",
    STATS_NET_COUNT                                               => "net.count",
    STATS_NET_PREFIX                                              => "net.",
    STATS_NET_SUFFIX_NAME                                         => ".name",
    STATS_NET_SUFFIX_RX_BYTES                                     => ".rx.bytes",
    STATS_NET_SUFFIX_RX_PKTS                                      => ".rx.pkts",
    STATS_NET_SUFFIX_RX_ERRS                                      => ".rx.errs",
    STATS_NET_SUFFIX_RX_DROP                                      => ".rx.drop",
    STATS_NET_SUFFIX_TX_BYTES                                     => ".tx.bytes",
    STATS_NET_SUFFIX_TX_PKTS                                      => ".tx.pkts",
    STATS_NET_SUFFIX_TX_ERRS                                      => ".tx.errs",
    STATS_NET_SUFFIX_TX_DROP                                      => ".tx.drop",
    STATS_BLOCK_COUNT                                             => "block.count",
    STATS_BLOCK_PREFIX                                            => "block.",
    STATS_BLOCK_SUFFIX_NAME                                       => ".name",
    STATS_BLOCK_SUFFIX_BACKINGINDEX                               => ".backingIndex",
    STATS_BLOCK_SUFFIX_PATH                                       => ".path",
    STATS_BLOCK_SUFFIX_RD_REQS                                    => ".rd.reqs",
    STATS_BLOCK_SUFFIX_RD_BYTES                                   => ".rd.bytes",
    STATS_BLOCK_SUFFIX_RD_TIMES                                   => ".rd.times",
    STATS_BLOCK_SUFFIX_WR_REQS                                    => ".wr.reqs",
    STATS_BLOCK_SUFFIX_WR_BYTES                                   => ".wr.bytes",
    STATS_BLOCK_SUFFIX_WR_TIMES                                   => ".wr.times",
    STATS_BLOCK_SUFFIX_FL_REQS                                    => ".fl.reqs",
    STATS_BLOCK_SUFFIX_FL_TIMES                                   => ".fl.times",
    STATS_BLOCK_SUFFIX_ERRORS                                     => ".errors",
    STATS_BLOCK_SUFFIX_ALLOCATION                                 => ".allocation",
    STATS_BLOCK_SUFFIX_CAPACITY                                   => ".capacity",
    STATS_BLOCK_SUFFIX_PHYSICAL                                   => ".physical",
    STATS_BLOCK_SUFFIX_THRESHOLD                                  => ".threshold",
    STATS_PERF_CMT                                                => "perf.cmt",
    STATS_PERF_MBMT                                               => "perf.mbmt",
    STATS_PERF_MBML                                               => "perf.mbml",
    STATS_PERF_CACHE_MISSES                                       => "perf.cache_misses",
    STATS_PERF_CACHE_REFERENCES                                   => "perf.cache_references",
    STATS_PERF_INSTRUCTIONS                                       => "perf.instructions",
    STATS_PERF_CPU_CYCLES                                         => "perf.cpu_cycles",
    STATS_PERF_BRANCH_INSTRUCTIONS                                => "perf.branch_instructions",
    STATS_PERF_BRANCH_MISSES                                      => "perf.branch_misses",
    STATS_PERF_BUS_CYCLES                                         => "perf.bus_cycles",
    STATS_PERF_STALLED_CYCLES_FRONTEND                            => "perf.stalled_cycles_frontend",
    STATS_PERF_STALLED_CYCLES_BACKEND                             => "perf.stalled_cycles_backend",
    STATS_PERF_REF_CPU_CYCLES                                     => "perf.ref_cpu_cycles",
    STATS_PERF_CPU_CLOCK                                          => "perf.cpu_clock",
    STATS_PERF_TASK_CLOCK                                         => "perf.task_clock",
    STATS_PERF_PAGE_FAULTS                                        => "perf.page_faults",
    STATS_PERF_CONTEXT_SWITCHES                                   => "perf.context_switches",
    STATS_PERF_CPU_MIGRATIONS                                     => "perf.cpu_migrations",
    STATS_PERF_PAGE_FAULTS_MIN                                    => "perf.page_faults_min",
    STATS_PERF_PAGE_FAULTS_MAJ                                    => "perf.page_faults_maj",
    STATS_PERF_ALIGNMENT_FAULTS                                   => "perf.alignment_faults",
    STATS_PERF_EMULATION_FAULTS                                   => "perf.emulation_faults",
    STATS_IOTHREAD_COUNT                                          => "iothread.count",
    STATS_IOTHREAD_PREFIX                                         => "iothread.",
    STATS_IOTHREAD_SUFFIX_POLL_MAX_NS                             => ".poll-max-ns",
    STATS_IOTHREAD_SUFFIX_POLL_GROW                               => ".poll-grow",
    STATS_IOTHREAD_SUFFIX_POLL_SHRINK                             => ".poll-shrink",
    STATS_MEMORY_BANDWIDTH_MONITOR_COUNT                          => "memory.bandwidth.monitor.count",
    STATS_MEMORY_BANDWIDTH_MONITOR_PREFIX                         => "memory.bandwidth.monitor.",
    STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NAME                    => ".name",
    STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_VCPUS                   => ".vcpus",
    STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NODE_COUNT              => ".node.count",
    STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NODE_PREFIX             => ".node.",
    STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NODE_SUFFIX_ID          => ".id",
    STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NODE_SUFFIX_BYTES_LOCAL => ".bytes.local",
    STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NODE_SUFFIX_BYTES_TOTAL => ".bytes.total",
    STATS_DIRTYRATE_CALC_STATUS                                   => "dirtyrate.calc_status",
    STATS_DIRTYRATE_CALC_START_TIME                               => "dirtyrate.calc_start_time",
    STATS_DIRTYRATE_CALC_PERIOD                                   => "dirtyrate.calc_period",
    STATS_DIRTYRATE_MEGABYTES_PER_SECOND                          => "dirtyrate.megabytes_per_second",
    STATS_DIRTYRATE_CALC_MODE                                     => "dirtyrate.calc_mode",
    STATS_DIRTYRATE_VCPU_PREFIX                                   => "dirtyrate.vcpu.",
    STATS_DIRTYRATE_VCPU_SUFFIX_MEGABYTES_PER_SECOND              => ".megabytes_per_second",
    STATS_VM_PREFIX                                               => "vm.",
    STATS_STATE                                                   => (1 << 0),
    STATS_CPU_TOTAL                                               => (1 << 1),
    STATS_BALLOON                                                 => (1 << 2),
    STATS_VCPU                                                    => (1 << 3),
    STATS_INTERFACE                                               => (1 << 4),
    STATS_BLOCK                                                   => (1 << 5),
    STATS_PERF                                                    => (1 << 6),
    STATS_IOTHREAD                                                => (1 << 7),
    STATS_MEMORY                                                  => (1 << 8),
    STATS_DIRTYRATE                                               => (1 << 9),
    STATS_VM                                                      => (1 << 10),
    PERF_PARAM_CMT                                                => "cmt",
    PERF_PARAM_MBMT                                               => "mbmt",
    PERF_PARAM_MBML                                               => "mbml",
    PERF_PARAM_CACHE_MISSES                                       => "cache_misses",
    PERF_PARAM_CACHE_REFERENCES                                   => "cache_references",
    PERF_PARAM_INSTRUCTIONS                                       => "instructions",
    PERF_PARAM_CPU_CYCLES                                         => "cpu_cycles",
    PERF_PARAM_BRANCH_INSTRUCTIONS                                => "branch_instructions",
    PERF_PARAM_BRANCH_MISSES                                      => "branch_misses",
    PERF_PARAM_BUS_CYCLES                                         => "bus_cycles",
    PERF_PARAM_STALLED_CYCLES_FRONTEND                            => "stalled_cycles_frontend",
    PERF_PARAM_STALLED_CYCLES_BACKEND                             => "stalled_cycles_backend",
    PERF_PARAM_REF_CPU_CYCLES                                     => "ref_cpu_cycles",
    PERF_PARAM_CPU_CLOCK                                          => "cpu_clock",
    PERF_PARAM_TASK_CLOCK                                         => "task_clock",
    PERF_PARAM_PAGE_FAULTS                                        => "page_faults",
    PERF_PARAM_CONTEXT_SWITCHES                                   => "context_switches",
    PERF_PARAM_CPU_MIGRATIONS                                     => "cpu_migrations",
    PERF_PARAM_PAGE_FAULTS_MIN                                    => "page_faults_min",
    PERF_PARAM_PAGE_FAULTS_MAJ                                    => "page_faults_maj",
    PERF_PARAM_ALIGNMENT_FAULTS                                   => "alignment_faults",
    PERF_PARAM_EMULATION_FAULTS                                   => "emulation_faults",
    BLOCK_JOB_TYPE_UNKNOWN                                        => 0,
    BLOCK_JOB_TYPE_PULL                                           => 1,
    BLOCK_JOB_TYPE_COPY                                           => 2,
    BLOCK_JOB_TYPE_COMMIT                                         => 3,
    BLOCK_JOB_TYPE_ACTIVE_COMMIT                                  => 4,
    BLOCK_JOB_TYPE_BACKUP                                         => 5,
    BLOCK_JOB_ABORT_ASYNC                                         => 1 << 0,
    BLOCK_JOB_ABORT_PIVOT                                         => 1 << 1,
    BLOCK_JOB_INFO_BANDWIDTH_BYTES                                => 1 << 0,
    BLOCK_JOB_SPEED_BANDWIDTH_BYTES                               => 1 << 0,
    BLOCK_PULL_BANDWIDTH_BYTES                                    => 1 << 6,
    BLOCK_REBASE_SHALLOW                                          => 1 << 0,
    BLOCK_REBASE_REUSE_EXT                                        => 1 << 1,
    BLOCK_REBASE_COPY_RAW                                         => 1 << 2,
    BLOCK_REBASE_COPY                                             => 1 << 3,
    BLOCK_REBASE_RELATIVE                                         => 1 << 4,
    BLOCK_REBASE_COPY_DEV                                         => 1 << 5,
    BLOCK_REBASE_BANDWIDTH_BYTES                                  => 1 << 6,
    BLOCK_COPY_SHALLOW                                            => 1 << 0,
    BLOCK_COPY_REUSE_EXT                                          => 1 << 1,
    BLOCK_COPY_TRANSIENT_JOB                                      => 1 << 2,
    BLOCK_COPY_SYNCHRONOUS_WRITES                                 => 1 << 3,
    BLOCK_COPY_BANDWIDTH                                          => "bandwidth",
    BLOCK_COPY_GRANULARITY                                        => "granularity",
    BLOCK_COPY_BUF_SIZE                                           => "buf-size",
    BLOCK_COMMIT_SHALLOW                                          => 1 << 0,
    BLOCK_COMMIT_DELETE                                           => 1 << 1,
    BLOCK_COMMIT_ACTIVE                                           => 1 << 2,
    BLOCK_COMMIT_RELATIVE                                         => 1 << 3,
    BLOCK_COMMIT_BANDWIDTH_BYTES                                  => 1 << 4,
    BLOCK_IOTUNE_TOTAL_BYTES_SEC                                  => "total_bytes_sec",
    BLOCK_IOTUNE_READ_BYTES_SEC                                   => "read_bytes_sec",
    BLOCK_IOTUNE_WRITE_BYTES_SEC                                  => "write_bytes_sec",
    BLOCK_IOTUNE_TOTAL_IOPS_SEC                                   => "total_iops_sec",
    BLOCK_IOTUNE_READ_IOPS_SEC                                    => "read_iops_sec",
    BLOCK_IOTUNE_WRITE_IOPS_SEC                                   => "write_iops_sec",
    BLOCK_IOTUNE_TOTAL_BYTES_SEC_MAX                              => "total_bytes_sec_max",
    BLOCK_IOTUNE_READ_BYTES_SEC_MAX                               => "read_bytes_sec_max",
    BLOCK_IOTUNE_WRITE_BYTES_SEC_MAX                              => "write_bytes_sec_max",
    BLOCK_IOTUNE_TOTAL_IOPS_SEC_MAX                               => "total_iops_sec_max",
    BLOCK_IOTUNE_READ_IOPS_SEC_MAX                                => "read_iops_sec_max",
    BLOCK_IOTUNE_WRITE_IOPS_SEC_MAX                               => "write_iops_sec_max",
    BLOCK_IOTUNE_TOTAL_BYTES_SEC_MAX_LENGTH                       => "total_bytes_sec_max_length",
    BLOCK_IOTUNE_READ_BYTES_SEC_MAX_LENGTH                        => "read_bytes_sec_max_length",
    BLOCK_IOTUNE_WRITE_BYTES_SEC_MAX_LENGTH                       => "write_bytes_sec_max_length",
    BLOCK_IOTUNE_TOTAL_IOPS_SEC_MAX_LENGTH                        => "total_iops_sec_max_length",
    BLOCK_IOTUNE_READ_IOPS_SEC_MAX_LENGTH                         => "read_iops_sec_max_length",
    BLOCK_IOTUNE_WRITE_IOPS_SEC_MAX_LENGTH                        => "write_iops_sec_max_length",
    BLOCK_IOTUNE_SIZE_IOPS_SEC                                    => "size_iops_sec",
    BLOCK_IOTUNE_GROUP_NAME                                       => "group_name",
    DISK_ERROR_NONE                                               => 0,
    DISK_ERROR_UNSPEC                                             => 1,
    DISK_ERROR_NO_SPACE                                           => 2,
    KEYCODE_SET_LINUX                                             => 0,
    KEYCODE_SET_XT                                                => 1,
    KEYCODE_SET_ATSET1                                            => 2,
    KEYCODE_SET_ATSET2                                            => 3,
    KEYCODE_SET_ATSET3                                            => 4,
    KEYCODE_SET_OSX                                               => 5,
    KEYCODE_SET_XT_KBD                                            => 6,
    KEYCODE_SET_USB                                               => 7,
    KEYCODE_SET_WIN32                                             => 8,
    KEYCODE_SET_QNUM                                              => 9,
    KEYCODE_SET_RFB                                               => 9,
    SEND_KEY_MAX_KEYS                                             => 16,
    PROCESS_SIGNAL_NOP                                            => 0,
    PROCESS_SIGNAL_HUP                                            => 1,
    PROCESS_SIGNAL_INT                                            => 2,
    PROCESS_SIGNAL_QUIT                                           => 3,
    PROCESS_SIGNAL_ILL                                            => 4,
    PROCESS_SIGNAL_TRAP                                           => 5,
    PROCESS_SIGNAL_ABRT                                           => 6,
    PROCESS_SIGNAL_BUS                                            => 7,
    PROCESS_SIGNAL_FPE                                            => 8,
    PROCESS_SIGNAL_KILL                                           => 9,
    PROCESS_SIGNAL_USR1                                           => 10,
    PROCESS_SIGNAL_SEGV                                           => 11,
    PROCESS_SIGNAL_USR2                                           => 12,
    PROCESS_SIGNAL_PIPE                                           => 13,
    PROCESS_SIGNAL_ALRM                                           => 14,
    PROCESS_SIGNAL_TERM                                           => 15,
    PROCESS_SIGNAL_STKFLT                                         => 16,
    PROCESS_SIGNAL_CHLD                                           => 17,
    PROCESS_SIGNAL_CONT                                           => 18,
    PROCESS_SIGNAL_STOP                                           => 19,
    PROCESS_SIGNAL_TSTP                                           => 20,
    PROCESS_SIGNAL_TTIN                                           => 21,
    PROCESS_SIGNAL_TTOU                                           => 22,
    PROCESS_SIGNAL_URG                                            => 23,
    PROCESS_SIGNAL_XCPU                                           => 24,
    PROCESS_SIGNAL_XFSZ                                           => 25,
    PROCESS_SIGNAL_VTALRM                                         => 26,
    PROCESS_SIGNAL_PROF                                           => 27,
    PROCESS_SIGNAL_WINCH                                          => 28,
    PROCESS_SIGNAL_POLL                                           => 29,
    PROCESS_SIGNAL_PWR                                            => 30,
    PROCESS_SIGNAL_SYS                                            => 31,
    PROCESS_SIGNAL_RT0                                            => 32,
    PROCESS_SIGNAL_RT1                                            => 33,
    PROCESS_SIGNAL_RT2                                            => 34,
    PROCESS_SIGNAL_RT3                                            => 35,
    PROCESS_SIGNAL_RT4                                            => 36,
    PROCESS_SIGNAL_RT5                                            => 37,
    PROCESS_SIGNAL_RT6                                            => 38,
    PROCESS_SIGNAL_RT7                                            => 39,
    PROCESS_SIGNAL_RT8                                            => 40,
    PROCESS_SIGNAL_RT9                                            => 41,
    PROCESS_SIGNAL_RT10                                           => 42,
    PROCESS_SIGNAL_RT11                                           => 43,
    PROCESS_SIGNAL_RT12                                           => 44,
    PROCESS_SIGNAL_RT13                                           => 45,
    PROCESS_SIGNAL_RT14                                           => 46,
    PROCESS_SIGNAL_RT15                                           => 47,
    PROCESS_SIGNAL_RT16                                           => 48,
    PROCESS_SIGNAL_RT17                                           => 49,
    PROCESS_SIGNAL_RT18                                           => 50,
    PROCESS_SIGNAL_RT19                                           => 51,
    PROCESS_SIGNAL_RT20                                           => 52,
    PROCESS_SIGNAL_RT21                                           => 53,
    PROCESS_SIGNAL_RT22                                           => 54,
    PROCESS_SIGNAL_RT23                                           => 55,
    PROCESS_SIGNAL_RT24                                           => 56,
    PROCESS_SIGNAL_RT25                                           => 57,
    PROCESS_SIGNAL_RT26                                           => 58,
    PROCESS_SIGNAL_RT27                                           => 59,
    PROCESS_SIGNAL_RT28                                           => 60,
    PROCESS_SIGNAL_RT29                                           => 61,
    PROCESS_SIGNAL_RT30                                           => 62,
    PROCESS_SIGNAL_RT31                                           => 63,
    PROCESS_SIGNAL_RT32                                           => 64,
    EVENT_DEFINED                                                 => 0,
    EVENT_UNDEFINED                                               => 1,
    EVENT_STARTED                                                 => 2,
    EVENT_SUSPENDED                                               => 3,
    EVENT_RESUMED                                                 => 4,
    EVENT_STOPPED                                                 => 5,
    EVENT_SHUTDOWN                                                => 6,
    EVENT_PMSUSPENDED                                             => 7,
    EVENT_CRASHED                                                 => 8,
    EVENT_DEFINED_ADDED                                           => 0,
    EVENT_DEFINED_UPDATED                                         => 1,
    EVENT_DEFINED_RENAMED                                         => 2,
    EVENT_DEFINED_FROM_SNAPSHOT                                   => 3,
    EVENT_UNDEFINED_REMOVED                                       => 0,
    EVENT_UNDEFINED_RENAMED                                       => 1,
    EVENT_STARTED_BOOTED                                          => 0,
    EVENT_STARTED_MIGRATED                                        => 1,
    EVENT_STARTED_RESTORED                                        => 2,
    EVENT_STARTED_FROM_SNAPSHOT                                   => 3,
    EVENT_STARTED_WAKEUP                                          => 4,
    EVENT_STARTED_RECREATED                                       => 5,
    EVENT_SUSPENDED_PAUSED                                        => 0,
    EVENT_SUSPENDED_MIGRATED                                      => 1,
    EVENT_SUSPENDED_IOERROR                                       => 2,
    EVENT_SUSPENDED_WATCHDOG                                      => 3,
    EVENT_SUSPENDED_RESTORED                                      => 4,
    EVENT_SUSPENDED_FROM_SNAPSHOT                                 => 5,
    EVENT_SUSPENDED_API_ERROR                                     => 6,
    EVENT_SUSPENDED_POSTCOPY                                      => 7,
    EVENT_SUSPENDED_POSTCOPY_FAILED                               => 8,
    EVENT_RESUMED_UNPAUSED                                        => 0,
    EVENT_RESUMED_MIGRATED                                        => 1,
    EVENT_RESUMED_FROM_SNAPSHOT                                   => 2,
    EVENT_RESUMED_POSTCOPY                                        => 3,
    EVENT_RESUMED_POSTCOPY_FAILED                                 => 4,
    EVENT_STOPPED_SHUTDOWN                                        => 0,
    EVENT_STOPPED_DESTROYED                                       => 1,
    EVENT_STOPPED_CRASHED                                         => 2,
    EVENT_STOPPED_MIGRATED                                        => 3,
    EVENT_STOPPED_SAVED                                           => 4,
    EVENT_STOPPED_FAILED                                          => 5,
    EVENT_STOPPED_FROM_SNAPSHOT                                   => 6,
    EVENT_STOPPED_RECREATED                                       => 7,
    EVENT_SHUTDOWN_FINISHED                                       => 0,
    EVENT_SHUTDOWN_GUEST                                          => 1,
    EVENT_SHUTDOWN_HOST                                           => 2,
    EVENT_PMSUSPENDED_MEMORY                                      => 0,
    EVENT_PMSUSPENDED_DISK                                        => 1,
    EVENT_CRASHED_PANICKED                                        => 0,
    EVENT_CRASHED_CRASHLOADED                                     => 1,
    EVENT_MEMORY_FAILURE_RECIPIENT_HYPERVISOR                     => 0,
    EVENT_MEMORY_FAILURE_RECIPIENT_GUEST                          => 1,
    EVENT_MEMORY_FAILURE_ACTION_IGNORE                            => 0,
    EVENT_MEMORY_FAILURE_ACTION_INJECT                            => 1,
    EVENT_MEMORY_FAILURE_ACTION_FATAL                             => 2,
    EVENT_MEMORY_FAILURE_ACTION_RESET                             => 3,
    MEMORY_FAILURE_ACTION_REQUIRED                                => (1 << 0),
    MEMORY_FAILURE_RECURSIVE                                      => (1 << 1),
    JOB_NONE                                                      => 0,
    JOB_BOUNDED                                                   => 1,
    JOB_UNBOUNDED                                                 => 2,
    JOB_COMPLETED                                                 => 3,
    JOB_FAILED                                                    => 4,
    JOB_CANCELLED                                                 => 5,
    JOB_STATS_COMPLETED                                           => 1 << 0,
    JOB_STATS_KEEP_COMPLETED                                      => 1 << 1,
    ABORT_JOB_POSTCOPY                                            => 1 << 0,
    JOB_OPERATION_UNKNOWN                                         => 0,
    JOB_OPERATION_START                                           => 1,
    JOB_OPERATION_SAVE                                            => 2,
    JOB_OPERATION_RESTORE                                         => 3,
    JOB_OPERATION_MIGRATION_IN                                    => 4,
    JOB_OPERATION_MIGRATION_OUT                                   => 5,
    JOB_OPERATION_SNAPSHOT                                        => 6,
    JOB_OPERATION_SNAPSHOT_REVERT                                 => 7,
    JOB_OPERATION_DUMP                                            => 8,
    JOB_OPERATION_BACKUP                                          => 9,
    JOB_OPERATION_SNAPSHOT_DELETE                                 => 10,
    JOB_OPERATION                                                 => "operation",
    JOB_TIME_ELAPSED                                              => "time_elapsed",
    JOB_TIME_ELAPSED_NET                                          => "time_elapsed_net",
    JOB_TIME_REMAINING                                            => "time_remaining",
    JOB_DOWNTIME                                                  => "downtime",
    JOB_DOWNTIME_NET                                              => "downtime_net",
    JOB_SETUP_TIME                                                => "setup_time",
    JOB_DATA_TOTAL                                                => "data_total",
    JOB_DATA_PROCESSED                                            => "data_processed",
    JOB_DATA_REMAINING                                            => "data_remaining",
    JOB_MEMORY_TOTAL                                              => "memory_total",
    JOB_MEMORY_PROCESSED                                          => "memory_processed",
    JOB_MEMORY_REMAINING                                          => "memory_remaining",
    JOB_MEMORY_CONSTANT                                           => "memory_constant",
    JOB_MEMORY_NORMAL                                             => "memory_normal",
    JOB_MEMORY_NORMAL_BYTES                                       => "memory_normal_bytes",
    JOB_MEMORY_BPS                                                => "memory_bps",
    JOB_MEMORY_DIRTY_RATE                                         => "memory_dirty_rate",
    JOB_MEMORY_PAGE_SIZE                                          => "memory_page_size",
    JOB_MEMORY_ITERATION                                          => "memory_iteration",
    JOB_MEMORY_POSTCOPY_REQS                                      => "memory_postcopy_requests",
    JOB_DISK_TOTAL                                                => "disk_total",
    JOB_DISK_PROCESSED                                            => "disk_processed",
    JOB_DISK_REMAINING                                            => "disk_remaining",
    JOB_DISK_BPS                                                  => "disk_bps",
    JOB_COMPRESSION_CACHE                                         => "compression_cache",
    JOB_COMPRESSION_BYTES                                         => "compression_bytes",
    JOB_COMPRESSION_PAGES                                         => "compression_pages",
    JOB_COMPRESSION_CACHE_MISSES                                  => "compression_cache_misses",
    JOB_COMPRESSION_OVERFLOW                                      => "compression_overflow",
    JOB_AUTO_CONVERGE_THROTTLE                                    => "auto_converge_throttle",
    JOB_SUCCESS                                                   => "success",
    JOB_ERRMSG                                                    => "errmsg",
    JOB_DISK_TEMP_USED                                            => "disk_temp_used",
    JOB_DISK_TEMP_TOTAL                                           => "disk_temp_total",
    JOB_VFIO_DATA_TRANSFERRED                                     => "vfio_data_transferred",
    EVENT_WATCHDOG_NONE                                           => 0,
    EVENT_IO_ERROR_NONE                                           => 0,
    EVENT_GRAPHICS_CONNECT                                        => 0,
    BLOCK_JOB_COMPLETED                                           => 0,
    BLOCK_JOB_FAILED                                              => 1,
    BLOCK_JOB_CANCELED                                            => 2,
    BLOCK_JOB_READY                                               => 3,
    EVENT_DISK_CHANGE_MISSING_ON_START                            => 0,
    EVENT_DISK_DROP_MISSING_ON_START                              => 1,
    EVENT_TRAY_CHANGE_OPEN                                        => 0,
    TUNABLE_CPU_VCPUPIN                                           => "cputune.vcpupin%u",
    TUNABLE_CPU_EMULATORPIN                                       => "cputune.emulatorpin",
    TUNABLE_CPU_IOTHREADSPIN                                      => "cputune.iothreadpin%u",
    TUNABLE_CPU_CPU_SHARES                                        => "cputune.cpu_shares",
    TUNABLE_CPU_GLOBAL_PERIOD                                     => "cputune.global_period",
    TUNABLE_CPU_GLOBAL_QUOTA                                      => "cputune.global_quota",
    TUNABLE_CPU_VCPU_PERIOD                                       => "cputune.vcpu_period",
    TUNABLE_CPU_VCPU_QUOTA                                        => "cputune.vcpu_quota",
    TUNABLE_CPU_EMULATOR_PERIOD                                   => "cputune.emulator_period",
    TUNABLE_CPU_EMULATOR_QUOTA                                    => "cputune.emulator_quota",
    TUNABLE_CPU_IOTHREAD_PERIOD                                   => "cputune.iothread_period",
    TUNABLE_CPU_IOTHREAD_QUOTA                                    => "cputune.iothread_quota",
    TUNABLE_BLKDEV_DISK                                           => "blkdeviotune.disk",
    TUNABLE_BLKDEV_TOTAL_BYTES_SEC                                => "blkdeviotune.total_bytes_sec",
    TUNABLE_BLKDEV_READ_BYTES_SEC                                 => "blkdeviotune.read_bytes_sec",
    TUNABLE_BLKDEV_WRITE_BYTES_SEC                                => "blkdeviotune.write_bytes_sec",
    TUNABLE_BLKDEV_TOTAL_IOPS_SEC                                 => "blkdeviotune.total_iops_sec",
    TUNABLE_BLKDEV_READ_IOPS_SEC                                  => "blkdeviotune.read_iops_sec",
    TUNABLE_BLKDEV_WRITE_IOPS_SEC                                 => "blkdeviotune.write_iops_sec",
    TUNABLE_BLKDEV_TOTAL_BYTES_SEC_MAX                            => "blkdeviotune.total_bytes_sec_max",
    TUNABLE_BLKDEV_READ_BYTES_SEC_MAX                             => "blkdeviotune.read_bytes_sec_max",
    TUNABLE_BLKDEV_WRITE_BYTES_SEC_MAX                            => "blkdeviotune.write_bytes_sec_max",
    TUNABLE_BLKDEV_TOTAL_IOPS_SEC_MAX                             => "blkdeviotune.total_iops_sec_max",
    TUNABLE_BLKDEV_READ_IOPS_SEC_MAX                              => "blkdeviotune.read_iops_sec_max",
    TUNABLE_BLKDEV_WRITE_IOPS_SEC_MAX                             => "blkdeviotune.write_iops_sec_max",
    TUNABLE_BLKDEV_SIZE_IOPS_SEC                                  => "blkdeviotune.size_iops_sec",
    TUNABLE_BLKDEV_GROUP_NAME                                     => "blkdeviotune.group_name",
    TUNABLE_BLKDEV_TOTAL_BYTES_SEC_MAX_LENGTH                     => "blkdeviotune.total_bytes_sec_max_length",
    TUNABLE_BLKDEV_READ_BYTES_SEC_MAX_LENGTH                      => "blkdeviotune.read_bytes_sec_max_length",
    TUNABLE_BLKDEV_WRITE_BYTES_SEC_MAX_LENGTH                     => "blkdeviotune.write_bytes_sec_max_length",
    TUNABLE_BLKDEV_TOTAL_IOPS_SEC_MAX_LENGTH                      => "blkdeviotune.total_iops_sec_max_length",
    TUNABLE_BLKDEV_READ_IOPS_SEC_MAX_LENGTH                       => "blkdeviotune.read_iops_sec_max_length",
    TUNABLE_BLKDEV_WRITE_IOPS_SEC_MAX_LENGTH                      => "blkdeviotune.write_iops_sec_max_length",
    CONSOLE_FORCE                                                 => (1 << 0),
    CONSOLE_SAFE                                                  => (1 << 1),
    CHANNEL_FORCE                                                 => (1 << 0),
    OPEN_GRAPHICS_SKIPAUTH                                        => (1 << 0),
    TIME_SYNC                                                     => (1 << 0),
    SCHED_FIELD_INT                                               => 1,
    SCHED_FIELD_UINT                                              => 2,
    SCHED_FIELD_LLONG                                             => 3,
    SCHED_FIELD_ULLONG                                            => 4,
    SCHED_FIELD_DOUBLE                                            => 5,
    SCHED_FIELD_BOOLEAN                                           => 6,
    SCHED_FIELD_LENGTH                                            => 80,
    BLKIO_PARAM_INT                                               => 1,
    BLKIO_PARAM_UINT                                              => 2,
    BLKIO_PARAM_LLONG                                             => 3,
    BLKIO_PARAM_ULLONG                                            => 4,
    BLKIO_PARAM_DOUBLE                                            => 5,
    BLKIO_PARAM_BOOLEAN                                           => 6,
    BLKIO_FIELD_LENGTH                                            => 80,
    MEMORY_PARAM_INT                                              => 1,
    MEMORY_PARAM_UINT                                             => 2,
    MEMORY_PARAM_LLONG                                            => 3,
    MEMORY_PARAM_ULLONG                                           => 4,
    MEMORY_PARAM_DOUBLE                                           => 5,
    MEMORY_PARAM_BOOLEAN                                          => 6,
    MEMORY_FIELD_LENGTH                                           => 80,
    INTERFACE_ADDRESSES_SRC_LEASE                                 => 0,
    INTERFACE_ADDRESSES_SRC_AGENT                                 => 1,
    INTERFACE_ADDRESSES_SRC_ARP                                   => 2,
    PASSWORD_ENCRYPTED                                            => 1 << 0,
    LIFECYCLE_POWEROFF                                            => 0,
    LIFECYCLE_REBOOT                                              => 1,
    LIFECYCLE_CRASH                                               => 2,
    LIFECYCLE_ACTION_DESTROY                                      => 0,
    LIFECYCLE_ACTION_RESTART                                      => 1,
    LIFECYCLE_ACTION_RESTART_RENAME                               => 2,
    LIFECYCLE_ACTION_PRESERVE                                     => 3,
    LIFECYCLE_ACTION_COREDUMP_DESTROY                             => 4,
    LIFECYCLE_ACTION_COREDUMP_RESTART                             => 5,
    LAUNCH_SECURITY_SEV_MEASUREMENT                               => "sev-measurement",
    LAUNCH_SECURITY_SEV_API_MAJOR                                 => "sev-api-major",
    LAUNCH_SECURITY_SEV_API_MINOR                                 => "sev-api-minor",
    LAUNCH_SECURITY_SEV_BUILD_ID                                  => "sev-build-id",
    LAUNCH_SECURITY_SEV_POLICY                                    => "sev-policy",
    LAUNCH_SECURITY_SEV_SNP_POLICY                                => "sev-snp-policy",
    LAUNCH_SECURITY_SEV_SECRET_HEADER                             => "sev-secret-header",
    LAUNCH_SECURITY_SEV_SECRET                                    => "sev-secret",
    LAUNCH_SECURITY_SEV_SECRET_SET_ADDRESS                        => "sev-secret-set-address",
    GUEST_INFO_USER_COUNT                                         => "user.count",
    GUEST_INFO_USER_PREFIX                                        => "user.",
    GUEST_INFO_USER_SUFFIX_NAME                                   => ".name",
    GUEST_INFO_USER_SUFFIX_DOMAIN                                 => ".domain",
    GUEST_INFO_USER_SUFFIX_LOGIN_TIME                             => ".login-time",
    GUEST_INFO_OS_ID                                              => "os.id",
    GUEST_INFO_OS_NAME                                            => "os.name",
    GUEST_INFO_OS_PRETTY_NAME                                     => "os.pretty-name",
    GUEST_INFO_OS_VERSION                                         => "os.version",
    GUEST_INFO_OS_VERSION_ID                                      => "os.version-id",
    GUEST_INFO_OS_KERNEL_RELEASE                                  => "os.kernel-release",
    GUEST_INFO_OS_KERNEL_VERSION                                  => "os.kernel-version",
    GUEST_INFO_OS_MACHINE                                         => "os.machine",
    GUEST_INFO_OS_VARIANT                                         => "os.variant",
    GUEST_INFO_OS_VARIANT_ID                                      => "os.variant-id",
    GUEST_INFO_TIMEZONE_NAME                                      => "timezone.name",
    GUEST_INFO_TIMEZONE_OFFSET                                    => "timezone.offset",
    GUEST_INFO_HOSTNAME_HOSTNAME                                  => "hostname",
    GUEST_INFO_FS_COUNT                                           => "fs.count",
    GUEST_INFO_FS_PREFIX                                          => "fs.",
    GUEST_INFO_FS_SUFFIX_MOUNTPOINT                               => ".mountpoint",
    GUEST_INFO_FS_SUFFIX_NAME                                     => ".name",
    GUEST_INFO_FS_SUFFIX_FSTYPE                                   => ".fstype",
    GUEST_INFO_FS_SUFFIX_TOTAL_BYTES                              => ".total-bytes",
    GUEST_INFO_FS_SUFFIX_USED_BYTES                               => ".used-bytes",
    GUEST_INFO_FS_SUFFIX_DISK_COUNT                               => ".disk.count",
    GUEST_INFO_FS_SUFFIX_DISK_PREFIX                              => ".disk.",
    GUEST_INFO_FS_SUFFIX_DISK_SUFFIX_ALIAS                        => ".alias",
    GUEST_INFO_FS_SUFFIX_DISK_SUFFIX_SERIAL                       => ".serial",
    GUEST_INFO_FS_SUFFIX_DISK_SUFFIX_DEVICE                       => ".device",
    GUEST_INFO_DISK_COUNT                                         => "disk.count",
    GUEST_INFO_DISK_PREFIX                                        => "disk.",
    GUEST_INFO_DISK_SUFFIX_NAME                                   => ".name",
    GUEST_INFO_DISK_SUFFIX_PARTITION                              => ".partition",
    GUEST_INFO_DISK_SUFFIX_DEPENDENCY_COUNT                       => ".dependency.count",
    GUEST_INFO_DISK_SUFFIX_DEPENDENCY_PREFIX                      => ".dependency.",
    GUEST_INFO_DISK_SUFFIX_DEPENDENCY_SUFFIX_NAME                 => ".name",
    GUEST_INFO_DISK_SUFFIX_SERIAL                                 => ".serial",
    GUEST_INFO_DISK_SUFFIX_ALIAS                                  => ".alias",
    GUEST_INFO_DISK_SUFFIX_GUEST_ALIAS                            => ".guest_alias",
    GUEST_INFO_DISK_SUFFIX_GUEST_BUS                              => ".guest_bus",
    GUEST_INFO_IF_COUNT                                           => "if.count",
    GUEST_INFO_IF_PREFIX                                          => "if.",
    GUEST_INFO_IF_SUFFIX_NAME                                     => ".name",
    GUEST_INFO_IF_SUFFIX_HWADDR                                   => ".hwaddr",
    GUEST_INFO_IF_SUFFIX_ADDR_COUNT                               => ".addr.count",
    GUEST_INFO_IF_SUFFIX_ADDR_PREFIX                              => ".addr.",
    GUEST_INFO_IF_SUFFIX_ADDR_SUFFIX_TYPE                         => ".type",
    GUEST_INFO_IF_SUFFIX_ADDR_SUFFIX_ADDR                         => ".addr",
    GUEST_INFO_IF_SUFFIX_ADDR_SUFFIX_PREFIX                       => ".prefix",
    GUEST_INFO_LOAD_1M                                            => "load.1m",
    GUEST_INFO_LOAD_5M                                            => "load.5m",
    GUEST_INFO_LOAD_15M                                           => "load.15m",
    GUEST_INFO_USERS                                              => (1 << 0),
    GUEST_INFO_OS                                                 => (1 << 1),
    GUEST_INFO_TIMEZONE                                           => (1 << 2),
    GUEST_INFO_HOSTNAME                                           => (1 << 3),
    GUEST_INFO_FILESYSTEM                                         => (1 << 4),
    GUEST_INFO_DISKS                                              => (1 << 5),
    GUEST_INFO_INTERFACES                                         => (1 << 6),
    GUEST_INFO_LOAD                                               => (1 << 7),
    AGENT_RESPONSE_TIMEOUT_BLOCK                                  => -2,
    AGENT_RESPONSE_TIMEOUT_DEFAULT                                => -1,
    AGENT_RESPONSE_TIMEOUT_NOWAIT                                 => 0,
    BACKUP_BEGIN_REUSE_EXTERNAL                                   => (1 << 0),
    AUTHORIZED_SSH_KEYS_SET_APPEND                                => (1 << 0),
    AUTHORIZED_SSH_KEYS_SET_REMOVE                                => (1 << 1),
    MESSAGE_DEPRECATION                                           => (1 << 0),
    MESSAGE_TAINTING                                              => (1 << 1),
    MESSAGE_IOERRORS                                              => (1 << 2),
    DIRTYRATE_UNSTARTED                                           => 0,
    DIRTYRATE_MEASURING                                           => 1,
    DIRTYRATE_MEASURED                                            => 2,
    DIRTYRATE_MODE_PAGE_SAMPLING                                  => 0,
    DIRTYRATE_MODE_DIRTY_BITMAP                                   => 1 << 0,
    DIRTYRATE_MODE_DIRTY_RING                                     => 1 << 1,
    FD_ASSOCIATE_SECLABEL_RESTORE                                 => (1 << 0),
    FD_ASSOCIATE_SECLABEL_WRITABLE                                => (1 << 1),
    GRAPHICS_RELOAD_TYPE_ANY                                      => 0,
    GRAPHICS_RELOAD_TYPE_VNC                                      => 1,
};


field $_id :param :reader;
field $_client :param :reader;


# ENTRYPOINT: REMOTE_PROC_DOMAIN_GET_BLOCK_JOB_INFO
async method get_block_job_info($disk, $flags = 0) {
    my $rv = await $_client->_call(
        $remote->PROC_DOMAIN_GET_BLOCK_JOB_INFO,
        { dom => $_id, path => $disk, flags => $flags // 0 } );

    if ($rv->{found}) {
        return $rv;
    }
    else {
        return undef;
    }
}

# ENTRYPOINT: REMOTE_PROC_DOMAIN_GET_EMULATOR_PIN_INFO
async method get_emulator_pin_info($flags = 0) {
    my $maplen = await $_client->_maplen;
    my $rv = await $_client->_call(
        $remote->PROC_DOMAIN_GET_EMULATOR_PIN_INFO,
        { dom => $_id, maplen => $maplen,
          flags => $flags // 0 } );

    if ($rv->{ret} == 0) {
        return undef;
    }
    else {
        return await $_client->_from_cpumap( $rv->{cpumaps} );
    }
}

# ENTRYPOINT: REMOTE_PROC_DOMAIN_GET_IOTHREAD_INFO
async method get_iothread_info($flags = 0) {
    my $rv = await $_client->_call(
        $remote->PROC_DOMAIN_GET_IOTHREAD_INFO,
        { dom => $_id, flags => $flags // 0 } );

    my @rv;
    for my $thread ($rv->{info}->@*) {
        push @rv, {
            iothread_id => $thread->{iothread_id},
            cpumap => await $_client->_from_cpumap( $thread->{cpumap} )
        };
    }

    return \@rv;
}

sub _patch_security_label($sec) {
    my $label = $sec->{label};
    $label = join('', map { chr($_) } $label->@* );
    chop $label; # eliminate terminating ascii \0-char
    $sec->{label} = $label;
}

# ENTRYPOINT: REMOTE_PROC_DOMAIN_GET_SECURITY_LABEL
async method get_security_label() {
    my $rv = await $_client->_call(
        $remote->PROC_DOMAIN_GET_SECURITY_LABEL,
        { dom => $_id } );

    _patch_security_label( $rv );
    return $rv;
}

# ENTRYPOINT: REMOTE_PROC_DOMAIN_GET_SECURITY_LABEL_LIST
async method get_security_label_list() {
    my $rv = await $_client->_call(
        $remote->PROC_DOMAIN_GET_SECURITY_LABEL_LIST,
        { dom => $_id } );

    for my $label ($rv->{labels}->@*) {
        _patch_security_label( $label );
    }

    return $rv->{labels};
}

# ENTRYPOINT: REMOTE_PROC_DOMAIN_GET_TIME
async method get_time($flags = 0) {
    my $rv = await $_client->_call(
        $remote->PROC_DOMAIN_GET_TIME,
        { dom => $_id, flags => $flags // 0 } );

    return ( $rv->{seconds}, $rv->{nseconds} );
}

# ENTRYPOINT: REMOTE_PROC_DOMAIN_GET_VCPU_PIN_INFO
async method get_vcpu_pin_info($flags = 0) {
    my $vcpus  = await $self->get_vcpus_flags( $flags // 0 );
    my $cpus   = await $_client->{totcpus};
    my $maplen = await $_client->_maplen;
    my $rv = await $_client->_call(
        $remote->PROC_DOMAIN_GET_VCPU_PIN_INFO,
        { dom => $_id, ncpumaps => $vcpus,
          maplen => $maplen, flags => $flags });

    my $maps = $rv->{cpumaps};
    my @rv;
    foreach my $vcpu_idx (0 .. ($rv->{num} - 1)) {
        push @rv, await $_client->_from_cpumap( $vcpu_idx*$maplen );
    }

    return \@rv;
}

# ENTRYPOINT: REMOTE_PROC_DOMAIN_GET_VCPUS
async method get_vcpus() {
    my $vcpus  = await $self->get_vcpus_flags;
    my $maplen = await $_client->_maplen;
    my $rv = await $_client->_call(
        $remote->PROC_DOMAIN_GET_VCPUS,
        { dom => $_id, maxinfo => $vcpus, maplen => $maplen } );

    my @rv;
    foreach my $vcpu_idx (0 .. ($vcpus - 1)) {
        push @rv, {
            $rv->{info}->[$vcpu_idx]->%*,
            affinity => await $_client->_from_cpumap( $rv->{cpumaps},
                                                     $vcpu_idx*$maplen ) };
    }

    return \@rv;
}

# ENTRYPOINT: REMOTE_PROC_DOMAIN_PIN_EMULATOR
async method pin_emulator($cpumap, $flags = 0) {
    await $self->_call(
        $remote->PROC_DOMAIN_PIN_EMULATOR,
        { dom => $_id, cpumap => $cpumap,
          flags => $flags // 0 } );
}

method _migrate_perform($cookie, $uri, $flags, $dname, $bandwidth) {
    return $_client->_call(
        $remote->PROC_DOMAIN_MIGRATE_PERFORM,
        { dom => $_id, cookie => $cookie, uri => $uri, flags => $flags // 0, dname => $dname, bandwidth => $bandwidth }, empty => 1 );
}

method abort_job() {
    return $_client->_call(
        $remote->PROC_DOMAIN_ABORT_JOB,
        { dom => $_id }, empty => 1 );
}

method abort_job_flags($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_ABORT_JOB_FLAGS,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

method add_iothread($iothread_id, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_ADD_IOTHREAD,
        { dom => $_id, iothread_id => $iothread_id, flags => $flags // 0 }, empty => 1 );
}

async method agent_set_response_timeout($timeout, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_AGENT_SET_RESPONSE_TIMEOUT,
        { dom => $_id, timeout => $timeout, flags => $flags // 0 }, unwrap => 'result' );
}

method attach_device($xml) {
    return $_client->_call(
        $remote->PROC_DOMAIN_ATTACH_DEVICE,
        { dom => $_id, xml => $xml }, empty => 1 );
}

method attach_device_flags($xml, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_ATTACH_DEVICE_FLAGS,
        { dom => $_id, xml => $xml, flags => $flags // 0 }, empty => 1 );
}

async method authorized_ssh_keys_get($user, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_AUTHORIZED_SSH_KEYS_GET,
        { dom => $_id, user => $user, flags => $flags // 0 }, unwrap => 'keys' );
}

method authorized_ssh_keys_set($user, $keys, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_AUTHORIZED_SSH_KEYS_SET,
        { dom => $_id, user => $user, keys => $keys, flags => $flags // 0 }, empty => 1 );
}

method backup_begin($backup_xml, $checkpoint_xml, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_BACKUP_BEGIN,
        { dom => $_id, backup_xml => $backup_xml, checkpoint_xml => $checkpoint_xml, flags => $flags // 0 }, empty => 1 );
}

async method backup_get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_BACKUP_GET_XML_DESC,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'xml' );
}

method block_commit($disk, $base, $top, $bandwidth, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_COMMIT,
        { dom => $_id, disk => $disk, base => $base, top => $top, bandwidth => $bandwidth, flags => $flags // 0 }, empty => 1 );
}

async method block_copy($path, $destxml, $params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_COPY,
        { dom => $_id, path => $path, destxml => $destxml, params => $params, flags => $flags // 0 }, empty => 1 );
}

method block_job_abort($path, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_JOB_ABORT,
        { dom => $_id, path => $path, flags => $flags // 0 }, empty => 1 );
}

method block_job_set_speed($path, $bandwidth, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_JOB_SET_SPEED,
        { dom => $_id, path => $path, bandwidth => $bandwidth, flags => $flags // 0 }, empty => 1 );
}

async method block_peek($path, $offset, $size, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_PEEK,
        { dom => $_id, path => $path, offset => $offset, size => $size, flags => $flags // 0 }, unwrap => 'buffer' );
}

method block_pull($path, $bandwidth, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_PULL,
        { dom => $_id, path => $path, bandwidth => $bandwidth, flags => $flags // 0 }, empty => 1 );
}

method block_rebase($path, $base, $bandwidth, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_REBASE,
        { dom => $_id, path => $path, base => $base, bandwidth => $bandwidth, flags => $flags // 0 }, empty => 1 );
}

method block_resize($disk, $size, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_RESIZE,
        { dom => $_id, disk => $disk, size => $size, flags => $flags // 0 }, empty => 1 );
}

method block_stats($path) {
    return $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_STATS,
        { dom => $_id, path => $path } );
}

async method block_stats_flags($path, $flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    my $nparams = await $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_STATS_FLAGS,
        { dom => $_id, path => $path, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $_client->_call(
        $remote->PROC_DOMAIN_BLOCK_STATS_FLAGS,
        { dom => $_id, path => $path, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

async method checkpoint_create_xml($xml_desc, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_CHECKPOINT_CREATE_XML,
        { dom => $_id, xml_desc => $xml_desc, flags => $flags // 0 }, unwrap => 'checkpoint' );
}

async method checkpoint_lookup_by_name($name, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_CHECKPOINT_LOOKUP_BY_NAME,
        { dom => $_id, name => $name, flags => $flags // 0 }, unwrap => 'checkpoint' );
}

method core_dump($to, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_CORE_DUMP,
        { dom => $_id, to => $to, flags => $flags // 0 }, empty => 1 );
}

method core_dump_with_format($to, $dumpformat, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_CORE_DUMP_WITH_FORMAT,
        { dom => $_id, to => $to, dumpformat => $dumpformat, flags => $flags // 0 }, empty => 1 );
}

async method create_with_flags($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_CREATE_WITH_FLAGS,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'dom' );
}

method del_iothread($iothread_id, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_DEL_IOTHREAD,
        { dom => $_id, iothread_id => $iothread_id, flags => $flags // 0 }, empty => 1 );
}

method del_throttle_group($group, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_DEL_THROTTLE_GROUP,
        { dom => $_id, group => $group, flags => $flags // 0 }, empty => 1 );
}

method destroy() {
    return $_client->_call(
        $remote->PROC_DOMAIN_DESTROY,
        { dom => $_id }, empty => 1 );
}

method destroy_flags($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_DESTROY_FLAGS,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

method detach_device($xml) {
    return $_client->_call(
        $remote->PROC_DOMAIN_DETACH_DEVICE,
        { dom => $_id, xml => $xml }, empty => 1 );
}

method detach_device_alias($alias, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_DETACH_DEVICE_ALIAS,
        { dom => $_id, alias => $alias, flags => $flags // 0 }, empty => 1 );
}

method detach_device_flags($xml, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_DETACH_DEVICE_FLAGS,
        { dom => $_id, xml => $xml, flags => $flags // 0 }, empty => 1 );
}

async method fsfreeze($mountpoints, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_FSFREEZE,
        { dom => $_id, mountpoints => $mountpoints, flags => $flags // 0 }, unwrap => 'filesystems' );
}

async method fsthaw($mountpoints, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_FSTHAW,
        { dom => $_id, mountpoints => $mountpoints, flags => $flags // 0 }, unwrap => 'filesystems' );
}

method fstrim($mountPoint, $minimum, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_FSTRIM,
        { dom => $_id, mountPoint => $mountPoint, minimum => $minimum, flags => $flags // 0 }, empty => 1 );
}

async method get_autostart() {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_AUTOSTART,
        { dom => $_id }, unwrap => 'autostart' );
}

async method get_autostart_once() {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_AUTOSTART_ONCE,
        { dom => $_id }, unwrap => 'autostart' );
}

async method get_blkio_parameters($flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    my $nparams = await $_client->_call(
        $remote->PROC_DOMAIN_GET_BLKIO_PARAMETERS,
        { dom => $_id, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_BLKIO_PARAMETERS,
        { dom => $_id, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

method get_block_info($path, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_GET_BLOCK_INFO,
        { dom => $_id, path => $path, flags => $flags // 0 } );
}

async method get_block_io_tune($disk, $flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    my $nparams = await $_client->_call(
        $remote->PROC_DOMAIN_GET_BLOCK_IO_TUNE,
        { dom => $_id, disk => $disk, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_BLOCK_IO_TUNE,
        { dom => $_id, disk => $disk, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

method get_control_info($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_GET_CONTROL_INFO,
        { dom => $_id, flags => $flags // 0 } );
}

async method get_cpu_stats($start_cpu, $ncpus, $flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    my $nparams = await $_client->_call(
        $remote->PROC_DOMAIN_GET_CPU_STATS,
        { dom => $_id, nparams => 0, start_cpu => $start_cpu, ncpus => $ncpus, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_CPU_STATS,
        { dom => $_id, nparams => $nparams, start_cpu => $start_cpu, ncpus => $ncpus, flags => $flags // 0 }, unwrap => 'params' );
}

async method get_disk_errors($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_DISK_ERRORS,
        { dom => $_id, maxerrors => $remote->DOMAIN_DISK_ERRORS_MAX, flags => $flags // 0 }, unwrap => 'errors' );
}

async method get_fsinfo($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_FSINFO,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'info' );
}

async method get_guest_info($types, $flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_GUEST_INFO,
        { dom => $_id, types => $types, flags => $flags // 0 }, unwrap => 'params' );
}

async method get_guest_vcpus($flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_GUEST_VCPUS,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'params' );
}

async method get_hostname($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_HOSTNAME,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'hostname' );
}

method get_info() {
    return $_client->_call(
        $remote->PROC_DOMAIN_GET_INFO,
        { dom => $_id } );
}

async method get_interface_parameters($device, $flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    my $nparams = await $_client->_call(
        $remote->PROC_DOMAIN_GET_INTERFACE_PARAMETERS,
        { dom => $_id, device => $device, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_INTERFACE_PARAMETERS,
        { dom => $_id, device => $device, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

method get_job_info() {
    return $_client->_call(
        $remote->PROC_DOMAIN_GET_JOB_INFO,
        { dom => $_id } );
}

method get_job_stats($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_GET_JOB_STATS,
        { dom => $_id, flags => $flags // 0 } );
}

async method get_launch_security_info($flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_LAUNCH_SECURITY_INFO,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'params' );
}

async method get_max_memory() {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_MAX_MEMORY,
        { dom => $_id }, unwrap => 'memory' );
}

async method get_max_vcpus() {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_MAX_VCPUS,
        { dom => $_id }, unwrap => 'num' );
}

async method get_memory_parameters($flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    my $nparams = await $_client->_call(
        $remote->PROC_DOMAIN_GET_MEMORY_PARAMETERS,
        { dom => $_id, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_MEMORY_PARAMETERS,
        { dom => $_id, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

async method get_messages($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_MESSAGES,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'msgs' );
}

async method get_metadata($type, $uri, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_METADATA,
        { dom => $_id, type => $type, uri => $uri, flags => $flags // 0 }, unwrap => 'metadata' );
}

async method get_numa_parameters($flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    my $nparams = await $_client->_call(
        $remote->PROC_DOMAIN_GET_NUMA_PARAMETERS,
        { dom => $_id, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_NUMA_PARAMETERS,
        { dom => $_id, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

async method get_os_type() {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_OS_TYPE,
        { dom => $_id }, unwrap => 'type' );
}

async method get_perf_events($flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_PERF_EVENTS,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'params' );
}

async method get_scheduler_parameters() {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_SCHEDULER_PARAMETERS,
        { dom => $_id, nparams => $remote->DOMAIN_SCHEDULER_PARAMETERS_MAX }, unwrap => 'params' );
}

async method get_scheduler_parameters_flags($flags = 0) {
    $flags |= await $_client->_typed_param_string_okay();
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_SCHEDULER_PARAMETERS_FLAGS,
        { dom => $_id, nparams => $remote->DOMAIN_SCHEDULER_PARAMETERS_MAX, flags => $flags // 0 }, unwrap => 'params' );
}

async method get_scheduler_type() {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_SCHEDULER_TYPE,
        { dom => $_id }, unwrap => 'type' );
}

method get_state($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_GET_STATE,
        { dom => $_id, flags => $flags // 0 } );
}

async method get_vcpus_flags($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_VCPUS_FLAGS,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'num' );
}

async method get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_GET_XML_DESC,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'xml' );
}

method graphics_reload($type, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_GRAPHICS_RELOAD,
        { dom => $_id, type => $type, flags => $flags // 0 }, empty => 1 );
}

async method has_current_snapshot($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_HAS_CURRENT_SNAPSHOT,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'result' );
}

async method has_managed_save_image($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_HAS_MANAGED_SAVE_IMAGE,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'result' );
}

method inject_nmi($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_INJECT_NMI,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

async method interface_addresses($source, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_INTERFACE_ADDRESSES,
        { dom => $_id, source => $source, flags => $flags // 0 }, unwrap => 'ifaces' );
}

method interface_stats($device) {
    return $_client->_call(
        $remote->PROC_DOMAIN_INTERFACE_STATS,
        { dom => $_id, device => $device } );
}

async method is_active() {
    return await $_client->_call(
        $remote->PROC_DOMAIN_IS_ACTIVE,
        { dom => $_id }, unwrap => 'active' );
}

async method is_persistent() {
    return await $_client->_call(
        $remote->PROC_DOMAIN_IS_PERSISTENT,
        { dom => $_id }, unwrap => 'persistent' );
}

async method is_updated() {
    return await $_client->_call(
        $remote->PROC_DOMAIN_IS_UPDATED,
        { dom => $_id }, unwrap => 'updated' );
}

async method list_all_checkpoints($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_LIST_ALL_CHECKPOINTS,
        { dom => $_id, need_results => $remote->DOMAIN_CHECKPOINT_LIST_MAX, flags => $flags // 0 }, unwrap => 'checkpoints' );
}

async method list_all_snapshots($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_LIST_ALL_SNAPSHOTS,
        { dom => $_id, need_results => $remote->DOMAIN_SNAPSHOT_LIST_MAX, flags => $flags // 0 }, unwrap => 'snapshots' );
}

method managed_save($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_MANAGED_SAVE,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

method managed_save_define_xml($dxml, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_MANAGED_SAVE_DEFINE_XML,
        { dom => $_id, dxml => $dxml, flags => $flags // 0 }, empty => 1 );
}

async method managed_save_get_xml_desc($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_MANAGED_SAVE_GET_XML_DESC,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'xml' );
}

method managed_save_remove($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_MANAGED_SAVE_REMOVE,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

async method memory_peek($offset, $size, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_MEMORY_PEEK,
        { dom => $_id, offset => $offset, size => $size, flags => $flags // 0 }, unwrap => 'buffer' );
}

async method memory_stats($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_MEMORY_STATS,
        { dom => $_id, maxStats => $remote->DOMAIN_MEMORY_STATS_MAX, flags => $flags // 0 }, unwrap => 'stats' );
}

async method migrate_get_compression_cache($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_MIGRATE_GET_COMPRESSION_CACHE,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'cacheSize' );
}

async method migrate_get_max_downtime($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_MIGRATE_GET_MAX_DOWNTIME,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'downtime' );
}

async method migrate_get_max_speed($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_MIGRATE_GET_MAX_SPEED,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'bandwidth' );
}

method migrate_set_compression_cache($cacheSize, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_MIGRATE_SET_COMPRESSION_CACHE,
        { dom => $_id, cacheSize => $cacheSize, flags => $flags // 0 }, empty => 1 );
}

method migrate_set_max_downtime($downtime, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_MIGRATE_SET_MAX_DOWNTIME,
        { dom => $_id, downtime => $downtime, flags => $flags // 0 }, empty => 1 );
}

method migrate_set_max_speed($bandwidth, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_MIGRATE_SET_MAX_SPEED,
        { dom => $_id, bandwidth => $bandwidth, flags => $flags // 0 }, empty => 1 );
}

method migrate_start_post_copy($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_MIGRATE_START_POST_COPY,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

method open_channel($name, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_OPEN_CHANNEL,
        { dom => $_id, name => $name, flags => $flags // 0 }, stream => 'read', empty => 1 );
}

method open_console($dev_name, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_OPEN_CONSOLE,
        { dom => $_id, dev_name => $dev_name, flags => $flags // 0 }, stream => 'read', empty => 1 );
}

method pin_iothread($iothreads_id, $cpumap, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_PIN_IOTHREAD,
        { dom => $_id, iothreads_id => $iothreads_id, cpumap => $cpumap, flags => $flags // 0 }, empty => 1 );
}

method pin_vcpu($vcpu, $cpumap) {
    return $_client->_call(
        $remote->PROC_DOMAIN_PIN_VCPU,
        { dom => $_id, vcpu => $vcpu, cpumap => $cpumap }, empty => 1 );
}

method pin_vcpu_flags($vcpu, $cpumap, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_PIN_VCPU_FLAGS,
        { dom => $_id, vcpu => $vcpu, cpumap => $cpumap, flags => $flags // 0 }, empty => 1 );
}

method pm_suspend_for_duration($target, $duration, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_PM_SUSPEND_FOR_DURATION,
        { dom => $_id, target => $target, duration => $duration, flags => $flags // 0 }, empty => 1 );
}

method pm_wakeup($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_PM_WAKEUP,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

method reboot($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_REBOOT,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

async method rename($new_name, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_RENAME,
        { dom => $_id, new_name => $new_name, flags => $flags // 0 }, unwrap => 'retcode' );
}

method reset($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_RESET,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

method resume() {
    return $_client->_call(
        $remote->PROC_DOMAIN_RESUME,
        { dom => $_id }, empty => 1 );
}

method save($to) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SAVE,
        { dom => $_id, to => $to }, empty => 1 );
}

method save_flags($to, $dxml, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SAVE_FLAGS,
        { dom => $_id, to => $to, dxml => $dxml, flags => $flags // 0 }, empty => 1 );
}

async method save_params($params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SAVE_PARAMS,
        { dom => $_id, params => $params, flags => $flags // 0 }, empty => 1 );
}

async method screenshot($screen, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_SCREENSHOT,
        { dom => $_id, screen => $screen, flags => $flags // 0 }, unwrap => 'mime', stream => 'read' );
}

method send_key($codeset, $holdtime, $keycodes, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SEND_KEY,
        { dom => $_id, codeset => $codeset, holdtime => $holdtime, keycodes => $keycodes, flags => $flags // 0 }, empty => 1 );
}

method send_process_signal($pid_value, $signum, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SEND_PROCESS_SIGNAL,
        { dom => $_id, pid_value => $pid_value, signum => $signum, flags => $flags // 0 }, empty => 1 );
}

method set_autostart($autostart) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_AUTOSTART,
        { dom => $_id, autostart => $autostart }, empty => 1 );
}

method set_autostart_once($autostart) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_AUTOSTART_ONCE,
        { dom => $_id, autostart => $autostart }, empty => 1 );
}

async method set_blkio_parameters($params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_BLKIO_PARAMETERS,
        { dom => $_id, params => $params, flags => $flags // 0 }, empty => 1 );
}

async method set_block_io_tune($disk, $params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_BLOCK_IO_TUNE,
        { dom => $_id, disk => $disk, params => $params, flags => $flags // 0 }, empty => 1 );
}

method set_block_threshold($dev, $threshold, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_BLOCK_THRESHOLD,
        { dom => $_id, dev => $dev, threshold => $threshold, flags => $flags // 0 }, empty => 1 );
}

method set_guest_vcpus($cpumap, $state, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_GUEST_VCPUS,
        { dom => $_id, cpumap => $cpumap, state => $state, flags => $flags // 0 }, empty => 1 );
}

async method set_interface_parameters($device, $params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_INTERFACE_PARAMETERS,
        { dom => $_id, device => $device, params => $params, flags => $flags // 0 }, empty => 1 );
}

async method set_iothread_params($iothread_id, $params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_IOTHREAD_PARAMS,
        { dom => $_id, iothread_id => $iothread_id, params => $params, flags => $flags // 0 }, empty => 1 );
}

async method set_launch_security_state($params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_LAUNCH_SECURITY_STATE,
        { dom => $_id, params => $params, flags => $flags // 0 }, empty => 1 );
}

method set_lifecycle_action($type, $action, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_LIFECYCLE_ACTION,
        { dom => $_id, type => $type, action => $action, flags => $flags // 0 }, empty => 1 );
}

method set_max_memory($memory) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_MAX_MEMORY,
        { dom => $_id, memory => $memory }, empty => 1 );
}

method set_memory($memory) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_MEMORY,
        { dom => $_id, memory => $memory }, empty => 1 );
}

method set_memory_flags($memory, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_MEMORY_FLAGS,
        { dom => $_id, memory => $memory, flags => $flags // 0 }, empty => 1 );
}

async method set_memory_parameters($params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_MEMORY_PARAMETERS,
        { dom => $_id, params => $params, flags => $flags // 0 }, empty => 1 );
}

method set_memory_stats_period($period, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_MEMORY_STATS_PERIOD,
        { dom => $_id, period => $period, flags => $flags // 0 }, empty => 1 );
}

method set_metadata($type, $metadata, $key, $uri, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_METADATA,
        { dom => $_id, type => $type, metadata => $metadata, key => $key, uri => $uri, flags => $flags // 0 }, empty => 1 );
}

async method set_numa_parameters($params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_NUMA_PARAMETERS,
        { dom => $_id, params => $params, flags => $flags // 0 }, empty => 1 );
}

async method set_perf_events($params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_PERF_EVENTS,
        { dom => $_id, params => $params, flags => $flags // 0 }, empty => 1 );
}

async method set_scheduler_parameters($params) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_SCHEDULER_PARAMETERS,
        { dom => $_id, params => $params }, empty => 1 );
}

async method set_scheduler_parameters_flags($params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_SCHEDULER_PARAMETERS_FLAGS,
        { dom => $_id, params => $params, flags => $flags // 0 }, empty => 1 );
}

async method set_throttle_group($group, $params, $flags = 0) {
    $params = await $_client->_filter_typed_param_string( $params );
    return await $_client->_call(
        $remote->PROC_DOMAIN_SET_THROTTLE_GROUP,
        { dom => $_id, group => $group, params => $params, flags => $flags // 0 }, empty => 1 );
}

method set_time($seconds, $nseconds, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_TIME,
        { dom => $_id, seconds => $seconds, nseconds => $nseconds, flags => $flags // 0 }, empty => 1 );
}

method set_user_password($user, $password, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_USER_PASSWORD,
        { dom => $_id, user => $user, password => $password, flags => $flags // 0 }, empty => 1 );
}

method set_vcpu($cpumap, $state, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_VCPU,
        { dom => $_id, cpumap => $cpumap, state => $state, flags => $flags // 0 }, empty => 1 );
}

method set_vcpus($nvcpus) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_VCPUS,
        { dom => $_id, nvcpus => $nvcpus }, empty => 1 );
}

method set_vcpus_flags($nvcpus, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SET_VCPUS_FLAGS,
        { dom => $_id, nvcpus => $nvcpus, flags => $flags // 0 }, empty => 1 );
}

method shutdown() {
    return $_client->_call(
        $remote->PROC_DOMAIN_SHUTDOWN,
        { dom => $_id }, empty => 1 );
}

method shutdown_flags($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_SHUTDOWN_FLAGS,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

async method snapshot_create_xml($xml_desc, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_CREATE_XML,
        { dom => $_id, xml_desc => $xml_desc, flags => $flags // 0 }, unwrap => 'snap' );
}

async method snapshot_current($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_CURRENT,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'snap' );
}

async method snapshot_list_names($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_LIST_NAMES,
        { dom => $_id, maxnames => $remote->DOMAIN_SNAPSHOT_LIST_MAX, flags => $flags // 0 }, unwrap => 'names' );
}

async method snapshot_lookup_by_name($name, $flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_LOOKUP_BY_NAME,
        { dom => $_id, name => $name, flags => $flags // 0 }, unwrap => 'snap' );
}

async method snapshot_num($flags = 0) {
    return await $_client->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_NUM,
        { dom => $_id, flags => $flags // 0 }, unwrap => 'num' );
}

method start_dirty_rate_calc($seconds, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_START_DIRTY_RATE_CALC,
        { dom => $_id, seconds => $seconds, flags => $flags // 0 }, empty => 1 );
}

method suspend() {
    return $_client->_call(
        $remote->PROC_DOMAIN_SUSPEND,
        { dom => $_id }, empty => 1 );
}

method undefine() {
    return $_client->_call(
        $remote->PROC_DOMAIN_UNDEFINE,
        { dom => $_id }, empty => 1 );
}

method undefine_flags($flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_UNDEFINE_FLAGS,
        { dom => $_id, flags => $flags // 0 }, empty => 1 );
}

method update_device_flags($xml, $flags = 0) {
    return $_client->_call(
        $remote->PROC_DOMAIN_UPDATE_DEVICE_FLAGS,
        { dom => $_id, xml => $xml, flags => $flags // 0 }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::Domain - Client side proxy to remote LibVirt domain

=head1 VERSION

v0.1.5

=head1 SYNOPSIS

  use Future::AsyncAwait;

  my $dom = await $virt->lookup_domain_by_name( 'domain' );
  await $dom->create;        # -> start domain
  say await $dom->get_state; # "1" ("running")
  await $dom->shutdown;      # -> gracefully shut down domain
  say await $dom->get_state; # "4" ("shutting down")

=head1 DESCRIPTION

Provides access to a domain and its related resources on the server.
The domain may or may not be running.

=head1 EVENTS

Event callbacks can be acquired through
L<Sys::Async::Virt/domain_event_register_any>.

=head1 CONSTRUCTOR

=head2 new

Not to be called directly. Instances are returned from calls
in L<Sys::Async::Virt>.

=head1 METHODS

=head2 get_block_job_info

  $job_info = await $dom->get_block_job_info( $disk );

Returns undef when no job associated with the named block device was found;
otherwise returns a reference to a hash with the fields as documented in the
L<virDomainBlockJobInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockJobInfo>
structure.

See also documentation of L<virDomainGetBlockJobInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetBlockJobInfo>.

=head2 get_emulator_pin_info

  $pins = await $dom->get_emulator_pin_info( $flags );

Returns an array reference with elements being booleans indicating pinning of
the emulator threads to the associated CPU, or C<undef> in case no emulator
threads are pinned.

See also the documentation of L<virDomainGetEmulatorPinInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetEmulatorPinInfo>.

=head2 get_iothread_info

  $iothreads = await $dom->get_iothread_info;

Returns an array of hashes. Each hash has the keys C<iothread_id> and
C<cpumap>. The CPU map is returned as an array of boolean values.

See also documentation of L<virDomainGetIOThreadInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetIOThreadInfo>.

=head2 get_perf_events

  $perf_events = await $dom->get_perf_events;

Returns an array reference where each element in the array is a
L<typed parameter value|Sys::Async::Virt/Typed parameter values>.

=head2 get_time

  ($secs, $nanos) = await $dom->get_time;

Return time extracted from the domain.

See also the documentation of L<virDomainGetTime|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetTime>.

=head2 get_vcpu_pin_info

  $vcpu_pins = await $dom->get_vcpu_pin_info( $flags = 0 );

Returns a reference to an array holding one entry for each vCPU. Each entry is
a reference to an array holding a boolean value for each physical CPU. The
boolean indicates whether the vCPU is allowed to run on that physical CPU
(affinity).

See also the documentation of L<virDomainGetVcpuPinInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetVcpuPinInfo>.

=head2 get_vcpus

  $vcpus = await $dom->get_vcpus;

Returns a reference to an array holding one entry for each vCPU. Each entry is
a reference to a hash with the keys as described in
L<virVcpuInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virVcpuInfo>,
with one extra key C<affinity>, an array of booleans where each element
indicates whether the vCPU is allowed to run on that physical CPU (affinity).

See also the documentation of L<virDomainGetVcpus|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetVcpus>.

=head2 pin_emulator

  await $dom->pin_emulator( $cpumap, $flags )
  # -> (* no data *)

Sets emulator threads to those indicated in C<$cpumap> -- a reference to an array
with boolean values, indicating a true value for each CPU the emulator is allowed
to be scheduled on.

See also the documentation of L<virDomainPinEmulator|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainPinEmulator>.

=head2 abort_job

  await $dom->abort_job;
  # -> (* no data *)

See documentation of L<virDomainAbortJob|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainAbortJob>.


=head2 abort_job_flags

  await $dom->abort_job_flags( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainAbortJobFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainAbortJobFlags>.


=head2 add_iothread

  await $dom->add_iothread( $iothread_id, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainAddIOThread|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainAddIOThread>.


=head2 agent_set_response_timeout

  $result = await $dom->agent_set_response_timeout( $timeout, $flags = 0 );

See documentation of L<virDomainAgentSetResponseTimeout|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainAgentSetResponseTimeout>.


=head2 attach_device

  await $dom->attach_device( $xml );
  # -> (* no data *)

See documentation of L<virDomainAttachDevice|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainAttachDevice>.


=head2 attach_device_flags

  await $dom->attach_device_flags( $xml, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainAttachDeviceFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainAttachDeviceFlags>.


=head2 authorized_ssh_keys_get

  $keys = await $dom->authorized_ssh_keys_get( $user, $flags = 0 );

See documentation of L<virDomainAuthorizedSSHKeysGet|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainAuthorizedSSHKeysGet>.


=head2 authorized_ssh_keys_set

  await $dom->authorized_ssh_keys_set( $user, $keys, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainAuthorizedSSHKeysSet|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainAuthorizedSSHKeysSet>.


=head2 backup_begin

  await $dom->backup_begin( $backup_xml, $checkpoint_xml, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainBackupBegin|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBackupBegin>.


=head2 backup_get_xml_desc

  $xml = await $dom->backup_get_xml_desc( $flags = 0 );

See documentation of L<virDomainBackupGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBackupGetXMLDesc>.


=head2 block_commit

  await $dom->block_commit( $disk, $base, $top, $bandwidth, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainBlockCommit|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockCommit>.


=head2 block_copy

  await $dom->block_copy( $path, $destxml, $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainBlockCopy|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockCopy>.


=head2 block_job_abort

  await $dom->block_job_abort( $path, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainBlockJobAbort|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockJobAbort>.


=head2 block_job_set_speed

  await $dom->block_job_set_speed( $path, $bandwidth, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainBlockJobSetSpeed|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockJobSetSpeed>.


=head2 block_peek

  $buffer = await $dom->block_peek( $path, $offset, $size, $flags = 0 );

See documentation of L<virDomainBlockPeek|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockPeek>.


=head2 block_pull

  await $dom->block_pull( $path, $bandwidth, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainBlockPull|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockPull>.


=head2 block_rebase

  await $dom->block_rebase( $path, $base, $bandwidth, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainBlockRebase|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockRebase>.


=head2 block_resize

  await $dom->block_resize( $disk, $size, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainBlockResize|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockResize>.


=head2 block_stats

  await $dom->block_stats( $path );
  # -> { errs => $errs,
  #      rd_bytes => $rd_bytes,
  #      rd_req => $rd_req,
  #      wr_bytes => $wr_bytes,
  #      wr_req => $wr_req }

See documentation of L<virDomainBlockStats|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockStats>.


=head2 block_stats_flags

  $params = await $dom->block_stats_flags( $path, $flags = 0 );

See documentation of L<virDomainBlockStatsFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainBlockStatsFlags>.


=head2 checkpoint_create_xml

  $checkpoint = await $dom->checkpoint_create_xml( $xml_desc, $flags = 0 );

See documentation of L<virDomainCheckpointCreateXML|https://libvirt.org/html/libvirt-libvirt-domain-checkpoint.html#virDomainCheckpointCreateXML>.


=head2 checkpoint_lookup_by_name

  $checkpoint = await $dom->checkpoint_lookup_by_name( $name, $flags = 0 );

See documentation of L<virDomainCheckpointLookupByName|https://libvirt.org/html/libvirt-libvirt-domain-checkpoint.html#virDomainCheckpointLookupByName>.


=head2 core_dump

  await $dom->core_dump( $to, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainCoreDump|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainCoreDump>.


=head2 core_dump_with_format

  await $dom->core_dump_with_format( $to, $dumpformat, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainCoreDumpWithFormat|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainCoreDumpWithFormat>.


=head2 create_with_flags

  $dom = await $dom->create_with_flags( $flags = 0 );

See documentation of L<virDomainCreateWithFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainCreateWithFlags>.


=head2 del_iothread

  await $dom->del_iothread( $iothread_id, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainDelIOThread|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainDelIOThread>.


=head2 del_throttle_group

  await $dom->del_throttle_group( $group, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainDelThrottleGroup|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainDelThrottleGroup>.


=head2 destroy

  await $dom->destroy;
  # -> (* no data *)

See documentation of L<virDomainDestroy|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainDestroy>.


=head2 destroy_flags

  await $dom->destroy_flags( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainDestroyFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainDestroyFlags>.


=head2 detach_device

  await $dom->detach_device( $xml );
  # -> (* no data *)

See documentation of L<virDomainDetachDevice|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainDetachDevice>.


=head2 detach_device_alias

  await $dom->detach_device_alias( $alias, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainDetachDeviceAlias|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainDetachDeviceAlias>.


=head2 detach_device_flags

  await $dom->detach_device_flags( $xml, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainDetachDeviceFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainDetachDeviceFlags>.


=head2 fsfreeze

  $filesystems = await $dom->fsfreeze( $mountpoints, $flags = 0 );

See documentation of L<virDomainFSFreeze|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainFSFreeze>.


=head2 fsthaw

  $filesystems = await $dom->fsthaw( $mountpoints, $flags = 0 );

See documentation of L<virDomainFSThaw|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainFSThaw>.


=head2 fstrim

  await $dom->fstrim( $mountPoint, $minimum, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainFSTrim|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainFSTrim>.


=head2 get_autostart

  $autostart = await $dom->get_autostart;

See documentation of L<virDomainGetAutostart|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetAutostart>.


=head2 get_autostart_once

  $autostart = await $dom->get_autostart_once;

See documentation of L<virDomainGetAutostartOnce|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetAutostartOnce>.


=head2 get_blkio_parameters

  $params = await $dom->get_blkio_parameters( $flags = 0 );

See documentation of L<virDomainGetBlkioParameters|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetBlkioParameters>.


=head2 get_block_info

  await $dom->get_block_info( $path, $flags = 0 );
  # -> { allocation => $allocation,
  #      capacity => $capacity,
  #      physical => $physical }

See documentation of L<virDomainGetBlockInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetBlockInfo>.


=head2 get_block_io_tune

  $params = await $dom->get_block_io_tune( $disk, $flags = 0 );

See documentation of L<virDomainGetBlockIoTune|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetBlockIoTune>.


=head2 get_control_info

  await $dom->get_control_info( $flags = 0 );
  # -> { details => $details,
  #      state => $state,
  #      stateTime => $stateTime }

See documentation of L<virDomainGetControlInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetControlInfo>.


=head2 get_cpu_stats

  $params = await $dom->get_cpu_stats( $start_cpu, $ncpus, $flags = 0 );

See documentation of L<virDomainGetCPUStats|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetCPUStats>.


=head2 get_disk_errors

  $errors = await $dom->get_disk_errors( $flags = 0 );

See documentation of L<virDomainGetDiskErrors|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetDiskErrors>.


=head2 get_fsinfo

  $info = await $dom->get_fsinfo( $flags = 0 );

See documentation of L<virDomainGetFSInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetFSInfo>.


=head2 get_guest_info

  $params = await $dom->get_guest_info( $types, $flags = 0 );

See documentation of L<virDomainGetGuestInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetGuestInfo>.


=head2 get_guest_vcpus

  $params = await $dom->get_guest_vcpus( $flags = 0 );

See documentation of L<virDomainGetGuestVcpus|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetGuestVcpus>.


=head2 get_hostname

  $hostname = await $dom->get_hostname( $flags = 0 );

See documentation of L<virDomainGetHostname|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetHostname>.


=head2 get_info

  await $dom->get_info;
  # -> { cpuTime => $cpuTime,
  #      maxMem => $maxMem,
  #      memory => $memory,
  #      nrVirtCpu => $nrVirtCpu,
  #      state => $state }

See documentation of L<virDomainGetInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetInfo>.


=head2 get_interface_parameters

  $params = await $dom->get_interface_parameters( $device, $flags = 0 );

See documentation of L<virDomainGetInterfaceParameters|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetInterfaceParameters>.


=head2 get_job_info

  await $dom->get_job_info;
  # -> { dataProcessed => $dataProcessed,
  #      dataRemaining => $dataRemaining,
  #      dataTotal => $dataTotal,
  #      fileProcessed => $fileProcessed,
  #      fileRemaining => $fileRemaining,
  #      fileTotal => $fileTotal,
  #      memProcessed => $memProcessed,
  #      memRemaining => $memRemaining,
  #      memTotal => $memTotal,
  #      timeElapsed => $timeElapsed,
  #      timeRemaining => $timeRemaining,
  #      type => $type }

See documentation of L<virDomainGetJobInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetJobInfo>.


=head2 get_job_stats

  await $dom->get_job_stats( $flags = 0 );
  # -> { params => $params, type => $type }

See documentation of L<virDomainGetJobStats|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetJobStats>.


=head2 get_launch_security_info

  $params = await $dom->get_launch_security_info( $flags = 0 );

See documentation of L<virDomainGetLaunchSecurityInfo|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetLaunchSecurityInfo>.


=head2 get_max_memory

  $memory = await $dom->get_max_memory;

See documentation of L<virDomainGetMaxMemory|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetMaxMemory>.


=head2 get_max_vcpus

  $num = await $dom->get_max_vcpus;

See documentation of L<virDomainGetMaxVcpus|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetMaxVcpus>.


=head2 get_memory_parameters

  $params = await $dom->get_memory_parameters( $flags = 0 );

See documentation of L<virDomainGetMemoryParameters|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetMemoryParameters>.


=head2 get_messages

  $msgs = await $dom->get_messages( $flags = 0 );

See documentation of L<virDomainGetMessages|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetMessages>.


=head2 get_metadata

  $metadata = await $dom->get_metadata( $type, $uri, $flags = 0 );

See documentation of L<virDomainGetMetadata|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetMetadata>.


=head2 get_numa_parameters

  $params = await $dom->get_numa_parameters( $flags = 0 );

See documentation of L<virDomainGetNumaParameters|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetNumaParameters>.


=head2 get_os_type

  $type = await $dom->get_os_type;

See documentation of L<virDomainGetOSType|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetOSType>.


=head2 get_perf_events

  $params = await $dom->get_perf_events( $flags = 0 );

See documentation of L<virDomainGetPerfEvents|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetPerfEvents>.


=head2 get_scheduler_parameters

  $params = await $dom->get_scheduler_parameters;

See documentation of L<virDomainGetSchedulerParameters|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetSchedulerParameters>.


=head2 get_scheduler_parameters_flags

  $params = await $dom->get_scheduler_parameters_flags( $flags = 0 );

See documentation of L<virDomainGetSchedulerParametersFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetSchedulerParametersFlags>.


=head2 get_scheduler_type

  $type = await $dom->get_scheduler_type;

See documentation of L<virDomainGetSchedulerType|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetSchedulerType>.


=head2 get_state

  await $dom->get_state( $flags = 0 );
  # -> { reason => $reason, state => $state }

See documentation of L<virDomainGetState|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetState>.


=head2 get_vcpus_flags

  $num = await $dom->get_vcpus_flags( $flags = 0 );

See documentation of L<virDomainGetVcpusFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetVcpusFlags>.


=head2 get_xml_desc

  $xml = await $dom->get_xml_desc( $flags = 0 );

See documentation of L<virDomainGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGetXMLDesc>.


=head2 graphics_reload

  await $dom->graphics_reload( $type, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainGraphicsReload|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainGraphicsReload>.


=head2 has_current_snapshot

  $result = await $dom->has_current_snapshot( $flags = 0 );

See documentation of L<virDomainHasCurrentSnapshot|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainHasCurrentSnapshot>.


=head2 has_managed_save_image

  $result = await $dom->has_managed_save_image( $flags = 0 );

See documentation of L<virDomainHasManagedSaveImage|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainHasManagedSaveImage>.


=head2 inject_nmi

  await $dom->inject_nmi( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainInjectNMI|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainInjectNMI>.


=head2 interface_addresses

  $ifaces = await $dom->interface_addresses( $source, $flags = 0 );

See documentation of L<virDomainInterfaceAddresses|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainInterfaceAddresses>.


=head2 interface_stats

  await $dom->interface_stats( $device );
  # -> { rx_bytes => $rx_bytes,
  #      rx_drop => $rx_drop,
  #      rx_errs => $rx_errs,
  #      rx_packets => $rx_packets,
  #      tx_bytes => $tx_bytes,
  #      tx_drop => $tx_drop,
  #      tx_errs => $tx_errs,
  #      tx_packets => $tx_packets }

See documentation of L<virDomainInterfaceStats|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainInterfaceStats>.


=head2 is_active

  $active = await $dom->is_active;

See documentation of L<virDomainIsActive|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainIsActive>.


=head2 is_persistent

  $persistent = await $dom->is_persistent;

See documentation of L<virDomainIsPersistent|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainIsPersistent>.


=head2 is_updated

  $updated = await $dom->is_updated;

See documentation of L<virDomainIsUpdated|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainIsUpdated>.


=head2 list_all_checkpoints

  $checkpoints = await $dom->list_all_checkpoints( $flags = 0 );

See documentation of L<virDomainListAllCheckpoints|https://libvirt.org/html/libvirt-libvirt-domain-checkpoint.html#virDomainListAllCheckpoints>.


=head2 list_all_snapshots

  $snapshots = await $dom->list_all_snapshots( $flags = 0 );

See documentation of L<virDomainListAllSnapshots|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainListAllSnapshots>.


=head2 managed_save

  await $dom->managed_save( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainManagedSave|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainManagedSave>.


=head2 managed_save_define_xml

  await $dom->managed_save_define_xml( $dxml, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainManagedSaveDefineXML|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainManagedSaveDefineXML>.


=head2 managed_save_get_xml_desc

  $xml = await $dom->managed_save_get_xml_desc( $flags = 0 );

See documentation of L<virDomainManagedSaveGetXMLDesc|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainManagedSaveGetXMLDesc>.


=head2 managed_save_remove

  await $dom->managed_save_remove( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainManagedSaveRemove|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainManagedSaveRemove>.


=head2 memory_peek

  $buffer = await $dom->memory_peek( $offset, $size, $flags = 0 );

See documentation of L<virDomainMemoryPeek|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainMemoryPeek>.


=head2 memory_stats

  $stats = await $dom->memory_stats( $flags = 0 );

See documentation of L<virDomainMemoryStats|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainMemoryStats>.


=head2 migrate_get_compression_cache

  $cacheSize = await $dom->migrate_get_compression_cache( $flags = 0 );

See documentation of L<virDomainMigrateGetCompressionCache|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainMigrateGetCompressionCache>.


=head2 migrate_get_max_downtime

  $downtime = await $dom->migrate_get_max_downtime( $flags = 0 );

See documentation of L<virDomainMigrateGetMaxDowntime|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainMigrateGetMaxDowntime>.


=head2 migrate_get_max_speed

  $bandwidth = await $dom->migrate_get_max_speed( $flags = 0 );

See documentation of L<virDomainMigrateGetMaxSpeed|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainMigrateGetMaxSpeed>.


=head2 migrate_set_compression_cache

  await $dom->migrate_set_compression_cache( $cacheSize, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainMigrateSetCompressionCache|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainMigrateSetCompressionCache>.


=head2 migrate_set_max_downtime

  await $dom->migrate_set_max_downtime( $downtime, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainMigrateSetMaxDowntime|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainMigrateSetMaxDowntime>.


=head2 migrate_set_max_speed

  await $dom->migrate_set_max_speed( $bandwidth, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainMigrateSetMaxSpeed|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainMigrateSetMaxSpeed>.


=head2 migrate_start_post_copy

  await $dom->migrate_start_post_copy( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainMigrateStartPostCopy|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainMigrateStartPostCopy>.


=head2 open_channel

  $stream = await $dom->open_channel( $name, $flags = 0 );

See documentation of L<virDomainOpenChannel|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainOpenChannel>.


=head2 open_console

  $stream = await $dom->open_console( $dev_name, $flags = 0 );

See documentation of L<virDomainOpenConsole|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainOpenConsole>.


=head2 pin_iothread

  await $dom->pin_iothread( $iothreads_id, $cpumap, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainPinIOThread|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainPinIOThread>.


=head2 pin_vcpu

  await $dom->pin_vcpu( $vcpu, $cpumap );
  # -> (* no data *)

See documentation of L<virDomainPinVcpu|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainPinVcpu>.


=head2 pin_vcpu_flags

  await $dom->pin_vcpu_flags( $vcpu, $cpumap, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainPinVcpuFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainPinVcpuFlags>.


=head2 pm_suspend_for_duration

  await $dom->pm_suspend_for_duration( $target, $duration, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainPMSuspendForDuration|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainPMSuspendForDuration>.


=head2 pm_wakeup

  await $dom->pm_wakeup( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainPMWakeup|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainPMWakeup>.


=head2 reboot

  await $dom->reboot( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainReboot|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainReboot>.


=head2 rename

  $retcode = await $dom->rename( $new_name, $flags = 0 );

See documentation of L<virDomainRename|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainRename>.


=head2 reset

  await $dom->reset( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainReset|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainReset>.


=head2 resume

  await $dom->resume;
  # -> (* no data *)

See documentation of L<virDomainResume|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainResume>.


=head2 save

  await $dom->save( $to );
  # -> (* no data *)

See documentation of L<virDomainSave|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSave>.


=head2 save_flags

  await $dom->save_flags( $to, $dxml, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSaveFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSaveFlags>.


=head2 save_params

  await $dom->save_params( $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSaveParams|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSaveParams>.


=head2 screenshot

  ( $mime, $stream ) = await $dom->screenshot( $screen, $flags = 0 );

See documentation of L<virDomainScreenshot|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainScreenshot>.


=head2 send_key

  await $dom->send_key( $codeset, $holdtime, $keycodes, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSendKey|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSendKey>.


=head2 send_process_signal

  await $dom->send_process_signal( $pid_value, $signum, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSendProcessSignal|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSendProcessSignal>.


=head2 set_autostart

  await $dom->set_autostart( $autostart );
  # -> (* no data *)

See documentation of L<virDomainSetAutostart|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetAutostart>.


=head2 set_autostart_once

  await $dom->set_autostart_once( $autostart );
  # -> (* no data *)

See documentation of L<virDomainSetAutostartOnce|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetAutostartOnce>.


=head2 set_blkio_parameters

  await $dom->set_blkio_parameters( $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetBlkioParameters|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetBlkioParameters>.


=head2 set_block_io_tune

  await $dom->set_block_io_tune( $disk, $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetBlockIoTune|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetBlockIoTune>.


=head2 set_block_threshold

  await $dom->set_block_threshold( $dev, $threshold, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetBlockThreshold|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetBlockThreshold>.


=head2 set_guest_vcpus

  await $dom->set_guest_vcpus( $cpumap, $state, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetGuestVcpus|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetGuestVcpus>.


=head2 set_interface_parameters

  await $dom->set_interface_parameters( $device, $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetInterfaceParameters|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetInterfaceParameters>.


=head2 set_iothread_params

  await $dom->set_iothread_params( $iothread_id, $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetIOThreadParams|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetIOThreadParams>.


=head2 set_launch_security_state

  await $dom->set_launch_security_state( $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetLaunchSecurityState|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetLaunchSecurityState>.


=head2 set_lifecycle_action

  await $dom->set_lifecycle_action( $type, $action, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetLifecycleAction|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetLifecycleAction>.


=head2 set_max_memory

  await $dom->set_max_memory( $memory );
  # -> (* no data *)

See documentation of L<virDomainSetMaxMemory|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetMaxMemory>.


=head2 set_memory

  await $dom->set_memory( $memory );
  # -> (* no data *)

See documentation of L<virDomainSetMemory|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetMemory>.


=head2 set_memory_flags

  await $dom->set_memory_flags( $memory, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetMemoryFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetMemoryFlags>.


=head2 set_memory_parameters

  await $dom->set_memory_parameters( $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetMemoryParameters|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetMemoryParameters>.


=head2 set_memory_stats_period

  await $dom->set_memory_stats_period( $period, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetMemoryStatsPeriod|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetMemoryStatsPeriod>.


=head2 set_metadata

  await $dom->set_metadata( $type, $metadata, $key, $uri, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetMetadata|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetMetadata>.


=head2 set_numa_parameters

  await $dom->set_numa_parameters( $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetNumaParameters|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetNumaParameters>.


=head2 set_perf_events

  await $dom->set_perf_events( $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetPerfEvents|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetPerfEvents>.


=head2 set_scheduler_parameters

  await $dom->set_scheduler_parameters( $params );
  # -> (* no data *)

See documentation of L<virDomainSetSchedulerParameters|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetSchedulerParameters>.


=head2 set_scheduler_parameters_flags

  await $dom->set_scheduler_parameters_flags( $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetSchedulerParametersFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetSchedulerParametersFlags>.


=head2 set_throttle_group

  await $dom->set_throttle_group( $group, $params, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetThrottleGroup|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetThrottleGroup>.


=head2 set_time

  await $dom->set_time( $seconds, $nseconds, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetTime|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetTime>.


=head2 set_user_password

  await $dom->set_user_password( $user, $password, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetUserPassword|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetUserPassword>.


=head2 set_vcpu

  await $dom->set_vcpu( $cpumap, $state, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetVcpu|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetVcpu>.


=head2 set_vcpus

  await $dom->set_vcpus( $nvcpus );
  # -> (* no data *)

See documentation of L<virDomainSetVcpus|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetVcpus>.


=head2 set_vcpus_flags

  await $dom->set_vcpus_flags( $nvcpus, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainSetVcpusFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSetVcpusFlags>.


=head2 shutdown

  await $dom->shutdown;
  # -> (* no data *)

See documentation of L<virDomainShutdown|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainShutdown>.


=head2 shutdown_flags

  await $dom->shutdown_flags( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainShutdownFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainShutdownFlags>.


=head2 snapshot_create_xml

  $snap = await $dom->snapshot_create_xml( $xml_desc, $flags = 0 );

See documentation of L<virDomainSnapshotCreateXML|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotCreateXML>.


=head2 snapshot_current

  $snap = await $dom->snapshot_current( $flags = 0 );

See documentation of L<virDomainSnapshotCurrent|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotCurrent>.


=head2 snapshot_list_names

  $names = await $dom->snapshot_list_names( $flags = 0 );

See documentation of L<virDomainSnapshotListNames|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotListNames>.


=head2 snapshot_lookup_by_name

  $snap = await $dom->snapshot_lookup_by_name( $name, $flags = 0 );

See documentation of L<virDomainSnapshotLookupByName|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotLookupByName>.


=head2 snapshot_num

  $num = await $dom->snapshot_num( $flags = 0 );

See documentation of L<virDomainSnapshotNum|https://libvirt.org/html/libvirt-libvirt-domain-snapshot.html#virDomainSnapshotNum>.


=head2 start_dirty_rate_calc

  await $dom->start_dirty_rate_calc( $seconds, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainStartDirtyRateCalc|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainStartDirtyRateCalc>.


=head2 suspend

  await $dom->suspend;
  # -> (* no data *)

See documentation of L<virDomainSuspend|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainSuspend>.


=head2 undefine

  await $dom->undefine;
  # -> (* no data *)

See documentation of L<virDomainUndefine|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainUndefine>.


=head2 undefine_flags

  await $dom->undefine_flags( $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainUndefineFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainUndefineFlags>.


=head2 update_device_flags

  await $dom->update_device_flags( $xml, $flags = 0 );
  # -> (* no data *)

See documentation of L<virDomainUpdateDeviceFlags|https://libvirt.org/html/libvirt-libvirt-domain.html#virDomainUpdateDeviceFlags>.



=head1 INTERNAL METHODS

=head2 _migrate_perform



=head1 CONSTANTS

=over 8

=item CHECKPOINT_CREATE_REDEFINE

=item CHECKPOINT_CREATE_QUIESCE

=item CHECKPOINT_CREATE_REDEFINE_VALIDATE

=item SNAPSHOT_CREATE_REDEFINE

=item SNAPSHOT_CREATE_CURRENT

=item SNAPSHOT_CREATE_NO_METADATA

=item SNAPSHOT_CREATE_HALT

=item SNAPSHOT_CREATE_DISK_ONLY

=item SNAPSHOT_CREATE_REUSE_EXT

=item SNAPSHOT_CREATE_QUIESCE

=item SNAPSHOT_CREATE_ATOMIC

=item SNAPSHOT_CREATE_LIVE

=item SNAPSHOT_CREATE_VALIDATE

=item NOSTATE

=item RUNNING

=item BLOCKED

=item PAUSED

=item SHUTDOWN

=item SHUTOFF

=item CRASHED

=item PMSUSPENDED

=item NOSTATE_UNKNOWN

=item RUNNING_UNKNOWN

=item RUNNING_BOOTED

=item RUNNING_MIGRATED

=item RUNNING_RESTORED

=item RUNNING_FROM_SNAPSHOT

=item RUNNING_UNPAUSED

=item RUNNING_MIGRATION_CANCELED

=item RUNNING_SAVE_CANCELED

=item RUNNING_WAKEUP

=item RUNNING_CRASHED

=item RUNNING_POSTCOPY

=item RUNNING_POSTCOPY_FAILED

=item BLOCKED_UNKNOWN

=item PAUSED_UNKNOWN

=item PAUSED_USER

=item PAUSED_MIGRATION

=item PAUSED_SAVE

=item PAUSED_DUMP

=item PAUSED_IOERROR

=item PAUSED_WATCHDOG

=item PAUSED_FROM_SNAPSHOT

=item PAUSED_SHUTTING_DOWN

=item PAUSED_SNAPSHOT

=item PAUSED_CRASHED

=item PAUSED_STARTING_UP

=item PAUSED_POSTCOPY

=item PAUSED_POSTCOPY_FAILED

=item PAUSED_API_ERROR

=item SHUTDOWN_UNKNOWN

=item SHUTDOWN_USER

=item SHUTOFF_UNKNOWN

=item SHUTOFF_SHUTDOWN

=item SHUTOFF_DESTROYED

=item SHUTOFF_CRASHED

=item SHUTOFF_MIGRATED

=item SHUTOFF_SAVED

=item SHUTOFF_FAILED

=item SHUTOFF_FROM_SNAPSHOT

=item SHUTOFF_DAEMON

=item CRASHED_UNKNOWN

=item CRASHED_PANICKED

=item PMSUSPENDED_UNKNOWN

=item PMSUSPENDED_DISK_UNKNOWN

=item CONTROL_OK

=item CONTROL_JOB

=item CONTROL_OCCUPIED

=item CONTROL_ERROR

=item CONTROL_ERROR_REASON_NONE

=item CONTROL_ERROR_REASON_UNKNOWN

=item CONTROL_ERROR_REASON_MONITOR

=item CONTROL_ERROR_REASON_INTERNAL

=item AFFECT_CURRENT

=item AFFECT_LIVE

=item AFFECT_CONFIG

=item NONE

=item START_PAUSED

=item START_AUTODESTROY

=item START_BYPASS_CACHE

=item START_FORCE_BOOT

=item START_VALIDATE

=item START_RESET_NVRAM

=item SCHEDULER_CPU_SHARES

=item SCHEDULER_GLOBAL_PERIOD

=item SCHEDULER_GLOBAL_QUOTA

=item SCHEDULER_VCPU_PERIOD

=item SCHEDULER_VCPU_QUOTA

=item SCHEDULER_EMULATOR_PERIOD

=item SCHEDULER_EMULATOR_QUOTA

=item SCHEDULER_IOTHREAD_PERIOD

=item SCHEDULER_IOTHREAD_QUOTA

=item SCHEDULER_WEIGHT

=item SCHEDULER_CAP

=item SCHEDULER_RESERVATION

=item SCHEDULER_LIMIT

=item SCHEDULER_SHARES

=item BLOCK_STATS_FIELD_LENGTH

=item BLOCK_STATS_READ_BYTES

=item BLOCK_STATS_READ_REQ

=item BLOCK_STATS_READ_TOTAL_TIMES

=item BLOCK_STATS_WRITE_BYTES

=item BLOCK_STATS_WRITE_REQ

=item BLOCK_STATS_WRITE_TOTAL_TIMES

=item BLOCK_STATS_FLUSH_REQ

=item BLOCK_STATS_FLUSH_TOTAL_TIMES

=item BLOCK_STATS_ERRS

=item MEMORY_STAT_SWAP_IN

=item MEMORY_STAT_SWAP_OUT

=item MEMORY_STAT_MAJOR_FAULT

=item MEMORY_STAT_MINOR_FAULT

=item MEMORY_STAT_UNUSED

=item MEMORY_STAT_AVAILABLE

=item MEMORY_STAT_ACTUAL_BALLOON

=item MEMORY_STAT_RSS

=item MEMORY_STAT_USABLE

=item MEMORY_STAT_LAST_UPDATE

=item MEMORY_STAT_DISK_CACHES

=item MEMORY_STAT_HUGETLB_PGALLOC

=item MEMORY_STAT_HUGETLB_PGFAIL

=item MEMORY_STAT_NR

=item MEMORY_STAT_LAST

=item DUMP_CRASH

=item DUMP_LIVE

=item DUMP_BYPASS_CACHE

=item DUMP_RESET

=item DUMP_MEMORY_ONLY

=item MIGRATE_LIVE

=item MIGRATE_PEER2PEER

=item MIGRATE_TUNNELLED

=item MIGRATE_PERSIST_DEST

=item MIGRATE_UNDEFINE_SOURCE

=item MIGRATE_PAUSED

=item MIGRATE_NON_SHARED_DISK

=item MIGRATE_NON_SHARED_INC

=item MIGRATE_CHANGE_PROTECTION

=item MIGRATE_UNSAFE

=item MIGRATE_OFFLINE

=item MIGRATE_COMPRESSED

=item MIGRATE_ABORT_ON_ERROR

=item MIGRATE_AUTO_CONVERGE

=item MIGRATE_RDMA_PIN_ALL

=item MIGRATE_POSTCOPY

=item MIGRATE_TLS

=item MIGRATE_PARALLEL

=item MIGRATE_NON_SHARED_SYNCHRONOUS_WRITES

=item MIGRATE_POSTCOPY_RESUME

=item MIGRATE_ZEROCOPY

=item MIGRATE_PARAM_URI

=item MIGRATE_PARAM_DEST_NAME

=item MIGRATE_PARAM_DEST_XML

=item MIGRATE_PARAM_PERSIST_XML

=item MIGRATE_PARAM_BANDWIDTH

=item MIGRATE_PARAM_BANDWIDTH_POSTCOPY

=item MIGRATE_PARAM_BANDWIDTH_AVAIL_SWITCHOVER

=item MIGRATE_PARAM_GRAPHICS_URI

=item MIGRATE_PARAM_LISTEN_ADDRESS

=item MIGRATE_PARAM_MIGRATE_DISKS

=item MIGRATE_PARAM_MIGRATE_DISKS_DETECT_ZEROES

=item MIGRATE_PARAM_DISKS_PORT

=item MIGRATE_PARAM_DISKS_URI

=item MIGRATE_PARAM_COMPRESSION

=item MIGRATE_PARAM_COMPRESSION_MT_LEVEL

=item MIGRATE_PARAM_COMPRESSION_MT_THREADS

=item MIGRATE_PARAM_COMPRESSION_MT_DTHREADS

=item MIGRATE_PARAM_COMPRESSION_XBZRLE_CACHE

=item MIGRATE_PARAM_COMPRESSION_ZLIB_LEVEL

=item MIGRATE_PARAM_COMPRESSION_ZSTD_LEVEL

=item MIGRATE_PARAM_AUTO_CONVERGE_INITIAL

=item MIGRATE_PARAM_AUTO_CONVERGE_INCREMENT

=item MIGRATE_PARAM_PARALLEL_CONNECTIONS

=item MIGRATE_PARAM_TLS_DESTINATION

=item MIGRATE_MAX_SPEED_POSTCOPY

=item SHUTDOWN_DEFAULT

=item SHUTDOWN_ACPI_POWER_BTN

=item SHUTDOWN_GUEST_AGENT

=item SHUTDOWN_INITCTL

=item SHUTDOWN_SIGNAL

=item SHUTDOWN_PARAVIRT

=item REBOOT_DEFAULT

=item REBOOT_ACPI_POWER_BTN

=item REBOOT_GUEST_AGENT

=item REBOOT_INITCTL

=item REBOOT_SIGNAL

=item REBOOT_PARAVIRT

=item DESTROY_DEFAULT

=item DESTROY_GRACEFUL

=item DESTROY_REMOVE_LOGS

=item SAVE_BYPASS_CACHE

=item SAVE_RUNNING

=item SAVE_PAUSED

=item SAVE_RESET_NVRAM

=item SAVE_PARAM_FILE

=item SAVE_PARAM_DXML

=item SAVE_PARAM_IMAGE_FORMAT

=item SAVE_PARAM_PARALLEL_CHANNELS

=item CPU_STATS_CPUTIME

=item CPU_STATS_USERTIME

=item CPU_STATS_SYSTEMTIME

=item CPU_STATS_VCPUTIME

=item BLKIO_WEIGHT

=item BLKIO_DEVICE_WEIGHT

=item BLKIO_DEVICE_READ_IOPS

=item BLKIO_DEVICE_WRITE_IOPS

=item BLKIO_DEVICE_READ_BPS

=item BLKIO_DEVICE_WRITE_BPS

=item MEMORY_PARAM_UNLIMITED

=item MEMORY_HARD_LIMIT

=item MEMORY_SOFT_LIMIT

=item MEMORY_MIN_GUARANTEE

=item MEMORY_SWAP_HARD_LIMIT

=item MEM_CURRENT

=item MEM_LIVE

=item MEM_CONFIG

=item MEM_MAXIMUM

=item NUMATUNE_MEM_STRICT

=item NUMATUNE_MEM_PREFERRED

=item NUMATUNE_MEM_INTERLEAVE

=item NUMATUNE_MEM_RESTRICTIVE

=item NUMA_NODESET

=item NUMA_MODE

=item GET_HOSTNAME_LEASE

=item GET_HOSTNAME_AGENT

=item METADATA_DESCRIPTION

=item METADATA_TITLE

=item METADATA_ELEMENT

=item XML_SECURE

=item XML_INACTIVE

=item XML_UPDATE_CPU

=item XML_MIGRATABLE

=item SAVE_IMAGE_XML_SECURE

=item BANDWIDTH_IN_AVERAGE

=item BANDWIDTH_IN_PEAK

=item BANDWIDTH_IN_BURST

=item BANDWIDTH_IN_FLOOR

=item BANDWIDTH_OUT_AVERAGE

=item BANDWIDTH_OUT_PEAK

=item BANDWIDTH_OUT_BURST

=item BLOCK_RESIZE_BYTES

=item BLOCK_RESIZE_CAPACITY

=item MEMORY_VIRTUAL

=item MEMORY_PHYSICAL

=item UNDEFINE_MANAGED_SAVE

=item UNDEFINE_SNAPSHOTS_METADATA

=item UNDEFINE_NVRAM

=item UNDEFINE_KEEP_NVRAM

=item UNDEFINE_CHECKPOINTS_METADATA

=item UNDEFINE_TPM

=item UNDEFINE_KEEP_TPM

=item VCPU_OFFLINE

=item VCPU_RUNNING

=item VCPU_BLOCKED

=item VCPU_INFO_CPU_OFFLINE

=item VCPU_INFO_CPU_UNAVAILABLE

=item VCPU_CURRENT

=item VCPU_LIVE

=item VCPU_CONFIG

=item VCPU_MAXIMUM

=item VCPU_GUEST

=item VCPU_HOTPLUGGABLE

=item IOTHREAD_POLL_MAX_NS

=item IOTHREAD_POLL_GROW

=item IOTHREAD_POLL_SHRINK

=item IOTHREAD_THREAD_POOL_MIN

=item IOTHREAD_THREAD_POOL_MAX

=item DEVICE_MODIFY_CURRENT

=item DEVICE_MODIFY_LIVE

=item DEVICE_MODIFY_CONFIG

=item DEVICE_MODIFY_FORCE

=item STATS_STATE_STATE

=item STATS_STATE_REASON

=item STATS_CPU_TIME

=item STATS_CPU_USER

=item STATS_CPU_SYSTEM

=item STATS_CPU_HALTPOLL_SUCCESS_TIME

=item STATS_CPU_HALTPOLL_FAIL_TIME

=item STATS_CPU_CACHE_MONITOR_COUNT

=item STATS_CPU_CACHE_MONITOR_PREFIX

=item STATS_CPU_CACHE_MONITOR_SUFFIX_NAME

=item STATS_CPU_CACHE_MONITOR_SUFFIX_VCPUS

=item STATS_CPU_CACHE_MONITOR_SUFFIX_BANK_COUNT

=item STATS_CPU_CACHE_MONITOR_SUFFIX_BANK_PREFIX

=item STATS_CPU_CACHE_MONITOR_SUFFIX_BANK_SUFFIX_ID

=item STATS_CPU_CACHE_MONITOR_SUFFIX_BANK_SUFFIX_BYTES

=item STATS_BALLOON_CURRENT

=item STATS_BALLOON_MAXIMUM

=item STATS_BALLOON_SWAP_IN

=item STATS_BALLOON_SWAP_OUT

=item STATS_BALLOON_MAJOR_FAULT

=item STATS_BALLOON_MINOR_FAULT

=item STATS_BALLOON_UNUSED

=item STATS_BALLOON_AVAILABLE

=item STATS_BALLOON_RSS

=item STATS_BALLOON_USABLE

=item STATS_BALLOON_LAST_UPDATE

=item STATS_BALLOON_DISK_CACHES

=item STATS_BALLOON_HUGETLB_PGALLOC

=item STATS_BALLOON_HUGETLB_PGFAIL

=item STATS_VCPU_CURRENT

=item STATS_VCPU_MAXIMUM

=item STATS_VCPU_PREFIX

=item STATS_VCPU_SUFFIX_STATE

=item STATS_VCPU_SUFFIX_TIME

=item STATS_VCPU_SUFFIX_WAIT

=item STATS_VCPU_SUFFIX_HALTED

=item STATS_VCPU_SUFFIX_DELAY

=item STATS_CUSTOM_SUFFIX_TYPE_CUR

=item STATS_CUSTOM_SUFFIX_TYPE_SUM

=item STATS_CUSTOM_SUFFIX_TYPE_MAX

=item STATS_NET_COUNT

=item STATS_NET_PREFIX

=item STATS_NET_SUFFIX_NAME

=item STATS_NET_SUFFIX_RX_BYTES

=item STATS_NET_SUFFIX_RX_PKTS

=item STATS_NET_SUFFIX_RX_ERRS

=item STATS_NET_SUFFIX_RX_DROP

=item STATS_NET_SUFFIX_TX_BYTES

=item STATS_NET_SUFFIX_TX_PKTS

=item STATS_NET_SUFFIX_TX_ERRS

=item STATS_NET_SUFFIX_TX_DROP

=item STATS_BLOCK_COUNT

=item STATS_BLOCK_PREFIX

=item STATS_BLOCK_SUFFIX_NAME

=item STATS_BLOCK_SUFFIX_BACKINGINDEX

=item STATS_BLOCK_SUFFIX_PATH

=item STATS_BLOCK_SUFFIX_RD_REQS

=item STATS_BLOCK_SUFFIX_RD_BYTES

=item STATS_BLOCK_SUFFIX_RD_TIMES

=item STATS_BLOCK_SUFFIX_WR_REQS

=item STATS_BLOCK_SUFFIX_WR_BYTES

=item STATS_BLOCK_SUFFIX_WR_TIMES

=item STATS_BLOCK_SUFFIX_FL_REQS

=item STATS_BLOCK_SUFFIX_FL_TIMES

=item STATS_BLOCK_SUFFIX_ERRORS

=item STATS_BLOCK_SUFFIX_ALLOCATION

=item STATS_BLOCK_SUFFIX_CAPACITY

=item STATS_BLOCK_SUFFIX_PHYSICAL

=item STATS_BLOCK_SUFFIX_THRESHOLD

=item STATS_PERF_CMT

=item STATS_PERF_MBMT

=item STATS_PERF_MBML

=item STATS_PERF_CACHE_MISSES

=item STATS_PERF_CACHE_REFERENCES

=item STATS_PERF_INSTRUCTIONS

=item STATS_PERF_CPU_CYCLES

=item STATS_PERF_BRANCH_INSTRUCTIONS

=item STATS_PERF_BRANCH_MISSES

=item STATS_PERF_BUS_CYCLES

=item STATS_PERF_STALLED_CYCLES_FRONTEND

=item STATS_PERF_STALLED_CYCLES_BACKEND

=item STATS_PERF_REF_CPU_CYCLES

=item STATS_PERF_CPU_CLOCK

=item STATS_PERF_TASK_CLOCK

=item STATS_PERF_PAGE_FAULTS

=item STATS_PERF_CONTEXT_SWITCHES

=item STATS_PERF_CPU_MIGRATIONS

=item STATS_PERF_PAGE_FAULTS_MIN

=item STATS_PERF_PAGE_FAULTS_MAJ

=item STATS_PERF_ALIGNMENT_FAULTS

=item STATS_PERF_EMULATION_FAULTS

=item STATS_IOTHREAD_COUNT

=item STATS_IOTHREAD_PREFIX

=item STATS_IOTHREAD_SUFFIX_POLL_MAX_NS

=item STATS_IOTHREAD_SUFFIX_POLL_GROW

=item STATS_IOTHREAD_SUFFIX_POLL_SHRINK

=item STATS_MEMORY_BANDWIDTH_MONITOR_COUNT

=item STATS_MEMORY_BANDWIDTH_MONITOR_PREFIX

=item STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NAME

=item STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_VCPUS

=item STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NODE_COUNT

=item STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NODE_PREFIX

=item STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NODE_SUFFIX_ID

=item STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NODE_SUFFIX_BYTES_LOCAL

=item STATS_MEMORY_BANDWIDTH_MONITOR_SUFFIX_NODE_SUFFIX_BYTES_TOTAL

=item STATS_DIRTYRATE_CALC_STATUS

=item STATS_DIRTYRATE_CALC_START_TIME

=item STATS_DIRTYRATE_CALC_PERIOD

=item STATS_DIRTYRATE_MEGABYTES_PER_SECOND

=item STATS_DIRTYRATE_CALC_MODE

=item STATS_DIRTYRATE_VCPU_PREFIX

=item STATS_DIRTYRATE_VCPU_SUFFIX_MEGABYTES_PER_SECOND

=item STATS_VM_PREFIX

=item STATS_STATE

=item STATS_CPU_TOTAL

=item STATS_BALLOON

=item STATS_VCPU

=item STATS_INTERFACE

=item STATS_BLOCK

=item STATS_PERF

=item STATS_IOTHREAD

=item STATS_MEMORY

=item STATS_DIRTYRATE

=item STATS_VM

=item PERF_PARAM_CMT

=item PERF_PARAM_MBMT

=item PERF_PARAM_MBML

=item PERF_PARAM_CACHE_MISSES

=item PERF_PARAM_CACHE_REFERENCES

=item PERF_PARAM_INSTRUCTIONS

=item PERF_PARAM_CPU_CYCLES

=item PERF_PARAM_BRANCH_INSTRUCTIONS

=item PERF_PARAM_BRANCH_MISSES

=item PERF_PARAM_BUS_CYCLES

=item PERF_PARAM_STALLED_CYCLES_FRONTEND

=item PERF_PARAM_STALLED_CYCLES_BACKEND

=item PERF_PARAM_REF_CPU_CYCLES

=item PERF_PARAM_CPU_CLOCK

=item PERF_PARAM_TASK_CLOCK

=item PERF_PARAM_PAGE_FAULTS

=item PERF_PARAM_CONTEXT_SWITCHES

=item PERF_PARAM_CPU_MIGRATIONS

=item PERF_PARAM_PAGE_FAULTS_MIN

=item PERF_PARAM_PAGE_FAULTS_MAJ

=item PERF_PARAM_ALIGNMENT_FAULTS

=item PERF_PARAM_EMULATION_FAULTS

=item BLOCK_JOB_TYPE_UNKNOWN

=item BLOCK_JOB_TYPE_PULL

=item BLOCK_JOB_TYPE_COPY

=item BLOCK_JOB_TYPE_COMMIT

=item BLOCK_JOB_TYPE_ACTIVE_COMMIT

=item BLOCK_JOB_TYPE_BACKUP

=item BLOCK_JOB_ABORT_ASYNC

=item BLOCK_JOB_ABORT_PIVOT

=item BLOCK_JOB_INFO_BANDWIDTH_BYTES

=item BLOCK_JOB_SPEED_BANDWIDTH_BYTES

=item BLOCK_PULL_BANDWIDTH_BYTES

=item BLOCK_REBASE_SHALLOW

=item BLOCK_REBASE_REUSE_EXT

=item BLOCK_REBASE_COPY_RAW

=item BLOCK_REBASE_COPY

=item BLOCK_REBASE_RELATIVE

=item BLOCK_REBASE_COPY_DEV

=item BLOCK_REBASE_BANDWIDTH_BYTES

=item BLOCK_COPY_SHALLOW

=item BLOCK_COPY_REUSE_EXT

=item BLOCK_COPY_TRANSIENT_JOB

=item BLOCK_COPY_SYNCHRONOUS_WRITES

=item BLOCK_COPY_BANDWIDTH

=item BLOCK_COPY_GRANULARITY

=item BLOCK_COPY_BUF_SIZE

=item BLOCK_COMMIT_SHALLOW

=item BLOCK_COMMIT_DELETE

=item BLOCK_COMMIT_ACTIVE

=item BLOCK_COMMIT_RELATIVE

=item BLOCK_COMMIT_BANDWIDTH_BYTES

=item BLOCK_IOTUNE_TOTAL_BYTES_SEC

=item BLOCK_IOTUNE_READ_BYTES_SEC

=item BLOCK_IOTUNE_WRITE_BYTES_SEC

=item BLOCK_IOTUNE_TOTAL_IOPS_SEC

=item BLOCK_IOTUNE_READ_IOPS_SEC

=item BLOCK_IOTUNE_WRITE_IOPS_SEC

=item BLOCK_IOTUNE_TOTAL_BYTES_SEC_MAX

=item BLOCK_IOTUNE_READ_BYTES_SEC_MAX

=item BLOCK_IOTUNE_WRITE_BYTES_SEC_MAX

=item BLOCK_IOTUNE_TOTAL_IOPS_SEC_MAX

=item BLOCK_IOTUNE_READ_IOPS_SEC_MAX

=item BLOCK_IOTUNE_WRITE_IOPS_SEC_MAX

=item BLOCK_IOTUNE_TOTAL_BYTES_SEC_MAX_LENGTH

=item BLOCK_IOTUNE_READ_BYTES_SEC_MAX_LENGTH

=item BLOCK_IOTUNE_WRITE_BYTES_SEC_MAX_LENGTH

=item BLOCK_IOTUNE_TOTAL_IOPS_SEC_MAX_LENGTH

=item BLOCK_IOTUNE_READ_IOPS_SEC_MAX_LENGTH

=item BLOCK_IOTUNE_WRITE_IOPS_SEC_MAX_LENGTH

=item BLOCK_IOTUNE_SIZE_IOPS_SEC

=item BLOCK_IOTUNE_GROUP_NAME

=item DISK_ERROR_NONE

=item DISK_ERROR_UNSPEC

=item DISK_ERROR_NO_SPACE

=item KEYCODE_SET_LINUX

=item KEYCODE_SET_XT

=item KEYCODE_SET_ATSET1

=item KEYCODE_SET_ATSET2

=item KEYCODE_SET_ATSET3

=item KEYCODE_SET_OSX

=item KEYCODE_SET_XT_KBD

=item KEYCODE_SET_USB

=item KEYCODE_SET_WIN32

=item KEYCODE_SET_QNUM

=item KEYCODE_SET_RFB

=item SEND_KEY_MAX_KEYS

=item PROCESS_SIGNAL_NOP

=item PROCESS_SIGNAL_HUP

=item PROCESS_SIGNAL_INT

=item PROCESS_SIGNAL_QUIT

=item PROCESS_SIGNAL_ILL

=item PROCESS_SIGNAL_TRAP

=item PROCESS_SIGNAL_ABRT

=item PROCESS_SIGNAL_BUS

=item PROCESS_SIGNAL_FPE

=item PROCESS_SIGNAL_KILL

=item PROCESS_SIGNAL_USR1

=item PROCESS_SIGNAL_SEGV

=item PROCESS_SIGNAL_USR2

=item PROCESS_SIGNAL_PIPE

=item PROCESS_SIGNAL_ALRM

=item PROCESS_SIGNAL_TERM

=item PROCESS_SIGNAL_STKFLT

=item PROCESS_SIGNAL_CHLD

=item PROCESS_SIGNAL_CONT

=item PROCESS_SIGNAL_STOP

=item PROCESS_SIGNAL_TSTP

=item PROCESS_SIGNAL_TTIN

=item PROCESS_SIGNAL_TTOU

=item PROCESS_SIGNAL_URG

=item PROCESS_SIGNAL_XCPU

=item PROCESS_SIGNAL_XFSZ

=item PROCESS_SIGNAL_VTALRM

=item PROCESS_SIGNAL_PROF

=item PROCESS_SIGNAL_WINCH

=item PROCESS_SIGNAL_POLL

=item PROCESS_SIGNAL_PWR

=item PROCESS_SIGNAL_SYS

=item PROCESS_SIGNAL_RT0

=item PROCESS_SIGNAL_RT1

=item PROCESS_SIGNAL_RT2

=item PROCESS_SIGNAL_RT3

=item PROCESS_SIGNAL_RT4

=item PROCESS_SIGNAL_RT5

=item PROCESS_SIGNAL_RT6

=item PROCESS_SIGNAL_RT7

=item PROCESS_SIGNAL_RT8

=item PROCESS_SIGNAL_RT9

=item PROCESS_SIGNAL_RT10

=item PROCESS_SIGNAL_RT11

=item PROCESS_SIGNAL_RT12

=item PROCESS_SIGNAL_RT13

=item PROCESS_SIGNAL_RT14

=item PROCESS_SIGNAL_RT15

=item PROCESS_SIGNAL_RT16

=item PROCESS_SIGNAL_RT17

=item PROCESS_SIGNAL_RT18

=item PROCESS_SIGNAL_RT19

=item PROCESS_SIGNAL_RT20

=item PROCESS_SIGNAL_RT21

=item PROCESS_SIGNAL_RT22

=item PROCESS_SIGNAL_RT23

=item PROCESS_SIGNAL_RT24

=item PROCESS_SIGNAL_RT25

=item PROCESS_SIGNAL_RT26

=item PROCESS_SIGNAL_RT27

=item PROCESS_SIGNAL_RT28

=item PROCESS_SIGNAL_RT29

=item PROCESS_SIGNAL_RT30

=item PROCESS_SIGNAL_RT31

=item PROCESS_SIGNAL_RT32

=item EVENT_DEFINED

=item EVENT_UNDEFINED

=item EVENT_STARTED

=item EVENT_SUSPENDED

=item EVENT_RESUMED

=item EVENT_STOPPED

=item EVENT_SHUTDOWN

=item EVENT_PMSUSPENDED

=item EVENT_CRASHED

=item EVENT_DEFINED_ADDED

=item EVENT_DEFINED_UPDATED

=item EVENT_DEFINED_RENAMED

=item EVENT_DEFINED_FROM_SNAPSHOT

=item EVENT_UNDEFINED_REMOVED

=item EVENT_UNDEFINED_RENAMED

=item EVENT_STARTED_BOOTED

=item EVENT_STARTED_MIGRATED

=item EVENT_STARTED_RESTORED

=item EVENT_STARTED_FROM_SNAPSHOT

=item EVENT_STARTED_WAKEUP

=item EVENT_STARTED_RECREATED

=item EVENT_SUSPENDED_PAUSED

=item EVENT_SUSPENDED_MIGRATED

=item EVENT_SUSPENDED_IOERROR

=item EVENT_SUSPENDED_WATCHDOG

=item EVENT_SUSPENDED_RESTORED

=item EVENT_SUSPENDED_FROM_SNAPSHOT

=item EVENT_SUSPENDED_API_ERROR

=item EVENT_SUSPENDED_POSTCOPY

=item EVENT_SUSPENDED_POSTCOPY_FAILED

=item EVENT_RESUMED_UNPAUSED

=item EVENT_RESUMED_MIGRATED

=item EVENT_RESUMED_FROM_SNAPSHOT

=item EVENT_RESUMED_POSTCOPY

=item EVENT_RESUMED_POSTCOPY_FAILED

=item EVENT_STOPPED_SHUTDOWN

=item EVENT_STOPPED_DESTROYED

=item EVENT_STOPPED_CRASHED

=item EVENT_STOPPED_MIGRATED

=item EVENT_STOPPED_SAVED

=item EVENT_STOPPED_FAILED

=item EVENT_STOPPED_FROM_SNAPSHOT

=item EVENT_STOPPED_RECREATED

=item EVENT_SHUTDOWN_FINISHED

=item EVENT_SHUTDOWN_GUEST

=item EVENT_SHUTDOWN_HOST

=item EVENT_PMSUSPENDED_MEMORY

=item EVENT_PMSUSPENDED_DISK

=item EVENT_CRASHED_PANICKED

=item EVENT_CRASHED_CRASHLOADED

=item EVENT_MEMORY_FAILURE_RECIPIENT_HYPERVISOR

=item EVENT_MEMORY_FAILURE_RECIPIENT_GUEST

=item EVENT_MEMORY_FAILURE_ACTION_IGNORE

=item EVENT_MEMORY_FAILURE_ACTION_INJECT

=item EVENT_MEMORY_FAILURE_ACTION_FATAL

=item EVENT_MEMORY_FAILURE_ACTION_RESET

=item MEMORY_FAILURE_ACTION_REQUIRED

=item MEMORY_FAILURE_RECURSIVE

=item JOB_NONE

=item JOB_BOUNDED

=item JOB_UNBOUNDED

=item JOB_COMPLETED

=item JOB_FAILED

=item JOB_CANCELLED

=item JOB_STATS_COMPLETED

=item JOB_STATS_KEEP_COMPLETED

=item ABORT_JOB_POSTCOPY

=item JOB_OPERATION_UNKNOWN

=item JOB_OPERATION_START

=item JOB_OPERATION_SAVE

=item JOB_OPERATION_RESTORE

=item JOB_OPERATION_MIGRATION_IN

=item JOB_OPERATION_MIGRATION_OUT

=item JOB_OPERATION_SNAPSHOT

=item JOB_OPERATION_SNAPSHOT_REVERT

=item JOB_OPERATION_DUMP

=item JOB_OPERATION_BACKUP

=item JOB_OPERATION_SNAPSHOT_DELETE

=item JOB_OPERATION

=item JOB_TIME_ELAPSED

=item JOB_TIME_ELAPSED_NET

=item JOB_TIME_REMAINING

=item JOB_DOWNTIME

=item JOB_DOWNTIME_NET

=item JOB_SETUP_TIME

=item JOB_DATA_TOTAL

=item JOB_DATA_PROCESSED

=item JOB_DATA_REMAINING

=item JOB_MEMORY_TOTAL

=item JOB_MEMORY_PROCESSED

=item JOB_MEMORY_REMAINING

=item JOB_MEMORY_CONSTANT

=item JOB_MEMORY_NORMAL

=item JOB_MEMORY_NORMAL_BYTES

=item JOB_MEMORY_BPS

=item JOB_MEMORY_DIRTY_RATE

=item JOB_MEMORY_PAGE_SIZE

=item JOB_MEMORY_ITERATION

=item JOB_MEMORY_POSTCOPY_REQS

=item JOB_DISK_TOTAL

=item JOB_DISK_PROCESSED

=item JOB_DISK_REMAINING

=item JOB_DISK_BPS

=item JOB_COMPRESSION_CACHE

=item JOB_COMPRESSION_BYTES

=item JOB_COMPRESSION_PAGES

=item JOB_COMPRESSION_CACHE_MISSES

=item JOB_COMPRESSION_OVERFLOW

=item JOB_AUTO_CONVERGE_THROTTLE

=item JOB_SUCCESS

=item JOB_ERRMSG

=item JOB_DISK_TEMP_USED

=item JOB_DISK_TEMP_TOTAL

=item JOB_VFIO_DATA_TRANSFERRED

=item EVENT_WATCHDOG_NONE

=item EVENT_IO_ERROR_NONE

=item EVENT_GRAPHICS_CONNECT

=item BLOCK_JOB_COMPLETED

=item BLOCK_JOB_FAILED

=item BLOCK_JOB_CANCELED

=item BLOCK_JOB_READY

=item EVENT_DISK_CHANGE_MISSING_ON_START

=item EVENT_DISK_DROP_MISSING_ON_START

=item EVENT_TRAY_CHANGE_OPEN

=item TUNABLE_CPU_VCPUPIN

=item TUNABLE_CPU_EMULATORPIN

=item TUNABLE_CPU_IOTHREADSPIN

=item TUNABLE_CPU_CPU_SHARES

=item TUNABLE_CPU_GLOBAL_PERIOD

=item TUNABLE_CPU_GLOBAL_QUOTA

=item TUNABLE_CPU_VCPU_PERIOD

=item TUNABLE_CPU_VCPU_QUOTA

=item TUNABLE_CPU_EMULATOR_PERIOD

=item TUNABLE_CPU_EMULATOR_QUOTA

=item TUNABLE_CPU_IOTHREAD_PERIOD

=item TUNABLE_CPU_IOTHREAD_QUOTA

=item TUNABLE_BLKDEV_DISK

=item TUNABLE_BLKDEV_TOTAL_BYTES_SEC

=item TUNABLE_BLKDEV_READ_BYTES_SEC

=item TUNABLE_BLKDEV_WRITE_BYTES_SEC

=item TUNABLE_BLKDEV_TOTAL_IOPS_SEC

=item TUNABLE_BLKDEV_READ_IOPS_SEC

=item TUNABLE_BLKDEV_WRITE_IOPS_SEC

=item TUNABLE_BLKDEV_TOTAL_BYTES_SEC_MAX

=item TUNABLE_BLKDEV_READ_BYTES_SEC_MAX

=item TUNABLE_BLKDEV_WRITE_BYTES_SEC_MAX

=item TUNABLE_BLKDEV_TOTAL_IOPS_SEC_MAX

=item TUNABLE_BLKDEV_READ_IOPS_SEC_MAX

=item TUNABLE_BLKDEV_WRITE_IOPS_SEC_MAX

=item TUNABLE_BLKDEV_SIZE_IOPS_SEC

=item TUNABLE_BLKDEV_GROUP_NAME

=item TUNABLE_BLKDEV_TOTAL_BYTES_SEC_MAX_LENGTH

=item TUNABLE_BLKDEV_READ_BYTES_SEC_MAX_LENGTH

=item TUNABLE_BLKDEV_WRITE_BYTES_SEC_MAX_LENGTH

=item TUNABLE_BLKDEV_TOTAL_IOPS_SEC_MAX_LENGTH

=item TUNABLE_BLKDEV_READ_IOPS_SEC_MAX_LENGTH

=item TUNABLE_BLKDEV_WRITE_IOPS_SEC_MAX_LENGTH

=item CONSOLE_FORCE

=item CONSOLE_SAFE

=item CHANNEL_FORCE

=item OPEN_GRAPHICS_SKIPAUTH

=item TIME_SYNC

=item SCHED_FIELD_INT

=item SCHED_FIELD_UINT

=item SCHED_FIELD_LLONG

=item SCHED_FIELD_ULLONG

=item SCHED_FIELD_DOUBLE

=item SCHED_FIELD_BOOLEAN

=item SCHED_FIELD_LENGTH

=item BLKIO_PARAM_INT

=item BLKIO_PARAM_UINT

=item BLKIO_PARAM_LLONG

=item BLKIO_PARAM_ULLONG

=item BLKIO_PARAM_DOUBLE

=item BLKIO_PARAM_BOOLEAN

=item BLKIO_FIELD_LENGTH

=item MEMORY_PARAM_INT

=item MEMORY_PARAM_UINT

=item MEMORY_PARAM_LLONG

=item MEMORY_PARAM_ULLONG

=item MEMORY_PARAM_DOUBLE

=item MEMORY_PARAM_BOOLEAN

=item MEMORY_FIELD_LENGTH

=item INTERFACE_ADDRESSES_SRC_LEASE

=item INTERFACE_ADDRESSES_SRC_AGENT

=item INTERFACE_ADDRESSES_SRC_ARP

=item PASSWORD_ENCRYPTED

=item LIFECYCLE_POWEROFF

=item LIFECYCLE_REBOOT

=item LIFECYCLE_CRASH

=item LIFECYCLE_ACTION_DESTROY

=item LIFECYCLE_ACTION_RESTART

=item LIFECYCLE_ACTION_RESTART_RENAME

=item LIFECYCLE_ACTION_PRESERVE

=item LIFECYCLE_ACTION_COREDUMP_DESTROY

=item LIFECYCLE_ACTION_COREDUMP_RESTART

=item LAUNCH_SECURITY_SEV_MEASUREMENT

=item LAUNCH_SECURITY_SEV_API_MAJOR

=item LAUNCH_SECURITY_SEV_API_MINOR

=item LAUNCH_SECURITY_SEV_BUILD_ID

=item LAUNCH_SECURITY_SEV_POLICY

=item LAUNCH_SECURITY_SEV_SNP_POLICY

=item LAUNCH_SECURITY_SEV_SECRET_HEADER

=item LAUNCH_SECURITY_SEV_SECRET

=item LAUNCH_SECURITY_SEV_SECRET_SET_ADDRESS

=item GUEST_INFO_USER_COUNT

=item GUEST_INFO_USER_PREFIX

=item GUEST_INFO_USER_SUFFIX_NAME

=item GUEST_INFO_USER_SUFFIX_DOMAIN

=item GUEST_INFO_USER_SUFFIX_LOGIN_TIME

=item GUEST_INFO_OS_ID

=item GUEST_INFO_OS_NAME

=item GUEST_INFO_OS_PRETTY_NAME

=item GUEST_INFO_OS_VERSION

=item GUEST_INFO_OS_VERSION_ID

=item GUEST_INFO_OS_KERNEL_RELEASE

=item GUEST_INFO_OS_KERNEL_VERSION

=item GUEST_INFO_OS_MACHINE

=item GUEST_INFO_OS_VARIANT

=item GUEST_INFO_OS_VARIANT_ID

=item GUEST_INFO_TIMEZONE_NAME

=item GUEST_INFO_TIMEZONE_OFFSET

=item GUEST_INFO_HOSTNAME_HOSTNAME

=item GUEST_INFO_FS_COUNT

=item GUEST_INFO_FS_PREFIX

=item GUEST_INFO_FS_SUFFIX_MOUNTPOINT

=item GUEST_INFO_FS_SUFFIX_NAME

=item GUEST_INFO_FS_SUFFIX_FSTYPE

=item GUEST_INFO_FS_SUFFIX_TOTAL_BYTES

=item GUEST_INFO_FS_SUFFIX_USED_BYTES

=item GUEST_INFO_FS_SUFFIX_DISK_COUNT

=item GUEST_INFO_FS_SUFFIX_DISK_PREFIX

=item GUEST_INFO_FS_SUFFIX_DISK_SUFFIX_ALIAS

=item GUEST_INFO_FS_SUFFIX_DISK_SUFFIX_SERIAL

=item GUEST_INFO_FS_SUFFIX_DISK_SUFFIX_DEVICE

=item GUEST_INFO_DISK_COUNT

=item GUEST_INFO_DISK_PREFIX

=item GUEST_INFO_DISK_SUFFIX_NAME

=item GUEST_INFO_DISK_SUFFIX_PARTITION

=item GUEST_INFO_DISK_SUFFIX_DEPENDENCY_COUNT

=item GUEST_INFO_DISK_SUFFIX_DEPENDENCY_PREFIX

=item GUEST_INFO_DISK_SUFFIX_DEPENDENCY_SUFFIX_NAME

=item GUEST_INFO_DISK_SUFFIX_SERIAL

=item GUEST_INFO_DISK_SUFFIX_ALIAS

=item GUEST_INFO_DISK_SUFFIX_GUEST_ALIAS

=item GUEST_INFO_DISK_SUFFIX_GUEST_BUS

=item GUEST_INFO_IF_COUNT

=item GUEST_INFO_IF_PREFIX

=item GUEST_INFO_IF_SUFFIX_NAME

=item GUEST_INFO_IF_SUFFIX_HWADDR

=item GUEST_INFO_IF_SUFFIX_ADDR_COUNT

=item GUEST_INFO_IF_SUFFIX_ADDR_PREFIX

=item GUEST_INFO_IF_SUFFIX_ADDR_SUFFIX_TYPE

=item GUEST_INFO_IF_SUFFIX_ADDR_SUFFIX_ADDR

=item GUEST_INFO_IF_SUFFIX_ADDR_SUFFIX_PREFIX

=item GUEST_INFO_LOAD_1M

=item GUEST_INFO_LOAD_5M

=item GUEST_INFO_LOAD_15M

=item GUEST_INFO_USERS

=item GUEST_INFO_OS

=item GUEST_INFO_TIMEZONE

=item GUEST_INFO_HOSTNAME

=item GUEST_INFO_FILESYSTEM

=item GUEST_INFO_DISKS

=item GUEST_INFO_INTERFACES

=item GUEST_INFO_LOAD

=item AGENT_RESPONSE_TIMEOUT_BLOCK

=item AGENT_RESPONSE_TIMEOUT_DEFAULT

=item AGENT_RESPONSE_TIMEOUT_NOWAIT

=item BACKUP_BEGIN_REUSE_EXTERNAL

=item AUTHORIZED_SSH_KEYS_SET_APPEND

=item AUTHORIZED_SSH_KEYS_SET_REMOVE

=item MESSAGE_DEPRECATION

=item MESSAGE_TAINTING

=item MESSAGE_IOERRORS

=item DIRTYRATE_UNSTARTED

=item DIRTYRATE_MEASURING

=item DIRTYRATE_MEASURED

=item DIRTYRATE_MODE_PAGE_SAMPLING

=item DIRTYRATE_MODE_DIRTY_BITMAP

=item DIRTYRATE_MODE_DIRTY_RING

=item FD_ASSOCIATE_SECLABEL_RESTORE

=item FD_ASSOCIATE_SECLABEL_WRITABLE

=item GRAPHICS_RELOAD_TYPE_ANY

=item GRAPHICS_RELOAD_TYPE_VNC

=back

=head1 BUGS AND LIMITATIONS

=head2 Unimplemented entry points

The following entry points have intentionally not been implemented,
because they are deprecated or contain bugs.

=over 8

=item * REMOTE_PROC_DOMAIN_CREATE (virDomainCreate)

This entry point contains a bug in the protocol definition; use
L</domain_create_flags> without flags (i.e. C<< $dom->domain_create_flags; >>)
to achieve the same effect.

=back

=begin fill-templates

# ENTRYPOINT: REMOTE_PROC_DOMAIN_CREATE

=end fill-templates

=head1 SEE ALSO

L<LibVirt|https://libvirt.org>, L<Sys::Virt>

=head1 LICENSE AND COPYRIGHT


  Copyright (C) 2024-2025 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
