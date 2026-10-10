package Monitoring::Sneck;

use 5.006;
use strict;
use warnings;
use Sys::Hostname qw(hostname);
use IPC::Open3    qw(open3);
use Symbol        qw(gensym);
use IO::Select;
use Time::HiRes qw(time);
use POSIX         qw(WNOHANG);
use JSON          ();
use File::Slurp   qw(read_file write_file);
use Monitoring::Sneck::Config ();

=head1 NAME

Monitoring::Sneck - a boopable LibreNMS JSON style SNMP extend for remotely running nagios style checks

=head1 VERSION

Version 1.6.0

=cut

our $VERSION = '1.6.0';

=head1 SYNOPSIS

    use Monitoring::Sneck;

    my $file='/usr/local/etc/sneck.conf';

    my $sneck=Monitoring::Sneck->new({config=>$file});

=head1 USAGE

Not really meant to be used as a library. The library is more of
to support the script.

=head1 CONFIG FORMAT

See L<Monitoring::Sneck::Config> for the config format and a example.

=head1 USAGE

snmpd just needs to print the cache. The simplest way is to cat the
GZip+BASE64 compressed cache, which avoids starting perl at all.

    extend sneck /bin/cat /var/cache/sneck.cache.snmp

sneck -c may be used instead. It reports a missing cache file as error
JSON instead of printing nothing, but has to start perl and read the
config on each poll.

    extend sneck /usr/bin/env PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin /usr/local/bin/sneck -c

If the cache file is changed via cache_file or B<-C>, cat its .snmp file
instead, or give B<-c> the same B<-C>.

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

    - $hash{data}{restarted} :: Count of the number of restarts ran.

    - $hash{data}{restart_state_error} :: Only present if the restart
      state file could not be read or written. Restarts still run if it
      can't be read, as if there was no state.

For below '$name' is the name of the check in question.

    - $hash{data}{checks}{$name} :: A hash with info on the checks ran.

    - $hash{data}{checks}{$name}{check} :: The command pre-variable substitution.

    - $hash{data}{checks}{$name}{ran} :: The command ran.

    - $hash{data}{checks}{$name}{output} :: The output of the check.

    - $hash{data}{checks}{$name}{exit} :: The exit code. If it died on a
      signal, this is 128 plus the signal number. If it could not be
      executed or timed out, this is -1.

    - $hash{data}{checks}{$name}{error} :: Only present if it died on a
      signal, timed out, or could not be executed. Provides a brief
      description.

    - $hash{data}{checks}{$name}{run_time} :: How long it took to run the checks.

    - $hash{data}{checks}{$name}{rechecked_by} :: Only present if it was
      rerun after a restart with check_restart set. The name of that
      restart. The rest of the results are from the rerun.

For below '$name' is the name of the debug checks in question. Debug
checks are run the same as checks, including check_timeout,
check_timeout_signal, and check_kill_sub_pids.

    - $hash{data}{debugs}{$name} :: A hash with info on the checks ran.

    - $hash{data}{debugs}{$name}{check} :: The command pre-variable substitution.

    - $hash{data}{debugs}{$name}{ran} :: The command ran.

    - $hash{data}{debugs}{$name}{output} :: The output of the check.

    - $hash{data}{debugs}{$name}{exit} :: The exit code. Same as for checks.

    - $hash{data}{debugs}{$name}{error} :: Only present if it died on a
      signal, timed out, or could not be executed. Provides a brief
      description.

    - $hash{data}{debugs}{$name}{run_time} :: How long it took to run the debug.

For below '$name' is the name of the restart in question. Every restart
in the config has a entry, even when restarts are disabled.

    - $hash{data}{restarts}{$name}{triggered} :: 0/1 for if enough of its
      checks failed to meet its threshold.

    - $hash{data}{restarts}{$name}{ran} :: 0/1 for if it ran.

    - $hash{data}{restarts}{$name}{reason} :: Why it did or did not run.
      One of 'threshold', 'cascade from $depend', 'cooldown, $N seconds
      left', 'max retries reached', 'skipped, dependency $depend failed',
      'maintenance window', 'not triggered', or 'restarts disabled'.

    - $hash{data}{restarts}{$name}{failed_checks} :: Array of the watched
      checks that counted as failed.

    - $hash{data}{restarts}{$name}{threshold} :: The threshold.

    - $hash{data}{restarts}{$name}{attempts} :: Runs for its threshold
      since its checks last recovered.

    - $hash{data}{restarts}{$name}{command} :: The command pre-variable
      substitution.

The rest are only present if it ran.

    - $hash{data}{restarts}{$name}{ran_command} :: The command ran.

    - $hash{data}{restarts}{$name}{output} :: The output of the command.

    - $hash{data}{restarts}{$name}{exit} :: The exit code. Same as for
      checks, plus -1 if it timed out.

    - $hash{data}{restarts}{$name}{error} :: Only present if it timed
      out, died on a signal, or could not be executed. If it timed out
      and timeout_signal is set, also says the signal was sent, plus
      any problems sending it. Also present if check_restart is set,
      the command exited 0, and its checks still met the threshold
      afterwards.

    - $hash{data}{restarts}{$name}{run_time} :: How long the command
      took to run, not counting check_restart.

    - $hash{data}{restarts}{$name}{recheck_failed_checks} :: Only present
      if check_restart is set. Array of the watched checks that still
      counted as failed when rerun.

