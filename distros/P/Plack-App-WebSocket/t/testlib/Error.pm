package testlib::Error;
use strict;
use warnings;
use Test::More;
use Test::Requires {
    "AnyEvent::HTTP" => "0"
};
use AnyEvent;
use AnyEvent::HTTP qw(http_get);
use Plack::App::WebSocket;
use testlib::Util qw(set_timeout run_server);

sub _str {
    my ($maybe_str) = @_;
    return defined($maybe_str) ? "$maybe_str" : "UNDEF";
}

sub _create_app {
    my %base = (on_establish => sub {
        fail("should not be established.");
    });
    my %apps = (
        default => Plack::App::WebSocket->new(%base),
        custom => Plack::App::WebSocket->new(%base, on_error => sub {
            my ($env) = @_;
            my $message = "custom error: " . $env->{"plack.app.websocket.error"} . ", " . _str($env->{"plack.app.websocket.error.handshake"});
            return [200, ["Content-Type", "text/plain", "Content-Length", length($message)], [$message]];
        }),
        streaming => Plack::App::WebSocket->new(%base, on_error => sub {
            my ($env) = @_;
            return sub {
                my $responder = shift;
                my $message = "error (streaming res): " . $env->{"plack.app.websocket.error"}. ", " . _str($env->{"plack.app.websocket.error.handshake"});
                $responder->([200, ["Content-Type", "text/plain", "Content-Length", length($message)], [$message]]);
            };
        })
    );
    return sub {
        my ($env) = @_;
        die "Unexpected request path" if $env->{PATH_INFO} !~ m{^/([^/]+)/?(.*)};
        my ($app_type, $option) = ($1, $2);
        my $app = $apps{$app_type};
        die "Unknown app type: $app_type" if not defined $app;
        if($option eq "no_io") {
            delete $env->{"psgix.io"};
        }
        return $app->call($env);
    };
}

sub run_tests {
    my ($server_runner) = @_;
    my ($port, $guard) = run_server($server_runner, _create_app());

    foreach my $case (
        {path => "/default/no_io", exp_status => 500, exp_body => qr/.*/},
        {path => "/default/", exp_status => 400, exp_body => qr/.*/},
        {path => "/custom/no_io", exp_status => 200, exp_body => qr/^custom error: not supported by the PSGI server, UNDEF$/},
        {path => "/custom/", exp_status => 200, exp_body => qr/^custom error: invalid request, handshake error/},
        {path => "/streaming/no_io", exp_status => 200, exp_body => qr/^error \(streaming res\): not supported by the PSGI server, UNDEF$/},
        {path => "/streaming/", exp_status => 200, exp_body => qr/^error \(streaming res\): invalid request, handshake error/},
    ) {
        my $cv_res = AnyEvent->condvar;
        http_get "http://127.0.0.1:$port$case->{path}", sub { $cv_res->send(@_) };
        my ($data, $headers) = $cv_res->recv;
        is $headers->{Status}, $case->{exp_status}, "$case->{path}: response status OK";
        like $data, $case->{exp_body}, "$case->{path}: response body OK";
    }
}


1;
