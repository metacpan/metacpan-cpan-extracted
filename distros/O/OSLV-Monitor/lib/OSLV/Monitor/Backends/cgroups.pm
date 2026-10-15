package OSLV::Monitor::Backends::cgroups;

use 5.006;
use strict;
use warnings;
use JSON;
use Clone 'clone';
use File::Slurp;
use Scalar::Util qw(looks_like_number);
use Time::HiRes  qw(time);

=head1 NAME

OSLV::Monitor::Backends::cgroups - Backend for Linux cgroups.

=head1 VERSION

Version 1.0.6

=cut

our $VERSION = '1.0.6';

=head1 SYNOPSIS

    use OSLV::Monitor::Backends::cgroups;

    my $backend = OSLV::Monitor::Backends::cgroups->new;

    my $usable=$backend->usable;
    if ( $usable ){
        $return_hash_ref=$backend->run;
    }

The cgroup to name mapping is done like below.

    systemd -> s_$name
    user -> u_$name
    docker -> d_$name
    podman -> p_$name
    machine.slice, non-podman -> m_$type_$name
        type is qemu, lxc, or nspawn, omitted if unknown
    anything else -> $name

Anything else is formed like below.

	$cgroup =~ s/^0\:\:\///;
    $cgroup =~ s/\/.*//;

The following ps to stats mapping are as below.

    %cpu -> percent-cpu
    %mem -> percent-memory
    rss -> rss
    vsize -> virtual-size
    trs -> text-size
    drs -> data-size
    size -> size

"procs" is a total number of procs in that cgroup.

The rest of the values are pulled from the following files with
the names kept as is.

    cpu.stat
    io.stat
    memory.stat

The following mappings are done though.

    pgfault -> minor-faults
    pgmajfault -> major-faults
    usage_usec -> cpu-time
    system_usec -> system-time
    user_usec -> user-time
    throttled_usec -> throttled-time
    burst_usec -> burst-time

=head1 METHODS

=head2 new

Initiates the backend object.

    my $backend=OSLV::MOnitor::Backend::cgroups->new(obj=>$obj)

    - base_dir :: Path to use for the base dir, where the proc/cgroup
            cache, linux_cache.json, is is created.
        Default :: /var/cache/oslv_monitor

    - obj :: The OSLVM::Monitor object.

    - time_divider :: What to use for "usec" to sec conversion. While normally
              the usec counters are microseconds, sometimes the value is in
              nanoseconds, despit the name.
        Default :: 1000000

=cut

sub new {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{base_dir} ) ) {
		$opts{base_dir} = '/var/cache/oslv_monitor';
	}

	if ( !defined( $opts{time_divider} ) ) {
		$opts{time_divider} = 1000000;
	} else {
		if ( !looks_like_number( $opts{time_divider} ) ) {
			die('time_divider is not a number');
		}
	}

	if ( !defined( $opts{obj} ) ) {
		die('$opts{obj} is undef');
	} elsif ( ref( $opts{obj} ) ne 'OSLV::Monitor' ) {
		die('ref $opts{obj} is not OSLV::Monitor');
	}

	my $self = {
		time_divider    => $opts{time_divider},
		version         => 1,
		cgroupns_usable => 1,
		mappings        => {},
		podman_mapping  => {},
		podman_info     => {},
		docker_mapping  => {},
		docker_info     => {},
		uid_mapping     => {},
		obj             => $opts{obj},
		cache_file      => $opts{base_dir} . '/linux_cache.json',
		counters        => {
			'cpu-time'                     => 1,
			'system-time'                  => 1,
			'user-time'                    => 1,
			'throttled-time'               => 1,
			'burst-time'                   => 1,
			'core_sched.force_idle-time'   => 1,
			'read-blocks'                  => 1,
			'major-faults'                 => 1,
			'involuntary-context-switches' => 1,
			'minor-faults'                 => 1,
			'nr_bursts'                    => 1,
			'nr_periods'                   => 1,
			'nr_throttled'                 => 1,
			'received-messages'            => 1,
			'sent-messages'                => 1,
			'swaps'                        => 1,
			'voluntary-context-switches'   => 1,
			'written-blocks'               => 1,
			'copy-on-write-faults'         => 1,
			'signals-taken'                => 1,
			'rbytes'                       => 1,
			'wbytes'                       => 1,
			'dbytes'                       => 1,
			'rios'                         => 1,
			'wios'                         => 1,
			'dios'                         => 1,
			'pgactivate'                   => 1,
			'pgdeactivate'                 => 1,
			'pglazyfree'                   => 1,
			'pglazyfreed'                  => 1,
			'pgrefill'                     => 1,
			'pgscan'                       => 1,
			'pgscan_direct'                => 1,
			'pgscan_khugepaged'            => 1,
			'pgscan_kswapd'                => 1,
			'pgsteal'                      => 1,
			'pgsteal_direct'               => 1,
			'pgsteal_khugepaged'           => 1,
			'pgsteal_kswapd'               => 1,
			'thp_fault_alloc'              => 1,
			'thp_collapse_alloc'           => 1,
			'thp_swpout'                   => 1,
			'thp_swpout_fallback'          => 1,
			'zswpin'                       => 1,
			'zswpout'                      => 1,
			'zswpwb'                       => 1,
		},
		cache     => {},
		new_cache => {},
		# seconds since the previous run, for turning counter deltas into rates...
		# set by run from the time saved in the cache, 300 if that is unknown
		interval => 300,
	};
	bless $self;

	return $self;
} ## end sub new

=head2 run

    $return_hash_ref=$backend->run(obj=>$obj);

=cut

