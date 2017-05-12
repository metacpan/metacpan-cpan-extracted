#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

{
    my $start = NetHack::Item->new("a blessed spellbook of force bolt");
    my $end = NetHack::Item->new("a white spellbook");

    ok($start->is_blessed);
    is($end->is_blessed, undef);
    is($end->is_uncursed, undef);
    is($end->is_cursed, undef);

    $end->did_polymorph_from($start);

    ok($end->is_blessed);
    ok(!$end->is_uncursed);
    ok(!$end->is_cursed);
}

{
    my $start = NetHack::Item->new("an uncursed spellbook of force bolt");
    my $end = NetHack::Item->new("a white spellbook");

    ok($start->is_uncursed);
    is($end->is_blessed, undef);
    is($end->is_uncursed, undef);
    is($end->is_cursed, undef);

    $end->did_polymorph_from($start);

    ok(!$end->is_blessed);
    ok($end->is_uncursed);
    ok(!$end->is_cursed);
}

{
    my $start = NetHack::Item->new("an cursed spellbook of force bolt");
    my $end = NetHack::Item->new("a white spellbook");

    ok($start->is_cursed);
    is($end->is_blessed, undef);
    is($end->is_uncursed, undef);
    is($end->is_cursed, undef);

    $end->did_polymorph_from($start);

    ok(!$end->is_blessed);
    ok(!$end->is_uncursed);
    ok($end->is_cursed);
}

{
    my $start = NetHack::Item->new("a spellbook of force bolt");
    my $end = NetHack::Item->new("a white spellbook");

    is($start->is_blessed, undef);
    is($start->is_uncursed, undef);
    is($start->is_cursed, undef);
    is($end->is_blessed, undef);
    is($end->is_uncursed, undef);
    is($end->is_cursed, undef);

    $end->did_polymorph_from($start);

    is($end->is_blessed, undef);
    is($end->is_uncursed, undef);
    is($end->is_cursed, undef);
}

done_testing;
