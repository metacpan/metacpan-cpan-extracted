#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;

my $elven_dagger = $pool->new_item("an elven dagger");
ok(!$elven_dagger->is_artifact, "not an artifact yet");

$elven_dagger->specific_name("Sorear");
ok(!$elven_dagger->is_artifact, "not an artifact yet");

$elven_dagger->specific_name("Sting");
ok($elven_dagger->is_artifact, "naming an elven dagger Sting makes it an artifact");

is($pool->get_artifact("Sting"), $elven_dagger, "Sting saved");

my $elven_broadsword = $pool->new_item("an elven broadsword");
ok(!$elven_broadsword->is_artifact, "not an artifact yet");

$elven_broadsword->specific_name("Arcanehl");
ok(!$elven_broadsword->is_artifact, "not an artifact yet");

$elven_broadsword->specific_name("Orcrist");
ok($elven_broadsword->is_artifact, "naming an elven broadsword Orcrist makes it an artifact");

is($pool->get_artifact("Orcrist"), $elven_broadsword, "Orcrist saved");
done_testing;