sub run {
	my $self = $_[0];

	my $data = {
		errors        => [],
		cache_failure => 0,
		oslvms        => {},
		has           => {
			'linux_mem_stats' => 1,
			'rwdops'          => 0,
			'rwdbytes'        => 0,
			'rwdblocks'       => 0,
			'signals-taken'   => 0,
			'recv_sent_msgs'  => 0,
			'cows'            => 0,
			'stack-size'      => 0,
			'swaps'           => 0,
			'sock'            => 1,
			'burst_time'      => 0,
			'throttled_time'  => 0,
			'burst_count'     => 0,
			'throttled_count' => 0,
		},
		totals        => {
			procs                          => 0,
			'percent-cpu'                  => 0,
			'percent-memory'               => 0,
			'system-time'                  => 0,
			'cpu-time'                     => 0,
			'user-time'                    => 0,
			rbytes                         => 0,
			wbytes                         => 0,
			rios                           => 0,
			wios                           => 0,
			dbytes                         => 0,
			dios                           => 0,
			'core_sched.force_idle_usec'   => 0,
			'core_sched.force_idle-time'   => 0,
			nr_periods                     => 0,
			nr_throttled                   => 0,
			throttled_usec                 => 0,
			'throttled-time'               => 0,
			nr_bursts                      => 0,
			burst_usec                     => 0,
			'burst-time'                   => 0,
			anon                           => 0,
			file                           => 0,
			kernel                         => 0,
			kernel_stack                   => 0,
			pagetables                     => 0,
			sec_pagetables                 => 0,
			percpu                         => 0,
			sock                           => 0,
			vmalloc                        => 0,
			shmem                          => 0,
			zswap                          => 0,
			zswapped                       => 0,
			file_mapped                    => 0,
			file_dirty                     => 0,
			file_writeback                 => 0,
			swapcached                     => 0,
			anon_thp                       => 0,
			file_thp                       => 0,
			shmem_thp                      => 0,
			inactive_anon                  => 0,
			active_anon                    => 0,
			inactive_file                  => 0,
			active_file                    => 0,
			unevictable                    => 0,
			slab_reclaimable               => 0,
			slab_unreclaimable             => 0,
			slab                           => 0,
			workingset_refault_anon        => 0,
			workingset_refault_file        => 0,
			workingset_activate_anon       => 0,
			workingset_activate_file       => 0,
			workingset_restore_anon        => 0,
			workingset_restore_file        => 0,
			workingset_nodereclaim         => 0,
			pgscan                         => 0,
			pgsteal                        => 0,
			pgscan_kswapd                  => 0,
			pgscan_direct                  => 0,
			pgscan_khugepaged              => 0,
			pgsteal_kswapd                 => 0,
			pgsteal_direct                 => 0,
			pgsteal_khugepaged             => 0,
			'minor-faults'                 => 0,
			'major-faults'                 => 0,
			pgrefill                       => 0,
			pgactivate                     => 0,
			pgdeactivate                   => 0,
			pglazyfree                     => 0,
			pglazyfreed                    => 0,
			zswpin                         => 0,
			zswpout                        => 0,
			zswpwb                         => 0,
			thp_fault_alloc                => 0,
			thp_collapse_alloc             => 0,
			thp_swpout                     => 0,
			thp_swpout_fallback            => 0,
			rss                            => 0,
			'data-size'                    => 0,
			'text-size'                    => 0,
			'size'                         => 0,
			'virtual-size'                 => 0,
			'elapsed-times'                => 0,
			'involuntary-context-switches' => 0,
			'voluntary-context-switches'   => 0,
		},
	};

	my $cache_is_new = 0;
	if ( -f $self->{cache_file} ) {
		eval {
			my $raw_cache = read_file( $self->{cache_file} );
			$self->{cache} = decode_json($raw_cache);
		};
		if ($@) {
			push(
				@{ $data->{errors} },
				'reading proc cache "' . $self->{cache_file} . '" failed... using a empty one...' . $@
			);
			$data->{cache_failure} = 1;
			# treat a corrupt/truncated cache as a fresh one so this run
			# regenerates and overwrites it with valid data instead of getting
			# permanently stuck on the bad file
			$self->{cache} = {};
			$cache_is_new  = 1;
		}
	} else {
		$cache_is_new = 1;
	}

	# rates are computed over the time since the previous run, as saved in the
	# cache, instead of assuming it was 300 seconds ago
	my $run_time = time;
	$self->{interval} = $self->{obj}->interval_since( $self->{cache}, $run_time );
	$self->{new_cache}{__oslv_monitor__} = { time => $run_time };

	my $base_stats = {
		procs                          => 0,
		'percent-cpu'                  => 0,
		'percent-memory'               => 0,
		'system-time'                  => 0,
		'cpu-time'                     => 0,
		'user-time'                    => 0,
		rbytes                         => 0,
		wbytes                         => 0,
		rios                           => 0,
		wios                           => 0,
		dbytes                         => 0,
		dios                           => 0,
		'core_sched.force_idle_usec'   => 0,
		'core_sched.force_idle-time'   => 0,
		nr_periods                     => 0,
		nr_throttled                   => 0,
		throttled_usec                 => 0,
		'throttled-time'               => 0,
		nr_bursts                      => 0,
		burst_usec                     => 0,
		'burst-time'                   => 0,
		anon                           => 0,
		file                           => 0,
		kernel                         => 0,
		kernel_stack                   => 0,
		pagetables                     => 0,
		sec_pagetables                 => 0,
		percpu                         => 0,
		sock                           => 0,
		vmalloc                        => 0,
		shmem                          => 0,
		zswap                          => 0,
		zswapped                       => 0,
		file_mapped                    => 0,
		file_dirty                     => 0,
		file_writeback                 => 0,
		swapcached                     => 0,
		anon_thp                       => 0,
		file_thp                       => 0,
		shmem_thp                      => 0,
		inactive_anon                  => 0,
		active_anon                    => 0,
		inactive_file                  => 0,
		active_file                    => 0,
		unevictable                    => 0,
		slab_reclaimable               => 0,
		slab_unreclaimable             => 0,
		slab                           => 0,
		workingset_refault_anon        => 0,
		workingset_refault_file        => 0,
		workingset_activate_anon       => 0,
		workingset_activate_file       => 0,
		workingset_restore_anon        => 0,
		workingset_restore_file        => 0,
		workingset_nodereclaim         => 0,
		pgscan                         => 0,
		pgsteal                        => 0,
		pgscan_kswapd                  => 0,
		pgscan_direct                  => 0,
		pgscan_khugepaged              => 0,
		pgsteal_kswapd                 => 0,
		pgsteal_direct                 => 0,
		pgsteal_khugepaged             => 0,
		'minor-faults'                 => 0,
		'major-faults'                 => 0,
		pgrefill                       => 0,
		pgactivate                     => 0,
		pgdeactivate                   => 0,
		pglazyfree                     => 0,
		pglazyfreed                    => 0,
		zswpin                         => 0,
		zswpout                        => 0,
		zswpwb                         => 0,
		thp_fault_alloc                => 0,
		thp_collapse_alloc             => 0,
		thp_swpout                     => 0,
		thp_swpout_fallback            => 0,
		rss                            => 0,
		'data-size'                    => 0,
		'text-size'                    => 0,
		'size'                         => 0,
		'virtual-size'                 => 0,
		'elapsed-times'                => 0,
		'involuntary-context-switches' => 0,
		'voluntary-context-switches'   => 0,
		'ip'                           => [],
		'path'                         => [],
	};

	my $stat_mapping = {
		'pgmajfault'                 => 'major-faults',
		'pgfault'                    => 'minor-faults',
		'usage_usec'                 => 'cpu-time',
		'user_usec'                  => 'user-time',
		'system_usec'                => 'system-time',
		'throttled_usec'             => 'throttled-time',
		'burst_usec'                 => 'burst-time',
		'core_sched.force_idle_usec' => 'core_sched.force_idle-time',
	};

	#
	# get podman/docker ID to name mappings
	#
	my @podman_compatible = ( 'docker', 'podman' );
	foreach my $cgroup_jank_type (@podman_compatible) {
		my $podman_output;
		if ( $cgroup_jank_type eq 'podman' ) {
			$podman_output = `podman ps --format json 2> /dev/null`;
		} elsif ( $cgroup_jank_type eq 'docker' ) {
			# --no-trunc is needed as for some unfathonable reason it truncates even when outputting json
			$podman_output = `docker ps --no-trunc --format json 2> /dev/null`;
			# returns a series of json entries seperated by a newline... the following expects it as
			# a array like podman outputs
			my @podman_outputA = split( /\n/, $podman_output );
			# and it is now a array of hashes as expected
			$podman_output = '[' . join( ',', @podman_outputA ) . ']';
		}
		if ( $? == 0 ) {
			my $podman_parsed;
			eval { $podman_parsed = decode_json($podman_output); };
			if ( defined($podman_parsed) && ref($podman_parsed) eq 'ARRAY' ) {
				foreach my $pod ( @{$podman_parsed} ) {
					my $pod_id;
					if ( defined( $pod->{'Id'} ) ) {
						$pod_id = $pod->{'Id'};
					} elsif ( defined( $pod->{'ID'} ) ) {
						$pod_id = $pod->{'ID'};
					}

					my $pod_name;
					if ( defined( $pod->{'PodName'} )
						&& ( $pod->{'PodName'} ne '' ) )
					{
						$pod_name = $pod->{'PodName'};
					} elsif ( defined( $pod->{'Names'} )
						&& ( ref( $pod->{'Names'} ) eq '' ) )
					{
						$pod_name = $pod->{'Names'};
					} elsif ( defined( $pod->{'Names'} )
						&& ( ref( $pod->{'Names'} ) eq 'ARRAY' )
						&& defined( $pod->{'Names'}[0] )
						&& ( ref( $pod->{'Names'}[0] ) eq '' ) )
					{
						$pod_name = $pod->{'Names'}[0];
					}

					if ( defined($pod_id) && defined($pod_name) ) {
						$self->{ $cgroup_jank_type . '_mapping' }{$pod_id} = {
							name     => $pod_name,
							Networks => $pod->{Networks},
						};
						my $inspect_output = `$cgroup_jank_type inspect $pod_id 2> /dev/null`;
						my $inspect_parsed;
						# every container in a podman pod maps to the pod name, so the info is
						# only created for the first and the rest are merged into it
						if ( !defined( $self->{ $cgroup_jank_type . '_info' }{$pod_name} ) ) {
							$self->{ $cgroup_jank_type . '_info' }{$pod_name} = { ip => [], path => [] };
						}
						my $pod_info = $self->{ $cgroup_jank_type . '_info' }{$pod_name};
						eval { $inspect_parsed = decode_json($inspect_output) };
						# record the container's root filesystem path when available
						if (   defined($inspect_parsed)
							&& ref($inspect_parsed) eq 'ARRAY'
							&& defined( $inspect_parsed->[0] )
							&& ref( $inspect_parsed->[0] ) eq 'HASH'
							&& defined( $inspect_parsed->[0]{GraphDriver} )
							&& ref( $inspect_parsed->[0]{GraphDriver} ) eq 'HASH'
							&& defined( $inspect_parsed->[0]{GraphDriver}{Data} )
							&& ref( $inspect_parsed->[0]{GraphDriver}{Data} ) eq 'HASH'
							&& defined( $inspect_parsed->[0]{GraphDriver}{Data}{MergedDir} )
							&& ref( $inspect_parsed->[0]{GraphDriver}{Data}{MergedDir} ) eq ''
							&& $inspect_parsed->[0]{GraphDriver}{Data}{MergedDir} ne '' )
						{
							my $merged_dir = $inspect_parsed->[0]{GraphDriver}{Data}{MergedDir};
							if ( !grep { $_ eq $merged_dir } @{ $pod_info->{path} } ) {
								push( @{ $pod_info->{path} }, $merged_dir );
							}
						}
						if (   defined($inspect_parsed)
							&& ref($inspect_parsed) eq 'ARRAY'
							&& defined( $inspect_parsed->[0] )
							&& ref( $inspect_parsed->[0] ) eq 'HASH'
							&& defined( $inspect_parsed->[0]{NetworkSettings} )
							&& ref( $inspect_parsed->[0]{NetworkSettings} ) eq 'HASH'
							&& defined( $inspect_parsed->[0]{NetworkSettings}{Networks} )
							&& ref( $inspect_parsed->[0]{NetworkSettings}{Networks} ) eq 'HASH' )
						{
							my @podman_networks = keys( %{ $inspect_parsed->[0]{NetworkSettings}{Networks} } );
							foreach my $network_to_process (@podman_networks) {
								my $current_network
									= $inspect_parsed->[0]{NetworkSettings}{Networks}{$network_to_process};
								if ( ref($current_network) eq 'HASH' ) {
									my $network_if;
									my $network_mac;
									if ( defined( $current_network->{MacAddress} )
										&& ref( $current_network->{MacAddress} ) eq '' )
									{
										$network_mac = $current_network->{MacAddress};
									}
									if ( defined( $current_network->{NetworkID} )
										&& ref( $current_network->{NetworkID} ) eq '' )
									{
										my $network_id = $current_network->{NetworkID};
										my $network_inspect_output
											= `$cgroup_jank_type network inspect $network_id 2> /dev/null`;
										my $network_inspect_parsed;
										eval { $network_inspect_parsed = decode_json($network_inspect_output) };
										if (   defined($network_inspect_parsed)
											&& ref($network_inspect_parsed) eq 'ARRAY'
											&& defined( $network_inspect_parsed->[0] )
											&& ref( $network_inspect_parsed->[0] ) eq 'HASH' )
										{
											my $network = $network_inspect_parsed->[0];
											# podman reports the interface directly, while docker has it as a
											# option for the bridge, and if not set there, it is br- followed
											# by the first 12 characters of the network ID
											if ( defined( $network->{network_interface} )
												&& ref( $network->{network_interface} ) eq '' )
											{
												$network_if = $network->{network_interface};
											} elsif ( ref( $network->{Options} ) eq 'HASH'
												&& defined( $network->{Options}{'com.docker.network.bridge.name'} )
												&& ref( $network->{Options}{'com.docker.network.bridge.name'} ) eq '' )
											{
												$network_if = $network->{Options}{'com.docker.network.bridge.name'};
											} elsif ( defined( $network->{Driver} )
												&& $network->{Driver} eq 'bridge'
												&& defined( $network->{Id} )
												&& ref( $network->{Id} ) eq '' )
											{
												$network_if = 'br-' . substr( $network->{Id}, 0, 12 );
											}
										} ## end if ( defined($network_inspect_parsed) && ...)
									} ## end if ( defined( $current_network->{NetworkID...}))

									# a network may have a IPv4 address, a IPv6 one, or both, and each
									# gets its own entry
									foreach my $ip_keys ( [ 'IPAddress', 'Gateway' ], [ 'GlobalIPv6Address', 'IPv6Gateway' ] )
									{
										my ( $ip_key, $gw_key ) = @{$ip_keys};
										if (   !defined( $current_network->{$ip_key} )
											|| ref( $current_network->{$ip_key} ) ne ''
											|| $current_network->{$ip_key} eq '' )
										{
											next;
										}
										my $net_work_info = {
											ip    => $current_network->{$ip_key},
											gw    => undef,
											gw_if => undef,
											mac   => $network_mac,
											if    => $network_if,
										};
										if (   defined( $current_network->{$gw_key} )
											&& ref( $current_network->{$gw_key} ) eq ''
											&& $current_network->{$gw_key} ne '' )
										{
											$net_work_info->{gw} = $current_network->{$gw_key};
										}
										if ( defined($network_if) ) {
											$net_work_info->{gw_if} = $self->route_get_if( $net_work_info->{ip}, $network_if );
										}
										# containers in a pod share the network namespace of the pod,
										# so the same IP turns up for each of them
										if ( !grep { $_->{ip} eq $net_work_info->{ip} } @{ $pod_info->{ip} } ) {
											push( @{ $pod_info->{ip} }, $net_work_info );
										}
									} ## end foreach my $ip_keys ( [ 'IPAddress', 'Gateway' ...])
								} ## end if ( ref($current_network) eq 'HASH' )
							} ## end foreach my $network_to_process (@podman_networks)
						} ## end if ( defined($inspect_parsed) && ref($inspect_parsed...))
					} ## end if ( defined($pod_id) && defined($pod_name...))
				} ## end foreach my $pod ( @{$podman_parsed} )
			} ## end if ( defined($podman_parsed) && ref($podman_parsed...))
		} ## end if ( $? == 0 )
	} ## end foreach my $cgroup_jank_type (@podman_compatible)

	#
	# gets of procs for finding a list of containers
	#
	#	my $ps_output = `ps -haxo pid,uid,gid,cgroupns,%cpu,%mem,rss,vsize,trs,drs,size,cgroup 2> /dev/null`;
	#	if ( $? != 0 ) {
	#		$self->{cgroupns_usable} = 0;
	my $ps_output = `ps -haxo pid,uid,gid,%cpu,%mem,rss,vsize,trs,drs,size,etimes,comm 2> /dev/null`;
	#	}
	my @ps_output_split = split( /\n/, $ps_output );
	my %found_cgroups;
	my %cgroups_percpu;
	my %cgroups_permem;
	my %cgroups_procs;
	my %cgroups_rss;
	my %cgroups_vsize;
	my %cgroups_trs;
	my %cgroups_drs;
	my %cgroups_size;
	my %cgroups_etimes;
	my %cgroups_invvol_ctxt_switches;
	my %cgroups_vol_ctxt_switches;
	my %cgroups_root_paths;

	foreach my $line (@ps_output_split) {
		$line =~ s/^\s+//;
		my $vol_ctxt_switches   = 0;
		my $invol_ctxt_switches = 0;
		my ( $pid, $uid, $gid, $percpu, $permem, $rss, $vsize, $trs, $drs, $size, $etimes, $comm );
		# comm is captured last, with a split limit, so a command name containing
		# whitespace does not shift the earlier fields
		( $pid, $uid, $gid, $percpu, $permem, $rss, $vsize, $trs, $drs, $size, $etimes, $comm )
			= split( /\s+/, $line, 12 );
		# skip the idle/swapper task... the Linux equivalent of FreeBSD's
		# [idle]... the true idle is PID 0 (swapper), which ps normally does
		# not list, but guard against it defensively so it can never be
		# counted as CPU usage
		if ( defined($comm) && ( $comm eq 'swapper' || $comm =~ m{^swapper/} ) ) {
			next;
		}

		# the cgroup is read from procfs rather than being fetched via ps as ps
		# hard truncates the cgroup column to 27 characters when it is not the
		# final column, regardless of -w/--width or COLUMNS... that both mangles
		# the name, mapping unrelated units to the same one, and leaves the path
		# under /sys/fs/cgroup non-existent, meaning no stats get read at all
		my $cgroup = $self->proc_cgroup($pid);
		# undef if the proc exited or is not under the unified hierarchy
		if ( !defined($cgroup) ) {
			next;
		}

		my $cache_name = 'proc-' . $pid . '-' . $uid . '-' . $gid . '-' . $cgroup;

		$found_cgroups{$cgroup} = $cgroup;

		# save the root fs path as seen by this process, resolving chroots
		# and the like... for the usual case this is just /
		my $proc_root_path = readlink( '/proc/' . $pid . '/root' );
		if ( defined($proc_root_path) ) {
			$cgroups_root_paths{$cgroup}{$proc_root_path} = 1;
		}

		eval {
			if ( -f '/proc/' . $pid . '/status' ) {
				my @switches_find = grep( /voluntary\_ctxt\_switches\:/, read_file( '/proc/' . $pid . '/status' ) );
				foreach my $found_switch (@switches_find) {
					chomp($found_switch);
					my @switch_split = split( /\:[\ \t]+/, $found_switch );
					if ( defined( $switch_split[0] ) && defined( $switch_split[1] ) ) {
						if ( $switch_split[0] eq 'voluntary_ctxt_switches' ) {
							$vol_ctxt_switches = $switch_split[1];
						} elsif ( $switch_split[0] eq 'nonvoluntary_ctxt_switches' ) {
							# the kernel calls these nonvoluntary and not involuntary
							$invol_ctxt_switches = $switch_split[1];
						}
					}
				} ## end foreach my $found_switch (@switches_find)
			} ## end if ( -f '/proc/' . $pid . '/status' )
		};
		$vol_ctxt_switches
			= $self->cache_process( $cache_name, 'voluntary-context-switches', $vol_ctxt_switches, $etimes );
		$invol_ctxt_switches
			= $self->cache_process( $cache_name, 'involuntary-context-switches', $invol_ctxt_switches, $etimes );

		if ( !defined( $cgroups_permem{$cgroup} ) ) {
			$cgroups_permem{$cgroup}               = $permem;
			$cgroups_percpu{$cgroup}               = $percpu;
			$cgroups_procs{$cgroup}                = 1;
			$cgroups_rss{$cgroup}                  = $rss;
			$cgroups_vsize{$cgroup}                = $vsize;
			$cgroups_trs{$cgroup}                  = $trs;
			$cgroups_drs{$cgroup}                  = $drs;
			$cgroups_size{$cgroup}                 = $size;
			$cgroups_etimes{$cgroup}               = $etimes;
			$cgroups_invvol_ctxt_switches{$cgroup} = $invol_ctxt_switches;
			$cgroups_vol_ctxt_switches{$cgroup}    = $vol_ctxt_switches;
		} else {
			$cgroups_permem{$cgroup} = $cgroups_permem{$cgroup} + $permem;
			$cgroups_percpu{$cgroup} = $cgroups_percpu{$cgroup} + $percpu;
			$cgroups_procs{$cgroup}++;
			$cgroups_rss{$cgroup}                  = $cgroups_rss{$cgroup} + $rss;
			$cgroups_vsize{$cgroup}                = $cgroups_vsize{$cgroup} + $vsize;
			$cgroups_trs{$cgroup}                  = $cgroups_trs{$cgroup} + $trs;
			$cgroups_drs{$cgroup}                  = $cgroups_drs{$cgroup} + $drs;
			$cgroups_size{$cgroup}                 = $cgroups_size{$cgroup} + $size;
			$cgroups_etimes{$cgroup}               = $cgroups_etimes{$cgroup} + $etimes;
			$cgroups_invvol_ctxt_switches{$cgroup} = $cgroups_invvol_ctxt_switches{$cgroup} + $invol_ctxt_switches;
			$cgroups_vol_ctxt_switches{$cgroup}    = $cgroups_vol_ctxt_switches{$cgroup} + $vol_ctxt_switches;
		} ## end else [ if ( !defined( $cgroups_permem{$cgroup} ) )]
	} ## end foreach my $line (@ps_output_split)

	#
	# build a list of mappings
	#
	# more than one cgroup will commonly map to the same name, such as each
	# session scope for a user or a service with cgroups nested under it, so the
	# cgroups are grouped up by the name they map to... each also maps to the dir
	# under /sys/fs/cgroup to read the stats from, which for the likes of a user is
	# the slice for that user and not the individual session scopes, given that
	# with cgroup v2 the stats for a cgroup include those of all its descendants
	my %name_to_cgroups;
	my %name_to_stat_dirs;
	foreach my $cgroup ( keys(%found_cgroups) ) {
		#my $cgroupns = $found_cgroups{$cgroup};
		my ( $map_to, $stat_dir ) = $self->cgroup_mapping($cgroup);
		if ( defined($map_to) ) {
			$self->{mappings}{$cgroup} = $map_to;
			push( @{ $name_to_cgroups{$map_to} }, $cgroup );
			if ( defined($stat_dir) ) {
				# keyed on the dir so that one shared by several cgroups is only read
				# once, otherwise the same values would be counted repeatedly
				$name_to_stat_dirs{$map_to}{$stat_dir} = 1;
			}
		}
	} ## end foreach my $cgroup ( keys(%found_cgroups) )

	#
	# get the stats
	#
	foreach my $name ( keys(%name_to_cgroups) ) {

		# only process this cgroup if the include check returns true, otherwise ignore it
		if ( $self->{obj}->include($name) ) {

			$data->{oslvms}{$name} = clone($base_stats);

			# these all come from ps and are per proc, so they are just summed up
			# across every cgroup mapping to this name... the totals are summed here
			# as well so they only cover included names, same as the cgroup stats
			my %root_paths_found;
			foreach my $cgroup ( @{ $name_to_cgroups{$name} } ) {
				my %ps_stats = (
					'percent-cpu'                  => $cgroups_percpu{$cgroup},
					'percent-memory'               => $cgroups_permem{$cgroup},
					procs                          => $cgroups_procs{$cgroup},
					rss                            => $cgroups_rss{$cgroup},
					'size'                         => $cgroups_size{$cgroup},
					'virtual-size'                 => $cgroups_vsize{$cgroup},
					'text-size'                    => $cgroups_trs{$cgroup},
					'data-size'                    => $cgroups_drs{$cgroup},
					'elapsed-times'                => $cgroups_etimes{$cgroup},
					'voluntary-context-switches'   => $cgroups_vol_ctxt_switches{$cgroup},
					'involuntary-context-switches' => $cgroups_invvol_ctxt_switches{$cgroup},
				);
				foreach my $stat ( keys(%ps_stats) ) {
					$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $ps_stats{$stat};
					$data->{totals}{$stat}        = $data->{totals}{$stat} + $ps_stats{$stat};
				}

				if ( defined( $cgroups_root_paths{$cgroup} ) ) {
					foreach my $root_path ( keys( %{ $cgroups_root_paths{$cgroup} } ) ) {
						$root_paths_found{$root_path} = 1;
					}
				}
			} ## end foreach my $cgroup ( @{ $name_to_cgroups{$name}...})

			if ( $name =~ /^p\_/ || $name =~ /^d\_/ ) {
				my $container_name = $name;
				$container_name =~ s/^[pd]\_//;
				my $info_key = ( $name =~ /^p\_/ ) ? 'podman_info' : 'docker_info';
				# a container with no ps/inspect info, such as one whose ID could not be
				# mapped to a name, keeps the empty IP list from the base stats
				if ( defined( $self->{$info_key}{$container_name} ) ) {
					$data->{oslvms}{$name}{'ip'} = $self->{$info_key}{$container_name}{ip};
				}
			}

			# record the root fs path for this oslvm, akin to the path for a FreeBSD
			# jail... for containers prefer the rootfs reported by "inspect" as the
			# procs there are in their own mount namespace and will see it as just /,
			# otherwise use the roots the procs see, which handles chroots and the like
			my @root_paths;
			if ( $name =~ /^[pd]\_/ ) {
				my $container_name = $name;
				$container_name =~ s/^[pd]\_//;
				my $info_key = ( $name =~ /^p\_/ ) ? 'podman_info' : 'docker_info';
				if ( defined( $self->{$info_key}{$container_name} ) ) {
					push( @root_paths, @{ $self->{$info_key}{$container_name}{path} } );
				}
			}
			if ( !@root_paths ) {
				@root_paths = sort( keys(%root_paths_found) );
			}
			if ( !@root_paths ) {
				push( @root_paths, '/' );
			}
			push( @{ $data->{oslvms}{$name}{path} }, @root_paths );

			foreach my $stat_dir ( sort( keys( %{ $name_to_stat_dirs{$name} } ) ) ) {
				my $base_dir = '/sys/fs/cgroup' . $stat_dir;

				# cached per cgroup dir rather than per name so the deltas stay correct
				# as the cgroups making up a name come and go
				my $cache_name = 'cgroup-' . $stat_dir;

				my $cpu_stats_raw;
				if ( -f $base_dir . '/cpu.stat' && -r $base_dir . '/cpu.stat' ) {
					eval { $cpu_stats_raw = read_file( $base_dir . '/cpu.stat' ); };
					if ( defined($cpu_stats_raw) ) {
						my @cpu_stats_split = split( /\n/, $cpu_stats_raw );
						foreach my $line (@cpu_stats_split) {
							my ( $stat, $value ) = split( /\s+/, $line, 2 );
							if ( defined( $stat_mapping->{$stat} ) ) {
								$stat = $stat_mapping->{$stat};
							}
							if ( defined( $data->{oslvms}{$name}{$stat} ) && defined($value) && $value =~ /[0-9\.]+/ ) {
								$value                        = $self->cache_process( $cache_name, $stat, $value );
								$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $value;
								$data->{totals}{$stat}        = $data->{totals}{$stat} + $value;
								if ( $stat eq 'nr_bursts' ) {
									$data->{has}{burst_count} = 1;
								}
								if ( $stat eq 'burst-time' ) {
									$data->{has}{burst_time} = 1;
								}
								if ( $stat eq 'throttled-time' ) {
									$data->{has}{throttled_time} = 1;
								}
								if ( $stat eq 'nr_throttled' ) {
									$data->{has}{throttled_count} = 1;
								}
							} ## end if ( defined( $data->{oslvms}{$name}{$stat...}))
						} ## end foreach my $line (@cpu_stats_split)
					} ## end if ( defined($cpu_stats_raw) )
				} ## end if ( -f $base_dir . '/cpu.stat' && -r $base_dir...)

				my $memory_stats_raw;
				if ( -f $base_dir . '/memory.stat' && -r $base_dir . '/memory.stat' ) {
					eval { $memory_stats_raw = read_file( $base_dir . '/memory.stat' ); };
					if ( defined($memory_stats_raw) ) {
						my @memory_stats_split = split( /\n/, $memory_stats_raw );
						foreach my $line (@memory_stats_split) {
							my ( $stat, $value ) = split( /\s+/, $line, 2 );
							if ( defined( $stat_mapping->{$stat} ) ) {
								$stat = $stat_mapping->{$stat};
							}
							if ( defined( $data->{oslvms}{$name}{$stat} ) && defined($value) && $value =~ /[0-9\.]+/ ) {
								$value                        = $self->cache_process( $cache_name, $stat, $value );
								$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $value;
								$data->{totals}{$stat}        = $data->{totals}{$stat} + $value;
							}
						} ## end foreach my $line (@memory_stats_split)
					} ## end if ( defined($memory_stats_raw) )
				} ## end if ( -f $base_dir . '/memory.stat' && -r $base_dir...)

				my $io_stats_raw;
				if ( -f $base_dir . '/io.stat' && -r $base_dir . '/io.stat' ) {
					eval { $io_stats_raw = read_file( $base_dir . '/io.stat' ); };
					if ( defined($io_stats_raw) ) {
						$data->{has}{rwdops}   = 1;
						$data->{has}{rwdbytes} = 1;
						my @io_stats_split = split( /\n/, $io_stats_raw );
						foreach my $line (@io_stats_split) {
							my @line_split = split( /\s/, $line );
							shift(@line_split);
							foreach my $item (@line_split) {
								my ( $stat, $value ) = split( /\=/, $item, 2 );
								if ( defined( $stat_mapping->{$stat} ) ) {
									$stat = $stat_mapping->{$stat};
								}
								if (   defined( $data->{oslvms}{$name}{$stat} )
									&& defined($value)
									&& $value =~ /[0-9]+/ )
								{
									$value = $self->cache_process( $cache_name, $stat, $value );
									$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $value;
									$data->{totals}{$stat}        = $data->{totals}{$stat} + $value;
								}
							} ## end foreach my $item (@line_split)
						} ## end foreach my $line (@io_stats_split)
					} ## end if ( defined($io_stats_raw) )
				} ## end if ( -f $base_dir . '/io.stat' && -r $base_dir...)
			} ## end foreach my $stat_dir ( sort( keys( %{ $name_to_stat_dirs...})))
		} ## end if ( $self->{obj}->include($name) )
	} ## end foreach my $name ( keys(%name_to_cgroups) )

	$data->{uid_mapping} = $self->{uid_mapping};

	# save the proc cache for next run... written atomically so an interrupted
	# write cannot leave behind a truncated/empty cache file
	eval { write_file( $self->{cache_file}, { atomic => 1 }, encode_json( $self->{new_cache} ) ); };
	if ($@) {
		push( @{ $data->{errors} }, 'saving proc cache failed, "' . $self->{cache_file} . '"... ' . $@ );
		$data->{cache_failure} = 1;
	}

	if ($cache_is_new) {
		delete( $data->{oslvms} );
		$data->{oslvms} = {};
		my @total_keys = keys( %{ $data->{totals} } );
		foreach my $total_key (@total_keys) {
			if ( ref( $data->{totals}{$total_key} ) eq '' ) {
				$data->{totals}{$total_key} = 0;
			}
		}
	} ## end if ($cache_is_new)

	return $data;
} ## end sub run

