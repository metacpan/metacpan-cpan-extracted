use strict;
use lib "t";
use t::ReproxyTest;
use Test::More;

run_reproxy_tests
    reproxy_class => 'Reproxy::Callback',
    reproxy_args  => [
        cb => sub {
            my ($self, $res, $env, $url) = @_;
            # fake it
            local $env->{HTTP_X_REPROXY_URL} = $env->{HTTP_X_REPROXY_TO};
            @$res = @{ t::ReproxyTest::proxy_target($env) };
        }
    ]
;

done_testing;