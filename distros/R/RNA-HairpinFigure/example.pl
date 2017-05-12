#!/usr/bin/env perl
use strict;
# use lib './lib';
use RNA::HairpinFigure;
my @data = (
    [   'test',
        'AGACAUGGGGCUGUGAAAUGGGUGAAACAGAAGCCAAUUAAAACCUAAUUAAUUAAAAACUAAUUAAUUAAAAUUAAUUAGUUUUAUCUAAUUAAAACCUUGUAGUUUUACCUCUAUUUUCCUUGGAAGCUUCU',
        '......(((((((.(((((((((((((((.(((...............((((((((((((((((((((....)))))))))))))...)))))))...))).).)))))))))..))))).).....)))))).',
    ],
    [   'hsa-mir-92a-1 MI0000093 Homo sapiens miR-92a-1 stem-loop',
        'CUUUCUACACAGGUUGGGAUCGGUUGCAAUGCUGUGUUUCUGUAUGGUAUUGCACUUGUCCCGGCCUGUUGAGUUUGG',
        '..(((...((((((((((((.(((.(((((((((((......)))))))))))))).)))))))))))).))).....'
    ]
);

for (@data) {
    my ( $name, $seq, $struct ) = @$_;

    my $figure = draw( $seq, $struct );

    print ">$name\n$seq\n$struct\n$figure\n\n";
}