=head2 usable

Dies if not usable, meaning not Linux or cgroup v2 is not mounted at
/sys/fs/cgroup.

    eval{ $backend->usable; };
    if ( $@ ){
        print 'Not usable because... '.$@."\n";
    }

=cut

sub usable {
	my $self = $_[0];

	# make sure it is linux
	if ( $^O !~ 'linux' ) {
		die '$^O is "' . $^O . '" and not "linux"';
	}

	# the stats are read from under /sys/fs/cgroup, which on a hybrid or v1 only
	# setup is not the unified hierarchy
	if ( !-f '/sys/fs/cgroup/cgroup.controllers' ) {
		die 'cgroup v2 is not mounted at /sys/fs/cgroup';
	}

	return 1;
} ## end sub usable

# Finds the cgroup v2 cgroup for a process.
#
# One arg is taken, the PID to check.
#
# Returns the unified hierarchy line from /proc/$pid/cgroup, as is, such as
# "0::/system.slice/ssh.service". undef is returned if the PID is undef or not
# a number, the process exited before it could be read, it is in the root
# cgroup, or it is not under the unified hierarchy.
#
#     my $cgroup = $backend->proc_cgroup(1234);
#     # "0::/user.slice/user-1000.slice/session-5.scope"
sub proc_cgroup {
	my $self = $_[0];
	my $pid  = $_[1];

	if ( !defined($pid) || !looks_like_number($pid) ) {
		return undef;
	}

	my $raw;
	# the proc may exit between being listed by ps and being read here, so a
	# failure to read it is entirely expected and not worth noting as a error
	eval { $raw = read_file( '/proc/' . $pid . '/cgroup' ); };
	if ( !defined($raw) ) {
		return undef;
	}

	# only the unified hierarchy, hierarchy ID 0 with a empty controller list,
	# is of interest here... on a hybrid setup the v1 lines are also present
	foreach my $line ( split( /\n/, $raw ) ) {
		if ( $line =~ /^0\:\:\// ) {
			# the root cgroup, where kernel threads and the like live, is not a
			# container of any sort and has no name to map to, so it is skipped,
			# matching what ps did previously by printing "-" for those
			if ( $line eq '0::/' ) {
				return undef;
			}
			return $line;
		}
	} ## end foreach my $line ( split( /\n/, $raw ) )

	return undef;
} ## end sub proc_cgroup

