package Monitoring::Sneck;

use 5.006;
use strict;
use warnings;
use File::Slurp   qw(read_file);
use Sys::Hostname qw(hostname);
use IPC::Open3    qw(open3);
use Symbol        qw(gensym);
use IO::Select;
use Time::HiRes qw(time);

=head1 NAME

Monitoring::Sneck - a boopable LibreNMS JSON style SNMP extend for remotely running nagios style checks

=head1 VERSION

Version 1.2.0

=cut

our $VERSION = '1.2.0';

=head1 SYNOPSIS

    use Monitoring::Sneck;

    my $file='/usr/local/etc/sneck.conf';

    my $sneck=Monitoring::Sneck->new({config=>$file});

=head1 USAGE

Not really meant to be used as a library. The library is more of
to support the script.

=head1 CONFIG FORMAT

White space is always cleared from the start of lines via /^[\t ]*/ for
each file line that is read in.

Blank lines are ignored.

Lines starting with /\#/ are comments lines.

Lines matching /^[Ee][Nn][Vv]\ [A-Za-z0-9\_]+\=/ are variables. Anything before the the
/\=/ is used as the name with everything after being the value.

Lines matching /^[A-Za-z0-9\_]+\=/ are variables. Anything before the the
/\=/ is used as the name with everything after being the value.

Lines matching /^[A-Za-z0-9\_]+\|/ are checks to run. Anything before the
/\|/ is the name with everything after command to run.

Lines matching /^\%[A-Za-z0-9\_]+\|/ are debug check to run. Anything before the
/\|/ is the name with everything after command to run. These will not count towards
the any of the counts. This exists purely for debugging purposes.

Any other sort of lines are considered an error.

Variables in the checks are in the form of /%+varaible_name%+/.

Variable names and check names may not be redefined once defined in the config.

=head2 EXAMPLE CONFIG

    env PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
    # this is a comment
    GEOM_DEV=foo
    geom_foo|/usr/local/libexec/nagios/check_geom mirror %GEOM_DEV%
    does_not_exist|/bin/this_will_error yup... that it will

    does_not_exist_2|/usr/bin/env /bin/this_will_also_error

The first line sets the %ENV variable PATH.

The second is ignored as it is a comment.

The third sets the variable GEOM_DEV to 'foo'

The fourth creates a check named geom_foo that calls check_geom_mirror
with the variable supplied to it being the value specified by the variable
GEOM_DEV.

The fith is a example of an error that will show what will happen when
you call to a file that does not exit.

The sixth line will be ignored as it is blank.

The seventh is a example of another command erroring.

When you run it, you will notice that errors for lines 4 and 5 are printed to STDERR.
For this reason you should use '2> /dev/null' when calling it from snmpd or
'2> /dev/null > /dev/null' when calling from cron.

=head1 USAGE

snmpd should be configured as below.

    extend sneck /usr/bin/env PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin /usr/local/bin/sneck -c

Then just setup a entry in like cron such as below.

    */5 * * * * /usr/bin/env PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin /usr/local/bin/sneck -u 2> /dev/null > /dev/null

Most likely want to run it once per polling interval.

You can use it in a non-cached manner with out cron, but this will result in a
longer polling time for LibreNMS or the like when it queries it.

=head1 RETURN HASH

The data section of the return hash is as below.

    - $hash{data}{alert} :: 0/1 boolean for if there is a aloert or not.

    - $hash{data}{ok} :: Count of the number of ok checks.

    - $hash{data}{warning} :: Count of the number of warning checks.

    - $hash{data}{critical} :: Count of the number of critical checks.

    - $hash{data}{unknown} :: Count of the number of unkown checks.

    - $hash{data}{errored} :: Count of the number of errored checks.

    - $hash{data}{alertString} :: The cumulative outputs of anything
      that returned a warning, critical, or unknown.

    - $hash{data}{vars} :: A hash with the variables to use.

    - $hash{data}{time} :: Time since epoch.

    - $hash{data}{hostname} :: The hostname the check was ran on.

    - $hash{data}{config} :: The raw config file if told to include it.

    - $hash{data}{run_time} :: How long it took to run all checks.

