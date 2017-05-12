use strict;
use warnings;

use HTTP::Request::Common;
use File::Temp;
use Plack::Builder;
use Plack::VCR;
use Plack::Test;
use Test::More tests => 2;

sub run_test_psgi_for_requests {
    my ( $app, $requests ) = @_;

    my @request_senders = map { construct_request_sender($_) } @$requests;

    test_psgi $app, sub {
        my ( $cb ) = @_;
        foreach my $sender (@request_senders) {
            $cb->($sender->());
        }
    };
}

sub verify_saved_requests {
    my ( $vcr, $requests ) = @_;

    my @request_testers = map { construct_request_tester($_) } @$requests;
    foreach my $request_test (@request_testers) {
        my $interaction = $vcr->next;
        ok $interaction, 'next interaction';
        $request_test->($interaction->request);
    }
}

sub construct_request_sender {
    my ( $req_data ) = @_;

    my %req_methods = (
        GET  => \&GET,
        POST => \&POST,
    );

    my ( $method, $uri, $headers, $content ) = @{$req_data}{qw/method uri headers content/};
    my @args;
    if($headers) {
        push @args, @$headers;
    }
    if($content) {
        push @args, (Content => $content);
    }

    my $method_sub = $req_methods{$method};
    return sub {
        $method_sub->($uri, @args);
    };
}

sub construct_request_tester {
    my ( $req_data ) = @_;
    my ( $method, $uri, $headers, $content ) = @{$req_data}{qw/method uri headers content/};

    return sub {
        my ( $req ) = @_;

        is($req->method, $method, 'method');
        is($req->uri, $uri, 'uri');
        if($headers) {
            for(my $i = 0; $i < @$headers; $i += 2) {
                my ( $header, $value ) = @{$headers}[$i, $i + 1];
                is($req->header($header), $value, "header $header");
            }
        }
        if($content) {
            my @expected_content;
            for(my $i = 0; $i < @$content; $i += 2) {
                push @expected_content, join('=', map { my $v = $_; $v =~ s/ /+/g; $v } @{$content}[$i, $i + 1]);
            }
            my $expected_content = join('&', @expected_content);
            is($req->content, $expected_content, 'content');
        }
    };
}

sub runonce_middleware {
    my ( $value ) = @_;

    return sub {
        my ( $app ) = @_;

        sub {
            my ( $env ) = @_;

            $env->{'psgi.run_once'} = $value;
            $app->($env);
        };
    };
}

my @requests = (
    { method => 'GET', uri => '/' },

    { method => 'GET', uri => '/', headers => [ 'X-Made-Up-Header' => 17 ] },

    { method => 'POST', uri => '/foo', headers => [ 'X-Made-Up-Header' => 17 ],
      content => [ first_name => 'Rob', last_name  => 'Hoelz', full_name  => 'Rob Hoelz' ] },

    { method => 'GET', uri => '/bar?name=Rob%20Hoelz' },
);

subtest 'batch requests to one app instance' => sub {
    plan tests => 2;
    foreach my $runonce (0 .. 1) {
        subtest "runonce $runonce" => sub {
            plan tests => 16;

            my $tempfile = File::Temp->new;
            close $tempfile;

            my $app = builder {
                enable runonce_middleware($runonce);
                enable 'Recorder', output => $tempfile->filename;
                sub {
                    [ 200, ['Content-Type' => 'text/plain'], ['OK'] ];
                };
            };

            run_test_psgi_for_requests($app, \@requests);

            my $vcr = Plack::VCR->new(filename => $tempfile->filename);

            verify_saved_requests($vcr, \@requests);

            my $interaction = $vcr->next;
            ok !$interaction, 'iterator exhausted';
        };
    }
};

subtest 'send each request in separate app instance' => sub {
    plan tests => 2;
    foreach my $runonce (0 .. 1) {
        subtest "runonce $runonce" => sub {
            my $tempfile = File::Temp->new;
            close $tempfile;

            foreach my $request ( @requests ) {
                my $app = builder {
                    enable runonce_middleware($runonce);
                    enable 'Recorder', output => $tempfile->filename;
                    sub {
                        [ 200, ['Content-Type' => 'text/plain'], ['OK'] ];
                    };
                };

                run_test_psgi_for_requests($app, [ $request ]);
            }

            my $vcr = Plack::VCR->new(filename => $tempfile->filename);

            if($runonce) {
                # in run_once mode (CGI mode), requests are all appended to
                # the same output file
                verify_saved_requests($vcr, \@requests);

            } else {
                # not-run_once means the file will be overwritten each time
                # the PSGI app runs.  Only the last request will be in the
                # output file
                verify_saved_requests($vcr, [ $requests[-1] ] );
            }

            my $interaction = $vcr->next;
            ok !$interaction, 'iterator exhausted';
            done_testing();
        };
    }
};