# Finds the host interface that traffic from a container IP leaves by, as seen
# by the routing table for a packet arriving from the container's network.
# Nothing is sent... "ip route get" only does a route lookup, using a public
# address, 8.8.8.8 or 2001:4860:4860::8888, as the destination.
#
# Takes the args below.
#
#     - ip :: The container IP, IPv4 or IPv6.
#
#     - if :: The host interface for the container's network, such as docker0
#             or podman0.
#
# Returns the interface name, or undef if either arg is undef or does not look
# like a IP or interface name, or if the lookup fails. The args are checked as
# they are passed to the shell.
#
#     my $gw_if = $backend->route_get_if( '172.17.0.2', 'docker0' );    # "eth0"
#     $gw_if = $backend->route_get_if( 'fd00::2', 'podman0' );           # "eth0"
sub route_get_if {
	my $self = $_[0];
	my $ip   = $_[1];
	my $if   = $_[2];

	if (   !defined($ip)
		|| !defined($if)
		|| $ip !~ /^[0-9a-fA-F\.\:]+$/
		|| $if !~ /^[A-Za-z0-9\.\_\-\@]+$/ )
	{
		return undef;
	}

	my ( $family, $destination ) = ( '-4', '8.8.8.8' );
	if ( $ip =~ /\:/ ) {
		( $family, $destination ) = ( '-6', '2001:4860:4860::8888' );
	}

	my $output = `ip -j $family route get $destination from $ip iif $if 2> /dev/null`;
	if ( $? != 0 ) {
		return undef;
	}

	my $parsed;
	eval { $parsed = decode_json($output); };
	if (   ref($parsed) eq 'ARRAY'
		&& ref( $parsed->[0] ) eq 'HASH'
		&& defined( $parsed->[0]{dev} )
		&& ref( $parsed->[0]{dev} ) eq '' )
	{
		return $parsed->[0]{dev};
	}

	return undef;
} ## end sub route_get_if

