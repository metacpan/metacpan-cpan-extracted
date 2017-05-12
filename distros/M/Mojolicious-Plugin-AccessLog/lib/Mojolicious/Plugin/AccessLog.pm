package Mojolicious::Plugin::AccessLog;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::IOLoop;

use File::Spec;
use IO::File;
use POSIX qw(setlocale strftime LC_ALL);
use Scalar::Util qw(blessed reftype weaken);
use Socket qw(inet_aton AF_INET);
use Time::HiRes qw(gettimeofday tv_interval);

our $VERSION = '0.010';

my $DEFAULT_FORMAT = 'common';
my %FORMATS = (
    $DEFAULT_FORMAT => '%h %l %u %t "%r" %>s %b',
    combined => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-Agent}i"',
    combinedio => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-Agent}i" %I %O',
);

# some systems (Windows) don't support %z correctly
my $TZOFFSET = strftime('%z', localtime) !~ /^[+-]\d{4}$/ && do {
    require Time::Local;
    my $t = time;
    my $d = (Time::Local::timegm(localtime($t)) - $t) / 60;
    sprintf '%+03d%02u', int($d / 60), $d % 60;
};
# some systems (Windows) don't support %s
my $NOEPOCHSECS = strftime('%s', localtime) !~ /^\d+$/;

