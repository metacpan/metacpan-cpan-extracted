use 5.10.0;
use strict;
use warnings;

use Test::Whitespaces {

    dirs => [
         'lib',
        't',
    ],

    files => [
        'README',
        'Makefile.PL',
        'Changes',
    ],

};
