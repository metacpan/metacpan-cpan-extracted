package Plack::Handler::SCGI;

use strict;
use 5.008_001;
our $VERSION = '0.02';

use SCGI;
use IO::Socket;
use Plack::Util;
use URI::Escape ();
use Try::Tiny;

sub new {
    my($class, %args) = @_;
    my $self = bless {
        port => 9000,
        server_ready => sub {},
        %args,
    }, $class;
}

sub run {
    my($self, $app) = @_;

    my $socket = IO::Socket::INET->new(
        Listen => 5,
        ReuseAddr => 1,
        LocalPort => $self->{port},
    ) or die "Cannot bind to port $self->{port}: $!";

    my $sock = SCGI->new($socket, blocking => 1)
        or die "Failed to open SCGI socket: $!";

    $self->{server_ready}->($self);

    while ( my $request = $sock->accept ) {
        try {
            $request->read_env;
            $self->handle_request($app, $request);
        } catch {
            warn "SCGI Error: $_";
        } finally {
            $request->close;
        }
    }
}

sub handle_request {
    my($self, $app, $request) = @_;

    my $env = $request->env;

    delete $env->{HTTP_CONTENT_TYPE};
    delete $env->{HTTP_CONTENT_LENGTH};
    ($env->{PATH_INFO}, $env->{QUERY_STRING}) = split /\?/, $env->{REQUEST_URI};
    $env->{PATH_INFO} = URI::Escape::uri_unescape $env->{PATH_INFO};
    $env->{SCRIPT_NAME} = '';
    $env->{SERVER_NAME} =~ s/:\d+$//; # lighttpd bug?

    $env = {
        %$env,
        'psgi.version'      => [1,1],
        'psgi.url_scheme'   => ($env->{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
        'psgi.input'        => $request->connection,
        'psgi.errors'       => *STDERR,
        'psgi.multithread'  => Plack::Util::FALSE,
        'psgi.multiprocess' => Plack::Util::TRUE,
        'psgi.run_once'     => Plack::Util::FALSE,
        'psgi.streaming'    => Plack::Util::TRUE,
        'psgi.nonblocking'  => Plack::Util::FALSE,
        'psgix.input.buffered' => Plack::Util::FALSE,
    };

    my $res = Plack::Util::run_app $app, $env;

    if (ref $res eq 'ARRAY') {
        $self->handle_response($res, $request->connection);
    } elsif (ref $res eq 'CODE') {
        $res->(sub { $self->handle_response($_[0], $request->connection) });
    } else {
        die "Bad response $res";
    }
}

sub handle_response {
    my($self, $res, $conn) = @_;

    my $hdrs;
    $hdrs = "Status: $res->[0]\015\012";

    my $headers = $res->[1];
    while (my ($k, $v) = splice @$headers, 0, 2) {
        $hdrs .= "$k: $v\015\012";
    }
    $hdrs .= "\015\012";

    $conn->print($hdrs);

    my $cb = sub { $conn->print($_[0]) };
    my $body = $res->[2];
    if (defined $body) {
        Plack::Util::foreach($body, $cb);
    }
    else {
        return Plack::Util::inline_object
            write => $cb,
            close => sub { };
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Plack::Handler::SCGI - PSGI handler on SCGI daemon

=head1 SYNOPSIS

  plackup -s SCGI --port 22222

=head1 DESCRIPTION

Plack::Handler::SCGI is a standalone SCGI daemon using L<SCGI>

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Plack::Handler::FCGI> L<SCGI>

=cut
