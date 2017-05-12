package Seis::Exporter;
use strict;
use warnings;
use utf8;
use 5.010_001;

sub import {
    my $class = shift;
    my $caller = caller(0);
    no strict 'refs';
    for my $name (@{"${class}::__RG_EXPORT"}) {
        *{"${caller}::${name}"} = *{"${class}::${name}"};
    }
}

1;

