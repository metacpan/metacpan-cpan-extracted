package Net::Connection::Linux_ss;

use 5.006;
use strict;
use warnings;
use Net::Connection;
use Proc::ProcessTable;
require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(ss_to_nc_objects);

=head1 NAME

Net::Connection::Linux_ss - Creates Net::Connection objects using ss on Linux.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Net::Connection::Linux_ss;

    my @objects;
    eval{ @objects=&ss_to_nc_objects; };

    # this time don't resolve ports or ptrs
    my $args={
         ports=>0,
         ptrs=>0,
    };
    eval{ @objects=&ss_to_nc_objects( $args ); };

=head1 REQUIREMENTS

This parses the output of 'ss -p4an' and 'ss -p6an', the ss from iproute2.

Process information beyond what ss itself reports is gathered from
L<Proc::ProcessTable> and /proc.

=head1 SUBROUTINES

=head2 ss_to_nc_objects

This calls 'ss -p4an 2> /dev/null' and 'ss -p6an 2> /dev/null', parses their
output, and returns an array of L<Net::Connection> objects.

Upon error, this will die.

A single socket may be held open by more than one process, which ss reports
as several entries in the process column of the one line. One object is
returned per process in that column, mirroring what lsof would print, so
those sockets appear more than once in the returned array.

=head3 args hash

=head4 ports

Attempt to resolve the port names.

Defaults to 1.

This value is a Perl boolean.

=head4 ptrs

Attempt to resolve the PTRs.

Defaults to 1.

This value is a Perl boolean.

=head4 uid_resolve

Attempt to resolve the UID to a username.

The UID itself is not something ss reports, so it is taken from the owner
of /proc/<pid>, meaning it is only available when this module is the one
calling ss.

Defaults to 1.

This value is a Perl boolean.

=head4 proc_info

Use L<Proc::ProcessTable> and /proc to fill in additional info.

This is what fills in proc, wchan, pctcpu, pctmem, and pid_start. Without
it, proc is still set, but to the process name ss prints, which is
truncated to fifteen characters.

This is incompatible with the string options.

This defaults to true if neither of the string options is specified.

This value is a Perl boolean.

=head4 ipv4

Call 'ss -p4an' and include the IPv4 sockets.

Defaults to 1.

This value is a Perl boolean.

=head4 ipv6

Call 'ss -p6an' and include the IPv6 sockets.

Defaults to 1.

This value is a Perl boolean.

=head4 ipv4_string

If this is specified, it parses the string as the output of 'ss -p4an'
instead of calling ss.

=head4 ipv6_string

If this is specified, it parses the string as the output of 'ss -p6an'
instead of calling ss.

If either of the string options is specified, ss is not called at all, so
specifying just one of the two parses just that one.

If running this on anything other than Linux without passing one of these,
it will die.

=head4 zombie_skip

This skips sockets that are not associated with any process, which is what
the ones with an empty process column are.

When these are not skipped, the resulting objects have the PID and UID left
undefined, as L<Net::Connection> requires those two to be numeric when they
are defined.

This defaults to 1.

The value taken is a Perl boolean.

=cut

sub ss_to_nc_objects {
	my %func_args;
	if ( defined( $_[0] ) ) {
		%func_args = %{ $_[0] };
	}

	my $strings_given = ( defined( $func_args{ipv4_string} ) || defined( $func_args{ipv6_string} ) );

	#
	# set the defaults for the various args
	#
	if ( !defined( $func_args{proc_info} ) ) {

		# if a string is set, default to false
		if ($strings_given) {
			$func_args{proc_info} = 0;
		} else {
			$func_args{proc_info} = 1;
		}
	}
	foreach my $arg_name (qw( ports ptrs uid_resolve zombie_skip ipv4 ipv6 )) {
		if ( !defined( $func_args{$arg_name} ) ) {
			$func_args{$arg_name} = 1;
		}
	}

	# each item is the raw ss output paired with the IP version it came from
	my @ss_outputs;
	if ($strings_given) {
		if ( $func_args{proc_info} ) {
			die('The ipv4_string and ipv6_string args are mutually exclusive with proc_info');
		}

		if ( defined( $func_args{ipv4_string} ) ) {
			push( @ss_outputs, [ $func_args{ipv4_string}, 4 ] );
		}
		if ( defined( $func_args{ipv6_string} ) ) {
			push( @ss_outputs, [ $func_args{ipv6_string}, 6 ] );
		}
	} else {
		if ( !$func_args{ipv4} && !$func_args{ipv6} ) {
			die('Both the ipv4 and ipv6 args are false, leaving nothing for ss to be called for');
		}

		if ( $^O !~ /linux/ ) {
			die('According to $^O, this is not Linux and this is specifically written for the ss from iproute2');
		}

		if ( $func_args{ipv4} ) {
			push( @ss_outputs, [ &_run_ss(4), 4 ] );
		}
		if ( $func_args{ipv6} ) {
			push( @ss_outputs, [ &_run_ss(6), 6 ] );
		}
	} ## end else [ if ($strings_given) ]

	# fetched once and then reused for each socket the PID in question owns
	my $proc_info = {};
	if ( $func_args{proc_info} ) {
		$proc_info = &_proc_table_info;
	}

	my $parse_state = {
		func_args => \%func_args,
		proc_info => $proc_info,

		# the PIDs only mean anything on this machine, so /proc is worth
		# poking at only when this module is the one that called ss
		live      => !$strings_given,
		uid_cache => {},
	};

	my @nc_objects;
	foreach my $ss_output (@ss_outputs) {
		push( @nc_objects, &_parse_ss_output( $ss_output->[0], $ss_output->[1], $parse_state ) );
	}

	return @nc_objects;
} ## end sub ss_to_nc_objects