A restart that ran and failed, including timing out or its checks still
failing with check_restart, sets alert and adds a line to alertString
along with any output from the command. Check results, counts, and
alertString reflect any checks rerun by check_restart.

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

If 'restart' is true, restarts whose checks failed are run. Otherwise
they are only reported. Never enable this for something polled by snmpd.

'state_file' is where restart state, used for min_interval and
max_retries, is kept. Default :: /var/cache/sneck.cache.restarts

'check_timeout', 'check_timeout_signal', and 'check_kill_sub_pids'
override the options of the same names in the config. See OPTIONS in
L<Monitoring::Sneck::Config>. 'check_timeout_signal' may also be 'none'
to send no signal even if the config sets one. Bad values are reported
the same as config errors.

    my $sneck;
    eval{
        $sneck=Monitoring::Sneck->new({config=>$file, include=>0, debug=>0, restart=>0});
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
				restarts    => {},
				restarted   => 0,
			},
			version => 1,
		},
		parsed_config => undef,
		good          => 1,
		debug         => 0,
		restart       => 0,
		state_file    => '/var/cache/sneck.cache.restarts',
		# same defaults as timeout, timeout_signal, and kill_sub_pids for restarts
		check_timeout        => 30,
		check_timeout_signal => undef,
		check_kill_sub_pids  => 1,
		# alertString lines from failed restarts, added after the checks by _tally_checks
		restart_alerts => [],
	};
	bless $self;

	if ( defined( $args{config} ) ) {
		$self->{config} = $args{config};
	}

	if ( defined( $args{debug} ) ) {
		$self->{debug} = $args{debug};
	}

	if ( defined( $args{restart} ) ) {
		$self->{restart} = $args{restart};
	}

	if ( defined( $args{state_file} ) ) {
		$self->{state_file} = $args{state_file};
	}

	my $parsed_config;
	eval { $parsed_config = Monitoring::Sneck::Config->new( { file => $self->{config} } ); };
	if ($@) {
		$self->{good}                   = 0;
		$self->{to_return}{error}       = 1;
		$self->{to_return}{errorString} = $@;
		return $self;
	}

	# include the config file if requested
	if ( defined( $args{include} )
		&& $args{include} )
	{
		$self->{to_return}{data}{config} = $parsed_config->raw;
	}

	if ( !$parsed_config->is_valid ) {
		$self->{good}                   = 0;
		$self->{to_return}{error}       = 1;
		$self->{to_return}{errorString} = join( '; ',
			map { $_->{where} . ': ' . $_->{message} } $parsed_config->errors );
		return $self;
	}

	# check timeout settings, args over the config over the defaults
	my $options = $parsed_config->options;
	my @arg_errors;
	foreach my $name ( 'check_timeout', 'check_timeout_signal', 'check_kill_sub_pids' ) {
		if ( defined( $options->{$name} ) ) {
			$self->{$name} = $options->{$name};
		}
		if ( !defined( $args{$name} ) ) {
			next;
		}
		if ( $name eq 'check_timeout_signal' && $args{$name} eq 'none' ) {
			$self->{$name} = undef;
			next;
		}
		my ( $value, $error ) = Monitoring::Sneck::Config->validate_option( $name, $args{$name} );
		if ( defined($error) ) {
			push( @arg_errors, 'arg ' . $name . ': ' . $error );
			next;
		}
		$self->{$name} = $value;
	} ## end foreach my $name ( 'check_timeout', 'check_timeout_signal', 'check_kill_sub_pids' )
	if ( defined( $arg_errors[0] ) ) {
		$self->{good}                   = 0;
		$self->{to_return}{error}       = 1;
		$self->{to_return}{errorString} = join( '; ', @arg_errors );
		return $self;
	}

	# only touch %ENV once the whole config is known to be good
	foreach my $env ( @{ $parsed_config->env } ) {
		$ENV{ $env->[0] } = $env->[1];
	}

	$self->{parsed_config} = $parsed_config;

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

	# reset the results so calling run more than once does not accumulate
	$self->{to_return}{data}{ok}          = 0;
	$self->{to_return}{data}{warning}     = 0;
	$self->{to_return}{data}{critical}    = 0;
	$self->{to_return}{data}{unknown}     = 0;
	$self->{to_return}{data}{errored}     = 0;
	$self->{to_return}{data}{alert}       = 0;
	$self->{to_return}{data}{alertString} = '';
	$self->{to_return}{data}{checks}      = {};
	$self->{to_return}{data}{debugs}      = {};
	$self->{to_return}{data}{restarts}    = {};
	$self->{to_return}{data}{restarted}   = 0;
	delete( $self->{to_return}{data}{restart_state_error} );
	$self->{restart_alerts} = [];

	# set the time it ran
	$self->{to_return}{data}{time} = time;
	#make sure it is a int
	$self->{to_return}{data}{time} =~ s/\..*$//;

	# debugs first, then checks, each in name order
	my $parsed_config = $self->{parsed_config};
	my @to_run;
	foreach my $type ( 'debugs', 'checks' ) {
		my $commands = $parsed_config->$type;
		foreach my $name ( sort( keys( %{$commands} ) ) ) {
			push( @to_run, [ $type, $name, $commands->{$name} ] );
		}
	}

	foreach my $item (@to_run) {
		$self->_run_check( @{$item} );
	}

	$self->_handle_restarts;

	$self->_tally_checks;

	$self->{to_return}{data}{vars} = $parsed_config->vars;

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

