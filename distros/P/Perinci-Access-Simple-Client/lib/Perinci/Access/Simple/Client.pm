package Perinci::Access::Simple::Client;

our $DATE = '2017-07-03'; # DATE
our $VERSION = '0.23'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Cwd qw(abs_path);
use Perinci::AccessUtil qw(strip_riap_stuffs_from_res);
use POSIX qw(:sys_wait_h);
use Tie::Cache;
use URI::Split qw(uri_split);
use URI::Escape;

use parent qw(Perinci::Access::Base);

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    # attributes
    $self->{retries}         //= 2;
    $self->{retry_delay}     //= 3;
    $self->{conn_cache_size} //= 32;

    # connection cache, key="tcp:HOST:PORT" OR "unix:ABSPATH" or "pipe:ABSPATH
    # ARGS". value=hash, for tcp & unix {socket=>...} and for pipe {pid=>...,
    # chld_out=>..., chld_in=>...}
    tie my(%conns), 'Tie::Cache', $self->{conn_cache_size};
    $self->{_conns} = \%conns;

    $self;
}

# for older Perinci::Access::Base 0.28-, to remove later
sub _init {}

sub _delete_cache {
    my ($self, $wanted) = @_;
    my $conns = $self->{_conns};
    return unless $conns;

    for my $k ($wanted ? ($wanted) : (keys %$conns)) {
        if ($k =~ /^pipe:/) {
            waitpid($conns->{$k}{pid}, WNOHANG);
        }
        delete $self->{_conns}{$k};
    }
}

sub DESTROY {
    my ($self) = @_;

    #$self->_delete_cache;
}

sub request {
    my $self = shift;
    $self->_parse_or_request('request', @_);
}

sub _parse {
    my $self = shift;
    $self->_parse_or_request('parse2', @_);
}

