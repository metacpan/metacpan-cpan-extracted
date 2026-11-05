# Proc::Fork::Control

Management front end to Perl's `fork()`.

The module caps how many children a process may run, tracks those
children, and can either block until they exit or return as soon as they
have been started. The interface is a set of exported functions. State
lives in one heap per process.

## Install

```
perl Makefile.PL
make
make test
make install
```

Or with a CPAN client, once the release is on CPAN:

```
cpanm Proc::Fork::Control
```

## Example

In the default blocking mode, `cfork` waits for the child before it
returns. Turn nonblocking mode on when more than one child must run at
the same time. The child cap still applies: `cfork` waits for a free
slot before it forks.

```perl
use Proc::Fork::Control;

cfork_init(25);
cfork_nonblocking(1);

for my $item (@work) {
    cfork(sub {
        # child work
        cfork_exit(0);
    });
}

cfork_nonblocking(0);
cfork_wait();
```

The full interface is in the POD: `perldoc Proc::Fork::Control`.

## Requirements

Perl 5.8 or newer, `POSIX`, and `Time::HiRes`.

## Tests

```
prove -l t
```

`t/01big.t` exercises the public functions and fails if the module emits
a warning.

Build the CPAN distribution with `make dist`. The tarball is
`Proc-Fork-Control-1.7.tar.gz`.

## History

Versions 1.2 through 1.6 were published from CVS. The CVS server is gone.
The git tags `v1.2` through `v1.6` were reconstructed from those release
tarballs. `v1.7` is the first release made from git.

## License

Copyright (C) 2014-2026 Colin Faber

The module source is released under the GNU General Public License,
version 2 ([LICENSE.GPL](LICENSE.GPL)). This distribution also includes
the Artistic License 1.0 ([LICENSE](LICENSE)), as it has since the first
public release.

## Support

Bug reports: <https://github.com/cfaber/Proc-Fork-Control/issues>
