#!/usr/bin/perl

use Nes;
my $nes = Nes::Singleton->new();

my %tags;
my $table = [ 
                { 
                  name   => 'One',
                  email  => 'one@example.com',
                },
                { 
                  name   => 'Two',
                  email  => 'two@example.com',
                },
                { 
                  name   => 'Three',
                  email  => 'three@example.com',
                }                                    
            ];

$tags{'users'} = $table;

$nes->out(%tags);

1; 
