#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
use Test::Needs;

use Capture::Tiny qw(capture);
use Regexp::From::String qw(str_maybe_to_re str_to_re);

subtest str_maybe_to_re => sub {
    dies_ok { str_maybe_to_re({foo=>1}, 'bar') } 'unknown option -> dies';

    is_deeply(str_maybe_to_re('foo'), 'foo');
    is_deeply(str_maybe_to_re('/foo'), '/foo');
    is_deeply(str_maybe_to_re('qr(foo'), 'qr(foo');
    is_deeply(str_maybe_to_re('qr|foo|'), 'qr|foo|');
    is_deeply(str_maybe_to_re('qr(foo)x'), 'qr(foo)x');

    is_deeply(str_maybe_to_re('/foo./'), qr(foo.));
    is_deeply(str_maybe_to_re('qr(foo.)i'), qr(foo.)i);

    is_deeply(str_maybe_to_re({ci=>1}, '/foo/'), qr(foo)i);
    is_deeply(str_maybe_to_re({ci=>1}, 'qr(foo)i'), qr(foo)i);

    is_deeply(str_maybe_to_re({always_quote=>1}, '/foo/'), '/foo/');
    is_deeply(str_maybe_to_re({always_quote=>1}, 'qr(foo.)'), 'qr(foo.)');

    if ($] >= 5.014) { # regex syntax (?^:)
        is_deeply(str_maybe_to_re({anchored=>1}, '/foo/'), qr(\A(?^:foo)\z));
    }

    dies_ok { str_maybe_to_re('/foo(/') } 'invalid pattern -> dies';

    # safety option
    subtest "safety option" => sub {
        local $_ = "";

        # safety 0
        $main::tmp = 0; str_maybe_to_re({safety=>0}, '//   and $main::tmp = 1 and   //'); ok($main::tmp, 'unsafe //   (safety 0) -> ok');
        $main::tmp = 0; str_maybe_to_re({safety=>0}, 'qr() and $main::tmp = 1 and qr()'); ok($main::tmp, 'unsafe qr() (safety 0) -> ok');
        $main::tmp = 0; lives_ok { str_maybe_to_re({safety=>0}, '/(?{   $main::tmp = 1                          })/') } 'embedded code in //   (safety 0) -> ok';
        $main::tmp = 0; lives_ok { str_maybe_to_re({safety=>0}, 'qr((?{ $main::tmp = 1                          }))') } 'embedded code in qr() (safety 0) -> ok';

        # safety 1 (default)
        $main::tmp = 0; dies_ok { str_maybe_to_re(             '//   and ($main::tmp = 1 and   //') } 'unsafe //   (safety 1) -> dies';
        $main::tmp = 0; dies_ok { str_maybe_to_re(             'qr() and ($main::tmp = 1 and qr()') } 'unsafe qr() (safety 1) -> dies';
        $main::tmp = 0; dies_ok { str_maybe_to_re(             '/(?{   $main::tmp = 1                          })/') } 'embedded code in //   (safety 1) -> dies';
        $main::tmp = 0; dies_ok { str_maybe_to_re(             'qr((?{ $main::tmp = 1                          }))') } 'embedded code in qr() (safety 1) -> dies';

        subtest "safety 2" => sub {
            test_needs "Regexp::Util";

            $main::tmp = 0; dies_ok { str_maybe_to_re({safety=>2}, '//   and ($main::tmp = 1 and   //') } 'unsafe //   (safety 2) -> dies';
            $main::tmp = 0; dies_ok { str_maybe_to_re({safety=>2}, 'qr() and ($main::tmp = 1 and qr()') } 'unsafe qr() (safety 2) -> dies';
            $main::tmp = 0; dies_ok { str_maybe_to_re({safety=>2}, '/(?{   $main::tmp = 1                          })/') } 'embedded code in //   (safety 2) -> dies';
            $main::tmp = 0; dies_ok { str_maybe_to_re({safety=>2}, 'qr((?{ $main::tmp = 1                          }))') } 'embedded code in qr() (safety 2) -> dies';
        };
    };
};

subtest str_to_re => sub {
    dies_ok { str_to_re({foo=>1}, 'bar') } 'unknown option -> dies';

    is_deeply(str_to_re('foo['), qr(foo\[));
    is_deeply(str_to_re('/foo'), qr(\/foo));
    is_deeply(str_to_re({case_insensitive=>1}, '/foo'), qr(\/foo)i);
    is_deeply(str_to_re({ci=>1}, '/foo'), qr(\/foo)i);
    is_deeply(str_to_re({anchored=>1}, '/foo'), qr(\A\/foo\z));

    is_deeply(str_to_re('/foo/'), qr(foo));
    is_deeply(str_to_re({always_quote=>1}, '/foo/'), qr(\/foo\/));
    is_deeply(str_to_re({always_quote=>1}, 'qr(foo.)'), qr(qr\(foo\.\)));
    is_deeply(str_to_re('qr(foo)i'), qr(foo)i);

    is_deeply(str_to_re({ci=>1}, 'qr(foo)'), qr(foo)i);

    if ($] >= 5.014) { # regex syntax (?^:)
        is_deeply(str_to_re({anchored=>1}, '/foo/'), qr(\A(?^:foo)\z));
    }

    dies_ok { str_to_re('/foo(/') };

    # XXX test safety option too
};

DONE_TESTING:
done_testing();
