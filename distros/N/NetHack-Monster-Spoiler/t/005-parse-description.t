#!/usr/bin/env perl
# vim: sw=4 et
use strict;
use warnings;
use Test::More tests => 19;

use NetHack::Monster::Spoiler;

sub parse {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($str, $want) = @_;

    my $got = NetHack::Monster::Spoiler->parse_description($str);

    for my $k (keys %$got) {
        delete $got->{$k} if !exists($want->{$k});
    }

    is_deeply($got, $want, $str);
}

parse 'Oracle' =>
    { monster => 'Oracle' };
parse 'Asidonhopo' =>
    { name => 'Asidonhopo', monster => 'shopkeeper' };
parse 'Asidonhopo the yellow dragon' =>
    { name => 'Asidonhopo', monster => 'yellow dragon' };
parse 'the invisible guardian naga hatchling renegade priest of Amaterasu Omikami' =>
    { god => 'Amaterasu Omikami', monster => 'guardian naga hatchling', priest => 1, renegade => 1, invisible => 1 };
parse 'guardian Angel of Kos' =>
    { monster => 'Angel', god => 'Kos', tame => 1 };
parse 'invisible saddled warhorse called Smasher' =>
    { monster => 'warhorse', invisible => 1, saddled => 1, name => 'Smasher' };
parse 'doy\'s ghost' =>
    { monster => 'ghost', name => 'doy' };
parse 'ross\' ghost' =>
    { monster => 'ghost', name => 'ross' };
parse 'its ghost' =>
    { monster => 'ghost', name => 'it' };
parse 'Ken the invisible Ryoshu' => # not a farlook result, melee etc
    { monster => 'samurai', invisible => 1, name => 'Ken' };
parse 'woman-at-arms' =>
    { monster => 'valkyrie' };
parse 'Minion of Huhetotl' =>
    { monster => 'Minion of Huhetotl' };
parse 'Fido' => # melee result
    { name => 'Fido' };
parse 'Neferet the Green' =>
    { monster => 'Neferet the Green' };
parse 'coyote - Canis latrans' =>
    { monster => 'coyote' };
parse 'high priestess' =>
    { monster => 'high priest', priest => 1, high_priest => 1 };
parse 'high priestess of Kos' =>
    { monster => 'high priest', priest => 1, high_priest => 1, god => 'Kos' };
parse 'poobah of Moloch' =>
    { monster => 'aligned priest', priest => 1, god => 'Moloch' };
parse 'Y-crad the invisible shopkeeper' =>
    { monster => 'shopkeeper', invisible => 1, name => 'Y-crad' };

