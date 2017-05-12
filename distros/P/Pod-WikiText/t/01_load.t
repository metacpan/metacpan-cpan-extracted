#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    chdir 't' if -d 't';
}
use lib '../lib';

use_ok( 'Pod::WikiText' );
require_ok( 'Pod::WikiText' );

my $obj = Pod::WikiText->new(infile=>'01_load.t');

ok( defined $obj, 'new Pod::WikiText()' );
ok( $obj->isa('Pod::WikiText'), 'isa Pod::WikiText' );

exit 0;