# Maps a cgroup to the name it is reported as and to the dir its stats are read
# from. See the POD SYNOPSIS for the naming. docker_mapping and podman_mapping
# need to be filled in first for containers to be named, else the ID is used.
#
# For a user slice, uid_mapping is also filled in with the passwd info for the
# UID if one exists.
#
# One arg is taken, the cgroup as returned by proc_cgroup.
#
# Returns a list of two items. The first is the name. The second is the dir to
# read stats from, relative to /sys/fs/cgroup. As cgroup v2 stats include
# descendants, this is the unit, slice, or container the name is for and not
# the cgroup itself. Both are undef if there is no name to map to, such as the
# root cgroup.
#
#     my ( $name, $stat_dir ) = $backend->cgroup_mapping('0::/system.slice/systemd-udevd.service/udev');
#     # ( 's_systemd-udevd', '/system.slice/systemd-udevd.service' )
#
#     ( $name, $stat_dir ) = $backend->cgroup_mapping('0::/user.slice/user-1000.slice/session-5.scope');
#     # ( 'u_1000', '/user.slice/user-1000.slice' )
sub cgroup_mapping {
	my $self        = $_[0];
	my $cgroup_name = $_[1];

	if ( !defined($cgroup_name) ) {
		return undef;
	}

	if ( $cgroup_name eq '0::/init.scope' ) {
		return ( 'init', '/init.scope' );
	}

	if ( $cgroup_name =~ /^0\:\:\/system\.slice\/docker\-[a-zA-Z0-9]+\.scope/ ) {
		my $id = $cgroup_name;
		$id =~ s/^0\:\:\/system\.slice\/docker\-//;
		$id =~ s/\.scope.*$//;
		# the scope for the container is what the stats are wanted for, not any of
		# the cgroups nested under it
		my $stat_dir = '/system.slice/docker-' . $id . '.scope';
		if ( defined( $self->{docker_mapping}{$id} ) ) {
			return ( 'd_' . $self->{docker_mapping}{$id}{name}, $stat_dir );
		}
		return ( 'd_' . $id, $stat_dir );
	} elsif ( $cgroup_name =~ /^0\:\:\/docker\// ) {
		my $id = $cgroup_name;
		$id =~ s/^0\:\:\/docker\///;
		$id =~ s/\/.*$//;
		if ( defined( $self->{docker_mapping}{$id} ) ) {
			return ( 'd_' . $self->{docker_mapping}{$id}{name}, '/docker/' . $id );
		}
		return ( 'd_' . $id, '/docker/' . $id );
	} elsif ( $cgroup_name =~ /^0\:\:\/machine\.slice\/libpod\-conmon-/ ) {
		# every container has its own conmon scope and all of them are lumped in
		# under the one name, so the stats are read from each of those scopes
		my $scope = $cgroup_name;
		$scope =~ s/^0\:\:\/machine\.slice\///;
		$scope =~ s/\/.*$//;
		return ( 'libpod-conmon', '/machine.slice/' . $scope );
	} elsif ( $cgroup_name =~ /^0\:\:\/machine\.slice\/libpod\-/ ) {
		my $id = $cgroup_name;
		$id =~ s/^0\:\:\/machine\.slice\/libpod\-//;
		$id =~ s/\.scope.*$//;
		my $stat_dir = '/machine.slice/libpod-' . $id . '.scope';
		if ( defined( $self->{podman_mapping}{$id} ) ) {
			return ( 'p_' . $self->{podman_mapping}{$id}{name}, $stat_dir );
		}
		return ( 'libpod', $stat_dir );
	} elsif ( $cgroup_name =~ /^0\:\:\/(system|machine)\.slice\// ) {
		# machine.slice is handled the same as system.slice once the libpod scopes
		# have been dealt with... reading stats from all of machine.slice would also
		# count every podman container under it a second time
		my $slice       = $1;
		my $prefix      = ( $slice eq 'system' ) ? 's_' : 'm_';
		my $under_slice = $cgroup_name;
		$under_slice =~ s/^0\:\:\/(system|machine)\.slice\///;
		# the first unit in the path is used so that a service with nested
		# cgroups, such as systemd-udevd.service/udev, is grouped under the
		# service and not under the name of the nested cgroup... nested slices,
		# such as system-getty.slice, are skipped over as the unit of interest
		# lives under them
		my @path_split = split( /\//, $under_slice );
		my @unit_path;
		my $unit;
		foreach my $part (@path_split) {
			if ( !defined($unit) ) {
				push( @unit_path, $part );
				if ( $part =~ /\.(service|scope)$/ ) {
					$unit = $part;
				}
			}
		}
		if ( !defined($unit) ) {
			$unit = $path_split[-1];
		}
		if ( !defined($unit) || $unit eq '' ) {
			return undef;
		}
		# stats are read from the unit and not from the cgroups nested under it as
		# the name is for the unit as a whole
		my $stat_dir = '/' . $slice . '.slice/' . join( '/', @unit_path );
		$unit =~ s/\.(service|scope)$//;
		if ( $slice eq 'machine' ) {
			$unit = $self->machine_name($unit);
		}
		return ( $prefix . $unit, $stat_dir );
	} elsif ( $cgroup_name =~ /^0\:\:\/user\.slice\// ) {
		my $user = $cgroup_name;
		$user =~ s/^0\:\:\/user\.slice\///;
		$user =~ s/\/.*$//;
		# the slice for the user is where the stats come from, meaning the session
		# scopes and the like nested under it are all accounted for
		my $stat_dir = '/user.slice/' . $user;
		$user =~ s/\.slice$//;
		$user =~ s/^user[\-\_]//;

		if ( $user =~ /^\d+$/ ) {
			my ( $name, $passwd, $uid, $gid, $quota, $comment, $gecos, $dir, $shell, $expire ) = getpwuid($user);
			if ( defined($name) ) {
				$self->{uid_mapping}{$user} = {
					name  => $name,
					gid   => $gid,
					home  => $dir,
					gecos => $gecos,
					shell => $shell,
				};
			}
		} ## end if ( $user =~ /^\d+$/ )

		return ( 'u_' . $user, $stat_dir );
	}

	$cgroup_name =~ s/^0\:\:\///;
	$cgroup_name =~ s/\/.*//;
	if ( $cgroup_name eq '' ) {
		return undef;
	}
	return ( $cgroup_name, '/' . $cgroup_name );
} ## end sub cgroup_mapping

# Normalizes the name of a unit under machine.slice to the name of the machine,
# so it is readable and stays the same across restarts.
#
# systemd escapes "-" in unit names as \x2d, machined names scopes
# machine-$name, and libvirt adds its type and domain ID, which changes each
# time the VM starts, as $type-$id-$name. nspawn started via machinectl is
# systemd-nspawn@$name instead.
#
# One arg is taken, the unit name with .service or .scope already removed.
#
# Returns the normalized name, prefixed with what it came from, qemu_, lxc_, or
# nspawn_, when that is known. A plain machine-$name scope could be from any
# machined user, such as nspawn run directly, so it gets no type. If normalizing
# leaves no name, the unit name is returned as is.
#
#     machine-qemu\x2d1\x2dvm  -> qemu_vm
#     machine-lxc\x2d12\x2dweb -> lxc_web
#     systemd-nspawn@foo       -> nspawn_foo
#     machine-foo              -> foo
#     foo\x2dbar               -> foo-bar
sub machine_name {
	my $self = $_[0];
	my $unit = $_[1];

	my $name = $unit;
	my $type;
	$name =~ s/\\x([0-9a-fA-F]{2})/chr(hex($1))/ge;
	if ( $name =~ s/^machine\-// ) {
		if ( $name =~ s/^(qemu|lxc)\-\d+\-// ) {
			$type = $1;
		}
	} elsif ( $name =~ s/^systemd\-nspawn\@// ) {
		$type = 'nspawn';
	}

	if ( $name eq '' ) {
		return $unit;
	}

	if ( defined($type) ) {
		return $type . '_' . $name;
	}

	return $name;
} ## end sub machine_name

# Turns a counter into a per second rate using the value cached by the previous
# run. Gauges, anything not in the counters list, are returned as is.
#
# For counters the raw value is saved to new_cache for the next run. The rate
# is the delta divided by the interval since the previous run. *_usec time
# counters are also divided by time_divider, making them seconds per second.
#
# Takes the args below.
#
#     - name :: The cache entry, such as "cgroup-/system.slice/ssh.service" or
#             "proc-$pid-$uid-$gid-$cgroup".
#
#     - var :: The stat name, such as "rbytes" or "cpu-time".
#
#     - new_value :: The current raw value.
#
#     - age :: Optional age in seconds of what the counter is for. Used when
#             nothing is cached, see below.
#
# Returns the rate, or the value for a gauge. 0 is returned if any of the first
# three args are undef, for a rate over 10000000000 as it is garbage, and for a
# counter with nothing cached unless age is set and within the interval, as
# then the total accrued is all from this interval. If the counter went
# backwards it was reset, so the raw value is used as the delta.
#
#     # rbytes cached as 100 and a interval of 300
#     my $rate = $backend->cache_process( 'cgroup-/foo', 'rbytes', 400 );    # 1
#
#     # a gauge
#     my $anon = $backend->cache_process( 'cgroup-/foo', 'anon', 12345 );    # 12345
sub cache_process {
	my $self      = $_[0];
	my $name      = $_[1];
	my $var       = $_[2];
	my $new_value = $_[3];
	my $age       = $_[4];

	if ( !defined($name) || !defined($var) || !defined($new_value) ) {
		warn('name, var, or new_value is undef');
		return 0;
	}

	# is a gauge and not a counter
	if ( !defined( $self->{counters}{$var} ) ) {
		return $new_value;
	}

	# not seen it yet
	if ( !defined( $self->{new_cache}{$name} ) ) {
		$self->{new_cache}{$name} = {};
	}
	$self->{new_cache}{$name}{$var} = $new_value;

	# first time seeing this counter, so there is no previous value to compute
	# a delta against... if what it is for is older than the polling interval,
	# or of unknown age, return 0 to avoid a spike from the accumulated total,
	# but for young ones the total accrued is from this interval, so usable...
	# either way the raw value saved to new_cache above provides the delta next run
	if ( !defined( $self->{cache}{$name}{$var} ) ) {
		if ( !defined($age) || !looks_like_number($age) || $age > $self->{interval} ) {
			return 0;
		}
	} elsif ( $new_value >= $self->{cache}{$name}{$var} ) {
		# if the counter instead went backwards it was reset, such as the cgroup
		# being recreated, in which case the raw value is what has accrued since then
		$new_value = $new_value - $self->{cache}{$name}{$var};
	}

	if ( $new_value != 0 ) {
		if (   $var eq 'cpu-time'
			|| $var eq 'system-time'
			|| $var eq 'user-time'
			|| $var eq 'throttled-time'
			|| $var eq 'burst-time'
			|| $var eq 'core_sched.force_idle-time' )
		{
			$new_value = $new_value / $self->{time_divider};
		}
		$new_value = $new_value / $self->{interval};
	} ## end if ( $new_value != 0 )

	# discard garbage values... new_cache keeps the raw value saved above so
	# the delta for the next run is still sane
	if ( $new_value > 10000000000 ) {
		return 0;
	}

	return $new_value;
} ## end sub cache_process

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-oslv-monitor at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=OSLV-Monitor>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OSLV::Monitor


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=OSLV-Monitor>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/OSLV-Monitor>

=item * Search CPAN

L<https://metacpan.org/release/OSLV-Monitor>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of OSLV::Monitor
