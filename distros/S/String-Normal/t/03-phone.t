#!perl -T
use strict;
use warnings FATAL => 'all';
use Test::More tests => 2;

use String::Normal;
my $obj = String::Normal->new( type => 'phone' );

is $obj->transform( '(615) 895-1536' ), '6158951536',   "correct transform";
is $obj->transform( '615.895.1536' ),   '6158951536',   "correct transform";
