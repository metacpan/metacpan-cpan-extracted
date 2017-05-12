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

# hash access
{
    my $app = Plack::Middleware::Woothee->wrap(sub {
        my $env = shift;
        $env->{'psgix.woothee'}->parse;
        my $content = join ',',
            $env->{'psgix.woothee'}{name},
            $env->{'psgix.woothee'}{category},
            $env->{'psgix.woothee'}{os},
            $env->{'psgix.woothee'}{vendor},
            $env->{'psgix.woothee'}{version};
        [ 200, [], [ $content ] ];
    });

    test_psgi $app, sub {
        my $cb  = shift;

        subtest UNKOWN => sub {
            my $res = $cb->(GET '/');

            is $res->code, 200;
            is $res->content, 'UNKNOWN,UNKNOWN,UNKNOWN,UNKNOWN,UNKNOWN';
        };

        subtest "iPhone: name" => sub {
            my $res = $cb->(
                GET '/',
                'User-Agent' => $UA,
            );

            is $res->code, 200;
            is $res->content, 'Safari,smartphone,iPhone,Apple,3.0';
        };

    };
}

# parse immediately, and hash access
{
    my $app = Plack::Middleware::Woothee->wrap(sub {
        my $env = shift;
        my $content = join ',',
            $env->{'psgix.woothee'}{name},
            $env->{'psgix.woothee'}{category},
            $env->{'psgix.woothee'}{os},
            $env->{'psgix.woothee'}{vendor},
            $env->{'psgix.woothee'}{version};
        [ 200, [], [ $content ] ];
    }, parse_all_req => 1);

    test_psgi $app, sub {
        my $cb  = shift;

        subtest "parse immediately" => sub {
            my $res = $cb->(
                GET '/',
                'User-Agent' => $UA,
            );

            is $res->code, 200;
            is $res->content, 'Safari,smartphone,iPhone,Apple,3.0';
        };

    };
}

# method call
{
    my @list = (
        [ 'name'     => 'Safari' ],
        [ 'category' => 'smartphone' ],
        [ 'os'       => 'iPhone' ],
        [ 'vendor'   => 'Apple' ],
        [ 'version'  => '3.0' ],
    );

    for my $pairs (@list) {
        _test( @{$pairs} );
    };
}

sub _test {
    my ($name, $expect) = @_;

    my $app = Plack::Middleware::Woothee->wrap(sub {
        my $env = shift;
        [ 200, [], [ $env->{'psgix.woothee'}->$name() ] ];
    });

    test_psgi $app, sub {
        my $cb  = shift;

        subtest UNKOWN => sub {
            my $res = $cb->(GET '/');

            is $res->code, 200;
            is $res->content, 'UNKNOWN';
        };

        subtest "iPhone: $name" => sub {
            my $res = $cb->(
                GET '/',
                'User-Agent' => $UA,
            );

            is $res->code, 200;
            is $res->content, $expect;
        };

    };
}

done_testing;