sub register {
    my ($self, $app, $conf) = @_;
    my $log = $conf->{log} // $app->log->handle;
    my ($pkg, $f, $l) = caller 2;   # :-/

    $app->log->warn(__PACKAGE__ . '::VERSION = ' . $VERSION);
    unless ($log) { # somebody cleared $app->log->handle?
        # Log a warning nevertheless - there might be an event handler.
        $app->log->warn(__PACKAGE__ . ': Log handle is not defined');
        return;
    }

    my $reftype = reftype $log // '';
    my $logger;

    if ($reftype eq 'GLOB') {
        eval { $log->autoflush(1) };
        $logger = sub { $log->print($_[0]) };
    }
    elsif (blessed($log) and my $l = $log->can('print') || $log->can('info')) {
        $logger = sub { $l->($log, $_[0]) };
    }
    elsif ($reftype eq 'CODE') {
        $logger = $log;
    }
    elsif (defined $log and not ref $log) {
        File::Spec->file_name_is_absolute($log)
            or $log = $app->home->rel_file($log);

        my $fh = IO::File->new($log, '>>')
            or die <<"";
Can't open log file "$log": $! at $f line $l.

        $fh->autoflush(1);
        $logger = sub { $fh->print($_[0]) };
    }
    else {
        $app->log->error(__PACKAGE__ . ': not a valid "log" value');
        return;
    }

    if ($conf->{uname_helper}) {
        warn <<"";
uname_helper is DEPRECATED in favor of \$c->req->env->{REMOTE_USER} at $f line $l.


        my $helper_name = $conf->{uname_helper};

        $helper_name = 'set_username' if $helper_name !~ /^[\_A-za-z]\w*$/;

        $app->helper(
            $helper_name => sub { $_[0]->req->env->{REMOTE_USER} = $_[1] }
        );
    }

    my @handler;
    my $strftime = sub {
        my ($fmt, @time) = @_;
        $fmt =~ s/%z/$TZOFFSET/g if $TZOFFSET;
        $fmt =~ s/%s/time()/ge if $NOEPOCHSECS;
        my $old_locale = setlocale(LC_ALL);
        setlocale(LC_ALL, 'C');
        my $out = strftime($fmt, @time);
        setlocale(LC_ALL, $old_locale);
        return $out;
    };
    my $format = $FORMATS{$conf->{format} // $DEFAULT_FORMAT};
    my $safe_re;

    if ($format) {
        # Apache default log formats don't quote username, which might
        # have spaces.
        $safe_re = qr/([^[:print:]]|\s)/;
    }
    else {
        # For custom log format appropriate quoting is the user's responsibility.
        $format = $conf->{format};
    }

    # each handler is called with following parameters:
    # 0: $tx, 1: $tx->req, 2: $tx->res, 3: $tx->req->url,
    # 4: $request_start_time, 5: $process_time, 6: $bytes_in, 7: $bytes_out
    # 8: HTTP request start line

    my $block_handler = sub {
        my ($block, $type) = @_;

        return sub { _safe($_[1]->headers->header($block) // '-') }
            if $type eq 'i';

        return sub { $_[2]->headers->header($block) // '-' }
            if $type eq 'o';

        return sub {
            return $_[4][0]
                if $block eq 'sec';
            return sprintf "%u%03u", $_[4][0], int($_[4][1] / 1000)
                if $block eq 'msec';
            return sprintf "%u%06u", @{$_[4]}
                if $block eq 'usec';
            return sprintf('%03u', $_[4][1] / 1000)
                if $block eq 'msec_frac';
            return sprintf('%06u', $_[4][1])
                if $block eq 'usec_frac';
            return $strftime->($block, localtime($_[4][0]));
        }
            if $type eq 't';

        return sub { _safe($_[1]->cookie($block // '')) }
            if $type eq 'C';

        return sub { _safe($_[1]->env->{$block // ''}) }
            if $type eq 'e';

        $app->log->error("{$block}$type not supported");

        return '-';
    };

    my $servername_cb = sub { $_[3]->base->host || '-' };
    my $remoteaddr_cb = sub { $_[0]->remote_address || '-' };
    my %char_handler = (
        '%' => '%',
        a => $remoteaddr_cb,
        A => sub { $_[0]->local_address // '-' },
        b => sub {
            $_[7] && ($_[7] - $_[2]->header_size - $_[2]->start_line_size) || '-'
        },
        B => sub {
            $_[7] ? $_[7] - $_[2]->header_size - $_[2]->start_line_size : '0'
        },
        D => sub { int($_[5] * 1000000) },
        h => $remoteaddr_cb,
        H => sub { 'HTTP/' . $_[1]->version },
        I => sub { $_[6] },
        l => '-',
        m => sub { $_[1]->method },
        O => sub { $_[7] },
        p => sub { $_[0]->local_port },
        P => sub { $$ },
        q => sub {
            my $s = $_[3]->query->to_string or return '';
            return '?' . $s;
        },
        r => sub { $_[8] },
        s => sub { $_[2]->code // '-' },
        t => sub {
            $strftime->('[%d/%b/%Y:%H:%M:%S %z]', localtime($_[4][0]))
        },
        T => sub { int $_[5] },
        u => sub {
            my $env = $_[1]->env;
            my $user =
                exists($env->{REMOTE_USER}) ?
                    length($env->{REMOTE_USER} // '') ?
                        $env->{REMOTE_USER} : '-' :
                        (split ':', $_[3]->base->userinfo || '-:')[0];

            return _safe($user, $safe_re)
        },
        U => sub { $_[3]->path },
        v => $servername_cb,
        V => $servername_cb,
    );

    if ($conf->{hostname_lookups}) {
        $char_handler{h} = sub {
            my $ip = $_[0]->remote_address or return '-';
            return gethostbyaddr(inet_aton($ip), AF_INET);
        };
    }

    my $char_handler = sub {
        my $char = shift;
        my $cb = $char_handler{$char};

        return $char_handler{$char} if $char_handler{$char};

        $app->log->error("\%$char not supported.");

        return '-';
    };

    $format =~ s~
        (?:
        \%\{(.+?)\}([a-z]) |
        \%(?:[<>])?([a-zA-Z\%])
        )
    ~
        push @handler, $1 ? $block_handler->($1, $2) : $char_handler->($3);
        '%s';
    ~egx;

    chomp $format;
    $format .= $conf->{lf} // $/ // "\n";

    $app->hook(after_build_tx => sub {
        my $tx = $_[0];

        $tx->on(connection => sub {
            my ($tx, $connection) = @_;
            my $bcr = my $bcw = 0;
            my $sl;
            my $t = [gettimeofday];
            my $s = Mojo::IOLoop->stream($connection);
            my $r = $s->on(read  => sub {
                # get the unmodified HTTP request start line
                $sl //= substr($_[1], 0, index($_[1], "\r\n"));
                $bcr += length $_[1];
            });
            my $w = $s->on(write => sub { $bcw += length $_[1] });

            weaken $s;
            weaken $r;
            weaken $w;

            $tx->on(finish => sub {
                my $tx = shift;
                my $dt = tv_interval($t);

                $s->unsubscribe(read  => $r);
                $s->unsubscribe(write => $w);
                $logger->(_log($tx, $format, \@handler, $t, $dt, $bcr, $bcw, $sl));
            });
        });
    });
}

sub _log {
    my ($tx, $format, $handler) = (shift, shift, shift);
    my $req = $tx->req;
    my @args = ($tx, $req, $tx->res, $req->url, @_);

    sprintf $format, map(ref() ? ($_->(@args))[0] // '' : $_, @$handler);
}

sub _safe {
    my $string = shift;
    my $re = shift // qr/([^[:print:]])/;

    $string =~ s/$re/'\x' . unpack('H*', $1)/eg
        if defined $string;

    return $string;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::AccessLog - An AccessLog Plugin for Mojolicious

=head1 VERSION

Version 0.010

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin(AccessLog => log => '/var/log/mojo/access.log');

  # Mojolicious::Lite
  plugin AccessLog => {log => '/var/log/mojo/access.log'};

=head1 DESCRIPTION

L<Mojolicious::Plugin::AccessLog> is a plugin to easily generate an
access log.

=head1 OPTIONS

L<Mojolicious::Plugin::AccessLog> supports the following options.

=head2 C<log>

Log data destination.

Default: C<< $app->log->handle >>, so that access log lines go to the
same destination as lines created with C<< $app->log->$method(...) >>.

This option may be set to one of the following values:

=head3 Absolute path

  plugin AccessLog => {log => '/var/log/mojo/access.log'};

A string specifying an absolute path to the log file. If the file does
not exist already, it will be created, otherwise log output will be
appended to the file. The log directory must exist in every case though.

=head3 Relative path

  # Mojolicious::Lite
  plugin AccessLog => {log => 'log/access.log'};

Similar to absolute path, but relative to the application home directory.

=head3 File Handle

  open $fh, '>', '/var/log/mojo/access.log';
  plugin AccessLog => {log => $fh};

  plugin AccessLog => {log => \*STDERR};

A file handle to which log lines are printed.

=head3 Object

  $log = IO::File->new('/var/log/mojo/access.log', O_WRONLY|O_APPEND);
  plugin AccessLog => {log => $log};

  $log = Log::Dispatch->new(...);
  plugin AccessLog => {log => $log};

An object, that implements either a C<print> method (like L<IO::Handle>
based classes) or an C<info> method (i.e. L<Log::Dispatch> or
L<Log::Log4perl>).

=head3 Callback routine

  $log = Log::Dispatch->new(...);
  plugin AccessLog => {
    log => sub { $log->log(level => 'debug', message => @_) }
  };

A code reference. The provided subroutine will be called for every log
line, that it gets as a single argument.

=head2 C<format>

A string to specify the format of each line of log output.

Default: "common" (see below).

This plugin implements a subset of
L<Apache's LogFormat|http://httpd.apache.org/docs/current/mod/mod_log_config.html>.

=over

=item %%

A percent sign.

=item %a

Remote IP-address.

=item %A

Local IP-address.

=item %b

Size of response in bytes, excluding HTTP headers. In CLF format, i.e.
a '-' rather than a 0 when no bytes are sent.

=item %B

Size of response in bytes, excluding HTTP headers.

=item %D

The time taken to serve the request, in microseconds.

=item %h

Remote host. See L</hostname_lookups> below.

=item %H

The request protocol.

=item %I

Bytes received, including request and headers. Cannot be zero.

=item %l

The remote logname, not implemented: currently always '-'.

=item %m

The request method.

=item %O

Bytes sent, including headers. Cannot be zero.

=item %p

The port of the server serving the request.

=item %P

The process ID of the child that serviced the request.

=item %r

First line of request: Request method, request URL and request protocol.
Synthesized from other fields, so it may not be the request verbatim.

=item %s

The HTTP status code of the response.

=item %t

Time the request was received (standard english format).

=item %T

The time taken to serve the request, in seconds.

=item %u

Remote user, or '-'.

The remote user is first looked up in C<< $c->req->env->{REMOTE_USER} >>
and only if that does not exist then in the first part of
C<< $c->req->url->base->userinfo >>. This means the latter lookup can be
disabled by setting C<< $c->req->env->{REMOTE_USER} = undef >>.

=item %U

The URL path requested, not including any query string.

=item %v

The name of the server serving the request.

=item %V

The name of the server serving the request.

=back

In addition, custom values can be referenced, using C<%{name}>,
with one of the mandatory modifier flags C<i>, C<o>, C<t>, C<C> or C<e>:

=over

=item %{RequestHeaderName}i

The contents of request header C<RequestHeaderName>.

=item %{ResponseHeaderName}o

The contents of response header C<ResponseHeaderName>.

=item %{Format}t

The time, in the form given by C<Format>, which should be in extended
L<strftime(3)> format (potentially localized). In addition to the
formats supported by strftime(3), the following format tokens are
supported:

=over

=item sec:

Number of seconds since the Epoch.

=item msec:

Number of milliseconds since the Epoch.

=item usec:

Number of microseconds since the Epoch.

=item msec_frac:

Millisecond fraction.

=item usec_frac:

Microsecond fraction.

=back

These tokens can not be combined with each other or strftime(3) formatting
in the same format string. You can use multiple %{format}t tokens instead:

  "%{%d/%b/%Y %T}t.%{msec_frac}t %{%z}t"

=item %{CookieName}C

The contents of cookie C<CookieName> in the request sent to the server.

=item %{VariableName}e

Content of the request environment hash variable C<VariableName>:

  $c->req->env->{VariableName}

The request environment hash is set by a L<CGI> or L<PSGI> server.

=back

Non-printable bytes are replaced by an escape sequence of C<\x..> with
C<..> being the hexadecimal code of the replaced byte.

For mostly historical reasons template names "common", "combined" and
"combinedio" can also be used:

=over

=item common

  %h %l %u %t "%r" %>s %b

=item combined

  %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-Agent}i"

=item combinedio

  %h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-Agent}i" %I %O

=back

These format template names have two drawbacks though:

=over

=item 1.

The username (%u) is not quoted, but a username is allowed to
contain spaces. As a consequence, log file parsers might lose track of
the right fields. To get around this, B<< spaces in usernames are replaced
by C<\x20> if one of the format template names is used >>.

=item 2.

The remote logname C<%l> as provided by an ident service is not useful
these days and therefore not supported, C<%l> is always substituted by
a hyphen (C<"-">).

=back

=head2 C<hostname_lookups>

Enable reverse DNS hostname lookup if C<true>. Keep in mind, that this
adds latency to every request, if C<%h> is part of the log line, because
it requires a DNS lookup to complete before the request is finished.
Default is C<false> (= disabled).

=head1 METHODS

L<Mojolicious::Plugin::AccessLog> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register(
    Mojolicious->new, {
      log => '/var/log/mojo/access.log',
      format => 'combined',
    }
  );

Register plugin hooks in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Plack::Middleware::AccessLog>,
L<Catalyst::Plugin::AccessLog>,
L<http://httpd.apache.org/docs/current/mod/mod_log_config.html>.

=head1 ACKNOWLEDGEMENTS

Many thanks to Tatsuhiko Miyagawa for L<Plack::Middleware::AccessLog>
and Andrew Rodland for L<Catalyst::Plugin::AccessLog>.
C<Mojolicious:Plugin::AccessLog> borrows a lot of code and ideas from
those modules.

=head1 AUTHOR

Bernhard Graf

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 - 2015 Bernhard Graf

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/> for more information.
