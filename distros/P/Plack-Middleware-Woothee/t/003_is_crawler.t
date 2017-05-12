use strict;
use warnings;

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::Woothee;

our $UA = <<'_UA_';
Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1C28 Safari/419.3
_UA_
chomp $UA;

# is_crawler
{
    my $app = Plack::Middleware::Woothee->wrap(sub {
        my $env = shift;
        [ 200, [], [ $env->{'psgix.woothee'}->is_crawler ] ];
    });

    test_psgi $app, sub {
        my $cb  = shift;

        subtest UNKOWN => sub {
            my $res = $cb->(GET '/');

            is $res->code, 200;
            is $res->content, '0';
        };

        subtest "iPhone: is_crawler" => sub {
            my $res = $cb->(
                GET '/',
                'User-Agent' => $UA,
            );

            is $res->code, 200;
            is $res->content, '0';
        };

        subtest "Googlebot: is_crawler" => sub {
            my $res = $cb->(
                GET '/',
                'User-Agent' => 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
            );

            is $res->code, 200;
            is $res->content, '1';
        };

    };
}

done_testing;
