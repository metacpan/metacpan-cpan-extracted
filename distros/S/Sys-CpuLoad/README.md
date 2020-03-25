# NAME

Sys::CpuLoad - retrieve system load averages

# VERSION

version 0.21

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

On Linux, FreeBSD and OpenBSD systems, it will make a call to `getloadavg`.

If `/proc/loadavg` is available, it will attempt to parse the file.

Otherwise, it will attempt to parse the output of `uptime`.

On error, it will return an array of `undef` values.

# SEE ALSO

[Sys::CpuLoadX](https://metacpan.org/pod/Sys::CpuLoadX)

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

# CONTRIBUTOR

Vincent Lefèvre <vincent@vinc17.net>

# COPYRIGHT AND LICENSE

This software is copyright (c) 1999-2002, 2020 by Clinton Wong <clintdw@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
