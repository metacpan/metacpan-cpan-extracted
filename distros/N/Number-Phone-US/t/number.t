#!/usr/bin/env perl -w
# $Id: number.t,v 1.1 2002/08/10 04:38:28 kennedyh Exp $

use strict;
use Test::Simple tests => 19;

# test the manual
use Number::Phone::US qw(is_valid_number);

my @numbers = (
               '(734) 555 1212',
               '(734) 555.1212',
               '(734) 555-1212',
               '(734) 5551212',
               '(734)5551212',
               '734 555 1212',
               '734.555.1212',
               '734-555-1212',
               '7345551212',
               '555 1212',
               '555.1212',
               '555-1212',
               '5551212',
               '5 1212',
               '5.1212',
               '5-1212',
               '51212');


foreach (@numbers) {
  ok( is_valid_number($_) );
}

# we disallow mixed form
ok( !is_valid_number('734-555.1212') );
ok( !is_valid_number('734-5551212') );