# Runs a single check or debug check and stores its results, replacing any
# earlier results for it. Used by run, and by _run_restart to rerun checks
# for check_restart. Does not count it towards ok, warning, and the like.
# That is done by _tally_checks once everything has run.
#
# It is run via _run_command using check_timeout, check_timeout_signal, and
# check_kill_sub_pids. A timeout gives a exit of -1 and a error.
#
# Args...
#
#     - type :: Either 'checks' or 'debugs'.
#
#     - name :: The name of the check.
#
#     - check :: The command, before variable substitution.
#
# Returns nothing. Results go in $self->{to_return}{data}{$type}{$name} as
# a hash ref of check, ran, output, exit, error if any, and run_time, as
# described under RETURN HASH.
#
# Example...
#
#     $self->_run_check( 'checks', 'http_check', '/usr/local/libexec/nagios/check_http -H %HOST%' );
#     # $self->{to_return}{data}{checks}{http_check} is
#     # { check => '...', ran => '...', output => 'HTTP OK...', exit => 0, run_time => '0.012345678' }
sub _run_check {
	my ( $self, $type, $name, $check ) = @_;

	my $check_start_time = Time::HiRes::time;
	if ( $self->{debug} ) {
		warn( $name . ' processing started at ' . $check_start_time );
		warn( $name . ' is of type ' . $type );
	}

	my $result = { check => $check };
	$self->{to_return}{data}{$type}{$name} = $result;

	if ( $self->{debug} ) {
		warn( $name . ' check string: "' . $check . '"' );
	}

	# put the variables in place
	$check = $self->{parsed_config}->substitute($check);
	$result->{ran} = $check;
	if ( $self->{debug} ) {
		warn( $name . ' check string post variable replacement: "' . $check . '"' );
	}

	my $command_result = $self->_run_command( $check, $self->{check_timeout}, $self->{check_timeout_signal},
		$self->{check_kill_sub_pids} );
	if ( $self->{debug} ) {
		warn( $name . ' command done... output is... "' . $command_result->{output} . '"' );
	}

	# exit is -1 for timeouts and failing to execute, and 128 + signal for
	# signal deaths, so neither is mistaken for a nagios exit code of 0 to 3
	my $exit_code = $command_result->{exit};
	$result->{output} = $command_result->{output};
	if ( defined( $command_result->{wait_status} ) && ( $command_result->{wait_status} & 127 ) ) {
		$result->{error} = sprintf(
			"child died with signal %d, %s coredump\n",
			( $command_result->{wait_status} & 127 ),
			( $command_result->{wait_status} & 128 ) ? 'with' : 'without'
		);
	} elsif ( defined( $command_result->{error} ) ) {
		$result->{error} = $command_result->{error};
	}
	$result->{exit} = $exit_code;

	if ( $self->{debug} ) {
		warn( $name . ' exit code is ' . $exit_code );
	}

	# figure out how long the run took
	my $check_stop_time = Time::HiRes::time;
	if ( $self->{debug} ) {
		warn( $name . ' finished at ' . $check_stop_time );
	}
	# round to the 9th place to avoid scientific notation
	$result->{run_time} = sprintf( '%.9f', $check_stop_time - $check_start_time );

	return;
} ## end sub _run_check

# Counts the check results into ok, warning, critical, unknown, and
# errored, and builds alert and alertString from them. Anything other than
# exit 0 sets alert. Output of warning, critical, and unknown checks is
# added to alertString in name order, followed by the lines for failed
# restarts in $self->{restart_alerts}, which also set alert. Called by run
# once checks and restarts are done, so rerun checks are counted with
# their final results.
#
# Takes no args and returns nothing. Results go in $self->{to_return}{data}.
#
# Example...
#
#     # http_check exited 2 and php_check exited 0
#     $self->_tally_checks;
#     # ok is 1, critical is 1, alert is 1, and alertString is the output of http_check plus "\n"
sub _tally_checks {
	my $self = $_[0];

	my $data           = $self->{to_return}{data};
	my %counts_by_exit = ( 0 => 'ok', 1 => 'warning', 2 => 'critical', 3 => 'unknown' );
	foreach my $count ( 'ok', 'warning', 'critical', 'unknown', 'errored' ) {
		$data->{$count} = 0;
	}
	$data->{alert}       = 0;
	$data->{alertString} = '';

	foreach my $name ( sort( keys( %{ $data->{checks} } ) ) ) {
		my $exit_code = $data->{checks}{$name}{exit};
		my $count     = defined( $counts_by_exit{$exit_code} ) ? $counts_by_exit{$exit_code} : 'errored';
		$data->{$count}++;
		if ( $self->{debug} ) {
			warn( $name . ' is ' . $count );
		}
		if ( $count ne 'ok' ) {
			$data->{alert} = 1;
		}
		# add it to the alert string if it is a warning, critical, or unknown
		if ( $count ne 'ok' && $count ne 'errored' ) {
			$data->{alertString} = $data->{alertString} . $data->{checks}{$name}{output} . "\n";
		}
	} ## end foreach my $name ( sort( keys( %{ $data->{checks} } ) ) )

	foreach my $line ( @{ $self->{restart_alerts} } ) {
		$data->{alert}       = 1;
		$data->{alertString} = $data->{alertString} . $line;
	}

	return;
} ## end sub _tally_checks

