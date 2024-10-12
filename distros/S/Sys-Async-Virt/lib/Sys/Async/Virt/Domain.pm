####################################################################
#
#     This file was generated using XDR::Parse version v0.3.1
#                   and LibVirt version v10.3.0
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

package Sys::Async::Virt::Domain v0.0.11;

use Carp qw(croak);
use Log::Any qw($log);

use Protocol::Sys::Virt::Remote::XDR v0.0.11;
my $remote = 'Protocol::Sys::Virt::Remote::XDR';

use constant {
    CHECKPOINT_CREATE_REDEFINE                => (1 << 0),
    CHECKPOINT_CREATE_QUIESCE                 => (1 << 1),
    CHECKPOINT_CREATE_REDEFINE_VALIDATE       => (1 << 2),
    SNAPSHOT_CREATE_REDEFINE                  => (1 << 0),
    SNAPSHOT_CREATE_CURRENT                   => (1 << 1),
    SNAPSHOT_CREATE_NO_METADATA               => (1 << 2),
    SNAPSHOT_CREATE_HALT                      => (1 << 3),
    SNAPSHOT_CREATE_DISK_ONLY                 => (1 << 4),
    SNAPSHOT_CREATE_REUSE_EXT                 => (1 << 5),
    SNAPSHOT_CREATE_QUIESCE                   => (1 << 6),
    SNAPSHOT_CREATE_ATOMIC                    => (1 << 7),
    SNAPSHOT_CREATE_LIVE                      => (1 << 8),
    SNAPSHOT_CREATE_VALIDATE                  => (1 << 9),
    NOSTATE                                   => 0,
    RUNNING                                   => 1,
    BLOCKED                                   => 2,
    PAUSED                                    => 3,
    SHUTDOWN                                  => 4,
    SHUTOFF                                   => 5,
    CRASHED                                   => 6,
    PMSUSPENDED                               => 7,
    NOSTATE_UNKNOWN                           => 0,
    RUNNING_UNKNOWN                           => 0,
    RUNNING_BOOTED                            => 1,
    RUNNING_MIGRATED                          => 2,
    RUNNING_RESTORED                          => 3,
    RUNNING_FROM_SNAPSHOT                     => 4,
    RUNNING_UNPAUSED                          => 5,
    RUNNING_MIGRATION_CANCELED                => 6,
    RUNNING_SAVE_CANCELED                     => 7,
    RUNNING_WAKEUP                            => 8,
    RUNNING_CRASHED                           => 9,
    RUNNING_POSTCOPY                          => 10,
    RUNNING_POSTCOPY_FAILED                   => 11,
    BLOCKED_UNKNOWN                           => 0,
    PAUSED_UNKNOWN                            => 0,
    PAUSED_USER                               => 1,
    PAUSED_MIGRATION                          => 2,
    PAUSED_SAVE                               => 3,
    PAUSED_DUMP                               => 4,
    PAUSED_IOERROR                            => 5,
    PAUSED_WATCHDOG                           => 6,
    PAUSED_FROM_SNAPSHOT                      => 7,
    PAUSED_SHUTTING_DOWN                      => 8,
    PAUSED_SNAPSHOT                           => 9,
    PAUSED_CRASHED                            => 10,
    PAUSED_STARTING_UP                        => 11,
    PAUSED_POSTCOPY                           => 12,
    PAUSED_POSTCOPY_FAILED                    => 13,
    PAUSED_API_ERROR                          => 14,
    SHUTDOWN_UNKNOWN                          => 0,
    SHUTDOWN_USER                             => 1,
    SHUTOFF_UNKNOWN                           => 0,
    SHUTOFF_SHUTDOWN                          => 1,
    SHUTOFF_DESTROYED                         => 2,
    SHUTOFF_CRASHED                           => 3,
    SHUTOFF_MIGRATED                          => 4,
    SHUTOFF_SAVED                             => 5,
    SHUTOFF_FAILED                            => 6,
    SHUTOFF_FROM_SNAPSHOT                     => 7,
    SHUTOFF_DAEMON                            => 8,
    CRASHED_UNKNOWN                           => 0,
    CRASHED_PANICKED                          => 1,
    PMSUSPENDED_UNKNOWN                       => 0,
    PMSUSPENDED_DISK_UNKNOWN                  => 0,
    CONTROL_OK                                => 0,
    CONTROL_JOB                               => 1,
    CONTROL_OCCUPIED                          => 2,
    CONTROL_ERROR                             => 3,
    CONTROL_ERROR_REASON_NONE                 => 0,
    CONTROL_ERROR_REASON_UNKNOWN              => 1,
    CONTROL_ERROR_REASON_MONITOR              => 2,
    CONTROL_ERROR_REASON_INTERNAL             => 3,
    AFFECT_CURRENT                            => 0,
    AFFECT_LIVE                               => 1 << 0,
    AFFECT_CONFIG                             => 1 << 1,
    NONE                                      => 0,
    START_PAUSED                              => 1 << 0,
    START_AUTODESTROY                         => 1 << 1,
    START_BYPASS_CACHE                        => 1 << 2,
    START_FORCE_BOOT                          => 1 << 3,
    START_VALIDATE                            => 1 << 4,
    START_RESET_NVRAM                         => 1 << 5,
    SCHEDULER_CPU_SHARES                      => "cpu_shares",
    SCHEDULER_GLOBAL_PERIOD                   => "global_period",
    SCHEDULER_GLOBAL_QUOTA                    => "global_quota",
    SCHEDULER_VCPU_PERIOD                     => "vcpu_period",
    SCHEDULER_VCPU_QUOTA                      => "vcpu_quota",
    SCHEDULER_EMULATOR_PERIOD                 => "emulator_period",
    SCHEDULER_EMULATOR_QUOTA                  => "emulator_quota",
    SCHEDULER_IOTHREAD_PERIOD                 => "iothread_period",
    SCHEDULER_IOTHREAD_QUOTA                  => "iothread_quota",
    SCHEDULER_WEIGHT                          => "weight",
    SCHEDULER_CAP                             => "cap",
    SCHEDULER_RESERVATION                     => "reservation",
    SCHEDULER_LIMIT                           => "limit",
    SCHEDULER_SHARES                          => "shares",
    BLOCK_STATS_FIELD_LENGTH                  => 80,
    BLOCK_STATS_READ_BYTES                    => "rd_bytes",
    BLOCK_STATS_READ_REQ                      => "rd_operations",
    BLOCK_STATS_READ_TOTAL_TIMES              => "rd_total_times",
    BLOCK_STATS_WRITE_BYTES                   => "wr_bytes",
    BLOCK_STATS_WRITE_REQ                     => "wr_operations",
    BLOCK_STATS_WRITE_TOTAL_TIMES             => "wr_total_times",
    BLOCK_STATS_FLUSH_REQ                     => "flush_operations",
    BLOCK_STATS_FLUSH_TOTAL_TIMES             => "flush_total_times",
    BLOCK_STATS_ERRS                          => "errs",
    MEMORY_STAT_SWAP_IN                       => 0,
    MEMORY_STAT_SWAP_OUT                      => 1,
    MEMORY_STAT_MAJOR_FAULT                   => 2,
    MEMORY_STAT_MINOR_FAULT                   => 3,
    MEMORY_STAT_UNUSED                        => 4,
    MEMORY_STAT_AVAILABLE                     => 5,
    MEMORY_STAT_ACTUAL_BALLOON                => 6,
    MEMORY_STAT_RSS                           => 7,
    MEMORY_STAT_USABLE                        => 8,
    MEMORY_STAT_LAST_UPDATE                   => 9,
    MEMORY_STAT_DISK_CACHES                   => 10,
    MEMORY_STAT_HUGETLB_PGALLOC               => 11,
    MEMORY_STAT_HUGETLB_PGFAIL                => 12,
    MEMORY_STAT_NR                            => 13,
    MEMORY_STAT_LAST                          => 13,
    DUMP_CRASH                                => (1 << 0),
    DUMP_LIVE                                 => (1 << 1),
    DUMP_BYPASS_CACHE                         => (1 << 2),
    DUMP_RESET                                => (1 << 3),
    DUMP_MEMORY_ONLY                          => (1 << 4),
    MIGRATE_LIVE                              => (1 << 0),
    MIGRATE_PEER2PEER                         => (1 << 1),
    MIGRATE_TUNNELLED                         => (1 << 2),
    MIGRATE_PERSIST_DEST                      => (1 << 3),
    MIGRATE_UNDEFINE_SOURCE                   => (1 << 4),
    MIGRATE_PAUSED                            => (1 << 5),
    MIGRATE_NON_SHARED_DISK                   => (1 << 6),
    MIGRATE_NON_SHARED_INC                    => (1 << 7),
    MIGRATE_CHANGE_PROTECTION                 => (1 << 8),
    MIGRATE_UNSAFE                            => (1 << 9),
    MIGRATE_OFFLINE                           => (1 << 10),
    MIGRATE_COMPRESSED                        => (1 << 11),
    MIGRATE_ABORT_ON_ERROR                    => (1 << 12),
    MIGRATE_AUTO_CONVERGE                     => (1 << 13),
    MIGRATE_RDMA_PIN_ALL                      => (1 << 14),
    MIGRATE_POSTCOPY                          => (1 << 15),
    MIGRATE_TLS                               => (1 << 16),
    MIGRATE_PARALLEL                          => (1 << 17),
    MIGRATE_NON_SHARED_SYNCHRONOUS_WRITES     => (1 << 18),
    MIGRATE_POSTCOPY_RESUME                   => (1 << 19),
    MIGRATE_ZEROCOPY                          => (1 << 20),
    MIGRATE_PARAM_URI                         => "migrate_uri",
    MIGRATE_PARAM_DEST_NAME                   => "destination_name",
    MIGRATE_PARAM_DEST_XML                    => "destination_xml",
    MIGRATE_PARAM_PERSIST_XML                 => "persistent_xml",
    MIGRATE_PARAM_BANDWIDTH                   => "bandwidth",
    MIGRATE_PARAM_BANDWIDTH_POSTCOPY          => "bandwidth.postcopy",
    MIGRATE_PARAM_GRAPHICS_URI                => "graphics_uri",
    MIGRATE_PARAM_LISTEN_ADDRESS              => "listen_address",
    MIGRATE_PARAM_MIGRATE_DISKS               => "migrate_disks",
    MIGRATE_PARAM_DISKS_PORT                  => "disks_port",
    MIGRATE_PARAM_DISKS_URI                   => "disks_uri",
    MIGRATE_PARAM_COMPRESSION                 => "compression",
    MIGRATE_PARAM_COMPRESSION_MT_LEVEL        => "compression.mt.level",
    MIGRATE_PARAM_COMPRESSION_MT_THREADS      => "compression.mt.threads",
    MIGRATE_PARAM_COMPRESSION_MT_DTHREADS     => "compression.mt.dthreads",
    MIGRATE_PARAM_COMPRESSION_XBZRLE_CACHE    => "compression.xbzrle.cache",
    MIGRATE_PARAM_COMPRESSION_ZLIB_LEVEL      => "compression.zlib.level",
    MIGRATE_PARAM_COMPRESSION_ZSTD_LEVEL      => "compression.zstd.level",
    MIGRATE_PARAM_AUTO_CONVERGE_INITIAL       => "auto_converge.initial",
    MIGRATE_PARAM_AUTO_CONVERGE_INCREMENT     => "auto_converge.increment",
    MIGRATE_PARAM_PARALLEL_CONNECTIONS        => "parallel.connections",
    MIGRATE_PARAM_TLS_DESTINATION             => "tls.destination",
    MIGRATE_MAX_SPEED_POSTCOPY                => (1 << 0),
    SHUTDOWN_DEFAULT                          => 0,
    SHUTDOWN_ACPI_POWER_BTN                   => (1 << 0),
    SHUTDOWN_GUEST_AGENT                      => (1 << 1),
    SHUTDOWN_INITCTL                          => (1 << 2),
    SHUTDOWN_SIGNAL                           => (1 << 3),
    SHUTDOWN_PARAVIRT                         => (1 << 4),
    REBOOT_DEFAULT                            => 0,
    REBOOT_ACPI_POWER_BTN                     => (1 << 0),
    REBOOT_GUEST_AGENT                        => (1 << 1),
    REBOOT_INITCTL                            => (1 << 2),
    REBOOT_SIGNAL                             => (1 << 3),
    REBOOT_PARAVIRT                           => (1 << 4),
    DESTROY_DEFAULT                           => 0,
    DESTROY_GRACEFUL                          => 1 << 0,
    DESTROY_REMOVE_LOGS                       => 1 << 1,
    SAVE_BYPASS_CACHE                         => 1 << 0,
    SAVE_RUNNING                              => 1 << 1,
    SAVE_PAUSED                               => 1 << 2,
    SAVE_RESET_NVRAM                          => 1 << 3,
    SAVE_PARAM_FILE                           => "file",
    SAVE_PARAM_DXML                           => "dxml",
    CPU_STATS_CPUTIME                         => "cpu_time",
    CPU_STATS_USERTIME                        => "user_time",
    CPU_STATS_SYSTEMTIME                      => "system_time",
    CPU_STATS_VCPUTIME                        => "vcpu_time",
    BLKIO_WEIGHT                              => "weight",
    BLKIO_DEVICE_WEIGHT                       => "device_weight",
    BLKIO_DEVICE_READ_IOPS                    => "device_read_iops_sec",
    BLKIO_DEVICE_WRITE_IOPS                   => "device_write_iops_sec",
    BLKIO_DEVICE_READ_BPS                     => "device_read_bytes_sec",
    BLKIO_DEVICE_WRITE_BPS                    => "device_write_bytes_sec",
    MEMORY_PARAM_UNLIMITED                    => 9007199254740991,
    MEMORY_HARD_LIMIT                         => "hard_limit",
    MEMORY_SOFT_LIMIT                         => "soft_limit",
    MEMORY_MIN_GUARANTEE                      => "min_guarantee",
    MEMORY_SWAP_HARD_LIMIT                    => "swap_hard_limit",
    MEM_CURRENT                               => 0,
    MEM_LIVE                                  => 1 << 0,
    MEM_CONFIG                                => 1 << 1,
    MEM_MAXIMUM                               => (1 << 2),
    NUMATUNE_MEM_STRICT                       => 0,
    NUMATUNE_MEM_PREFERRED                    => 1,
    NUMATUNE_MEM_INTERLEAVE                   => 2,
    NUMATUNE_MEM_RESTRICTIVE                  => 3,
    NUMA_NODESET                              => "numa_nodeset",
    NUMA_MODE                                 => "numa_mode",
    GET_HOSTNAME_LEASE                        => (1 << 0),
    GET_HOSTNAME_AGENT                        => (1 << 1),
    METADATA_DESCRIPTION                      => 0,
    METADATA_TITLE                            => 1,
    METADATA_ELEMENT                          => 2,
    XML_SECURE                                => (1 << 0),
    XML_INACTIVE                              => (1 << 1),
    XML_UPDATE_CPU                            => (1 << 2),
    XML_MIGRATABLE                            => (1 << 3),
    SAVE_IMAGE_XML_SECURE                     => (1 << 0),
    BANDWIDTH_IN_AVERAGE                      => "inbound.average",
    BANDWIDTH_IN_PEAK                         => "inbound.peak",
    BANDWIDTH_IN_BURST                        => "inbound.burst",
    BANDWIDTH_IN_FLOOR                        => "inbound.floor",
    BANDWIDTH_OUT_AVERAGE                     => "outbound.average",
    BANDWIDTH_OUT_PEAK                        => "outbound.peak",
    BANDWIDTH_OUT_BURST                       => "outbound.burst",
    BLOCK_RESIZE_BYTES                        => 1 << 0,
    BLOCK_RESIZE_CAPACITY                     => 1 << 1,
    MEMORY_VIRTUAL                            => 1 << 0,
    MEMORY_PHYSICAL                           => 1 << 1,
    UNDEFINE_MANAGED_SAVE                     => (1 << 0),
    UNDEFINE_SNAPSHOTS_METADATA               => (1 << 1),
    UNDEFINE_NVRAM                            => (1 << 2),
    UNDEFINE_KEEP_NVRAM                       => (1 << 3),
    UNDEFINE_CHECKPOINTS_METADATA             => (1 << 4),
    UNDEFINE_TPM                              => (1 << 5),
    UNDEFINE_KEEP_TPM                         => (1 << 6),
    VCPU_OFFLINE                              => 0,
    VCPU_RUNNING                              => 1,
    VCPU_BLOCKED                              => 2,
    VCPU_INFO_CPU_OFFLINE                     => -1,
    VCPU_INFO_CPU_UNAVAILABLE                 => -2,
    VCPU_CURRENT                              => 0,
    VCPU_LIVE                                 => 1 << 0,
    VCPU_CONFIG                               => 1 << 1,
    VCPU_MAXIMUM                              => (1 << 2),
    VCPU_GUEST                                => (1 << 3),
    VCPU_HOTPLUGGABLE                         => (1 << 4),
    IOTHREAD_POLL_MAX_NS                      => "poll_max_ns",
    IOTHREAD_POLL_GROW                        => "poll_grow",
    IOTHREAD_POLL_SHRINK                      => "poll_shrink",
    IOTHREAD_THREAD_POOL_MIN                  => "thread_pool_min",
    IOTHREAD_THREAD_POOL_MAX                  => "thread_pool_max",
    DEVICE_MODIFY_CURRENT                     => 0,
    DEVICE_MODIFY_LIVE                        => 1 << 0,
    DEVICE_MODIFY_CONFIG                      => 1 << 1,
    DEVICE_MODIFY_FORCE                       => (1 << 2),
    STATS_STATE                               => (1 << 0),
    STATS_CPU_TOTAL                           => (1 << 1),
    STATS_BALLOON                             => (1 << 2),
    STATS_VCPU                                => (1 << 3),
    STATS_INTERFACE                           => (1 << 4),
    STATS_BLOCK                               => (1 << 5),
    STATS_PERF                                => (1 << 6),
    STATS_IOTHREAD                            => (1 << 7),
    STATS_MEMORY                              => (1 << 8),
    STATS_DIRTYRATE                           => (1 << 9),
    STATS_VM                                  => (1 << 10),
    PERF_PARAM_CMT                            => "cmt",
    PERF_PARAM_MBMT                           => "mbmt",
    PERF_PARAM_MBML                           => "mbml",
    PERF_PARAM_CACHE_MISSES                   => "cache_misses",
    PERF_PARAM_CACHE_REFERENCES               => "cache_references",
    PERF_PARAM_INSTRUCTIONS                   => "instructions",
    PERF_PARAM_CPU_CYCLES                     => "cpu_cycles",
    PERF_PARAM_BRANCH_INSTRUCTIONS            => "branch_instructions",
    PERF_PARAM_BRANCH_MISSES                  => "branch_misses",
    PERF_PARAM_BUS_CYCLES                     => "bus_cycles",
    PERF_PARAM_STALLED_CYCLES_FRONTEND        => "stalled_cycles_frontend",
    PERF_PARAM_STALLED_CYCLES_BACKEND         => "stalled_cycles_backend",
    PERF_PARAM_REF_CPU_CYCLES                 => "ref_cpu_cycles",
    PERF_PARAM_CPU_CLOCK                      => "cpu_clock",
    PERF_PARAM_TASK_CLOCK                     => "task_clock",
    PERF_PARAM_PAGE_FAULTS                    => "page_faults",
    PERF_PARAM_CONTEXT_SWITCHES               => "context_switches",
    PERF_PARAM_CPU_MIGRATIONS                 => "cpu_migrations",
    PERF_PARAM_PAGE_FAULTS_MIN                => "page_faults_min",
    PERF_PARAM_PAGE_FAULTS_MAJ                => "page_faults_maj",
    PERF_PARAM_ALIGNMENT_FAULTS               => "alignment_faults",
    PERF_PARAM_EMULATION_FAULTS               => "emulation_faults",
    BLOCK_JOB_TYPE_UNKNOWN                    => 0,
    BLOCK_JOB_TYPE_PULL                       => 1,
    BLOCK_JOB_TYPE_COPY                       => 2,
    BLOCK_JOB_TYPE_COMMIT                     => 3,
    BLOCK_JOB_TYPE_ACTIVE_COMMIT              => 4,
    BLOCK_JOB_TYPE_BACKUP                     => 5,
    BLOCK_JOB_ABORT_ASYNC                     => 1 << 0,
    BLOCK_JOB_ABORT_PIVOT                     => 1 << 1,
    BLOCK_JOB_INFO_BANDWIDTH_BYTES            => 1 << 0,
    BLOCK_JOB_SPEED_BANDWIDTH_BYTES           => 1 << 0,
    BLOCK_PULL_BANDWIDTH_BYTES                => 1 << 6,
    BLOCK_REBASE_SHALLOW                      => 1 << 0,
    BLOCK_REBASE_REUSE_EXT                    => 1 << 1,
    BLOCK_REBASE_COPY_RAW                     => 1 << 2,
    BLOCK_REBASE_COPY                         => 1 << 3,
    BLOCK_REBASE_RELATIVE                     => 1 << 4,
    BLOCK_REBASE_COPY_DEV                     => 1 << 5,
    BLOCK_REBASE_BANDWIDTH_BYTES              => 1 << 6,
    BLOCK_COPY_SHALLOW                        => 1 << 0,
    BLOCK_COPY_REUSE_EXT                      => 1 << 1,
    BLOCK_COPY_TRANSIENT_JOB                  => 1 << 2,
    BLOCK_COPY_SYNCHRONOUS_WRITES             => 1 << 3,
    BLOCK_COPY_BANDWIDTH                      => "bandwidth",
    BLOCK_COPY_GRANULARITY                    => "granularity",
    BLOCK_COPY_BUF_SIZE                       => "buf-size",
    BLOCK_COMMIT_SHALLOW                      => 1 << 0,
    BLOCK_COMMIT_DELETE                       => 1 << 1,
    BLOCK_COMMIT_ACTIVE                       => 1 << 2,
    BLOCK_COMMIT_RELATIVE                     => 1 << 3,
    BLOCK_COMMIT_BANDWIDTH_BYTES              => 1 << 4,
    BLOCK_IOTUNE_TOTAL_BYTES_SEC              => "total_bytes_sec",
    BLOCK_IOTUNE_READ_BYTES_SEC               => "read_bytes_sec",
    BLOCK_IOTUNE_WRITE_BYTES_SEC              => "write_bytes_sec",
    BLOCK_IOTUNE_TOTAL_IOPS_SEC               => "total_iops_sec",
    BLOCK_IOTUNE_READ_IOPS_SEC                => "read_iops_sec",
    BLOCK_IOTUNE_WRITE_IOPS_SEC               => "write_iops_sec",
    BLOCK_IOTUNE_TOTAL_BYTES_SEC_MAX          => "total_bytes_sec_max",
    BLOCK_IOTUNE_READ_BYTES_SEC_MAX           => "read_bytes_sec_max",
    BLOCK_IOTUNE_WRITE_BYTES_SEC_MAX          => "write_bytes_sec_max",
    BLOCK_IOTUNE_TOTAL_IOPS_SEC_MAX           => "total_iops_sec_max",
    BLOCK_IOTUNE_READ_IOPS_SEC_MAX            => "read_iops_sec_max",
    BLOCK_IOTUNE_WRITE_IOPS_SEC_MAX           => "write_iops_sec_max",
    BLOCK_IOTUNE_TOTAL_BYTES_SEC_MAX_LENGTH   => "total_bytes_sec_max_length",
    BLOCK_IOTUNE_READ_BYTES_SEC_MAX_LENGTH    => "read_bytes_sec_max_length",
    BLOCK_IOTUNE_WRITE_BYTES_SEC_MAX_LENGTH   => "write_bytes_sec_max_length",
    BLOCK_IOTUNE_TOTAL_IOPS_SEC_MAX_LENGTH    => "total_iops_sec_max_length",
    BLOCK_IOTUNE_READ_IOPS_SEC_MAX_LENGTH     => "read_iops_sec_max_length",
    BLOCK_IOTUNE_WRITE_IOPS_SEC_MAX_LENGTH    => "write_iops_sec_max_length",
    BLOCK_IOTUNE_SIZE_IOPS_SEC                => "size_iops_sec",
    BLOCK_IOTUNE_GROUP_NAME                   => "group_name",
    DISK_ERROR_NONE                           => 0,
    DISK_ERROR_UNSPEC                         => 1,
    DISK_ERROR_NO_SPACE                       => 2,
    KEYCODE_SET_LINUX                         => 0,
    KEYCODE_SET_XT                            => 1,
    KEYCODE_SET_ATSET1                        => 2,
    KEYCODE_SET_ATSET2                        => 3,
    KEYCODE_SET_ATSET3                        => 4,
    KEYCODE_SET_OSX                           => 5,
    KEYCODE_SET_XT_KBD                        => 6,
    KEYCODE_SET_USB                           => 7,
    KEYCODE_SET_WIN32                         => 8,
    KEYCODE_SET_QNUM                          => 9,
    KEYCODE_SET_RFB                           => 9,
    SEND_KEY_MAX_KEYS                         => 16,
    PROCESS_SIGNAL_NOP                        => 0,
    PROCESS_SIGNAL_HUP                        => 1,
    PROCESS_SIGNAL_INT                        => 2,
    PROCESS_SIGNAL_QUIT                       => 3,
    PROCESS_SIGNAL_ILL                        => 4,
    PROCESS_SIGNAL_TRAP                       => 5,
    PROCESS_SIGNAL_ABRT                       => 6,
    PROCESS_SIGNAL_BUS                        => 7,
    PROCESS_SIGNAL_FPE                        => 8,
    PROCESS_SIGNAL_KILL                       => 9,
    PROCESS_SIGNAL_USR1                       => 10,
    PROCESS_SIGNAL_SEGV                       => 11,
    PROCESS_SIGNAL_USR2                       => 12,
    PROCESS_SIGNAL_PIPE                       => 13,
    PROCESS_SIGNAL_ALRM                       => 14,
    PROCESS_SIGNAL_TERM                       => 15,
    PROCESS_SIGNAL_STKFLT                     => 16,
    PROCESS_SIGNAL_CHLD                       => 17,
    PROCESS_SIGNAL_CONT                       => 18,
    PROCESS_SIGNAL_STOP                       => 19,
    PROCESS_SIGNAL_TSTP                       => 20,
    PROCESS_SIGNAL_TTIN                       => 21,
    PROCESS_SIGNAL_TTOU                       => 22,
    PROCESS_SIGNAL_URG                        => 23,
    PROCESS_SIGNAL_XCPU                       => 24,
    PROCESS_SIGNAL_XFSZ                       => 25,
    PROCESS_SIGNAL_VTALRM                     => 26,
    PROCESS_SIGNAL_PROF                       => 27,
    PROCESS_SIGNAL_WINCH                      => 28,
    PROCESS_SIGNAL_POLL                       => 29,
    PROCESS_SIGNAL_PWR                        => 30,
    PROCESS_SIGNAL_SYS                        => 31,
    PROCESS_SIGNAL_RT0                        => 32,
    PROCESS_SIGNAL_RT1                        => 33,
    PROCESS_SIGNAL_RT2                        => 34,
    PROCESS_SIGNAL_RT3                        => 35,
    PROCESS_SIGNAL_RT4                        => 36,
    PROCESS_SIGNAL_RT5                        => 37,
    PROCESS_SIGNAL_RT6                        => 38,
    PROCESS_SIGNAL_RT7                        => 39,
    PROCESS_SIGNAL_RT8                        => 40,
    PROCESS_SIGNAL_RT9                        => 41,
    PROCESS_SIGNAL_RT10                       => 42,
    PROCESS_SIGNAL_RT11                       => 43,
    PROCESS_SIGNAL_RT12                       => 44,
    PROCESS_SIGNAL_RT13                       => 45,
    PROCESS_SIGNAL_RT14                       => 46,
    PROCESS_SIGNAL_RT15                       => 47,
    PROCESS_SIGNAL_RT16                       => 48,
    PROCESS_SIGNAL_RT17                       => 49,
    PROCESS_SIGNAL_RT18                       => 50,
    PROCESS_SIGNAL_RT19                       => 51,
    PROCESS_SIGNAL_RT20                       => 52,
    PROCESS_SIGNAL_RT21                       => 53,
    PROCESS_SIGNAL_RT22                       => 54,
    PROCESS_SIGNAL_RT23                       => 55,
    PROCESS_SIGNAL_RT24                       => 56,
    PROCESS_SIGNAL_RT25                       => 57,
    PROCESS_SIGNAL_RT26                       => 58,
    PROCESS_SIGNAL_RT27                       => 59,
    PROCESS_SIGNAL_RT28                       => 60,
    PROCESS_SIGNAL_RT29                       => 61,
    PROCESS_SIGNAL_RT30                       => 62,
    PROCESS_SIGNAL_RT31                       => 63,
    PROCESS_SIGNAL_RT32                       => 64,
    EVENT_DEFINED                             => 0,
    EVENT_UNDEFINED                           => 1,
    EVENT_STARTED                             => 2,
    EVENT_SUSPENDED                           => 3,
    EVENT_RESUMED                             => 4,
    EVENT_STOPPED                             => 5,
    EVENT_SHUTDOWN                            => 6,
    EVENT_PMSUSPENDED                         => 7,
    EVENT_CRASHED                             => 8,
    EVENT_DEFINED_ADDED                       => 0,
    EVENT_DEFINED_UPDATED                     => 1,
    EVENT_DEFINED_RENAMED                     => 2,
    EVENT_DEFINED_FROM_SNAPSHOT               => 3,
    EVENT_UNDEFINED_REMOVED                   => 0,
    EVENT_UNDEFINED_RENAMED                   => 1,
    EVENT_STARTED_BOOTED                      => 0,
    EVENT_STARTED_MIGRATED                    => 1,
    EVENT_STARTED_RESTORED                    => 2,
    EVENT_STARTED_FROM_SNAPSHOT               => 3,
    EVENT_STARTED_WAKEUP                      => 4,
    EVENT_SUSPENDED_PAUSED                    => 0,
    EVENT_SUSPENDED_MIGRATED                  => 1,
    EVENT_SUSPENDED_IOERROR                   => 2,
    EVENT_SUSPENDED_WATCHDOG                  => 3,
    EVENT_SUSPENDED_RESTORED                  => 4,
    EVENT_SUSPENDED_FROM_SNAPSHOT             => 5,
    EVENT_SUSPENDED_API_ERROR                 => 6,
    EVENT_SUSPENDED_POSTCOPY                  => 7,
    EVENT_SUSPENDED_POSTCOPY_FAILED           => 8,
    EVENT_RESUMED_UNPAUSED                    => 0,
    EVENT_RESUMED_MIGRATED                    => 1,
    EVENT_RESUMED_FROM_SNAPSHOT               => 2,
    EVENT_RESUMED_POSTCOPY                    => 3,
    EVENT_RESUMED_POSTCOPY_FAILED             => 4,
    EVENT_STOPPED_SHUTDOWN                    => 0,
    EVENT_STOPPED_DESTROYED                   => 1,
    EVENT_STOPPED_CRASHED                     => 2,
    EVENT_STOPPED_MIGRATED                    => 3,
    EVENT_STOPPED_SAVED                       => 4,
    EVENT_STOPPED_FAILED                      => 5,
    EVENT_STOPPED_FROM_SNAPSHOT               => 6,
    EVENT_SHUTDOWN_FINISHED                   => 0,
    EVENT_SHUTDOWN_GUEST                      => 1,
    EVENT_SHUTDOWN_HOST                       => 2,
    EVENT_PMSUSPENDED_MEMORY                  => 0,
    EVENT_PMSUSPENDED_DISK                    => 1,
    EVENT_CRASHED_PANICKED                    => 0,
    EVENT_CRASHED_CRASHLOADED                 => 1,
    EVENT_MEMORY_FAILURE_RECIPIENT_HYPERVISOR => 0,
    EVENT_MEMORY_FAILURE_RECIPIENT_GUEST      => 1,
    EVENT_MEMORY_FAILURE_ACTION_IGNORE        => 0,
    EVENT_MEMORY_FAILURE_ACTION_INJECT        => 1,
    EVENT_MEMORY_FAILURE_ACTION_FATAL         => 2,
    EVENT_MEMORY_FAILURE_ACTION_RESET         => 3,
    MEMORY_FAILURE_ACTION_REQUIRED            => (1 << 0),
    MEMORY_FAILURE_RECURSIVE                  => (1 << 1),
    JOB_NONE                                  => 0,
    JOB_BOUNDED                               => 1,
    JOB_UNBOUNDED                             => 2,
    JOB_COMPLETED                             => 3,
    JOB_FAILED                                => 4,
    JOB_CANCELLED                             => 5,
    JOB_STATS_COMPLETED                       => 1 << 0,
    JOB_STATS_KEEP_COMPLETED                  => 1 << 1,
    ABORT_JOB_POSTCOPY                        => 1 << 0,
    JOB_OPERATION_UNKNOWN                     => 0,
    JOB_OPERATION_START                       => 1,
    JOB_OPERATION_SAVE                        => 2,
    JOB_OPERATION_RESTORE                     => 3,
    JOB_OPERATION_MIGRATION_IN                => 4,
    JOB_OPERATION_MIGRATION_OUT               => 5,
    JOB_OPERATION_SNAPSHOT                    => 6,
    JOB_OPERATION_SNAPSHOT_REVERT             => 7,
    JOB_OPERATION_DUMP                        => 8,
    JOB_OPERATION_BACKUP                      => 9,
    JOB_OPERATION_SNAPSHOT_DELETE             => 10,
    JOB_OPERATION                             => "operation",
    JOB_TIME_ELAPSED                          => "time_elapsed",
    JOB_TIME_ELAPSED_NET                      => "time_elapsed_net",
    JOB_TIME_REMAINING                        => "time_remaining",
    JOB_DOWNTIME                              => "downtime",
    JOB_DOWNTIME_NET                          => "downtime_net",
    JOB_SETUP_TIME                            => "setup_time",
    JOB_DATA_TOTAL                            => "data_total",
    JOB_DATA_PROCESSED                        => "data_processed",
    JOB_DATA_REMAINING                        => "data_remaining",
    JOB_MEMORY_TOTAL                          => "memory_total",
    JOB_MEMORY_PROCESSED                      => "memory_processed",
    JOB_MEMORY_REMAINING                      => "memory_remaining",
    JOB_MEMORY_CONSTANT                       => "memory_constant",
    JOB_MEMORY_NORMAL                         => "memory_normal",
    JOB_MEMORY_NORMAL_BYTES                   => "memory_normal_bytes",
    JOB_MEMORY_BPS                            => "memory_bps",
    JOB_MEMORY_DIRTY_RATE                     => "memory_dirty_rate",
    JOB_MEMORY_PAGE_SIZE                      => "memory_page_size",
    JOB_MEMORY_ITERATION                      => "memory_iteration",
    JOB_MEMORY_POSTCOPY_REQS                  => "memory_postcopy_requests",
    JOB_DISK_TOTAL                            => "disk_total",
    JOB_DISK_PROCESSED                        => "disk_processed",
    JOB_DISK_REMAINING                        => "disk_remaining",
    JOB_DISK_BPS                              => "disk_bps",
    JOB_COMPRESSION_CACHE                     => "compression_cache",
    JOB_COMPRESSION_BYTES                     => "compression_bytes",
    JOB_COMPRESSION_PAGES                     => "compression_pages",
    JOB_COMPRESSION_CACHE_MISSES              => "compression_cache_misses",
    JOB_COMPRESSION_OVERFLOW                  => "compression_overflow",
    JOB_AUTO_CONVERGE_THROTTLE                => "auto_converge_throttle",
    JOB_SUCCESS                               => "success",
    JOB_ERRMSG                                => "errmsg",
    JOB_DISK_TEMP_USED                        => "disk_temp_used",
    JOB_DISK_TEMP_TOTAL                       => "disk_temp_total",
    EVENT_WATCHDOG_NONE                       => 0,
    EVENT_IO_ERROR_NONE                       => 0,
    EVENT_GRAPHICS_CONNECT                    => 0,
    BLOCK_JOB_COMPLETED                       => 0,
    BLOCK_JOB_FAILED                          => 1,
    BLOCK_JOB_CANCELED                        => 2,
    BLOCK_JOB_READY                           => 3,
    EVENT_DISK_CHANGE_MISSING_ON_START        => 0,
    EVENT_DISK_DROP_MISSING_ON_START          => 1,
    EVENT_TRAY_CHANGE_OPEN                    => 0,
    TUNABLE_CPU_VCPUPIN                       => "cputune.vcpupin%u",
    TUNABLE_CPU_EMULATORPIN                   => "cputune.emulatorpin",
    TUNABLE_CPU_IOTHREADSPIN                  => "cputune.iothreadpin%u",
    TUNABLE_CPU_CPU_SHARES                    => "cputune.cpu_shares",
    TUNABLE_CPU_GLOBAL_PERIOD                 => "cputune.global_period",
    TUNABLE_CPU_GLOBAL_QUOTA                  => "cputune.global_quota",
    TUNABLE_CPU_VCPU_PERIOD                   => "cputune.vcpu_period",
    TUNABLE_CPU_VCPU_QUOTA                    => "cputune.vcpu_quota",
    TUNABLE_CPU_EMULATOR_PERIOD               => "cputune.emulator_period",
    TUNABLE_CPU_EMULATOR_QUOTA                => "cputune.emulator_quota",
    TUNABLE_CPU_IOTHREAD_PERIOD               => "cputune.iothread_period",
    TUNABLE_CPU_IOTHREAD_QUOTA                => "cputune.iothread_quota",
    TUNABLE_BLKDEV_DISK                       => "blkdeviotune.disk",
    TUNABLE_BLKDEV_TOTAL_BYTES_SEC            => "blkdeviotune.total_bytes_sec",
    TUNABLE_BLKDEV_READ_BYTES_SEC             => "blkdeviotune.read_bytes_sec",
    TUNABLE_BLKDEV_WRITE_BYTES_SEC            => "blkdeviotune.write_bytes_sec",
    TUNABLE_BLKDEV_TOTAL_IOPS_SEC             => "blkdeviotune.total_iops_sec",
    TUNABLE_BLKDEV_READ_IOPS_SEC              => "blkdeviotune.read_iops_sec",
    TUNABLE_BLKDEV_WRITE_IOPS_SEC             => "blkdeviotune.write_iops_sec",
    TUNABLE_BLKDEV_TOTAL_BYTES_SEC_MAX        => "blkdeviotune.total_bytes_sec_max",
    TUNABLE_BLKDEV_READ_BYTES_SEC_MAX         => "blkdeviotune.read_bytes_sec_max",
    TUNABLE_BLKDEV_WRITE_BYTES_SEC_MAX        => "blkdeviotune.write_bytes_sec_max",
    TUNABLE_BLKDEV_TOTAL_IOPS_SEC_MAX         => "blkdeviotune.total_iops_sec_max",
    TUNABLE_BLKDEV_READ_IOPS_SEC_MAX          => "blkdeviotune.read_iops_sec_max",
    TUNABLE_BLKDEV_WRITE_IOPS_SEC_MAX         => "blkdeviotune.write_iops_sec_max",
    TUNABLE_BLKDEV_SIZE_IOPS_SEC              => "blkdeviotune.size_iops_sec",
    TUNABLE_BLKDEV_GROUP_NAME                 => "blkdeviotune.group_name",
    TUNABLE_BLKDEV_TOTAL_BYTES_SEC_MAX_LENGTH => "blkdeviotune.total_bytes_sec_max_length",
    TUNABLE_BLKDEV_READ_BYTES_SEC_MAX_LENGTH  => "blkdeviotune.read_bytes_sec_max_length",
    TUNABLE_BLKDEV_WRITE_BYTES_SEC_MAX_LENGTH => "blkdeviotune.write_bytes_sec_max_length",
    TUNABLE_BLKDEV_TOTAL_IOPS_SEC_MAX_LENGTH  => "blkdeviotune.total_iops_sec_max_length",
    TUNABLE_BLKDEV_READ_IOPS_SEC_MAX_LENGTH   => "blkdeviotune.read_iops_sec_max_length",
    TUNABLE_BLKDEV_WRITE_IOPS_SEC_MAX_LENGTH  => "blkdeviotune.write_iops_sec_max_length",
    CONSOLE_FORCE                             => (1 << 0),
    CONSOLE_SAFE                              => (1 << 1),
    CHANNEL_FORCE                             => (1 << 0),
    OPEN_GRAPHICS_SKIPAUTH                    => (1 << 0),
    TIME_SYNC                                 => (1 << 0),
    SCHED_FIELD_INT                           => 1,
    SCHED_FIELD_UINT                          => 2,
    SCHED_FIELD_LLONG                         => 3,
    SCHED_FIELD_ULLONG                        => 4,
    SCHED_FIELD_DOUBLE                        => 5,
    SCHED_FIELD_BOOLEAN                       => 6,
    SCHED_FIELD_LENGTH                        => 80,
    BLKIO_PARAM_INT                           => 1,
    BLKIO_PARAM_UINT                          => 2,
    BLKIO_PARAM_LLONG                         => 3,
    BLKIO_PARAM_ULLONG                        => 4,
    BLKIO_PARAM_DOUBLE                        => 5,
    BLKIO_PARAM_BOOLEAN                       => 6,
    BLKIO_FIELD_LENGTH                        => 80,
    MEMORY_PARAM_INT                          => 1,
    MEMORY_PARAM_UINT                         => 2,
    MEMORY_PARAM_LLONG                        => 3,
    MEMORY_PARAM_ULLONG                       => 4,
    MEMORY_PARAM_DOUBLE                       => 5,
    MEMORY_PARAM_BOOLEAN                      => 6,
    MEMORY_FIELD_LENGTH                       => 80,
    INTERFACE_ADDRESSES_SRC_LEASE             => 0,
    INTERFACE_ADDRESSES_SRC_AGENT             => 1,
    INTERFACE_ADDRESSES_SRC_ARP               => 2,
    PASSWORD_ENCRYPTED                        => 1 << 0,
    LIFECYCLE_POWEROFF                        => 0,
    LIFECYCLE_REBOOT                          => 1,
    LIFECYCLE_CRASH                           => 2,
    LIFECYCLE_ACTION_DESTROY                  => 0,
    LIFECYCLE_ACTION_RESTART                  => 1,
    LIFECYCLE_ACTION_RESTART_RENAME           => 2,
    LIFECYCLE_ACTION_PRESERVE                 => 3,
    LIFECYCLE_ACTION_COREDUMP_DESTROY         => 4,
    LIFECYCLE_ACTION_COREDUMP_RESTART         => 5,
    LAUNCH_SECURITY_SEV_MEASUREMENT           => "sev-measurement",
    LAUNCH_SECURITY_SEV_API_MAJOR             => "sev-api-major",
    LAUNCH_SECURITY_SEV_API_MINOR             => "sev-api-minor",
    LAUNCH_SECURITY_SEV_BUILD_ID              => "sev-build-id",
    LAUNCH_SECURITY_SEV_POLICY                => "sev-policy",
    LAUNCH_SECURITY_SEV_SECRET_HEADER         => "sev-secret-header",
    LAUNCH_SECURITY_SEV_SECRET                => "sev-secret",
    LAUNCH_SECURITY_SEV_SECRET_SET_ADDRESS    => "sev-secret-set-address",
    GUEST_INFO_USERS                          => (1 << 0),
    GUEST_INFO_OS                             => (1 << 1),
    GUEST_INFO_TIMEZONE                       => (1 << 2),
    GUEST_INFO_HOSTNAME                       => (1 << 3),
    GUEST_INFO_FILESYSTEM                     => (1 << 4),
    GUEST_INFO_DISKS                          => (1 << 5),
    GUEST_INFO_INTERFACES                     => (1 << 6),
    AGENT_RESPONSE_TIMEOUT_BLOCK              => -2,
    AGENT_RESPONSE_TIMEOUT_DEFAULT            => -1,
    AGENT_RESPONSE_TIMEOUT_NOWAIT             => 0,
    BACKUP_BEGIN_REUSE_EXTERNAL               => (1 << 0),
    AUTHORIZED_SSH_KEYS_SET_APPEND            => (1 << 0),
    AUTHORIZED_SSH_KEYS_SET_REMOVE            => (1 << 1),
    MESSAGE_DEPRECATION                       => (1 << 0),
    MESSAGE_TAINTING                          => (1 << 1),
    DIRTYRATE_UNSTARTED                       => 0,
    DIRTYRATE_MEASURING                       => 1,
    DIRTYRATE_MEASURED                        => 2,
    DIRTYRATE_MODE_PAGE_SAMPLING              => 0,
    DIRTYRATE_MODE_DIRTY_BITMAP               => 1 << 0,
    DIRTYRATE_MODE_DIRTY_RING                 => 1 << 1,
    FD_ASSOCIATE_SECLABEL_RESTORE             => (1 << 0),
    FD_ASSOCIATE_SECLABEL_WRITABLE            => (1 << 1),
    GRAPHICS_RELOAD_TYPE_ANY                  => 0,
    GRAPHICS_RELOAD_TYPE_VNC                  => 1,
};


