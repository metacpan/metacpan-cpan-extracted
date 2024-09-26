package OSLV::Monitor::Backends::FreeBSD;

use 5.006;
use strict;
use warnings;
use JSON;
use Clone 'clone';
use File::Slurp;
use List::Util qw( uniq );

=head1 NAME

OSLV::Monitor::Backends::FreeBSD - backend for FreeBSD jails

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';

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

	# get a list of jails for jid to name mapping
	my $output = `/usr/sbin/jls -h --libxo json 2> /dev/null`;
	my $jls;
	my %jid_to_name;
	my @IP_keys = ( 'ip4.addr', 'ip6.addr' );
	eval { $jls = decode_json($output) };
	if ($@) {
		push( @{ $data->{errors} }, 'decoding output from "jls -s --libxo json 2> /dev/null" failed... ' . $@ );
		return $data;
	}
	if (   defined($jls)
		&& ref($jls) eq 'HASH'
		&& defined( $jls->{'jail-information'} )
		&& ref( $jls->{'jail-information'} ) eq 'HASH'
		&& defined( $jls->{'jail-information'}{jail} )
		&& ref( $jls->{'jail-information'}{jail} ) eq 'ARRAY' )
	{
		foreach my $jls_jail ( @{ $jls->{'jail-information'}{jail} } ) {
			if ( defined( $jls_jail->{name} ) && defined( $jls_jail->{jid} ) ) {
				my $jname = $jls_jail->{name};

				$jid_to_name{ $jls_jail->{jid} } = $jname;

				$data->{oslvms}{$jname} = clone($base_stats);

				# finds each ip ifconfig shows in a jail
				my $output = `ifconfig -j $jname 2> /dev/null`;
				my %found_IPv4;
				my %found_IPv6;
				if ( $? eq 0 ) {
					my @output_split = split( /\n/, $output );
					my $interface;
					foreach my $line (@output_split) {
						if ( $line =~ /^[a-zA-Z].*\:[\ \t]+flags\=/ ) {
							$interface = $line;
							$interface =~ s/\:[\ \t]+flags.*//;
						} elsif ( $line =~ /^[\ \t]+inet6 /
							&& defined($interface) )
						{
							$line =~ s/^[\ \t]+inet6 //;
							$line =~ s/\ .*$//;
							$line =~ s/\%.*$//;
							$found_IPv6{$line} = $interface;
						} elsif ( $line =~ /^[\ \t]+inet /
							&& defined($interface) )
						{
							$line =~ s/^[\ \t]+inet //;
							$line =~ s/ .*$//;
							$found_IPv4{$line} = $interface;
						}
					} ## end foreach my $line (@output_split)
				} ## end if ( $? eq 0 )

				foreach my $ip_key (@IP_keys) {
					my @current_IPs;

					if ( $ip_key eq 'ip4.addr' ) {
						@current_IPs = keys(%found_IPv4);
					} else {
						@current_IPs = keys(%found_IPv6);
					}

					if (   defined( $jls_jail->{$ip_key} )
						&& ref( $jls_jail->{$ip_key} ) eq 'ARRAY'
						&& defined( $jls_jail->{$ip_key}[0] ) )
					{
						foreach my $ip ( @{ $jls_jail->{$ip_key} } ) {
							if ( ref($ip) eq '' && !defined( $found_IPv4{$ip} ) && !defined( $found_IPv6{$ip} ) ) {
								if (   $ip =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/
									|| $ip =~ /^[\:0-9a-fA-F]+$/ )
								{
									push( @current_IPs, $ip );
								}
							}
						}
					} ## end if ( defined( $jls_jail->{$ip_key} ) && ref...)
					foreach my $ip (@current_IPs) {
						my $ip_if;
						my $ip_gw;
						my $ip_gw_if;

						if ( $ip_key eq 'ip4.addr'
							&& defined( $found_IPv4{$ip} ) )
						{
							$ip_if = $found_IPv4{$ip};
						} elsif ( $ip_key eq 'ip6.addr'
							&& defined( $found_IPv6{$ip} ) )
						{
							$ip_if = $found_IPv6{$ip};
						}
						# set the ip type flag for netstat
						my $ip_flag = '-6';
						if ( $ip_key eq 'ip4.addr' ) {
							$ip_flag = '-4';
						}

						# fetch netstat route info for the jail
						my $output = `route -n -j $jname $ip_flag show default 2> /dev/null`;
						if ( $? eq 0 ) {
							my @output_split = split( /\n/, $output );
							foreach my $line (@output_split) {
								if ( $line =~ /gateway\:[\ \t]/ ) {
									$line =~ s/.*gateway\:[\ \t]+//;
									$line =~ s/[\ \t]*$//;
									$ip_gw = $line;
								} elsif ( $line =~ /interface:[\ \t]/ ) {
									$line =~ s/.*interface\:[\ \t]+//;
									$line =~ s/[\ \t]*$//;
									$ip_gw_if = $line;
								}
							} ## end foreach my $line (@output_split)
						} ## end if ( $? eq 0 )

						push(
							@{ $data->{oslvms}{$jname}{ip} },
							{
								ip    => $ip,
								if    => $ip_if,
								gw    => $ip_gw,
								gw_if => $ip_gw_if,
							}
						);
					} ## end foreach my $ip (@current_IPs)
				} ## end foreach my $ip_key (@IP_keys)
			} ## end if ( defined( $jls_jail->{name} ) && defined...)
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

	foreach my $jail (@found_jails) {
		$output
			= `/bin/ps a --libxo json -o %cpu,%mem,pid,acflag,cow,dsiz,etimes,inblk,jail,majflt,minflt,msgrcv,msgsnd,nivcsw,nswap,nvcsw,oublk,rss,ssiz,systime,time,tsiz,usertime,vsz,pid,gid,uid,command,jid,nsigs -J $jail 2> /dev/null`;
		my $ps;
		eval { $ps = decode_json($output); };
		if ( !$@ ) {
			foreach my $proc ( @{ $ps->{'process-information'}{process} } ) {
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
						$data->{oslvms}{$jail}{$stat}
							= $data->{oslvms}{$jail}{$stat} + $stat_value;
						$data->{totals}{$stat} = $data->{totals}{$stat} + $stat_value;
					} else {
						$data->{oslvms}{$jail}{$stat}
							= $data->{oslvms}{$jail}{$stat} + $proc->{$stat};
						$data->{totals}{$stat} = $data->{totals}{$stat} + $proc->{$stat};
					}
				} ## end foreach my $stat (@stats)

				$data->{oslvms}{$jail}{procs}++;
				$data->{totals}{procs}++;

				$new_proc_cache->{$cache_name} = $proc;
			} ## end foreach my $proc ( @{ $ps->{'process-information'...}})
		} ## end if ( !$@ )
	} ## end foreach my $jail (@found_jails)

	# save the proc cache for next run
	eval { write_file( $self->{proc_cache}, encode_json($new_proc_cache) ); };
	if ($@) {
		push( @{ $data->{errors} }, 'saving proc cache failed, "' . $self->{proc_cache} . '"... ' . $@ );
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
