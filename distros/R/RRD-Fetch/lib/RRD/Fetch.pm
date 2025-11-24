package RRD::Fetch;
use base 'Error::Helper';

use 5.006;
use strict;
use warnings;
use String::ShellQuote qw(shell_quote);
use Time::Piece        ();
use Statistics::Lite   qw(max mean median min mode sum);

=head1 NAME

RRD::Fetch - Fetch information from a RRD file.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use RRD::Fetch;

    my $rrd_fetch=RRD::Fetch->new(rrd_file=>'foo.rrd');


=head1 SUBROUTINES/METHODS

=head2 new

Initiates the object.

The required args are as below.

    - rrd_file :: The RRD file to operate on. It needs to exist at the time it is called.
        Default :: undef

The following are optional.

    - CF :: The RRD CF type to use.
        Default :: AVERAGE
        Values :: AVERAGE, MIN, MAX, LAST

    - resolution :: Interval you want the values to have. Note, this does not support the optional
            suffixes as of currently.
        Default :: undef
        Type :: int

    - backoff :: How many seconds to wait for to try again if it has a non-zero exit.
        Default :: 1
        Type :: int

    - retries :: Number of times to retry if there is a non-zero exit. Set to 0 to disable.
        Default :: 3
        Type :: int

    - align :: Call with --align-start.
        Default :: 1
        Type :: bool

=cut

