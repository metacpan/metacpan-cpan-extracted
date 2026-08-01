package Net::Connection::FreeBSD_sockstat;

use 5.006;
use strict;
use warnings;
use Net::Connection;
use JSON;
require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(sockstat_to_nc_objects);

=head1 NAME

Net::Connection::FreeBSD_sockstat - Creates Net::Connection objects using sockstat on FreeBSD.

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

    use Net::Connection::FreeBSD_sockstat;

    my @objects;
    eval{ @objects=&sockstat_to_nc_objects; };

    # this time don't resolve ports, ptrs, or usernames
    my $args={
         ports=>0,
         ptrs=>0,
    };
    eval{ @objects=&sockstat_to_nc_objects( $args )); };

=head1 REQUIREMENTS

This parses the JSON emitted by 'sockstat -46s --libxo json'.

libxo support was added to sockstat in FreeBSD 15.0. Earlier releases ship a
sockstat that does not understand '--libxo' and will exit with a usage error.

Process information is gathered by calling ps instead of reading the process
table directly, so nothing outside of the base system is needed for that.

Worth noting for anyone coming from 0.0.x, which used Proc::ProcessTable, is
that ps appends the accounting name in parentheses when a proc has rewritten
its argv, so proc for those reads like the first of the two below instead of
the second.

    MUSHclient.exe (wine)
    MUSHclient.exe

=head1 SUBROUTINES

=head2 sockstat_to_nc_objects

This parses the output of 'sockstat -46s --libxo json'.

Upon error, this will die.

=head3 args hash

=head4 ports

Attempt to resolve the port names.

Defaults to 1.

This value is a Perl boolean.

=head4 ptrs

Attempt to resolve the PTRs.

Defaults to 1.

This value is a Perl boolean.

=head4 proc_info

Call ps and use that to fill in additional info.

This is incompatible with the string option.

This defaults to true if no string is specified.

This value is a Perl boolean.

=head4 string

If this is specified, it parses the string instead of calling sockstat.

The string is expected to be the JSON produced by
'sockstat -46s --libxo json'.

If running this on anything other than FreeBSD with out passing this, it will die.

=head4 zombie_skip

This skips sockets that are not associated with any process.

These are the sockets that print as the line below with the standard text
output, the JSON for them lacking the user, command, pid, and fd keys.

    USER     COMMAND    PID   FD PROTO  LOCAL ADDRESS         FOREIGN ADDRESS       PATH STATE   CONN STATE
    ?        ?          ?     ?  tcp6   ::1:4045              *:*                                LISTEN

When these are not skipped, the resulting objects have a username of ? with
the PID and UID left undefined, as Net::Connection requires those two to be
numeric when they are defined.

This defaults to 1.

The value taken is a Perl boolean.

=cut

