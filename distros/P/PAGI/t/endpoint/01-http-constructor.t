#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';

subtest 'can create endpoint subclass' => sub {
    require PAGI::Endpoint::HTTP;

    package MyEndpoint {
        use parent 'PAGI::Endpoint::HTTP';
        use Future::AsyncAwait;

        async sub get {
            my ($self, $req, $res) = @_;
            await $res->text("Hello");
        }
    }

    my $endpoint = MyEndpoint->new;
    isa_ok($endpoint, 'PAGI::Endpoint::HTTP');
    isa_ok($endpoint, 'MyEndpoint');
};

subtest 'factory class methods have defaults' => sub {
    require PAGI::Endpoint::HTTP;

    is(PAGI::Endpoint::HTTP->request_class, 'PAGI::Request', 'default request_class');
    is(PAGI::Endpoint::HTTP->response_class, 'PAGI::Response', 'default response_class');
};

subtest 'subclass can override factory classes' => sub {
    package CustomEndpoint {
        use parent 'PAGI::Endpoint::HTTP';

        sub request_class { 'My::Request' }
        sub response_class { 'My::Response' }
    }

    is(CustomEndpoint->request_class, 'My::Request', 'custom request_class');
    is(CustomEndpoint->response_class, 'My::Response', 'custom response_class');
};

done_testing;
