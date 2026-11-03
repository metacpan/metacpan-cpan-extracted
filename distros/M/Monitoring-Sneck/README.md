# Monitoring::Sneck

## SYNOPSIS

```
sneck -u [-C <cache file>] [-f <config file>] [-p] [-i] [-d] [-q] [-l|-L] [-P <pid dir>] [-r] [-T <seconds>] [-s <signal>] [-k|-K]

sneck -c [-C <cache file>] [-f <config file>] [-b]

sneck [-f <config file>] [-p] [-i] [-d] [-q] [-r] [-T <seconds>] [-s <signal>] [-k|-K]

sneck -t [-f <config file>]

sneck -h

sneck -v
```

## FLAGS

The cache file, PID dir, locking, and check timeout settings may also
be set in the config file. Flags override those. See OPTIONS.

### -f config_file

The config file to use.

Files ending in .yaml or .yml are read as YAML, which needs YAML::XS.

Default :: /usr/local/etc/sneck.conf

### -p

Pretty print the JSON.

### -C cache_file

The cache file to use.

Overrides `cache_file` in the config.

Default :: /var/cache/sneck.cache

A secondary cache file based on this name is also created. By default
it is /var/cache/sneck.cache.snmp and always holds the GZip+BASE64
compressed version.

Compliance check state, used for `interval`, is kept in the cache file
name with `.compliance` added, so by default
/var/cache/sneck.cache.compliance. It is only used if a compliance
check has a interval.

### -u

Update the cache file. Will also print what was written to it.

### -c

Print the cache file. Please note that -p or -i won't affect
this as this flag only reads/prints the cache file.

If the cache file does not exist or can't be read, error JSON saying
so is printed and it exits 3.

### -b

When used with -c, print the LibreNMS style GZip+BASE64 compressed
cache instead.

### -i

Includes the config file used.

### -d

Print debugging info to stderr.

### -q

Don't print the results. Exit quietly. Meant for use with -u.

### -l

Enable locking for -u so more than one instance can't run at a time.
Overrides `locking` in the config.

The PID file is sneck.pid in the directory set by -P.

### -L

Disable locking, overriding `locking` in the config. Can not be used
with -l.

### -P pid_dir

The directory for the PID file used by -l. The user running sneck must
be able to write to it.

Overrides `pid_dir` in the config.

Default :: /var/run

### -r

Run any restarts whose checks failed. Without this, restarts are only
reported as `restarts disabled`. Meant to be used with -u from cron.
Never use it from snmpd.

Restart state, used for `min_interval` and `max_retries`, is kept in the
cache file name with `.restarts` added, so by default
/var/cache/sneck.cache.restarts.

Use locking with this to make sure two runs can't restart things at the
same time. Without it, a warning saying so is printed to stderr.

### -T seconds

Seconds to wait on each check before giving up on it. Overrides
`check_timeout` in the config.

Default :: 30

### -s signal

Signal to send a check on timeout, such as TERM. Overrides
`check_timeout_signal` in the config. `none` sends no signal, even if
the config sets one.

Default :: none

### -k

Also send the timeout signal to all child processes of a check.
Overrides `check_kill_sub_pids` in the config. Does nothing without a
timeout signal. This is the default.

### -K

Do not send the timeout signal to child processes of a check. Overrides
`check_kill_sub_pids` in the config. Can not be used with -k.

### -t

Test the config file. Prints any errors and warnings, then exits 0 if
there are no errors and 1 if there are or the file can't be read.
Warnings, such as a check using a undefined variable, do not affect the
exit code.

### -h, --help

Print the help.

### -v, --version

Print the version.

## CONFIG FORMAT

The sneck format is described below. Files ending in .yaml or .yml
use the YAML format instead, described under YAML CONFIG.

Each line has leading spaces and tabs removed before it is looked at. A
trailing \r is also removed, so files with CRLF line endings work.

Blank lines are ignored.

Lines starting with # are comments and are ignored.

- `env NAME=value` :: Sets a environment variable. The `env` is case
  insensitive. The value may be empty. These may be set more than once,
  with the last one winning. They are only applied if the whole config
  is valid.

- `$name=value` :: A option. See OPTIONS.

- `NAME=value` :: A variable. The name is before the first =, the value
  is everything after it. The value may be empty.

- `name|command` :: A check. The command is everything after the first
  | with leading whitespace removed. It may not be empty.