# Works out which restarts triggered and, if restarts are enabled, runs
# them. Called by run after all checks have run and before _tally_checks.
# Takes no args and returns nothing. Results go in
# $self->{to_return}{data}{restarts} and $self->{to_return}{data}{restarted},
# and failures are added to $self->{restart_alerts}. Which restarts
# triggered is worked out once, before any run, so checks rerun by
# check_restart do not change it for the restarts after.
#
# Restarts run in dependency order. A restart runs if its threshold was
# met, or if cascade is set and one of its depends ran without failing.
# Before running, it is skipped if a depend failed or was itself skipped
# for that reason, and held back by not_every, min_interval and, for
# threshold triggered runs, max_retries. One held back by not_every gets no
# status, so restarts depending on it act as if it did not trigger, and its
# state is left alone. State for min_interval and max_retries is kept in
# the state file. It is written before each restart runs, so a run that is killed
# part way through still counts, and again once all are done. last_run is
# set to when each restart finished.
#
# Example...
#
#     # http_check exited 2 and httpd watches it with the default threshold of 1
#     $self->_handle_restarts;
#     # $self->{to_return}{data}{restarts}{httpd} is
#     # { triggered => 1, ran => 1, reason => 'threshold', failed_checks => ['http_check'],
#     #   threshold => 1, attempts => 1, command => '...', ran_command => '...',
#     #   output => '...', exit => 0, run_time => '1.234567890' }
sub _handle_restarts {
	my $self = $_[0];

	my $data     = $self->{to_return}{data};
	my $restarts = $self->{parsed_config}->restarts;
	my @names    = sort( keys( %{$restarts} ) );
	if ( !defined( $names[0] ) ) {
		return;
	}

	foreach my $name (@names) {
		my $restart       = $restarts->{$name};
		my @failed_checks = grep { $self->_check_failed( $data->{checks}{$_}{exit}, $restart ) } @{ $restart->{checks} };
		$data->{restarts}{$name} = {
			triggered     => scalar(@failed_checks) >= $restart->{threshold} ? 1 : 0,
			ran           => 0,
			reason        => 'not triggered',
			failed_checks => \@failed_checks,
			threshold     => $restart->{threshold},
			attempts      => 0,
			command       => $restart->{command},
		};
	} ## end foreach my $name (@names)

	if ( !$self->{restart} ) {
		foreach my $name (@names) {
			$data->{restarts}{$name}{reason} = 'restarts disabled';
		}
		return;
	}

	my ( $state, $state_error ) = $self->_read_restart_state;
	my $write_error;

	# forget restarts no longer in the config
	foreach my $name ( keys( %{$state} ) ) {
		if ( !defined( $restarts->{$name} ) ) {
			delete( $state->{$name} );
		}
	}

	# 'ok' or 'failed' for those that ran, 'skipped' for those skipped because a depend failed
	my %status;
	foreach my $name ( $self->_restart_order($restarts) ) {
		my $restart = $restarts->{$name};
		my $result  = $data->{restarts}{$name};
		my $now     = int(time);
		if ( !defined( $state->{$name} ) ) {
			$state->{$name} = { last_run => 0, attempts => 0 };
		}
		my $state_item = $state->{$name};

		# the checks recovered, so start counting attempts again
		if ( !$result->{triggered} ) {
			$state_item->{attempts} = 0;
		}

		my $run_reason;
		my $cascade_from;
		if ( $result->{triggered} ) {
			$run_reason = 'threshold';
		} elsif ( $restart->{cascade} ) {
			($cascade_from) = grep { defined( $status{$_} ) && $status{$_} eq 'ok' } @{ $restart->{depends} };
			if ( defined($cascade_from) ) {
				$run_reason = 'cascade from ' . $cascade_from;
			}
		}

		if ( defined($run_reason) ) {
			my ($failed_depend)
				= grep { defined( $status{$_} ) && ( $status{$_} eq 'failed' || $status{$_} eq 'skipped' ) }
				@{ $restart->{depends} };
			my $since_last = $now - $state_item->{last_run};
			if ( defined($failed_depend) ) {
				$result->{reason} = 'skipped, dependency ' . $failed_depend . ' failed';
				$status{$name} = 'skipped';
			} elsif ( defined( $restart->{not_every} ) && $self->_in_not_every( $restart->{not_every}, $now ) ) {
				$result->{reason} = 'maintenance window';
			} elsif ( $restart->{min_interval} > 0
				&& $since_last >= 0
				&& $since_last < $restart->{min_interval} )
			{
				$result->{reason} = 'cooldown, ' . ( $restart->{min_interval} - $since_last ) . ' seconds left';
			} elsif ( $run_reason eq 'threshold'
				&& $restart->{max_retries} > 0
				&& $state_item->{attempts} >= $restart->{max_retries} )
			{
				$result->{reason} = 'max retries reached';
			} else {
				# save the run before it starts, so it still counts if sneck dies while it runs
				$state_item->{last_run} = $now;
				if ( $run_reason eq 'threshold' ) {
					$state_item->{attempts}++;
				}
				my $error = $self->_write_restart_state($state);
				if ( defined($error) ) {
					$write_error = $error;
				}

				$self->_run_restart( $name, $restart, $result, $cascade_from, $state_item->{attempts} );

				# min_interval is counted from when it finished
				$state_item->{last_run} = int(time);
				$status{$name} = defined( $result->{error} ) || $result->{exit} != 0 ? 'failed' : 'ok';
			} ## end else [ if ( defined($failed_depend) ) ]
		} ## end if ( defined($run_reason) )

		$result->{attempts} = $state_item->{attempts};
	} ## end foreach my $name ( $self->_restart_order($restarts) )

	my $error = $self->_write_restart_state($state);
	if ( defined($error) ) {
		$write_error = $error;
	}
	my @state_errors = grep { defined($_) } ( $state_error, $write_error );
	if ( defined( $state_errors[0] ) ) {
		$data->{restart_state_error} = join( '; ', @state_errors );
	}

	return;
} ## end sub _handle_restarts