For below '$name' is the name of the check in question.

    - $hash{data}{checks}{$name} :: A hash with info on the checks ran.

    - $hash{data}{checks}{$name}{check} :: The command pre-variable substitution.

    - $hash{data}{checks}{$name}{ran} :: The command ran.

    - $hash{data}{checks}{$name}{output} :: The output of the check.

    - $hash{data}{checks}{$name}{exit} :: The exit code.

    - $hash{data}{checks}{$name}{error} :: Only present it died on a
      signal or could not be executed. Provides a brief description.

    - $hash{data}{checks}{$name}{run_time} :: How long it took to run the checks.

For below '$name' is the name of the debug checks in question.

    - $hash{data}{debugs}{$name} :: A hash with info on the checks ran.

    - $hash{data}{debugs}{$name}{check} :: The command pre-variable substitution.

    - $hash{data}{debugs}{$name}{ran} :: The command ran.

    - $hash{data}{debugs}{$name}{output} :: The output of the check.

    - $hash{data}{debugs}{$name}{exit} :: The exit code.

    - $hash{data}{debugs}{$name}{error} :: Only present it died on a
      signal or could not be executed. Provides a brief description.

    - $hash{data}{checks}{$name}{run_time} :: How long it took to run the debug.

=head1 METHODS

=head2 new

Initiates the object.

One argument is taken and that is a hash ref. If the key 'config'
is present, that will be the config file used. Otherwise
'/usr/local/etc/sneck.conf' is used. The key 'include' is a Perl
boolean for if the raw config should be included in the JSON.

This function should always work as long as it can read the config.
If there is an error with parsing or the like, it will be reported
in the expected format when $sneck->run is called.

This is meant to be rock solid and always work, meaning LibreNMS
style JSON is always returned(provided Perl and the other modules
are working).

If 'debug' is true, when run is called, debugging info will be
printed.

    my $sneck;
    eval{
        $sneck=Monitoring::Sneck->new({config=>$file, include=>0, debug=>0});
    };
    if ($@){
        die($@);
    }

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ) {
		%args = %{ $_[1] };
	}

	# init the object

	my $self = {

		config    => '/usr/local/etc/sneck.conf',
		to_return => {
			error       => 0,
			errorString => '',
			data        => {
				hostname    => hostname,
				ok          => 0,
				warning     => 0,
				critical    => 0,
				unknown     => 0,
				errored     => 0,
				alert       => 0,
				alertString => '',
				checks      => {},
				debugs      => {},
			},
			version => 1,
		},
		checks => {},
		vars   => {},
		good   => 1,
		debug  => 0,
	};
	bless $self;

	my $config_raw;
	eval { $config_raw = read_file( $self->{config} ); };
	if ($@) {
		$self->{good}                   = 0;
		$self->{to_return}{error}       = 1;
		$self->{to_return}{errorString} = 'Failed to read in the config file "' . $self->{config} . '"... ' . $@;
		$self->{checks}                 = {};
		return $self;
	}

	# include the config file if requested
	if ( defined( $args{include} )
		&& $args{include} )
	{
		$self->{to_return}{data}{config} = $config_raw;
	}

	if ( defined( $args{debug} ) ) {
		$self->{debug} = $args{debug};
	}

	# split the file and ignore any comments
	my @config_split = grep( !/^[\t\ ]*#/, split( /\n/, $config_raw ) );
	my $found_items  = 0;
	foreach my $line (@config_split) {
		$line =~ s/^[\ \t]*//;
		if ( $line =~ /^[Ee][Nn][Vv]\ [A-Za-z0-9\_]+\=/ ) {
			my ( $name, $value ) = split( /\=/, $line, 2 );

			# make sure we have a value
			if ( !defined($value) ) {
				$value = '';
			}

			# remove the starting bit
			$name =~ s/^[Ee][Nn][Vv]\ //;
			$ENV{$name} = $value;
		} elsif ( $line =~ /^[A-Za-z0-9\_]+\=/ ) {

			# we found a variable
			my ( $name, $value ) = split( /\=/, $line, 2 );

			# make sure we have a value
			if ( !defined($value) ) {
				$self->{good} = 0;
				$self->{to_return}{error} = 1;
				$self->{to_return}{errorString}
					= '"' . $line . '" seems to be a variable, but just a variable and no value';
				return $self;
			}

			# remove any white space from the end of the name
			$name =~ s/[\t\ ]*$//;

			# check to make sure it is not already defined
			if ( defined( $self->{vars}{$name} ) ) {
				$self->{good}                   = 0;
				$self->{to_return}{error}       = 1;
				$self->{to_return}{errorString} = 'variable "' . $name . '" is redefined on the line "' . $line . '"';
				return $self;
			}

			$self->{vars}{$name} = $value;
		} elsif ( $line =~ /^\%*[A-Za-z0-9\_]+\|/ ) {

			# we found a check to add
			my ( $name, $check ) = split( /\|/, $line, 2 );

			# make sure we have a check
			if ( !defined($check) ) {
				$self->{good} = 0;
				$self->{to_return}{error} = 1;
				$self->{to_return}{errorString}
					= '"' . $line . '" seems to be a check, but just contains a check name and no check';
				return $self;
			}

			# remove any white space from the end of the name
			$name =~ s/[\t\ ]*$//;

			# check to make sure it is not already defined
			if ( defined( $self->{checks}{$name} ) ) {
				$self->{good}                   = 0;
				$self->{to_return}{error}       = 1;
				$self->{to_return}{errorString} = 'check "' . $name . '" is defined on the line "' . $line . '"';
				return $self;
			}

			# remove any white space from the start of the check
			$check =~ s/^[\t\ ]*//;

			$self->{checks}{$name} = $check;

			$found_items++;
		} elsif ( $line =~ /^$/ ) {

			# just ignore empty lines so we don't error on them
		} else {
			# we did not get a match for this line
			$self->{good}                   = 0;
			$self->{to_return}{error}       = 1;
			$self->{to_return}{errorString} = '"' . $line . '" is not a understood line';
			return $self;
		}
	} ## end foreach my $line (@config_split)

	$self;
} ## end sub new

