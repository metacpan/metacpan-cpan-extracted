#! /usr/bin/env perl

use 5.010;
use warnings;

use IO::File;
use PPR;

@ARGV = $0;

for my $filename (@ARGV) {
    my $file = slurp($filename);

    my $count = $file =~ s/(?&PerlStatement) $PPR::GRAMMAR//gx;

    printf("$filename contains %d statements\n", $count);
}



sub slurp {
    my $filename = shift;
    my $file = IO::File->new($filename, 'r');
    local $/;
    return readline $file;
}
