use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::MockObject;
use Test::MockModule;
use URI::Escape;
use HTTP::Response;

BEGIN {
    use_ok('Net::Google::DataAPI::Role::Service');
}

{
    package MyService;
    use Any::Moose;
    with 'Net::Google::DataAPI::Role::Service';
}

{
    my $s = MyService->new;
    my $req = HTTP::Request->new;
    is $s->prepare_request($req), $req;
}

done_testing;
