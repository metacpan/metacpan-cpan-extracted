use strict;
use warnings;
use Test2::V0;
use Future;
use Future::AsyncAwait;
use File::Temp;
use PAGI::Response;
use PAGI::Nano;

{
    package Local::EventResponse;

    sub new {
        my ($class, @events) = @_;
        return bless { events => \@events }, $class;
    }

    sub respond {
        my ($self, $send) = @_;
        return $send->($self->{events}[0])->then(sub {
            return $send->($self->{events}[1]);
        });
    }
}

sub mock_send {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };
    return ($send, \@sent);
}

sub invoke {
    my ($app, $scope) = @_;
    my ($send, $sent) = mock_send();
    my $future = $app->($scope, sub { Future->done }, $send);
    return ($future, $sent);
}

sub event_types {
    my ($sent) = @_;
    return [map { $_->{type} } @$sent];
}

my $handler_calls = 0;
my $buffered_app = app {
    not_found sub {
        ++$handler_calls;
        return PAGI::Response->text('Missing', status => 404);
    };
};

subtest 'buffered custom not_found uses the HTTP response event family' => sub {
    my ($future, $sent) = invoke($buffered_app, {
        type => 'http', method => 'GET', path => '/missing',
    });
    $future->get;

    is event_types($sent),
        ['http.response.start', 'http.response.body'],
        'plain HTTP response events are unchanged';
    is $handler_calls, 1, 'custom handler was invoked';
};

subtest 'buffered custom not_found uses the SSE decline event family' => sub {
    my ($future, $sent) = invoke($buffered_app, {
        type => 'sse', path => '/missing',
    });
    $future->get;

    is event_types($sent),
        ['sse.http.response.start', 'sse.http.response.body'],
        'SSE response events are translated';
    is $handler_calls, 2, 'custom handler was invoked';
};

subtest 'SSE rejects file-form custom not_found bodies' => sub {
    my ($fh, $filename) = File::Temp::tempfile();
    print {$fh} 'not found';
    close $fh;

    my $file_app = app {
        not_found sub {
            return PAGI::Response->new->status(404)->send_file($filename);
        };
    };
    my ($future, $sent) = invoke($file_app, {
        type => 'sse', path => '/missing',
    });

    like dies { $future->get }, qr/sse.*file|file.*sse/i,
        'file-form decline fails loudly with an SSE-specific message';
    is event_types($sent), ['sse.http.response.start'],
        'a translated start may be emitted before the future file body is rejected';
};

subtest 'buffered custom not_found uses the supported WebSocket denial event family' => sub {
    my ($future, $sent) = invoke($buffered_app, {
        type       => 'websocket',
        path       => '/missing',
        extensions => { 'websocket.http.response' => {} },
    });
    $future->get;

    is event_types($sent),
        ['websocket.http.response.start', 'websocket.http.response.body'],
        'WebSocket response events are translated when the extension is advertised';
    is $handler_calls, 3, 'custom handler was invoked';
};

subtest 'falsey WebSocket denial capability is still advertised' => sub {
    my $calls = 0;
    my $falsey_capability_app = app {
        not_found sub {
            ++$calls;
            return PAGI::Response->text('Missing', status => 404);
        };
    };
    my ($future, $sent) = invoke($falsey_capability_app, {
        type       => 'websocket',
        path       => '/missing',
        extensions => { 'websocket.http.response' => 0 },
    });
    $future->get;

    is event_types($sent),
        ['websocket.http.response.start', 'websocket.http.response.body'],
        'extension support is based on key presence, not value truthiness';
    is $calls, 1, 'custom handler was invoked for a falsey capability value';
};

subtest 'unsupported WebSocket bypasses the custom handler and closes' => sub {
    my ($future, $sent) = invoke($buffered_app, {
        type => 'websocket', path => '/missing',
    });
    $future->get;

    is $sent, [{ type => 'websocket.close' }],
        'a pre-accept close asks the server for a portable body-less 403';
    is $handler_calls, 3, 'custom handler was not invoked without the extension';
};

