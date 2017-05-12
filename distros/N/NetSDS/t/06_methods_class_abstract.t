#!/usr/bin/env perl
#===============================================================================
#
#         FILE:  06_methods_class_abstract.t
#
#  DESCRIPTION:  Test methods availability
#
#       AUTHOR:  Michael Bochkaryov (Rattler), <misha@rattler.kiev.ua>
#      COMPANY:  Net.Style
#      CREATED:  25.09.2009 17:35:42 EEST
#===============================================================================

use strict;
use warnings;

use Test::More tests => 13;    # last test to print

use NetSDS::Class::Abstract;

can_ok( 'NetSDS::Class::Abstract', 'new' );
can_ok( 'NetSDS::Class::Abstract', 'mk_accessors' );
can_ok( 'NetSDS::Class::Abstract', 'mk_ro_accessors' );
can_ok( 'NetSDS::Class::Abstract', 'mk_wo_accessors' );
can_ok( 'NetSDS::Class::Abstract', 'mk_package_accessors' );
can_ok( 'NetSDS::Class::Abstract', 'mk_class_accessors' );
can_ok( 'NetSDS::Class::Abstract', 'use_modules' );
can_ok( 'NetSDS::Class::Abstract', 'unbless' );
can_ok( 'NetSDS::Class::Abstract', 'log' );
can_ok( 'NetSDS::Class::Abstract', 'logger' );
can_ok( 'NetSDS::Class::Abstract', 'error' );
can_ok( 'NetSDS::Class::Abstract', 'errstr' );
can_ok( 'NetSDS::Class::Abstract', 'errcode' );

1;

