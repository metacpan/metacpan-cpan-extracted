package Net::Wait;

use Carp qw( croak );
use Net::EmptyPort qw( wait_port );

our $VERSION = '0.001';

sub import {
    my $package = shift;

    my @tests;
    my %opts = ( timeout => 10 );

    while ( local $_ = shift ) {
        if (/^-verbose$/) {
            $opts{verbose} = 1 and next;
        }

        if (/^-timeout$/) {
            my $timeout = shift;
            croak "Missing value for -timeout when loading $package"
                unless defined $timeout;

            $opts{timeout} = $timeout;
            next;
        }

        if (/^-/) {
            croak "Found unknown option when loading $package: $_";
        }

        push @tests, $_;
    }

    croak "Missing list of host/port pairs when loading $package"
        unless @tests;

    my $limit = '';
    if ( $opts{timeout} > 0 ) {
        $limit = " up to $opts{timeout} second";
        $limit .= 's' if $opts{timeout} != 1;
    }

    for (@tests) {
        my ( $host, $port ) = split /:/, $_, 2;

        croak "Cannot parse host and port from argument to $package: '$_'"
            unless $host && $port;

        warn "Waiting$limit for $_\n" if $opts{verbose};

        wait_port {
            host     => $host,
            port     => $port,
            max_wait => $opts{timeout},
            proto    => 'tcp',
        } or croak "$package timed out while waiting for $_";
    }
}

delete @Net::Wait::{qw( wait_port croak )};

1;

__END__

=encoding UTF-8

=head1 NAME

Net::Wait - Wait on startup until the specified ports are listening

=head1 SYNOPSIS

    # Use as a library
    use Net::Wait -timeout => 10, 'perl.org:80';

    # Or from the command line
    # perl -MNet::Wait=perl.org:80 ...

=head1 DESCRIPTION

When you import Net::Wait, you provide a list of TCP hosts and ports. It
will then block until those ports are listening, or until it times out, in
which case an error will be raised and execution will stop..

It is inspired in interface and functionality by the popular
L<wait-for-it|https://github.com/vishnubob/wait-for-it> Bash script originally
written by Giles Hall, and is in essence a convenience wrapper around
L<Net::EmptyPort::wait_port|Net::EmptyPort/wait_port(%args)>.

Host / port pairs need to be provided as a single string with the host and the
port separated by a colon (C<:>). There are no default values: ports always
need to be specified. If Net::Wait cannot parse these from the input it will
throw an error.

They will be tested in the order they were provided.

=head1 OPTIONS

Net::Wait accepts a number of options before the list of hosts to wait for.
Passing an unknown option will raise a compile-time error, as will providing
an invalid value to any valid option.

=head2 timeout

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

=head2 verbose

    use Net::Wait -verbose, ...;

If present, Net::Wait will print output about what it is waiting for and for
how long it will wait.

Defaults to off, for no output.

=head1 SEE ALSO

=over

=item L<wait-for-it|https://github.com/vishnubob/wait-for-it>

The original bash implementation.

=item L<Net::EmptyPort>

The underlying library used by Net::Wait.

=item L<IO::Socket::PortState>

An older library that also allows to check whether a port is open. The
interface is more limited, but unlike Net::EmptyPort, it has no non-core
dependencies.

=back

=head1 ACKNOWLEDGEMENTS

This module exists because Owen Allsopp thought it would be a good idea.

=head1 COPYRIGHT AND LICENSE

Copyright 2022 José Joaquín Atria

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.
