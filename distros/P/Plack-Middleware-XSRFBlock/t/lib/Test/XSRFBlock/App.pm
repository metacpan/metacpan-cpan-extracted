package Test::XSRFBlock::App;
use strict;
use warnings;

use HTTP::Status qw(:constants);
use Plack::Request;
use Plack::Builder;

my $form = <<FORM;
<html>
    <head><title>the form</title></head>
    <body>
        <form action="/post" method="post">
            <input type="text" name="name" />
            <input type="submit" />
        </form>
    </body>
</html>
FORM

my $form_outside = <<FORM;
<html>
    <head><title>the form</title></head>
    <body>
        <form action="http://example.com/post" method="post">
            <input type="text" name="name" />
            <input type="submit" />
        </form>
        <form action="http://example.com:80/post" method="post">
            <input type="text" name="text" />
            <input type="submit" />
        </form>
    </body>
</html>
FORM

my $form_localhost = <<FORM;
<html>
    <head><title>the form</title></head>
    <body>
        <form action="http://localhost/post" method="post">
            <input type="text" name="name" />
            <input type="submit" />
        </form>
    </body>
</html>
FORM

my $form_localhost_port = <<FORM;
<html>
    <head><title>the form</title></head>
    <body>
        <form action="http://localhost:80/post" method="post">
            <input type="text" name="name" />
            <input type="submit" />
        </form>
    </body>
</html>
FORM

sub base_app {
    my $base_app = sub {
        my $req = Plack::Request->new(shift);
        my $name = $req->param('name') or die 'name not found';
        return  [ HTTP_OK, [ 'Content-Type' => 'text/plain' ], [ "Hello " . $name ] ]
    };
}

sub blocked_app {
    my $blocked_app = sub {
        # purposely pick values we wouldn't get under normal operations
        return  [
            HTTP_I_AM_A_TEAPOT,
            [ 'Content-Type' => 'text/teapot' ],
            [ q{That door is firmly closed!} ]
        ],
    };
}


sub mapped_app {
    my $mapped = builder {
        mount "/post" => base_app();
        mount "/form/html" => sub { [ HTTP_OK, [ 'Content-Type' => 'text/html; charset=utf-8' ], [ $form ] ] };
        mount "/form/xhtml" => sub { [ HTTP_OK, [ 'Content-Type' => 'application/xhtml+xml; charset=utf-8' ], [ $form ] ] };
        mount "/form/text" => sub { [ HTTP_OK, [ 'Content-Type' => 'text/plain' ], [ $form ] ] };
        mount "/form/html-charset" => sub { [ HTTP_OK, [ 'Content-Type' => 'text/html; charset=UTF-8' ], [ $form ] ] };
        mount "/form/xhtml-charset" => sub { [ HTTP_OK, [ 'Content-Type' => 'application/xhtml+xml; charset=UTF-8' ], [ $form ] ] };
        mount "/form/text-charset" => sub { [ HTTP_OK, [ 'Content-Type' => 'text/plain; charset=UTF-8' ], [ $form ] ] };

        mount "/form/html-outside" => sub { [ HTTP_OK, [ 'Content-Type' => 'text/html' ], [ $form_outside ] ] };
        mount "/form/html-localhost" => sub { [ HTTP_OK, [ 'Content-Type' => 'text/html' ], [ $form_localhost ] ] };
        mount "/form/html-localhost-port" => sub { [ HTTP_OK, [ 'Content-Type' => 'text/html' ], [ $form_localhost_port ] ] };
    };
}

