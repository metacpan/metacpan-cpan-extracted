package OSLV::Monitor::Backends::cgroups;

use 5.006;
use strict;
use warnings;
use JSON;
use Clone 'clone';
use File::Slurp;
use IO::Interface::Simple;
use Math::BigInt;
use Scalar::Util qw(looks_like_number);

=head1 NAME

OSLV::Monitor::Backends::cgroups - Backend for Linux cgroups.

=head1 VERSION

Version 1.0.2

=cut

our $VERSION = '1.0.2';

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

=head2 METHODS

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
			'system_usec'                  => 1,
			'usage_usec'                   => 1,
			'user_usec'                    => 1,
			'zswpin'                       => 1,
			'zswpout'                      => 1,
			'zswpwb'                       => 1,
		},
		cache     => {},
		new_cache => {},
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
		errors => [],
		oslvms => {},
		has    => {
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
		totals => {
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
			nr_periods                     => 0,
			nr_throttled                   => 0,
			throttled_usec                 => 0,
			nr_bursts                      => 0,
			burst_usec                     => 0,
			anon                           => 0,
			file                           => 0,
			kernel                         => 0,
			kernel_stack                   => 0,
			pagetables                     => 0,
			sec_pagetables                 => 0,
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
			thp_fault_alloc                => 0,
			thp_collapse_alloc             => 0,
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

	my $proc_cache;
	my $new_cache    = {};
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
			return $data;
		}
	} else {
		$cache_is_new = 1;
	}

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
		nr_periods                     => 0,
		nr_throttled                   => 0,
		throttled_usec                 => 0,
		nr_bursts                      => 0,
		burst_usec                     => 0,
		anon                           => 0,
		file                           => 0,
		kernel                         => 0,
		kernel_stack                   => 0,
		pagetables                     => 0,
		sec_pagetables                 => 0,
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
		thp_fault_alloc                => 0,
		thp_collapse_alloc             => 0,
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
		my $podman_output = `$cgroup_jank_type ps --format json 2> /dev/null`;
		if ( $? == 0 ) {
			my $podman_parsed;
			eval { $podman_parsed = decode_json($podman_output); };
			if ( defined($podman_parsed) && ref($podman_parsed) eq 'ARRAY' ) {
				foreach my $pod ( @{$podman_parsed} ) {
					if ( defined( $pod->{Id} ) && defined( $pod->{Names} ) && defined( $pod->{Names}[0] ) ) {
						$self->{ $cgroup_jank_type . '_mapping' }{ $pod->{Id} } = {
							podname  => $pod->{PodName},
							Networks => $pod->{Networks},
						};
						if ( $self->{ $cgroup_jank_type . '_mapping' }{ $pod->{Id} }{podname} ne '' ) {
							$self->{ $cgroup_jank_type . '_mapping' }{ $pod->{Id} }{name}
								= $self->{ $cgroup_jank_type . '_mapping' }{ $pod->{Id} }{podname} . '-'
								. $pod->{Names}[0];
						} else {
							$self->{ $cgroup_jank_type . '_mapping' }{ $pod->{Id} }{name} = $pod->{Names}[0];
						}
						my $container_id   = $pod->{Id};
						my $inspect_output = `$cgroup_jank_type inspect $container_id 2> /dev/null`;
						my $inspect_parsed;
						$self->{ $cgroup_jank_type . '_info' }{$container_id} = { ip => [] };
						eval { $inspect_parsed = decode_json($inspect_output) };
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
								if (   ref($current_network) eq 'HASH'
									&& ref( $current_network->{IPAddress} ) eq '' )
								{
									my $net_work_info = {
										ip    => $current_network->{IPAddress},
										gw    => undef,
										gw_if => undef,
										mac   => undef,
										if    => undef,
									};
									if ( defined( $current_network->{Gateway} )
										&& ref( $current_network->{Gateway} ) eq '' )
									{
										$net_work_info->{gw} = $current_network->{Gateway};
									}
									if ( defined( $current_network->{MacAddress} )
										&& ref( $current_network->{MacAddress} ) eq '' )
									{
										$net_work_info->{mac} = $current_network->{MacAddress};
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
											&& ref( $network_inspect_parsed->[0] ) eq 'HASH'
											&& defined( $network_inspect_parsed->[0]{network_interface} )
											&& ref( $network_inspect_parsed->[0]{network_interface} ) eq '' )
										{
											$net_work_info->{if} = $network_inspect_parsed->[0]{network_interface};
										}
									} ## end if ( defined( $current_network->{NetworkID...}))
									if (   defined( $net_work_info->{if} )
										&& defined( $net_work_info->{ip} ) )
									{
										my $ip_r_g_output
											= `ip r g from $net_work_info->{ip} iif $net_work_info->{if} 8.8.8.8`;
										if ( $? == 0 ) {
											my @ip_r_g_output_split = split( /\n/, $ip_r_g_output );
											if ( defined( $ip_r_g_output_split[0] ) ) {
												$ip_r_g_output_split[0] =~ s/^.*[\ \t]+dev[\ \t]+//;
												$ip_r_g_output_split[0] =~ s/[\ \t].*$//;
												$net_work_info->{gw_if} = $ip_r_g_output_split[0];
											}
										}
									} ## end if ( defined( $net_work_info->{if} ) && defined...)
									push(
										@{ $self->{ $cgroup_jank_type . '_info' }{ $pod->{Names}[0] }{ip} },
										$net_work_info
									);
								} ## end if ( ref($current_network) eq 'HASH' && ref...)
							} ## end foreach my $network_to_process (@podman_networks)
						} ## end if ( defined($inspect_parsed) && ref($inspect_parsed...))
					} ## end if ( defined( $pod->{Id} ) && defined( $pod...))
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
	my $ps_output = `ps -haxo pid,uid,gid,%cpu,%mem,rss,vsize,trs,drs,size,etimes,cgroup 2> /dev/null`;
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

	foreach my $line (@ps_output_split) {
		$line =~ s/^\s+//;
		my $vol_ctxt_switches   = 0;
		my $invol_ctxt_switches = 0;
		my ( $pid, $uid, $gid, $cgroupns, $percpu, $permem, $rss, $vsize, $trs, $drs, $size, $etimes, $cgroup );
		#		if ( $self->{cgroupns_usable} ) {
		#			( $pid, $uid, $gid, $cgroupns, $percpu, $permem, $rss, $vsize, $trs, $drs, $size, $etimes, $cgroup )#
		#				= split( /\s+/, $line );
		#		} else {
		( $pid, $uid, $gid, $percpu, $permem, $rss, $vsize, $trs, $drs, $size, $etimes, $cgroup )
			= split( /\s+/, $line );
		#		}
		if ( $cgroup =~ /^0\:\:\// ) {

			my $cache_name = 'proc-' . $pid . '-' . $uid . '-' . $gid . '-' . $cgroup;

			$found_cgroups{$cgroup}           = $cgroup;
			$data->{totals}{'percent-cpu'}    = $data->{totals}{'percent-cpu'} + $percpu;
			$data->{totals}{'percent-memory'} = $data->{totals}{'percent-memory'} + $permem;
			$data->{totals}{rss}              = $data->{totals}{rss} + $rss;
			$data->{totals}{'virtual-size'}   = $data->{totals}{'virtual-size'} + $vsize;
			$data->{totals}{'text-size'}      = $data->{totals}{'text-size'} + $trs;
			$data->{totals}{'data-size'}      = $data->{totals}{'data-size'} + $drs;
			$data->{totals}{'size'}           = $data->{totals}{'size'} + $size;
			$data->{totals}{'elapsed-times'}  = $data->{totals}{'elapsed-times'} + $etimes;

			eval {
				if ( -f '/proc/' . $pid . '/status' ) {
					my @switches_find
						= grep( /voluntary\_ctxt\_switches\:/, read_file( '/proc/' . $pid . '/status' ) );
					foreach my $found_switch (@switches_find) {
						chomp($found_switch);
						my @switch_split = split( /\:[\ \t]+/, $found_switch );
						if ( defined( $switch_split[0] ) && defined( $switch_split[1] ) ) {
							if ( $switch_split[0] eq 'voluntary_ctxt_switches' ) {
								$vol_ctxt_switches = $switch_split[1];
							} elsif ( $switch_split[0] eq 'involuntary_ctxt_switches' ) {
								$invol_ctxt_switches = $switch_split[1];
							}
						}
					} ## end foreach my $found_switch (@switches_find)
				} ## end if ( -f '/proc/' . $pid . '/status' )
			};
			$vol_ctxt_switches = $self->cache_process( $cache_name, 'voluntary-context-switches', $vol_ctxt_switches );
			$data->{totals}{'voluntary-context-switches'}
				= $data->{totals}{'voluntary-context-switches'} + $vol_ctxt_switches;
			$invol_ctxt_switches
				= $self->cache_process( $cache_name, 'involuntary-context-switches', $invol_ctxt_switches );
			$data->{totals}{'involuntary-context-switches'}
				= $data->{totals}{'involuntary-context-switches'} + $invol_ctxt_switches;

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
		} ## end if ( $cgroup =~ /^0\:\:\// )
	} ## end foreach my $line (@ps_output_split)

	#
	# build a list of mappings
	#
	foreach my $cgroup ( keys(%found_cgroups) ) {
		#my $cgroupns = $found_cgroups{$cgroup};
		my $map_to = $self->cgroup_mapping($cgroup);
		if ( defined($map_to) ) {
			$self->{mappings}{$cgroup} = $map_to;
		}
	}

	#
	# get the stats
	#
	foreach my $cgroup ( keys( %{ $self->{mappings} } ) ) {
		my $name = $self->{mappings}{$cgroup};

		# only process this cgroup if the include check returns true, otherwise ignore it
		if ( $self->{obj}->include($name) ) {

			my $cache_name = 'cgroup-' . $name;

			$data->{oslvms}{$name} = clone($base_stats);

			$data->{oslvms}{$name}{'percent-cpu'}    = $cgroups_percpu{$cgroup};
			$data->{oslvms}{$name}{'percent-memory'} = $cgroups_permem{$cgroup};
			$data->{oslvms}{$name}{procs}            = $cgroups_procs{$cgroup};
			$data->{totals}{procs}                   = $data->{totals}{procs} + $cgroups_procs{$cgroup};
			$data->{oslvms}{$name}{rss}              = $cgroups_rss{$cgroup};
			$data->{oslvms}{$name}{'virtual-size'}   = $cgroups_vsize{$cgroup};
			$data->{oslvms}{$name}{'text-size'}      = $cgroups_trs{$cgroup};
			$data->{oslvms}{$name}{'data-size'}      = $cgroups_drs{$cgroup};
			$data->{oslvms}{$name}{'size'}           = $cgroups_size{$cgroup};
			$data->{oslvms}{$name}{'elapsed-times'}  = $cgroups_etimes{$cgroup};

			if ( $name =~ /^p\_/ || $name =~ /^d\_/ ) {
				my $container_name = $name;
				$container_name =~ s/^[pd]\_//;
				if ( $name =~ /^p\_/ ) {
					$data->{oslvms}{$name}{'ip'} = $self->{podman_info}{$container_name}{ip};
				} elsif ( $name =~ /^d\_/ ) {
					$data->{oslvms}{$name}{'ip'} = $self->{docker_info}{$container_name}{ip};
				}
			}

			my $base_dir = $cgroup;
			$base_dir =~ s/^0\:\://;
			$base_dir = '/sys/fs/cgroup' . $base_dir;

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
							my ( $stat, $value ) = split( /\=/, $line, 2 );
							if ( defined( $stat_mapping->{$stat} ) ) {
								$stat = $stat_mapping->{$stat};
							}
							if ( defined( $data->{oslvms}{$name}{$stat} ) && defined($value) && $value =~ /[0-9]+/ ) {
								$value                        = $self->cache_process( $cache_name, $stat, $value );
								$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $value;
								$data->{totals}{$stat}        = $data->{totals}{$stat} + $value;
							}
						} ## end foreach my $item (@line_split)
					} ## end foreach my $line (@io_stats_split)
				} ## end if ( defined($io_stats_raw) )
			} ## end if ( -f $base_dir . '/io.stat' && -r $base_dir...)
		} ## end if ( $self->{obj}->include($name) )
	} ## end foreach my $cgroup ( keys( %{ $self->{mappings}...}))

	$data->{uid_mapping} = $self->{uid_mapping};

	# save the proc cache for next run
	eval { write_file( $self->{cache_file}, encode_json( $self->{new_cache} ) ); };
	if ($@) {
		push( @{ $data->{errors} }, 'saving proc cache failed, "' . $self->{proc_cache} . '"... ' . $@ );
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

Dies if not usable.

    eval{ $backend->usable; };
    if ( $@ ){
        print 'Not usable because... '.$@."\n";
    }

=cut

sub usable {
	my $self = $_[0];

	# make sure it is freebsd

	if ( $^O !~ 'linux' ) {
		die '$^O is "' . $^O . '" and not "linux"';
	}

	return 1;
} ## end sub usable

sub cgroup_mapping {
	my $self        = $_[0];
	my $cgroup_name = $_[1];
	#my $cgroupns    = $_[2];

	if ( !defined($cgroup_name) ) {
		return undef;
	}

	if ( $cgroup_name eq '0::/init.scope' ) {
		return 'init';
	}

	if ( $cgroup_name =~ /^0\:\:\/system\.slice\/docker\-[a-zA-Z0-9]+\.scope/ ) {
		$cgroup_name =~ s/^0\:\:\/system\.slice\/docker\-//;
		$cgroup_name =~ s/\.scope.*$//;
		return 'd_' . $cgroup_name;
	} elsif ( $cgroup_name =~ /^0\:\:\/docker\// ) {
		$cgroup_name =~ s/^0\:\:\/docker\///;
		$cgroup_name =~ s/\/.*$//;
		return 'd_' . $cgroup_name;
	} elsif ( $cgroup_name =~ /^0\:\:\/system\.slice\// ) {
		$cgroup_name =~ s/^.*\///;
		$cgroup_name =~ s/\.service$//;
		return 's_' . $cgroup_name;
	} elsif ( $cgroup_name =~ /^0\:\:\/user\.slice\// ) {
		$cgroup_name =~ s/^0\:\:\/user\.slice\///;
		$cgroup_name =~ s/\.slice.*$//;
		$cgroup_name =~ s/^user[\-\_]//;

		if ( $cgroup_name =~ /^\d+$/ ) {
			my ( $name, $passwd, $uid, $gid, $quota, $comment, $gecos, $dir, $shell, $expire ) = getpwuid($cgroup_name);
			if ( defined($name) ) {
				$self->{uid_mapping}{$cgroup_name} = {
					name  => $name,
					gid   => $gid,
					home  => $dir,
					gecos => $gecos,
					shell => $shell,
				};
			}
		} ## end if ( $cgroup_name =~ /^\d+$/ )

		return 'u_' . $cgroup_name;
	} elsif ( $cgroup_name =~ /^0\:\:\/machine\.slice\/libpod\-conmon-/ ) {
		return 'libpod-conmon';
	} elsif ( $cgroup_name =~ /^0\:\:\/machine\.slice\/libpod\-/ ) {
		$cgroup_name =~ s/^^0\:\:\/machine\.slice\/libpod\-//;
		$cgroup_name =~ s/\.scope.*$//;
		if ( defined( $self->{podman_mapping}{$cgroup_name} ) ) {
			return 'p_' . $self->{podman_mapping}{$cgroup_name}{name};
		}
		return 'libpod';
	}

	$cgroup_name =~ s/^0\:\:\///;
	$cgroup_name =~ s/\/.*//;
	return $cgroup_name;
} ## end sub cgroup_mapping

sub ip_to_if {
	my $self = $_[0];
	my $ip   = $_[1];

	if ( !defined($ip) || ref($ip) ne '' ) {
		return undef;
	}

	my $if = IO::Interface::Simple->new_from_address($ip);

	if ( !defined($if) ) {
		return undef;
	}

	return $if->name;
} ## end sub ip_to_if

sub cache_process {
	my $self      = $_[0];
	my $name      = $_[1];
	my $var       = $_[2];
	my $new_value = $_[3];

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

	# not seen it yet
	if ( !defined( $self->{cache}{$name}{$var} ) ) {
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
			$new_value = $new_value / 300;
		} ## end if ( $new_value != 0 )
		return $new_value;
	} ## end if ( !defined( $self->{cache}{$name}{$var}...))

	if ( $new_value >= $self->{cache}{$name}{$var} ) {
		$new_value = $new_value - $self->{cache}{$name}{$var};
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
			$new_value = $new_value / 300;
		} ## end if ( $new_value != 0 )
		if ( $new_value > 10000000000 ) {
			$self->{new_cache}{$name}{$var} = 0;
			return 0;
		}
		return $new_value;
	} ## end if ( $new_value >= $self->{cache}{$name}{$var...})

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
		$new_value = $new_value / 300;
	} ## end if ( $new_value != 0 )

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
