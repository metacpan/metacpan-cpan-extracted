#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use Regexp::Stringify qw(stringify_regexp);

# arg:plver
is(stringify_regexp(regexp=>qr/a/ , plver=>'5.14.0'), '(^:a)');
is(stringify_regexp(regexp=>qr/a/i, plver=>'5.14.0'), '(^i:a)');
is(stringify_regexp(regexp=>qr/a/ , plver=>'5.12.0'), '(?:(?-)a)');
is(stringify_regexp(regexp=>qr/a/i, plver=>'5.12.0'), '(?:(?i-)a)');

# strip unknown regex modifiers
if (version->parse($^V) >= version->parse('5.14.0')) {
    eval q|
    is(stringify_regexp(regexp=>qr/a/ui, plver=>'5.14.0'), '(^ui:a)');
    is(stringify_regexp(regexp=>qr/a/ui, plver=>'5.12.0'), '(?:(?i-)a)');
    }|;
}

#arg: with_qr
is(stringify_regexp(regexp=>qr/a/ , plver=>'5.14.0', with_qr=>1), 'qr(a)');
is(stringify_regexp(regexp=>qr/a/i, plver=>'5.14.0', with_qr=>1), 'qr(a)i');

# test special characters
is(stringify_regexp(regexp=>qr!(a)\(b/\/!, plver=>'5.14.0'),
   '(^:(a)\\(b/\\/)');

DONE_TESTING:
done_testing();
