#!perl

use strict;
use warnings;
use Test::More tests => 2;
use I18N::Langinfo qw/langinfo CODESET/;
use PerlIO::locale;

use POSIX qw(locale_h);

SKIP: {
    setlocale(LC_CTYPE, "en_US.UTF-8") or skip("no such locale", 2) if langinfo(CODESET) ne 'UTF-8';

    open(O, ">:locale", "foo") or die $!;
    print O "\x{430}";
    close O;
    open(I, "<", "foo") or die $!;
    local $/ = \1;
    is(ord(<I>), 0xd0);
    is(ord(<I>), 0xb0);
    close I;
}

END { unlink "foo" }
