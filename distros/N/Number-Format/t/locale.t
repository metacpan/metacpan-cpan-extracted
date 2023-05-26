# -*- CPerl -*-

use Test::More;
use strict;
use warnings;

BEGIN {
    # Do not test when under OpenBSD; see
    # http://www.in-ulm.de/~mascheck/locale/ and
    # http://undeadly.org/cgi?action=article&sid=20030206041352
    plan skip_all => 'OpenBSD C library lacks locale support'
        if $^O =~ /^(openbsd|dragonfly)$/;
    plan 'no_plan';
}

BEGIN { use_ok('Number::Format') }
BEGIN { use_ok('POSIX') }

SKIP:
{
    setlocale(&LC_ALL, 'de_DE')
        or setlocale(&LC_ALL, 'de_DE.utf8')
            or setlocale(&LC_ALL, 'de_DE.ISO8859-1')
                or skip("Unable to set de_DE locale", 1);
    my $german = Number::Format->new();

    # On some sysetms (notably Mac OS X) the locale data is wrong for de_DE.
    # Force it to match what we would see on Linux so the test passes.
    $german->{n_cs_precedes}  = $german->{p_cs_precedes}  = '0';
    $german->{n_sep_by_space} = $german->{p_sep_by_space} = '1';
    $german->{thousands_sep}  = '.';
    $german->{decimal_point}  = ',';

    my $curr = $german->{int_curr_symbol}; # may be EUR or DEM
    my $num  = "123.456,79";

    is($german->format_price(123456.789), "$num $curr", "euros");
    is($german->unformat_number($num), 123456.79, "unformat German");
}

SKIP:
{
    setlocale(&LC_ALL, 'ru_RU')
        or setlocale(&LC_ALL, 'ru_RU.utf8')
            or setlocale(&LC_ALL, 'ru_RU.ISO8859-5')
                or skip("Unable to set ru_RU locale", 1);
    my $russian = Number::Format->new();

    # On some sysetms (notably Cygwin) the locale data is wrong for ru_RU.
    # Force it to match what we would see on Linux so the test passes.
    $russian->{n_sep_by_space} = $russian->{p_sep_by_space} = '1';
    my $sep = $russian->{mon_thousands_sep};
    my $dec = $russian->{mon_decimal_point};
    my $num = "123${sep}456${dec}79";

    like($russian->format_price(123456.789), qr/^$num RU[RB] $/, "rubles");
    is($russian->unformat_number("$num RUB "), 123456.79, "unformat rubles");
    is($russian->unformat_number($num), 123456.79, "unformat Russian 1");
    $num = "123${sep}456$russian->{decimal_point}79";
    is($russian->unformat_number($num), 123456.79, "unformat Russian 2");
}

my $num = "123,456.79";

SKIP:
{
    setlocale(&LC_ALL, 'en_US')
        or setlocale(&LC_ALL, 'en_US.utf8')
            or setlocale(&LC_ALL, 'en_US.ISO8859-1')
                or skip("Unable to set en_US locale", 1);
    my $english = Number::Format->new();

    is($english->format_price(123456.789), "USD $num", "USD");
    is($english->unformat_number($num), 123456.79, "unformat English");
}

setlocale(&LC_ALL, "C")
    or skip("Unable to set en_US locale", 1);
my $c = Number::Format->new();
is($c->format_price(123456.789, 2, "currency_symbol"),
   "\$ $num", "Dollar sign");
is($c->unformat_number($num), 123456.79, "unformat C");
