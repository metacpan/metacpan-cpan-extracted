package OSLV::Monitor::Backends::FreeBSD;

use 5.006;
use strict;
use warnings;
use JSON;
use Clone 'clone';
use File::Slurp;
use List::Util qw( uniq );
use IO::Interface::Simple;

=head1 NAME

OSLV::Monitor::Backends::FreeBSD - backend for FreeBSD jails

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use OSLV::Monitor::Backends::FreeBSD;

    my $backend = OSLV::Monitor::Backends::FreeBSD->new;

    my $usable=$backend->usable;
    if ( $usable ){
        $return_hash_ref=$backend->run;
    }

The stats names match those produced by "ps --libxo json".

=head2 METHODS

=head2 new

Initiates the backend object.

    my $backend=OSLV::MOnitor::Backend::FreeBSD->new(
        base_dir => $base_dir,
    );

The following arguments are usable.

    - base_dir :: Path to use for the base dir, where the proc
            cache, freebsd_proc_cache.json, is is created.
        Default :: /var/cache/oslv_monitor

    - obj :: The OSLVM::Monitor object.

=cut

sub new {
	my ( $blank, %opts ) = @_;

	if ( !defined( $opts{base_dir} ) ) {
		$opts{base_dir} = '/var/cache/oslv_monitor';
	}

	if ( !defined( $opts{obj} ) ) {
		die('$opts{obj} is undef');
	} elsif ( ref( $opts{obj} ) ne 'OSLV::Monitor' ) {
		die('ref $opts{obj} is not OSLV::Monitor');
	}

	my $self = { version => 1, proc_cache => $opts{base_dir} . '/freebsd_proc_cache.json', obj => $opts{obj} };
	bless $self;

	return $self;
} ## end sub new

=head2 run

    $return_hash_ref=$backend->run;

=cut

