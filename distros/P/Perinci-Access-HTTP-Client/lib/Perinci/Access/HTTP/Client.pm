package Perinci::Access::HTTP::Client;

our $DATE = '2017-07-03'; # DATE
our $VERSION = '0.24'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
use Log::ger;

use Perinci::AccessUtil qw(strip_riap_stuffs_from_res);
use Scalar::Util qw(blessed);

use parent qw(Perinci::Access::Base);

my @logging_levels = keys %Log::ger::Levels;

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);

    # attributes
    $self->{retries}         //= 2;
    $self->{retry_delay}     //= 3;
    unless (defined $self->{log_level}) {
        $self->{log_level} =
            $ENV{TRACE} ? 6 :
                $ENV{DEBUG} ? 5 :
                    $ENV{VERBOSE} ? 4 :
                        $ENV{QUIET} ? 2 :
                            0;
    }
    $self->{log_callback}    //= undef;
    $self->{ssl_cert_file}   //= $ENV{SSL_CERT_FILE};
    $self->{ssl_ca_file}     //= $ENV{SSL_CA_FILE};
    $self->{user}            //= $ENV{PERINCI_HTTP_USER};
    $self->{password}        //= $ENV{PERINCI_HTTP_PASSWORD};

    $self;
}

# for older Perinci::Access::Base 0.28-, to remove later
sub _init {}

