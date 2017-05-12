package t::ReproxyTest;
use strict;
use parent qw(Exporter);
our @EXPORT = qw(run_reproxy_tests);

use Test::More;
use Plack::Runner;
use Plack::Test;
use Plack::Builder;
use Test::TCP;
use HTTP::Request::Common;

sub run_reproxy_tests(@) {
    my (%args) = @_;

    my $reproxy_class = $args{reproxy_class};
    my $reproxy_args  = $args{reproxy_args};
    my $server = start_proxy_target();
    test_psgi
        app => builder {
            enable $reproxy_class, @$reproxy_args;
            sub {
                my $env = shift;
                my @hdrs;
                if ($env->{REQUEST_METHOD} ne 'HEAD' && (my $reproxy_url = $env->{HTTP_X_REPROXY_TO} ) ) {
                    push @hdrs, ("X-Reproxy-URL" => $reproxy_url);
                } else {
                    push @hdrs, "Content-Type" => "text/html";
                }

                return [ 200, \@hdrs, [ "NO REPROXY" ] ];
            }
        },
        client => test_cb( $server->port )
    ;
}

sub proxy_target {
    my $env = shift;

    # Make sure that we received the proper input
    my $input = do { local $/; my $fh = $env->{'psgi.input'}; <$fh> };

    local @$env{qw(psgi.errors psgi.input psgix.io)};
    return [ 200,
        [ 'Content-Type' => 'text/plain' ],
        [ "REPROXY SUCCESS", $input || '' ]
    ];
}

sub start_proxy_target {
    # Create a dummy server to reproxy to
    my $server = Test::TCP->new(
        code => sub {
            my $port = shift;
            my $runner = Plack::Runner->new();
            $runner->parse_options( '--host' => '127.0.0.1', '--port' => $port );
            $runner->run(\&proxy_target);
        }
    );
}
    
sub test_cb {
    my $port = shift;
    return sub {
        my $cb = shift;

        note "Force reproxy";
        my $res = $cb->( GET "http://127.0.0.1/",
            'X-Reproxy-To' => sprintf "http://127.0.0.1:%d/", $port
        );
    
        ok $res->is_success, "Reproxy request is success";
        if ( is $res->content_type, 'text/plain', 'content-type is text/plain') {
            is $res->content, "REPROXY SUCCESS";
        }
    
        note "Force reproxy (POST)";
        $res = $cb->( POST "http://127.0.0.1/",
            'X-Reproxy-To' => sprintf "http://127.0.0.1:%d/", $port,
            Content => [ "foo" => 1, "bar" => 2 ],
        );
        ok $res->is_success, "Reproxy request is success";
        if ( is $res->content_type, 'text/plain', 'content-type is text/plain') {
            is $res->content, "REPROXY SUCCESS";
        }
    
    
        note "No reproxy";
        $res = $cb->( GET "http://127.0.0.1/" );
    
        ok $res->is_success, "Reproxy request is success";
        if ( is $res->content_type, 'text/html', 'content-type is text/html') {
            is $res->content, "NO REPROXY";
        }
    
        note "No reproxy (HEAD)";
        $res = $cb->( HEAD "http://127.0.0.1/",
            'X-Reproxy-To' => sprintf "http://127.0.0.1:%d/", $port
        );
    
        ok $res->is_success, "Reproxy request is success";
        if ( is $res->content_type, 'text/html', 'content-type is text/html') {
            is $res->content, "NO REPROXY";
        }
    }
}

1;
