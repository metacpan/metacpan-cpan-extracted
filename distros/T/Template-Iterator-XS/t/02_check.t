#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;

use Template::Iterator::XS;

my $i = Template::Iterator-> new([2,'what', sub { 4 } ]);
ok( 2 == $i->get_first );
    
my ( $value ) = $i->get_next;
ok( 'what' eq $value);

( $value ) = $i->get_next;
ok( 4 == $value->());

( $value ) = $i->get_next;
ok( ! defined $value);

( $value ) = $i->get_next;
ok( ! defined $value);
