#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

use FindBin;
use Imager;
use PDF::API2;

pass;

diag( "We are $0" );
diag( "Perl $], ", "$^X on $^O" );
diag( "Imager ", $Imager::VERSION );
diag( "PDF::API2 ", $PDF::API2::VERSION );

diag( "FindBind says $FindBin::Bin" );
# diag( join ' ', "INC:", @INC );