# Checks if a time falls in a not_every maintenance window. Used by
# _handle_restarts. The time is turned into local time via localtime, so
# TZ is honored, and matched to the minute. DateTime::Event::Cron is only
# loaded the first time this is called.
#
# Args...
#
#     - spec :: A five field cron spec, as already validated by
#       Monitoring::Sneck::Config.
#
#     - epoch :: Unix time to check.
#
# Returns 1 if the time matches the spec, otherwise 0.
#
# Example...
#
#     # 2026-10-11 02:30 local time, a Sunday
#     $self->_in_not_every( '* 2-3 * * 0', $epoch );
#     # returns 1
#
#     $self->_in_not_every( '* 4 * * *', $epoch );
#     # returns 0
sub _in_not_every {
	my ( $self, $spec, $epoch ) = @_;

	require DateTime;
	require DateTime::Event::Cron;

	# floating, so it is matched as is and DateTime never has to work out the local time zone itself
	my @local_time = localtime($epoch);
	my $local_time = DateTime->new(
		year      => $local_time[5] + 1900,
		month     => $local_time[4] + 1,
		day       => $local_time[3],
		hour      => $local_time[2],
		minute    => $local_time[1],
		time_zone => 'floating',
	);

	return DateTime::Event::Cron->new_from_cron( cron => $spec )->match($local_time) ? 1 : 0;
} ## end sub _in_not_every

