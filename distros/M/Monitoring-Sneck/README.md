# Monitoring::Sneck

## SYNOPSIS

```
sneck -u [-C <cache file>] [-f <config file>] [-p] [-i] [-d] [-q] [-l|-L] [-P <pid dir>] [-r] [-T <seconds>] [-s <signal>] [-k|-K]

sneck -c [-C <cache file>] [-f <config file>] [-b]

sneck [-f <config file>] [-p] [-i] [-r] [-T <seconds>] [-s <signal>] [-k|-K]

sneck -t [-f <config file>]
```

## FLAGS

The cache file, PID dir, locking, and check timeout settings may also
be set in the config file. Flags override those. See OPTIONS.

### -f config_file

The config file to use.

Files ending in .yaml or .yml are read as YAML, which needs YAML::XS.

Default :: /usr/local/etc/sneck.conf

### -p

Pretty it in a nicely formatted format.

### -C cache_file

The cache file to use.

Overrides `cache_file` in the config.

Default :: /var/cache/sneck.cache

A secondary cache file based on this name is also created. By default
it is /var/cache/sneck.cache.snmp and always holds the GZip+BASE64
compressed version.

### -u

Update the cache file. Will also print the was written to it.

### -c

Print the cache file. Please note that -p or -i won't affect
this as this flag only reads/prints the cache file.

### -b

When used with -c, print the LibreNMS style GZip+BASE64 compressed
cache instead.

### -i

Includes the config file used.

### -d

Print debugging info if called with -u.

### -q

Don't print the results for -u. Exit quietly.

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
same time.

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

Names are made up of `A-Z`, `a-z`, `0-9`, and `_`.

Any other sort of line is an error. Every bad line is reported, along
with its line number.

Variables are used in commands in the form `%NAME%`. A reference to a
variable that is not defined is left as written and produces a warning,
as it may just be part of the command, such as `date +%Y%m%d`. Use `-t`
to see warnings.

Option, variable, check, debug check, and restart names may not be
redefined.

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
```

The first line sets the %ENV variable PATH.

The second is ignored as it is a comment.

The third sets the variable GEOM_DEV to 'foo'

The fourth creates a check named geom_foo that calls check_geom_mirror
with the variable supplied to it being the value specified by the
variable GEOM_DEV.

The fith is a example of an error that will show what will happen when
you call to a file that does not exit.

The sixth line will be ignored as it is blank.

The seventh is a example of another command erroring.

When you run it, you will notice that errors for lines 4 and 5 are
printed to STDERR. For this reason you should use '2> /dev/null' when
calling it from snmpd or '2> /dev/null > /dev/null' when calling from
cron. 

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
debugs:
  routes: netstat -rn
```

- `options` :: Options. See OPTIONS.

- `env` :: Environment variables to set, in sorted name order. Only
  applied if the whole config is valid.

- `vars` :: Variables.

- `checks` :: Checks, with the command as the value.

- `debugs` :: Debug checks, with the command as the value.

- `restarts` :: Restarts, each a mapping of options plus `command`.
  See RESTARTS.

Any other top level key is an error. Any section may be left out or
empty.

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

- `check_timeout` :: Seconds to wait on each check and debug check
  before giving up on it. Works the same as `timeout` for restarts. A
  timeout counts as errored, with a exit of -1. The same as -T.
  Default :: 30

- `check_timeout_signal` :: Signal to send a check on timeout. Works the
  same as `timeout_signal` for restarts. The same as -s.
  Default :: none

- `check_kill_sub_pids` :: If 1, the timeout signal is also sent to all
  child processes of the check. Works the same as `kill_sub_pids` for
  restarts. The same as -k. -K disables it. Takes true and false in YAML.
  Default :: 1

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

## RESTARTS

A restart is a command run when enough of the checks it watches fail.
They only run with -r. Otherwise they are just reported.

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

- `checks` :: Required. The checks to watch. Debug checks can't be
  watched.

- `threshold` :: How many of the watched checks must fail for it to
  trigger. Default :: 1

- `depends` :: Other restarts this one depends on. When both trigger,
  the ones depended on run first. A depend that didn't trigger is
  assumed fine and isn't run. If a depend runs and fails, this one is
  skipped. Cycles are errors.

- `cascade` :: If 1, this also runs when any of its depends ran without
  failing, even if its own threshold wasn't met. Default :: 0

- `ignore_unknown` :: If 0, unknown counts as failed. Default :: 1

- `ignore_errored` :: If 0, errored counts as failed. This is any exit
  other than 0 to 3, dying on a signal, or not being able to run the
  check. Default :: 1

- `min_interval` :: Minimum seconds between runs. 0 turns it off.
  Default :: 180

- `max_retries` :: How many times in a row it will run for its threshold
  before giving up until its checks recover. 0 means always retry. Runs
  from cascade don't count. Default :: 0

- `timeout` :: Seconds to wait on the command before giving up on it.
  On timeout its output pipes are closed and it is left running. Nothing
  is sent to it, but if it writes again it gets SIGPIPE, or whatever it
  does when the reader goes away. A timeout counts as failed, with an
  exit of -1. Default :: 30

