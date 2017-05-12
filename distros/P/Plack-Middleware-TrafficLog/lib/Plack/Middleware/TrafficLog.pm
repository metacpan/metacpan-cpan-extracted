package Plack::Middleware::TrafficLog;

=head1 NAME

Plack::Middleware::TrafficLog - Log headers and body of HTTP traffic

=head1 SYNOPSIS

  # In app.psgi
  use Plack::Builder;

  builder {
      enable "TrafficLog", with_body => 1;
  };

=head1 DESCRIPTION

This middleware logs the request and response messages with detailed
information about headers and body.

The example log:

  [08/Aug/2012:16:59:47 +0200] [164836368] [127.0.0.1 -> 0:5000] [Request ]
  |GET / HTTP/1.1|Connection: TE, close|Host: localhost:5000|TE: deflate,gzi
  p;q=0.3|User-Agent: lwp-request/6.03 libwww-perl/6.03||
  [08/Aug/2012:16:59:47 +0200] [164836368] [127.0.0.1 <- 0:5000] [Response]
  |HTTP/1.0 200 OK|Content-Type: text/plain||Hello World

This module works also with applications which have delayed response. In that
case each chunk is logged separately and shares the same unique ID number and
headers.

The body of request and response is not logged by default. For streaming
responses only first chunk is logged by default.

=for readme stop

=cut


use 5.008;

use strict;
use warnings;

our $VERSION = '0.0401';


use parent 'Plack::Middleware';

use Plack::Util::Accessor qw(
    with_request with_response with_date with_body with_all_chunks eol body_eol logger
    _counter _call_id _strftime
);


use Plack::Util;

use Plack::Request;
use Plack::Response;

use POSIX ();
use POSIX::strftime::Compiler ();
use Scalar::Util ();


sub prepare_app {
    my ($self) = @_;

    # the default values
    $self->with_request(Plack::Util::TRUE)     unless defined $self->with_request;
    $self->with_response(Plack::Util::TRUE)    unless defined $self->with_response;
    $self->with_date(Plack::Util::TRUE)        unless defined $self->with_date;
    $self->with_body(Plack::Util::FALSE)       unless defined $self->with_body;
    $self->with_all_chunks(Plack::Util::FALSE) unless defined $self->with_all_chunks;
    $self->body_eol(defined $self->eol ? $self->eol : ' ') unless defined $self->body_eol;
    $self->eol('|')         unless defined $self->eol;

    $self->_strftime(POSIX::strftime::Compiler->new('%d/%b/%Y:%H:%M:%S %z'));

    $self->_counter(0);
};


sub _log_message {
    my ($self, $type, $env, $status, $headers, $body) = @_;

    my $logger = $self->logger || sub { $env->{'psgi.errors'}->print(@_) };

    my $server_addr = sprintf '%s:%s', $env->{SERVER_NAME}, $env->{SERVER_PORT};
    my $remote_addr = defined $env->{REMOTE_PORT}
        ? sprintf '%s:%s', $env->{REMOTE_ADDR}, $env->{REMOTE_PORT}
        : $env->{REMOTE_ADDR};

    my $eol = $self->eol;
    my $body_eol = $self->body_eol;
    $body =~ s/\015?\012/$body_eol/gs if defined $body_eol;

    my $date = $self->with_date
        ? ('['. $self->_strftime->to_string(localtime) . '] ')
        : '';

    $logger->( sprintf "%s[%s] [%s %s %s] [%s] %s%s%s%s%s%s\n",
        $date,
        $self->_call_id,

        $remote_addr,
        $type eq 'Request ' ? '->' : $type eq 'Response' ? '<-' : '--',
        $server_addr,

        $type,

        $eol,
        $status,
        $eol,
        $headers->as_string($eol),
        $eol,
        $body,
    );
};


sub _log_request {
    my ($self, $env) = @_;

    my $req = Plack::Request->new($env);

    my $status = sprintf '%s %s %s', $req->method, $req->request_uri, $req->protocol;
    my $headers = $req->headers;
    my $body = $self->with_body ? $req->content : '';

    $self->_log_message('Request ', $env, $status, $headers, $body);
};


sub _log_response {
    my ($self, $env, $ret) = @_;

    my $res = Plack::Response->new(@$ret);

    my $status_code = $res->status;
    my $status_message = HTTP::Status::status_message($status_code);

    my $status = sprintf 'HTTP/1.0 %s %s', $status_code, defined $status_message ? $status_message : '';
    my $headers = $res->headers;
    my $body = '';
    if ($self->with_body) {
        $body = $res->content;
        $body = '' unless defined $body;
        $body = join '', grep { defined $_ } @$body if ref $body eq 'ARRAY';
    }

    $self->_log_message('Response', $env, $status, $headers, $body);
};


sub call {
    my ($self, $env) = @_;

    $self->_call_id(sprintf '%015d',
        time % 2**16 * 2**32 +
        (Scalar::Util::looks_like_number $env->{REMOTE_PORT} ? $env->{REMOTE_PORT} : int rand 2**16) % 2**16 * 2**16 +
        $self->_counter % 2**16);
    $self->_counter($self->_counter + 1);

    # Preprocessing
    $self->_log_request($env) if $self->with_request;

    # $self->app is the original app
    my $res = $self->app->($env);

    # Postprocessing
    return $self->with_response ? $self->response_cb($res, sub {
        my ($ret) = @_;
        my $seen;
        return sub {
            my ($chunk) = @_;
            return if $seen and not defined $chunk;
            return $chunk if $seen and not $self->with_all_chunks;
            $self->_log_response($env, [ $ret->[0], $ret->[1], [$chunk] ]);
            $seen = Plack::Util::TRUE;
            return $chunk;
        };
    }) : $res;
};


1;


=head1 CONFIGURATION

=over 4

=item logger

  # traffic.l4p
  log4perl.logger.traffic = DEBUG, LogfileTraffic
  log4perl.appender.LogfileTraffic = Log::Log4perl::Appender::File
  log4perl.appender.LogfileTraffic.filename = traffic.log
  log4perl.appender.LogfileTraffic.layout = PatternLayout
  log4perl.appender.LogfileTraffic.layout.ConversionPattern = %m{chomp}%n

  # app.psgi
  use Log::Log4perl qw(:levels get_logger);
  Log::Log4perl->init('traffic.l4p');
  my $logger = get_logger('traffic');

  enable "Plack::Middleware::TrafficLog",
      logger => sub { $logger->log($INFO, join '', @_) };

Sets a callback to print log message to. It prints to C<psgi.errors> output
stream by default.

=item with_request

The false value disables logging of request message.

=item with_response

The false value disables logging of response message.

=item with_date

The false value disables logging of current date.

=item with_body

The true value enables logging of message's body.

=item with_all_chunks

The true value enables logging of every chunk for streaming responses.

=item eol

Sets the line separator for message's headers and body. The default value is
the pipe character C<|>.

=item body_eol

Sets the line separator for message's body only. The default is the space
character C< >. The default value is used only if B<eol> is also undefined.

=back

=for readme continue

=head1 SEE ALSO

L<Plack>, L<Plack::Middleware::AccessLog>.

=head1 BUGS

This module has unstable API and it can be changed in future.

The log file can contain the binary data if the PSGI server provides binary
files.

If you find the bug or want to implement new features, please report it at
L<http://github.com/dex4er/perl-Plack-Middleware-TrafficLog/issues>

The code repository is available at
L<http://github.com/dex4er/perl-Plack-Middleware-TrafficLog>

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2012, 2014-2015 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