# Runs a single restart and records the results. Used by _handle_restarts.
# The command gets the SNECK_* environment variables described under
# RESTARTS in Monitoring::Sneck::Config. If check_restart is set, its
# checks are then rerun via _run_check after check_restart_delay seconds.
# A failed restart, including its checks still meeting the threshold
# afterwards, adds a line to $self->{restart_alerts}, along with any
# output from the command.
#
# Args...
#
#     - name :: The name of the restart.
#
#     - restart :: Hash ref of the restart as returned by the restarts
#       method of Monitoring::Sneck::Config.
#
#     - result :: Hash ref of the restart's entry in data.restarts, which
#       is filled in with ran, reason, ran_command, output, exit, error if
#       any, run_time, and recheck_failed_checks if rechecked.
#
#     - cascade_from :: Name of the depend it is cascading from, or undef
#       if it is running for its threshold.
#
#     - attempts :: Runs for its threshold since its checks last
#       recovered, this one included. Passed on as SNECK_ATTEMPTS.
#
# Returns nothing.
#
# Example...
#
#     $self->_run_restart( 'httpd', $restarts->{httpd}, $data->{restarts}{httpd}, undef, 1 );
#     # $data->{restarts}{httpd}{ran} is 1 and $data->{restarted} went up by 1
#
#     $self->_run_restart( 'httpd', $restarts->{httpd}, $data->{restarts}{httpd}, 'php_fpm', 0 );
#     # same, but reason is 'cascade from php_fpm' and SNECK_REASON was 'cascade'
sub _run_restart {
	my ( $self, $name, $restart, $result, $cascade_from, $attempts ) = @_;

	my $reason      = defined($cascade_from) ? 'cascade from ' . $cascade_from : 'threshold';
	my $start_time  = Time::HiRes::time;
	my $ran_command = $self->{parsed_config}->substitute( $restart->{command} );
	if ( $self->{debug} ) {
		warn( 'restart ' . $name . ' running for ' . $reason . ': "' . $ran_command . '"' );
	}

	# tell the command why it is running
	my %sneck_env = (
		SNECK_RESTART       => $name,
		SNECK_REASON        => defined($cascade_from) ? 'cascade'     : 'threshold',
		SNECK_CASCADE_FROM  => defined($cascade_from) ? $cascade_from : '',
		SNECK_FAILED_CHECKS => join( ',', @{ $result->{failed_checks} } ),
		SNECK_CHECKS        => join( ',', @{ $restart->{checks} } ),
		SNECK_THRESHOLD     => $restart->{threshold},
		SNECK_ATTEMPTS      => $attempts,
	);
	my $command_result;
	{
		local @ENV{ keys(%sneck_env) } = values(%sneck_env);
		$command_result = $self->_run_command( $ran_command, $restart->{timeout}, $restart->{timeout_signal},
			$restart->{kill_sub_pids} );
	}

	$result->{ran}         = 1;
	$result->{reason}      = $reason;
	$result->{ran_command} = $ran_command;
	$result->{output}      = $command_result->{output};
	$result->{exit}        = $command_result->{exit};
	if ( defined( $command_result->{error} ) ) {
		$result->{error} = $command_result->{error};
	}
	$result->{run_time} = sprintf( '%.9f', Time::HiRes::time - $start_time );
	$self->{to_return}{data}{restarted}++;

	if ( $restart->{check_restart} ) {
		if ( $restart->{check_restart_delay} > 0 ) {
			if ( $self->{debug} ) {
				warn( 'restart ' . $name . ' waiting ' . $restart->{check_restart_delay} . ' seconds to recheck' );
			}
			sleep( $restart->{check_restart_delay} );
		}
		my $checks = $self->{parsed_config}->checks;
		foreach my $check_name ( @{ $restart->{checks} } ) {
			$self->_run_check( 'checks', $check_name, $checks->{$check_name} );
			$self->{to_return}{data}{checks}{$check_name}{rechecked_by} = $name;
		}
		my @still_failed = grep { $self->_check_failed( $self->{to_return}{data}{checks}{$_}{exit}, $restart ) }
			@{ $restart->{checks} };
		$result->{recheck_failed_checks} = \@still_failed;
		if ( scalar(@still_failed) >= $restart->{threshold} && !defined( $result->{error} ) ) {
			$result->{error} = 'checks still failing after restart: ' . join( ', ', @still_failed );
		}
	} ## end if ( $restart->{check_restart} )

	if ( defined( $result->{error} ) || $result->{exit} != 0 ) {
		my $why = defined( $result->{error} ) ? $result->{error} : 'exit ' . $result->{exit};
		if ( $result->{output} ne '' ) {
			$why = $why . ': ' . $result->{output};
		}
		push( @{ $self->{restart_alerts} }, 'restart "' . $name . '" failed, ' . $why . "\n" );
	}

	if ( $self->{debug} ) {
		warn( 'restart ' . $name . ' exit code is ' . $result->{exit} );
	}

	return;
} ## end sub _run_restart

