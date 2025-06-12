use 5.10.1;
use strict;
use warnings;



use Test::Whitespaces {

    dirs => [
        'lib',
        't',
        'xt',
        'example',
    ],

    files => [
        'README',
        'Makefile.PL',
        'Changes',
    ],

};
