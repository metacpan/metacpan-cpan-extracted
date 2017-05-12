use Test;
BEGIN { plan tests => 22 };

use Sys::Statgrab;
ok(1); # If we made it this far, we're ok.


my $fail;
foreach my $constname (qw(
	SG_ERROR_ASPRINTF SG_ERROR_DEVSTAT_GETDEVS SG_ERROR_DEVSTAT_SELECTDEVS
	SG_ERROR_ENOENT SG_ERROR_GETIFADDRS SG_ERROR_GETMNTINFO
	SG_ERROR_GETPAGESIZE SG_ERROR_KSTAT_DATA_LOOKUP SG_ERROR_KSTAT_LOOKUP
	SG_ERROR_KSTAT_OPEN SG_ERROR_KSTAT_READ SG_ERROR_KVM_GETSWAPINFO
	SG_ERROR_KVM_OPENFILES SG_ERROR_MALLOC SG_ERROR_NONE SG_ERROR_OPEN
	SG_ERROR_OPENDIR SG_ERROR_PARSE SG_ERROR_SETEGID SG_ERROR_SETEUID
	SG_ERROR_SETMNTENT SG_ERROR_SOCKET SG_ERROR_SWAPCTL SG_ERROR_SYSCONF
	SG_ERROR_SYSCTL SG_ERROR_SYSCTLBYNAME SG_ERROR_SYSCTLNAMETOMIB
	SG_ERROR_UNAME SG_ERROR_UNSUPPORTED SG_ERROR_XSW_VER_MISMATCH
	SG_IFACE_DUPLEX_FULL SG_IFACE_DUPLEX_HALF SG_IFACE_DUPLEX_UNKNOWN
	SG_PROCESS_STATE_RUNNING SG_PROCESS_STATE_SLEEPING
	SG_PROCESS_STATE_STOPPED SG_PROCESS_STATE_UNKNOWN
	SG_PROCESS_STATE_ZOMBIE)) {
  next if (eval "my \$a = $constname; 1");
  if ($@ =~ /^Your vendor has not defined Unix::Statgrab macro $constname/) {
    print "# pass: $@";
  } else {
    print "# fail: $@";
    $fail = 1;
  }
}
if ($fail) {
    ok(0);
} else {
    ok(1);
}

my %funcs = (
    get_host_info		=> [ qw/os_name os_release os_version platform hostname uptime/ ],
    get_cpu_stats		=> [ qw/user kernel idle iowait swap nice total systime/],
    get_cpu_stats_diff		=> [ qw/user kernel idle iowait swap nice total systime/],
    get_cpu_percents		=> [ qw/user kernel idle iowait swap nice systime/],
    get_disk_io_stats		=> [ qw/num_disks disk_name read_bytes write_bytes systime/ ],
    get_disk_io_stats_diff	=> [ qw/num_disks disk_name read_bytes write_bytes systime/ ],
    get_fs_stats		=> [ qw/num_fs device_name fs_type mnt_point size 
					used avail total_inodes used_inodes free_inodes
					avail_inodes io_size block_size total_blocks
					free_blocks used_blocks avail_blocks/ ],
    get_load_stats		=> [ qw/min1 min5 min15/ ],
    get_mem_stats		=> [ qw/total free used cache/ ],
    get_swap_stats		=> [ qw/total free used/ ],
    get_network_io_stats	=> [ qw/num_ifaces interface_name tx rx ipackets opackets
					ierrors oerrors collisions systime/ ],
    get_network_io_stats_diff	=> [ qw/num_ifaces interface_name tx rx ipackets opackets
					ierrors oerrors collisions systime/ ],
    get_network_iface_stats	=> [ qw/num_ifaces interface_name speed dup up/ ],
    get_page_stats		=> [ qw/pages_pagein pages_pageout systime/ ],
    get_page_stats_diff		=> [ qw/pages_pagein pages_pageout systime/ ],
    get_user_stats		=> [ qw/num_entries name_list/ ],
);

my @cygwin_unsupported = qw(
	get_disk_io_stats
	get_disk_io_stats_diff
	get_fs_stats
	get_load_stats
	get_network_io_stats
	get_network_io_stats_diff
	get_network_iface_stats
);

# we only check that nothing segfaults
while (my ($func, $methods) = each %funcs) {
	if ($^O eq 'cygwin' && grep(/^$func$/, @cygwin_unsupported)) {
		warn "#Skipping $^O currently unsupported function $func";
		ok(1);
		next;
	}
    if (my $o = &{"Sys::Statgrab::$func"}) {
	for (@$methods) {
	    # perl5.5.3 doesn't allow $o->$_
	    my $class = ref $o;
	    &{ "${class}::$_" }($o);
	}
    }
    ok(1);
}

my $p = get_process_stats;
my @p;
if ($p) {
    $p->sort_by("name");
    ok(1);
    @p = $p->all_procs;
    ok(1);
} else {
    # yes, I know, it's insane
    ok(1) for 1 .. 2;
}

my $pr = $p[0];
if ($pr) {
    $pr->proc_name;
    $pr->proc_title;
    $pr->pid;
    $pr->parent_pid;
    $pr->pgid;
    $pr->uid;
    $pr->euid;
    $pr->gid;
    $pr->egid;
    $pr->proc_size;
    $pr->proc_resident;
    $pr->time_spent;
    $pr->cpu_percent;
    $pr->nice;
    $pr->state;
} 
ok(1);

   
@p = sort sort_procs_by_name $p->all_procs;
@p = sort sort_procs_by_pid  $p->all_procs;
@p = sort sort_procs_by_uid  $p->all_procs;
@p = sort sort_procs_by_gid  $p->all_procs;
@p = sort sort_procs_by_size $p->all_procs;
@p = sort sort_procs_by_res  $p->all_procs;
@p = sort sort_procs_by_cpu  $p->all_procs;
@p = sort sort_procs_by_time $p->all_procs;
ok(1);

