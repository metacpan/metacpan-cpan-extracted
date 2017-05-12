#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my %equivalents = (
    blessed => ['holy'],
    cursed  => ['unholy'],
);

for my $buc (qw/blessed uncursed cursed/) {
    my %others = map { $_ => 1 } qw/blessed uncursed cursed/;
    delete $others{$buc};

    for my $input ($buc, @{ $equivalents{$buc} || [] }) {
        for (["is_$buc" => 1], [buc => $input], []) {
            my $item = NetHack::Item->new(raw => "a long sword", @$_);
            $item->buc($input) if !@$_;

            my $method = "is_$buc";
            ok($item->$method, "the sword is $buc");
            is($item->buc, $buc, "correct value from ->buc");

            for my $buc (keys %others) {
                my $method = "is_$buc";
                is($item->$method, 0, "the sword is not $buc");
            }
        }

        my $method = "is_$buc";

        my $sword = NetHack::Item->new("a $input long sword");
        ok($sword->$method, "the sword is $buc, parsed from the description");
        is($sword->buc, $buc, "correct value from ->buc");

        for my $buc (keys %others) {
            my $method = "is_$buc";
            is($sword->$method, 0, "the sword is NOT $input");
        }
    }
}

my $sword = NetHack::Item->new("a long sword");
is($sword->$_, undef, $_) for qw/is_blessed is_uncursed is_cursed/;

$sword->is_cursed(0);

is($sword->$_, undef, $_) for qw/is_blessed is_uncursed/;
is($sword->is_cursed, 0, "is_cursed");

$sword->is_blessed(0);

is($sword->$_, 0, $_) for qw/is_blessed is_cursed/;
is($sword->is_uncursed, 1, "setting two of the three to 0 will set the other to 1");


my $spellbook = NetHack::Item->new("a white spellbook");
is($spellbook->$_, undef, $_) for qw/is_blessed is_uncursed is_cursed/;

$spellbook->is_uncursed(1);
is($sword->$_, 0, $_) for qw/is_blessed is_cursed/;
is($sword->is_uncursed, 1, "setting two of the three to 0 will set the other to 1");

done_testing;