sub setup_test_apps {
    my %app;
    my $mapped = mapped_app;

    $app{'psgix.input.non-buffered'} = builder {
        if ($ENV{PLACK_DEBUG}) {
            use Log::Dispatch;
            my $logger = Log::Dispatch->new(
                outputs => [
                    [
                        'Screen',
                        min_level => 'debug',
                        stderr    => 1,
                        newline   => 1
                    ]
                ],
            );
            enable "LogDispatch", logger => $logger;
        }
        enable 'XSRFBlock';
        $mapped;
    };

    # psgix.input.buffered
    $app{'psgix.input.buffered'} = builder {
        enable sub {
            my $app = shift;
            sub {
                my $env = shift;
                my $req = Plack::Request->new($env);
                my $content = $req->content; # <<< force psgix.input.buffered true.
                $app->($env);
            };
        };
        enable 'XSRFBlock';
        $mapped;
    };

    $app{'psgix.input.non-buffered.meta_tag'} = builder {
        if ($ENV{PLACK_DEBUG}) {
            use Log::Dispatch;
            my $logger = Log::Dispatch->new(
                outputs => [
                    [
                        'Screen',
                        min_level => 'debug',
                        stderr    => 1,
                        newline   => 1
                    ]
                ],
            );
            enable "LogDispatch", logger => $logger;
        }
        enable 'XSRFBlock',
            meta_tag => 'my_xsrf_meta_tag';
        $mapped;
    };

    $app{'psgix.input.non-buffered.blocked'} = builder {
        if ($ENV{PLACK_DEBUG}) {
            use Log::Dispatch;
            my $logger = Log::Dispatch->new(
                outputs => [
                    [
                        'Screen',
                        min_level => 'debug',
                        stderr    => 1,
                        newline   => 1
                    ]
                ],
            );
            enable "LogDispatch", logger => $logger;
        }
        enable 'XSRFBlock',
            blocked => blocked_app;
        $mapped;
    };

    $app{'psgix.input.non-buffered.token_per_request'} = builder {
        if ($ENV{PLACK_DEBUG}) {
            use Log::Dispatch;
            my $logger = Log::Dispatch->new(
                outputs => [
                    [
                        'Screen',
                        min_level => 'debug',
                        stderr    => 1,
                        newline   => 1
                    ]
                ],
            );
            enable "LogDispatch", logger => $logger;
        }
        enable 'XSRFBlock',
            token_per_request => 1;
        $mapped;
    };

    # psgix.input.buffered
    $app{'psgix.input.buffered.token_per_request'} = builder {
        enable sub {
            my $app = shift;
            sub {
                my $env = shift;
                my $req = Plack::Request->new($env);
                my $content = $req->content; # <<< force psgix.input.buffered true.
                $app->($env);
            };
        };
        enable 'XSRFBlock',
            token_per_request => 1;
        $mapped;
    };

    # create a new token only if the request is to a path which contains the string xhtml
    $app{'psgix.input.non-buffered.token_per_request_sub'} = builder {
        if ($ENV{PLACK_DEBUG}) {
            use Log::Dispatch;
            my $logger = Log::Dispatch->new(
                outputs => [
                    [
                        'Screen',
                        min_level => 'debug',
                        stderr    => 1,
                        newline   => 1
                    ]
                ],
            );
            enable "LogDispatch", logger => $logger;
        }
        enable 'XSRFBlock',
            token_per_request => sub { $_[1]->path =~ /xhtml/i };
        $mapped;
    };

    # psgix.input.buffered
    # create a new token only if the request is to a path which contains the string xhtml
    $app{'psgix.input.buffered.token_per_request_sub'} = builder {
        enable sub {
            my $app = shift;
            sub {
                my $env = shift;
                my $req = Plack::Request->new($env);
                my $content = $req->content; # <<< force psgix.input.buffered true.
                $app->($env);
            };
        };
        enable 'XSRFBlock',
            token_per_request => sub { $_[1]->path =~ /xhtml/i };
        $mapped;
    };

    $app{'psgix.input.non-buffered.token_per_session'} = builder {
        if ($ENV{PLACK_DEBUG}) {
            use Log::Dispatch;
            my $logger = Log::Dispatch->new(
                outputs => [
                    [
                        'Screen',
                        min_level => 'debug',
                        stderr    => 1,
                        newline   => 1
                    ]
                ],
            );
            enable "LogDispatch", logger => $logger;
        }
        enable 'XSRFBlock',
            token_per_request => 0; # <<< disable token_per_request
        $mapped;
    };

    $app{'psgix.input.non-buffered.request_header'} = builder {
        if ($ENV{PLACK_DEBUG}) {
            use Log::Dispatch;
            my $logger = Log::Dispatch->new(
                outputs => [
                    [
                        'Screen',
                        min_level => 'debug',
                        stderr    => 1,
                        newline   => 1
                    ]
                ],
            );
            enable "LogDispatch", logger => $logger;
        }
        enable 'XSRFBlock',
            header_name => 'X-XSRF-Token',
            meta_tag => 'my_xsrf_meta_tag';
        $mapped;
    };

    $app{'psgix.input.non-buffered.cookie_options'} = builder {
        if ($ENV{PLACK_DEBUG}) {
            use Log::Dispatch;
            my $logger = Log::Dispatch->new(
                outputs => [
                    [
                        'Screen',
                        min_level => 'debug',
                        stderr    => 1,
                        newline   => 1
                    ]
                ],
            );
            enable "LogDispatch", logger => $logger;
        }
        enable 'XSRFBlock',
            header_name => 'X-XSRF-Token',
            meta_tag => 'my_xsrf_meta_tag',
            cookie_options => { secure => 1, httponly => 1 };
        $mapped;
    };


    return \%app;
}
1;