- `%name|command` :: A debug check. Same as a check, but not counted
  towards any of the counts. It exists purely for debugging. The leading
  % is not part of the name, so a check and a debug check may share a
  name.

- `@name|options|command` :: A restart. Options are space separated
  `key=value`, with `checks` and `depends` being comma separated lists.
  Values containing spaces may be quoted with `"` or `'`. See RESTARTS.

- `!name|options|command` :: A compliance check. Laid out the same as a
  restart. The options may be empty, but the second | is still needed,
  such as `!foo||/bin/true`. See COMPLIANCE.

Names are made up of `A-Z`, `a-z`, `0-9`, and `_`.

Any other sort of line is an error. Every bad line is reported, along
with its line number.

Variables are used in commands in the form `%NAME%`. A reference to a
variable that is not defined is left as written and produces a warning,
as it may just be part of the command, such as `date +%Y%m%d`. Use `-t`
to see warnings.

Option, variable, check, debug check, compliance check, and restart
names may not be redefined. A compliance check may share a name with a
check or debug check.

Checks, debug checks, and compliance checks starting with `perl:` are
perl checks, run in process. See PERL CHECKS.

## EXAMPLE CONFIG

```
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
```

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
STDERR. For this reason, use `2> /dev/null` when calling it from snmpd
or `2> /dev/null > /dev/null` when calling it from cron.

## YAML CONFIG

YAML configs need YAML::XS, which is optional and only loaded when a
YAML config is used.

```
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
```

- `options` :: Options. See OPTIONS.

- `env` :: Environment variables to set, in sorted name order. Only
  applied if the whole config is valid.

- `vars` :: Variables.

- `checks` :: Checks, with the command as the value.

- `debugs` :: Debug checks, with the command as the value.

- `compliance` :: Compliance checks, each a mapping of options plus
  `command`. See COMPLIANCE.

- `restarts` :: Restarts, each a mapping of options plus `command`.
  See RESTARTS.

Any other top level key is an error. Any section may be left out or
empty. An empty file is a valid config with nothing in it.

Names, variables, and undefined variable warnings work the same as the
sneck format. Errors and warnings point to a path, such as
`checks.geom_foo`, as YAML::XS does not give line numbers.

Values must be strings or numbers. An empty value is an empty string
for `env` and `vars` and an error for `checks` and `debugs`.

Some things to watch for.

- Unquoted `true` becomes 1 and `false` becomes an empty string. Quote
  values like those.

- A value starting with `%` must be quoted, as `%` can't start a plain
  YAML value.

- A value containing `: ` or ending in `:`, such as `-c 1:`, must be
  quoted, or it is read as a mapping.

- Duplicate keys are not caught. YAML::XS silently keeps the last one.

## OPTIONS

Options are settings for sneck itself. Flags override them.

- `cache_file` :: The cache file. The same as -C. May not be empty.

- `pid_dir` :: The directory for the PID file used for locking. The
  same as -P. May not be empty.

- `locking` :: If 1, locking is enabled. The same as -l. -L disables
  it. Takes true and false in YAML.

- `check_timeout` :: Seconds to wait on each check, debug check, and
  compliance check before giving up on it. Compliance checks may
  override it via their `timeout` option. Works the same as `timeout`
  for restarts. A timeout counts as errored, with a exit of -1. The same
  as -T.
  Default :: 30

- `check_timeout_signal` :: Signal to send a check, debug check, or
  compliance check on timeout. Works the same as `timeout_signal` for
  restarts. The same as -s.
  Default :: none

- `check_kill_sub_pids` :: If 1, the timeout signal is also sent to all
  child processes of the check, debug check, or compliance check. Works
  the same as `kill_sub_pids` for restarts. The same as -k. -K disables
  it. Takes true and false in YAML.
  Default :: 1

- `compliance_alert` :: If 1, compliance checks that are not ok and not
  waived also set `.data.alert` and are added to `.data.alertString`.
  Takes true and false in YAML.
  Default :: 0

Any other option is an error.

```
$cache_file=/var/db/sneck/sneck.cache
$pid_dir=/var/run/sneck
$locking=1
$check_timeout=60
$check_timeout_signal=TERM
```

```
options:
  cache_file: /var/db/sneck/sneck.cache
  pid_dir: /var/run/sneck
  locking: true
  check_timeout: 60
  check_timeout_signal: TERM
```

## COMPLIANCE