#
# Calls ss for the specified IP version and returns the raw output.
#
sub _run_ss {
	my $ip_version = $_[0];

	my $ss_raw = `ss -p${ip_version}an 2> /dev/null`;
	if ( $? != 0 ) {
		die( 'Calling "ss -p' . $ip_version . 'an" failed with a exit code of ' . ( $? >> 8 ) );
	}

	return $ss_raw;
} ## end sub _run_ss

#
# Parses the output of a single ss call into Net::Connection objects.
#
sub _parse_ss_output {
	my $ss_raw      = $_[0];
	my $ip_version  = $_[1];
	my $parse_state = $_[2];

	my %func_args = %{ $parse_state->{func_args} };
	my $proc_info = $parse_state->{proc_info};

	my @nc_objects;

	foreach my $line ( split( /\n/, $ss_raw ) ) {

		# skip the header and any blank lines
		if ( ( $line =~ /^Netid/ ) || ( $line !~ /\S/ ) ) {
			next;
		}

		# the process column is left as one chunk as the process names in it
		# may contain whitespace
		my ( $netid, $conn_state, $recvq, $sendq, $local, $peer, $process_column ) = split( /[\ \t]+/, $line, 7 );

		# anything lacking the peer column is not parsable
		if ( !defined($peer) ) {
			next;
		}

		my ( $local_host, $local_port ) = &_split_host_port($local);
		my ( $peer_host,  $peer_port )  = &_split_host_port($peer);

		# ss only puts the address family in the netid for the protocols that
		# are version specific, so icmp6 stays icmp6 instead of becoming icmp66
		my $proto = $netid;
		if ( substr( $proto, -1 ) ne $ip_version ) {
			$proto = $proto . $ip_version;
		}

		# the basic args shared by every process holding this socket open
		my $socket_args = {
			local_host   => $local_host,
			local_port   => $local_port,
			foreign_host => $peer_host,
			foreign_port => $peer_port,
			proto        => $proto,
			state        => $conn_state,
			ports        => $func_args{ports},
			ptrs         => $func_args{ptrs},
		};

		# Net::Connection requires these to be numeric when they are defined
		if ( defined($recvq) && ( $recvq =~ /^[0-9]+$/ ) ) {
			$socket_args->{recvq} = $recvq;
		}
		if ( defined($sendq) && ( $sendq =~ /^[0-9]+$/ ) ) {
			$socket_args->{sendq} = $sendq;
		}

		my @processes = &_parse_process_column($process_column);

		# a socket with an empty process column is not held open by anything
		if ( !@processes ) {
			if ( $func_args{zombie_skip} ) {
				next;
			}

			push( @nc_objects, Net::Connection->new($socket_args) );
			next;
		}

		foreach my $process (@processes) {
			my $args = { %{$socket_args} };

			$args->{pid} = $process->{pid};

			# ss truncates the process name to fifteen characters, so this is
			# only a fallback for when the process table is not being used
			$args->{proc} = $process->{name};

			my $uid;
			if ( defined( $proc_info->{ $process->{pid} } ) ) {
				$uid = $proc_info->{ $process->{pid} }{uid};

				foreach my $field (qw( proc wchan pctcpu pctmem pid_start )) {
					if ( defined( $proc_info->{ $process->{pid} }{$field} ) ) {
						$args->{$field} = $proc_info->{ $process->{pid} }{$field};
					}
				}
			}

			if ( !defined($uid) && $parse_state->{live} ) {
				$uid = &_uid_for_pid( $process->{pid}, $parse_state->{uid_cache} );
			}

			# Net::Connection dies when asked to resolve without a UID or
			# username to work from, so only ask when there is a UID
			if ( defined($uid) ) {
				$args->{uid}         = $uid;
				$args->{uid_resolve} = $func_args{uid_resolve};
			}

			push( @nc_objects, Net::Connection->new($args) );
		} ## end foreach my $process (@processes)
	} ## end foreach my $line ( split( /\n/, $ss_raw ) )

	return @nc_objects;
} ## end sub _parse_ss_output

