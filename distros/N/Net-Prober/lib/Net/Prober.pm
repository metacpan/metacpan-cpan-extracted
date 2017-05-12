# ABSTRACT: Probes network hosts for downtime, latency, etc...

package Net::Prober;
$Net::Prober::VERSION = '0.16';

use 5.010;
use strict;
use warnings;

use Carp ();
use Data::Dumper ();
use Digest::MD5 ();
use IO::Socket::INET ();
use LWPx::ParanoidAgent ();
use Net::Ping ();
use Time::HiRes ();

use Net::Prober::Probe::Base ();


sub port_name_to_num {
    my ($port) = @_;

    if (defined $port and $port ne "" and $port =~ m{^\D}) {
        $port = (getservbyname($port, "tcp"))[2];
    }

    return $port;
}

sub probe_any {
    my ($class, $args) = @_;
    my $full_pkg = $class;

    # Open up for != Net::Prober::* classes
    if ($full_pkg !~ m{::}) {
        $full_pkg = "Net::Prober::${full_pkg}";
    }

    eval "require $full_pkg; 1" or do {
        Carp::croak("Couldn't load $full_pkg class: $@");
    };

    my $p = $full_pkg->new();
    return $p->probe($args);
}

sub probe_icmp {
    return probe_any('ping', @_);
}

sub probe_ping {
    return probe_any('ping', @_);
}

sub probe_imap {
    return probe_any('imap', @_);
}

sub probe_ssh {
    return probe_any('ssh', @_);
}

sub probe_smtp {
    return probe_any('smtp', @_);
}

sub probe_http {
    return probe_any('http', @_);
}

sub probe_tcp {
    return probe_any('tcp', @_);
}


sub probe {
    my ($probe_type) = @_;

    if (! $probe_type || ref $probe_type ne 'HASH') {
        Carp::croak("Invalid probe data");
    }

    my $host = $probe_type->{host};
    if (! defined $host or $host eq "") {
        Carp::croak("Can't probe undefined host");
    }

    my %probe_args = %{ $probe_type };
    my $class = lc ($probe_args{class} || 'tcp');

    # Resolve port names (http => 80)
    $probe_args{port} = port_name_to_num($probe_args{port});

    my $result = probe_any($class, \%probe_args);

    return $result;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Prober - Probes network hosts for downtime, latency, etc...

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    use Net::Prober;

    my $result = Net::Prober::probe({
        class   => 'tcp',
        port    => 'ssh',
        host    => 'localhost',
        timeout => 3.5,
    });

    # $result = {
    #   ok   => 1,
    #   time => 0.0002345,
    #   host => '127.0.0.1',
    #   port => 22,
    # }

    # or...

    my $result = Net::Prober::probe({
        protocol => 'http',
        host     => 'www.opera.com',
        url      => '/browser',
        match    => 'Faster',
    });

=head1 DESCRIPTION

This module allows to probe hosts for downtime or latency.

You can use it if you want to know things like:

=over 4

=item can we connect to host C<X> on port I<whatever>?

=item how long it takes to connect to host C<X> on port I<whatever>?

=item does host C<X> respond to icmp pings?

=item check if host C<X> responds within a given timeout

=back

Various types of probes are implemented, namely:

=over 4

=item B<tcp>

Opens a socket, connects and closes the socket.

=item B<udp>

Same as TCP, but using a UDP connection.

=item B<http>

Makes an HTTP connection, and requests a given URL (or C</>
if none given). Can check that the content of the response
matches a given regular expression, or has an exact md5 hash.

=back

=head1 NAME

Net::Prober - Probes network hosts for downtime, latency, etc...

=head1 LOGGING TO SYSLOG

It is possible to enable automatic logging to syslog.
It was in fact the default before version C<0.08>.

To do that, include in your script:

    use Net::Prober;
    $Net::Prober::Probe::Base::USE_SYSLOG = 1;

Not very pretty, I know.

=head1 MOTIVATION

There must be tons of ready-made modules that do exactly
what this module tries to do. So why?

One reason is that, as ridiculous as this might sound,
I couldn't find any CPAN module to do this.

For example, I looked at the nagios code, as Nagios
does this (and more) but I couldn't find anything
even remotely similar.

Another reason is that I need this code to be very
compact and flexible enough to be wired directly
to a small config file, to be able to specify
the probe arguments as JSON. This is inspired by
the Varnish probe config block:

    # This is my config file.
    # It's JSON presumably...

    "backends": {
        "1.2.3.4" : {
            "datacenter" : "norway1",
            "probe" : {
                "protocol": "tcp",
                "port" : "8432",
                "timeout" : 1.0,
            },
        },

        # ...
    }

=head1 FUNCTIONS

=head2 C<port_name_to_num($port)>

Converts a given port name (ex.: C<ssh>, or C<http>) to
a number. Returns the number as result.

If the given port doesn't look like a port name,
then you get back what you passed as argument,
unchanged.

=head2 C<probe( \%probe_spec )>

Runs a probe against a given host/port.

C<\%probe_spec> allows you to specify what kind of probe
you want to run and against what hostname and port.

Allowed hash keys are:

=over 4

=item C<protocol>

What type of probe you want to run.
Can be any of C<tcp>, C<http>, C<icmp>.

B<Default is tcp>.

=item C<host>

Hostname or IP to be probed.

=item C<port>

Port or service to be probed.
Examples:

    23, 'ssh', 8432, 'http', 'echo'

=item C<timeout>

The maximum time to wait for a result. In seconds.

=back

Returns the results as hashref. Example:

    my $result = Net::Prober::probe({
        host => 'localhost',
        port => 'ssh',
        protocol => 'tcp',
        timeout => 0.5,
    });

You will get B<at least> these keys:

    $result = {
        ok => 1,
        time => 0.001234,    # how long it took (s)
    }

or in case of failure:

    $result = {
        ok => 0,
        time => 0.001234,
        reason => 'Why the probe failed',
    }

=head3 C<http> probe

The HTTP probe support additional arguments:

=over 4

=item C<match>

Checks if the content matches a given regular expression.
Example:

    match => 'Not found'
    match => 'Log(in|out)'

=item C<md5>

Checks if the whole content of the response matches a given
MD5 hash. B<You can calculate the MD5 of a given URL with>:

    wget -q -O - http://your.url.here | md5sum

=item C<url>

What URL to download. By default it uses C</>.

=item C<up_status_re>

By default, any HTTP response with status 2xx or 3xx (redirect)
will be considered successful. However, it is also possible to specify
your own custom regular expression instead. In this way, you can consider
"healthy" a host that replies to your HTTP probe with a 404 (not found)
or other status code.

Example:

    up_status_re => '^[234]'
    up_status_re => '^30[12]$'

=back

=head3 C<icmp> probe

Uses L<Net::Ping> to perform C<ICMP> probes, that is,
to send a ping packet to the given host and port.

C<size> of ping packets is not currently supported.

C<protocol> is an additional key that allows to specify
whether the pings should be sent via UDP or TCP. Remember
that to send ICMP UDP packets you need root privileges.

B<The ICMP probe code will automatically switch to TCP if the
necessary privileges are not available>.

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Cosimo Streppone.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
