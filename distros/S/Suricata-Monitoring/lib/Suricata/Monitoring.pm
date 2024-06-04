package Suricata::Monitoring;

use 5.006;
use strict;
use warnings;
use JSON;
use File::Path qw(make_path);
use File::ReadBackwards;
use Carp;
use File::Slurp;
use Time::Piece;
use Hash::Flatten qw(:all);
use MIME::Base64;
use IO::Compress::Gzip qw(gzip $GzipError);

=head1 NAME

Suricata::Monitoring - LibreNMS JSON SNMP extend and Nagios style check for Suricata stats

=head1 VERSION

Version 1.0.0

=cut

our $VERSION = '1.0.0';

=head1 SYNOPSIS

    use Suricata::Monitoring;

    my $args = {
        mode               => 'librenms',
        drop_percent_warn  => .75;
        drop_percent_crit  => 1,
        error_delta_warn   => 1,
        error_delta_crit   => 2,
        error_ignore=>[],
        files=>{
               'ids'=>'/var/log/suricata/alert-ids.json',
               'foo'=>'/var/log/suricata/alert-foo.json',
               },
    };

    my $sm=Suricata::Monitoring->new( $args );
    my $returned=$sm->run;
    $sm->print;
    exit $returned->{alert};

=head1 METHODS

=head2 new

Initiate the object.

The args are taken as a hash ref. The keys are documented as below.

The only must have is 'files'.

    - mode :: Wether the print_output output should be for Nagios or LibreNMS.
      - value :: 'librenms' or 'nagios'
      - Default :: librenms

    - drop_percent_warn :: Drop percent warning threshold.
      - Default :: .75

    - drop_percent_crit :: Drop percent critical threshold.
      - Default :: 1

    - error_delta_warn :: Error delta warning threshold. In errors/second.
      - Default :: 1

    - error_delta_crit :: Error delta critical threshold. In errors/second.
      - Default :: 2

    - max_age :: How far back to read in seconds.
      - Default :: 360

    - files :: A hash with the keys being the instance name and the values
      being the Eve files to read.

    my $args = {
        mode               => 'librenms',
        drop_percent_warn  => .75;
        drop_percent_crit  => 1,
        error_delta_warn   => 1,
        error_delta_crit   => 2,
        max_age            => 360,
        error_ignore=>[],
        files=>{
               'ids'=>'/var/log/suricata/alert-ids.json',
               'foo'=>'/var/log/suricata/alert-foo.json',
               },
    };

    my $sm=Suricata::Monitoring->new( $args );

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ) {
		%args = %{ $_[1] };
	}

	# init the object
	my $self = {
		drop_percent_warn => .75,
		drop_percent_crit => 1,
		error_delta_warn  => 1,
		error_delta_crit  => 2,
		max_age           => 360,
		mode              => 'librenms',
		cache_dir         => '/var/cache/suricata-monitoring/',
	};
	bless $self;

	# reel in the numeric args
	my @num_args = ( 'drop_percent_warn', 'drop_percent_crit', 'error_delta_warn', 'error_delta_crit', 'max_age' );
	for my $num_arg (@num_args) {
		if ( defined( $args{$num_arg} ) ) {
			$self->{$num_arg} = $args{$num_arg};
			if ( $args{$num_arg} !~ /[0-9\.]+/ ) {
				confess( '"' . $num_arg . '" with a value of "' . $args{$num_arg} . '" is not numeric' );
			}
		}
	}

	# get the mode and make sure it is valid
	if (
		defined( $args{mode} )
		&& (   ( $args{mode} ne 'librenms' )
			&& ( $args{mode} ne 'nagios' ) )
		)
	{
		confess( '"' . $args{mode} . '" is not a understood mode' );
	} elsif ( defined( $args{mode} ) ) {
		$self->{mode} = $args{mode};
	}

	# make sure we have files specified
	if (   ( !defined( $args{files} ) )
		|| ( !defined( keys( %{ $args{files} } ) ) ) )
	{
		confess('No files specified');
	} else {
		$self->{files} = $args{files};
	}

	# pull in cache dir location
	if ( defined( $args{cache_dir} ) ) {
		$self->{cache_dir} = $args{cache_dir};
	}

	# if the cache dir does not exist, try to create it
	if ( !-d $self->{cache_dir} ) {
		make_path( $self->{cache_dir} )
			or confess(
				'"' . $args{cache_dir} . '" does not exist or is not a directory and could not be create... ' . $@ );
	}

	return $self;
} ## end sub new