# which: parse0 = quick parse (for parse_url(), parse2 = more thorough parse
# (for testing)
sub _parse_or_request {
    my ($self, $which, $action, $server_url, $extra) = @_;
    log_trace("=> %s\::request(action=%s, server_url=%s, extra=%s)",
                 __PACKAGE__, $action, $server_url, $extra);
    return [400, "Please specify server_url"] unless $server_url;

    my ($uri,
        $cache_key,
        $host, $port, # tcp
        $path,        # unix & pipe
        $args         # pipe
    );
    my ($srvsch, $srvauth, $srvpath, $srvquery, $srvfrag) =
        uri_split($server_url);
    $srvauth //= "";
    $srvpath //= "";
    return [400, "Please supply only riap+tcp/riap+unix/riap+pipe URL"]
        unless $srvsch =~ /\Ariap\+(tcp|unix|pipe)\z/;
    if ($srvsch eq 'riap+tcp') {
        if ($srvauth =~ m!^(.+):(\d+)$!) {
            ($host, $port) = ($1, $2, $3);
            $uri = $srvpath;
            $cache_key = "tcp:".lc($host).":$port";
        } else {
            return [400, "Invalid riap+tcp URL, please use this format: ".
                "riap+tcp://host:1234 or riap+tcp://host:1234/uri"];
        }
    } elsif ($srvsch eq 'riap+unix') {
        if ($srvpath =~ m!(.+)/(/.*)!) {
            ($path, $uri) = (uri_unescape($1), $2);
        } elsif ($srvpath =~ m!(.+)!) {
            $path = uri_unescape($1);
        }
        unless ($which eq 'parse0') {
            if (defined($path)) {
                my $apath = abs_path($path) or
                    return [500, "Can't find absolute path for $path"];
                $cache_key = "unix:$apath";
            } else {
                return [400, "Invalid riap+unix URL, please use this format: ".
                            ", e.g.: riap+unix:/path/to/unix/socket or ".
                                "riap+unix:/path/to/unix/socket//uri"];
            }
        }
    } elsif ($srvsch eq 'riap+pipe') {
        if ($srvpath =~ m!(.+?)//(.*?)/(/.*)!) {
            ($path, $args, $uri) = (uri_unescape($1), $2, $3);
        } elsif ($srvpath =~ m!(.+?)//(.*)!) {
            ($path, $args) = (uri_unescape($1), $2);
        } elsif ($srvpath =~ m!(.+)!) {
            $path = uri_unescape($1);
            $args = '';
        }
        $args = [map {uri_unescape($_)} split m!/!, $args // ''];
        unless ($which eq 'parse0') {
            if (defined($path)) {
                my $apath = abs_path($path) or
                    return [500, "Can't find absolute path for $path"];
                $cache_key = "pipe:$apath ".join(" ", @$args);
            } else {
                return [400, "Invalid riap+pipe URL, please use this format: ".
                            "riap+pipe:/path/to/prog or ".
                                "riap+pipe:/path/to/prog//arg1/arg2 or ".
                                    "riap+pipe:/path/to/prog//arg1/arg2//uri"];
            }
        }
    }

    my $req;
    my $res;

    unless ($which eq 'parse0') {
        $req = { v=>$self->{riap_version}, action=>$action, %{$extra // {}} };
        $uri ||= $req->{uri}; $req->{uri} //= $uri;
        $res = $self->check_request($req);
        return $res if $res;
    }

    if ($which =~ /parse/) {
        return [200, "OK", {
            args=>$args, host=>$host, path=>$path, port=>$port,
            scheme=>$srvsch, uri=>$uri,
        }];
    }

    log_trace("Parsed URI, scheme=%s, host=%s, port=%s, path=%s, args=%s, ".
                     "uri=%s", $srvsch, $host, $port, $path, $args, $uri);

    require JSON::MaybeXS;
    state $json = JSON::MaybeXS->new->allow_nonref;

    my $attempts = 0;
    my $do_retry;
    my $e;
    while (1) {
        $do_retry = 0;

        my ($in, $out);
        my $cache = $self->{_conns}{$cache_key};
        # check cache staleness
        if ($cache) {
            if ($srvsch =~ /tcp|unix/) {
                if ($cache->{socket}->connected) {
                    $in = $out = $cache->{socket};
                } else {
                    log_info("Stale socket cache (%s), discarded",
                                $cache_key);
                    $cache = undef;
                }
            } else {
                if (kill(0, $cache->{pid})) {
                    $in  = $cache->{chld_out};
                    $out = $cache->{chld_in};
                } else {
                    log_info(
                        "Process (%s) seems dead/unsignalable, discarded",
                        $cache_key);
                    $cache = undef;
                }
            }
        }
        # connect
        if (!$cache) {
            if ($srvsch =~ /tcp|unix/) {
                my $sock;
                if ($srvsch eq 'riap+tcp') {
                    require IO::Socket::INET;
                    $sock = IO::Socket::INET->new(
                        PeerHost => $host,
                        PeerPort => $port,
                        Proto    => 'tcp',
                    );
                } else {
                    use IO::Socket::UNIX;
                    $sock = IO::Socket::UNIX->new(
                        Type => SOCK_STREAM,
                        Peer => $path,
                    );
                }
                $e = $@;
                if ($sock) {
                    $self->{_conns}{$cache_key} = {socket=>$sock};
                    $in = $out = $sock;
                } else {
                    $e = $srvsch eq 'riap+tcp' ?
                        "Can't connect to TCP socket $host:$port: $e" :
                            "Can't connect to Unix socket $path: $e";
                    $do_retry++; goto RETRY;
                }
            } else {
                # taken from Modern::Perl. enable methods on filehandles;
                # unnecessary when 5.14 autoloads them
                require IO::File;
                require IO::Handle;

                require IPC::Open2;

                require String::ShellQuote;
                my $cmd = $path . (@$args ? " " . join(" ", map {
                    String::ShellQuote::shell_quote($_) } @$args) : "");
                log_trace("executing cmd: %s", $cmd);

                # using shell
                #my $pid = IPC::Open2::open2($in, $out, $cmd, @$args);

                # not using shell
                my $pid = IPC::Open2::open2($in, $out, $path, @$args);

                if ($pid) {
                    $self->{_conns}{$cache_key} = {
                        pid=>$pid, chld_out=>$in, chld_in=>$out};
                } else {
                    $e = "Can't open2 $cmd: $!";
                    $do_retry++; goto RETRY;
                }
            }
        }

        my $req_json;
        eval { $req_json = $json->encode($req) };
        $e = $@;
        return [400, "Can't encode request as JSON: $e"] if $e;

        $out->write("j$req_json\015\012");
        log_trace("Sent request to server: %s", $req_json);

        # XXX alarm/timeout
        my $line = $in->getline;
        log_trace("Got line from server: %s", $line);
        if (!$line) {
            $self->_delete_cache($cache_key);
            return [500, "Empty response from server"];
        } elsif ($line !~ /^j(.+)/) {
            $self->_delete_cache($cache_key);
            return [500, "Invalid response line from server: $line"];
        }
        eval { $res = $json->decode($1) };
        $e = $@;
        if ($e) {
            $self->_delete_cache($cache_key);
            return [500, "Invalid JSON response from server: $e"];
        }
        strip_riap_stuffs_from_res($res);
        return $res;

      RETRY:
        if ($do_retry && $attempts++ < $self->{retries}) {
            log_trace("Request failed ($e), waiting to retry #%s...",
                         $attempts);
            sleep $self->{retry_delay};
        } else {
            last;
        }
    }
    return [500, "$e (tried $attempts times)"];
}

sub request_tcp {
    my ($self, $action, $hostport, $extra) = @_;
    $self->request($action, "riap+tcp://$hostport->[0]:$hostport->[1]", $extra);
}

sub request_unix {
    my ($self, $action, $sockpath, $extra) = @_;
    $self->request($action => "riap+unix:" . uri_escape($sockpath), $extra);
}

sub request_pipe {
    my ($self, $action, $cmd, $extra) = @_;
    $self->request($action => "riap+pipe:" . uri_escape($cmd->[0]) . "//" .
                       join("/", map {uri_escape($_)} @$cmd[1..@$cmd-1]),
                   $extra);
}

sub parse_url {
    my ($self, $uri) = @_;

    my $res0 = $self->_parse_or_request('parse0', 'dummy', $uri);
    #use Data::Dump; dd $res0;
    die "Can't parse URL $uri: $res0->[0] - $res0->[1]" unless $res0->[0]==200;
    $res0 = $res0->[2];
    my $res = {proto=>$res0->{scheme}, path=>$res0->{uri}};
    if ($res->{proto} eq 'riap+unix') {
        $res->{unix_sock_path} = $res0->{path};
    } elsif ($res->{proto} eq 'riap+tcp') {
        $res->{host} = $res0->{host};
        $res->{port} = $res0->{port};
    } elsif ($res->{proto} eq 'riap+pipe') {
        $res->{prog_path} = $res0->{path};
        $res->{args} = $res0->{args};
    }

    $res;
}

1;
# ABSTRACT: Riap::Simple client

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Access::Simple::Client - Riap::Simple client

=head1 VERSION

This document describes version 0.23 of Perinci::Access::Simple::Client (from Perl distribution Perinci-Access-Simple-Client), released on 2017-07-03.

=head1 SYNOPSIS

 use Perinci::Access::Simple::Client;
 my $pa = Perinci::Access::Simple::Client->new;

 my $res;

 ## performing Riap requests

 # to request server over TCP
 $res = $pa->request(call => 'riap+tcp://localhost:5678/Foo/Bar/func',
                     {args => {a1=>1, a2=>2}});

 # to request server over Unix socket (separate Unix socket path and Riap
 # request key 'uri' with an extra slash /)
 $res = $pa->request(call => 'riap+unix:/var/run/api.sock//Foo/Bar/func',
                     {args => {a1=>1, a2=>2}});

 # to request "server" (program) over pipe (separate program path and first
 # argument with an extra slash /, then separate each program argument with
 # slashes, finally separate last program argument with Riap request key 'uri'
 # with an extra slash /). Arguments are URL-escaped so they can contain slashes
 # if needed (in the encoded form of %2F).
 $res = $pa->request(call => 'riap+pipe:/path/to/prog//arg1/arg2//Foo/Bar/func',
                     {args => {a1=>1, a2=>2}});

 # an example for riap+pipe, accessing a remote program via SSH client
 use URI::Escape;
 my @cmd = ('ssh', '-T', 'user@host', '/path/to/program', 'first arg', '2nd');
 my $uri = "/Foo/Bar/func";
 $res = $pa->request(call => 'riap+pipe:' .
                             uri_escape($cmd[0]) . '//' .
                             join('/', map { uri_escape($_) } @cmd[1..@cmd-1]) . '/' .
                             $uri,
                     {args => {a1=>1, a2=>2}});

 # helper for riap+tcp
 $res = $pa->request_tcp(call => [$host, $port], \%extra);

 # helper for riap+unix
 $res = $pa->request_unix(call => $sockpath, \%extra);

 # helper for riap+pipe
 my @cmd = ('/path/to/program', 'first arg', '2nd');
 $res = $pa->request_pipe(call => \@cmd, \%extra);

 ## parsing URL

 $res = $pa->parse_url("riap+unix:/var/run/apid.sock//Foo/bar");   # -> {proto=>"riap+unix", path=>"/Foo/bar", unix_sock_path=>"/var/run/apid.sock"}
 $res = $pa->parse_url("riap+tcp://localhost:5000/Foo/bar");       # -> {proto=>"riap+tcp" , path=>"/Foo/bar", host=>"localhost", port=>5000}
 $res = $pa->parse_url("riap+pipe:/path/to/prog//a1/a2//Foo/bar"); # -> {proto=>"riap+pipe", path=>"/Foo/bar", prog_path=>"/path/to/prog", args=>["a1", "a2"]}

=head1 DESCRIPTION

This class implements L<Riap::Simple> client. It supports the 'riap+tcp',
'riap+unix', and 'riap+pipe' schemes for a variety of methods to access the
server: either via TCP (where the server can be on a remote computer), Unix
socket, or a program (where the program can also be on a remote computer, e.g.
accessed via ssh).

=head1 METHODS

=head2 PKG->new(%attrs) => OBJ

Instantiate object. Known attributes:

=over 4

=item * retries => INT (default 2)

Number of retries to do on network failure. Setting it to 0 will disable
retries.

=item * retry_delay => INT (default 3)

Number of seconds to wait between retries.

=back

=head2 $pa->request($action => $server_url, \%extra) => $res

Send Riap request to C<$server_url>.

=head2 $pa->request_tcp($action => [$host, $port], \%extra) => $res

Helper/wrapper for request(), it forms C<$server_url> using:

 "riap+tcp://$host:$port"

You need to specify Riap request key 'uri' in C<%extra>.

=head2 $pa->request_unix($action => $sockpath, \%extra) => $res

Helper/wrapper for request(), it forms C<$server_url> using:

 "riap+unix:" . uri_escape($sockpath)

You need to specify Riap request key 'uri' in C<%extra>.

=head2 $pa->request_pipe($action => \@cmd, \%extra) => $res

Helper/wrapper for request(), it forms C<$server_url> using:

 "riap+pipe:" . uri_escape($cmd[0]) . "//" .
 join("/", map {uri_escape($_)} @cmd[1..@cmd-1])

You need to specify Riap request key 'uri' in C<%extra>.

=head2 $pa->parse_url($server_url) => HASH

=head1 FAQ

=head2 When I use riap+pipe, is the program executed for each Riap request?

No, this module does some caching, so if you call the same program (with the
same arguments) 10 times, the same program will be used and it will receive 10
Riap requests using the L<Riap::Simple> protocol.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-Simple-Client>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Access-Simple-Client>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-Simple-Client>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Access::Simple::Server>

L<Riap::Simple>, L<Riap>, L<Rinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
