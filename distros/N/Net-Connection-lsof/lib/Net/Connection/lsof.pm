
package Net::Connection::lsof;

use 5.006;
use strict;
use warnings;
use Net::Connection;
use Proc::ProcessTable;
use POSIX ();
require Exporter;

our @ISA    = qw(Exporter);
our @EXPORT = qw(lsof_to_nc_objects);

=head1 NAME

Net::Connection::lsof - This uses lsof to generate an array of Net::Connection objects.

=head1 VERSION

Version 0.4.0

=cut

our $VERSION = '0.4.0';

=head1 SYNOPSIS

    use Net::Connection::lsof;

    my @objects;
    eval{ @objects = lsof_to_nc_objects(); };

    # this time don't resolve ports, ptrs, or usernames
    my $args={
             ports=>0,
             ptrs=>0,
             uid_resolve=>0,
             };
    eval{ @objects = lsof_to_nc_objects($args); };

=head1 SUBROUTINES

=head2 lsof_to_nc_objects

This runs 'lsof -i UDP -i TCP -n -l -P' and parses the output
returns an array of L<Net::Connection> objects. If a non-zero exit code is
returned, it will die. On Linux an exit value of 1 is also accepted as
some distros will exit 1 upon success.

There is one optional argument and that is hash reference that can take
several possible keys.

=head3 args hash

=head4 ports

Attempt to resolve the port names.

Defaults to 1.

=head4 ptrs

Attempt to resolve the PTRs.

Defaults to 1.

=head4 uid_resolve

Attempt to resolve the UID to a username.

Defaults to 1.

=head4 proc_info

Add assorted process information to the objects.

Defaults to 1.

    my @objects;
    eval{ @objects = lsof_to_nc_objects( $args ); };

=cut

sub lsof_to_nc_objects {
	my %func_args;
	if ( defined( $_[0] ) ) {
		%func_args = %{ $_[0] };
	}

	foreach my $arg_name (qw(ptrs ports uid_resolve proc_info)) {
		if ( !defined( $func_args{$arg_name} ) ) {
			$func_args{$arg_name} = 1;
		}
	}

	my $output_raw = `lsof -i UDP -i TCP -n -l -P 2> /dev/null`;

	# Some Linux distros, such as Debian 9, have a lsof that will exit 1
	# upon success, so on Linux also accept a exit value of 1.
	if ( ( $? != 0 ) && !( ( $^O eq 'linux' ) && ( $? == 256 ) ) ) {
		die(
			'"lsof -i UDP -i TCP -n -l -P" exited with a non-zero value or in the case of some linux distros a non-1 value'
		);
	}

	return _parse_lsof_output( $output_raw, \%func_args );
} ## end sub lsof_to_nc_objects

sub _parse_lsof_output {
	my $output_raw = $_[0];
	my %func_args  = %{ $_[1] };

	my @output_lines = split( /\n/, $output_raw );

	# skip the header line
	shift(@output_lines);

	my @nc_objects;

	# per PID cache of assembled process info and a PID to process table entry mapping
	my %pid_info;
	my %pid_to_proc_entry;
	my $physmem;
	if ( $func_args{proc_info} ) {
		my $process_table = Proc::ProcessTable->new->table;
		foreach my $proc_entry ( @{$process_table} ) {
			$pid_to_proc_entry{ $proc_entry->{pid} } = $proc_entry;
		}
		$physmem = _get_physmem();
	}

	foreach my $output_line (@output_lines) {

		# The first nine characters are the command column, which is not
		# used, followed by a space. Anything not longer than that is not
		# parsable.
		if ( length($output_line) <= 10 ) {
			next;
		}
		my $line = substr( $output_line, 10 );

		$line =~ s/^[\t ]*//;

		my @line_split = split( /[\ \t]+/, $line );

		# skip any line missing the name field as it is not parsable
		if ( !defined( $line_split[7] ) ) {
			next;
		}

		my $args = {
			pid         => $line_split[0],
			uid         => $line_split[1],
			ports       => $func_args{ports},
			ptrs        => $func_args{ptrs},
			uid_resolve => $func_args{uid_resolve},
		};

		my $type = $line_split[3];
		my $mode = $line_split[6];
		my $name = $line_split[7];

		# Use the name and type to build the proto.
		my $proto = '';
		if ( $type =~ /6/ ) {
			$proto = '6';
		} elsif ( $type =~ /4/ ) {
			$proto = '4';
		}
		if ( $mode =~ /[Uu][Dd][Pp]/ ) {
			$proto = 'udp' . $proto;
		} elsif ( $mode =~ /[Tt][Cc][Pp]/ ) {
			$proto = 'tcp' . $proto;
		}
		$args->{proto} = $proto;

		my ( $local, $foreign ) = split( /\-\>/, $name );

		my $ip;
		my $port;

		if ( !defined($foreign) ) {
			$args->{foreign_host} = '*';
			$args->{foreign_port} = '*';
		} else {
			if ( $foreign =~ /\]/ ) {
				( $ip, $port ) = split( /\]/, $foreign );
				$ip   =~ s/^\[//;
				$port =~ s/\://;
			} else {
				( $ip, $port ) = split( /\:/, $foreign );
			}

			$args->{foreign_host} = $ip;
			$args->{foreign_port} = $port;
		} ## end else [ if ( !defined($foreign) ) ]

		if ( $local =~ /\]/ ) {
			( $ip, $port ) = split( /\]/, $local );
			$ip   =~ s/^\[//;
			$port =~ s/\://;
		} else {
			( $ip, $port ) = split( /\:/, $local );
		}
		$args->{local_host} = $ip;
		$args->{local_port} = $port;

		$args->{state} = '';
		if ( defined( $line_split[8] ) ) {
			$args->{state} = $line_split[8];
			$args->{state} =~ s/[\(\)]//g;
		}

		#
		# put together process info if requested
		#
		if ( $func_args{proc_info} ) {
			if ( !defined( $pid_info{ $args->{pid} } ) ) {
				$pid_info{ $args->{pid} }
					= _proc_info_for_pid( $pid_to_proc_entry{ $args->{pid} }, $args->{pid}, $physmem );
			}
			my $proc_info = $pid_info{ $args->{pid} };
			foreach my $info_key ( keys( %{$proc_info} ) ) {
				$args->{$info_key} = $proc_info->{$info_key};
			}
		} ## end if ( $func_args{proc_info} )

		push( @nc_objects, Net::Connection->new($args) );
	} ## end foreach my $output_line (@output_lines)

	return @nc_objects;
} ## end sub _parse_lsof_output

