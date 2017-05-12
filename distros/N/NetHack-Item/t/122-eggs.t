#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $item = eval { NetHack::Item->new('3 uncursed eggs') };
ok(!$@, "'3 uncursed eggs' didn't throw an error");
done_testing;
