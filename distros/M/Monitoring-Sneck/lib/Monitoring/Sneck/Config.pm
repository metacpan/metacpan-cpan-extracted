package Monitoring::Sneck::Config;

use 5.006;
use strict;
use warnings;
use File::Slurp qw(read_file);
use Config      qw(%Config);

=head1 NAME

Monitoring::Sneck::Config - parses and validates sneck config files

=head1 VERSION

Version 1.6.0

=cut

our $VERSION = '1.6.0';

=head1 SYNOPSIS

    use Monitoring::Sneck::Config;

    my $config;
    eval { $config = Monitoring::Sneck::Config->new( { file => '/usr/local/etc/sneck.conf' } ); };
    if ($@) {
        die($@);
    }

    if ( !$config->is_valid ) {
        foreach my $error ( $config->errors ) {
            print $error->{where} . ': ' . $error->{message} . "\n";
        }
    }

    foreach my $name ( sort keys %{ $config->checks } ) {
        print $name . ' runs ' . $config->substitute( $config->checks->{$name} ) . "\n";
    }

=head1 CONFIG FORMAT

Two formats are supported, the sneck format and YAML. Files ending in
.yaml or .yml are read as YAML, anything else as the sneck format. This
can be overridden via the format arg to new.

The following applies to both.

Names of variables, environment variables, checks, and debug checks are
made up of A-Z, a-z, 0-9, and _.

Variables are used in commands in the form /%+variable_name%+/. A
reference to a variable that is not defined is left as written and
produces a warning, as it may just be part of the command, such as
'date +%Y%m%d'.

Debug checks are the same as checks, but are not counted towards any of
the counts. They exist purely for debugging. A check and a debug check
may share a name.

Commands may not be empty.

Environment variables are only set if the whole config is valid.

=head2 SNECK FORMAT

Each line has leading spaces and tabs removed before it is looked at. A
trailing \r is also removed, so files with CRLF line endings work.

Blank lines are ignored.

Lines starting with # are comments and are ignored.

Lines matching /^[Ee][Nn][Vv]\ [A-Za-z0-9\_]+\=/ set environment
variables. The name is between the space and the first =, the value is
everything after it. The value may be empty. These may be set more than
once, with the last one winning.

Lines matching /^\$[A-Za-z0-9\_]+\=/ are options. The name is between
the $ and the first =, the value is everything after it. See OPTIONS.

Lines matching /^[A-Za-z0-9\_]+\=/ are variables. The name is before the
first =, the value is everything after it. The value may be empty.

Lines matching /^[A-Za-z0-9\_]+\|/ are checks. The name is before the
first |, the command is everything after it with leading whitespace
removed.

Lines matching /^\%[A-Za-z0-9\_]+\|/ are debug checks. The leading % is
not part of the name.

Lines matching /^\@[A-Za-z0-9\_]+\|[^\|]*\|/ are restarts. The name is
between the @ and the first |, the options are between the first and
second |, and the command is everything after the second |, with
leading whitespace removed. Options are separated by spaces or tabs and
are in the form key=value. Values containing spaces or tabs may be
quoted with " or ', such as not_every="* 0-3 * * *". The checks and
depends options are comma separated lists. See RESTARTS.

Any other sort of line is an error.

Option, variable, check, debug check, and restart names may not be
redefined.

=head3 EXAMPLE SNECK CONFIG

    env PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
    # this is a comment
    GEOM_DEV=foo
    geom_foo|/usr/local/libexec/nagios/check_geom mirror %GEOM_DEV%
    does_not_exist|/bin/this_will_error yup... that it will

    does_not_exist_2|/usr/bin/env /bin/this_will_also_error

    #includes route info
    %routes|netstat -rn

    php_check|/usr/local/libexec/nagios/check_procs -C php-fpm -c 1:
    @php_fpm|checks=php_check|/usr/sbin/service php_fpm restart

The first line sets the environment variable PATH.

The second is ignored as it is a comment.

The third sets the variable GEOM_DEV to 'foo'.

The fourth creates a check named geom_foo that calls check_geom with
the value of the variable GEOM_DEV.

The fifth is an example of a check that calls a file that does not
exist.

The sixth line is ignored as it is blank.

The seventh is an example of another command erroring.

The eighth is ignored as it is blank.

The ninth is ignored as it is a comment.

The tenth creates a debug check named routes.

The eleventh is ignored as it is blank.

The twelfth creates a check named php_check.

The thirteenth creates a restart named php_fpm that runs the command
when php_check is critical, if restarts are enabled.

When it is run, errors for the fifth and seventh lines are printed to
STDERR. For this reason, use '2> /dev/null' when calling it from snmpd
or '2> /dev/null > /dev/null' when calling it from cron.

=head2 YAML FORMAT

This needs L<YAML::XS>, which is optional and only loaded when a YAML
config is used.

The top level is a mapping with up to six keys, each of which is a
mapping of names to values.

    - options :: Options. See OPTIONS.

    - env :: Environment variables to set. Set in sorted name order.

    - vars :: Variables.

    - checks :: Checks, with the command as the value.

    - debugs :: Debug checks, with the command as the value.

    - restarts :: Restarts. Each is a mapping of options plus command.
      See RESTARTS.

Any other top level key is an error. Any section may be left out or
empty. An empty file is a valid config with nothing in it.

Values must be strings or numbers. An empty value, such as 'FOO:' or
'FOO: ~', is an empty string for env and vars and an error for checks
and debugs.

YAML::XS turns some unquoted values into something else. 'true' becomes
1 and 'false' becomes a empty string. Quote values like those.

Values starting with % or containing ': ' or ending in ':' must be quoted,
such as '-w 80 -c 1:'.

YAML::XS keeps the last of any duplicate keys without saying anything,
so redefinitions can not be caught like they are in the sneck format.

=head3 EXAMPLE YAML CONFIG

    env:
      PATH: /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
    vars:
      GEOM_DEV: foo
    checks:
      geom_foo: /usr/local/libexec/nagios/check_geom mirror %GEOM_DEV%
      does_not_exist: /bin/this_will_error yup... that it will
      php_check: '/usr/local/libexec/nagios/check_procs -C php-fpm -c 1:'
    debugs:
      routes: netstat -rn
    restarts:
      php_fpm:
        command: /usr/sbin/service php_fpm restart
        checks: [php_check]

=head1 OPTIONS

Options are settings for sneck itself. Options given on the command
line override these. cache_file, pid_dir, and locking are only used by
sneck, not L<Monitoring::Sneck>.

    - cache_file :: The cache file. The same as B<-C> for sneck.
      May not be empty.

    - pid_dir :: The directory for the PID file used for locking. The
      same as B<-P> for sneck. May not be empty.

    - locking :: If 1, locking is enabled. The same as B<-l> for sneck.
      B<-L> disables it. Takes true and false in YAML.

    - check_timeout :: Seconds to wait on each check and debug check
      before giving up on it. Works the same as timeout for restarts.
      A timeout counts as errored, with a exit of -1. The same as B<-T>
      for sneck.
      Default :: 30

    - check_timeout_signal :: Signal to send a check or debug check on
      timeout. Works the same as timeout_signal for restarts. The same
      as B<-s> for sneck.
      Default :: none

    - check_kill_sub_pids :: If 1, the timeout signal is also sent to
      all child processes of the check or debug check. Works the same
      as kill_sub_pids for restarts. The same as B<-k> for sneck. B<-K>
      disables it. Takes true and false in YAML.
      Default :: 1

