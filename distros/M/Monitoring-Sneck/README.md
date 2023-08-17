# Monitoring::Sneck

## SYNOPSIS

```
sneck -u [-C <cache file>] [-f <config file>] [-p] [-i]

sneck -c [-C <cache file>] [-b]

sneck [-f <config file>] [-p] [-i]
```

## FLAGS

```
-f <config>              Config file to use.
                         Default: /usr/local/etc/sneck.conf

-c                       Print the cache and exit. Requires -u being used previously.

-C                       Cache file.
                         Default: /var/cache/sneck.cache

-b                       base64+gzip the printing of the cache.

-u                       Run and write to cache.

-p                       Pretty print. Does not affect -c.

-i                       Include the raw config in the JSON.

-h                       Print help info.
--help                   Print help info.
-v                       Print version info.
--version                Print version info.
```

## CONFIG FORMAT

White space is always cleared from the start of lines via /^[\t ]*/ for
each file line that is read in.

Blank lines are ignored.

Lines starting with /\#/ are comments lines.

Lines matching /^[A-Za-z0-9\_]+\=/ are variables. Anything before the the
/\=/ is used as the name with everything after being the value.

Lines matching /^[A-Za-z0-9\_]+\|/ are checks to run. Anything before the
/\|/ is the name with everything after command to run.

Any other sort of lines are considered an error.

Variables in the checks are in the form of %%%varaible_name%%%.

Variable names and check names may not be redefined once defined in the config.

### EXAMPLE CONFIG

```
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
# this is a comment
geom_foo|/usr/bin/env PATH=%%%PATH%%% /usr/local/libexec/nagios/check_geom mirror foo
does_not_exist|/bin/this_will_error yup... that it will
 
does_not_exist_2|/usr/bin/env /bin/this_will_also_error
```

The first line creates a variable named path.

The second is ignored as it is a comment.

The third creates a check named geom_foo that calls env with and sets the PATH to the
the variable defined on line 1 and then calls check_geom_mirror.

The fourth is a example of an error that will show what will happen when you call to a
file that does not exist.

The fifth line will be ignored as it is blank.

The sixth is a example of another command erroring.

When you run it, you will notice that errors for lines 4 and 5 are printed to STDERR.
For this reason you should use '2> /dev/null' when calling it from snmpd or
'2> /dev/null > /dev/null' when calling from cron.

## USAGE

snmpd should be configured as below.

```
extend sneck /usr/bin/env PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin /usr/local/bin/sneck -c
```

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

For the following `$name` is the name of the check ran.

- .data.checks.$name :: A hash with info on the checks ran.

- .data.checks.$name.check :: The command pre-variable substitution.

- .data.checks.$name.ran :: The command ran.

- .data.checks.$name.output :: The output of the check.

- .data.checks.$name.exit :: The exit code.

- .data.checks.$name.error :: Only present it died on a signal or
  could not be executed. Provides a brief description.

## INSTALLING

### FreeBSD

```
pkg install p5-JSON p5-File-Slurp p5-MIME-Base64 p5-Gzip-Faster p5-App-cpanminus
cpanminus Monitoring::Sneck
```

### Debian

```
apt-get install zlib1g-dev cpanminus
cpanminus Monitoring::Sneck
```

### From Src

```
perl Makefile.PL
make
make test
make install
```