- `not_every` :: A maintenance window, as a five field cron spec. While
  local time matches it, the restart doesn't run. Numbers only, no names
  like `sat` or `jan`. Sunday is 0 or 7. If both day of month and day of
  week are given, either matching is enough, same as cron. Restarts
  depending on one held back by this act as if it didn't trigger. Must
  be quoted, such as `not_every="* 2-3 * * 0"`, or in YAML
  `not_every: '* 2-3 * * 0'`. Default :: none

Critical always counts as failed. Ok and warning never do.

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
*/5 * * * * /usr/bin/env PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin  /usr/local/bin/sneck -u 2> /dev/null > /dev/null
```

Most likely want to run it once per polling interval.

You can use it in a non-cached manner with out cron, but this will result in a
longer polling time for LibreNMS or the like when it queries it.

## RETURN HASH/JSON

The generated JSON/hash is as below in jpath notation.

- .data.alert :: 0/1 boolean for if there is a aloert or not.

- .data.ok :: Count of the number of ok checks.

- .data.warning :: Count of the number of warning checks.

- .data.critical :: Count of the number of critical checks.

- .data.unknown :: Count of the number of unkown checks.

- .data.errored :: Count of the number of errored checks.

- .data.alertString :: The cumulative outputs of anything that
  returned a warning, critical, or unknown.

- .data.vars :: A hash with the variables to use.

- .data.time :: Time since epoch.

- .data.time :: The hostname the check was ran on.

- .data.config :: The raw config file if told to include it.

- $hash{data}{run_time} :: How long it took to run all checks.

- .data.restarted :: Count of the number of restarts ran.

- .data.restart_state_error :: Only present if the restart state file
  could not be read or written.

For the following `$name` is the name of the check ran.

- .data.checks.$name :: A hash with info on the checks ran.

- .data.checks.$name.check :: The command pre-variable substitution.

- .data.checks.$name.ran :: The command ran.

- .data.checks.$name.output :: The output of the check.

- .data.checks.$name.exit :: The exit code. 128 plus the signal number if it
  died on a signal. -1 if it timed out or could not be executed.

- .data.checks.$name.error :: Only present if it died on a signal, timed
  out, or could not be executed. Provides a brief description.

- $hash{data}{checks}{$name}{run_time} :: How long it took to run the checks.

For the following `$name` is the name of the debug check ran.

- .data.debugs.$name :: A hash with info on the checks ran.

- .data.debugs.$name.check :: The command pre-variable substitution.

- .data.debugs.$name.ran :: The command ran.

- .data.debugs.$name.output :: The output of the check.

- .data.debugs.$name.exit :: The exit code. 128 plus the signal number if it
  died on a signal. -1 if it timed out or could not be executed.

- .data.debugs.$name.error :: Only present if it died on a signal, timed
  out, or could not be executed. Provides a brief description.

 - $hash{data}{checks}{$name}{run_time} :: How long it took to run the debug.

For the following `$name` is the name of the restart. Every restart has
an entry, even when restarts are disabled.

- .data.restarts.$name.triggered :: 0/1 for if its threshold was met.

- .data.restarts.$name.ran :: 0/1 for if it ran.

- .data.restarts.$name.reason :: Why it did or didn't run. One of
  `threshold`, `cascade from $depend`, `cooldown, $N seconds left`,
  `max retries reached`, `skipped, dependency $depend failed`,
  `maintenance window`, `not triggered`, or `restarts disabled`.

- .data.restarts.$name.failed_checks :: The watched checks that failed.

- .data.restarts.$name.threshold :: The threshold.

- .data.restarts.$name.attempts :: Runs for its threshold since its
  checks last recovered.

- .data.restarts.$name.command :: The command pre-variable substitution.

- .data.restarts.$name.ran_command :: The command ran. Only if it ran.

- .data.restarts.$name.output :: The output. Only if it ran.

- .data.restarts.$name.exit :: The exit code, or -1 if it timed out. Only if
  it ran.

- .data.restarts.$name.error :: Only present if it timed out, died on a
  signal, or could not be executed.

- .data.restarts.$name.run_time :: How long it took. Only if it ran.

## INSTALLING

### FreeBSD

```
pkg install p5-JSON p5-JSON-XS p5-File-Slurp p5-Proc-PID-File p5-DateTime-Event-Cron p5-App-cpanminus
cpanminus Monitoring::Sneck
```

### Debian

```
apt-get install libjson-perl libjson-xs-perl libfile-slurp-perl libproc-pid-file-perl libdatetime-event-cron-perl cpanminus
cpanminus Monitoring::Sneck
```

### YAML Support

For YAML configs, also install YAML::XS.

```
# FreeBSD
pkg install p5-YAML-LibYAML

# Debian
apt-get install libyaml-libyaml-perl
```

### From Src

```
perl Makefile.PL
make
make test
make install
```
