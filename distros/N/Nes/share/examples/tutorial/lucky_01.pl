#!/usr/bin/perl

use Nes;
my $nes = Nes::Singleton->new();

my %nes_tags;
$nes_tags{'number'} = int(rand(10));

$nes->out(%nes_tags);

1;
