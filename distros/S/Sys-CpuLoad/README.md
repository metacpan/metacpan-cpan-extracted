# NAME

Sys::CpuLoad - retrieve system load averages

# VERSION

version 0.32

# SYNOPSIS

```perl
use Sys::CpuLoad 'load';
print '1 min, 5 min, 15 min load average: ',
      join(',', load()), "\n";
```

# DESCRIPTION

This module retrieves the 1 minute, 5 minute, and 15 minute load average
of a machine.

# EXPORTS

## load

This method returns the load average for 1 minute, 5 minutes and 15
minutes as an array.

On Linux, Solaris, FreeBSD, NetBSD and OpenBSD systems, it will make a
call to ["getloadavg"](#getloadavg).

If `/proc/loadavg` is available on non-Cygwin systems, it
will call ["proc\_loadavg"](#proc_loadavg).

Otherwise, it will attempt to parse the output of `uptime`.

On error, it will return an array of `undef` values.

As of v0.29, you can override the default function by changing
`$Sys::CpuLoad::LOAD`:

```perl
use Sys::CpuLoad 'load';

no warnings 'once';

$Sys::CpuLoad::LOAD = 'uptimr';

@load = load();
```

If you are writing code to work on multiple systems, you should use
the `load` function.  But if your code is intended for specific systems,
then you should use the appropriate function.

## getloadavg

This is a wrapper around the system call to `getloadavg`.

If this call is unavailable, or it is fails, it will return `undef`.

Added in v0.22.

## proc\_loadavg

If `/proc/loadavg` is available, it will be used.

If the data cannot be parsed, it will return `undef`.

Added in v0.22.

## uptime

Parse the output of uptime.

If the [uptime](https://metacpan.org/pod/uptime) executable cannot be found, or the output cannot be
parsed, it will return `undef`.

Added in v0.22.

As of v0.24, you can override the executable path by setting
`$Sys::CpuLoad::UPTIME`, e.g.

```perl
use Sys::CpuLoad 'uptime';

no warnings 'once';

$Sys::CpuLoad::UPTIME = '/usr/bin/w';

@load = uptime();
```

# SEE ALSO

[Sys::CpuLoadX](https://metacpan.org/pod/Sys%3A%3ACpuLoadX)

# SOURCE

The development version is on github at [https://github.com/robrwo/Sys-CpuLoad](https://github.com/robrwo/Sys-CpuLoad)
and may be cloned from [git://github.com/robrwo/Sys-CpuLoad.git](git://github.com/robrwo/Sys-CpuLoad.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/Sys-CpuLoad/issues](https://github.com/robrwo/Sys-CpuLoad/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHORS

- Robert Rothenberg <rrwo@cpan.org>
- Clinton Wong <clintdw@cpan.org>

# CONTRIBUTORS

- Slaven Rezić <slaven@rezic.de>
- Victor Wagner
- Dmitry Dorofeev <dima@yasp.com>
- Vincent Lefèvre <vincent@vinc17.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 1999-2002, 2020, 2025 by Clinton Wong <clintdw@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
