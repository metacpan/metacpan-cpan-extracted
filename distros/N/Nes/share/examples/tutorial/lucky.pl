#!/usr/bin/perl

use Nes;
my $nes = Nes::Singleton->new('./lucky.nhtml');
my $q   = $nes->{'query'}->{'q'};
my $min = $q->{'lucky_param_1'} || 0;
my $max = $q->{'lucky_param_2'} || 9;

my %nes_tags;
$nes_tags{'number'} = $min + int(rand($max+1-$min));

$nes->out(%nes_tags);

1;
