package Sagan::Monitoring;

use 5.006;
use strict;
use warnings;
use JSON;
use File::Path qw(make_path);
use File::ReadBackwards;
use Carp;
use File::Slurp;
use Time::Piece;

=head1 NAME

Sagan::Monitoring - LibreNMS JSON SNMP extend and Nagios style check for Sagan stats

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Sagan::Monitoring;

    my $args = {
        mode               => 'librenms',
        drop_percent_warn  => .75;
        drop_percent_crit  => 1,
        files=>{
               'ids'=>'/var/log/sagan/alert-ids.json',
               'foo'=>'/var/log/sagan/alert-foo.json',
               },
    };

    my $sm=Sagan::Monitoring->new( $args );
    my $returned=$sm->run;
    $sm->print;
    exit $returned->{alert};

=head1 METHODS

=head2 new

Initiate the object.

The args are taken as a hash ref. The keys are documented as below.

The only must have is 'files'.

This assumes that stats-json.subtract_old_values is set to 'true'
for Suricata.

    - drop_percent_warn :: Drop percent warning threshold.
      - Default :: .75;
	
    - drop_percent_crit :: Drop percent critical threshold.
      - Default :: 1
	
    - files :: A hash with the keys being the instance name and the values
      being the Eve files to read. ".total" is not a valid instance name.
      Similarly anything starting with a "." should be considred reserved.

    my $args = {
        drop_percent_warn  => .75;
        drop_percent_crit  => 1,
        mode               => 'librenms',
        files=>{
               'ids'=>'/var/log/sagan/stats-ids.json',
               'foo'=>'/var/log/sagan/stats-foo.json',
               },
    };

    my $sm=Sagan::Monitoring->new( $args );

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ) {
		%args = %{ $_[1] };
	}

	# init the object
	my $self = {
		'drop_percent_warn' => '.75',
		'drop_percent_crit' => '1',
		max_age             => 360,
		mode                => 'librenms',
		cache               => '/var/cache/sagan_monitoring.json',
	};
	bless $self;

	# reel in the threshold values
	my @thresholds = ( 'drop_percent_warn', 'drop_percent_crit' );
	for my $threshold (@thresholds) {
		if ( defined( $args{$threshold} ) ) {
			$self->{$threshold} = $args{$threshold};
			if ( $args{$threshold} !~ /[0-9\.]+/ ) {
				confess( '"' . $threshold . '" with a value of "' . $args{$threshold} . '" is not numeric' );
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
	}
	elsif ( defined( $args{mode} ) ) {
		$self->{mode} = $args{mode};
	}

	# make sure we have files specified
	if (   ( !defined( $args{files} ) )
		|| ( !defined( keys( %{ $args{files} } ) ) ) )
	{
		confess('No files specified');
	}
	else {
		$self->{files} = $args{files};
	}

	if ( defined( $self->{files}{'.total'} ) ) {
		confess('".total" is not a valid instance name');
	}

	return $self;
}

=head2 run

This runs it and collects the data. Also updates the cache.

This will return a LibreNMS style hash.

    my $returned=$sm->run;

=cut

sub run {
	my $self = $_[0];

	# this will be returned
	my $to_return = {
		data        => { '.total' => {} },
		version     => 1,
		error       => '0',
		errorString => '',
		alert       => '0',
		alertString => ''
	};

	# figure out the time slot we care about
	my $from = time;
	my $till = $from - $self->{max_age};

	# process the files for each instance
	my @instances = keys( %{ $self->{files} } );
	my @alerts;
	my $current_till;
	foreach my $instance (@instances) {

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

				# if current till is not set, set it
				if (  !defined($current_till)
					&& defined($timestamp)
					&& $timestamp =~ /^[0-9]+\-[0-9]+\-[0-9]+T[0-9]+\:[0-9]+\:[0-9\.]+[\-\+][0-9]+/ )
				{

					# get the number of hours
					my $hours = $timestamp;
					$hours =~ s/.*[\-\+]//g;
					$hours =~ s/^0//;
					$hours =~ s/[0-9][0-9]$//;

					# get the number of minutes
					my $minutes = $timestamp;
					$minutes =~ s/.*[\-\+]//g;
					$minutes =~ s/^[0-9][0-9]//;

					my $second_diff = ( $minutes * 60 ) + ( $hours * 60 * 60 );

					if ( $timestamp =~ /\+/ ) {
						$current_till = $till + $second_diff;
					}
					else {
						$current_till = $till - $second_diff;
					}
				}
				$timestamp =~ s/\..*$//;
				my $t = Time::Piece->strptime( $timestamp, '%Y-%m-%dT%H:%M:%S' );

				# stop process further lines as we've hit the oldest we care about
				if ( $t->epoch <= $current_till ) {
					$process_it = 0;
				}

				# we found the entry we are looking for if
				# this matches, so process it
				if ( defined( $json->{event_type} )
					&& $json->{event_type} eq 'stats' )
				{
					# we can stop processing now as this is what we were looking for
					$process_it = 0;

					# holds the found new alerts
					my @new_alerts;

					my $new_stats = {
						uptime              => $json->{stats}{uptime},
						total_delta         => $json->{stats}{captured}{total},
						drop_delta          => $json->{stats}{captured}{drop},
						ignore_delta        => $json->{stats}{captured}{ignore},
						threshold_delta     => $json->{stats}{captured}{threshold},
						after_delta         => $json->{stats}{captured}{after},
						match_delta         => $json->{stats}{captured}{match},
						bytes_delta         => $json->{stats}{captured}{bytes_total},
						bytes_ignored_delta => $json->{stats}{captured}{bytes_ignored},
						max_bytes_log_line  => $json->{stats}{captured}{max_bytes_log_line},
						eps                 => $json->{stats}{captured}{eps},
						f_total_delta       => $json->{stats}{flow}{total},
						f_dropped_delta     => $json->{stats}{flow}{dropped},
						alert               => 0,
						alertString         => '',
					};

					# find the drop percentages
					if ( $new_stats->{total_delta} != 0 ) {
						$new_stats->{drop_percent} = ( $new_stats->{drop_delta} / $new_stats->{total_delta} ) * 100;
						$new_stats->{drop_percent} = sprintf( '%0.5f', $new_stats->{drop_percent} );
					}
					else {
						$new_stats->{total_percent} = 0;
					}
					if ( $new_stats->{f_total_delta} != 0 ) {
						$new_stats->{f_drop_percent}
							= ( $new_stats->{f_dropped_delta} / $new_stats->{f_total_delta} ) * 100;
						$new_stats->{f_drop_percent} = sprintf( '%0.5f', $new_stats->{f_drop_percent} );
					}
					else {
						$new_stats->{f_drop_percent} = 0;
					}

					# check for drop percent alerts
					if (   $new_stats->{drop_percent} >= $self->{drop_percent_warn}
						&& $new_stats->{drop_percent} < $self->{drop_percent_crit} )
					{
						$new_stats->{alert} = 1;
						push( @new_alerts,
								  $instance
								. ' drop_percent warning '
								. $new_stats->{drop_percent} . ' >= '
								. $self->{drop_percent_warn} );
					}
					if ( $new_stats->{drop_percent} >= $self->{drop_percent_crit} ) {
						$new_stats->{alert} = 2;
						push( @new_alerts,
								  $instance
								. ' drop_percent critical '
								. $new_stats->{drop_percent} . ' >= '
								. $self->{drop_percent_crit} );
					}

					# check for f_drop percent alerts
					if (   $new_stats->{f_drop_percent} >= $self->{drop_percent_warn}
						&& $new_stats->{f_drop_percent} < $self->{drop_percent_crit} )
					{
						$new_stats->{alert} = 1;
						push( @new_alerts,
								  $instance
								. ' f_drop_percent warning '
								. $new_stats->{f_drop_percent} . ' >= '
								. $self->{drop_percent_warn} );
					}
					if ( $new_stats->{f_drop_percent} >= $self->{drop_percent_crit} ) {
						$new_stats->{alert} = 2;
						push( @new_alerts,
								  $instance
								. ' f_drop_percent critical '
								. $new_stats->{f_drop_percent} . ' >= '
								. $self->{drop_percent_crit} );
					}

					# add stuff to .total
					my @intance_keys = keys( %{$new_stats} );
					foreach my $total_key (@intance_keys) {
						if ( $total_key ne 'alertString' && $total_key ne 'alert' ) {
							if ( !defined( $to_return->{data}{'.total'}{$total_key} ) ) {
								$to_return->{data}{'.total'}{$total_key} = $new_stats->{$total_key};
							}
							else {
								$to_return->{data}{'.total'}{$total_key}
									= $to_return->{data}{'.total'}{$total_key} + $new_stats->{$total_key};
							}
						}
					}

					$to_return->{data}{$instance} = $new_stats;
				}

			};

			# get the next line
			$line = $bw->readline;
		}

	}

	# find the drop percentages
	if ( $to_return->{data}{'.total'}{total_delta} != 0 ) {
		$to_return->{data}{'.total'}{drop_percent}
			= ( $to_return->{data}{'.total'}{drop_delta} / $to_return->{data}{'.total'}{total_delta} ) * 100;
		$to_return->{data}{'.total'}{drop_percent} = sprintf( '%0.5f', $to_return->{data}{'.total'}{drop_percent} );
	}
	else {
		$to_return->{data}{'.total'}{drop_percent} = 0;
	}
	if ( $to_return->{data}{'.total'}{f_dropped_delta} != 0 ) {
		$to_return->{data}{'.total'}{f_drop_percent}
			= ( $to_return->{data}{'.total'}{f_dropped_delta} / $to_return->{data}{'.total'}{f_total_delta} ) * 100;
		$to_return->{data}{'.total'}{f_drop_percent} = sprintf( '%0.5f', $to_return->{data}{'.total'}{f_drop_percent} );
	}
	else {
		$to_return->{data}{'.total'}{f_drop_percent} = 0;
	}

	# check for drop percent alerts
	if (   $to_return->{data}{'.total'}{drop_percent} >= $self->{drop_percent_warn}
		&& $to_return->{data}{'.total'}{drop_percent} < $self->{drop_percent_crit} )
	{
		$to_return->{alert} = 1;
		push( @alerts,
				  'total drop_percent warning '
				. $to_return->{data}{'.total'}{drop_percent} . ' >= '
				. $self->{drop_percent_warn} );
	}
	if ( $to_return->{data}{'.total'}{drop_percent} >= $self->{drop_percent_crit} ) {
		$to_return->{alert} = 2;
		push( @alerts,
				  'total drop_percent critical '
				. $to_return->{data}{'.total'}{drop_percent} . ' >= '
				. $self->{drop_percent_crit} );
	}

	# check for f_drop percent alerts
	if (   $to_return->{data}{'.total'}{f_drop_percent} >= $self->{drop_percent_warn}
		&& $to_return->{data}{'.total'}{f_drop_percent} < $self->{drop_percent_crit} )
	{
		$to_return->{alert} = 1;
		push( @alerts,
				  'total f_drop_percent warning '
				. $to_return->{data}{'.total'}{f_drop_percent} . ' >= '
				. $self->{drop_percent_warn} );
	}
	if ( $to_return->{data}{'.total'}{f_drop_percent} >= $self->{drop_percent_crit} ) {
		$to_return->{alert} = 2;
		push( @alerts,
				  'total f_drop_percent critical '
				. $to_return->{data}{'.total'}{f_drop_percent} . ' >= '
				. $self->{drop_percent_crit} );
	}

	# join any found alerts into the string
	$to_return->{alertString} = join( "\n", @alerts );
	$to_return->{data}{'.total'}{alert} = $to_return->{'alert'};

	# write the cache file on out
	eval {
		my $json      = JSON->new->utf8->canonical(1);
		my $new_cache = $json->encode($to_return) . "\n";
		open( my $fh, '>', $self->{cache} );
		print $fh $new_cache;
		close($fh);
	};
	if ($@) {
		$to_return->{error}       = '1';
		$to_return->{alert}       = '3';
		$to_return->{errorString} = 'Failed to write new cache JSON file, "' . $self->{cache} . '".... ' . $@;

		# set the nagious style alert stuff
		$to_return->{alert} = '3';
		if ( $to_return->{alertString} eq '' ) {
			$to_return->{alertString} = $to_return->{errorString};
		}
		else {
			$to_return->{alertString} = $to_return->{errorString} . "\n" . $to_return->{alertString};
		}
	}

	$self->{results} = $to_return;

	return $to_return;
}

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
		}
		elsif ( $self->{results}{alert} eq '1' ) {
			print 'WARNING - ';
		}
		elsif ( $self->{results}{alert} eq '2' ) {
			print 'CRITICAL - ';
		}
		elsif ( $self->{results}{alert} eq '3' ) {
			print 'UNKNOWN - ';
		}
		my $alerts = $self->{results}{alertString};
		chomp($alerts);
		$alerts = s/\n/\, /g;
		print $alerts. "\n";
	}
	else {
		my $json = JSON->new->utf8->canonical(1);
		print $json->encode( $self->{results} ) . "\n";
	}
}