Any other option is an error.

    $cache_file=/var/db/sneck/sneck.cache
    $pid_dir=/var/run/sneck
    $locking=1
    $check_timeout=60
    $check_timeout_signal=TERM

    options:
      cache_file: /var/db/sneck/sneck.cache
      pid_dir: /var/run/sneck
      locking: true
      check_timeout: 60
      check_timeout_signal: TERM

=head1 RESTARTS

A restart is a command that is run when enough of the checks it watches
fail. Restarts only run when asked for, via the restart option of
L<Monitoring::Sneck> or B<-r> for sneck. Otherwise they are just
reported.

Options are as below.

    - checks :: Required. The checks to watch. Debug checks can not be
      watched.

    - threshold :: How many of the watched checks must fail for it to
      trigger. Must be between 1 and the number of checks.
      Default :: 1

    - depends :: Other restarts this one depends on. When both trigger,
      the ones depended on run first. A depend that did not trigger is
      assumed to be fine and is not run. If a depend runs and fails,
      or was itself skipped for that reason, this one is skipped.
      Dependency cycles are errors.
      Default :: none

    - cascade :: If 1, this also runs when any of its depends ran
      without failing, even if its own threshold was not met.
      Default :: 0

    - ignore_unknown :: If 0, unknown, exit 3, counts as failed.
      Default :: 1

    - ignore_errored :: If 0, errored counts as failed. This is any
      exit other than 0 to 3, dying on a signal, or not being able to
      run the check.
      Default :: 1

    - min_interval :: Minimum seconds from when this restart last
      finished to when it may run again. 0 turns it off.
      Default :: 180

    - max_retries :: How many times in a row it will run for its
      threshold before giving up until its checks recover. 0 means
      always retry. Runs from cascade do not count towards this.
      Default :: 0

    - timeout :: Seconds to wait on the command before giving up on it.
      On timeout its output pipes are closed and it is left running,
      unless timeout_signal is set. If it writes again it gets SIGPIPE,
      or whatever it does when the reader goes away. A timeout counts
      as failed, with a exit of -1.
      Default :: 30

    - timeout_signal :: Signal to send the command on timeout, as a
      name such as TERM or SIGTERM, or a number. 0 is not allowed. It is
      sent to the PID of the command and it is not waited on afterwards.
      If the command has shell metacharacters in it, that PID is the
      /bin/sh running it, so use kill_sub_pids to reach the command.
      Default :: none

    - kill_sub_pids :: If 1, the timeout signal is also sent to all
      child processes of the command, found via pgrep and signaled via
      pkill, deepest first. Does nothing without timeout_signal.
      Default :: 1

    - check_restart :: If 1, its checks are rerun after the command
      finishes and their results replace the earlier ones in what is
      returned. If they still meet the threshold, the restart counts
      as failed, the same as the command failing.
      Default :: 0

    - check_restart_delay :: Seconds to wait after the command finishes
      before rerunning its checks. Does nothing without check_restart.
      Default :: 5

    - not_every :: A maintenance window, as a five field cron spec of
      minute, hour, day of month, month, and day of week. While the
      local time matches it, this restart does not run. Only numbers
      are allowed, no names such as sat or jan. Sunday is 0 or 7. As
      with cron, if both day of month and day of week are given, either
      one matching is enough. Restarts depending on one held back by
      this treat it as if it did not trigger. In the sneck format it
      must be quoted. In YAML it must be quoted if it starts with *.
      Needs L<DateTime::Event::Cron>.
      Default :: none

Critical always counts as failed. Ok and warning never do.

The 0/1 options also take true and false in YAML.

Restart commands get variables put in place the same as checks. A
restart does not wait for its output to be closed once its command has
exited, so a daemon started by it holding stdout open is fine.

The command is also given the environment variables below, describing
why it is running.

    - SNECK_RESTART :: The name of the restart.

    - SNECK_REASON :: Either 'threshold' or 'cascade'.

    - SNECK_CASCADE_FROM :: The depend it cascaded from, or empty.

    - SNECK_FAILED_CHECKS :: Comma separated list of its checks that
      counted as failed. May be empty for a cascade.

    - SNECK_CHECKS :: Comma separated list of the checks it watches.

    - SNECK_THRESHOLD :: The threshold.

    - SNECK_ATTEMPTS :: Runs for its threshold since its checks last
      recovered, this one included.

    @httpd|checks=http_check,php_check threshold=2 depends=php_fpm cascade=1 timeout=60|/usr/sbin/service apache24 restart

    restarts:
      httpd:
        command: /usr/sbin/service apache24 restart
        checks: [http_check, php_check]
        threshold: 2
        depends: [php_fpm]
        cascade: true
        timeout: 60

    @php_fpm|checks=php_check timeout=60 timeout_signal=TERM check_restart=1|/usr/sbin/service php_fpm restart

    restarts:
      php_fpm:
        command: /usr/sbin/service php_fpm restart
        checks: [php_check]
        timeout: 60
        timeout_signal: TERM
        check_restart: true

    @php_fpm|checks=php_check not_every="* 2-3 * * 0"|/usr/sbin/service php_fpm restart

    restarts:
      php_fpm:
        command: /usr/sbin/service php_fpm restart
        checks: [php_check]
        not_every: '* 2-3 * * 0'

The last two never restart between 02:00 and 03:59 on Sundays.

=head1 METHODS

=head2 new

Reads and parses a config.

One argument is taken and that is a hash ref.

    - file :: Path to the config file to read.

    - raw :: The config as a string. Used instead of file if both
      are given.

    - format :: Either 'sneck' or 'yaml'. If not given, a file ending
      in .yaml or .yml is 'yaml' and anything else, including raw, is
      'sneck'.

Dies if neither file nor raw is given, the file can not be read, the
format is unknown, or the format is 'yaml' and YAML::XS can not be
loaded. Problems with the config itself never die. Check them via
is_valid and errors.

    my $config;
    eval { $config = Monitoring::Sneck::Config->new( { file => $file } ); };
    if ($@) {
        die($@);
    }

    my $config = Monitoring::Sneck::Config->new( { raw => "FOO=bar\nfoo_check|/bin/echo %FOO%\n" } );

    my $config = Monitoring::Sneck::Config->new( { raw => "checks:\n  foo_check: /bin/true\n", format => 'yaml' } );

=cut

