package Net::Connection::ncnetstat;

use 5.006;
use strict;
use warnings;
use Net::Connection;
use Net::Connection::Match;
use Net::Connection::Sort;
use Term::ANSIColor;
use Proc::ProcessTable;
use Text::ANSITable;

# the native collection method for the OS in question, if there is one
my %native_collectors = (
	linux   => [ 'Net::Connection::Linux_ss',         'ss_to_nc_objects' ],
	freebsd => [ 'Net::Connection::FreeBSD_sockstat', 'sockstat_to_nc_objects' ],
);

# the collection method to fall back to when there is no usable native one
my @lsof_collector = ( 'Net::Connection::lsof', 'lsof_to_nc_objects' );

# holds the code ref for the collection method chosen by &_collector
my $collector;

=head1 NAME

Net::Connection::ncnetstat - The backend for ncnetstat, the colorized and enhanced netstat like tool.

=head1 VERSION

Version 0.9.0

=cut

our $VERSION = '0.9.0';

=head1 SYNOPSIS

    use Net::Connection::ncnetstat;
    
    # Net::Connection::Match filters
    my @filters=(
                 {
                  type=>'States',
                  invert=>1,
                  args=>{
                         states=>['LISTEN']
                  }
                 }
                );
    
    my $ncnetstat=Net::Connection::ncnetstat->new(
                                                  {
                                                   ptr=>1,
                                                   command=>1,
                                                   command_long=>0,
                                                   wchan=>0,
                                                   pct_show=>1,
                                                   sorter=>{
                                                            invert=>0,
                                                            type=>'host_lf',
                                                   },
                                                   match=>{
                                                           checks=>\@filters,
                                                   }
                                                  }
                                                 );
    
    print $ncnetstat->run;

=head1 METHODS

=head2 new

This initiates the object.

    my $ncnetstat=Net::Connection::ncnetstat->new( \%args );

=head3 args hash ref

=head4 command

If set to true, it will show the command for the PID.

=head4 command_long

If set to true, the full command is shown.

This requires command also being true.

=head4 match

This is the hash to pass to L<Net::Connection::Match>.

By default this is undef and that module won't be used.

=head4 no_pid_user

Don't show the PID or UID/user colomn.

=head4 sorter

This is what is to be passed to L<Net::Connection::Sorter>.

The default is as below.

    {
     type=>'unsorted',
     invert=>0,
    }

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ) {
		%args = %{ $_[1] };
	}

	if ( !defined( $args{sorter} ) ) {
		$args{sorter} = {
			type   => 'unsorted',
			invert => 0,
		};
	}

	my $self = {
		invert       => 0,
		sorter       => Net::Connection::Sort->new( $args{sorter} ),
		ptr          => 1,
		command      => 0,
		command_long => 0,
		wchan        => 0,
		pct          => 0,
		no_pid_user  => 0,
	};
	bless $self;

	if ( defined( $args{match} ) ) {
		$self->{match} = Net::Connection::Match->new( $args{match} );
	}

	if ( defined( $args{ptr} ) ) {
		$self->{ptr} = $args{ptr};
	}

	if ( defined( $args{command} ) ) {
		$self->{command} = $args{command};
	}

	if ( defined( $args{pct} ) ) {
		$self->{pct} = $args{pct};
	}

	if ( defined( $args{wchan} ) ) {
		$self->{wchan} = $args{wchan};
	}

	if ( defined( $args{command_long} ) ) {
		$self->{command_long} = $args{command_long};
	}

	if ( defined( $args{no_pid_user} ) ) {
		$self->{no_pid_user} = $args{no_pid_user};
	}

	return $self;
} ## end sub new

# Returns the code ref for the collection method to use, loading the module it
# lives in as needed.
#
# The native collection method for the OS in question is preferred, but as it is
# entirely possible for that module to not be installed, L<Net::Connection::lsof>
# is used as a fallback. This is why the loading is done at runtime instead of
# via use, as a missing native module should not render this module unusable.
sub _collector {
	if ( defined($collector) ) {
		return $collector;
	}

	my @to_try;
	if ( defined( $native_collectors{$^O} ) ) {
		push( @to_try, $native_collectors{$^O} );
	}
	push( @to_try, \@lsof_collector );

	my @failures;
	foreach my $to_try (@to_try) {
		my ( $module, $sub_name ) = @{$to_try};

		my $module_file = $module . '.pm';
		$module_file =~ s/::/\//g;

		if ( !eval { require $module_file; 1 } ) {
			push( @failures, $module . ' could not be loaded... ' . $@ );
			next;
		}

		$collector = $module->can($sub_name);
		if ( defined($collector) ) {
			return $collector;
		}

		push( @failures, $module . ' does not provide ' . $sub_name );
	} ## end foreach my $to_try (@to_try)

	die( 'No usable connection collection method found... ' . join( ' ', @failures ) );
} ## end sub _collector