sub new($class, %args) {
    return bless {
        id => $args{id},
        client => $args{client},
    }, $class;
}

# @@@TODO: ENTRYPOINT: REMOTE_PROC_DOMAIN_GET_VCPU_PIN_INFO
#
# Check out Sys::Virt::Domain::get_vcpu_info
#
# async sub get_vcpu_pin_info($self, $flags = 0) {
#     my $maplen = await $self->{client}->_maplen;
#     return $self->{client}->_call(
#         $remote->PROC_DOMAIN_GET_VCPU_INFO,
#         { dom => $self->{id}, ncpumaps => ...,
#           maplen => $maplen, flags => $flags // 0 });
# }

sub _migrate_perform($self, $cookie, $uri, $flags, $dname, $resource) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_MIGRATE_PERFORM,
        { dom => $self->{id}, cookie => $cookie, uri => $uri, flags => $flags // 0, dname => $dname, resource => $resource }, empty => 1 );
}

sub abort_job($self) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_ABORT_JOB,
        { dom => $self->{id} }, empty => 1 );
}

sub abort_job_flags($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_ABORT_JOB_FLAGS,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub add_iothread($self, $iothread_id, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_ADD_IOTHREAD,
        { dom => $self->{id}, iothread_id => $iothread_id, flags => $flags // 0 }, empty => 1 );
}

async sub agent_set_response_timeout($self, $timeout, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_AGENT_SET_RESPONSE_TIMEOUT,
        { dom => $self->{id}, timeout => $timeout, flags => $flags // 0 }, unwrap => 'result' );
}

sub attach_device($self, $xml) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_ATTACH_DEVICE,
        { dom => $self->{id}, xml => $xml }, empty => 1 );
}

sub attach_device_flags($self, $xml, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_ATTACH_DEVICE_FLAGS,
        { dom => $self->{id}, xml => $xml, flags => $flags // 0 }, empty => 1 );
}

async sub authorized_ssh_keys_get($self, $user, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_AUTHORIZED_SSH_KEYS_GET,
        { dom => $self->{id}, user => $user, flags => $flags // 0 }, unwrap => 'keys' );
}

sub authorized_ssh_keys_set($self, $user, $keys, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_AUTHORIZED_SSH_KEYS_SET,
        { dom => $self->{id}, user => $user, keys => $keys, flags => $flags // 0 }, empty => 1 );
}

sub backup_begin($self, $backup_xml, $checkpoint_xml, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_BACKUP_BEGIN,
        { dom => $self->{id}, backup_xml => $backup_xml, checkpoint_xml => $checkpoint_xml, flags => $flags // 0 }, empty => 1 );
}

async sub backup_get_xml_desc($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_BACKUP_GET_XML_DESC,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'xml' );
}

sub block_commit($self, $disk, $base, $top, $bandwidth, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_BLOCK_COMMIT,
        { dom => $self->{id}, disk => $disk, base => $base, top => $top, bandwidth => $bandwidth, flags => $flags // 0 }, empty => 1 );
}

async sub block_copy($self, $path, $destxml, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_BLOCK_COPY,
        { dom => $self->{id}, path => $path, destxml => $destxml, params => $params, flags => $flags // 0 }, empty => 1 );
}

sub block_job_abort($self, $path, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_BLOCK_JOB_ABORT,
        { dom => $self->{id}, path => $path, flags => $flags // 0 }, empty => 1 );
}

sub block_job_set_speed($self, $path, $bandwidth, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_BLOCK_JOB_SET_SPEED,
        { dom => $self->{id}, path => $path, bandwidth => $bandwidth, flags => $flags // 0 }, empty => 1 );
}

sub block_pull($self, $path, $bandwidth, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_BLOCK_PULL,
        { dom => $self->{id}, path => $path, bandwidth => $bandwidth, flags => $flags // 0 }, empty => 1 );
}

sub block_rebase($self, $path, $base, $bandwidth, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_BLOCK_REBASE,
        { dom => $self->{id}, path => $path, base => $base, bandwidth => $bandwidth, flags => $flags // 0 }, empty => 1 );
}

sub block_resize($self, $disk, $size, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_BLOCK_RESIZE,
        { dom => $self->{id}, disk => $disk, size => $size, flags => $flags // 0 }, empty => 1 );
}

sub block_stats($self, $path) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_BLOCK_STATS,
        { dom => $self->{id}, path => $path } );
}

async sub block_stats_flags($self, $path, $flags = 0) {
    $flags |= await $self->{client}->_typed_param_string_okay();
    my $nparams = await $self->{client}->_call(
        $remote->PROC_DOMAIN_BLOCK_STATS_FLAGS,
        { dom => $self->{id}, path => $path, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_BLOCK_STATS_FLAGS,
        { dom => $self->{id}, path => $path, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

async sub checkpoint_create_xml($self, $xml_desc, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_CHECKPOINT_CREATE_XML,
        { dom => $self->{id}, xml_desc => $xml_desc, flags => $flags // 0 }, unwrap => 'checkpoint' );
}

async sub checkpoint_lookup_by_name($self, $name, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_CHECKPOINT_LOOKUP_BY_NAME,
        { dom => $self->{id}, name => $name, flags => $flags // 0 }, unwrap => 'checkpoint' );
}

sub core_dump($self, $to, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_CORE_DUMP,
        { dom => $self->{id}, to => $to, flags => $flags // 0 }, empty => 1 );
}

sub core_dump_with_format($self, $to, $dumpformat, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_CORE_DUMP_WITH_FORMAT,
        { dom => $self->{id}, to => $to, dumpformat => $dumpformat, flags => $flags // 0 }, empty => 1 );
}

async sub create_with_flags($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_CREATE_WITH_FLAGS,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'dom' );
}

sub del_iothread($self, $iothread_id, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_DEL_IOTHREAD,
        { dom => $self->{id}, iothread_id => $iothread_id, flags => $flags // 0 }, empty => 1 );
}

sub destroy($self) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_DESTROY,
        { dom => $self->{id} }, empty => 1 );
}

sub destroy_flags($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_DESTROY_FLAGS,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub detach_device($self, $xml) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_DETACH_DEVICE,
        { dom => $self->{id}, xml => $xml }, empty => 1 );
}

sub detach_device_alias($self, $alias, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_DETACH_DEVICE_ALIAS,
        { dom => $self->{id}, alias => $alias, flags => $flags // 0 }, empty => 1 );
}

sub detach_device_flags($self, $xml, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_DETACH_DEVICE_FLAGS,
        { dom => $self->{id}, xml => $xml, flags => $flags // 0 }, empty => 1 );
}

async sub fsfreeze($self, $mountpoints, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_FSFREEZE,
        { dom => $self->{id}, mountpoints => $mountpoints, flags => $flags // 0 }, unwrap => 'filesystems' );
}

async sub fsthaw($self, $mountpoints, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_FSTHAW,
        { dom => $self->{id}, mountpoints => $mountpoints, flags => $flags // 0 }, unwrap => 'filesystems' );
}

sub fstrim($self, $mountPoint, $minimum, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_FSTRIM,
        { dom => $self->{id}, mountPoint => $mountPoint, minimum => $minimum, flags => $flags // 0 }, empty => 1 );
}

async sub get_autostart($self) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_AUTOSTART,
        { dom => $self->{id} }, unwrap => 'autostart' );
}

async sub get_blkio_parameters($self, $flags = 0) {
    $flags |= await $self->{client}->_typed_param_string_okay();
    my $nparams = await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_BLKIO_PARAMETERS,
        { dom => $self->{id}, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_BLKIO_PARAMETERS,
        { dom => $self->{id}, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

sub get_block_info($self, $path, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_BLOCK_INFO,
        { dom => $self->{id}, path => $path, flags => $flags // 0 } );
}

async sub get_block_io_tune($self, $disk, $flags = 0) {
    $flags |= await $self->{client}->_typed_param_string_okay();
    my $nparams = await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_BLOCK_IO_TUNE,
        { dom => $self->{id}, disk => $disk, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_BLOCK_IO_TUNE,
        { dom => $self->{id}, disk => $disk, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

sub get_control_info($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_CONTROL_INFO,
        { dom => $self->{id}, flags => $flags // 0 } );
}

async sub get_cpu_stats($self, $start_cpu, $ncpus, $flags = 0) {
    $flags |= await $self->{client}->_typed_param_string_okay();
    my $nparams = await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_CPU_STATS,
        { dom => $self->{id}, nparams => 0, start_cpu => $start_cpu, ncpus => $ncpus, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_CPU_STATS,
        { dom => $self->{id}, nparams => $nparams, start_cpu => $start_cpu, ncpus => $ncpus, flags => $flags // 0 }, unwrap => 'params' );
}

async sub get_disk_errors($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_DISK_ERRORS,
        { dom => $self->{id}, maxerrors => $remote->DOMAIN_DISK_ERRORS_MAX, flags => $flags // 0 }, unwrap => 'errors' );
}

async sub get_fsinfo($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_FSINFO,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'info' );
}

async sub get_guest_info($self, $types, $flags = 0) {
    $flags |= await $self->{client}->_typed_param_string_okay();
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_GUEST_INFO,
        { dom => $self->{id}, types => $types, flags => $flags // 0 }, unwrap => 'params' );
}

async sub get_guest_vcpus($self, $flags = 0) {
    $flags |= await $self->{client}->_typed_param_string_okay();
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_GUEST_VCPUS,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'params' );
}

async sub get_hostname($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_HOSTNAME,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'hostname' );
}

sub get_info($self) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_INFO,
        { dom => $self->{id} } );
}

async sub get_interface_parameters($self, $device, $flags = 0) {
    $flags |= await $self->{client}->_typed_param_string_okay();
    my $nparams = await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_INTERFACE_PARAMETERS,
        { dom => $self->{id}, device => $device, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_INTERFACE_PARAMETERS,
        { dom => $self->{id}, device => $device, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

sub get_job_info($self) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_JOB_INFO,
        { dom => $self->{id} } );
}

sub get_job_stats($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_JOB_STATS,
        { dom => $self->{id}, flags => $flags // 0 } );
}

async sub get_max_memory($self) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_MAX_MEMORY,
        { dom => $self->{id} }, unwrap => 'memory' );
}

async sub get_max_vcpus($self) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_MAX_VCPUS,
        { dom => $self->{id} }, unwrap => 'num' );
}

async sub get_memory_parameters($self, $flags = 0) {
    $flags |= await $self->{client}->_typed_param_string_okay();
    my $nparams = await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_MEMORY_PARAMETERS,
        { dom => $self->{id}, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_MEMORY_PARAMETERS,
        { dom => $self->{id}, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

async sub get_messages($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_MESSAGES,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'msgs' );
}

async sub get_metadata($self, $type, $uri, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_METADATA,
        { dom => $self->{id}, type => $type, uri => $uri, flags => $flags // 0 }, unwrap => 'metadata' );
}

async sub get_numa_parameters($self, $flags = 0) {
    $flags |= await $self->{client}->_typed_param_string_okay();
    my $nparams = await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_NUMA_PARAMETERS,
        { dom => $self->{id}, nparams => 0, flags => $flags // 0 }, unwrap => 'nparams' );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_NUMA_PARAMETERS,
        { dom => $self->{id}, nparams => $nparams, flags => $flags // 0 }, unwrap => 'params' );
}

async sub get_os_type($self) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_OS_TYPE,
        { dom => $self->{id} }, unwrap => 'type' );
}

async sub get_scheduler_parameters($self) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_SCHEDULER_PARAMETERS,
        { dom => $self->{id}, nparams => $remote->DOMAIN_SCHEDULER_PARAMETERS_MAX }, unwrap => 'params' );
}

async sub get_scheduler_parameters_flags($self, $flags = 0) {
    $flags |= await $self->{client}->_typed_param_string_okay();
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_SCHEDULER_PARAMETERS_FLAGS,
        { dom => $self->{id}, nparams => $remote->DOMAIN_SCHEDULER_PARAMETERS_MAX, flags => $flags // 0 }, unwrap => 'params' );
}

async sub get_scheduler_type($self) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_SCHEDULER_TYPE,
        { dom => $self->{id} }, unwrap => 'type' );
}

sub get_state($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_STATE,
        { dom => $self->{id}, flags => $flags // 0 } );
}

async sub get_vcpus_flags($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_VCPUS_FLAGS,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'num' );
}

async sub get_xml_desc($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_GET_XML_DESC,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'xml' );
}

sub graphics_reload($self, $type, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_GRAPHICS_RELOAD,
        { dom => $self->{id}, type => $type, flags => $flags // 0 }, empty => 1 );
}

async sub has_current_snapshot($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_HAS_CURRENT_SNAPSHOT,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'result' );
}

async sub has_managed_save_image($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_HAS_MANAGED_SAVE_IMAGE,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'result' );
}

sub inject_nmi($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_INJECT_NMI,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

async sub interface_addresses($self, $source, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_INTERFACE_ADDRESSES,
        { dom => $self->{id}, source => $source, flags => $flags // 0 }, unwrap => 'ifaces' );
}

sub interface_stats($self, $device) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_INTERFACE_STATS,
        { dom => $self->{id}, device => $device } );
}

async sub is_active($self) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_IS_ACTIVE,
        { dom => $self->{id} }, unwrap => 'active' );
}

async sub is_persistent($self) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_IS_PERSISTENT,
        { dom => $self->{id} }, unwrap => 'persistent' );
}

async sub is_updated($self) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_IS_UPDATED,
        { dom => $self->{id} }, unwrap => 'updated' );
}

async sub list_all_checkpoints($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_LIST_ALL_CHECKPOINTS,
        { dom => $self->{id}, need_results => $remote->DOMAIN_CHECKPOINT_LIST_MAX, flags => $flags // 0 }, unwrap => 'checkpoints' );
}

async sub list_all_snapshots($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_LIST_ALL_SNAPSHOTS,
        { dom => $self->{id}, need_results => $remote->DOMAIN_SNAPSHOT_LIST_MAX, flags => $flags // 0 }, unwrap => 'snapshots' );
}

sub managed_save($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_MANAGED_SAVE,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub managed_save_define_xml($self, $dxml, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_MANAGED_SAVE_DEFINE_XML,
        { dom => $self->{id}, dxml => $dxml, flags => $flags // 0 }, empty => 1 );
}

async sub managed_save_get_xml_desc($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_MANAGED_SAVE_GET_XML_DESC,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'xml' );
}

sub managed_save_remove($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_MANAGED_SAVE_REMOVE,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

async sub memory_stats($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_MEMORY_STATS,
        { dom => $self->{id}, maxStats => $remote->DOMAIN_MEMORY_STATS_MAX, flags => $flags // 0 }, unwrap => 'stats' );
}

async sub migrate_get_compression_cache($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_MIGRATE_GET_COMPRESSION_CACHE,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'cacheSize' );
}

async sub migrate_get_max_downtime($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_MIGRATE_GET_MAX_DOWNTIME,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'downtime' );
}

async sub migrate_get_max_speed($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_MIGRATE_GET_MAX_SPEED,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'bandwidth' );
}

sub migrate_set_compression_cache($self, $cacheSize, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_MIGRATE_SET_COMPRESSION_CACHE,
        { dom => $self->{id}, cacheSize => $cacheSize, flags => $flags // 0 }, empty => 1 );
}

sub migrate_set_max_downtime($self, $downtime, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_MIGRATE_SET_MAX_DOWNTIME,
        { dom => $self->{id}, downtime => $downtime, flags => $flags // 0 }, empty => 1 );
}

sub migrate_set_max_speed($self, $bandwidth, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_MIGRATE_SET_MAX_SPEED,
        { dom => $self->{id}, bandwidth => $bandwidth, flags => $flags // 0 }, empty => 1 );
}

sub migrate_start_post_copy($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_MIGRATE_START_POST_COPY,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub open_channel($self, $name, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_OPEN_CHANNEL,
        { dom => $self->{id}, name => $name, flags => $flags // 0 }, stream => 'read', empty => 1 );
}

sub open_console($self, $dev_name, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_OPEN_CONSOLE,
        { dom => $self->{id}, dev_name => $dev_name, flags => $flags // 0 }, stream => 'read', empty => 1 );
}

sub pin_iothread($self, $iothreads_id, $cpumap, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_PIN_IOTHREAD,
        { dom => $self->{id}, iothreads_id => $iothreads_id, cpumap => $cpumap, flags => $flags // 0 }, empty => 1 );
}

sub pin_vcpu($self, $vcpu, $cpumap) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_PIN_VCPU,
        { dom => $self->{id}, vcpu => $vcpu, cpumap => $cpumap }, empty => 1 );
}

sub pin_vcpu_flags($self, $vcpu, $cpumap, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_PIN_VCPU_FLAGS,
        { dom => $self->{id}, vcpu => $vcpu, cpumap => $cpumap, flags => $flags // 0 }, empty => 1 );
}

sub pm_suspend_for_duration($self, $target, $duration, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_PM_SUSPEND_FOR_DURATION,
        { dom => $self->{id}, target => $target, duration => $duration, flags => $flags // 0 }, empty => 1 );
}

sub pm_wakeup($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_PM_WAKEUP,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub reboot($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_REBOOT,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

async sub rename($self, $new_name, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_RENAME,
        { dom => $self->{id}, new_name => $new_name, flags => $flags // 0 }, unwrap => 'retcode' );
}

sub reset($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_RESET,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub resume($self) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_RESUME,
        { dom => $self->{id} }, empty => 1 );
}

sub save($self, $to) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SAVE,
        { dom => $self->{id}, to => $to }, empty => 1 );
}

sub save_flags($self, $to, $dxml, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SAVE_FLAGS,
        { dom => $self->{id}, to => $to, dxml => $dxml, flags => $flags // 0 }, empty => 1 );
}

async sub save_params($self, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SAVE_PARAMS,
        { dom => $self->{id}, params => $params, flags => $flags // 0 }, empty => 1 );
}

async sub screenshot($self, $screen, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SCREENSHOT,
        { dom => $self->{id}, screen => $screen, flags => $flags // 0 }, unwrap => 'mime', stream => 'read' );
}

sub send_key($self, $codeset, $holdtime, $keycodes, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SEND_KEY,
        { dom => $self->{id}, codeset => $codeset, holdtime => $holdtime, keycodes => $keycodes, flags => $flags // 0 }, empty => 1 );
}

sub send_process_signal($self, $pid_value, $signum, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SEND_PROCESS_SIGNAL,
        { dom => $self->{id}, pid_value => $pid_value, signum => $signum, flags => $flags // 0 }, empty => 1 );
}

sub set_autostart($self, $autostart) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_AUTOSTART,
        { dom => $self->{id}, autostart => $autostart }, empty => 1 );
}

async sub set_blkio_parameters($self, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_BLKIO_PARAMETERS,
        { dom => $self->{id}, params => $params, flags => $flags // 0 }, empty => 1 );
}

async sub set_block_io_tune($self, $disk, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_BLOCK_IO_TUNE,
        { dom => $self->{id}, disk => $disk, params => $params, flags => $flags // 0 }, empty => 1 );
}

sub set_block_threshold($self, $dev, $threshold, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_BLOCK_THRESHOLD,
        { dom => $self->{id}, dev => $dev, threshold => $threshold, flags => $flags // 0 }, empty => 1 );
}

sub set_guest_vcpus($self, $cpumap, $state, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_GUEST_VCPUS,
        { dom => $self->{id}, cpumap => $cpumap, state => $state, flags => $flags // 0 }, empty => 1 );
}

async sub set_interface_parameters($self, $device, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_INTERFACE_PARAMETERS,
        { dom => $self->{id}, device => $device, params => $params, flags => $flags // 0 }, empty => 1 );
}

async sub set_iothread_params($self, $iothread_id, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_IOTHREAD_PARAMS,
        { dom => $self->{id}, iothread_id => $iothread_id, params => $params, flags => $flags // 0 }, empty => 1 );
}

async sub set_launch_security_state($self, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_LAUNCH_SECURITY_STATE,
        { dom => $self->{id}, params => $params, flags => $flags // 0 }, empty => 1 );
}

sub set_lifecycle_action($self, $type, $action, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_LIFECYCLE_ACTION,
        { dom => $self->{id}, type => $type, action => $action, flags => $flags // 0 }, empty => 1 );
}

sub set_max_memory($self, $memory) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_MAX_MEMORY,
        { dom => $self->{id}, memory => $memory }, empty => 1 );
}

sub set_memory($self, $memory) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_MEMORY,
        { dom => $self->{id}, memory => $memory }, empty => 1 );
}

sub set_memory_flags($self, $memory, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_MEMORY_FLAGS,
        { dom => $self->{id}, memory => $memory, flags => $flags // 0 }, empty => 1 );
}

async sub set_memory_parameters($self, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_MEMORY_PARAMETERS,
        { dom => $self->{id}, params => $params, flags => $flags // 0 }, empty => 1 );
}

sub set_memory_stats_period($self, $period, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_MEMORY_STATS_PERIOD,
        { dom => $self->{id}, period => $period, flags => $flags // 0 }, empty => 1 );
}

sub set_metadata($self, $type, $metadata, $key, $uri, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_METADATA,
        { dom => $self->{id}, type => $type, metadata => $metadata, key => $key, uri => $uri, flags => $flags // 0 }, empty => 1 );
}

async sub set_numa_parameters($self, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_NUMA_PARAMETERS,
        { dom => $self->{id}, params => $params, flags => $flags // 0 }, empty => 1 );
}

async sub set_perf_events($self, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_PERF_EVENTS,
        { dom => $self->{id}, params => $params, flags => $flags // 0 }, empty => 1 );
}

async sub set_scheduler_parameters($self, $params) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_SCHEDULER_PARAMETERS,
        { dom => $self->{id}, params => $params }, empty => 1 );
}

async sub set_scheduler_parameters_flags($self, $params, $flags = 0) {
    $params = await $self->{client}->_filter_typed_param_string( $params );
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_SCHEDULER_PARAMETERS_FLAGS,
        { dom => $self->{id}, params => $params, flags => $flags // 0 }, empty => 1 );
}

sub set_time($self, $seconds, $nseconds, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_TIME,
        { dom => $self->{id}, seconds => $seconds, nseconds => $nseconds, flags => $flags // 0 }, empty => 1 );
}

sub set_user_password($self, $user, $password, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_USER_PASSWORD,
        { dom => $self->{id}, user => $user, password => $password, flags => $flags // 0 }, empty => 1 );
}

sub set_vcpu($self, $cpumap, $state, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_VCPU,
        { dom => $self->{id}, cpumap => $cpumap, state => $state, flags => $flags // 0 }, empty => 1 );
}

sub set_vcpus($self, $nvcpus) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_VCPUS,
        { dom => $self->{id}, nvcpus => $nvcpus }, empty => 1 );
}

sub set_vcpus_flags($self, $nvcpus, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SET_VCPUS_FLAGS,
        { dom => $self->{id}, nvcpus => $nvcpus, flags => $flags // 0 }, empty => 1 );
}

sub shutdown($self) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SHUTDOWN,
        { dom => $self->{id} }, empty => 1 );
}

sub shutdown_flags($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SHUTDOWN_FLAGS,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

async sub snapshot_create_xml($self, $xml_desc, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_CREATE_XML,
        { dom => $self->{id}, xml_desc => $xml_desc, flags => $flags // 0 }, unwrap => 'snap' );
}

async sub snapshot_current($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_CURRENT,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'snap' );
}

async sub snapshot_list_names($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_LIST_NAMES,
        { dom => $self->{id}, maxnames => $remote->DOMAIN_SNAPSHOT_LIST_MAX, flags => $flags // 0 }, unwrap => 'names' );
}

async sub snapshot_lookup_by_name($self, $name, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_LOOKUP_BY_NAME,
        { dom => $self->{id}, name => $name, flags => $flags // 0 }, unwrap => 'snap' );
}

async sub snapshot_num($self, $flags = 0) {
    return await $self->{client}->_call(
        $remote->PROC_DOMAIN_SNAPSHOT_NUM,
        { dom => $self->{id}, flags => $flags // 0 }, unwrap => 'num' );
}

sub start_dirty_rate_calc($self, $seconds, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_START_DIRTY_RATE_CALC,
        { dom => $self->{id}, seconds => $seconds, flags => $flags // 0 }, empty => 1 );
}

sub suspend($self) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_SUSPEND,
        { dom => $self->{id} }, empty => 1 );
}

sub undefine($self) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_UNDEFINE,
        { dom => $self->{id} }, empty => 1 );
}

sub undefine_flags($self, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_UNDEFINE_FLAGS,
        { dom => $self->{id}, flags => $flags // 0 }, empty => 1 );
}

sub update_device_flags($self, $xml, $flags = 0) {
    return $self->{client}->_call(
        $remote->PROC_DOMAIN_UPDATE_DEVICE_FLAGS,
        { dom => $self->{id}, xml => $xml, flags => $flags // 0 }, empty => 1 );
}



1;


__END__

=head1 NAME

Sys::Async::Virt::Domain - Client side proxy to remote LibVirt domain

=head1 VERSION

v0.0.11

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

=item MIGRATE_PARAM_GRAPHICS_URI

=item MIGRATE_PARAM_LISTEN_ADDRESS

=item MIGRATE_PARAM_MIGRATE_DISKS

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

=item LAUNCH_SECURITY_SEV_SECRET_HEADER

=item LAUNCH_SECURITY_SEV_SECRET

=item LAUNCH_SECURITY_SEV_SECRET_SET_ADDRESS

=item GUEST_INFO_USERS

=item GUEST_INFO_OS

=item GUEST_INFO_TIMEZONE

=item GUEST_INFO_HOSTNAME

=item GUEST_INFO_FILESYSTEM

=item GUEST_INFO_DISKS

=item GUEST_INFO_INTERFACES

=item AGENT_RESPONSE_TIMEOUT_BLOCK

=item AGENT_RESPONSE_TIMEOUT_DEFAULT

=item AGENT_RESPONSE_TIMEOUT_NOWAIT

=item BACKUP_BEGIN_REUSE_EXTERNAL

=item AUTHORIZED_SSH_KEYS_SET_APPEND

=item AUTHORIZED_SSH_KEYS_SET_REMOVE

=item MESSAGE_DEPRECATION

=item MESSAGE_TAINTING

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


  Copyright (C) 2024 Erik Huelsmann

All rights reserved. This program is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
