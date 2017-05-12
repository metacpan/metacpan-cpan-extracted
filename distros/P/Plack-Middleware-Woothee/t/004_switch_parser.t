use strict;
use warnings;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'lib');

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::Woothee;

{
    my $app = Plack::Middleware::Woothee->wrap(sub {
        my $env = shift;
        $env->{'psgix.woothee'}->parse;
        my $content = join ',',
            $env->{'psgix.woothee'}{name},
            $env->{'psgix.woothee'}{category},
            $env->{'psgix.woothee'}{os},
            $env->{'psgix.woothee'}{vendor},
            $env->{'psgix.woothee'}{version},
            $env->{'psgix.woothee'}->is_crawler;
        [ 200, [], [ $content ] ];
    }, parser => 'Moothee');

    test_psgi $app, sub {
        my $cb  = shift;

        my $res = $cb->(
            GET '/',
            'User-Agent' => 'Foo/1.0',
        );

        is $res->code, 200;
        is $res->content, 'MootheeName,MootheeCategory,MootheeOs,MootheeVender,MootheeVersion,UNKNOWN';
    };
}

done_testing;