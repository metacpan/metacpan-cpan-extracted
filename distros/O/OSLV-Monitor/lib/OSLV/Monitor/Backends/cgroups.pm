package OSLV::Monitor::Backends::cgroups;

use 5.006;
use strict;
use warnings;
use JSON;
use Clone 'clone';
use File::Slurp;
use IO::Interface::Simple;

=head1 NAME

OSLV::Monitor::Backends::cgroups - Backend for Linux cgroups.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

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

    %cpu -> cpu_usage_per
    %mem -> mem_usage_per
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

=head2 METHODS

=head2 new

Initiates the backend object.

    my $backend=OSLV::MOnitor::Backend::cgroups->new(obj=>$obj)

    - obj :: The OSLVM::Monitor object.

=cut

sub new {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{obj} ) ) {
		die('$opts{obj} is undef');
	} elsif ( ref( $opts{obj} ) ne 'OSLV::Monitor' ) {
		die('ref $opts{obj} is not OSLV::Monitor');
	}

	my $self = {
		version         => 1,
		cgroupns_usable => 1,
		mappings        => {},
		podman_mapping  => {},
		podman_info     => {},
		docker_mapping  => {},
		docker_info     => {},
		uid_mapping     => {},
		obj             => $opts{obj},
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
		totals => {
			procs                        => 0,
			cpu_usage_per                => 0,
			mem_usage_per                => 0,
			rbytes                       => 0,
			wbytes                       => 0,
			rios                         => 0,
			wios                         => 0,
			dbytes                       => 0,
			dios                         => 0,
			usage_usec                   => 0,
			user_usec                    => 0,
			system_usec                  => 0,
			'core_sched.force_idle_usec' => 0,
			nr_periods                   => 0,
			nr_throttled                 => 0,
			throttled_usec               => 0,
			nr_bursts                    => 0,
			burst_usec                   => 0,
			anon                         => 0,
			file                         => 0,
			kernel                       => 0,
			kernel_stack                 => 0,
			pagetables                   => 0,
			sec_pagetables               => 0,
			percpu                       => 0,
			sock                         => 0,
			vmalloc                      => 0,
			shmem                        => 0,
			zswap                        => 0,
			zswapped                     => 0,
			file_mapped                  => 0,
			file_dirty                   => 0,
			file_writeback               => 0,
			swapcached                   => 0,
			anon_thp                     => 0,
			file_thp                     => 0,
			shmem_thp                    => 0,
			inactive_anon                => 0,
			active_anon                  => 0,
			inactive_file                => 0,
			active_file                  => 0,
			unevictable                  => 0,
			slab_reclaimable             => 0,
			slab_unreclaimable           => 0,
			slab                         => 0,
			workingset_refault_anon      => 0,
			workingset_refault_file      => 0,
			workingset_activate_anon     => 0,
			workingset_activate_file     => 0,
			workingset_restore_anon      => 0,
			workingset_restore_file      => 0,
			workingset_nodereclaim       => 0,
			pgscan                       => 0,
			pgsteal                      => 0,
			pgscan_kswapd                => 0,
			pgscan_direct                => 0,
			pgscan_khugepaged            => 0,
			pgsteal_kswapd               => 0,
			pgsteal_direct               => 0,
			pgsteal_khugepaged           => 0,
			pgfault                      => 0,
			pgmajfault                   => 0,
			pgrefill                     => 0,
			pgactivate                   => 0,
			pgdeactivate                 => 0,
			pglazyfree                   => 0,
			pglazyfreed                  => 0,
			zswpin                       => 0,
			zswpout                      => 0,
			thp_fault_alloc              => 0,
			thp_collapse_alloc           => 0,
			rss                          => 0,
			'data-size'                  => 0,
			'text-size'                  => 0,
			'size'                       => 0,
			'virtual-size'               => 0,
		},
	};

	my $base_stats = {
		procs                        => 0,
		cpu_usage_per                => 0,
		mem_usage_per                => 0,
		rbytes                       => 0,
		wbytes                       => 0,
		rios                         => 0,
		wios                         => 0,
		dbytes                       => 0,
		dios                         => 0,
		usage_usec                   => 0,
		user_usec                    => 0,
		system_usec                  => 0,
		'core_sched.force_idle_usec' => 0,
		nr_periods                   => 0,
		nr_throttled                 => 0,
		throttled_usec               => 0,
		nr_bursts                    => 0,
		burst_usec                   => 0,
		anon                         => 0,
		file                         => 0,
		kernel                       => 0,
		kernel_stack                 => 0,
		pagetables                   => 0,
		sec_pagetables               => 0,
		percpu                       => 0,
		sock                         => 0,
		vmalloc                      => 0,
		shmem                        => 0,
		zswap                        => 0,
		zswapped                     => 0,
		file_mapped                  => 0,
		file_dirty                   => 0,
		file_writeback               => 0,
		swapcached                   => 0,
		anon_thp                     => 0,
		file_thp                     => 0,
		shmem_thp                    => 0,
		inactive_anon                => 0,
		active_anon                  => 0,
		inactive_file                => 0,
		active_file                  => 0,
		unevictable                  => 0,
		slab_reclaimable             => 0,
		slab_unreclaimable           => 0,
		slab                         => 0,
		workingset_refault_anon      => 0,
		workingset_refault_file      => 0,
		workingset_activate_anon     => 0,
		workingset_activate_file     => 0,
		workingset_restore_anon      => 0,
		workingset_restore_file      => 0,
		workingset_nodereclaim       => 0,
		pgscan                       => 0,
		pgsteal                      => 0,
		pgscan_kswapd                => 0,
		pgscan_direct                => 0,
		pgscan_khugepaged            => 0,
		pgsteal_kswapd               => 0,
		pgsteal_direct               => 0,
		pgsteal_khugepaged           => 0,
		pgfault                      => 0,
		pgmajfault                   => 0,
		pgrefill                     => 0,
		pgactivate                   => 0,
		pgdeactivate                 => 0,
		pglazyfree                   => 0,
		pglazyfreed                  => 0,
		zswpin                       => 0,
		zswpout                      => 0,
		thp_fault_alloc              => 0,
		thp_collapse_alloc           => 0,
		rss                          => 0,
		'data-size'                  => 0,
		'text-size'                  => 0,
		'size'                       => 0,
		'virtual-size'               => 0,
		'ip'                         => [],
		'path'                       => [],
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
	my $ps_output = `ps -haxo pid,cgroupns,%cpu,%mem,rss,vsize,trs,drs,size,cgroup 2> /dev/null`;
	if ( $? != 0 ) {
		$self->{cgroupns_usable} = 0;
		$ps_output = `ps -haxo pid,%cpu,%mem,rss,vsize,trs,drs,size,cgroup 2> /dev/null`;
	}
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

	foreach my $line (@ps_output_split) {
		$line =~ s/^\s+//;
		my ( $pid, $cgroupns, $percpu, $permem, $rss, $vsize, $trs, $drs, $size, $cgroup );
		if ( $self->{cgroupns_usable} ) {
			( $pid, $cgroupns, $percpu, $permem, $rss, $vsize, $trs, $drs, $size, $cgroup ) = split( /\s+/, $line );
		} else {
			( $pid, $percpu, $permem, $rss, $vsize, $trs, $drs, $size, $cgroup ) = split( /\s+/, $line );
		}
		if ( $cgroup =~ /^0\:\:\// ) {
			$found_cgroups{$cgroup}         = $cgroupns;
			$data->{totals}{cpu_usage_per}  = $data->{totals}{cpu_usage_per} + $percpu;
			$data->{totals}{mem_usage_per}  = $data->{totals}{mem_usage_per} + $permem;
			$data->{totals}{rss}            = $data->{totals}{rss} + $rss;
			$data->{totals}{'virtual-size'} = $data->{totals}{'virtual-size'} + $vsize;
			$data->{totals}{'text-size'}    = $data->{totals}{'text-size'} + $trs;
			$data->{totals}{'data-size'}    = $data->{totals}{'data-size'} + $drs;
			$data->{totals}{'size'}         = $data->{totals}{'size'} + $size;

			if ( !defined( $cgroups_permem{$cgroup} ) ) {
				$cgroups_permem{$cgroup} = $permem;
				$cgroups_percpu{$cgroup} = $percpu;
				$cgroups_procs{$cgroup}  = 1;
				$cgroups_rss{$cgroup}    = $rss;
				$cgroups_vsize{$cgroup}  = $vsize;
				$cgroups_trs{$cgroup}    = $trs;
				$cgroups_drs{$cgroup}    = $drs;
				$cgroups_size{$cgroup}   = $size;
			} else {
				$cgroups_permem{$cgroup} = $cgroups_permem{$cgroup} + $permem;
				$cgroups_percpu{$cgroup} = $cgroups_percpu{$cgroup} + $percpu;
				$cgroups_procs{$cgroup}++;
				$cgroups_rss{$cgroup}   = $cgroups_rss{$cgroup} + $rss;
				$cgroups_vsize{$cgroup} = $cgroups_vsize{$cgroup} + $vsize;
				$cgroups_trs{$cgroup}   = $cgroups_trs{$cgroup} + $trs;
				$cgroups_drs{$cgroup}   = $cgroups_drs{$cgroup} + $drs;
				$cgroups_size{$cgroup}  = $cgroups_size{$cgroup} + $size;
			} ## end else [ if ( !defined( $cgroups_permem{$cgroup} ) )]
		} ## end if ( $cgroup =~ /^0\:\:\// )
	} ## end foreach my $line (@ps_output_split)

	#
	# build a list of mappings
	#
	foreach my $cgroup ( keys(%found_cgroups) ) {
		my $cgroupns = $found_cgroups{$cgroup};
		my $map_to   = $self->cgroup_mapping( $cgroup, $cgroupns );
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

			$data->{oslvms}{$name} = clone($base_stats);

			$data->{oslvms}{$name}{cpu_usage_per}  = $cgroups_percpu{$cgroup};
			$data->{oslvms}{$name}{mem_usage_per}  = $cgroups_permem{$cgroup};
			$data->{oslvms}{$name}{procs}          = $cgroups_procs{$cgroup};
			$data->{totals}{procs}                 = $data->{totals}{procs} + $cgroups_procs{$cgroup};
			$data->{oslvms}{$name}{rss}            = $cgroups_rss{$cgroup};
			$data->{oslvms}{$name}{'virtual-size'} = $cgroups_vsize{$cgroup};
			$data->{oslvms}{$name}{'text-size'}    = $cgroups_trs{$cgroup};
			$data->{oslvms}{$name}{'data-size'}    = $cgroups_drs{$cgroup};
			$data->{oslvms}{$name}{'size'}         = $cgroups_size{$cgroup};

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
						if ( defined( $data->{oslvms}{$name}{$stat} ) && defined($value) && $value =~ /[0-9\.]+/ ) {
							$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $value;
							$data->{totals}{$stat} = $data->{totals}{$stat} + $value;
						}
					}
				} ## end if ( defined($cpu_stats_raw) )
			} ## end if ( -f $base_dir . '/cpu.stat' && -r $base_dir...)

			my $memory_stats_raw;
			if ( -f $base_dir . '/memory.stat' && -r $base_dir . '/memory.stat' ) {
				eval { $memory_stats_raw = read_file( $base_dir . '/memory.stat' ); };
				if ( defined($memory_stats_raw) ) {
					my @memory_stats_split = split( /\n/, $memory_stats_raw );
					foreach my $line (@memory_stats_split) {
						my ( $stat, $value ) = split( /\s+/, $line, 2 );
						if ( defined( $data->{oslvms}{$name}{$stat} ) && defined($value) && $value =~ /[0-9\.]+/ ) {
							$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $value;
							$data->{totals}{$stat} = $data->{totals}{$stat} + $value;
						}
					}
				} ## end if ( defined($memory_stats_raw) )
			} ## end if ( -f $base_dir . '/memory.stat' && -r $base_dir...)

			my $io_stats_raw;
			if ( -f $base_dir . '/io.stat' && -r $base_dir . '/io.stat' ) {
				eval { $io_stats_raw = read_file( $base_dir . '/io.stat' ); };
				if ( defined($io_stats_raw) ) {
					my @io_stats_split = split( /\n/, $io_stats_raw );
					foreach my $line (@io_stats_split) {
						my @line_split = split( /\s/, $line );
						shift(@line_split);
						foreach my $item (@line_split) {
							my ( $stat, $value ) = split( /\=/, $line, 2 );
							if ( defined( $data->{oslvms}{$name}{$stat} ) && defined($value) && $value =~ /[0-9]+/ ) {
								$data->{oslvms}{$name}{$stat} = $data->{oslvms}{$name}{$stat} + $value;
								$data->{totals}{$stat} = $data->{totals}{$stat} + $value;
							}
						}
					} ## end foreach my $line (@io_stats_split)
				} ## end if ( defined($io_stats_raw) )
			} ## end if ( -f $base_dir . '/io.stat' && -r $base_dir...)
		} ## end if ( $self->{obj}->include($name) )
	} ## end foreach my $cgroup ( keys( %{ $self->{mappings}...}))

	$data->{uid_mapping} = $self->{uid_mapping};

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
	my $cgroupns    = $_[2];

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
