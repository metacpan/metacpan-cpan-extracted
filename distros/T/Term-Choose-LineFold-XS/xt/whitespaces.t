use 5.16.0;
use strict;
use warnings;



use Test::Whitespaces {

    dirs => [
        'lib',
        't',
        'xt',
    ],

    files => [
        'README',
        'Makefile.PL',
        'Changes',
    ],

};