sub request {
    my ($self, $action, $server_url, $extra, $copts) = @_;
    $extra //= {};
    $copts //= {};
    log_trace(
        "=> %s\::request(action=%s, server_url=%s, extra=%s)",
        __PACKAGE__, $action, $server_url, $extra);
    return [400, "Please specify server_url"] unless $server_url;
    my $rreq = { v=>$self->{riap_version},
                 action=>$action,
                 ua=>"Perinci/".($Perinci::Access::HTTP::Client::VERSION//"?"),
                 %$extra };
    my $res = $self->check_request($rreq);
    return $res if $res;

    state $json = do {
        require JSON::MaybeXS;
        JSON::MaybeXS->new->allow_nonref;
    };

    state $ua;
    state $callback = sub {
        my ($resp, $ua, $h, $data) = @_;

        # we collect HTTP response body into __buffer first. if __mark is set
        # then we need to separate each log message and response part.
        # otherwise, everything just needs to go to __body.

        #$log->tracef("got resp: %s (%d bytes)", $data, length($data));
        #say sprintf("D:got resp: %s (%d bytes)", $data, length($data));

        if ($ua->{__mark}) {
            $ua->{__buffer} .= $data;
            if ($ua->{__buffer} =~ /\A([lr])(\d+) /) {
                my ($chtype, $chlen) = ($1, $2);
                # not enough data yet
                my $hlen = 1+length($chlen)+1;
                return 1 unless length($ua->{__buffer}) >= $hlen + $chlen;
                my $chdata = substr($ua->{__buffer}, $hlen, $chlen);
                substr($ua->{__buffer}, 0, $hlen+$chlen) = "";
                if ($chtype eq 'l') {
                    if ($self->{log_callback}) {
                        $self->{log_callback}->($chdata);
                    } else {
                        $chdata =~ s/^\[(\w+)\]//;
                        my $level = $1;
                        $level = "error" unless $level ~~ @logging_levels;
                        my $logger_name = "log_$level";
                        no strict 'refs';
                        &{$logger_name}("[$server_url] $chdata");
                    }
                    return 1;
                } elsif ($chtype eq 'r') {
                    $ua->{__body} .= $chdata;
                } else {
                    $ua->{__body} = "[500,\"Unknown chunk type $chtype".
                        "try updating ${\(__PACKAGE__)} version\"]";
                    return 0;
                }
            } else {
                $ua->{__body} = "[500,\"Invalid response from server,".
                    " server is probably using older version of ".
                        "Riap::HTTP server library\"]";
                return 0;
            }
        } else {
            $ua->{__body} .= $data;
        }
    };

    if (!$ua) {
        require LWP::UserAgent;
        $ua = LWP::UserAgent->new(
            ssl_opts => {
                SSL_cert_file => $self->{ssl_cert_file},
                SSL_ca_file   => $self->{ssl_ca_file},
            },
        );
        $ua->env_proxy;
        $ua->set_my_handler(
            "request_send", sub {
                my ($req, $ua, $h) = @_;
                $ua->{__buffer} = "";
                $ua->{__body} = "";
            });
        $ua->set_my_handler(
            "response_header", sub {
                my ($resp, $ua, $h) = @_;
                if ($resp->header('x-riap-logging')) {
                    $ua->{__mark} = 1;
                } else {
                    $ua->{__log_level} = 0;
                }
            });
        $ua->set_my_handler(
            "response_data", $callback);
    }

    my $authuser = $copts->{user}     // $self->{user};
    my $authpass = $copts->{password} // $self->{password};
    if (defined $authuser) {
        require URI;
        my $suri = URI->new($server_url);
        my $host = $suri->host;
        my $port = $suri->port;
        $ua->credentials(
            "$host:$port",
            $self->{realm} // "restricted area",
            $authuser,
            $authpass,
        );
    }

    my $http_req = HTTP::Request->new(POST => $server_url);
    for (keys %$rreq) {
        next if /\A(?:args|fmt|loglevel|_.*)\z/;
        my $hk = "x-riap-$_";
        my $hv = $rreq->{$_};
        if (!defined($hv) || ref($hv)) {
            $hk = "$hk-j-";
            $hv = $json->encode($hv);
        }
        $http_req->header($hk => $hv);
    }
    $ua->{__log_level} = $self->{log_level};
    $http_req->header('x-riap-loglevel' => $ua->{__log_level});
    $http_req->header('x-riap-fmt'      => 'json');

    my %args;
    if ($rreq->{args}) {
        for (keys %{$rreq->{args}}) {
            $args{$_} = $rreq->{args}{$_};
        }
    }
    my $args_s = $json->encode(\%args);
    $http_req->header('Content-Type' => 'application/json');
    $http_req->header('Content-Length' => length($args_s));
    $http_req->content($args_s);

    #use Data::Dump; dd $http_req;

    my $custom_lwp_imp;
    if ($server_url =~ m!\Ahttps?:/[^/]!i) { # XXX we don't support https, rite?
        require LWP::Protocol::http::SocketUnixAlt;
        $custom_lwp_imp = "LWP::Protocol::http::SocketUnixAlt";
    }

    my $attempts = 0;
    my $do_retry;
    my $http_res;
    while (1) {
        $do_retry = 0;

        my $old_imp;
        if ($custom_lwp_imp) {
            $old_imp = LWP::Protocol::implementor("http");
            LWP::Protocol::implementor("http", $custom_lwp_imp);
        }

        eval { $http_res = $ua->request($http_req) };
        my $eval_err = $@;

        if ($old_imp) {
            LWP::Protocol::implementor("http", $old_imp);
        }

        return [500, "Client died: $eval_err"] if $eval_err;

        if ($http_res->code >= 500) {
            log_warn("Network failure (%d - %s), retrying ...",
                        $http_res->code, $http_res->message);
            $do_retry++;
        }

        if ($do_retry && $attempts++ < $self->{retries}) {
            sleep $self->{retry_delay};
        } else {
            last;
        }
    }

    return [500, "Network failure: ".$http_res->code." - ".$http_res->message]
        unless $http_res->is_success;

    # empty __buffer
    $callback->($http_res, $ua, undef, "") if length($ua->{__buffer});

    return [500, "Empty response from server (1)"]
        if !length($http_res->content);
    return [500, "Empty response from server (2)"]
        unless length($ua->{__body});

    eval {
        #say "D:body=$ua->{__body}";
        log_trace("body: %s", $ua->{__body});
        $res = $json->decode($ua->{__body});
    };
    my $eval_err = $@;
    return [500, "Invalid JSON from server: $eval_err"] if $eval_err;

    #use Data::Dump; dd $res;
    strip_riap_stuffs_from_res($res);
}

sub parse_url {
    require URI::Split;

    my ($self, $uri, $copts) = @_;
    die "Please specify url" unless $uri;

    my $res = $self->request(info => $uri, {}, $copts);
    die "Can't 'info' on $uri: $res->[0] - $res->[1]" unless $res->[0] == 200;

    my $resuri = $res->[2]{uri};
    my ($sch, $auth, $path) = URI::Split::uri_split($resuri);
    $sch //= "pl";

    {proto=>$sch, path=>$path};
}

1;
# ABSTRACT: Riap::HTTP client

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Access::HTTP::Client - Riap::HTTP client

=head1 VERSION

This document describes version 0.24 of Perinci::Access::HTTP::Client (from Perl distribution Perinci-Access-HTTP-Client), released on 2017-07-03.

=head1 SYNOPSIS

 use Perinci::Access::HTTP::Client;
 my $pa = Perinci::Access::HTTP::Client->new;

 ## perform Riap requests

 # list all functions in package
 my $res = $pa->request(list => 'http://localhost:5000/api/',
                        {uri=>'/Some/Module/', type=>'function'});
 # -> [200, "OK", ['/Some/Module/mult2', '/Some/Module/mult2']]

 # call function
 $res = $pa->request(call => 'http://localhost:5000/api/',
                     {uri=>'/Some/Module/mult2', args=>{a=>2, b=>3}});
 # -> [200, "OK", 6]

 # get function metadata
 $res = $pa->request(meta => 'http://localhost:5000/api/',
                     {uri=>'/Foo/Bar/multn'});
 # -> [200, "OK", {v=>1.1, summary=>'Multiple many numbers', ...}]

 # pass HTTP credentials (via object attribute)
 my $pa = Perinci::Access::HTTP::Client->new(user => 'admin', password=>'123');
 my $res = $pa->request(call => '...', {...});
 # -> [200, "OK", 'result']

 # HTTP credentials can also be passed on a per-request basis
 my $pa = Perinci::Access::HTTP::Client->new();
 my $res = $pa->request(call => '...', {...}, {user=>'admin', password=>'123'});

 ## parse server URL
 $res = $pa->parse_url("https://cpanlists.org/api/"); # {proto=>"https", path=>"/App/cpanlists/Server/"}

=head1 DESCRIPTION

This class implements L<Riap::HTTP> client.

=for Pod::Coverage ^action_.+

=head1 ATTRIBUTES

=over

=item * realm => STR

For HTTP basic authentication. Defaults to "restricted area" (this is the
default realm used by L<Plack::Middleware::Auth::Basic>).

=item * user => STR

For HTTP basic authentication. Default will be taken from environment
C<PERINCI_HTTP_USER>.

=item * password => STR

For HTTP basic authentication. Default will be taken from environment
C<PERINCI_HTTP_PASSWORD>.

=item * ssl_cert_file => STR

Path to SSL client certificate. Default will be taken from environment
C<SSL_CERT_FILE>.

=item * ssl_cert_file => STR

Path to SSL CA certificate. Default will be taken from environment
C<SSL_CA_FILE>.

=back

=head1 METHODS

=head2 PKG->new(%attrs) => OBJ

Instantiate object. Known attributes:

=over

=item * retries => INT (default 2)

Number of retries to do on network failure. Setting it to 0 will disable
retries.

=item * retry_delay => INT (default 3)

Number of seconds to wait between retries.

=item * log_level => INT (default 0 or from environment)

Will be fed into Riap request key 'loglevel' (if >0). Note that some servers
might forbid setting log level.

If TRACE environment variable is true, default log_level will be set to 6. If
DEBUG, 5. If VERBOSE, 4. If quiet, 1. Else 0.

=item * log_callback => CODE

Pass log messages from the server to this subroutine. If not specified, log
messages will be "rethrown" into Log::ger loggers (e.g. log_warn(), log_debug(),
etc).

=back

=head2 $pa->request($action => $server_url[, \%extra_keys[, \%client_opts]]) => $res

Send Riap request to $server_url. Note that $server_url is the HTTP URL of Riap
server. You will need to specify code entity URI via C<uri> key in %extra_keys.

C<%extra_keys> is optional and contains additional Riap request keys (except
C<action>, which is taken from C<$action>).

C<%client_opts> is optional and contains additional information, like C<user>
(HTTP authentication user, overrides one in object attribute), C<password> (HTTP
authentication user, overrides one in object attribute).

=head2 $pa->parse_url($server_url[, \%client_opts]) => HASH

=head1 FAQ

=head2 How do I connect to a HTTP server that listens on a Unix socket?

This class can switch to using L<LWP::Protocol::http::SocketUnixAlt> when it
detects that the server is on a Unix socket, using this syntax (notice the
single instead of double slash after C<http:>):

 http:/path/to/unix.sock//uri

=head2 How do I connect to an HTTPS server without a "real" SSL certificate?

Since this module is using L<LWP>, you can set environment variable
C<PERL_LWP_SSL_VERIFY_HOSTNAME> to 0. See LWP for more details.

=head1 ENVIRONMENT

C<PERINCI_HTTP_USER>.

C<PERINCI_HTTP_PASSWORD>.

C<SSL_CERT_FILE>, C<SSL_CA_FILE>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-HTTP-Client>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Access-HTTP-Client>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-HTTP-Client>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Access::HTTP::Server>

L<Riap>, L<Rinci>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013, 2012 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
