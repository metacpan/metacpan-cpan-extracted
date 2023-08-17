#!/usr/bin/perl

use strict;
use warnings;

use Test::More ( tests => 1 );

use PM::Packages;

is_deeply( [ pm_packages(__FILE__) ], [], "Nothing" );


package 
    Hidden::Package;


__DATA__

package Also::Hidden;
