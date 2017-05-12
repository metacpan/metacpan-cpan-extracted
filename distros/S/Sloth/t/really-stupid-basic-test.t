# Yes, this test isn't at all comprehensive. Real tests are coming!

use strict;
use warnings;

use lib 't/lib';

use HTTP::Request::Common;
use HTTP::Status qw( :constants );
use Plack::Test;
use Test::More;

use Zoo;

test_psgi
    app => Zoo->new,
    client => sub {
        my $cb = shift;
        {
            my $res = $cb->(GET '/animal/rabbit', Accept => '*/*');
            is($res->content => 'An animal');
            is($res->code => HTTP_OK);
        }

        {
            my $res = $cb->(PUT '/animal/wolf', Accept => '*/*');
            is($res->code => HTTP_METHOD_NOT_ALLOWED);
        }

        {
            my $res = $cb->(GET '/animal', Accept => '*/*');
            is($res->code => HTTP_NOT_FOUND);
        }
    };

done_testing;

