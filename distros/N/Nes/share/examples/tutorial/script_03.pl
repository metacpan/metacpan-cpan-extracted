#!/usr/bin/perl

use Nes;
my $nes = Nes::Singleton->new();

my %tags;
$tags{'var_hello'} = 'Hello Nes Tutorial';

$nes->out(%tags);

1; 