# Runs a check or restart command with a timeout and returns its results.
# Used by _run_check and _run_restart.
#
# The command is run via open3. Output from stdout and stderr is collected
# until the command exits. It does not wait for the
# pipes to close, as a daemon started by the command may keep them open.
#
# On timeout, if a signal is given, it is sent to the command, and to its
# child processes first if kill_sub_pids is 1. Then the pipes are closed and
# the command is given up on. Without a signal it is left running and if it
# writes again it gets SIGPIPE, or whatever it does to handle the reader
# going away. Either way its exit code is never collected.
#
# Args...
#
#     - command :: The command to run, after variable substitution.
#
#     - timeout :: Seconds to wait before giving up on it.
#
#     - timeout_signal :: Signal name to send on timeout, without the SIG
#       prefix, such as 'TERM'. undef to send nothing.
#
#     - kill_sub_pids :: 1 to also send the signal to all child processes
#       of the command. See _signal_sub_pids.
#
# Returns a hash ref as below.
#
#     - output :: stdout and stderr, with the final newline removed. On
#       timeout, whatever came in before it.
#
#     - exit :: The exit code. 128 plus the signal number if it died on a
#       signal. -1 if it timed out or could not be executed.
#
#     - error :: Only present if it timed out, died on a signal, or could
#       not be executed. On timeout with a signal, says it was sent along
#       with any problems sending it.
#
#     - wait_status :: The raw $? from waitpid, or undef if it timed out or
#       could not be executed.
#
# Example...
#
#     my $result = $self->_run_command( '/usr/sbin/service apache24 restart', 30, undef, 1 );
#     # $result is { output => 'Performing sanity check...', exit => 0, wait_status => 0 }
#
#     my $result = $self->_run_command( '/bin/sleep 60', 1, undef, 1 );
#     # $result is { output => '', exit => -1, error => 'timed out after 1 seconds' }
#
#     my $result = $self->_run_command( '/bin/sleep 60', 1, 'TERM', 1 );
#     # $result is { output => '', exit => -1, error => 'timed out after 1 seconds, sent SIGTERM' }
sub _run_command {
	my ( $self, $command, $timeout, $timeout_signal, $kill_sub_pids ) = @_;

	my %result = ( output => '', exit => -1 );
	my $wait_status;
	my @signal_errors;
	eval {
		my $pid = open3( my $std_in, my $std_out, my $std_err = gensym, $command );
		close($std_in);

		my $select   = IO::Select->new( $std_out, $std_err );
		my $deadline = Time::HiRes::time + $timeout;
		while ( !defined($wait_status) ) {
			my $remaining = $deadline - Time::HiRes::time;
			if ( $remaining <= 0 ) {
				last;
			}

			# wake up at least every 0.1 seconds to see if it has exited
			my $wait = $remaining < 0.1 ? $remaining : 0.1;
			if ( $select->count ) {
				foreach my $handle ( $select->can_read($wait) ) {
					if ( sysread( $handle, my $buffer, 4096 ) ) {
						$result{output} = $result{output} . $buffer;
					} else {
						$select->remove($handle);
					}
				}
			} else {
				select( undef, undef, undef, $wait );
			}

			if ( waitpid( $pid, WNOHANG ) == $pid ) {
				$wait_status = $?;
			}
		} ## end while ( !defined($wait_status) )

		# grab anything left that is ready now, without waiting on pipes held open by others
		if ( defined($wait_status) ) {
			my $drain_deadline = Time::HiRes::time + 1;
			while ( $select->count && Time::HiRes::time < $drain_deadline ) {
				my @ready = $select->can_read(0);
				if ( !defined( $ready[0] ) ) {
					last;
				}
				foreach my $handle (@ready) {
					if ( sysread( $handle, my $buffer, 4096 ) ) {
						$result{output} = $result{output} . $buffer;
					} else {
						$select->remove($handle);
					}
				}
			} ## end while ( $select->count && Time::HiRes::time < $drain_deadline )
		} ## end if ( defined($wait_status) )

		# children first, as once the command is gone they are no longer findable via its PID
		if ( !defined($wait_status) && defined($timeout_signal) ) {
			if ($kill_sub_pids) {
				push( @signal_errors, $self->_signal_sub_pids( $timeout_signal, $pid ) );
			}
			if ( !kill( $timeout_signal, $pid ) ) {
				push( @signal_errors, 'failed to send SIG' . $timeout_signal . ' to ' . $pid . ': ' . $! );
			}
		}

		close($std_out);
		close($std_err);
	};
	if ($@) {
		$result{output} = $@;
		$result{error}  = 'failed to execute';
		chomp( $result{output} );
		return \%result;
	}

	chomp( $result{output} );
	if ( !defined($wait_status) ) {
		$result{error} = 'timed out after ' . $timeout . ' seconds';
		if ( defined($timeout_signal) ) {
			$result{error} = $result{error} . ', sent SIG' . $timeout_signal;
			if ( defined( $signal_errors[0] ) ) {
				$result{error} = $result{error} . ', ' . join( '; ', @signal_errors );
			}
		}
	} elsif ( $wait_status & 127 ) {
		$result{wait_status} = $wait_status;
		$result{exit}  = 128 + ( $wait_status & 127 );
		$result{error} = 'child died with signal ' . ( $wait_status & 127 );
	} else {
		$result{wait_status} = $wait_status;
		$result{exit}        = $wait_status >> 8;
	}

	return \%result;
} ## end sub _run_command

# Sends a signal to every process below a PID, deepest first, so a process
# is signaled before its parent and is not orphaned out of reach. Children
# are found via pgrep -P and signaled via pkill -P. Used on check and
# restart timeouts.
#
# Args...
#
#     - signal :: Signal name without the SIG prefix, such as 'TERM'.
#
#     - pid :: The PID whose children, and their children, get the signal.
#       It is not signaled itself.
#
# Returns a array of problems, each a string, or a empty array if there
# were none. pgrep or pkill finding nothing is not a problem.
#
# Example...
#
#     my @errors = $self->_signal_sub_pids( 'TERM', 12345 );
#     # every process below 12345 got SIGTERM and @errors is ()
#
#     my @errors = $self->_signal_sub_pids( 'TERM', 12345 );
#     # without pgrep installed, @errors is ( 'failed to run pgrep: No such file or directory' )
sub _signal_sub_pids {
	my ( $self, $signal, $pid ) = @_;

	my $pgrep_fh;
	if ( !open( $pgrep_fh, '-|', 'pgrep', '-P', $pid ) ) {
		return ( 'failed to run pgrep: ' . $! );
	}
	my @children;
	while ( my $line = <$pgrep_fh> ) {
		if ( $line =~ /^([0-9]+)\s*$/ ) {
			push( @children, $1 );
		}
	}
	close($pgrep_fh);
	# 1 is nothing found
	if ( ( $? >> 8 ) > 1 || ( $? & 127 ) ) {
		return ( 'pgrep -P ' . $pid . ' failed with wait status ' . $? );
	}

	my @errors;
	foreach my $child (@children) {
		push( @errors, $self->_signal_sub_pids( $signal, $child ) );
	}

	if ( defined( $children[0] ) ) {
		system( 'pkill', '-' . $signal, '-P', $pid );
		if ( $? == -1 ) {
			push( @errors, 'failed to run pkill: ' . $! );
		} elsif ( ( $? >> 8 ) > 1 || ( $? & 127 ) ) {
			push( @errors, 'pkill -' . $signal . ' -P ' . $pid . ' failed with wait status ' . $? );
		}
	}

	return @errors;
} ## end sub _signal_sub_pids


