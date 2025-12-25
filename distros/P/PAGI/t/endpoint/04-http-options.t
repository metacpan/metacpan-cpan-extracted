#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::Endpoint::HTTP;

package MockResponse {
    use Future::AsyncAwait;

    sub new {
        my ($class) = @_;
        bless { status => 200, headers => [] }, $class;
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
    async sub empty {
        my ($self) = @_;
        return $self;
    }
    async sub text {
        my ($self, $body, %opts) = @_;
        $self->{status} = $opts{status} if $opts{status};
        return $self;
    }
    sub get_header {
        my ($self, $name) = @_;
        for (@{$self->{headers}}) {
            return $_->[1] if lc($_->[0]) eq lc($name);
        }
        return undef;
    }
}

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

package CRUDEndpoint {
    use parent 'PAGI::Endpoint::HTTP';
    use Future::AsyncAwait;

    async sub get {
        my ($self, $req, $res) = @_;
        await $res->empty;
    }
    async sub post {
        my ($self, $req, $res) = @_;
        await $res->empty;
    }
    async sub delete {
        my ($self, $req, $res) = @_;
        await $res->empty;
    }
}

subtest 'OPTIONS returns allowed methods' => sub {
    my $endpoint = CRUDEndpoint->new;
    my $req = MockRequest->new('OPTIONS');
    my $res = MockResponse->new;

    $endpoint->dispatch($req, $res)->get;

    my $allow = $res->get_header('Allow');
    ok(defined $allow, 'Allow header set');
    like($allow, qr/GET/, 'includes GET');
    like($allow, qr/POST/, 'includes POST');
    like($allow, qr/DELETE/, 'includes DELETE');
    like($allow, qr/HEAD/, 'includes HEAD (implicit from GET)');
    like($allow, qr/OPTIONS/, 'includes OPTIONS');
};

subtest '405 response includes Allow header' => sub {
    my $endpoint = CRUDEndpoint->new;
    my $req = MockRequest->new('PATCH');  # Not implemented
    my $res = MockResponse->new;

    $endpoint->dispatch($req, $res)->get;

    my $allow = $res->get_header('Allow');
    ok(defined $allow, 'Allow header set on 405');
};

done_testing;