sub _proc_info_for_pid {
	my $proc_entry = $_[0];
	my $pid        = $_[1];
	my $physmem    = $_[2];

	# The process exited between the lsof invocation and the process
	# table being fetched. Returning a empty hash caches the negative
	# result, preventing pointless repeat lookups.
	if ( !defined($proc_entry) ) {
		return {};
	}

	my %proc_info;

	if ( !defined( $proc_entry->{cmndline} ) || $proc_entry->{cmndline} eq '' ) {

		# kernel proc
		$proc_info{proc} = '[' . $proc_entry->{fname} . ']';
	} else {

		# non-kernel proc
		$proc_info{proc} = $proc_entry->{cmndline};
	}

	# Linux has shit wchan reporting and apparently if you want more than
	# the address you need to use the ass backwards /proc
	if ( $^O eq 'linux' ) {
		if ( open( my $wchan_fh, '<', '/proc/' . $pid . '/wchan' ) ) {
			$proc_info{wchan} = readline($wchan_fh);
			close($wchan_fh);
		}
	} else {
		$proc_info{wchan} = $proc_entry->{wchan};
	}

	$proc_info{pid_start} = $proc_entry->{start};

	eval { $proc_info{pctcpu} = $proc_entry->pctcpu; };

	# Not all platforms provide pctmem, so on those compute it from
	# the RSS, which Proc::ProcessTable provides in bytes everywhere.
	my $proc_pctmem;
	eval { $proc_pctmem = $proc_entry->pctmem; };
	if (  !defined($proc_pctmem)
		&& defined($physmem) )
	{
		eval { $proc_pctmem = ( $proc_entry->rss / $physmem ) * 100; };
	}
	$proc_info{pctmem} = $proc_pctmem;

	return \%proc_info;
} ## end sub _proc_info_for_pid

sub _get_physmem {
	my $physmem;

	# Figure out how much physical memory this machine has, which is
	# needed on platforms where Proc::ProcessTable does not provide
	# pctmem. First try POSIX::sysconf, which requires no external
	# programs, but not every POSIX module exposes _SC_PHYS_PAGES.
	eval {
		my $phys_pages = POSIX::sysconf( POSIX::_SC_PHYS_PAGES() );
		my $pagesize   = POSIX::sysconf( POSIX::_SC_PAGESIZE() );
		if ( $phys_pages && $pagesize ) {
			$physmem = $phys_pages * $pagesize;
		}
	};

	# Fall back on sysctl, checking the various places it may live.
	if ( !defined($physmem) ) {
		foreach my $sysctl_bin ( '/sbin/sysctl', '/usr/sbin/sysctl' ) {
			if ( -x $sysctl_bin ) {
				my $sysctl_physmem = `$sysctl_bin -n hw.physmem 2> /dev/null`;
				if ( defined($sysctl_physmem) ) {
					chomp($sysctl_physmem);
					if ( $sysctl_physmem =~ /^[0-9]+$/ ) {
						$physmem = $sysctl_physmem;
						last;
					}
				}
			} ## end if ( -x $sysctl_bin )
		} ## end foreach my $sysctl_bin ( '/sbin/sysctl', '/usr/sbin/sysctl')
	} ## end if ( !defined($physmem) )

	# If physmem could not be found, pctmem is left undef on platforms
	# where Proc::ProcessTable does not provide it, so failing here is
	# not fatal.

	return $physmem;
} ## end sub _get_physmem

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-connection-lsof at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Connection-lsof>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Connection::lsof


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Connection-lsof>

=item * Search CPAN

L<https://metacpan.org/release/Net-Connection-lsof>

=item * Git Repo

L<https://github.com/VVelox/Net-Connection-lsof>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Net::Connection::lsof
