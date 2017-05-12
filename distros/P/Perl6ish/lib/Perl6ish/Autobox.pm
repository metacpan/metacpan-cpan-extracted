use strict;

package Perl6ish::Autobox;
use base 'autobox';

sub import {
    (shift)->SUPER::import(
        ARRAY  => 'Perl6ish::Array',
        HASH   => 'Perl6ish::Hash',
        STRING => 'Perl6ish::String'
    );
}


1;

