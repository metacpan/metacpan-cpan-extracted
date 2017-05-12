package Net::HAProxy;
BEGIN {
  $Net::HAProxy::VERSION = '0.001';
}
use Moose;
use Moose::Util::TypeConstraints;
use IO::Socket::UNIX;
use IO::Scalar;
use Text::CSV;
use namespace::autoclean;

subtype 'ReadWritableSocket',
    as 'Str',
    where { -w $_ && -r $_ && -S $_ },
    message { "'$_' is not a read/writable socket." };

has socket => (is => 'ro', isa => 'ReadWritableSocket', required => 1);
has timeout => (is => 'ro', isa => 'Int', default => 1);

# ABSTRACT: control HAProxy through a socket


sub _send_command {
    my ($self, $cmd) = @_;

    my $sock = IO::Socket::UNIX->new(
            Peer => $self->socket,
            Type => SOCK_STREAM,
            Timeout => $self->timeout
        );

    $sock->write("$cmd\n");
    local $/ = undef;
    my $data = (<$sock>);
    $sock->close;

    return $data;
}


sub stats {
    my ($self, $args) = @_;

    my $iid = $args->{iid}  || '-1';
    my $type = $args->{type}     || '-1';
    my $sid = $args->{sid} || '-1';

    my $data = $self->_send_command("show stat $iid $type $sid");

    my $sh = IO::Scalar->new(\$data);

    my $fields = $sh->getline;
    $fields =~ s/^\# //;

    my $csv = Text::CSV->new;
    $csv->parse($fields);
    $csv->column_names(grep { length } $csv->fields);

    my $res = $csv->getline_hr_all($sh); pop @$res;
    return $res;
}



sub info {
    my ($self) = @_;
    my $data = $self->_send_command("show info");

    my $info = {};

    for my $line (split /\n/, $data) {
        chomp $line;
        next unless length $line;
        my ($key, $value) = split /:\s+/, $line;
        $info->{$key} = $value;
    }

    return $info;
}



sub set_weight {
    my ($self, $pxname, $svname, $weight) = @_;

    die "Invalid weight must be between 0 and 100"
        unless $weight > 0 and $weight <= 100;

    my $response = $self->_send_command("enable server $pxname/$svname $weight\%");
    chomp $response;
    die $response if length $response;
}



sub enable_server {
    my ($self, $pxname, $svname) = @_;
    my $response = $self->_send_command("enable server $pxname/$svname");
    chomp $response;
    die $response if length $response;
}


sub disable_server {
    my ($self, $pxname, $svname) = @_;
    my $response = $self->_send_command("disable server $pxname/$svname");
    chomp $response;
    die $response if length $response;
}



sub errors {
    my ($self) = @_;
    return $self->_send_command("show errors");
}


