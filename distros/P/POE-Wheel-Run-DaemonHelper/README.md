# POE-Wheel-Run-DaemonHelper

Helper for the POE::Wheel::Run for easy controlling logging of
stdout/err as well as restarting with backoff.

A small example.

```perl
use strict;
use warnings;
use POE::Wheel::Run::DaemonHelper;
use POE;

my $program = 'sleep 1; echo test; derp derp derp';

my $dh = POE::Wheel::Run::DaemonHelper->new(
	program           => $program,
	status_syslog     => 1,
	status_print      => 1,
	restart_ctl       => 1,
	status_print_warn => 1,
	# this one will be ignored as the second one is already warning
	status_syslog_warn => 1,
);

$dh->create_session;

POE::Kernel->run();
```

## Install

Requirements...

- POE
- Algorithm::Backoff
- Error::Helper
- Sys::Syslog

Via CPANM

```
cpanm POE::Wheel::Run::DaemonHelper
```

Or source...

```
perl Makefile.PL
make
make test
make install
```
