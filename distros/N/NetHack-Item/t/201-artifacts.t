#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $spoiler = "NetHack::Item::Spoiler";
my @artifacts;

for my $type ($spoiler->spoiler_types) {
    my $list = $type->list;
    push @artifacts, grep { $_->{artifact} } values %$list;
}

is(@artifacts, 37, "NetHack has 37 artifacts (apparently)");

my @baseless = grep { !$_->{base} } @artifacts;
is(@baseless, 4, "four base-less artifacts (invocation items + Amulet");

for my $artifact (@artifacts) {
    my $item = NetHack::Item->new($artifact->{name});
    ok($item->spoiler, "got some spoiler data from the artifact");
    ok($item->is_artifact, "the item is an artifact!");

    if (grep { $_ == $artifact } @baseless) {
        ok(!exists($artifact->{base}), "no base for the special artifacts");
        next;
    }

    my $base = $artifact->{base};
    my $possibilities = $spoiler->possibilities_for_appearance($base);
    is(@$possibilities, 1, "1 identity for the base ($base) of $artifact->{name}");

    my $identity = $possibilities->[0];
    my $spoiler_data = $spoiler->spoiler_for($identity);
    is($spoiler_data->{name}, $base, "base is identity");
}

done_testing;
