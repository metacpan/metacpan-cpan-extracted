#!perl -w

use strict;

use lib 't/lib', 'lib';
use myconfig;

use Test::More tests => 2;

BEGIN {
    use_ok('String::Numeric');
    use_ok('String::Numeric::' . ( $ENV{STRING_NUMERIC_PP} ? 'PP' : 'XS' ));
}

diag("String::Numeric $String::Numeric::VERSION, Perl $], $^X");

