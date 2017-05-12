#!/usr/bin/perl

use strict;

require 'perperl.ph';

my @fields = &_dummy_slot'fieldnames;

for (my $i = 0; $i <= $#fields; ++$i) {
    my $fld = $fields[$i];
    my $size = &_dummy_slot'sizeof($i);
    printf("%-10s %2d\n", $fld, $size);
}