=head2 run

This runs it and collects the data. Also updates the cache.

This will return a LibreNMS style hash.

    my $returned=$sm->run;

=cut

sub run {
	my $self = $_[0];

	# this will be returned
	my $to_return = {
		data => {
			totals      => { drop_percent => 0, error_delta => 0 },
			instances   => {},
			alert       => 0,
			alertString => ''
		},
		version     => 2,
		error       => 0,
		errorString => '',
	};

	my $previous;
	my $previous_file = $self->{cache_dir} . '/stats.json';
	if ( -f $previous_file ) {
		#
		eval {
			my $previous_raw = read_file($previous_file);
			$previous = decode_json($previous_raw);
		};
		if ($@) {
			$to_return->{error} = '1';
			$to_return->{errorString}
				= 'Failed to read previous JSON file, "' . $previous_file . '", and decode it... ' . $@;
			$self->{results} = $to_return;
			return $to_return;
		}
	} ## end if ( -f $previous_file )

	# figure out the time slot we care about
	my $from = time;
	my $till = $from - $self->{max_age};

	# process the files for each instance
	my @instances = keys( %{ $self->{files} } );
	my @alerts;
	foreach my $instance (@instances) {

		# if we found it or not
		my $found = 0;

		# ends processing for this file
		my $process_it = 1;

		# open the file for reading it backwards
		my $bw;
		eval {
			$bw = File::ReadBackwards->new( $self->{files}{$instance} )
				or die( 'Can not read "' . $self->{files}{$instance} . '"... ' . $! );
		};
		if ($@) {
			$to_return->{error} = '2';
			if ( $to_return->{errorString} ne '' ) {
				$to_return->{errorString} = $to_return->{errorString} . "\n";
			}
			$to_return->{errorString} = $to_return->{errorString} . $instance . ': ' . $@;
			$process_it = 0;
		}

		# get the first line, if possible
		my $line;
		if ($process_it) {
			$line = $bw->readline;
		}
		while ( $process_it
			&& defined($line) )
		{
			eval {
				my $json      = decode_json($line);
				my $timestamp = $json->{timestamp};
				$timestamp =~ s/\.[0-9]*//;
				my $t = Time::Piece->strptime( $timestamp, '%Y-%m-%dT%H:%M:%S%z' );
				# stop process further lines as we've hit the oldest we care about
				if ( $t->epoch <= $till ) {
					$process_it = 0;
				}

				# this is stats and we should be processing it, continue
				if ( $process_it && defined( $json->{event_type} ) && $json->{event_type} eq 'stats' ) {
					# an array that we don't really want
					delete( $json->{stats}{detect}{engines} );
					$found                                   = 1;
					$process_it                              = 0;
					$to_return->{data}{instances}{$instance} = flatten(
						\%{ $json->{stats} },
						{
							HashDelimiter  => '__',
							ArrayDelimiter => '@@@',
						}
					);
				} ## end if ( $process_it && defined( $json->{event_type...}))
			};

			# if we did not find it, error... either Suricata is not running or stats is not output interval for
			# it is to low... needs to be under 5 minutes to function meaningfully for this
			if ( !$found && !$process_it ) {
				push( @alerts,
						  'Did not find a stats entry for instance "'
						. $instance
						. '" in "'
						. $self->{files}{$instance}
						. '" going back "'
						. $self->{max_age}
						. '" seconds' );
			} ## end if ( !$found && !$process_it )

			# get the next line
			$line = $bw->readline;
		} ## end while ( $process_it && defined($line) )

	} ## end foreach my $instance (@instances)

	#
	#
	# put totals together
	#
	#
	foreach my $instance (@instances) {
		my @vars = keys( %{ $to_return->{data}{instances}{$instance} } );
		foreach my $var (@vars) {
			# remove it if is from a array that was missed
			if ( $var =~ /\@\@\@/ ) {
				delete( $to_return->{data}{instances}{$instance}{$var} );
			} else {
				if ( !defined( $to_return->{data}{totals}{$var} ) ) {
					$to_return->{data}{totals}{$var} = $to_return->{data}{instances}{$instance}{$var};
				} else {
					$to_return->{data}{totals}{$var}
						= $to_return->{data}{totals}{$var} + $to_return->{data}{instances}{$instance}{$var};
				}
			}
		} ## end foreach my $var (@vars)
	} ## end foreach my $instance (@instances)

	#
	#
	# process error deltas and and look for alerts
	#
	#
	my @totals     = keys( %{ $to_return->{data}{totals} } );
	my @error_keys = ('file_store__fs_errors');
	foreach my $item (@totals) {
		if ( $item =~ /app_layer__error__[a-zA-Z0-9\-\_]+__gap/ ) {
			push( @error_keys, $item );
		}
	}
	foreach my $item (@error_keys) {
		my $delta = $previous->{data}{totals}{$item} - $to_return->{data}{totals}{$item};
		# if less than zero, then it has been restarted or clicked over
		if ( $delta < 0 ) {
			$delta = $to_return->{data}{totals}{$item};
		}
		$to_return->{data}{totals}{error_delta} = $to_return->{data}{totals}{error_delta} + $delta;
		# this expects to work in 5 minute increments so convert to errors per second
		if ( $delta != 0 ) {
			$to_return->{data}{totals}{error_delta} = $to_return->{data}{totals}{error_delta} + $delta;
		}
		if ( $delta >= $self->{error_delta_crit} ) {
			if ( $to_return->{data}{alert} < 2 ) {
				$to_return->{data}{alert} = 2;
			}
			push( @alerts, 'CRITICAL - ' . $item . ' has a error delta greater than ' . $self->{error_delta_crit} );
		} elsif ( $delta >= $self->{error_delta_warn} ) {
			if ( $to_return->{data}{alert} < 1 ) {
				$to_return->{data}{alert} = 1;
			}
			push( @alerts, 'WARNING - ' . $item . ' has a error delta greater than ' . $self->{error_delta_warn} );
		}
	} ## end foreach my $item (@error_keys)
	# this expects to work in 5 minute increments so convert to errors per second
	if ( $to_return->{data}{totals}{error_delta} != 0 ) {
		$to_return->{data}{totals}{error_delta} = $to_return->{data}{totals}{error_delta} / 300;
	}
	if ( $to_return->{data}{totals}{error_delta} >= $self->{error_delta_crit} ) {
		if ( $to_return->{data}{alert} < 2 ) {
			$to_return->{data}{alert} = 2;
		}
		push( @alerts,
				  'CRITICAL - total error delta, '
				. $to_return->{data}{totals}{error_delta}
				. ', greater than '
				. $self->{error_delta_crit} );
	} elsif ( $to_return->{data}{totals}{error_delta} >= $self->{error_delta_warn} ) {
		if ( $to_return->{data}{alert} < 1 ) {
			$to_return->{data}{alert} = 1;
		}
		push( @alerts,
				  'WARNING - total error delta, '
				. $to_return->{data}{totals}{error_delta}
				. ', greater than '
				. $self->{error_delta_warn} );
	} ## end elsif ( $to_return->{data}{totals}{error_delta...})

	#
	#
	# process drop precent and and look for alerts
	#
	#
	my @drop_keys = ( 'capture__kernel_drops', 'capture__kernel_ifdrops', 'capture__kernel_drops_any' );
	# if this previous greater than or equal, almost certain it rolled over or restarted, so detla is zero
	my $delta = $to_return->{data}{totals}{capture__kernel_packets};
	if ( defined( $previous->{data}{totals}{capture__kernel_packets} ) ) {
		$delta
			= $to_return->{data}{totals}{capture__kernel_packets} - $previous->{data}{totals}{capture__kernel_packets};
	}
	$to_return->{data}{totals}{capture__kernel_drops_any} = 0;
	if (defined($to_return->{data}{totals}{capture__kernel_drops})) {
		$to_return->{data}{totals}{capture__kernel_drops_any} += $to_return->{data}{totals}{capture__kernel_drops};
	}
	if (defined($to_return->{data}{totals}{capture__kernel_ifdrops})) {
		$to_return->{data}{totals}{capture__kernel_drops_any} += $to_return->{data}{totals}{capture__kernel_ifdrops};
	}
	# if delta is 0, then there previous is zero
	foreach my $item (@drop_keys) {
		my $drop_delta = 0;
		if ( $delta > 0 ) {
			if ( defined( $previous->{data}{totals}{$item} ) ) {
				$drop_delta = $to_return->{data}{totals}{$item} - $previous->{data}{totals}{$item};
			} else {
				$drop_delta = $to_return->{data}{totals}{$item};
			}
		} else {
			if (defined($to_return->{data}{totals}{$item})) {
				# delta is zero, it has restarted or rolled over
				$drop_delta = $to_return->{data}{totals}{$item};
			}
		}
		if ( $drop_delta > 0 ) {
			my $drop_percent = $drop_delta / $delta;
			if ( $to_return->{data}{totals}{drop_percent} < $drop_percent ) {
				$to_return->{data}{totals}{drop_percent} = $drop_percent;
			}
			if ( $drop_percent >= $self->{drop_percent_crit} ) {
				if ( $to_return->{data}{alert} < 2 ) {
					$to_return->{data}{alert} = 2;
				}
				push( @alerts,
						  'CRITICAL - '
						. $item
						. ' for totals has a drop percent greater than '
						. $self->{drop_percent_crit} );
			} elsif ( $drop_percent >= $self->{drop_percent_warn} ) {
				if ( $to_return->{data}{alert} < 1 ) {
					$to_return->{data}{alert} = 1;
				}
				push( @alerts,
						  'WARNING - '
						. $item
						. ' for totals has a drop percent greater than '
						. $self->{drop_percent_warn} );
			} ## end elsif ( $drop_percent >= $self->{drop_percent_warn...})
		} ## end if ( $drop_delta > 0 )
	} ## end foreach my $item (@drop_keys)

	#
	#
	# create the error string
	#
	#
	$to_return->{alertString} = join( "\n", @alerts );

	#
	#
	# write the cache file on out
	#
	#
	eval {
		my $new_cache = encode_json($to_return);
		write_file( $previous_file, $new_cache );

		my $compressed_string;
		gzip \$new_cache => \$compressed_string;
		my $compressed = encode_base64($compressed_string);
		$compressed =~ s/\n//g;
		$compressed = $compressed . "\n";

		if ( length($compressed) > length($new_cache) ) {
			write_file( $self->{cache_dir} . '/snmp', $new_cache );
		} else {
			write_file( $self->{cache_dir} . '/snmp', $compressed );
		}
	};
	if ($@) {
		$to_return->{error}       = '1';
		$to_return->{data}{alert} = '3';
		$to_return->{errorString} = 'Failed to write new cache JSON and SNMP return files.... ' . $@;

		# set the nagious style alert stuff
		$to_return->{alert} = '3';
		if ( $to_return->{data}{alertString} eq '' ) {
			$to_return->{data}{alertString} = $to_return->{errorString};
		} else {
			$to_return->{data}{alertString} = $to_return->{errorString} . "\n" . $to_return->{alertString};
		}
	} ## end if ($@)

	$self->{results} = $to_return;

	return $to_return;
} ## end sub run