sub sessions {
    my ($self) = @_;
    return  $self->_send_command("show sess");
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Net::HAProxy - control HAProxy through a socket

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Try::Tiny;
    use Net::HAProxy;

    my $haproxy = Net::HAProxy->new(
        socket => '/var/run/haproxy-services.sock',
        timeout => 1 # default
    );

    # dump statistics
    print Dumper $haproxy->stats;

    # specify which statistics to list
    print $haproxy->stats({ iid => 2, sid => 1, type => -1});

    # info about haproxy status
    print Dumper $haproxy->info;

    try {
        $haproxy->enable_server('pxname', 'svname');
    } catch {
        print "Couldn't enable server: $_\n";
    };

    try {
        $haproxy->disable_server('pxname', 'svname');
    } catch {
        print "Couldn't disable server: $_\n";
    };

    try {
        $haproxy->set_weight('pxname', 'svname', 50);
    } catch {
        print "Couldn't set weighting: $_\n";
    };

=head1 METHODS

=head2 stats

Arguments: ({ iid => -1, sid => -1, type => -1})
    sid  => service id, -1 for all services (default).
    iid  => unique proxy id, -1 for all proxies (default).
    type => 1 for frontends, 2 for backends, 4 for servers, -1 for all (default)

    these values can be ORed, for example:
          1 + 2     = 3   -> frontend + backend.
          1 + 2 + 4 = 7   -> frontend + backend + server.

Returns: array of hashes, keys described below

=head2 field descriptions

This field documentation was borrowed from the HAProxy 1.4 docs
    http://haproxy.1wt.eu/download/1.4/doc/configuration.txt

If your using an earlier version of HAProxy this should still work, please check the docs for the right field descriptions
    http://haproxy.1wt.eu/download/1.3/doc/configuration.txt

 act: server is active (server), number of active servers (backend)
 bck: server is backup (server), number of backup servers (backend)
 bin: bytes in
 bout: bytes out
 check_code: layer5-7 code, if available
 check_duration: time in ms took to finish last health check
 check_status: status of last health check, one of:
        UNK     -> unknown
        INI     -> initializing
        SOCKERR -> socket error
        L4OK    -> check passed on layer 4, no upper layers testing enabled
        L4TMOUT -> layer 1-4 timeout
        L4CON   -> layer 1-4 connection problem, for example
                   "Connection refused" (tcp rst) or "No route to host" (icmp)
        L6OK    -> check passed on layer 6
        L6TOUT  -> layer 6 (SSL) timeout
        L6RSP   -> layer 6 invalid response - protocol error
        L7OK    -> check passed on layer 7
        L7OKC   -> check conditionally passed on layer 7, for example 404 with
                   disable-on-404
        L7TOUT  -> layer 7 (HTTP/SMTP) timeout
        L7RSP   -> layer 7 invalid response - protocol error
        L7STS   -> layer 7 response error, for example HTTP 5xx
 chkdown: number of UP->DOWN transitions
 chkfail: number of failed checks
 cli_abrt: number of data transfers aborted by the client
 downtime: total downtime (in seconds)
 dreq: denied requests
 dresp: denied responses
 econ: connection errors
 ereq: request errors
 eresp: response errors (among which srv_abrt)
 hanafail: failed health checks details
 hrsp_1xx: http responses with 1xx code
 hrsp_2xx: http responses with 2xx code
 hrsp_3xx: http responses with 3xx code
 hrsp_4xx: http responses with 4xx code
 hrsp_5xx: http responses with 5xx code
 hrsp_other: http responses with other codes (protocol error)
 iid: unique proxy id
 lastchg: last status change (in seconds)
 lbtot: total number of times a server was selected
 pid: process id (0 for first instance, 1 for second, ...)
 pxname: proxy name
 qcur: current queued requests
 qlimit: queue limit
 qmax: max queued requests
 rate_lim: limit on new sessions per second
 rate_max: max number of new sessions per second
 rate: number of sessions per second over last elapsed second
 req_rate: HTTP requests per second over last elapsed second
 req_rate_max: max number of HTTP requests per second observed
 req_tot: total number of HTTP requests received
 scur: current sessions
 sid: service id (unique inside a proxy)
 slim: sessions limit
 smax: max sessions
 srv_abrt: number of data transfers aborted by the server (inc. in eresp)
 status: status (UP/DOWN/NOLB/MAINT/MAINT(via)...)
 stot: total sessions
 svname: service name (FRONTEND for frontend, BACKEND for backend, any name for server)
 throttle: warm up status
 tracked: id of proxy/server if tracking is enabled
 type (0=frontend, 1=backend, 2=server, 3=socket)
 weight: server weight (server), total weight (backend)
 wredis: redispatches (warning)
 wretr: retries (warning)

=head2 info

returns a hash

=head2 set_weight

Arguments: proxy name (pxname), service name (svname), integer (0-100)

Dies on invalid proxy / service name / weighting

=head2 enable_server

Arguments: proxy name (pxname), service name (svname)

Dies on invalid proxy / service name.

=head2 disable_server

Arguments: proxy name (pxname), service name (svname)

Dies on invalid proxy / service name.

=head2 errors (EXPERIMENTAL)

list errors, currently returns raw response

=head2 sessions (EXPERIMENTAL)

show current sessions currently returns raw response

=head1 AUTHOR

robin edwards <robin.ge@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by robin edwards.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

