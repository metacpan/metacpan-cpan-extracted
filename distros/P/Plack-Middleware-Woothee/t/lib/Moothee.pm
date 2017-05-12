package Moothee;
use strict;
use warnings;

sub parse {
    return {
        name     => 'MootheeName',
        category => 'MootheeCategory',
        os       => 'MootheeOs',
        version  => 'MootheeVersion',
        vendor   => 'MootheeVender',
    };
}

sub is_crawler { 'UNKNOWN' }

1;