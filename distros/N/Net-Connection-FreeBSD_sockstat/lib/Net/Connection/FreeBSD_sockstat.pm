package Net::Connection::FreeBSD_sockstat;

use 5.006;
use strict;
use warnings;
use Net::Connection;
use Proc::ProcessTable;
require Exporter;
 
our @ISA = qw(Exporter);
our @EXPORT=qw(sockstat_to_nc_objects);

=head1 NAME

Net::Connection::FreeBSD_sockstat - Creates Net::Connection objects using sockstat on FreeBSD.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


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

=head1 SUBROUTINES

=head2 sockstat_to_nc_objects

This parses the output of 'sockstat -46s'.

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

Load up the process table and use that to fill in additional info.

This is incompatible with the string option.

This defaults to true if no string is specified.

This value is a Perl boolean.

=head4 string

If this is specified, it parses the string instead of calling sockstat.

If running this on anything other than FreeBSD with out passing this, it will die.

=head4 zombie_skip

This skips items with connections that died but are still in the table.

This skips lines like the one below.

    USER     COMMAND    PID   FD PROTO  LOCAL ADDRESS         FOREIGN ADDRESS       PATH STATE   CONN STATE
    ?        ?          ?     ?  tcp6   ::1:4045              *:*                                LISTEN

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
		}
		else {
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

	my $output_raw;
	if ( defined( $func_args{string} ) ) {
		$output_raw = $func_args{string};

		if ( $func_args{proc_info} ) {
			die('Function args string and proc_info are mutually exclusive');
		}
	}

	if ( !defined($output_raw) ) {
		$output_raw = `sockstat -46s`;
		if ( $^O !~ /freebsd/ ) {
			die('According to $^O, this is not FreeBSD and this is specifically written for FreeBSDs sockstat');
		}
	}

	# split the lines of the raw
	my @output_lines = split( /\n/, $output_raw );

	# holds the Net::Conection objects
	my @nc_objects;

	# process info caches
	my %pid_proc;
	my %pid_pctmem;
	my %pid_pctcpu;
	my %pid_wchan;
	my %pid_start;

	# load the process table up if needed.
	my $proc_table;
	my $physmem;
	if ( $func_args{proc_info} ) {
		my $pt = Proc::ProcessTable->new;
		$proc_table = $pt->table;
		$physmem    = `/sbin/sysctl -a hw.physmem`;
		chomp($physmem);
		$physmem =~ s/^.*\: //;
	}

	# process each line
	my $line_int = 1;
	while ( defined( $output_lines[$line_int] ) ) {

		# skip this line if it is a zombie connection info
		my $process_line = 1;
		if ( ( $output_lines[$line_int] =~ /^\?/ ) && $func_args{zombie_skip} ) {
			$process_line = 0;
		}
		if ($process_line) {

			my $line = $output_lines[$line_int];

			my @line_split = split( /[\ \t]+/, $line );

			# USER     COMMAND    PID   FD PROTO  LOCAL ADDRESS         FOREIGN ADDRESS       PATH STATE   CONN STATE
			# kitsune  firefox    10942 44 tcp4   192.168.15.2:21084    162.159.130.234:443                CLOSED
			# ?        ?          ?     ?  tcp6   ::1:4045              *:*                                LISTEN

			my $uid      = '?';
			my $pid      = '?';
			my $username = '?';
			if ( $line_split[0] ne '?' ) {
				$pid      = $line_split[2];
				$uid      = getpwnam( $line_split[0] );
				$username = $line_split[0];
			}

			# the basic args initially for Net::Connection
			my $args = {
				pid         => $pid,
				uid         => $uid,
				username    => $username,
				state       => '',
				proto       => $line_split[4],
				ports       => $func_args{ports},
				ptrs        => $func_args{ptrs},
				uid_resolve => $func_args{uid_resolve},
			};

			# get the local and foreign IPs
			# not just splitting on \: as that will match IPv$
			$args->{local_host} = $line_split[5];
			$args->{local_host} =~ s/\:[\*0123456789]+$//;

			$args->{local_port} = $line_split[5];
			$args->{local_port} =~ s/^.*\://;

			$args->{foreign_host} = $line_split[6];
			$args->{foreign_host} =~ s/\:[\*0123456789]+$//;

			$args->{foreign_port} = $line_split[6];
			$args->{foreign_port} =~ s/^.*\://;

			# state is going to be the last item in the array if it is not UDP
			if ( $args->{proto} !~ /^udp/ ) {
				$args->{state} = $line_split[-1];
			}

			#
			# put together process info if requested
			# skips adding it if the UID is ? as that means that the proc no longer exists
			#
			if ( $func_args{proc_info}
				&& ( $args->{uid} ne '?' ) )
			{
				# if possible used cached info
				if ( defined( $pid_proc{ $args->{pid} } ) ) {
					$args->{proc}      = $pid_proc{ $args->{pid} };
					$args->{wchan}     = $pid_wchan{ $args->{pid} };
					$args->{pctmem}    = $pid_pctmem{ $args->{pid} };
					$args->{pctcpu}    = $pid_pctcpu{ $args->{pid} };
					$args->{pid_start} = $pid_start{ $args->{pid} };
				}
				else {
					my $loop     = 1;
					my $proc_int = 0;
					while ( defined( $proc_table->[$proc_int] )
						&& $loop )
					{

						# matched
						if ( $proc_table->[$proc_int]->{pid} eq $args->{pid} ) {

							# exit the loop
							$loop = 0;

							# fetch and save the proc info
							if ( $proc_table->[$proc_int]->cmndline =~ /^$/ ) {

								# kernel proc
								$args->{proc} = '[' . $proc_table->[$proc_int]->{fname} . ']';
							}
							else {
								# non-kernel proc
								$args->{proc} = $proc_table->[$proc_int]->{cmndline};
							}
							$pid_proc{ $args->{pid} } = $args->{proc};

							$args->{wchan} = $proc_table->[$proc_int]->{wchan};
							$pid_wchan{ $args->{pid} } = $args->{wchan};

							$args->{pid_start} = $proc_table->[$proc_int]->{pid_start};
							$pid_start{ $args->{pid} } = $args->{pid_start};

							$args->{pctcpu} = $proc_table->[$proc_int]->{pctcpu};
							$pid_pctcpu{ $args->{pid} } = $args->{pctcpu};

							$args->{pctmem} = ( ( $proc_table->[$proc_int]->{rssize} * 1024 * 4 ) / $physmem ) * 100;

							$pid_pctmem{ $args->{pid} } = $args->{pctmem};
						}

						$proc_int++;
					}
				}

			}

			push( @nc_objects, Net::Connection->new($args) );
		}

		$line_int++;

	}

	return @nc_objects;
}

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

1; # End of Net::Connection::FreeBSD_sockstat
