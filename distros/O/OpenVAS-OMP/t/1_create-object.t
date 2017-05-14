#!/usr/bin/perl -w
#
# Filename:     1_create_objetct
# Description:  Test object creation
# Creator:      Winfried Neessen <wn@neessen.net>
#
# $Id$
#
# Last modified: [ 2013-06-11 16:04:53 ]

use Test::More tests => 2;
use lib ( 'blib/lib', 'lib/', 'lib/OpenVAS' );
use OpenVAS::OMP;

## Create new OpenVAS::OMP object {{{
my $omp = OpenVAS::OMP->new
(
	host		=> 'localhost',
	ssl_verify	=> 1,
	username	=> 'testuser',
	password	=> 'password',
);
# }}}

## Check if object has been defined {{{
ok( defined( $omp ), 'OpenVAS::OMP object successfully created.' );
ok( $omp->isa( 'OpenVAS::OMP' ), 'Object is an OpenVAS::OMP object.' );
# }}}
