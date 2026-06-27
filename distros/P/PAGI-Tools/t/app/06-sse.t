#!/usr/bin/env perl

use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use IO::Async::Loop;

use lib 'lib';

use PAGI::App::SSE::Pubsub;

my $loop = IO::Async::Loop->new;

sub run_async {
    my ($code) = @_;
    my $future = $code->();
    $loop->await($future);
}

# =============================================================================
# Test: PAGI::App::SSE::Pubsub
# =============================================================================

subtest 'App::SSE::Pubsub' => sub {

    subtest 'client_count starts at zero' => sub {
        my $count = PAGI::App::SSE::Pubsub->client_count;
        is $count, 0, 'starts with 0 clients';
    };

    subtest 'sends SSE headers' => sub {
        my $app = PAGI::App::SSE::Pubsub->new(channel => 'test_channel')->to_app;

        # We need to disconnect quickly
        my @events = ({ type => 'http.disconnect' });
        my $event_idx = 0;

        my @sent;
        run_async(async sub {
            await $app->(
                { type => 'http', path => '/events', headers => [] },
                async sub { $events[$event_idx++] },
                async sub  {
        my ($event) = @_; push @sent, $event },
            );
        });

        is $sent[0]{status}, 200, 'status 200';
        my $content_type = (grep { $_->[0] eq 'content-type' } @{$sent[0]{headers}})[0];
        is $content_type->[1], 'text/event-stream', 'correct content-type';
    };

    subtest 'publish class method' => sub {
        # Just verify the method exists and doesn't crash
        my $can_publish = PAGI::App::SSE::Pubsub->can('publish');
        ok $can_publish, 'has publish method';
        PAGI::App::SSE::Pubsub->publish('nonexistent', { data => 'test' });
        pass 'publish to empty channel succeeds';
    };

    subtest 'list_channels class method' => sub {
        my $can_list = PAGI::App::SSE::Pubsub->can('list_channels');
        ok $can_list, 'has list_channels method';
        my @channels = PAGI::App::SSE::Pubsub->list_channels;
        ok ref(\@channels) eq 'ARRAY', 'returns list';
    };
};

done_testing;
