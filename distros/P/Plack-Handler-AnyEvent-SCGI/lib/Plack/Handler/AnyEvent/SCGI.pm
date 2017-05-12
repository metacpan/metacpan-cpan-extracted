package Plack::Handler::AnyEvent::SCGI;

use strict;
use 5.008_001;
our $VERSION = '0.03';

use AnyEvent::SCGI;
use URI::Escape;
use Plack::Util;

sub new {
    my($class, %args) = @_;
    bless { port => 9999, %args }, $class;
}

sub run {
    my $self = shift;
    $self->register_service(@_);
    $self->{_cv}->recv;
}

sub register_service {
    my($self, $app) = @_;

    $self->{_server} = scgi_server $self->{host} || '127.0.0.1', $self->{port}, sub {
        my($handle, $env, $content_r, $fatal, $error) = @_;
        $self->handle_request($app, $handle, $env, $content_r) unless $fatal;
    };

    $self->{_cv} = AE::cv;
}

sub handle_request {
    my($self, $app, $handle, $env, $content_r) = @_;

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
        'psgi.input'        => do { open my $io, "<", $content_r || \''; $io },
        'psgi.errors'       => *STDERR,
        'psgi.multithread'  => Plack::Util::FALSE,
        'psgi.multiprocess' => Plack::Util::FALSE,
        'psgi.run_once'     => Plack::Util::FALSE,
        'psgi.streaming'    => Plack::Util::TRUE,
        'psgi.nonblocking'  => Plack::Util::TRUE,
        'psgix.input.buffered' => Plack::Util::TRUE,
    };

    my $res = Plack::Util::run_app $app, $env;

    if (ref $res eq 'ARRAY') {
        $self->handle_response($res, $handle);
    } elsif (ref $res eq 'CODE') {
        $res->(sub { $self->handle_response($_[0], $handle) });
    } else {
        die "Bad response $res";
    }
}

sub handle_response {
    my($self, $res, $handle) = @_;

    my $hdrs;
    $hdrs = "Status: $res->[0]\015\012";

    my $headers = $res->[1];
    while (my ($k, $v) = splice @$headers, 0, 2) {
        $hdrs .= "$k: $v\015\012";
    }
    $hdrs .= "\015\012";

    $handle->push_write($hdrs);

    my $cb = sub { $handle->push_write($_[0]) };
    my $body = $res->[2];
    if (defined $body) {
        Plack::Util::foreach($body, $cb);
        $handle->push_shutdown;
    } else {
        return Plack::Util::inline_object
            write => $cb,
            close => sub { $handle->push_shutdown };
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Plack::Handler::AnyEvent::SCGI - PSGI handler on AnyEvent::SCGI

=head1 SYNOPSIS

  plackup -s AnyEvent::SCGI --port 22222

=head1 DESCRIPTION

Plack::Handler::AnyEvent::SCGI is a standalone SCGI daemon running on L<AnyEvent::SCGI>.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::SCGI> L<Plack::Handler::SCGI>

=cut