A compliance check is a nagios style check for how a system is set up,
such as root logins being off or a file having the right mode, rather
than if something is working. They run the same as checks, but are
counted separately and set `.data.compliance_alert` instead of
`.data.alert`. Set the `compliance_alert` option to have them set
`.data.alert` as well.

```
!ssh_no_root|control=CIS-5.2.10 framework=CIS severity=high|sshd -T | grep -qi '^permitrootlogin no$'
!pkg_vulns|control=VULN-1 severity=high interval=86400 timeout=300|/usr/local/libexec/nagios/check_pkg_audit
!telnet_off|control=CIS-2.2.18 framework=CIS waived_until=2026-12-31 waiver="legacy box, ticket 1234"|/usr/local/libexec/sneck/check_telnet_off
```

```
compliance:
  ssh_no_root:
    command: sshd -T | grep -qi '^permitrootlogin no$'
    control: CIS-5.2.10
    framework: CIS
    severity: high
  pkg_vulns:
    command: /usr/local/libexec/nagios/check_pkg_audit
    control: VULN-1
    severity: high
    interval: 86400
    timeout: 300
  telnet_off:
    command: /usr/local/libexec/sneck/check_telnet_off
    control: CIS-2.2.18
    framework: CIS
    waived_until: 2026-12-31
    waiver: legacy box, ticket 1234
```

All options are optional.

- `control` :: The ID of the control it checks, such as CIS-5.2.10.
  Used in place of the name in `.data.compliance_alertString`.
  Default :: none

- `framework` :: The framework the control is from, such as CIS or
  STIG. Ones with a framework also get counts and a score for it under
  `.data.compliance_frameworks`. Default :: none

- `severity` :: One of low, medium, high, or critical, in any case.
  Only used for reporting. It does not change how the exit code is
  counted. Default :: none

- `interval` :: Minimum seconds between runs. Until it is due again,
  the last result is reused and marked as cached. A change to the
  command, after variables are put in place, makes it run right away.
  0 runs it every time. Default :: 0

- `timeout` :: Seconds to wait on it. Works the same as `check_timeout`,
  which is used if this is not set. Default :: `check_timeout`

- `waived_until` :: A date as YYYY-MM-DD. Through the end of that day,
  local time, warning, critical, and unknown count as waived instead.
  Errored is never waived, as that means the check itself is broken.
  Once the date passes, it counts as normal again. Default :: none

- `waiver` :: Why it is waived, such as a ticket number. Needs
  `waived_until`. Default :: none

Restarts can't watch compliance checks.

State for `interval` is kept in the cache file name with `.compliance`
added, so by default /var/cache/sneck.cache.compliance. It is only used
if a compliance check has a interval.

## PERL CHECKS