=head1 LibreNMS HASH

    + $hash{'alert'} :: Alert status.
      - 0 :: OK
      - 1 :: WARNING
      - 2 :: CRITICAL
      - 3 :: UNKNOWN
    
    + $hash{'alertString'} :: A string describing the alert. Defaults to
      '' if there is no alert.
    
    + $hash{'error'} :: A integer representing a error. '0' represents
      everything is fine.
    
    + $hash{'errorString'} :: A string description of the error.
    
    + $hash{'data'}{$instance} :: Values migrated from the
      instance. *_delta values are created via computing the difference
      from the previously saved info. *_percent is based off of the delta
      in question over the packet delta. Delta are created for packet,
      drop, ifdrop, and error. Percents are made for drop, ifdrop, and
      error.
    
    + $hash{'data'}{'.total'} :: Total values of from all the
      intances. Any percents will be recomputed.
    

    The stat keys are migrated as below.
    
    uptime              => $json->{stats}{uptime},
    total_delta         => $json->{stats}{captured}{total},
    drop_delta          => $json->{stats}{captured}{drop},
    ignore_delta        => $json->{stats}{captured}{ignore},
    threshold_delta     => $json->{stats}{captured}{theshold},
    after_delta         => $json->{stats}{captured}{after},
    match_delta         => $json->{stats}{captured}{match},
    bytes_delta         => $json->{stats}{captured}{bytes_total},
    bytes_ignored_delta => $json->{stats}{captured}{bytes_ignored},
    max_bytes_log_line  => $json->{stats}{captured}{max_bytes_log_line},
    eps                 => $json->{stats}{captured}{eps},
    f_total_delta       => $json->{stats}{flow}{total},
    f_dropped_delta     => $json->{stats}{flow}{dropped},

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sagan-monitoring at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sagan-Monitoring>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sagan::Monitoring


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sagan-Monitoring>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sagan-Monitoring>

=item * Search CPAN

L<https://metacpan.org/release/Sagan-Monitoring>

=back

=head * Git

L<git@github.com:VVelox/Sagan-Monitoring.git>

=item * Web

L<https://github.com/VVelox/Sagan-Monitoring>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Sagan::Monitoring