=head2 run

This runs it and returns a string.

The collection method used is chosen based on the OS. L<Net::Connection::Linux_ss>
is used on Linux and L<Net::Connection::FreeBSD_sockstat> on FreeBSD. Anything
else falls back to L<Net::Connection::lsof>, which is also used if the native
module for the OS in question is not installed.

    print $ncnetstat->run;

=cut

sub run {
	my $self = $_[0];

	my $collection_method = _collector();
	my @objects           = &{$collection_method}();

	my @found;
	if ( defined( $self->{match} ) ) {
		foreach my $conn (@objects) {
			if ( $self->{match}->match($conn) ) {
				push( @found, $conn );
			}
		}
	} else {
		@found = @objects;
	}

	@found = $self->{sorter}->sorter( \@found );

	my $tb = Text::ANSITable->new;
	$tb->border_style('ASCII::None');
	$tb->color_theme('NoColor');

	my @headers;
	my $header_int = 0;
	push( @headers, 'Proto' );
	$tb->set_column_style( $header_int, pad => 0 );
	$header_int++;
	if ( !$self->{no_pid_user} ) {
		push( @headers, 'User' );
		$tb->set_column_style( $header_int, pad => 1 );
		$header_int++;
		push( @headers, 'PID' );
		$tb->set_column_style( $header_int, pad => 0 );
		$header_int++;
	}
	push( @headers, 'Local Host' );
	$tb->set_column_style( $header_int, pad => 1, formats => [ [ wrap => { ansi => 1, mb => 1 } ] ] );
	$header_int++;
	push( @headers, 'L Port' );
	$tb->set_column_style( $header_int, pad => 0 );
	$header_int++;
	push( @headers, 'Remote Host' );
	$tb->set_column_style( $header_int, pad => 1, formats => [ [ wrap => { ansi => 1, mb => 1 } ] ] );
	$header_int++;
	push( @headers, 'R Port' );
	$tb->set_column_style( $header_int, pad => 0 );
	$header_int++;
	push( @headers, 'State' );
	$tb->set_column_style( $header_int, pad => 1 );
	$header_int++;

	my $padding = 0;
	if ( $self->{wchan} ) {
		if ( ( $header_int % 2 ) != 0 ) {
			$padding = 1;
		}
		push( @headers, 'WChan' );
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	}

	if ( $self->{pct} ) {
		if ( ( $header_int % 2 ) != 0 ) {
			$padding = 1;
		} else {
			$padding = 0;
		}
		push( @headers, 'CPU%' );
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
		if ( ( $header_int % 2 ) != 0 ) {
			$padding = 1;
		} else {
			$padding = 0;
		}
		push( @headers, 'Mem%' );
		$tb->set_column_style( $header_int, pad => $padding );
		$header_int++;
	} ## end if ( $self->{pct} )

	if ( $self->{command} ) {
		if ( ( $header_int % 2 ) != 0 ) {
			$padding = 1;
		} else {
			$padding = 0;
		}
		push( @headers, 'Command' );
		$tb->set_column_style( $header_int, pad => $padding, formats => [ [ wrap => { ansi => 1, mb => 1 } ] ] );
		$header_int++;
	} ## end if ( $self->{command} )

	$tb->set_column_style( 4,  pad => 0 );
	$tb->set_column_style( 5,  pad => 1, formats => [ [ wrap => { ansi => 1, mb => 1 } ] ] );
	$tb->set_column_style( 6,  pad => 0 );
	$tb->set_column_style( 7,  pad => 1 );
	$tb->set_column_style( 8,  pad => 0 );
	$tb->set_column_style( 9,  pad => 1 );
	$tb->set_column_style( 10, pad => 0 );
	$tb->set_column_style( 11, pad => 1, formats => [ [ wrap => { ansi => 1, mb => 1 } ] ] );
	$tb->set_column_style( 12, pad => 0 );
	$tb->set_column_style( 13, pad => 1 );

	$tb->columns( \@headers );

	# process table stuff if needed
	my $ppt;
	my $proctable;
	my %cmd_cache;
	if ( $self->{command} ) {
		$ppt       = Proc::ProcessTable->new;
		$proctable = $ppt->table;
	}

	my @td;
	foreach my $conn (@found) {
		my @new_line = ( color('bright_yellow') . $conn->proto . color('reset'), );

		# don't add the PID or user if requested to
		if ( !$self->{no_pid_user} ) {

			# handle adding the username or UID if we have one
			if ( defined( $conn->username ) ) {
				push( @new_line, color('bright_cyan') . $conn->username . color('reset') );
			} else {
				if ( defined( $conn->uid ) ) {
					push( @new_line, color('bright_cyan') . $conn->uid . color('reset') );
				} else {
					push( @new_line, '' );
				}
			}

			# handle adding the PID if we have one
			if ( defined( $conn->pid ) ) {
				push( @new_line, color('bright_red') . $conn->pid . color('reset') );
				$conn->pid;
			} else {
				push( @new_line, '' );
			}
		} ## end if ( !$self->{no_pid_user} )

		# Figure out what we are using for the local host
		my $local;
		if ( defined( $conn->local_ptr ) && $self->{ptr} ) {
			$local = $conn->local_ptr;
		} else {
			$local = $conn->local_host;
		}

		# Figure out what we are using for the foriegn host
		my $foreign;
		if ( defined( $conn->foreign_ptr ) && $self->{ptr} ) {
			$foreign = $conn->foreign_ptr;
		} else {
			$foreign = $conn->foreign_host;
		}

		# Figure out what we are using for the local port
		my $lport;
		if ( defined( $conn->local_port_name ) ) {
			$lport = $conn->local_port_name;
		} else {
			$lport = $conn->local_port;
		}

		# Figure out what we are using for the foreign port
		my $fport;
		if ( defined( $conn->foreign_port_name ) ) {
			$fport = $conn->foreign_port_name;
		} else {
			$fport = $conn->foreign_port;
		}

		push( @new_line,
			color('bright_green') . $local . color('reset'),
			color('green') . $lport . color('reset'),
			color('bright_magenta') . $foreign . color('reset'),
			color('magenta') . $fport . color('reset'),
			color('bright_blue') . $conn->state . color('reset'),
		);

		# handle the wchan bit if needed
		if ( $self->{wchan}
			&& defined( $conn->wchan ) )
		{
			push( @new_line, color('bright_yellow') . $conn->wchan . color('reset') );
		}

		# handle the percent stuff if needed
		if ( $self->{pct}
			&& defined( $conn->pctcpu ) )
		{
			push( @new_line, color('bright_cyan') . sprintf( '%.2f', $conn->pctcpu ) . color('reset') );
		}

		# handle the percent stuff if needed
		if ( $self->{pct}
			&& defined( $conn->pctmem ) )
		{
			push( @new_line, color('bright_green') . sprintf( '%.2f', $conn->pctmem ) . color('reset') );
		}

		# handle the command portion if needed
		if ( defined( $conn->pid )
			&& $self->{command} )
		{

			my $loop = 1;
			my $proc = 0;
			while ( defined( $proctable->[$proc] )
				&& $loop )
			{
				my $command;
				if ( defined( $cmd_cache{ $conn->pid } ) ) {
					push( @new_line, color('bright_red') . $cmd_cache{ $conn->pid } . color('reset') );
					$loop = 0;
				} elsif ( defined( $conn->proc ) ) {
					my $command = $conn->proc;
					if ( !$self->{command_long} ) {
						$command =~ s/\ .*//;
					}
					$cmd_cache{ $conn->pid } = $command;
					push( @new_line, color('bright_red') . $cmd_cache{ $conn->pid } . color('reset') );
					$loop = 0,;
				} elsif ( $proctable->[$proc]->pid eq $conn->pid ) {
					if ( $proctable->[$proc]->{'cmndline'} =~ /^$/ ) {

						#kernel process
						$cmd_cache{ $conn->pid }
							= color('bright_red') . '[' . $proctable->[$proc]->{'fname'} . ']' . color('reset');
					} elsif ( $self->{command_long} ) {
						$cmd_cache{ $conn->pid }
							= color('bright_red') . $proctable->[$proc]->{'cmndline'} . color('reset');
					} elsif ( $proctable->[$proc]->{'cmndline'} =~ /^\// ) {

						# something ran with a complete path
						$cmd_cache{ $conn->pid }
							= color('bright_red') . $proctable->[$proc]->{'fname'} . color('reset');
					} else {
						# likely a thread or the like... such as dovecot/auth
						# just trunkcat everything after the space
						my $cmd = $proctable->[$proc]->{'cmndline'};
						$cmd =~ s/\ +.*//g;
						$cmd_cache{ $conn->pid } = color('bright_red') . $cmd . color('reset');
					}

					push( @new_line, $cmd_cache{ $conn->pid } );
					$loop = 0;
				} ## end elsif ( $proctable->[$proc]->pid eq $conn->pid)

				$proc++;
			} ## end while ( defined( $proctable->[$proc] ) && $loop)

		} elsif ( ( !defined( $conn->pid ) )
			&& $self->{command} )
		{
			push( @new_line, '' );
		}

		$tb->add_row( \@new_line );
	} ## end foreach my $conn (@found)

	return $tb->draw;
} ## end sub run

=head1 TODO

* Add support for more collection methods.

* Support color selection and column ordering.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-connection-ncnetstat at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Connection-ncnetstat>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Connection::ncnetstat


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Connection-ncnetstat>

=item * Search CPAN

L<https://metacpan.org/release/Net-Connection-ncnetstat>

=item * Repository

L<https://github.com/VVelox/Net-Connection-ncnetstat>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Net::Connection::ncnetstat