sub sockstat_to_nc_objects {
	my %func_args;
	if ( defined( $_[0] ) ) {
		%func_args = %{ $_[0] };
	}

	#
	# set the defaults for the various args
	#
	if ( !defined( $func_args{proc_info} ) ) {

		# if a string is set, default to false
		if ( defined( $func_args{string} ) ) {
			$func_args{proc_info} = 0;
		} else {
			$func_args{proc_info} = 1;
		}
	}
	if ( !defined( $func_args{ptrs} ) ) {
		$func_args{ptrs} = 1;
	}
	if ( !defined( $func_args{ports} ) ) {
		$func_args{ports} = 1;
	}
	if ( !defined( $func_args{zombie_skip} ) ) {
		$func_args{zombie_skip} = 1;
	}

	my $sockstat_raw;
	if ( defined( $func_args{string} ) ) {
		$sockstat_raw = $func_args{string};

		if ( $func_args{proc_info} ) {
			die('Function args string and proc_info are mutually exclusive');
		}
	} else {
		if ( $^O !~ /freebsd/ ) {
			die('According to $^O, this is not FreeBSD and this is specifically written for FreeBSDs sockstat');
		}

		$sockstat_raw = `sockstat -46s --libxo json`;
		if ( $? != 0 ) {
			die( 'Calling "sockstat -46s --libxo json" failed with a exit code of ' . ( $? >> 8 ) );
		}
	} ## end else [ if ( defined( $func_args{string} ) ) ]

	my $sockstat_parsed;
	eval { $sockstat_parsed = decode_json($sockstat_raw); };
	if ($@) {
		die( 'Failed to decode the JSON from sockstat... ' . $@ );
	}

	if (   ( ref($sockstat_parsed) ne 'HASH' )
		|| ( ref( $sockstat_parsed->{sockstat} ) ne 'HASH' )
		|| ( ref( $sockstat_parsed->{sockstat}{socket} ) ne 'ARRAY' ) )
	{
		die('The JSON from sockstat does not contain the array .sockstat.socket');
	}

	# fetched once and then reused for each socket the PID in question owns
	my $proc_info;
	if ( $func_args{proc_info} ) {
		$proc_info = &_ps_proc_info;
	}

	# holds the Net::Connection objects
	my @nc_objects;

	foreach my $socket ( @{ $sockstat_parsed->{sockstat}{socket} } ) {

		# sockets with no owning process lack the user, command, pid, and fd keys
		my $orphaned = 0;
		if ( !defined( $socket->{pid} ) || !defined( $socket->{user} ) ) {
			$orphaned = 1;
		}

		if ( $orphaned && $func_args{zombie_skip} ) {
			next;
		}

		# Net::Connection wants the PID and UID left undef rather than filled
		# in with something like a question mark as it requires them to be
		# numeric when they are defined
		my $uid;
		my $pid;
		my $username = '?';
		if ( !$orphaned ) {
			$pid      = $socket->{pid};
			$username = $socket->{user};

			# sockstat prints the raw UID when it can not be resolved to a name
			$uid = getpwnam($username);
			if ( !defined($uid) && ( $username =~ /^[0-9]+$/ ) ) {
				$uid = $username;
			}
		} ## end if ( !$orphaned )

		# the basic args initially for Net::Connection
		my $args = {
			pid         => $pid,
			uid         => $uid,
			username    => $username,
			state       => '',
			proto       => $socket->{proto},
			ports       => $func_args{ports},
			ptrs        => $func_args{ptrs},
			uid_resolve => $func_args{uid_resolve},
		};

		# libxo breaks the addresses out into their own containers, meaning
		# there is no need to figure out where the address stops and the port
		# begins like there is with the text output
		$args->{local_host}   = $socket->{local}{address};
		$args->{local_port}   = &_port_stringify( $socket->{local}{port} );
		$args->{foreign_host} = $socket->{foreign}{address};
		$args->{foreign_port} = &_port_stringify( $socket->{foreign}{port} );

		# only emitted for the protocols that have a connection state, so TCP and SCTP
		if ( defined( $socket->{'conn-state'} ) ) {
			$args->{state} = $socket->{'conn-state'};
		}

		#
		# put together process info if requested
		# skips adding it if the socket is orphaned as that means the proc no longer exists
		#
		if (   $func_args{proc_info}
			&& !$orphaned
			&& defined( $proc_info->{$pid} ) )
		{
			$args->{proc}      = $proc_info->{$pid}{proc};
			$args->{wchan}     = $proc_info->{$pid}{wchan};
			$args->{pctmem}    = $proc_info->{$pid}{pctmem};
			$args->{pctcpu}    = $proc_info->{$pid}{pctcpu};
			$args->{pid_start} = $proc_info->{$pid}{pid_start};
		} ## end if ( $func_args{proc_info} && !$orphaned &&...)

		push( @nc_objects, Net::Connection->new($args) );
	} ## end foreach my $socket ( @{ $sockstat_parsed->{sockstat...}})

	return @nc_objects;
} ## end sub sockstat_to_nc_objects

#
# libxo emits the port as a integer, using zero where the text output uses a
# star, so map it back so the returned objects match what sockstat displays
#
sub _port_stringify {
	my $port = $_[0];

	if ( !defined($port) || ( $port eq '0' ) ) {
		return '*';
	}

	return $port;
}

#
# Calls ps and returns a hash ref, keyed on PID, of the bits that
# Net::Connection wants filled in.
#
sub _ps_proc_info {
	my $ps_raw = `ps -axww -o pid,wchan,%cpu,%mem,etimes,command --libxo json`;
	if ( $? != 0 ) {
		die( 'Calling ps failed with a exit code of ' . ( $? >> 8 ) );
	}

	my $ps_parsed;
	eval { $ps_parsed = decode_json($ps_raw); };
	if ($@) {
		die( 'Failed to decode the JSON from ps... ' . $@ );
	}

	if (   ( ref($ps_parsed) ne 'HASH' )
		|| ( ref( $ps_parsed->{'process-information'} ) ne 'HASH' )
		|| ( ref( $ps_parsed->{'process-information'}{process} ) ne 'ARRAY' ) )
	{
		die('The JSON from ps does not contain the array .process-information.process');
	}

	# ps reports how long the proc has been running instead of when it started
	my $now = time;

	my $proc_info = {};
	foreach my $proc ( @{ $ps_parsed->{'process-information'}{process} } ) {
		if ( !defined( $proc->{pid} ) ) {
			next;
		}

		# ps already wraps the names of kernel procs in square brackets
		$proc_info->{ $proc->{pid} } = {
			proc      => $proc->{command},
			wchan     => $proc->{'wait-channel'},
			pctcpu    => $proc->{'percent-cpu'} + 0,
			pctmem    => $proc->{'percent-memory'} + 0,
			pid_start => $now - $proc->{'elapsed-times'},
		};
	} ## end foreach my $proc ( @{ $ps_parsed->{'process-information'...}})

	return $proc_info;
} ## end sub _ps_proc_info

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-connection-freebsd_sockstat at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Connection-FreeBSD_sockstat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Connection::FreeBSD_sockstat


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Connection-FreeBSD_sockstat>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-Connection-FreeBSD_sockstat>

=item * Search CPAN

L<https://metacpan.org/release/Net-Connection-FreeBSD_sockstat>

=item * Git Repo

L<https://gitea.eesdp.org/vvelox/Net-Connection-FreeBSD_sockstat>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Net::Connection::FreeBSD_sockstat
