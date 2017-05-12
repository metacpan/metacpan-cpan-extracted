#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

incorporate_ok "a scroll labeled KIRJE" => "a scroll of genocide" => {
    identity   => 'scroll of genocide',
    appearance => 'scroll labeled KIRJE',
};

# this could happen if as a wizard you start with geno, and so never have the
# appearance, then later on get mind flayed
incorporate_ok "a scroll of genocide" => "a scroll labeled KIRJE" => {
    identity   => 'scroll of genocide',
    appearance => 'scroll labeled KIRJE',
};

done_testing;