sub new {
	my %args;
	if ( defined( $_[1] ) ) {
		%args = %{ $_[1] };
	}

	my $self = {
		file     => $args{file},
		raw      => undef,
		format   => 'sneck',
		options  => {},
		vars     => {},
		env      => [],
		checks   => {},
		debugs   => {},
		restarts => {},
		invalid_restarts => {},
		errors   => [],
		warnings => [],
	};
	bless $self;

	if ( defined( $args{format} ) ) {
		if ( $args{format} ne 'sneck' && $args{format} ne 'yaml' ) {
			die( 'Unknown format "' . $args{format} . '"' );
		}
		$self->{format} = $args{format};
	} elsif ( !defined( $args{raw} )
		&& defined( $args{file} )
		&& $args{file} =~ /\.[Yy][Aa]?[Mm][Ll]$/ )
	{
		$self->{format} = 'yaml';
	}

	if ( defined( $args{raw} ) ) {
		$self->{raw} = $args{raw};
	} elsif ( defined( $args{file} ) ) {
		eval { $self->{raw} = read_file( $args{file} ); };
		if ($@) {
			die( 'Failed to read in the config file "' . $args{file} . '"... ' . $@ );
		}
	} else {
		die('Neither file nor raw specified');
	}

	if ( $self->{format} eq 'yaml' ) {
		if ( !eval { require YAML::XS; 1 } ) {
			die( 'YAML::XS is required for YAML configs... ' . $@ );
		}
		$self->_parse_yaml;
	} else {
		$self->_parse_sneck;
	}

	return $self;
} ## end sub new

=head2 file

Returns the path to the config file read or undef if it was created
from a string.

    my $file = $config->file;

=cut

sub file {
	return $_[0]->{file};
}

=head2 format

Returns the format the config was parsed as, either 'sneck' or 'yaml'.

    my $format = $config->format;

=cut

sub format {
	return $_[0]->{format};
}

=head2 raw

Returns the raw config as a string, exactly as read.

    my $raw = $config->raw;

=cut

sub raw {
	return $_[0]->{raw};
}

=head2 is_valid

Returns 1 if the config has no errors, otherwise 0. Warnings do not
affect this.

    if ( !$config->is_valid ) {
        warn('config has errors');
    }

=cut

sub is_valid {
	if ( defined( $_[0]->{errors}[0] ) ) {
		return 0;
	}
	return 1;
}

=head2 errors

Returns a list of errors found in the config. Each is a hash ref as
below.

    - where :: Where the problem is, for printing. For the sneck format
      this is 'line N'. For YAML this is the path to the problem, such
      as 'checks.foo', or 'YAML' for a YAML syntax error.

    - line :: The line number, starting at 1. Undef for YAML.

    - path :: The path to the problem, such as 'checks.foo'. Undef for
      the sneck format.

    - text :: The line as it appears in the file. Undef for YAML.

    - message :: A description of the problem.

For the sneck format these are in line order. For YAML they are in
section order, options, env, vars, checks, debugs, then restarts, then by
name.

    foreach my $error ( $config->errors ) {
        print $error->{where} . ': ' . $error->{message} . "\n";
    }

=cut

sub errors {
	return @{ $_[0]->{errors} };
}

=head2 warnings

Returns a list of warnings found in the config. Same format and order
as errors.

    foreach my $warning ( $config->warnings ) {
        print $warning->{where} . ': ' . $warning->{message} . "\n";
    }

=cut

sub warnings {
	return @{ $_[0]->{warnings} };
}

=head2 options

Returns a hash ref of the options set in the config, with the names as
keys. Options not set are left out, so the caller can fall back to its
own defaults. Invalid ones are also left out. Values are in the
standard form described under validate_option. This is a copy, so
changing it does not change the config.

    my $cache_file = $config->options->{cache_file};

=cut

sub options {
	return { %{ $_[0]->{options} } };
}

=head2 validate_option

Validates a option value and puts it in a standard form, the same as is
done for the config. May be called on the class or a object.

Two arguments are taken, the option name and the value.

Returns two values. The first is the value in standard form or undef if
it is not valid. The second is undef if it is valid or a error message.

The standard forms are as below.

    - locking, check_kill_sub_pids :: 0 or 1.

    - check_timeout :: A number.

    - check_timeout_signal :: The signal name without the SIG prefix,
      such as TERM. Numbers are turned into names.

    my ( $signal, $error ) = Monitoring::Sneck::Config->validate_option( 'check_timeout_signal', 'sigterm' );
    # $signal is 'TERM' and $error is undef

    my ( $timeout, $error ) = Monitoring::Sneck::Config->validate_option( 'check_timeout', 0 );
    # $timeout is undef and $error is 'option "check_timeout" must be a whole number of at least 1'

=cut

sub validate_option {
	my ( $self, $name, $value ) = @_;

	if ( !defined($name) ) {
		return ( undef, 'no option name given' );
	}

	my $label = 'option "' . $name . '"';

	my %known = map { $_ => 1 } ( 'cache_file', 'pid_dir', 'locking', 'check_timeout', 'check_timeout_signal', 'check_kill_sub_pids' );
	if ( !$known{$name} ) {
		return ( undef, 'unknown ' . $label );
	}

	if ( ref($value) ) {
		return ( undef, $label . ' must be a string or number' );
	}

	if ( $name eq 'locking' || $name eq 'check_kill_sub_pids' ) {
		if ( !defined($value) || $value !~ /^[01]?$/ ) {
			return ( undef, $label . ' must be 0 or 1' );
		}
		return ( $value ? 1 : 0, undef );
	}

	if ( $name eq 'check_timeout' ) {
		if ( !defined($value) || $value !~ /^[0-9]+$/ || $value < 1 ) {
			return ( undef, $label . ' must be a whole number of at least 1' );
		}
		return ( $value + 0, undef );
	}

	if ( $name eq 'check_timeout_signal' ) {
		my $signal = $self->_signal_name($value);
		if ( !defined($signal) ) {
			return ( undef, $label . ' must be a signal name or a signal number other than 0' );
		}
		return ( $signal, undef );
	}

	if ( !defined($value) || $value eq '' ) {
		return ( undef, $label . ' may not be empty' );
	}
	return ( $value, undef );
} ## end sub validate_option

=head2 vars

Returns a hash ref of the variables, with the names as keys. This is a
copy, so changing it does not change the config.

    my $value = $config->vars->{GEOM_DEV};

=cut

sub vars {
	return { %{ $_[0]->{vars} } };
}

=head2 env

Returns a array ref of environment variables to set, in the order they
should be set. Each item is a array ref of the name and value. This is
a copy, so changing it does not change the config.

For the sneck format, the order is the order they appear in the config.
For YAML, it is sorted by name.

Nothing is set in %ENV by this module. That is left to the caller.

    foreach my $env ( @{ $config->env } ) {
        $ENV{ $env->[0] } = $env->[1];
    }

=cut

sub env {
	return [ map { [ @{$_} ] } @{ $_[0]->{env} } ];
}

=head2 checks

Returns a hash ref of the checks, with the names as keys and the
commands, before variable substitution, as values. This is a copy, so
changing it does not change the config.

    my $command = $config->checks->{geom_foo};

