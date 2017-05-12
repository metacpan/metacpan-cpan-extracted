#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $sack = NetHack::Item->new("a sack");
is($sack->weight, undef, "don't know the weight yet, because we don't know the contents");
$sack->contents_known(1);
is($sack->weight, 15, "the contents are known to be empty, so weight is the sack's weight");

$sack->add_item(NetHack::Item->new("a pearl ring"));
is($sack->weight, 18, "weight is sack's weight + contents' weight");

$sack->add_item(NetHack::Item->new("a gray stone"));
is($sack->weight, undef, "we don't know the sack's weight if we don't know the contents' weight");

my $boh = NetHack::Item->new("a bag of holding");
is($boh->weight, undef, "we don't know the weight yet");
$boh->contents_known(1);
is($boh->weight, 15, "boh weighs 15");

$boh->add_item(NetHack::Item->new("a pearl ring"));
is($boh->weight, undef, "we don't know the BUC of the boh so we don't know the weight");

$boh->is_cursed(1);
is($boh->weight, 21, "weight is 15 + ring(3)*2");
done_testing;
