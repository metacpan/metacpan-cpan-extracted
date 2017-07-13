package Plack::Middleware::PeriAHS::LogAccess;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.61'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(
                                dest
                                max_args_len
                                max_resp_len
                        );

use JSON::MaybeXS;
use Plack::Util;
use POSIX;
use Scalar::Util qw(blessed);
use Time::HiRes qw(gettimeofday tv_interval);

sub prepare_app {
    my $self = shift;
    if (!$self->dest) {
        die "Please specify dest";
    }

    $self->{max_args_len} //= 1000;
    $self->{max_resp_len} //= 1000;

    if (!ref($self->dest)) {
        open my($fh), ">>", $self->dest
            or die "Can't open log file '$self->{dest}': $!";
        $self->dest($fh);
    }
}

sub call {
    log_trace("=> PeriAHS::LogAccess middleware");

    my ($self, $env) = @_;

    $env->{'periahs.start_request_time'} = time();

    # call app first
    my $res = $self->app->($env);
    return $self->response_cb(
        $res,
        sub {
            my $res = shift;
            $self->log_access($env);
        });
}

sub log_access {
    my ($self, $env) = @_;

    my $now = [gettimeofday];

    return unless $env->{'periahs.start_request_time'};

    my $time = POSIX::strftime("%d/%b/%Y:%H:%M:%S +0000",
                               gmtime($env->{'periahs.start_request_time'}));
    my $server_addr;
    if ($env->{'gepok.unix_socket'}) {
        $server_addr = "unix:$env->{SERVER_NAME}";
    } else {
        $server_addr = "tcp:$env->{SERVER_PORT}";
    }

    state $json = JSON::MaybeXS->new->allow_nonref->allow_blessed->convert_blessed;
    local *UNIVERSAL::TO_JSON = sub { "$_[0]" };

    my $rreq = $env->{'riap.request'};

    my $action = $rreq->{action} // "";
    my $skip_args;
    my $skip_resp;
    if ($action =~ /\A(list|info|meta)\z/o) {
        # skip logging details of unimportant actions
        $skip_args = 1;
        $skip_resp = 1;
    }

    my ($args_s, $args_len, $args_partial);
    if ($rreq->{args} && !$skip_args) {
        $args_s = $json->encode($rreq->{args});
        $args_len = length($args_s);
        $args_partial = $args_len > $self->max_args_len;
        $args_s = substr($args_s, 0, $self->max_args_len)
            if $args_partial;
    } else {
        $args_s = "";
        $args_len = 0;
        $args_partial = 0;
    }

    my $res = $env->{'riap.response'};
    my ($resp_s, $resp_len, $resp_partial);
    if ($res && !$skip_resp) {
        $resp_s = $json->encode($res);
        $resp_len = length($resp_s);
        $resp_partial = $resp_len > $self->max_resp_len;
        $resp_s = substr($resp_s, 0, $self->max_resp_len)
            if $resp_partial;
    } else {
        $resp_s = "";
        $resp_partial = 0;
        $resp_len = 0;
    }

    my $subt;
    if ($env->{'periahs.start_action_time'}) {
        if ($env->{'periahs.finish_action_time'}) {
            $subt = sprintf("%.3fms",
                            1000*tv_interval(
                                $env->{'periahs.start_action_time'},
                                $env->{'periahs.finish_action_time'}));
        } else {
            $subt = "D";
        }
    } else {
        $subt = "-";
    }

    my $reqt;
    if ($env->{'gepok.connect_time'}) {
        $reqt = sprintf("%.3fms",
                        1000*tv_interval($env->{'gepok.start_request_time'},
                                         $now));
    } else {
        $reqt = "-";
    }

    my $extra = "";

    my $fmt = join(
        "",
        "[%s] ", # time
        "[%s] ", # remote addr
        "[%s] ", # server addr
        "[user %s] ",
        "%s %s ", # action URI
        "[args %s %s] ",
        "[resp %s %s] ",
        "%s %s", # subt reqt
        "%s", # extra info
        "\n"
    );

    my $uri = $rreq->{uri} // "-";
    my $log_line = sprintf(
        $fmt,
        $time,
        $env->{REMOTE_ADDR},
        $server_addr,
        $env->{REMOTE_USER} // "-",
        _safe($action),
        _safe($uri),
        ($skip_args ? "S" : $args_len.($args_partial ? "p" : "")), ($skip_args ? "?" : $args_s),
        ($skip_resp ? "S" : $resp_len.($resp_partial ? "p" : "")), ($skip_resp ? "?" : $resp_s),
        $subt, $reqt,
        $extra,
    );
    #$log->tracef("Riap access log: %s", $log_line);

    my $dest = $self->dest;
    if (blessed($dest)) {
        if ($dest->can("syswrite")) {
            $dest->syswrite($log_line);
        } elsif ($dest->can("write")) {
            $dest->write($log_line);
        } elsif ($dest->can("log")) {
            $dest->log(log=>'info', message=>$log_line);
        } else {
            die "BUG: dest cannot be syswrite()'d or write()'d or log()'ed";
        }
    } else {
        syswrite $self->{dest}, $log_line;
    }
}

sub _safe {
    my $string = shift;
    $string =~ s/([^[:print:]])/"\\x" . unpack("H*", $1)/eg
        if defined $string;
    $string;
}

1;
# ABSTRACT: Log request

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::PeriAHS::LogAccess - Log request

=head1 VERSION

This document describes version 0.61 of Plack::Middleware::PeriAHS::LogAccess (from Perl distribution Perinci-Access-HTTP-Server), released on 2017-07-10.

=head1 SYNOPSIS

 # In app.psgi
 use Plack::Builder;

 builder {
     enable "PeriAHS::LogAccess", dest => "/path/to/api-access.log";
 }

=head1 DESCRIPTION

This middleware forwards the request to given app and logs request. Only
requests which have executed action (has $env->{'periahs.start_action_time'}
set) will be logged.

The log looks like this (all in one line):

 [20/Aug/2011:22:05:38 +0000] [127.0.0.1] [tcp:80] [libby] call
 /MyModule/my_func [args 14 {"name":"val"}] [resp 12 [200,"OK",1]]
 2.123ms 5.947ms

The second last field ("2.123ms") is time spent executing the Riap action (in
this case, calling the subroutine), and the last field ("5.947ms") is time spent
for the whole HTTP request (from client connect until HTTP response is sent).

This middleware should be put outermost (first) to be able to record request
starting time more accurately.

=for Pod::Coverage .*

=head1 CONFIGURATION

=over 4

=item * dest => STR or OBJ

Either a string (path to log file) or an object which support <syswrite()> (like
L<IO::Handle>) or C<write()> (like IO::Handle or L<File::Write::Rotate>) or
C<log> (like L<Log::Dispatch::Output>). If object supports C<log>, it will be
called like a Log::Dispatch::Output object, i.e. $obj->log(level=>'info',
message=>"Log line ...\n"). Otherwise it will be called with the log line as the
single argument.

=item * max_args_len => INT (default 1000)

Maximum number of characters of args to log. Args will be JSON-encoded and
truncated to this value if too long. In the log file it will be printed as:

 [args <LENGTH> <ARGS>]

=item * max_resp_len => INT (default 1000)

Maximum number of characters of sub response to log. Response will be
JSON-encoded and truncated to this value if too long. In the log file it will be
printed as:

 [resp <LENGTH> <ARGS>]

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-HTTP-Server>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Access-HTTP-Server>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-HTTP-Server>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