=cut

sub checks {
	return { %{ $_[0]->{checks} } };
}

=head2 debugs

Returns a hash ref of the debug checks. Same format as checks. The
names do not include the leading % used by the sneck format.

    my $command = $config->debugs->{routes};

=cut

sub debugs {
	return { %{ $_[0]->{debugs} } };
}

=head2 restarts

Returns a hash ref of the restarts, with the names as keys. Each value
is a hash ref with every option filled in, defaults included, as below.
This is a copy, so changing it does not change the config.

    - command :: The command, before variable substitution.

    - checks :: Array ref of the names of the checks watched.

    - depends :: Array ref of the names of the restarts depended on.

    - threshold, cascade, ignore_unknown, ignore_errored, min_interval,
      max_retries, timeout, kill_sub_pids, check_restart,
      check_restart_delay :: As described under
      RESTARTS. The 0/1 options are always 0 or 1.

    - timeout_signal :: The signal name without the SIG prefix, such as
      TERM, or undef if not set. Numbers are turned into names.

    - not_every :: The cron spec with surrounding whitespace removed and
      other runs of whitespace turned into a single space, or undef if
      not set.

    my $threshold = $config->restarts->{httpd}{threshold};

=cut

sub restarts {
	my %restarts;
	foreach my $name ( keys( %{ $_[0]->{restarts} } ) ) {
		if ( $_[0]->{invalid_restarts}{$name} ) {
			next;
		}
		my $restart = $_[0]->{restarts}{$name};
		$restarts{$name} = { %{$restart}, checks => [ @{ $restart->{checks} } ], depends => [ @{ $restart->{depends} } ] };
	}
	return \%restarts;
}

=head2 substitute

Takes a string, usually a check command, and returns it with the
variables put in place. Variables are put in place in sorted name
order. Undefined variables are left as written.

    my $ran = $config->substitute( $config->checks->{geom_foo} );

=cut

sub substitute {
	my $self   = $_[0];
	my $string = $_[1];

	foreach my $var_name ( sort( keys( %{ $self->{vars} } ) ) ) {
		my $value = $self->{vars}{$var_name};
		$string =~ s/%+$var_name%+/$value/g;
	}

	return $string;
}

# Parses $self->{raw} as the sneck format, filling in options, vars, env,
# checks, debugs, restarts, errors, and warnings. Called once by new. Takes no args and
# returns nothing.
#
# Lines are numbered from 1 so errors and warnings can point at them. All
# lines are looked at, so every error is reported, not just the first.
# Errors and warnings are sorted into line order at the end.
#
# Example...
#
#     $self->{raw} = "FOO=bar\nbad line\n";
#     $self->_parse_sneck;
#     # $self->{vars} is { FOO => 'bar' }
#     # $self->{errors} is [ { where => 'line 2', line => 2, path => undef, text => 'bad line',
#     #                        message => '"bad line" is not a understood line' } ]
sub _parse_sneck {
	my $self = $_[0];

	# where each command was defined, for undefined variable warnings
	my %command_locations;

	# options already given, even if invalid, so redefinitions are caught
	my %option_seen;

	my $line_number = 0;
	foreach my $text ( split( /\n/, $self->{raw} ) ) {
		$line_number++;
		$text =~ s/\r$//;

		my $line = $text;
		$line =~ s/^[\ \t]*//;

		my $location = { line => $line_number, text => $text };

		if ( $line eq '' || $line =~ /^#/ ) {
			# blank or comment
			next;
		} elsif ( $line =~ /^[Ee][Nn][Vv]\ ([A-Za-z0-9\_]+)\=(.*)$/ ) {
			push( @{ $self->{env} }, [ $1, $2 ] );
		} elsif ( $line =~ /^\$([A-Za-z0-9\_]+)\=(.*)$/ ) {
			my ( $name, $value ) = ( $1, $2 );
			if ( $option_seen{$name} ) {
				$self->_add_problem( 'errors', $location, 'option "' . $name . '" is redefined' );
				next;
			}
			$option_seen{$name} = 1;
			$self->_add_option( $name, $value, $location );
		} elsif ( $line =~ /^([A-Za-z0-9\_]+)\=(.*)$/ ) {
			my ( $name, $value ) = ( $1, $2 );
			if ( defined( $self->{vars}{$name} ) ) {
				$self->_add_problem( 'errors', $location, 'variable "' . $name . '" is redefined' );
				next;
			}
			$self->{vars}{$name} = $value;
		} elsif ( $line =~ /^(\%?)([A-Za-z0-9\_]+)\|(.*)$/ ) {
			my ( $type, $name, $command ) = ( 'checks', $2, $3 );
			if ( $1 eq '%' ) {
				$type = 'debugs';
			}

			if ( defined( $self->{$type}{$name} ) ) {
				$self->_add_problem( 'errors', $location, $self->_type_label($type) . ' "' . $name . '" is redefined' );
				next;
			}

			if ( $self->_add_command( $type, $name, $command, $location ) ) {
				$command_locations{$type}{$name} = $location;
			}
		} elsif ( $line =~ /^\@([A-Za-z0-9\_]+)\|([^\|]*)\|(.*)$/ ) {
			my ( $name, $options_string, $command ) = ( $1, $2, $3 );

			if ( defined( $self->{restarts}{$name} ) ) {
				$self->_add_problem( 'errors', $location, 'restart "' . $name . '" is redefined' );
				next;
			}

			# options are space separated key=value, with checks and depends being comma separated lists
			my %options;
			my $options_good = 1;
			my ( $option_strings, $unterminated ) = $self->_split_options($options_string);
			if ( defined($unterminated) ) {
				$self->_add_problem( 'errors', $location,
					'restart "' . $name . '" has a unterminated quote in "' . $unterminated . '"' );
				$options_good = 0;
			}
			foreach my $option ( @{$option_strings} ) {
				if ( $option !~ /^([A-Za-z\_]+)\=(.*)$/ ) {
					$self->_add_problem( 'errors', $location,
						'restart "' . $name . '" option "' . $option . '" is not in the form key=value' );
					$options_good = 0;
					next;
				}
				my ( $key, $value ) = ( $1, $2 );
				$value =~ s/\"([^\"]*)\"|\'([^\']*)\'/defined($1) ? $1 : $2/ge;
				if ( exists( $options{$key} ) ) {
					$self->_add_problem( 'errors', $location,
						'restart "' . $name . '" option "' . $key . '" is given more than once' );
					$options_good = 0;
					next;
				}
				if ( $key eq 'checks' || $key eq 'depends' ) {
					$value = [ split( /,/, $value, -1 ) ];
				}
				$options{$key} = $value;
			} ## end foreach my $option ( @{$option_strings} )
			# added even with bad options, so what it references is still checked
			$self->_add_restart( $name, $command, \%options, $location );
			if ( !$options_good ) {
				$self->{invalid_restarts}{$name} = 1;
			}
			$command_locations{restarts}{$name} = $location;
		} else {
			$self->_add_problem( 'errors', $location, '"' . $line . '" is not a understood line' );
		}
	} ## end foreach my $text ( split( /\n/, $self->{raw} ) )

	$self->_validate_restarts( $command_locations{restarts} );
	$self->_warn_undefined_vars( \%command_locations );

	# keep errors and warnings in line order
	@{ $self->{errors} }   = sort { $a->{line} <=> $b->{line} } @{ $self->{errors} };
	@{ $self->{warnings} } = sort { $a->{line} <=> $b->{line} || $a->{message} cmp $b->{message} } @{ $self->{warnings} };

	return;
} ## end sub _parse_sneck