sub run {
	my $self = $_[0];

	my $data = {
		errors        => [],
		cache_failure => 0,
		oslvms        => {},
		totals        => {
			'copy-on-write-faults'         => 0,
			'cpu-time'                     => 0,
			'data-size'                    => 0,
			'elapsed-times'                => 0,
			'involuntary-context-switches' => 0,
			'major-faults'                 => 0,
			'minor-faults'                 => 0,
			'percent-cpu'                  => 0,
			'percent-memory'               => 0,
			'read-blocks'                  => 0,
			'received-messages'            => 0,
			'rss'                          => 0,
			'sent-messages'                => 0,
			'stack-size'                   => 0,
			'swaps'                        => 0,
			'system-time'                  => 0,
			'text-size'                    => 0,
			'user-time'                    => 0,
			'virtual-size'                 => 0,
			'voluntary-context-switches'   => 0,
			'written-blocks'               => 0,
			'procs'                        => 0,
			'signals-taken'                => 0,
		},
	};

	my $proc_cache;
	my $new_proc_cache = {};
	if ( -f $self->{proc_cache} ) {
		eval {
			my $raw_cache = read_file( $self->{proc_cache} );
			$proc_cache = decode_json($raw_cache);
		};
		if ($@) {
			push(
				@{ $data->{errors} },
				'reading proc cache "' . $self->{proc_cache} . '" failed... using a empty one...' . $@
			);
			$data->{cache_failure} = 1;
			$proc_cache = {};
		}
	} ## end if ( -f $self->{proc_cache} )

	my $base_stats = {
		'copy-on-write-faults'         => 0,
		'cpu-time'                     => 0,
		'data-size'                    => 0,
		'elapsed-times'                => 0,
		'involuntary-context-switches' => 0,
		'major-faults'                 => 0,
		'minor-faults'                 => 0,
		'percent-cpu'                  => 0,
		'percent-memory'               => 0,
		'read-blocks'                  => 0,
		'received-messages'            => 0,
		'rss'                          => 0,
		'sent-messages'                => 0,
		'stack-size'                   => 0,
		'swaps'                        => 0,
		'system-time'                  => 0,
		'text-size'                    => 0,
		'user-time'                    => 0,
		'virtual-size'                 => 0,
		'voluntary-context-switches'   => 0,
		'written-blocks'               => 0,
		'procs'                        => 0,
		'signals-taken'                => 0,
		'ip'                           => [],
		'path'                         => [],
	};

	# get a list of jails
	my $output = `/usr/sbin/jls --libxo json 2> /dev/null`;
	my $jls;
	eval { $jls = decode_json($output) };
	if ($@) {
		push( @{ $data->{errors} }, 'decoding output from "jls --libxo json 2> /dev/null" failed... ' . $@ );
		return $data;
	}
	if (   defined($jls)
		&& ref($jls) eq 'HASH'
		&& defined( $jls->{'jail-information'} )
		&& ref( $jls->{'jail-information'} ) eq 'HASH'
		&& defined( $jls->{'jail-information'}{jail} )
		&& ref( $jls->{'jail-information'}{jail} ) eq 'ARRAY' )
	{
		my @IP_keys = ( 'ipv4', 'ipv6' );
		foreach my $jls_jail ( @{ $jls->{'jail-information'}{jail} } ) {
			# only process this jail if the include check returns true, otherwise ignore it
			if ( $self->{obj}->include( $jls_jail->{'hostname'} ) ) {
				if ( !defined( $data->{oslvms}{ $jls_jail->{'hostname'} } ) ) {
					$data->{oslvms}{ $jls_jail->{'hostname'} } = clone($base_stats);
				}
				push( @{ $data->{oslvms}{ $jls_jail->{'hostname'} }{path} }, $jls_jail->{path} );

				my $jname = $jls_jail->{'hostname'};

				my $ipv4_gw    = undef;
				my $ipv4_gw_if = undef;
				my $ipv6_gw    = undef;
				my $ipv6_gw_if = undef;
				eval {
					my $netstat_raw = `/usr/bin/netstat -j $jname -rn --libxo json 2> /dev/null`;
					if ( $? == 0 ) {
						my $netstat_raw_parsed = decode_json($netstat_raw);
						if (   defined($netstat_raw_parsed)
							&& ref($netstat_raw_parsed) eq 'HASH'
							&& defined( $netstat_raw_parsed->{statistics} )
							&& ref( $netstat_raw_parsed->{statistics} ) eq 'HASH'
							&& defined( $netstat_raw_parsed->{statistics}{'route-table'} )
							&& ref( $netstat_raw_parsed->{statistics}{'route-table'} ) eq 'HASH'
							&& defined( $netstat_raw_parsed->{statistics}{'route-table'}{'rt-family'} )
							&& ref( $netstat_raw_parsed->{statistics}{'route-table'}{'rt-family'} ) eq 'ARRAY'
							&& defined( $netstat_raw_parsed->{statistics}{'route-table'}{'rt-family'}[0] ) )
						{
							foreach
								my $family ( @{ $netstat_raw_parsed->{statistics}{'route-table'}{'rt-family'} } )
							{
								if (   ref( $family->{'address-family'} ) eq ''
									&& ref( $family->{'rt-entry'} ) eq 'ARRAY'
									&& defined( $family->{'rt-entry'}[0] ) )
								{
									foreach my $rt_entry ( @{ $family->{'rt-entry'} } ) {
										if (   ref($rt_entry) eq 'HASH'
											&& defined( $rt_entry->{destination} )
											&& ref( $rt_entry->{destination} ) eq ''
											&& defined( $rt_entry->{gateway} )
											&& ref( $rt_entry->{gateway} ) eq ''
											&& defined( $rt_entry->{'interface-name'} )
											&& ref( $rt_entry->{'interface-name'} ) eq '' )
										{
											if ( $family->{'address-family'} eq 'Internet' ) {
												$ipv4_gw    = $rt_entry->{gateway};
												$ipv4_gw_if = $rt_entry->{'interface-name'};
											} elsif ( $family->{'address-family'} eq 'Internet6' ) {
												$ipv6_gw    = $rt_entry->{gateway};
												$ipv6_gw_if = $rt_entry->{'interface-name'};
											}
										} ## end if ( ref($rt_entry) eq 'HASH' && defined( ...))
									} ## end foreach my $rt_entry ( @{ $family->{'rt-entry'}...})
								} ## end if ( ref( $family->{'address-family'} ) eq...)
							} ## end foreach my $family ( @{ $netstat_raw_parsed->{statistics...}})
						} ## end if ( defined($netstat_raw_parsed) && ref($netstat_raw_parsed...))
					} ## end if ( $? == 0 )
				};

				foreach my $ip_key (@IP_keys) {
					my $ip_gw;
					my $ip_if;
					my $ip_gw_if;
					if ( $ip_key eq 'ipv4' ) {
						$ip_gw    = $ipv4_gw;
						$ip_gw_if = $ipv4_gw_if;
					} elsif ( $ip_key eq 'ipv6' ) {
						$ip_gw    = $ipv6_gw;
						$ip_gw_if = $ipv6_gw_if;
					}
					if (
						defined( $jls_jail->{$ip_key} )
						&& (
							( ref( $jls_jail->{$ip_key} ) eq '' && $jls_jail->{$ip_key} ne '' )
							|| (   ref( $jls_jail->{$ip_key} ) eq 'ARRAY'
								&& defined( $jls_jail->{$ip_key}[0] )
								&& $jls_jail->{$ip_key}[0] ne '' )
						)
						)
					{
						if ( ref( $jls_jail->{$ip_key} ) eq '' ) {
							# handle it if it is a string
							$jls_jail->{$ip_key} =~ s/^[\t\ ]*//;
							$jls_jail->{$ip_key} =~ s/[\t\ ]*$//;
							if ( $jls_jail->{$ip_key} !~ /[\t\ \,]/ ) {
								eval { $ip_if = $self->ip_to_if( $jls_jail->{$ip_key} ); };
								# if just a single IP, add it
								push(
									@{ $data->{oslvms}{$jname}{ip} },
									{
										ip    => $jls_jail->{$ip_key},
										if    => $ip_if,
										gw    => $ip_gw,
										gw_if => $ip_gw_if,
									}
								);
							} else {
								# if multiple IPs, split it apart and add it
								my @ip_split = split( /[\t \ \,]+/, $jls_jail->{$ip_key} );
								foreach my $ip_split_item (@ip_split) {
									if ( $ip_split_item ne '' && $ip_split_item =~ /^[A-Fa-f\:\.0-9]+$/ ) {
										eval { $ip_if = $self->ip_to_if( $jls_jail->{$ip_key} ); };
										push(
											@{ $data->{oslvms}{$jname}{ip} },
											{
												ip    => $ip_split_item,
												if    => $ip_if,
												gw    => $ip_gw,
												gw_if => $ip_gw_if,
											}
										);
									} ## end if ( $ip_split_item ne '' && $ip_split_item...)
								} ## end foreach my $ip_split_item (@ip_split)
							} ## end else [ if ( $jls_jail->{$ip_key} !~ /[\t\ \,]/ ) ]
						} elsif ( ref( $jls_jail->{$ip_key} ) eq 'ARRAY' ) {
							foreach my $ip_array_item ( @{ $jls_jail->{$ip_key} } ) {
								$ip_array_item =~ s/^[\t\ ]*//;
								$ip_array_item =~ s/[\t\ ]*$//;
								if ( $ip_array_item !~ /[\t\ \,]/ ) {
									eval { $ip_if = $self->ip_to_if( $jls_jail->{$ip_key} ); };
									# if just a single IP, add it
									push( @{ $data->{oslvms}{$jname}{ip} }, $ip_array_item );
								} else {
									# if multiple IPs, split it apart and add it
									my @ip_split = split( /[\t \ \,]+/, $ip_array_item );
									foreach my $ip_split_item (@ip_split) {
										if ( $ip_split_item ne '' && $ip_split_item =~ /^[A-Fa-f\:\.0-9]+$/ ) {
											eval { $ip_if = $self->ip_to_if( $jls_jail->{$ip_key} ); };
											push(
												@{ $data->{oslvms}{$jname}{ip} },
												{
													ip    => $ip_split_item,
													if    => $ip_if,
													gw    => $ip_gw,
													gw_if => $ip_gw_if,
												}
											);
										} ## end if ( $ip_split_item ne '' && $ip_split_item...)
									} ## end foreach my $ip_split_item (@ip_split)
								} ## end else [ if ( $ip_array_item !~ /[\t\ \,]/ ) ]
							} ## end foreach my $ip_array_item ( @{ $jls_jail->{$ip_key...}})
						} ## end elsif ( ref( $jls_jail->{$ip_key} ) eq 'ARRAY')
					} ## end if ( defined( $jls_jail->{$ip_key} ) && ( ...))
				} ## end foreach my $ip_key (@IP_keys)
			} ## end if ( $self->{obj}->include( $jls_jail->{'hostname'...}))
		} ## end foreach my $jls_jail ( @{ $jls->{'jail-information'...}})
	} ## end if ( defined($jls) && ref($jls) eq 'HASH' ...)

	# remove possible dup paths
	my @found_jails = keys( %{ $data->{oslvms} } );
	foreach my $jail (@found_jails) {
		my @uniq_paths = uniq( @{ $data->{oslvms}{$jail}{path} } );
		$data->{oslvms}{$jail}{path} = \@uniq_paths;
	}

	my @stats = (
		'copy-on-write-faults',         'cpu-time',
		'data-size',                    'elapsed-times',
		'involuntary-context-switches', 'major-faults',
		'minor-faults',                 'percent-cpu',
		'percent-memory',               'read-blocks',
		'received-messages',            'rss',
		'sent-messages',                'stack-size',
		'swaps',                        'system-time',
		'text-size',                    'user-time',
		'virtual-size',                 'voluntary-context-switches',
		'written-blocks',               'signals-taken',
	);

	$output
		= `/bin/ps a --libxo json -o %cpu,%mem,pid,acflag,cow,dsiz,etimes,inblk,jail,majflt,minflt,msgrcv,msgsnd,nivcsw,nswap,nvcsw,oublk,rss,ssiz,systime,time,tsiz,usertime,vsz,pid,gid,uid,command,jid,nsigs 2> /dev/null`;
	my $ps;
	eval { $ps = decode_json($output); };
	if ($@) {
		push( @{ $data->{errors} }, 'decoding output from ps failed... ' . $@ );
		return $data;
	}

	# values that are time stats that require additional processing
	my $times = { 'cpu-time' => 1, 'system-time' => 1, 'user-time' => 1, };
	# these are counters and differences needed computed for them
	my $counters = {
		'cpu-time'                     => 1,
		'system-time'                  => 1,
		'user-time'                    => 1,
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
	};

	if (   defined($ps)
		&& ref($ps) eq 'HASH'
		&& defined( $ps->{'process-information'} )
		&& ref( $ps->{'process-information'} ) eq 'HASH'
		&& defined( $ps->{'process-information'}{process} )
		&& ref( $ps->{'process-information'}{process} ) eq 'ARRAY' )
	{
		foreach my $proc ( @{ $ps->{'process-information'}{process} } ) {
			# - means there is no jail
			# if it is not defined it means it was previously not included
			if ( $proc->{'jail-name'} ne '-' && defined( $data->{oslvms}{ $proc->{'jail-name'} } ) ) {
				my $cache_name
					= $proc->{pid} . '-'
					. $proc->{uid} . '-'
					. $proc->{gid} . '-'
					. $proc->{'jail-id'} . '-'
					. $proc->{command};

				foreach my $stat (@stats) {
					# pre-process the stat if it is a time value that requires it
					if ( defined( $times->{$stat} ) ) {
						# [days-][hours:]minutes:seconds
						my $seconds = 0;
						my $time    = $proc->{$stat};

						if ( $time =~ /-/ ) {
							my $days = $time;
							$days =~ s/\-.*$//;
							$seconds = $seconds + ( $days * 86400 );
						} else {
							my @time_split = split( /\:/, $time );
							if ( defined( $time_split[2] ) ) {
								$seconds
									= $seconds + ( 3600 * $time_split[0] ) + ( 60 * $time_split[1] ) + $time_split[2];
							} else {
								$seconds = $seconds + ( 60 * $time_split[1] ) + $time_split[1];
							}
						}
						$proc->{$stat} = $seconds;
					} ## end if ( defined( $times->{$stat} ) )

					if ( $counters->{$stat} ) {
						my $stat_value;
						if ( defined( $proc_cache->{$cache_name} ) && defined( $proc_cache->{$cache_name}{$stat} ) ) {
							$stat_value = ( $proc->{$stat} - $proc_cache->{$cache_name}{$stat} ) / 300;
						} else {
							$stat_value = $proc->{$stat} / 300;
						}
						$data->{oslvms}{ $proc->{'jail-name'} }{$stat}
							= $data->{oslvms}{ $proc->{'jail-name'} }{$stat} + $stat_value;
						$data->{totals}{$stat} = $data->{totals}{$stat} + $stat_value;
					} else {
						$data->{oslvms}{ $proc->{'jail-name'} }{$stat}
							= $data->{oslvms}{ $proc->{'jail-name'} }{$stat} + $proc->{$stat};
						$data->{totals}{$stat} = $data->{totals}{$stat} + $proc->{$stat};
					}
				} ## end foreach my $stat (@stats)

				$data->{oslvms}{ $proc->{'jail-name'} }{procs}++;
				$data->{totals}{procs}++;

				$new_proc_cache->{$cache_name} = $proc;
			} ## end if ( $proc->{'jail-name'} ne '-' && defined...)
		} ## end foreach my $proc ( @{ $ps->{'process-information'...}})
	} ## end if ( defined($ps) && ref($ps) eq 'HASH' &&...)

	# save the proc cache for next run
	eval { write_file( $self->{proc_cache}, encode_json($new_proc_cache) ); };
	if ($@) {
		push( @{ $data->{errors} }, 'saving proc cache failed, "' . $self->{proc_cache} . '"... ' . $@ );
		return $data;
	}

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
	if ( $^O !~ 'freebsd' ) {
		die '$^O is "' . $^O . '" and not "freebsd"';
	}

	# make sure we can locate jls
	my $cmd_bin = `/bin/sh -c 'which jls 2> /dev/null'`;
	if ( $? != 0 ) {
		die 'The command "jls" is not in the path... ' . $ENV{PATH};
	}

	return 1;
} ## end sub usable

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
