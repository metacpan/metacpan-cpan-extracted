package Perlbal::Plugin::PSGI;
use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.03';

use Perlbal;
use Plack::Util;

sub register {
    my ($class, $svc) = @_;
    $svc->register_hook('PSGI', 'start_http_request', sub { handle_request($svc, $_[0]); });
}

sub handle_psgi_app_command {
    my $mc = shift->parse(qr/^psgi_app\s*=\s*(\S+)$/, "usage: PSGI_APP=<path>");
    my ($app_path) = $mc->args;

    my $handler = Plack::Util::load_psgi $app_path;
    my $svcname;
    unless ($svcname ||= $mc->{ctx}{last_created}) {
        return $mc->err("No service name in context from CREATE SERVICE <name> or USE <service_name>");
    }

    my $svc = Perlbal->service($svcname);
    return $mc->err("Non-existent service '$svcname'") unless $svc;

    my $cfg = $svc->{extra_config}->{_psgi_app} = $handler;

    return 1;
}

sub unregister {
    my ($class, $svc) = @_;
    $svc->unregister_hooks('PSGI');
    return 1;
}

sub load {
    Perlbal::register_global_hook('manage_command.psgi_app', \&handle_psgi_app_command);
    Perlbal::Service::add_role('psgi_server', sub { Perlbal::Plugin::PSGI::Client->new(@_) });
    return 1;
}

sub unload {
    Perlbal::unregister_global_hook('manage_command.psgi_app');
    Perlbal::Service::remove_role('psgi_server');
    return 1;
}

our $HR_RECURSION = 0;

sub handle_request {
    my $svc = shift;
    my $pb = shift;

    return 0 if $HR_RECURSION;
    local $HR_RECURSION = 1;

    my $app = $svc->{extra_config}->{_psgi_app};
    unless (defined $app) {
        return $pb->send_response(500, "No PSGI app is configured for this service");
    }

    Perlbal::Plugin::PSGI::Client->new_from_base($pb);

    return 1;
}

package Perlbal::Plugin::PSGI::Client;

use strict;
use warnings;
use base "Perlbal::ClientProxy";
use fields;

sub request_backend {
    my Perlbal::Plugin::PSGI::Client $self = shift;
    my $backend = Perlbal::Plugin::PSGI::Backend->new;
    $backend->assign_client($self);
}

package Perlbal::Plugin::PSGI::Backend;

use strict;
use warnings;

use Perlbal::ClientHTTPBase;
use Perlbal::Service;

use Plack::Util;
use Plack::HTTPParser qw(parse_http_request);
use HTTP::Status;

sub new {
    my $class = shift;
    my $self = bless {}, (ref $class || $class);
    $self->{input} = [];
    $self->{remaining} = 0;
    return $self;
}

sub close {
    # Do we need to do any cleanup?
}

sub forget_client {
    # Do we need to do any cleanup?
}

sub write {
    my $self = shift;
    my $bufref = shift;
    my $input = $self->{input};
    push @$input, $bufref;
    $self->{remaining} -= length($$bufref);
    return if $self->{remaining};
    $self->run_request;
}

sub assign_client {
    my $self = shift;
    my Perlbal::ClientHTTPBase $pb = shift;
    my Perlbal::Service $svc = $pb->{service};
    $self->{client} = $pb;
    $pb->backend($self);

    my $hdr = $pb->{req_headers} or return 0;
    my ($server_name, $server_port) = split /:/, ($pb->{selector_svc} ? $pb->{selector_svc}->{listen} : $svc->{listen});

    my $env = $self->{env} = {
        'psgi.version'      => [ 1, 0 ],
        'psgi.errors'       => Plack::Util::inline_object(print => sub { Perlbal::log('error', @_) }),
        'psgi.url_scheme'   => 'http',
        'psgi.nonblocking'  => Plack::Util::TRUE,
        'psgi.run_once'     => Plack::Util::FALSE,
        'psgi.multithread'  => Plack::Util::FALSE,
        'psgi.multiprocess' => Plack::Util::FALSE,
        'psgi.streaming'    => Plack::Util::TRUE,
        REMOTE_ADDR         => $pb->{peer_ip},
        SERVER_NAME         => $server_name,
        SERVER_PORT         => $server_port,
    };

    parse_http_request($pb->{headers_string}, $env);

    if ($env->{CONTENT_LENGTH}) {
        $self->{remaining} = $env->{CONTENT_LENGTH};
    } else {
        $self->run_request;
    }
}

sub run_request {
    my $self = shift;

    my Perlbal::ClientHTTPBase $pb = $self->{client};
    my Perlbal::Service $svc = $pb->{service};
    my $app = $svc->{extra_config}->{_psgi_app};
    my $env = $self->{env};
    my $buf_ref = \join('', map { $$_ } @{$self->{input}});
    open my $input, "<", $buf_ref;
    $env->{'psgi.input'} = $input;

    my $responder = sub {
        my $res = shift;

        my $hd = $pb->{res_headers} = Perlbal::HTTPHeaders->new_response($res->[0]);
        my %seen;
        while (my($k, $v) = splice @{$res->[1]}, 0, 2) {
            if ($seen{lc($k)}++) {
                my $newvalue = $hd->header($k) . "\015\012$k: $v";
                $hd->header($k, $newvalue);
            } else {
                $hd->header($k, $v);
            }
        }

        $pb->setup_keepalive($hd);

        $pb->state('xfer_resp');
        $pb->tcp_cork(1);  # cork writes to self
        $pb->write($hd->to_string_ref);

        if (!defined $res->[2]) {
            return Plack::Util::inline_object
                write => sub { $pb->write(@_) },
                close => sub { $pb->write(sub { $pb->http_response_sent}) };
        } elsif (Plack::Util::is_real_fh($res->[2])) {
            $pb->reproxy_fh($res->[2], -s $res->[2]);
        } else {
            Plack::Util::foreach($res->[2], sub { $pb->write(@_) });
            $pb->write(sub { $pb->http_response_sent });
        }
    };

    my $res = Plack::Util::run_app $app, $env;
    ref $res eq 'CODE' ? $res->($responder) : $responder->($res);
}

1;

=head1 NAME

Perlbal::Plugin::PSGI - PSGI web server on Perlbal

=head1 SYNOPSIS

  LOAD PSGI
  CREATE SERVICE psgi
    SET role    = psgi_server
    SET listen  = 127.0.0.1:80
    PSGI_APP    = /path/to/app.psgi
  ENABLE psgi

=head1 DESCRIPTION

This is a Perlbal plugin to allow any PSGI application run natively
inside Perlbal process.

=head1 COPYRIGHT

Copyright 2009- Tatsuhiko Miyagawa

=head1 AUTHOR

Tatsuhiko Miyagawa

Jonathan Steinert

Based on Perlbal::Plugin::Cgilike written by Martin Atkins.

=head1 LICENSE

This module is licensed under the same terms as Perl itself.

=cut
