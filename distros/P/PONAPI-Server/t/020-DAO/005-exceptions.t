#!perl
use strict;
use warnings;

use Test::More;
use JSON::MaybeXS;

use PONAPI::Exception;

use PONAPI::DAO;
use Test::PONAPI::Repository::MockDB;
use Test::PONAPI::Repository::MockDB::Loader;

my $repository = Test::PONAPI::Repository::MockDB->new;
my $dao = PONAPI::DAO->new( version => '1.0', repository => $repository );
isa_ok($dao, 'PONAPI::DAO');

subtest '... throwing a simple exception' => sub {

    {
        my $this_sub_throws_an_exception = sub {
            PONAPI::Exception->throw(
                message => "invalid param `X`",
                bad_request_data => 1,
            );
        };

        my $e;
        eval {
            $this_sub_throws_an_exception->();
            1;
        } or do {
            $e = $@ || 'Unknown error';
        };

        isa_ok($e, 'PONAPI::Exception');
        is($e->status, 400, '... has the default 400 status');
        is($e->as_string, 'invalid param `X`', '... has the correct string output');
        is($e->json_api_version, '1.0', '... has the correct API version');
        is_deeply(
            [ $e->as_response ],
            [
                400,
                [],
                {
                    errors  => [ { status => 400, detail => "Bad request data: invalid param `X`" } ],
                    jsonapi => { version => '1.0' },
                }
            ],
            "... exception response is correct"
        );

    }

};

# TODO: we need more testing for the various options available for exceptions

done_testing;
