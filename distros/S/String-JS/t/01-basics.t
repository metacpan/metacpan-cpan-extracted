#!perl -T

use 5.010;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.98;

use String::JS qw(
                     encode_js_string
                     decode_js_string
             );

subtest encode_js_string => sub {
    is(encode_js_string(""), q(""));
    is(encode_js_string("a'\"\n"), q("a'\\"\n"));

    is(encode_js_string("", 1), q(''));
    is(encode_js_string("a'\"\n", 1), q('a\\'"\n'));

    is(encode_js_string("", 2), q(''));
    is(encode_js_string("a'\"\n", 2), q('a\\\\'\\\"\\\\n'));

    dies_ok { encode_js_string('', 3) };
};

subtest decode_js_string => sub {
    decode_js_string(q("a $\\""), 'a $"');
    #is(decode_js_string(q('"'), '"')); # not yet implemented
    dies_ok { decode_js_string(q(1)) };
};

DONE_TESTING:
done_testing();
