#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::Endpoint::HTTP;

# Mock request that returns method
package MockRequest {
    sub new {
        my ($class, $method) = @_;
        bless { method => $method }, $class;
    }
    sub method {
        my ($self) = @_;
        $self->{method};
    }
}

# Mock response that captures what was sent
package MockResponse {
    use Future::AsyncAwait;
    sub new {
        my ($class) = @_;
        bless { sent => undef, status => 200, headers => [] }, $class;
    }
    sub status {
        my ($self, $s) = @_;
        $self->{status} = $s if defined $s;
        return $self;
    }
    sub header {
        my ($self, $name, $value) = @_;
        push @{$self->{headers}}, [$name, $value];
        return $self;
    }
    async sub text {
        my ($self, $body, %opts) = @_;
        $self->{sent} = $body;
        $self->{status} = $opts{status} if $opts{status};
        return $self;
    }
    sub sent {
        my ($self) = @_;
        $self->{sent};
    }
}

package TestEndpoint {
    use parent 'PAGI::Endpoint::HTTP';
    use Future::AsyncAwait;

    async sub get {
        my ($self, $req, $res) = @_;
        await $res->text("GET response");
    }

    async sub post {
        my ($self, $req, $res) = @_;
        await $res->text("POST response");
    }
}

subtest 'dispatches GET to get method' => sub {
    my $endpoint = TestEndpoint->new;
    my $req = MockRequest->new('GET');
    my $res = MockResponse->new;

    $endpoint->dispatch($req, $res)->get;

    is($res->sent, 'GET response', 'GET dispatched correctly');
};

subtest 'dispatches POST to post method' => sub {
    my $endpoint = TestEndpoint->new;
    my $req = MockRequest->new('POST');
    my $res = MockResponse->new;

    $endpoint->dispatch($req, $res)->get;

    is($res->sent, 'POST response', 'POST dispatched correctly');
};

subtest 'returns 405 for unimplemented method' => sub {
    my $endpoint = TestEndpoint->new;  # No PUT method defined
    my $req = MockRequest->new('PUT');
    my $res = MockResponse->new;

    $endpoint->dispatch($req, $res)->get;

    like($res->sent, qr/405|Method Not Allowed/i, '405 for unimplemented');
};

subtest 'HEAD dispatches to get if no head method' => sub {
    my $endpoint = TestEndpoint->new;
    my $req = MockRequest->new('HEAD');
    my $res = MockResponse->new;

    $endpoint->dispatch($req, $res)->get;

    is($res->sent, 'GET response', 'HEAD falls back to GET');
};

done_testing;
