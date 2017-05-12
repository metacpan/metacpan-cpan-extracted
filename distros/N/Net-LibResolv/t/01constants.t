#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

use Net::LibResolv qw(
   NS_C_IN NS_T_A NS_T_MX
   type_name2value type_value2name
);

is( NS_C_IN,  1, 'NS_C_IN' );
is( NS_T_A,   1, 'NS_T_A' );
is( NS_T_MX, 15, 'NS_T_MX' );

is( type_name2value("MX"),   15, 'type_name2value' );
is( type_value2name(15),   "MX", 'type_value2name' );