A check, debug check, or compliance check in the form `perl:$name $args`
runs the check `$name` from
[Monitoring::Sneck::Checks](https://github.com/VVelox/Monitoring-Sneck-Checks)
inside of sneck, instead of starting a program for it. Each is a module,
such as Monitoring::Sneck::Checks::http, whose POD lists its args.

```
www|perl:http -H www.example.org -S -w 1 -c 2
www_cert|perl:https_cert -H www.example.org -w 30 -c 14
!hosts_file|control=LOCAL-1|perl:hosts -e db.example.org=%DB_IP%
```

Variables are put in place first, then the args are split as a shell
would, so quote args with spaces in them.

The name must be a-z, 0-9, and _, starting with a letter, which is
checked along with the args having balanced quotes when the config is
read. Whether the check is there is only known when it is run.

The exit is what the check returns, as for any other command, with two
differences. A exit of -1, which is errored, means the check, or
Monitoring::Sneck::Checks, could not be loaded, such as it not being
installed or the name being base. Running past `check_timeout`, or the
`timeout` of a compliance check, is UNKNOWN, a exit of 3, as nothing is
forked to be killed. Each check passes the timeout on to what it talks
to the network through, so this is rare. `check_timeout_signal` and
`check_kill_sub_pids` do not apply.

Monitoring::Sneck::Checks is optional and only loaded once a perl check
is run.

Restarts can't be perl checks, as they are commands to run, not checks.
A restart command starting with `perl:` is a error. Restarts may watch
perl checks though, and `check_restart` reruns them in process.

## RESTARTS

A restart is a command run when enough of the checks it watches fail.
They only run with -r. Otherwise they are just reported.

The command can't be a perl check. See PERL CHECKS.

```
http_check|/usr/local/libexec/nagios/check_http -H localhost
php_check|/usr/local/libexec/nagios/check_procs -C php-fpm -c 1:
@php_fpm|checks=php_check|/usr/sbin/service php_fpm restart
@httpd|checks=http_check,php_check threshold=2 depends=php_fpm cascade=1 timeout=60|/usr/sbin/service apache24 restart
```

```
restarts:
  php_fpm:
    command: /usr/sbin/service php_fpm restart
    checks: [php_check]
  httpd:
    command: /usr/sbin/service apache24 restart
    checks: [http_check, php_check]
    threshold: 2
    depends: [php_fpm]
    cascade: true
    timeout: 60
```

- `checks` :: Required. The checks to watch. Debug checks and
  compliance checks can't be watched.

- `threshold` :: How many of the watched checks must fail for it to
  trigger. Must be between 1 and the number of checks. Default :: 1

- `depends` :: Other restarts this one depends on. When both trigger,
  the ones depended on run first. A depend that didn't trigger is
  assumed fine and isn't run. If a depend runs and fails, or was itself
  skipped for that reason, this one is skipped. Cycles are errors.
  Default :: none

- `cascade` :: If 1, this also runs when any of its depends ran without
  failing, even if its own threshold wasn't met. Default :: 0

- `ignore_unknown` :: If 0, unknown, exit 3, counts as failed.
  Default :: 1

- `ignore_errored` :: If 0, errored counts as failed. This is any exit
  other than 0 to 3, dying on a signal, or not being able to run the
  check. Default :: 1

- `min_interval` :: Minimum seconds from when this restart last finished
  to when it may run again. 0 turns it off. Default :: 180

- `max_retries` :: How many times in a row it will run for its threshold
  before giving up until its checks recover. 0 means always retry. Runs
  from cascade don't count. Default :: 0

- `timeout` :: Seconds to wait on the command before giving up on it.
  On timeout its output pipes are closed and it is left running, unless
  `timeout_signal` is set. If it writes again it gets SIGPIPE, or
  whatever it does when the reader goes away. A timeout counts as
  failed, with an exit of -1. Default :: 30

- `timeout_signal` :: Signal to send the command on timeout, as a name
  such as TERM or SIGTERM, or a number. 0 is not allowed. It is sent to
  the PID of the command and it is not waited on afterwards. If the
  command has shell metacharacters in it, that PID is the /bin/sh
  running it, so use `kill_sub_pids` to reach the command.
  Default :: none

- `kill_sub_pids` :: If 1, the timeout signal is also sent to all child
  processes of the command, found via pgrep and signaled via pkill,
  deepest first. Does nothing without `timeout_signal`. Default :: 1

- `check_restart` :: If 1, its checks are rerun after the command
  finishes and their results replace the earlier ones in what is
  returned. If they still meet the threshold, the restart counts as
  failed, the same as the command failing. Default :: 0

- `check_restart_delay` :: Seconds to wait after the command finishes
  before rerunning its checks. Does nothing without `check_restart`.
  Default :: 5

- `not_every` :: A maintenance window, as a five field cron spec of
  minute, hour, day of month, month, and day of week. While local time
  matches it, the restart doesn't run. Numbers only, no names like `sat`
  or `jan`. Sunday is 0 or 7. If both day of month and day of week are
  given, either matching is enough, same as cron. Restarts depending on
  one held back by this act as if it didn't trigger. Must be quoted,
  such as `not_every="* 2-3 * * 0"`, or in YAML
  `not_every: '* 2-3 * * 0'`. Default :: none

Critical always counts as failed. Ok and warning never do.

The 0/1 options also take true and false in YAML.

Restart commands get variables put in place the same as checks. A
restart does not wait for its output to be closed once its command has
exited, so a daemon started by it holding stdout open is fine.

The command is also given the environment variables below, describing
why it is running.

- `SNECK_RESTART` :: The name of the restart.

- `SNECK_REASON` :: Either `threshold` or `cascade`.

- `SNECK_CASCADE_FROM` :: The depend it cascaded from, or empty.

- `SNECK_FAILED_CHECKS` :: Comma separated list of its checks that
  counted as failed. May be empty for a cascade.

- `SNECK_CHECKS` :: Comma separated list of the checks it watches.

- `SNECK_THRESHOLD` :: The threshold.

- `SNECK_ATTEMPTS` :: Runs for its threshold since its checks last
  recovered, this one included.

```
@php_fpm|checks=php_check timeout=60 timeout_signal=TERM check_restart=1|/usr/sbin/service php_fpm restart
@php_fpm|checks=php_check not_every="* 2-3 * * 0"|/usr/sbin/service php_fpm restart
```

```
restarts:
  php_fpm:
    command: /usr/sbin/service php_fpm restart
    checks: [php_check]
    timeout: 60
    timeout_signal: TERM
    check_restart: true
    not_every: '* 2-3 * * 0'
```

The last two never restart between 02:00 and 03:59 on Sundays.

A restart that ran and failed sets `.data.alert` and adds a line to
`.data.alertString`, along with any output from the command.

## USAGE

snmpd just needs to print the cache. The simplest way is to cat the
GZip+BASE64 compressed cache, which avoids starting perl at all.

```
extend sneck /bin/cat /var/cache/sneck.cache.snmp
```

sneck -c may be used instead. It reports a missing cache file as error
JSON instead of printing nothing, but has to start perl and read the
config on each poll.

```
extend sneck /usr/bin/env PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin /usr/local/bin/sneck -c
```

If the cache file is changed via `cache_file` or -C, cat its .snmp file
instead, or give -c the same -C.

Then just setup a entry in like cron such as below.

```
*/5 * * * * /usr/bin/env PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin /usr/local/bin/sneck -u 2> /dev/null > /dev/null
```

Most likely want to run it once per polling interval.

You can use it in a non-cached manner with out cron, but this will result in a
longer polling time for LibreNMS or the like when it queries it.

## RETURN HASH/JSON

The generated JSON/hash is as below in jpath notation.

- .data.alert :: 0/1 boolean for if there is a alert or not.

- .data.ok :: Count of the number of ok checks.

- .data.warning :: Count of the number of warning checks.

- .data.critical :: Count of the number of critical checks.

- .data.unknown :: Count of the number of unknown checks.

- .data.errored :: Count of the number of errored checks.

- .data.alertString :: The cumulative outputs of anything that
  returned a warning, critical, or unknown.

- .data.vars :: A hash with the variables to use.

- .data.time :: Time since epoch.

- .data.hostname :: The hostname the check was ran on.

- .data.config :: The raw config file if told to include it.

- .data.run_time :: How long it took to run all checks.

- .data.restarted :: Count of the number of restarts ran.

- .data.restart_state_error :: Only present if the restart state file
  could not be read or written. Restarts still run if it can't be read,
  as if there was no state.

- .data.compliance_ok, .data.compliance_warning,
  .data.compliance_critical, .data.compliance_unknown,
  .data.compliance_errored :: Counts of compliance checks, the same as
  for checks. Waived ones are not included.

- .data.compliance_waived :: Count of compliance checks that were not ok
  but are waived. These are not counted anywhere else.

- .data.compliance_alert :: 0/1 for if any compliance check is not ok
  and not waived. Only sets `.data.alert` as well if the
  `compliance_alert` option is set.

- .data.compliance_alertString :: The outputs of compliance checks that
  are warning, critical, or unknown and not waived, each prefixed with
  the control, or the name if there is none, and the severity, such as
  `[CIS-5.2.10 high] `. Added to `.data.alertString` if the
  `compliance_alert` option is set.

- .data.compliance_score :: Percent of compliance checks that are ok,
  leaving out waived ones, to two decimal places. null if there are none
  to score.

- .data.compliance_frameworks.$framework :: The same counts as above for
  compliance checks with that framework, as ok, warning, critical,
  unknown, errored, waived, and score.

- .data.compliance_state_error :: Only present if the compliance state
  file could not be read or written. Compliance checks are run as if
  there was no state.

For the following `$name` is the name of the check ran.

- .data.checks.$name :: A hash with info on the checks ran.

- .data.checks.$name.check :: The command pre-variable substitution.

- .data.checks.$name.ran :: The command ran.

- .data.checks.$name.output :: The output of the check.

- .data.checks.$name.exit :: The exit code. If it died on a signal, this
  is 128 plus the signal number. If it could not be executed or timed
  out, this is -1. For a perl check, -1 is it not being able to be
  loaded and timing out is 3, see PERL CHECKS.

- .data.checks.$name.error :: Only present if it died on a signal, timed
  out, or could not be executed. Provides a brief description.

- .data.checks.$name.run_time :: How long it took to run the check.

- .data.checks.$name.rechecked_by :: Only present if it was rerun after
  a restart with `check_restart` set. The name of that restart. The rest
  of the results are from the rerun.

For the following `$name` is the name of the debug check ran. Debug
checks are run the same as checks, including `check_timeout`,
`check_timeout_signal`, and `check_kill_sub_pids`.

- .data.debugs.$name :: A hash with info on the checks ran.

- .data.debugs.$name.check :: The command pre-variable substitution.

- .data.debugs.$name.ran :: The command ran.

- .data.debugs.$name.output :: The output of the check.

- .data.debugs.$name.exit :: The exit code. Same as for checks.

- .data.debugs.$name.error :: Only present if it died on a signal, timed
  out, or could not be executed. Provides a brief description.

- .data.debugs.$name.run_time :: How long it took to run the debug.

For the following `$name` is the name of the compliance check. They are
run the same as checks, except `timeout` may override `check_timeout`.

- .data.compliance.$name.check, ran, output, exit, error, run_time ::
  The same as for checks. For a cached result, these are from when it
  last ran.

- .data.compliance.$name.last_ran :: Time since epoch of when it last
  started running.

- .data.compliance.$name.cached :: 0/1 for if this is a earlier result
  reused because of `interval`.

- .data.compliance.$name.waived :: 0/1 for if it is not ok and counted
  as waived. Errored is never waived.

- .data.compliance.$name.control, framework, severity, waived_until,
  waiver :: Only present if set in the config.

For the following `$name` is the name of the restart. Every restart has
an entry, even when restarts are disabled.

- .data.restarts.$name.triggered :: 0/1 for if enough of its checks
  failed to meet its threshold.

- .data.restarts.$name.ran :: 0/1 for if it ran.

- .data.restarts.$name.reason :: Why it did or didn't run. One of
  `threshold`, `cascade from $depend`, `cooldown, $N seconds left`,
  `max retries reached`, `skipped, dependency $depend failed`,
  `maintenance window`, `not triggered`, or `restarts disabled`.

- .data.restarts.$name.failed_checks :: Array of the watched checks that
  counted as failed.

- .data.restarts.$name.threshold :: The threshold.

- .data.restarts.$name.attempts :: Runs for its threshold since its
  checks last recovered.

- .data.restarts.$name.command :: The command pre-variable substitution.

The rest are only present if it ran.

- .data.restarts.$name.ran_command :: The command ran.

- .data.restarts.$name.output :: The output of the command.

- .data.restarts.$name.exit :: The exit code. Same as for checks.

- .data.restarts.$name.error :: Only present if it timed out, died on a
  signal, or could not be executed. If it timed out and `timeout_signal`
  is set, also says the signal was sent, plus any problems sending it.
  Also present if `check_restart` is set and its checks still met the
  threshold afterwards, unless one of the above already set it.

- .data.restarts.$name.run_time :: How long the command took to run, not
  counting `check_restart`.

- .data.restarts.$name.recheck_failed_checks :: Only present if
  `check_restart` is set. Array of the watched checks that still counted
  as failed when rerun.

A restart that ran and failed, including timing out or its checks still
failing with `check_restart`, sets `.data.alert` and adds a line to
`.data.alertString` along with any output from the command. Check
results, counts, and `.data.alertString` reflect any checks rerun by
`check_restart`.

## INSTALLING

### FreeBSD

```
pkg install p5-JSON p5-JSON-XS p5-File-Slurp p5-Proc-PID-File p5-DateTime-Event-Cron p5-App-cpanminus
cpanm Monitoring::Sneck
```

### Debian

```
apt-get install libjson-perl libjson-xs-perl libfile-slurp-perl libproc-pid-file-perl libdatetime-event-cron-perl cpanminus
cpanm Monitoring::Sneck
```

### YAML Support

For YAML configs, also install YAML::XS.

```
# FreeBSD
pkg install p5-YAML-LibYAML

# Debian
apt-get install libyaml-libyaml-perl
```

### Perl Checks

For perl: checks, run in process instead of as a program, also install
[Monitoring::Sneck::Checks](https://github.com/VVelox/Monitoring-Sneck-Checks).
See PERL CHECKS.

```
www|perl:http -H www.example.org -S -w 1 -c 2
```

### From Source

```
perl Makefile.PL
make
make test
make install
```