# Decides if a check result counts as failed for a restart. Critical
# always does. Unknown and errored do if the restart does not ignore them.
# Ok and warning never do.
#
# Args...
#
#     - exit :: The exit code of the check, as stored in data.checks.
#
#     - restart :: Hash ref of the restart as returned by the restarts
#       method of Monitoring::Sneck::Config.
#
# Returns 1 if failed, otherwise 0.
#
# Example...
#
#     $self->_check_failed( 2, $restart );    # 1
#     $self->_check_failed( 3, { ignore_unknown => 1, ... } );    # 0
#     $self->_check_failed( 3, { ignore_unknown => 0, ... } );    # 1
sub _check_failed {
	my ( $self, $exit, $restart ) = @_;

	if ( !defined($exit) || $exit == 0 || $exit == 1 ) {
		return 0;
	} elsif ( $exit == 2 ) {
		return 1;
	} elsif ( $exit == 3 ) {
		return $restart->{ignore_unknown} ? 0 : 1;
	}
	return $restart->{ignore_errored} ? 0 : 1;
} ## end sub _check_failed

# Sorts restarts so every restart comes after the ones it depends on.
# Restarts with nothing left to wait on are taken in name order. The
# config has already been checked for cycles.
#
# Args...
#
#     - restarts :: Hash ref as returned by the restarts method of
#       Monitoring::Sneck::Config.
#
# Returns a list of restart names.
#
# Example...
#
#     # a_app depends on z_db
#     my @order = $self->_restart_order($restarts);
#     # @order is ( 'z_db', 'a_app' )
sub _restart_order {
	my ( $self, $restarts ) = @_;

	my %waiting_on;
	my %dependents;
	foreach my $name ( keys( %{$restarts} ) ) {
		$waiting_on{$name} = scalar( @{ $restarts->{$name}{depends} } );
		foreach my $depend ( @{ $restarts->{$name}{depends} } ) {
			push( @{ $dependents{$depend} }, $name );
		}
	}

	my @order;
	my @ready = sort( grep { $waiting_on{$_} == 0 } keys(%waiting_on) );
	while ( defined( $ready[0] ) ) {
		my $name = shift(@ready);
		push( @order, $name );
		foreach my $dependent ( @{ $dependents{$name} || [] } ) {
			$waiting_on{$dependent}--;
			if ( $waiting_on{$dependent} == 0 ) {
				@ready = sort( @ready, $dependent );
			}
		}
	} ## end while ( defined( $ready[0] ) )

	return @order;
} ## end sub _restart_order

# Reads the restart state file. A missing file is a empty state and not a
# error. A file that can not be read or parsed is also used as a empty
# state, so restarts still happen, but a error is returned for
# data.restart_state_error. Entries that are not in the expected form are
# dropped.
#
# Returns a hash ref of restart names to hash refs of last_run, epoch
# seconds of when it last finished, or when it last started if sneck died
# while it was running, and attempts, threshold triggered runs
# since its checks last recovered. Also returns a error string or undef.
#
# Example...
#
#     my ( $state, $error ) = $self->_read_restart_state;
#     # $state is { httpd => { last_run => 1791491419, attempts => 2 } } and $error is undef
sub _read_restart_state {
	my $self = $_[0];

	my $file = $self->{state_file};
	if ( !-e $file ) {
		return ( {}, undef );
	}

	my $decoded;
	eval {
		$decoded = JSON->new->decode( read_file($file) );
	};
	if ($@) {
		my $error = $@;
		chomp($error);
		return ( {}, 'failed to read restart state file "' . $file . '"... ' . $error );
	}
	if ( ref($decoded) ne 'HASH' || ref( $decoded->{restarts} ) ne 'HASH' ) {
		return ( {}, 'restart state file "' . $file . '" is not in the expected format' );
	}

	my %state;
	foreach my $name ( keys( %{ $decoded->{restarts} } ) ) {
		my $item = $decoded->{restarts}{$name};
		if (   ref($item) eq 'HASH'
			&& defined( $item->{last_run} )
			&& $item->{last_run} =~ /^[0-9]+$/
			&& defined( $item->{attempts} )
			&& $item->{attempts} =~ /^[0-9]+$/ )
		{
			$state{$name} = { last_run => $item->{last_run} + 0, attempts => $item->{attempts} + 0 };
		}
	} ## end foreach my $name ( keys( %{ $decoded->{restarts} } ) )

	return ( \%state, undef );
} ## end sub _read_restart_state

# Writes the restart state file. It is written atomically via File::Slurp,
# so a crash never leaves a half written file.
#
# Args...
#
#     - state :: Hash ref as returned by _read_restart_state.
#
# Returns undef on success or a error string.
#
# Example...
#
#     my $error = $self->_write_restart_state( { httpd => { last_run => 1791491419, attempts => 1 } } );
#     # writes {"restarts":{"httpd":{"attempts":1,"last_run":1791491419}}}
sub _write_restart_state {
	my ( $self, $state ) = @_;

	my $file = $self->{state_file};
	eval { write_file( $file, { atomic => 1 }, JSON->new->canonical(1)->encode( { restarts => $state } ) . "\n" ); };
	if ($@) {
		my $error = $@;
		chomp($error);
		return 'failed to write restart state file "' . $file . '"... ' . $error;
	}

	return undef;
} ## end sub _write_restart_state

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
