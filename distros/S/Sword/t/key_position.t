#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 7;

use Sword;

my $library = Sword::Manager->new;
my $kjv = $library->get_module('KJV');

SKIP: {
    skip "KJV is not installed", 5 unless $kjv;

    $kjv->set_key('eph2.8');

    is($kjv->render_text, "For by grace are ye saved through faith; and that not of yourselves: it is the gift of God:\n", "Ephesians 2:8 is as expected");

    $kjv->increment;
    
    is($kjv->render_text, "Not of works, lest any man should boast.\n", "Increment gets us Ephesians 2:9");

    $kjv->decrement;

    is($kjv->render_text, "For by grace are ye saved through faith; and that not of yourselves: it is the gift of God:\n", "Decrement returns us to Ephesians 2:8");

    $kjv->increment(2);

    is($kjv->render_text, "For we are his workmanship, created in Christ Jesus unto good works, which God hath before ordained that we should walk in them.\n", "Increment 2 gets us to Ephesians 2:10");

    $kjv->decrement(2);

    is($kjv->render_text, "For by grace are ye saved through faith; and that not of yourselves: it is the gift of God:\n", "Decrement 2 returns us to Ephesians 2:8");

    $kjv->top;
    is($kjv->render_text, "In the beginning God created the heaven and the earth.", "Top takes us to Genesis 1:1");

    $kjv->bottom;
    is($kjv->render_text, "The grace of our Lord Jesus Christ be with you all. Amen.\n", "Bottom takes us to Revelation 22:21");
}