#
# Splits a 'address:port' column from ss into the two, returning them as a
# two item array.
#
sub _split_host_port {
	my $address_port = $_[0];

	# everything past the last colon is the port, which is what keeps the
	# colons in a IPv6 address from being mistaken for the separator
	my $separator = rindex( $address_port, ':' );
	if ( $separator < 0 ) {
		return ( $address_port, '*' );
	}

	my $host = substr( $address_port, 0, $separator );
	my $port = substr( $address_port, $separator + 1 );

	# ss wraps IPv6 addresses in square brackets, with any scope ID left
	# outside of them, so '[fe80::1]%eno3' becomes 'fe80::1%eno3'
	$host =~ s/[\[\]]//g;

	return ( $host, $port );
} ## end sub _split_host_port

#
# Pulls the processes out of the process column, which reads like the below,
# and returns them as an array of hash refs.
#
#     users:(("rpcbind",pid=915,fd=4),("systemd",pid=1,fd=244))
#
sub _parse_process_column {
	my $process_column = $_[0];

	my @processes;

	if ( !defined($process_column) ) {
		return @processes;
	}

	while ( $process_column =~ /\(\"(.*?)\",pid=([0-9]+)(?:,fd=([0-9]+))?/g ) {
		push( @processes, { name => $1, pid => $2, fd => $3 } );
	}

	return @processes;
} ## end sub _parse_process_column

#
# Returns a hash ref, keyed on PID, of the bits that Net::Connection wants
# filled in that ss does not report.
#
sub _proc_table_info {
	my $proc_info = {};

	foreach my $proc_entry ( @{ Proc::ProcessTable->new->table } ) {
		my %info = ( uid => $proc_entry->{uid} );

		if ( !defined( $proc_entry->{cmndline} ) || ( $proc_entry->{cmndline} eq '' ) ) {

			# kernel proc
			$info{proc} = '[' . $proc_entry->{fname} . ']';
		} else {

			# non-kernel proc
			$info{proc} = $proc_entry->{cmndline};
		}

		$info{pid_start} = $proc_entry->{start};
		$info{wchan}     = &_wchan_for_pid( $proc_entry->{pid} );

		eval { $info{pctcpu} = $proc_entry->pctcpu; };
		eval { $info{pctmem} = $proc_entry->pctmem; };

		$proc_info->{ $proc_entry->{pid} } = \%info;
	} ## end foreach my $proc_entry ( @{ Proc::ProcessTable->...})

	return $proc_info;
} ## end sub _proc_table_info

#
# Proc::ProcessTable hands back the raw address for wchan on Linux, so the
# symbol name has to come from /proc, which is not readable for every proc.
#
sub _wchan_for_pid {
	my $pid = $_[0];

	my $wchan;
	if ( open( my $wchan_fh, '<', '/proc/' . $pid . '/wchan' ) ) {
		$wchan = readline($wchan_fh);
		close($wchan_fh);

		if ( defined($wchan) ) {
			chomp($wchan);
		}
	}

	return $wchan;
} ## end sub _wchan_for_pid

#
# ss does not report the UID, but /proc/<pid> is owned by the user the proc
# is running as. The cache keeps the repeat sockets of a PID to one stat.
#
sub _uid_for_pid {
	my $pid       = $_[0];
	my $uid_cache = $_[1];

	if ( !exists( $uid_cache->{$pid} ) ) {
		$uid_cache->{$pid} = ( stat( '/proc/' . $pid ) )[4];
	}

	return $uid_cache->{$pid};
} ## end sub _uid_for_pid

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-connection-linux_ss at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Connection-Linux_ss>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Connection::Linux_ss


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Connection-Linux_ss>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-Connection-Linux_ss>

=item * Search CPAN

L<https://metacpan.org/release/Net-Connection-Linux_ss>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999


=cut

1;    # End of Net::Connection::Linux_ss