sub new {
	my ( $empty, %opts ) = @_;

	my $self = {
		CF              => 'AVERAGE',
		retries         => 3,
		backoff         => 1,
		rrd_file        => undef,
		quoted_rrd_file => undef,
		resolution      => undef,
		align           => 1,
		perror          => undef,
		error           => undef,
		errorLine       => undef,
		errorFilename   => undef,
		errorString     => "",
		errorExtra      => {
			all_errors_fatal => 0,
			flags            => {
				1  => 'not_a_file',
				2  => 'rrd_file_undef',
				3  => 'fetch_retries_exceeded',
				4  => 'wrong_ref_type',
				5  => 'not_a_int',
				6  => 'less_than_1',
				7  => 'CF_bad',
				8  => 'start_undef',
				9  => 'end_undef',
				10 => 'bad_by_opt',
				11 => 'no_columns',
				12 => 'start_wrong_format',
				13 => 'start_failed_parsing',
				14 => 'fetching_a_day_failed',
			},
			fatal_flags => {
				'not_a_file'            => 1,
				'rrd_file_undef'        => 1,
				'wrong_ref_type'        => 1,
				'not_a_int'             => 1,
				'less_than_1'           => 1,
				'CF_bad'                => 1,
				'start_undef'           => 1,
				'end_undef'             => 1,
				'bad_by_opt'            => 1,
				'no_columns'            => 1,
				'start_wrong_format'    => 1,
				'start_failed_parsing'  => 1,
				'fetching_a_day_failed' => 1,
			},
			perror_not_fatal => 0,
		},
	};
	bless $self;

	if ( !defined( $opts{rrd_file} ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 1;
		$self->{errorString} = '$opts{rrd_file} is undef';
		$self->warn;
		return $self;
	}

	if ( ref( $opts{rrd_file} ) ne '' ) {
		$self->{perror}      = 1;
		$self->{error}       = 4;
		$self->{errorString} = '$opts{rrd_file} is of ref type "' . ref( $opts{rrd_file} ) . '" and not ""';
		$self->warn;
		return $self;
	}

	if ( !-f $opts{rrd_file} ) {
		$self->{perror}      = 1;
		$self->{error}       = 2;
		$self->{errorString} = '"' . $opts{rrd_file} . '" is not a file';
		$self->warn;
		return $self;
	}

	$self->{rrd_file}        = $opts{rrd_file};
	$self->{quoted_rrd_file} = shell_quote( $opts{rrd_file} );

	if ( defined( $opts{CF} ) ) {
		if ( ref( $opts{CF} ) ne '' ) {
			$self->{perror}      = 1;
			$self->{error}       = 4;
			$self->{errorString} = '$opts{CF} is of ref type "' . ref( $opts{CF} ) . '" and not ""';
			$self->warn;
			return $self;
		} elsif ( $opts{CF} ne 'AVERAGE'
			&& $opts{CF} ne 'MIN'
			&& $opts{CF} ne 'MAX'
			&& $opts{CF} ne 'LAST' )
		{
			$self->{perror}      = 1;
			$self->{error}       = 7;
			$self->{errorString} = '$opts{CF} is set to "' . $opts{CF} . '" and not "AVERAGE", "MIN", "MAX", or "LAST"';
			$self->warn;
			return $self;
		} ## end elsif ( $opts{CF} ne 'AVERAGE' && $opts{CF} ne...)
		$self->{CF} = $opts{CF};
	} ## end if ( defined( $opts{CF} ) )

	my @int_read = ( 'resolution', 'backoff', 'retries', 'align' );
	foreach my $int_to_read_in (@int_read) {
		if ( defined( $opts{$int_to_read_in} ) ) {
			if ( ref( $opts{$int_to_read_in} ) ne '' ) {
				$self->{perror} = 1;
				$self->{error}  = 4;
				$self->{errorString}
					= '$opts{'
					. $int_to_read_in
					. '} is of ref type "'
					. ref( $opts{$int_to_read_in} )
					. '" and not ""';
				$self->warn;
				return $self;
			} elsif ( $opts{$int_to_read_in} !~ /[0-9]+/ ) {
				$self->{perror}      = 1;
				$self->{error}       = 5;
				$self->{errorString} = '$opts{' . $int_to_read_in . '} is defined and does not appear to be a integer';
				$self->warn;
				return $self;
			} elsif ( ( $int_to_read_in ne 'retries' && $int_to_read_in ne 'align' ) && $opts{$int_to_read_in} <= 0 ) {
				# retries may be less than one to disable it
				$self->{perror} = 1;
				$self->{error}  = 6;
				$self->{errorString}
					= '$opts{' . $int_to_read_in . '} is set to ' . $opts{$int_to_read_in} . ' which is less than 1';
				$self->warn;
				return $self;
			}

			$self->{$int_to_read_in} = $opts{$int_to_read_in};
		} ## end if ( defined( $opts{$int_to_read_in} ) )
	} ## end foreach my $int_to_read_in (@int_read)

	return $self;
} ## end sub new

=head2 fetch_raw

Fetches the specified information.

The required args are as below. Be aware as of currently start/end are not validated.

    - start :: Value for passing via the --start flag.
        Default :: undef

    - end :: Value for passing via the --start flag.
        Default :: undef

Be aware exceeding the number of retries is not a fatal error. It will issue a
warning.

    my $results = $rrd_fetch->fetch_raw(start=>'20240503', end=>'start+1d');
    if ($results->{success}) {
        print $results->{output};
    } else {
        die("Number of retries exceeded... last output was...\n".$results->{output});
    }

The returned data is hash ref.

    - .output :: The results of the fetch command.

    - .success :: 0/1 for if it succeded or not.

    - .retries :: The number of retries. 0 if success on the first attempt.

=cut

sub fetch_raw {
	my ( $self, %opts ) = @_;

	if ( !$self->errorblank ) {
		return undef;
	}

	if ( !defined( $opts{start} ) ) {
		$self->{error}       = 8;
		$self->{errorString} = '$opts{start} is undef';
		$self->warn;
	} elsif ( ref( $opts{start} ) ne '' ) {
		$self->{error}       = 4;
		$self->{errorString} = '$opts{start} is of ref type "' . ref( $opts{start} ) . '" and not ""';
		$self->warn;
	}

	if ( !defined( $opts{end} ) ) {
		$self->{error}       = 9;
		$self->{errorString} = '$opts{end} is undef';
		$self->warn;
	} elsif ( ref( $opts{end} ) ne '' ) {
		$self->{error}       = 4;
		$self->{errorString} = '$opts{end} is of ref type "' . ref( $opts{end} ) . '" and not ""';
		$self->warn;
	}

	$opts{start} = shell_quote( $opts{start} );
	$opts{end}   = shell_quote( $opts{end} );

	my $to_return = {
		retries => 0,
		success => 0,
		output  => '',
	};

	my $resolution_opts = '';
	if ( defined( $self->{resolution} ) ) {
		$resolution_opts = '--resolution ' . $self->{resolution};
	}

	my $align = '';
	if ( $self->{'align'} ) {
		$align = '--align-start';
	}

	$to_return->{output}
		= `rrdtool fetch $self->{quoted_rrd_file} $self->{CF} $resolution_opts --start $opts{start} --end $opts{end} $align`;
	if ( $? != 0 ) {
		$to_return->{retries}++;
		my $loop = 1;
		while ( $to_return->{retries} <= $self->{retries} && $loop ) {
			$to_return->{output}
				= `rrdtool fetch $self->{quoted_rrd_file} $self->{CF} $resolution_opts --start $opts{start} --end $opts{end} $align`;
			if ( $? != 0 ) {
				$to_return->{retries}++;
			} else {
				$loop = 0;
			}
		}

		if ( $to_return->{retries} > $self->{retries} ) {
			$self->{error} = 3;
			$self->{errorString}
				= 'The following command exited non-zero more than the allowed number of retires, '
				. $self->{retries}
				. ', "rrdtool fetch '
				. $self->{quoted_rrd_file} . ' '
				. $self->{CF} . ' '
				. $resolution_opts
				. ' --start '
				. $opts{start}
				. ' --end '
				. $opts{end} . '" '
				. $align;
			$self->warn;
			return $to_return;
		} ## end if ( $to_return->{retries} > $self->{retries...})
	} ## end if ( $? != 0 )

	$to_return->{success} = 1;

	return $to_return;
} ## end sub fetch_raw

=head2 fetch_joined

Fetches the specified information.

The required args are as below. Be aware as of currently start/end are not validated.

    - start :: Value for passing via the --start flag.
        Default :: undef

    - end :: Value for passing via the --start flag.
        Default :: undef

The optional args are as below.

    - by :: What to join by.
            time - Join by the time value
            column - join by the column name

        Default :: column

Be aware exceeding the number of retries is not a fatal error. It will issue a
warning.

    my $results = $rrd_fetch->fetch_raw(start=>'20240503', end=>'start+1d');

The return is is a hash ref for column by is as below.

    - .output :: The results of the fetch command.

    - .success :: 0/1 for if it succeded or not.

    - .retries :: The number of retries. 0 if success on the first attempt.

    - .columns[] :: A array of the columns.

    - .data :: A hash ref that holds the columns.

    - .data.$column[] :: A array for a specific column that holds values at that time.
        The time can for a specific value can be looked up via checking it's array location
        in the array .rows[]. So lets say we a column named foo and we want the time for value
        3, $results->{data}{foo}[3], we would check .rows[3], $results->{rows}[3].

    - .rows[] :: A array of time stamps. 

The return is is a hash ref for column by is as below.

    - .output :: The results of the fetch command.

    - .success :: 0/1 for if it succeded or not.

    - .retries :: The number of retries. 0 if success on the first attempt.

    - .columns[] :: A array of the columns.

    - .data :: A hash ref that holds the rows

    - .data.$time :: A hash that holds a hash of the columns for that point in time.

    - .data.$time.$column :: A value for a column at a specific point in time.

    - .rows[] :: A array of time stamps.

=cut

sub fetch_joined {
	my ( $self, %opts ) = @_;

	if ( !$self->errorblank ) {
		return undef;
	}

	if ( !defined( $opts{by} ) ) {
		$opts{by} = 'column';
	} else {
		if ( $opts{by} ne 'column' && $opts{by} ne 'time' ) {
			$self->{error}       = 10;
			$self->{errorString} = '$opts{by} should either be colmn or time';
			$self->warn;
		}
	}

	my $results = $self->fetch_raw(%opts);
	if ( !$results->{success} ) {
		return $results;
	}

	$results->{success} = 0;

	my @output_split = split( /\n/, $results->{output} );
	$output_split[0] =~ s/^[\t\ ]+//;
	my @columns = split( /[\t\ ]+/, $output_split[0] );
	$results->{columns} = \@columns;

	# if this is blank, we did not get any thing useful... we should have
	if ( $output_split[0] eq '' ) {
		$self->{error} = 11;
		$self->{errorString}
			= '$output_split[0] is "" meaning there was some sort of parsing error or error retrieving the data';
		$self->warn;
	}

	# start at 2 as 0=args and 1=blank
	my $line = 2;
	$results->{data} = {};
	if ( $opts{by} eq 'column' ) {
		$results->{rows} = [];
		foreach my $column (@columns) {
			$results->{data}{$column} = [];
		}
		while ( defined( $output_split[$line] ) ) {
			my @line_split = split( /\:*[\t\ ]+/, $output_split[$line] );
			if ( defined( $line_split[0] ) && defined( $line_split[1] ) ) {
				my $my_read = 1;
				push( @{ $results->{rows} }, $line_split[0] );
				foreach my $column (@columns) {
					if ( defined( $line_split[$my_read] ) ) {
						push( @{ $results->{data}{$column} }, $line_split[$my_read] );
					} else {
						$results->{data}{$column} = undef;
					}
					$my_read++;
				}
			} ## end if ( defined( $line_split[0] ) && defined(...))
			$line++;
		} ## end while ( defined( $output_split[$line] ) )
	} elsif ( $opts{by} eq 'time' ) {
		$results->{rows} = [];
		while ( defined( $output_split[$line] ) ) {
			my @line_split = split( /[\t\ ]+/, $output_split[$line] );
			if ( defined( $line_split[0] ) && defined( $line_split[1] ) ) {
				my $my_read = 1;
				push( @{ $results->{rows} }, $line_split[0] );
				$results->{data}{ $line_split[0] } = {};
				foreach my $column (@columns) {
					if ( defined( $line_split[$my_read] ) ) {
						$results->{data}{ $line_split[0] }{$column} = $line_split[$my_read];
					} else {
						$results->{data}{ $line_split[0] }{$column} = undef;
					}
					$my_read++;
				}
				$line++;
			} ## end if ( defined( $line_split[0] ) && defined(...))
		} ## end while ( defined( $output_split[$line] ) )
	} ## end elsif ( $opts{by} eq 'time' )

	$results->{success} = 1;

	return $results;
} ## end sub fetch_joined

=head1 daily_max

Gets daily max info.

Requires a start time and end time in 

    - start :: Start time in %Y%m%d
        Default :: undef

    - for :: Number of days to get info on.
        Default :: 7

The return is is a hash ref for column by is as below.

    - .columns[] :: A array of the columns.

    - .dates[] :: A array of dates.

    . .max.$date.$column :: The max info for a specific column on that date.

=cut

sub daily_stats {
	my ( $self, %opts ) = @_;

	if ( !$self->errorblank ) {
		return undef;
	}

	if ( !defined( $opts{start} ) ) {
		$self->{error}       = 8;
		$self->{errorString} = '$opts{start} is undef';
		$self->warn;
	} elsif ( ref( $opts{start} ) ne '' ) {
		$self->{error}       = 4;
		$self->{errorString} = '$opts{start} is of ref type "' . ref( $opts{start} ) . '" and not ""';
		$self->warn;
	} elsif ( $opts{start} !~ /\d\d\d\d[01]\d[0123]\d/ ) {
		$self->{error} = 12;
		$self->{errorString}
			= '$opts{start} set to "'
			. $opts{start}
			. '" which does not appear to be %Y%m%d or /\d\d\d\d[01]\d[0123]\d/';
		$self->warn;
	}

	if ( !defined( $opts{for} ) ) {
		$opts{for} = 7;
	} elsif ( ref( $opts{for} ) ne '' ) {
		$self->{error}       = 4;
		$self->{errorString} = '$opts{for} is of ref type "' . ref( $opts{for} ) . '" and not ""';
		$self->warn;
	} elsif ( $opts{for} !~ /\d+/ ) {
		$self->{error}       = 5;
		$self->{errorString} = '$opts{for}, "' . $opts{for} . '", does not appear to be a int';
		$self->warn;
	}

	my $t;
	eval {
		$t = Time::Piece->strptime( $opts{start}, '%Y%m%d' );
		if ( !defined($t) ) {
			die('Time::Piece->strptime returned undef');
		}
	};
	if ($@) {
		$self->{error}       = 13;
		$self->{errorString} = '$opts{start}, "' . $opts{start} . '", failed parsing... ' . $@;
		$self->warn;
	}

	my $to_return = {
		'columns' => [],
		'dates'   => [],
		'max'     => {},
	};

	my $day = 1;
	while ( $day <= $opts{for} ) {
		my $current_day = $t->strftime('%Y%m%d');
		push( @{ $to_return->{'dates'} }, $current_day );

		my $day_results = $self->fetch_joined( 'start' => $current_day, 'end' => 'start+1day' );

		if ( !$day_results->{'success'} ) {
			$self->{error} = 14;
			$self->{errorString}
				= '$day_results->{success} is false... called "$self->(start=>"'
				. $current_day
				. '", end=>\'+1day\');"...';
			$self->warn;
		}

		if ( $day == 1 ) {
			$to_return->{'columns'} = $day_results->{'columns'};
		}

		$to_return->{'max'}{$current_day}    = {};
		$to_return->{'min'}{$current_day}    = {};
		$to_return->{'mean'}{$current_day}   = {};
		$to_return->{'mode'}{$current_day}   = {};
		$to_return->{'median'}{$current_day} = {};
		$to_return->{'sum'}{$current_day}    = {};
		foreach my $column ( @{ $to_return->{'columns'} } ) {
			my @values;
			foreach my $current_value ( @{ $day_results->{'data'}{$column} } ) {
				if ( defined($current_value) && $current_value !~ /[Nn][Aa][Nn]/ ) {
					push( @values, $current_value );
				}
			}
			$to_return->{'max'}{$current_day}{$column}    = sprintf( '%.12f', max(@values) );
			$to_return->{'min'}{$current_day}{$column}    = sprintf( '%.12f', min(@values) );
			$to_return->{'sum'}{$current_day}{$column}    = sprintf( '%.12f', sum(@values) );
			$to_return->{'mean'}{$current_day}{$column}   = sprintf( '%.12f', mean(@values) );
			$to_return->{'mode'}{$current_day}{$column}   = sprintf( '%.12f', mode(@values) );
			$to_return->{'median'}{$current_day}{$column} = sprintf( '%.12f', median(@values) );
		} ## end foreach my $column ( @{ $to_return->{'columns'}...})

		$t += 86400;
		$day++;
	} ## end while ( $day <= $opts{for} )

	return $to_return;
} ## end sub daily_stats

=head2

=head1 ERROR CODES/FLAGS

=head2 1/not_a_file

The specified file is not a file.

=head2 2/rrd_file_undef

The value given for rrd_file is undef.

=head2 3/fetch_retries_exceeded

rrdtool exited zero and number of retries has been exceeded.

=head2 4/wrong_ref_type

The specified variable is of the wrong ref type.

=head2 5/not_a_int

Value is not a int.

=head2 6/less_than_1

The number is less than1.

=head2 7/CF_bad

The value of CF is not set to one of the following.

    AVERAGE
    MIN
    MAX
    LAST

=head2 8/start_undef

start is undef.

=head2 9/end_undef

end is undef.

=head2 10/bad_by_opt

The value for $opts{by} is not recognized. See the docs for fetch_joined.

=head2 11/no_columns

Unable to retrieve any columns info. Parsing failed for some reason, likely due to bad data.

=head2 12/start_wrong_format

The value for start is not in the format %Y%m%d.

=head2 13/start_failed_parsing

The value passed for start could not be parsed via Time::Piece. Expected for mat is %Y%m%d.

=head2 14/fetching_a_day_failed

Failed to fetch information for a a day.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rrd-fetch at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=RRD-Fetch>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc RRD::Fetch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=RRD-Fetch>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/RRD-Fetch>

=item * Search CPAN

L<https://metacpan.org/release/RRD-Fetch>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991


=cut

1;    # End of RRD::Fetch
