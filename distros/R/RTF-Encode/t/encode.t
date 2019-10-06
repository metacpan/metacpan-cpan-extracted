#!/usr/bin/env perl
# vim:ts=4:shiftwidth=4:expandtab

use strict;
use warnings;

use Test::More;
use RTF::Encode qw/ encode_rtf /;

is(encode_rtf("\n"), "\\line\n");
is(encode_rtf("\t"), "\\tab ");
is(encode_rtf(":"), "\\u58\\'3f");
is(encode_rtf(chr(0x2603)), "\\u9731\\'3f");
is(encode_rtf(chr(0x1f63b)), "\\u-10179\\'3f\\u-8645\\'3f", "Non-BMP character becomes a UTF-16 surrogate pair encoded as two signed decimals.");

done_testing();