subtest 'supported WebSocket translates streaming custom not_found bodies' => sub {
    my $streaming_app = app {
        not_found sub {
            return PAGI::Response->new->status(404)->stream(async sub {
                my ($writer) = @_;
                await $writer->write('one');
                await $writer->write('two');
            });
        };
    };
    my ($future, $sent) = invoke($streaming_app, {
        type       => 'websocket',
        path       => '/missing',
        extensions => { 'websocket.http.response' => {} },
    });
    $future->get;

    is event_types($sent), [
        'websocket.http.response.start',
        'websocket.http.response.body',
        'websocket.http.response.body',
        'websocket.http.response.body',
    ], 'start and every streamed body use the WebSocket denial event family';
    is [map { +{ body => $_->{body}, more => $_->{more} } } @$sent[1 .. 3]], [
        { body => 'one', more => 1 },
        { body => 'two', more => 1 },
        { body => '',    more => 0 },
    ], 'stream data and final body retain their payload and continuation flags';
};

subtest 'supported WebSocket rejects file-form custom not_found bodies' => sub {
    my ($fh, $filename) = File::Temp::tempfile();
    print {$fh} 'not found';
    close $fh;

    my $file_app = app {
        not_found sub {
            return PAGI::Response->new->status(404)->send_file($filename);
        };
    };
    my ($future, $sent) = invoke($file_app, {
        type       => 'websocket',
        path       => '/missing',
        extensions => { 'websocket.http.response' => {} },
    });

    like dies { $future->get }, qr/websocket.*file|file.*websocket/i,
        'file-form denial fails loudly with a WebSocket-specific message';
    is event_types($sent), ['websocket.http.response.start'],
        'a translated start may be emitted before the future file body is rejected';
};

subtest 'translated protocol responses reject fh-form bodies' => sub {
    for my $protocol (qw(sse websocket)) {
        subtest $protocol => sub {
            my ($fh) = File::Temp::tempfile();
            my $fh_app = app {
                not_found sub {
                    return Local::EventResponse->new(
                        {
                            type    => 'http.response.start',
                            status  => 404,
                            headers => [],
                        },
                        {
                            type => 'http.response.body',
                            fh   => $fh,
                        },
                    );
                };
            };
            my %scope = (type => $protocol, path => '/missing');
            $scope{extensions} = { 'websocket.http.response' => {} }
                if $protocol eq 'websocket';
            my ($future, $sent) = invoke($fh_app, \%scope);

            like dies { $future->get }, qr/$protocol.*fh|fh.*$protocol/i,
                'fh-form body fails loudly with a protocol-specific message';
            is event_types($sent), ["$protocol.http.response.start"],
                'the fh-form body is not forwarded';
        };
    }
};

subtest 'translated sends do not mutate source event hashes' => sub {
    my $start = {
        type    => 'http.response.start',
        status  => 404,
        headers => [['content-type', 'text/plain']],
    };
    my $body = {
        type => 'http.response.body',
        body => 'Missing',
        more => 0,
    };
    my $source_app = app {
        not_found sub {
            return Local::EventResponse->new($start, $body);
        };
    };
    my ($future, $sent) = invoke($source_app, {
        type => 'sse', path => '/missing',
    });
    $future->get;

    is [$start->{type}, $body->{type}],
        ['http.response.start', 'http.response.body'],
        'source event types remain HTTP-shaped';
    is $sent, [
        { %$start, type => 'sse.http.response.start' },
        { %$body,  type => 'sse.http.response.body' },
    ], 'translated copies retain the source payload';
};

subtest 'custom not_found rejects an unexpected scope type' => sub {
    my ($future, $sent) = invoke($buffered_app, {
        type => 'custom', path => '/missing',
    });

    like dies { $future->get }, qr/not_found.*unsupported scope type.*custom/i,
        'unknown protocol scope fails loudly';
    is $sent, [], 'no invalid response event was emitted';
    is $handler_calls, 3, 'custom handler was not invoked for an unknown scope';
};

done_testing;
