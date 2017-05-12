#!/usr/bin/perl
#
# test.pl for sFlow.pm
#
# Elisa Jasinska <elisa.jasinska@ams-ix.net>
# 2006/11/8
#

use Test::More qw(no_plan);

BEGIN { use_ok( 'Net::sFlow' ); } 
BEGIN { use_ok( 'Math::BigInt' ); }
