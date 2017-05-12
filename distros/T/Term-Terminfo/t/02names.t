#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use Term::Terminfo;

# Force vt100 no matter what we're actually on
my $ti = Term::Terminfo->new( "vt100" );

# It would do not to be too exacting on the set of names
ok( scalar( grep { $_ eq "am" } $ti->flag_capnames ), '$ti->flag_capnames has am' );

ok( scalar( grep { $_ eq "it" } $ti->num_capnames ), '$ti->num_capnames has it' );

ok( scalar( grep { $_ eq "cr" } $ti->str_capnames ), '$ti->str_capnames has cr' );

ok( scalar( grep { $_ eq "auto_right_margin" } $ti->flag_varnames ), '$ti->flag_varnames has auto_right_margin' );

ok( scalar( grep { $_ eq "init_tabs" } $ti->num_varnames ), '$ti->num_varnames has init_tabs' );

ok( scalar( grep { $_ eq "carriage_return" } $ti->str_varnames ), '$ti->str_varnames has carriage_return' );
