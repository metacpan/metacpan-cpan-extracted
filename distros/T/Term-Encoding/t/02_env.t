use strict;
use Test::More;

use Term::Encoding;

if ($^O eq 'MSWin32') {
    plan skip_all => "Don't test this on win32";
}

plan tests => 6;

# disable I18N::Langinfo for testing
no warnings 'redefine', 'prototype';
eval {
    require I18N::Langinfo;
    local $SIG{__WARN__} = sub { };
    *I18N::Langinfo::langinfo = sub { undef };
};

test_locale('ja_JP.EUC-JP', 'euc-jp');
test_locale('ja_JP.UTF-8', 'utf-8');
test_locale('en_US.UTF-8', 'utf-8');
test_locale('ja_JP.euc', 'euc-jp');
test_locale('japanese.euc', 'euc-jp');
test_locale('ko_KR.euc', 'euc-kr');

sub test_locale {
    my($locale, $expected) = @_;

    local $ENV{LANGUAGE} = $locale;
    my $encoding = Term::Encoding::get_encoding();
    is $encoding, $expected;
}




