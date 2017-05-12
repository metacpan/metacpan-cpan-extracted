use strict;
use Test::More 0.98;

use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::Mock::Guard qw(mock_guard);
use JSON::XS qw(decode_json);

subtest 'without error ' => sub {
    my $app = builder {
        enable 'PostErrorToSlack';
        sub {
            return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello, World!' ] ];
        }
    };

    test_psgi $app => sub {
        my $server = shift;

        my $res = $server->(GET "http://localhost/");
        is $res->code, 200;
        is $res->content, 'Hello, World!';
    };
};

subtest 'with error' => sub {
    my $app = builder {
        enable 'PostErrorToSlack',
            webhook_url => 'http://example.com/';
        sub {
            die 'expected error';
        }
    };

    test_psgi $app => sub {
        my $server = shift;


        my $req;
        my $g = mock_guard 'LWP::UserAgent' => {
            post => sub {
                my $self = shift;
                $req = \@_;
            },
        };

        my $res = $server->(GET "http://localhost/");
        is $res->code, 500;
        like  $res->content, qr{expected error};

        is $g->call_count('LWP::UserAgent', 'post'), 1;

        is $req->[0], 'http://example.com/';

        my $payload =  decode_json($req->[1]->{payload});
        like $payload->{text}, qr{encountered an error};
        like $payload->{text}, qr{expected error};
        is_deeply [ sort keys %$payload ], ['text'];
    };
};

subtest 'customize' => sub {
    my $app = builder {
        enable 'PostErrorToSlack',
            webhook_url => 'http://example.com/',
            channel => '#custom',
            username => 'custom_error',
            icon_emoji => ':sushi:',
            icon_url => 'http://image.example.com/icon.jpg';
        sub {
            die 'expected error';
        }
    };

    test_psgi $app => sub {
        my $server = shift;


        my $req;
        my $g = mock_guard 'LWP::UserAgent' => {
            post => sub {
                my $self = shift;
                $req = \@_;
            },
        };

        my $res = $server->(GET "http://localhost/");
        is $res->code, 500;
        like  $res->content, qr{expected error};

        is $g->call_count('LWP::UserAgent', 'post'), 1;

        is $req->[0], 'http://example.com/';

        my $payload =  decode_json($req->[1]->{payload});
        is_deeply [ sort keys %$payload ], [qw(channel icon_emoji icon_url text username)];

        like $payload->{text}, qr{encountered an error};
        like $payload->{text}, qr{expected error};
        is $payload->{channel}, '#custom';
        is $payload->{username}, 'custom_error';
        is $payload->{icon_emoji}, ':sushi:';
        is $payload->{icon_url}, 'http://image.example.com/icon.jpg';
    };
};

done_testing;