=head2 print_output

Prints the output.

    $sm->print_output;

=cut

sub print_output {
	my $self = $_[0];

	if ( $self->{mode} eq 'nagios' ) {
		if ( $self->{results}{alert} eq '0' ) {
			print "OK - no alerts\n";
			return;
		} elsif ( $self->{results}{alert} eq '1' ) {
			print 'WARNING - ';
		} elsif ( $self->{results}{alert} eq '2' ) {
			print 'CRITICAL - ';
		} elsif ( $self->{results}{alert} eq '3' ) {
			print 'UNKNOWN - ';
		}
		my $alerts = $self->{results}{alertString};
		chomp($alerts);
		$alerts = s/\n/\, /g;
		print $alerts. "\n";
	} else {
		print encode_json( $self->{results} ) . "\n";
	}
} ## end sub print_output

=head1 LibreNMS HASH

    + $hash{'alert'} :: Alert status.
      - 0 :: OK
      - 1 :: WARNING
      - 2 :: CRITICAL
      - 3 :: UNKNOWN

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-suricata-monitoring at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Suricata-Monitoring>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Suricata::Monitoring


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Suricata-Monitoring>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Suricata-Monitoring>

=item * Search CPAN

L<https://metacpan.org/release/Suricata-Monitoring>

=back


=head * Git

L<git@github.com:VVelox/Suricata-Monitoring.git>

=item * Web

L<https://github.com/VVelox/Suricata-Monitoring>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Suricata::Monitoring