=head2 run

This runs the checks and returns the return hash.

    my $return=$sneck->run;

=cut

sub run {
	my $self = $_[0];

	my $run_start_time = Time::HiRes::time;
	if ( $self->{debug} ) {
		warn( 'run started at ' . $run_start_time );
	}

	# if something went wrong with new, just return
	if ( !$self->{good} ) {
		if ( $self->{debug} ) {
			warn('$self->{good} false... returning $self->{to_return}');
		}
		return $self->{to_return};
	}

	# set the time it ran
	$self->{to_return}{data}{time} = time;

	my @vars   = keys( %{ $self->{vars} } );
	my @checks = sort( keys( %{ $self->{checks} } ) );
	foreach my $name (@checks) {
		my $check_start_time = Time::HiRes::time;
		if ( $self->{debug} ) {
			warn( $name . ' processing started at ' . $check_start_time );
		}

		my $type = 'checks';
		if ( $name =~ /^\%/ ) {
			$type = 'debugs';
		}
		if ( $self->{debug} ) {
			warn( $name . ' is of type ' . $type );
		}

		my $check = $self->{checks}{$name};
		$name =~ s/^\%//;
		$self->{to_return}{data}{$type}{$name} = { check => $check };

		if ( $self->{debug} ) {
			warn( $name . ' check string: "' . $check . '"' );
		}

		# put the variables in place
		foreach my $var_name (@vars) {
			my $value = $self->{vars}{$var_name};
			$check =~ s/%+$var_name%+/$value/g;
		}
		$self->{to_return}{data}{$type}{$name}{ran} = $check;
		if ( $self->{debug} ) {
			warn( $name . ' check string post variable replacement: "' . $check . '"' );
		}

		my $check_pid = open3( my $std_in, my $std_out, my $std_err = gensym, $check );
		if ( $self->{debug} ) {
			warn( $name . ' open3 called' );
		}

		my $s = IO::Select->new();
		$s->add($std_out);
		$s->add($std_err);
		my $output = '';
		while ( my @ready = $s->can_read ) {
			foreach my $handle (@ready) {
				if ( sysread( $handle, my $buf, 4096 ) ) {
					$output = $output . $buf;
				} else {
					$s->remove($handle);
				}
			}
		}

		if ( $self->{debug} ) {
			warn( $name . ' IO::Select for open3 done... output is... "' . $output . '"' );
		}

		# call wait pid so we can get the exit code
		waitpid( $check_pid, 0 );
		my $exit_code = $?;
		$self->{to_return}{data}{$type}{$name}{output} = $output;
		if ( defined( $self->{to_return}{data}{$type}{$name}{output} ) ) {
			chomp( $self->{to_return}{data}{$type}{$name}{output} );
		}

		# handle the exit code
		if ( $exit_code == -1 ) {
			$self->{to_return}{data}{$type}{$name}{error} = 'failed to execute';
		} elsif ( $exit_code & 127 ) {
			$self->{to_return}{data}{$type}{$name}{error} = sprintf(
				"child died with signal %d, %s coredump\n",
				( $exit_code & 127 ),
				( $exit_code & 128 ) ? 'with' : 'without'
			);
		} else {
			$exit_code = $exit_code >> 8;
		}
		$self->{to_return}{data}{$type}{$name}{exit} = $exit_code;

		if ( $self->{debug} ) {
			warn( $name . ' exit code is ' . $exit_code );
		}

		# anything other than 0, 1, 2, or 3 is a error
		if ( $type eq 'checks' ) {
			if ( $self->{to_return}{data}{checks}{$name}{exit} == 0 ) {
				$self->{to_return}{data}{ok}++;
				if ( $self->{debug} ) {
					warn( $name . ' is ok' );
				}
			} elsif ( $self->{to_return}{data}{checks}{$name}{exit} == 1 ) {
				$self->{to_return}{data}{warning}++;
				$self->{to_return}{data}{alert} = 1;
				if ( $self->{debug} ) {
					warn( $name . ' is warning' );
				}
			} elsif ( $self->{to_return}{data}{checks}{$name}{exit} == 2 ) {
				$self->{to_return}{data}{critical}++;
				$self->{to_return}{data}{alert} = 1;
				if ( $self->{debug} ) {
					warn( $name . ' is critical' );
				}
			} elsif ( $self->{to_return}{data}{checks}{$name}{exit} == 3 ) {
				$self->{to_return}{data}{unknown}++;
				$self->{to_return}{data}{alert} = 1;
				if ( $self->{debug} ) {
					warn( $name . ' is unknown' );
				}
			} else {
				$self->{to_return}{data}{errored}++;
				$self->{to_return}{data}{alert} = 1;
				if ( $self->{debug} ) {
					warn( $name . ' is errored' );
				}
			}

			# add it to the alert string if it is a warning
			if ( $exit_code == 1 || $exit_code == 2 || $exit_code == 3 ) {
				$self->{to_return}{data}{alertString}
					= $self->{to_return}{data}{alertString} . $self->{to_return}{data}{checks}{$name}{output} . "\n";
			}
		} ## end if ( $type eq 'checks' )

		# figure out how long the run took
		my $check_stop_time = Time::HiRes::time;
		if ( $self->{debug} ) {
			warn( $name . ' finished at ' . $check_stop_time );
		}
		my $check_time = $check_stop_time - $check_start_time;
		# round to the 9th place to avoid scientific notation
		$self->{to_return}{data}{$type}{$name}{run_time} = sprintf( '%.9f', $check_time );
	} ## end foreach my $name (@checks)

	$self->{to_return}{data}{vars} = $self->{vars};

	# figure out how long the run took
	my $run_stop_time = Time::HiRes::time;
	if ( $self->{debug} ) {
		warn( 'run finished at ' . $run_stop_time );
	}

	my $run_time = $run_stop_time - $run_start_time;
	if ( $self->{debug} ) {
		warn( 'run time was ' . $run_time );
	}

	# round to the 9th place to avoid scientific notation
	$self->{to_return}{data}{run_time} = sprintf( '%.9f', $run_time );

	if ( $self->{debug} ) {
		warn('run is returning now');
	}
	return $self->{to_return};
} ## end sub run

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-monitoring-sneck at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Monitoring-Sneck>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Monitoring::Sneck


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Monitoring-Sneck>

=item * Search CPAN

L<https://metacpan.org/release/Monitoring-Sneck>

=item * Github

l<https://github.com/VVelox/Monitoring-Sneck>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Monitoring::Sneck