# Splits the options part of a sneck format restart line into its
# individual options. Used by _parse_sneck. Options are separated by spaces
# or tabs, except inside " or ' quotes, which are left in place for the
# caller to remove from the value.
#
# Args...
#
#     - options_string :: The text between the first and second | of a
#       restart line.
#
# Returns a array ref of the option strings, quotes included, followed by
# undef, or by the unparsed rest of the string starting at the first
# quote that was never closed.
#
# Example...
#
#     my ( $options, $unterminated ) = $self->_split_options(' checks=a not_every="* 0-3 * * *"');
#     # $options is [ 'checks=a', 'not_every="* 0-3 * * *"' ] and $unterminated is undef
#
#     ( $options, $unterminated ) = $self->_split_options('checks=a not_every="* 0-3');
#     # $options is [ 'checks=a', 'not_every=' ] and $unterminated is '"* 0-3'
sub _split_options {
	my ( $self, $options_string ) = @_;

	my @options;
	while ( $options_string =~ /\G[\ \t]*((?:[^\ \t\"\']+|\"[^\"]*\"|\'[^\']*\')+)/gc ) {
		push( @options, $1 );
	}

	# anything left besides whitespace starts with a unclosed quote
	if ( $options_string =~ /\G[\ \t]*([^\ \t].*)$/gc ) {
		return ( \@options, $1 );
	}

	return ( \@options, undef );
} ## end sub _split_options

# Parses $self->{raw} as YAML, filling in options, vars, env, checks, debugs,
# restarts, errors, and warnings. Called once by new after YAML::XS has been loaded.
# Takes no args and returns nothing.
#
# YAML::XS gives no line numbers for keys, so problems point at a path
# such as 'checks.foo' instead. A YAML syntax error is a single error with
# the path 'YAML'. Sections are handled in the order options, env, vars,
# checks, debugs, restarts, and names within them in sorted order, so problems come out in
# a stable order.
#
# Example...
#
#     $self->{raw} = "vars:\n  FOO: bar\nchecks:\n  foo_check: /bin/echo %FOO%\nbogus: 1\n";
#     $self->_parse_yaml;
#     # $self->{vars} is { FOO => 'bar' }
#     # $self->{checks} is { foo_check => '/bin/echo %FOO%' }
#     # $self->{errors} is [ { where => 'bogus', line => undef, path => 'bogus', text => undef,
#     #                        message => 'unknown top level key "bogus"' } ]
sub _parse_yaml {
	my $self = $_[0];

	my @documents;
	eval {
		# never let a config create perl objects
		no warnings 'once';
		local $YAML::XS::LoadBlessed = 0;
		@documents = YAML::XS::Load( $self->{raw} );
	};
	if ($@) {
		my $yaml_error = $@;
		$yaml_error =~ s/\s+/ /g;
		$yaml_error =~ s/^\s+|\s+$//g;
		$self->_add_problem( 'errors', { path => 'YAML' }, $yaml_error );
		return;
	}

	# an empty file or one with only comments is an empty config
	if ( !defined( $documents[0] ) ) {
		return;
	}

	if ( defined( $documents[1] ) ) {
		$self->_add_problem( 'errors', { path => 'YAML' }, 'only one YAML document is allowed' );
		return;
	}

	my $config = $documents[0];
	if ( ref($config) ne 'HASH' ) {
		$self->_add_problem( 'errors', { path => 'YAML' }, 'the top level must be a mapping' );
		return;
	}

	my %known_sections = ( options => 1, env => 1, vars => 1, checks => 1, debugs => 1, restarts => 1 );
	foreach my $key ( sort( keys( %{$config} ) ) ) {
		if ( !$known_sections{$key} ) {
			$self->_add_problem( 'errors', { path => $key }, 'unknown top level key "' . $key . '"' );
		}
	}

	# where each command was defined, for undefined variable warnings
	my %command_locations;

	foreach my $section ( 'options', 'env', 'vars', 'checks', 'debugs', 'restarts' ) {
		my $items = $config->{$section};
		if ( !defined($items) ) {
			next;
		}
		if ( ref($items) ne 'HASH' ) {
			$self->_add_problem( 'errors', { path => $section }, 'must be a mapping' );
			next;
		}

		foreach my $name ( sort( keys( %{$items} ) ) ) {
			my $location = { path => $section . '.' . $name };
			my $value    = $items->{$name};

			if ( $name !~ /^[A-Za-z0-9\_]+$/ ) {
				$self->_add_problem( 'errors', $location, 'name "' . $name . '" may only contain A-Z, a-z, 0-9, and _' );
				next;
			}

			# restarts are a mapping of options, with the command being one of them
			if ( $section eq 'restarts' ) {
				$command_locations{restarts}{$name} = $location;
				if ( ref($value) ne 'HASH' ) {
					# still known, so restarts depending on it are not told it does not exist
					$self->_add_problem( 'errors', $location, 'value must be a mapping' );
					$self->{restarts}{$name} = { %{ $self->_restart_defaults }, command => '' };
					$self->{invalid_restarts}{$name} = 1;
					next;
				}
				my %options = %{$value};
				my $command = delete( $options{command} );
				$self->_add_restart( $name, $command, \%options, $location );
				next;
			} ## end if ( $section eq 'restarts' )

			if ( $section eq 'options' ) {
				$self->_add_option( $name, $value, $location );
				next;
			}

			if ( ref($value) ) {
				$self->_add_problem( 'errors', $location, 'value must be a string or number' );
				next;
			}

			if ( $section eq 'env' ) {
				push( @{ $self->{env} }, [ $name, defined($value) ? $value : '' ] );
			} elsif ( $section eq 'vars' ) {
				$self->{vars}{$name} = defined($value) ? $value : '';
			} else {
				if ( $self->_add_command( $section, $name, $value, $location ) ) {
					$command_locations{$section}{$name} = $location;
				}
			}
		} ## end foreach my $name ( sort( keys( %{$items} ) ) )
	} ## end foreach my $section ( 'options', 'env', 'vars', 'checks', 'debugs', 'restarts' )

	$self->_validate_restarts( $command_locations{restarts} );
	$self->_warn_undefined_vars( \%command_locations );

	return;
} ## end sub _parse_yaml

# Validates and adds a option via validate_option. Used by both parsers.
# Records a error if the option is unknown or its value is bad, in which
# case it is not added.
#
# Args...
#
#     - name :: The name of the option, without the leading $ used by the
#       sneck format.
#
#     - value :: The value, as taken by validate_option.
#
#     - location :: Hash ref of where it was defined, as taken by
#       _add_problem.
#
# Returns 1 if it was added or 0 if there was a error.
#
# Example...
#
#     $self->_add_option( 'locking', 1, { line => 2, text => '$locking=1' } );
#     # returns 1 and $self->{options}{locking} is 1
#
#     $self->_add_option( 'pid_dir', '', { path => 'options.pid_dir' } );
#     # returns 0 and adds the error 'option "pid_dir" may not be empty'
sub _add_option {
	my ( $self, $name, $value, $location ) = @_;

	my ( $validated, $error ) = $self->validate_option( $name, $value );
	if ( defined($error) ) {
		$self->_add_problem( 'errors', $location, $error );
		return 0;
	}

	$self->{options}{$name} = $validated;
	return 1;
} ## end sub _add_option

# Adds a check or debug check after making sure it has a command. Leading
# spaces and tabs are removed from the command first. Used by both
# parsers. Records a error if the command is empty.
#
# Args...
#
#     - type :: Either 'checks' or 'debugs'.
#
#     - name :: The name of the check, without any leading %.
#
#     - command :: The command, possibly undef for YAML.
#
#     - location :: Hash ref of where it was defined, as taken by
#       _add_problem.
#
# Returns 1 if it was added or 0 if the command was empty.
#
# Example...
#
#     $self->_add_command( 'checks', 'foo', '  /bin/true', { line => 3, text => 'foo|  /bin/true' } );
#     # returns 1 and $self->{checks}{foo} is '/bin/true'
#
#     $self->_add_command( 'debugs', 'bar', undef, { path => 'debugs.bar' } );
#     # returns 0 and adds the error 'debug check "bar" has no command'
sub _add_command {
	my ( $self, $type, $name, $command, $location ) = @_;

	if ( !defined($command) ) {
		$command = '';
	}
	$command =~ s/^[\ \t]*//;

	if ( $command =~ /^\s*$/ ) {
		$self->_add_problem( 'errors', $location, $self->_type_label($type) . ' "' . $name . '" has no command' );
		return 0;
	}

	$self->{$type}{$name} = $command;
	return 1;
} ## end sub _add_command

# Validates and adds a restart. Leading spaces and tabs are removed from
# the command first. Used by both parsers. Records a error for every
# problem found. Checks and depends are only checked for valid names here.
# Whether they exist is checked by _validate_restarts once everything is
# parsed.
#
# A restart with errors is still added, using the options that were good
# plus defaults, and marked in $self->{invalid_restarts}. That way
# _validate_restarts still checks what it references, and restarts that
# depend on it are not wrongly told it does not exist. The restarts method
# leaves invalid ones out.
#
# Args...
#
#     - name :: The name of the restart.
#
#     - command :: The command to run. For YAML this may be undef or, in
#       error, a reference.
#
#     - options :: Hash ref of options. checks and depends are array refs
#       of names. The rest are scalars. Unknown keys are errors. YAML false
#       comes through as a empty string and is taken as 0.
#
#     - location :: Hash ref of where it was defined, as taken by
#       _add_problem.
#
# Returns 1 if it was valid or 0 if there were any errors.
#
# Example...
#
#     $self->_add_restart( 'httpd', '/usr/sbin/service apache24 restart',
#         { checks => [ 'http_check', 'php_check' ], threshold => 2 }, { line => 5, text => '...' } );
#     # returns 1 and $self->{restarts}{httpd} is
#     # { command => '/usr/sbin/service apache24 restart', checks => [ 'http_check', 'php_check' ],
#     #   depends => [], threshold => 2, cascade => 0, ignore_unknown => 1, ignore_errored => 1,
#     #   min_interval => 180, max_retries => 0, timeout => 30, timeout_signal => undef,
#     #   kill_sub_pids => 1, check_restart => 0, check_restart_delay => 5, not_every => undef }
sub _add_restart {
	my ( $self, $name, $command, $options, $location ) = @_;

	my $label         = 'restart "' . $name . '"';
	my $errors_before = scalar( @{ $self->{errors} } );

	my %restart = %{ $self->_restart_defaults };

	foreach my $key ( sort( keys( %{$options} ) ) ) {
		if ( !exists( $restart{$key} ) ) {
			$self->_add_problem( 'errors', $location, $label . ' has unknown option "' . $key . '"' );
		}
	}

	foreach my $key ( 'checks', 'depends' ) {
		if ( !defined( $options->{$key} ) ) {
			next;
		}
		if ( ref( $options->{$key} ) ne 'ARRAY' ) {
			$self->_add_problem( 'errors', $location, $label . ' option "' . $key . '" must be a list' );
			next;
		}
		my %seen;
		foreach my $item ( @{ $options->{$key} } ) {
			if ( !defined($item) || ref($item) || $item !~ /^[A-Za-z0-9\_]+$/ ) {
				my $shown = defined($item) && !ref($item) ? $item : '';
				$self->_add_problem( 'errors', $location,
					$label . ' option "' . $key . '" has the invalid name "' . $shown . '"' );
				next;
			}
			if ( $seen{$item} ) {
				$self->_add_problem( 'errors', $location,
					$label . ' option "' . $key . '" lists "' . $item . '" more than once' );
				next;
			}
			$seen{$item} = 1;
			push( @{ $restart{$key} }, $item );
		} ## end foreach my $item ( @{ $options->{$key} } )
	} ## end foreach my $key ( 'checks', 'depends' )

	if ( !defined( $options->{checks} )
		|| ( ref( $options->{checks} ) eq 'ARRAY' && !defined( $options->{checks}[0] ) ) )
	{
		$self->_add_problem( 'errors', $location, $label . ' has no checks' );
	}

	foreach my $key ( 'cascade', 'ignore_unknown', 'ignore_errored', 'kill_sub_pids', 'check_restart' ) {
		if ( !exists( $options->{$key} ) ) {
			next;
		}
		my $value = $options->{$key};
		if ( !defined($value) || ref($value) || $value !~ /^[01]?$/ ) {
			$self->_add_problem( 'errors', $location, $label . ' option "' . $key . '" must be 0 or 1' );
			next;
		}
		$restart{$key} = $value ? 1 : 0;
	} ## end foreach my $key ( 'cascade', 'ignore_unknown', 'ignore_errored', 'kill_sub_pids', 'check_restart' )

	if ( exists( $options->{timeout_signal} ) ) {
		my $signal = $self->_signal_name( $options->{timeout_signal} );
		if ( defined($signal) ) {
			$restart{timeout_signal} = $signal;
		} else {
			$self->_add_problem( 'errors', $location,
				$label . ' option "timeout_signal" must be a signal name or a signal number other than 0' );
		}
	}

	if ( exists( $options->{not_every} ) ) {
		my ( $spec, $error ) = $self->_parse_cron( $options->{not_every} );
		if ( defined($error) ) {
			$self->_add_problem( 'errors', $location, $label . ' option "not_every" ' . $error );
		} else {
			$restart{not_every} = $spec;
		}
	}

	my %minimums = ( threshold => 1, min_interval => 0, max_retries => 0, timeout => 1, check_restart_delay => 0 );
	foreach my $key ( sort( keys(%minimums) ) ) {
		if ( !exists( $options->{$key} ) ) {
			next;
		}
		my $value = $options->{$key};
		if ( !defined($value) || ref($value) || $value !~ /^[0-9]+$/ || $value < $minimums{$key} ) {
			$self->_add_problem( 'errors', $location,
				$label . ' option "' . $key . '" must be a whole number of at least ' . $minimums{$key} );
			next;
		}
		$restart{$key} = $value + 0;
	} ## end foreach my $key ( sort( keys(%minimums) ) )

	if ( defined( $restart{checks}[0] ) && $restart{threshold} > scalar( @{ $restart{checks} } ) ) {
		$self->_add_problem( 'errors', $location,
				  $label
				. ' threshold of '
				. $restart{threshold}
				. ' is more than its '
				. scalar( @{ $restart{checks} } )
				. ' checks' );
	}

	if ( ref($command) ) {
		$self->_add_problem( 'errors', $location, $label . ' option "command" must be a string' );
		$command = '';
	} else {
		if ( !defined($command) ) {
			$command = '';
		}
		$command =~ s/^[\ \t]*//;
		if ( $command =~ /^\s*$/ ) {
			$self->_add_problem( 'errors', $location, $label . ' has no command' );
		}
	}

	$restart{command} = $command;
	$self->{restarts}{$name} = \%restart;

	if ( scalar( @{ $self->{errors} } ) > $errors_before ) {
		$self->{invalid_restarts}{$name} = 1;
		return 0;
	}

	return 1;
} ## end sub _add_restart

# Returns the default options for a restart. Used by _add_restart and for
# restarts too broken to parse at all.
#
# Returns a new hash ref each time, with empty checks and depends lists and
# the default for every other option. No command is included.
#
# Example...
#
#     my %restart = %{ $self->_restart_defaults };
#     # $restart{threshold} is 1 and $restart{min_interval} is 180
sub _restart_defaults {
	return {
		checks              => [],
		depends             => [],
		threshold           => 1,
		cascade             => 0,
		ignore_unknown      => 1,
		ignore_errored      => 1,
		min_interval        => 180,
		max_retries         => 0,
		timeout             => 30,
		timeout_signal      => undef,
		kill_sub_pids       => 1,
		check_restart       => 0,
		check_restart_delay => 5,
		not_every           => undef,
	};
} ## end sub _restart_defaults

# Validates a cron spec, as used by not_every, and puts it in a standard
# form. Used by _add_restart. DateTime::Event::Cron is only loaded the
# first time this is called.
#
# Args...
#
#     - spec :: The cron spec from the config. May be undef or, in error,
#       a reference for YAML.
#
# Returns two values. The first is the spec with surrounding whitespace
# removed and other runs of whitespace turned into a single space, or
# undef if it is not valid. The second is undef if it is valid, or the
# end of a error message saying why it is not, to be put after the
# option name.
#
# Example...
#
#     my ( $spec, $error ) = $self->_parse_cron(' *  0-3 * * * ');
#     # $spec is '* 0-3 * * *' and $error is undef
#
#     ( $spec, $error ) = $self->_parse_cron('* 0-30 * * *');
#     # $spec is undef and $error is 'is not a valid cron spec, Field value (30) out of range (0-23)'
sub _parse_cron {
	my ( $self, $spec ) = @_;

	if ( !defined($spec) || ref($spec) ) {
		return ( undef, 'must be a string' );
	}

	$spec =~ s/^\s+|\s+$//g;
	$spec =~ s/\s+/ /g;

	if ( !eval { require DateTime::Event::Cron; 1 } ) {
		return ( undef, 'needs DateTime::Event::Cron, which could not be loaded' );
	}

	my $cron = eval { DateTime::Event::Cron->new_from_cron( cron => $spec ) };
	if ( !defined($cron) ) {
		my $cron_error = $@;
		$cron_error =~ s/\s+at\s+\S+\s+line\s+\d+\.?\s*$//;
		$cron_error =~ s/\s+/ /g;
		$cron_error =~ s/^\s+|\s+$//g;
		$cron_error =~ s/\.$//;
		return ( undef, 'is not a valid cron spec, ' . $cron_error );
	}

	# anything past the fifth field is taken as a crontab command
	if ( defined( $cron->command ) && $cron->command ne '' ) {
		return ( undef, 'is not a valid cron spec, it must have exactly five fields' );
	}

	return ( $spec, undef );
} ## end sub _parse_cron

# Turns a signal given in a config into its name, as used by kill and
# pkill. Known signals come from $Config{sig_name} and $Config{sig_num}, so
# what is accepted matches the OS perl was built for.
#
# Args...
#
#     - signal :: The signal from the config. A name, with or without the
#       SIG prefix and in any case, or a number. undef or a reference is
#       taken as invalid.
#
# Returns the upper case name without the SIG prefix, or undef if it is not
# a known signal or is 0. If a number has more than one name, the first one
# listed by $Config{sig_name} is used.
#
# Example...
#
#     my $signal = $self->_signal_name('sigterm');
#     # $signal is 'TERM'
#
#     my $signal = $self->_signal_name(9);
#     # $signal is 'KILL'
#
#     my $signal = $self->_signal_name(0);
#     # $signal is undef
sub _signal_name {
	my ( $self, $signal ) = @_;

	if ( !defined($signal) || ref($signal) ) {
		return undef;
	}

	my @names   = split( ' ', $Config{sig_name} );
	my @numbers = split( ' ', $Config{sig_num} );
	my %numbers_by_name;
	my %names_by_number;
	foreach my $index ( 0 .. $#names ) {
		$numbers_by_name{ $names[$index] } = $numbers[$index];
		if ( !exists( $names_by_number{ $numbers[$index] } ) ) {
			$names_by_number{ $numbers[$index] } = $names[$index];
		}
	}

	my $name;
	if ( $signal =~ /^[0-9]+$/ ) {
		$name = $names_by_number{ $signal + 0 };
	} else {
		$name = uc($signal);
		$name =~ s/^SIG//;
		if ( !exists( $numbers_by_name{$name} ) ) {
			$name = undef;
		}
	}

	if ( !defined($name) || $numbers_by_name{$name} == 0 ) {
		return undef;
	}

	return $name;
} ## end sub _signal_name

# Checks the restarts against the rest of the config once everything is
# parsed. Records a error for each watched check that does not exist,
# each depend that does not exist, and each restart that is part of a
# dependency cycle.
#
# Args...
#
#     - restart_locations :: Hash ref of restart names to locations, as
#       taken by _add_problem. May be undef if there are no restarts.
#
# Returns nothing.
#
# Example...
#
#     $self->{restarts}{a}{depends} = ['b'];
#     $self->{restarts}{b}{depends} = ['a'];
#     $self->_validate_restarts( { a => { line => 1, text => '...' }, b => { line => 2, text => '...' } } );
#     # adds the errors 'restart "a" has a dependency cycle: a -> b -> a' and
#     # 'restart "b" has a dependency cycle: b -> a -> b'
sub _validate_restarts {
	my ( $self, $restart_locations ) = @_;

	foreach my $name ( sort( keys( %{ $self->{restarts} } ) ) ) {
		my $restart  = $self->{restarts}{$name};
		my $location = $restart_locations->{$name};

		foreach my $check ( @{ $restart->{checks} } ) {
			if ( !defined( $self->{checks}{$check} ) ) {
				my $message = 'restart "' . $name . '" watches unknown check "' . $check . '"';
				if ( defined( $self->{debugs}{$check} ) ) {
					$message = $message . ', debug checks can not be watched';
				}
				$self->_add_problem( 'errors', $location, $message );
			}
		}

		foreach my $depend ( @{ $restart->{depends} } ) {
			if ( !defined( $self->{restarts}{$depend} ) ) {
				$self->_add_problem( 'errors', $location,
					'restart "' . $name . '" depends on unknown restart "' . $depend . '"' );
			}
		}

		my $cycle = $self->_find_dependency_cycle($name);
		if ( defined($cycle) ) {
			$self->_add_problem( 'errors', $location,
				'restart "' . $name . '" has a dependency cycle: ' . join( ' -> ', @{$cycle} ) );
		}
	} ## end foreach my $name ( sort( keys( %{ $self->{restarts} } ) ) )

	return;
} ## end sub _validate_restarts

# Looks for a path through depends that leads from a restart back to
# itself. Depends on unknown restarts are ignored. Searches breadth first,
# so the shortest cycle is found.
#
# Args...
#
#     - start :: The name of the restart to start from.
#
# Returns a array ref of the names in the cycle, starting and ending with
# start, or undef if there is no cycle.
#
# Example...
#
#     # a depends on b, b depends on c, c depends on a
#     my $cycle = $self->_find_dependency_cycle('a');
#     # $cycle is [ 'a', 'b', 'c', 'a' ]
sub _find_dependency_cycle {
	my ( $self, $start ) = @_;

	my %visited;
	my @queue = map { [ $_, [ $start, $_ ] ] } @{ $self->{restarts}{$start}{depends} };
	while ( defined( $queue[0] ) ) {
		my ( $current, $path ) = @{ shift(@queue) };
		if ( $current eq $start ) {
			return $path;
		}
		if ( $visited{$current} || !defined( $self->{restarts}{$current} ) ) {
			next;
		}
		$visited{$current} = 1;
		push( @queue, map { [ $_, [ @{$path}, $_ ] ] } @{ $self->{restarts}{$current}{depends} } );
	}

	return undef;
} ## end sub _find_dependency_cycle

# Records a warning for each undefined variable used by each check, debug
# check, and restart command. Each variable is only warned about once per
# command. Used by both parsers once everything is parsed, as variables
# may be defined after the commands that use them.
#
# Args...
#
#     - command_locations :: Hash ref of 'checks', 'debugs', and
#       'restarts', each a hash ref of names to locations as taken by
#       _add_problem.
#
# Returns nothing.
#
# Example...
#
#     $self->{checks}{foo} = '/bin/echo %NOPE%';
#     $self->_warn_undefined_vars( { checks => { foo => { line => 3, text => 'foo|/bin/echo %NOPE%' } } } );
#     # adds the warning 'check "foo" uses undefined variable "NOPE"' for line 3
sub _warn_undefined_vars {
	my ( $self, $command_locations ) = @_;

	foreach my $type ( 'checks', 'debugs', 'restarts' ) {
		foreach my $name ( sort( keys( %{ $self->{$type} } ) ) ) {
			my $command = $self->{$type}{$name};
			if ( $type eq 'restarts' ) {
				$command = $command->{command};
			}
			my %seen;
			while ( $command =~ /%+([A-Za-z0-9\_]+)(?=%)/g ) {
				my $var_name = $1;
				if ( !defined( $self->{vars}{$var_name} ) && !$seen{$var_name} ) {
					$seen{$var_name} = 1;
					$self->_add_problem( 'warnings', $command_locations->{$type}{$name},
						$self->_type_label($type) . ' "' . $name . '" uses undefined variable "' . $var_name . '"' );
				}
			}
		} ## end foreach my $name ( sort( keys( %{ $self->{$type} } ) ) )
	} ## end foreach my $type ( 'checks', 'debugs', 'restarts' )

	return;
} ## end sub _warn_undefined_vars

# Returns the label used in messages for a type.
#
# Args...
#
#     - type :: Either 'checks', 'debugs', or 'restarts'.
#
# Returns 'check' for 'checks', 'debug check' for 'debugs', and 'restart'
# for 'restarts'.
#
# Example...
#
#     my $label = $self->_type_label('debugs');
#     # $label is 'debug check'
sub _type_label {
	if ( $_[1] eq 'debugs' ) {
		return 'debug check';
	} elsif ( $_[1] eq 'restarts' ) {
		return 'restart';
	}
	return 'check';
}

# Records a error or warning. Returns nothing.
#
# Args...
#
#     - kind :: Either 'errors' or 'warnings'.
#
#     - location :: Hash ref of where the problem is. For the sneck format
#       this has 'line', the line number starting at 1, and 'text', the
#       line as it appears in the file. For YAML this has 'path', such as
#       'checks.foo' or 'YAML'.
#
#     - message :: A description of the problem.
#
# The recorded hash ref has where, line, path, text, and message, as
# described in the POD for errors.
#
# Example...
#
#     $self->_add_problem( 'errors', { line => 4, text => 'foo bar' }, '"foo bar" is not a understood line' );
#     # $self->{errors} now ends with
#     # { where => 'line 4', line => 4, path => undef, text => 'foo bar',
#     #   message => '"foo bar" is not a understood line' }
#
#     $self->_add_problem( 'errors', { path => 'checks.foo' }, 'check "foo" has no command' );
#     # $self->{errors} now ends with
#     # { where => 'checks.foo', line => undef, path => 'checks.foo', text => undef,
#     #   message => 'check "foo" has no command' }
sub _add_problem {
	my ( $self, $kind, $location, $message ) = @_;

	my $where = $location->{path};
	if ( defined( $location->{line} ) ) {
		$where = 'line ' . $location->{line};
	}

	push(
		@{ $self->{$kind} },
		{
			where   => $where,
			line    => $location->{line},
			path    => $location->{path},
			text    => $location->{text},
			message => $message,
		}
	);
	return;
} ## end sub _add_problem

=head1 BUGS

Please report any bugs or feature requests to C<bug-monitoring-sneck at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Monitoring-Sneck>.

=cut

1;    # End of Monitoring::Sneck::Config
