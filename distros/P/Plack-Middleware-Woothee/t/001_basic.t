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

# object
{
    my $app = Plack::Middleware::Woothee->wrap(sub {
        my $env = shift;
        [ 200, [], [ ref($env->{'psgix.woothee'}) ] ];
    });

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');

        is $res->code, 200, 'basic response';
        is $res->content, 'Plack::Middleware::Woothee::Object', 'psgix.woothee';
    };
}

done_testing;
