# NAME

Net::Wait - Wait on startup until the specified ports are listening

# SYNOPSIS

    # Use as a library
    use Net::Wait -timeout => 10, 'perl.org:80';

    # Or from the command line
    # perl -MNet::Wait=perl.org:80 ...

# DESCRIPTION

When you import Net::Wait, you provide a list of TCP hosts and ports. It
will then block until those ports are listening, or until it times out, in
which case an error will be raised and execution will stop..

It is inspired in interface and functionality by the popular
[wait-for-it](https://github.com/vishnubob/wait-for-it) Bash script originally
written by Giles Hall, and is in essence a convenience wrapper around
[Net::EmptyPort::wait\_port](https://metacpan.org/pod/Net%3A%3AEmptyPort#wait_port-args).

Host / port pairs need to be provided as a single string with the host and the
port separated by a colon (`:`). There are no default values: ports always
need to be specified. If Net::Wait cannot parse these from the input it will
throw an error.

They will be tested in the order they were provided.

# OPTIONS

Net::Wait accepts a number of options before the list of hosts to wait for.
Passing an unknown option will raise a compile-time error, as will providing
an invalid value to any valid option.

## timeout

    use Net::Wait -timeout => $seconds, ...;

Specify the maximum amount of time in seconds that Net::Wait should wait for
before aborting.

The same value will be used for all the provided host/port pairs, and will
apply independently to each of them. If any takes longer than the timeout
to become available, an error will be raised and execution will abort.

If you need different timeouts to apply to different hosts, Net::Wait can be
imported multiple times with different options, since each set of options
will only apply that one time.

Defaults to 10 seconds. Set to a negative value for no timeout.

## verbose

    use Net::Wait -verbose, ...;

If present, Net::Wait will print output about what it is waiting for and for
how long it will wait.

Defaults to off, for no output.

# SEE ALSO

- [wait-for-it](https://github.com/vishnubob/wait-for-it)

    The original bash implementation.

- [Net::EmptyPort](https://metacpan.org/pod/Net%3A%3AEmptyPort)

    The underlying library used by Net::Wait.

- [IO::Socket::PortState](https://metacpan.org/pod/IO%3A%3ASocket%3A%3APortState)

    An older library that also allows to check whether a port is open. The
    interface is more limited, but unlike Net::EmptyPort, it has no non-core
    dependencies.

# ACKNOWLEDGEMENTS

This module exists because Owen Allsopp thought it would be a good idea.

# COPYRIGHT AND LICENSE

Copyright 2022 José Joaquín Atria

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.
