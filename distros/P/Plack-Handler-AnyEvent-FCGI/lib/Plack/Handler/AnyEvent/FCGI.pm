package Plack::Handler::AnyEvent::FCGI;

use strict;
use 5.008_001;
our $VERSION = '0.01';

use AnyEvent;
use AnyEvent::FCGI;
use Plack::Util;
use IO::Handle::Util qw(io_from_write_cb);
use URI;
use URI::Escape;

sub new {
    my($class, %args) = @_;
    bless { %args }, $class;
}

sub run {
    my $self = shift;
    $self->register_service(@_);
    $self->{_cv}->recv;
}

sub register_service {
    my($self, $app) = @_;

    my $listen = $self->{listen}[0]
        or die "listen address/socket not specified";

    my %args;
    if ($listen =~ /:\d+$/) {
        @args{qw(host port)} = split /:/, $listen, 2;
        $args{host} = undef if $args{host} eq '';
    } else {
        $args{socket} = $listen;
    }

    warn "Listening on $listen for FCGI connections\n";

    $self->{_server} = AnyEvent::FCGI->new(
        %args,
        on_request => sub { $self->_on_request($app, @_) },
    );

    $self->{_cv} = AE::cv;
}

sub _on_request {
    my($self, $app, $request) = @_;

    my $env = $request->params;

    # deal with ligttpd/nginx path normalization
    my $uri = URI->new("http://localhost" .  $env->{REQUEST_URI});
    $env->{PATH_INFO} = URI::Escape::uri_unescape($uri->path);
    $env->{PATH_INFO} =~ s/^\Q$env->{SCRIPT_NAME}\E//;

    $env = {
        %$env,
        'psgi.version'      => [1,1],
        'psgi.url_scheme'   => ($env->{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
        'psgi.input'        => do { open my $io, "<", \$request->read_stdin || \''; $io },
        'psgi.errors'       => io_from_write_cb sub { $request->print_stderr(@_) },
        'psgi.multithread'  => 0,
        'psgi.multiprocess' => 0,
        'psgi.run_once'     => 0,
        'psgi.streaming'    => 1,
        'psgi.nonblocking'  => 1,
        'psgix.input.buffered' => 1,
    };

    my $res = Plack::Util::run_app($app, $env);

    if (ref $res eq 'ARRAY') {
        $self->handle_response($res, $request);
    } elsif (ref $res eq 'CODE') {
        $res->(sub { $self->handle_response($_[0], $request) });
    } else {
        die "Bad response: $res";
    }
}

sub handle_response {
    my($self, $res, $request) = @_;

    my $hdrs;
    $hdrs = "Status: $res->[0]\015\012";

    my $headers = $res->[1];
    while (my ($k, $v) = splice @$headers, 0, 2) {
        $hdrs .= "$k: $v\015\012";
    }
    $hdrs .= "\015\012";

    $request->print_stdout($hdrs);

    my $cb = sub { $request->print_stdout($_[0]) };
    my $body = $res->[2];
    if (defined $body) {
        Plack::Util::foreach($body, $cb);
        $request->finish;
    } else {
        return Plack::Util::inline_object
            write => $cb,
            close => sub { $request->finish };
    }
}


1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Plack::Handler::AnyEvent::FCGI - Asynchronous FCGI handler for PSGI using AnyEvent::FCGI

=head1 SYNOPSIS

  > plackup -s AnyEvent::FCGI myapp.psgi

=head1 DESCRIPTION

Plack::Handler::AnyEvent::FCGI is a PSGI adapter for L<AnyEvent::FCGI>
allowing AnyEvent based non-blocking applications running behind a web
server using FastCGI as a protocol.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2011- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::FCGI> L<Plack::Handler::AnyEvent::SCGI> L<Plack::Handler::FCGI>

=cut
