package Moos::Role;

use Moos ();
use Carp;
sub import {
        carp("Please 'use Moos-Role' instead");
        shift and unshift @_, qw( Moos -Role );
        goto \&Moos::import;
}

1;
