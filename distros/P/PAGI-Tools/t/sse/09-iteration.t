#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::SSE;

subtest 'each iterates over arrayref' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };

    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, $send);
    $sse->start->get;

    my @items = ('one', 'two', 'three');

    $sse->each(\@items, async sub {
        my ($item) = @_;
        await $sse->send($item);
    })->get;

    my @data_sent = map { $_->{data} } grep { $_->{type} eq 'sse.send' } @sent;
    is(\@data_sent, ['one', 'two', 'three'], 'all items sent');
};

subtest 'each with transformer returns event spec' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };

    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, $send);
    $sse->start->get;

    my @items = ({ name => 'Alice' }, { name => 'Bob' });

    $sse->each(\@items, async sub {
        my ($item, $index) = @_;
        return {
            data  => $item,
            event => 'user',
            id    => $index,
        };
    })->get;

    my @events = grep { $_->{type} eq 'sse.send' } @sent;
    is($events[0]{event}, 'user', 'first event type');
    is($events[0]{id}, '0', 'first event id');
    is($events[1]{id}, '1', 'second event id');
};

subtest 'each with coderef iterator' => sub {
    my @sent;
    my $send = sub { push @sent, $_[0]; Future->done };

    my $sse = PAGI::SSE->new({ type => 'sse' }, sub {}, $send);
    $sse->start->get;

    my @items = (1, 2, 3);
    my $idx = 0;
    my $iterator = sub {
        return undef if $idx >= @items;
        return $items[$idx++];
    };

    $sse->each($iterator, async sub {
        my ($item) = @_;
        await $sse->send("item: $item");
    })->get;

    my @data_sent = map { $_->{data} } grep { $_->{type} eq 'sse.send' } @sent;
    is(\@data_sent, ['item: 1', 'item: 2', 'item: 3'], 'coderef iterator works');
};

done_testing;
