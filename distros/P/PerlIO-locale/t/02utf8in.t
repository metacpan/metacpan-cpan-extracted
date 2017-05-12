#!perl

use strict;
use warnings;
use Test::More tests => 1;
use I18N::Langinfo qw/langinfo CODESET/;
use PerlIO::locale;

use POSIX qw(locale_h);

SKIP: {
    setlocale(LC_CTYPE, "en_US.UTF-8") or skip("no such locale", 1) if langinfo(CODESET) ne 'UTF-8';

    open(O, ">", "foo") or die $!;
    print O "\xd0\xb0";
    close O;
    open(I, "<:locale", "foo") or die $!;
    is(ord(<I>), 0x430);
    close I;
}

END { unlink "foo" }
